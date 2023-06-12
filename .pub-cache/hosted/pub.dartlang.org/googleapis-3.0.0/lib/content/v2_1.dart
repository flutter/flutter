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

/// Content API for Shopping - v2.1
///
/// Manage your product listings and accounts for Google Shopping
///
/// For more information, see
/// <https://developers.google.com/shopping-content/v2/>
///
/// Create an instance of [ShoppingContentApi] to access these resources:
///
/// - [AccountsResource]
///   - [AccountsCredentialsResource]
///   - [AccountsLabelsResource]
///   - [AccountsReturncarrierResource]
/// - [AccountstatusesResource]
/// - [AccounttaxResource]
/// - [BuyongoogleprogramsResource]
/// - [CollectionsResource]
/// - [CollectionstatusesResource]
/// - [CssesResource]
/// - [DatafeedsResource]
/// - [DatafeedstatusesResource]
/// - [LiasettingsResource]
/// - [LocalinventoryResource]
/// - [OrderinvoicesResource]
/// - [OrderreportsResource]
/// - [OrderreturnsResource]
///   - [OrderreturnsLabelsResource]
/// - [OrdersResource]
/// - [OrdertrackingsignalsResource]
/// - [PosResource]
/// - [ProductsResource]
/// - [ProductstatusesResource]
///   - [ProductstatusesRepricingreportsResource]
/// - [PubsubnotificationsettingsResource]
/// - [RegionalinventoryResource]
/// - [RegionsResource]
/// - [ReportsResource]
/// - [RepricingrulesResource]
///   - [RepricingrulesRepricingreportsResource]
/// - [ReturnaddressResource]
/// - [ReturnpolicyResource]
/// - [ReturnpolicyonlineResource]
/// - [SettlementreportsResource]
/// - [SettlementtransactionsResource]
/// - [ShippingsettingsResource]
library content.v2_1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Manage your product listings and accounts for Google Shopping
class ShoppingContentApi {
  /// Manage your product listings and accounts for Google Shopping
  static const contentScope = 'https://www.googleapis.com/auth/content';

  final commons.ApiRequester _requester;

  AccountsResource get accounts => AccountsResource(_requester);
  AccountstatusesResource get accountstatuses =>
      AccountstatusesResource(_requester);
  AccounttaxResource get accounttax => AccounttaxResource(_requester);
  BuyongoogleprogramsResource get buyongoogleprograms =>
      BuyongoogleprogramsResource(_requester);
  CollectionsResource get collections => CollectionsResource(_requester);
  CollectionstatusesResource get collectionstatuses =>
      CollectionstatusesResource(_requester);
  CssesResource get csses => CssesResource(_requester);
  DatafeedsResource get datafeeds => DatafeedsResource(_requester);
  DatafeedstatusesResource get datafeedstatuses =>
      DatafeedstatusesResource(_requester);
  LiasettingsResource get liasettings => LiasettingsResource(_requester);
  LocalinventoryResource get localinventory =>
      LocalinventoryResource(_requester);
  OrderinvoicesResource get orderinvoices => OrderinvoicesResource(_requester);
  OrderreportsResource get orderreports => OrderreportsResource(_requester);
  OrderreturnsResource get orderreturns => OrderreturnsResource(_requester);
  OrdersResource get orders => OrdersResource(_requester);
  OrdertrackingsignalsResource get ordertrackingsignals =>
      OrdertrackingsignalsResource(_requester);
  PosResource get pos => PosResource(_requester);
  ProductsResource get products => ProductsResource(_requester);
  ProductstatusesResource get productstatuses =>
      ProductstatusesResource(_requester);
  PubsubnotificationsettingsResource get pubsubnotificationsettings =>
      PubsubnotificationsettingsResource(_requester);
  RegionalinventoryResource get regionalinventory =>
      RegionalinventoryResource(_requester);
  RegionsResource get regions => RegionsResource(_requester);
  ReportsResource get reports => ReportsResource(_requester);
  RepricingrulesResource get repricingrules =>
      RepricingrulesResource(_requester);
  ReturnaddressResource get returnaddress => ReturnaddressResource(_requester);
  ReturnpolicyResource get returnpolicy => ReturnpolicyResource(_requester);
  ReturnpolicyonlineResource get returnpolicyonline =>
      ReturnpolicyonlineResource(_requester);
  SettlementreportsResource get settlementreports =>
      SettlementreportsResource(_requester);
  SettlementtransactionsResource get settlementtransactions =>
      SettlementtransactionsResource(_requester);
  ShippingsettingsResource get shippingsettings =>
      ShippingsettingsResource(_requester);

  ShoppingContentApi(http.Client client,
      {core.String rootUrl = 'https://shoppingcontent.googleapis.com/',
      core.String servicePath = 'content/v2.1/'})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AccountsResource {
  final commons.ApiRequester _requester;

  AccountsCredentialsResource get credentials =>
      AccountsCredentialsResource(_requester);
  AccountsLabelsResource get labels => AccountsLabelsResource(_requester);
  AccountsReturncarrierResource get returncarrier =>
      AccountsReturncarrierResource(_requester);

  AccountsResource(commons.ApiRequester client) : _requester = client;

  /// Returns information about the authenticated user.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountsAuthInfoResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountsAuthInfoResponse> authinfo({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'accounts/authinfo';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountsAuthInfoResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Claims the website of a Merchant Center sub-account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account whose website is claimed.
  ///
  /// [overwrite] - Only available to selected merchants. When set to `True`,
  /// this flag removes any existing claim on the requested website by another
  /// account and replaces it with a claim from this account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountsClaimWebsiteResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountsClaimWebsiteResponse> claimwebsite(
    core.String merchantId,
    core.String accountId, {
    core.bool? overwrite,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (overwrite != null) 'overwrite': ['${overwrite}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/accounts/' +
        commons.escapeVariable('$accountId') +
        '/claimwebsite';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return AccountsClaimWebsiteResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves, inserts, updates, and deletes multiple Merchant Center
  /// (sub-)accounts in a single request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountsCustomBatchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountsCustomBatchResponse> custombatch(
    AccountsCustomBatchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'accounts/batch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AccountsCustomBatchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a Merchant Center sub-account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. This must be a multi-client
  /// account, and accountId must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account.
  ///
  /// [force] - Flag to delete sub-accounts with products. The default value is
  /// false.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String merchantId,
    core.String accountId, {
    core.bool? force,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (force != null) 'force': ['${force}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/accounts/' +
        commons.escapeVariable('$accountId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account.
  ///
  /// [view] - Controls which fields will be populated. Acceptable values are:
  /// "merchant" and "css". The default value is "merchant".
  /// Possible string values are:
  /// - "MERCHANT"
  /// - "CSS"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Account].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Account> get(
    core.String merchantId,
    core.String accountId, {
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/accounts/' +
        commons.escapeVariable('$accountId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Account.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a Merchant Center sub-account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. This must be a multi-client
  /// account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Account].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Account> insert(
    Account request,
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/accounts';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Account.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Performs an action on a link between two Merchant Center accounts, namely
  /// accountId and linkedAccountId.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account that should be linked.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountsLinkResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountsLinkResponse> link(
    AccountsLinkRequest request,
    core.String merchantId,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/accounts/' +
        commons.escapeVariable('$accountId') +
        '/link';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AccountsLinkResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the sub-accounts in your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. This must be a multi-client
  /// account.
  ///
  /// [label] - If view is set to "css", only return accounts that are assigned
  /// label with given ID.
  ///
  /// [maxResults] - The maximum number of accounts to return in the response,
  /// used for paging.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [view] - Controls which fields will be populated. Acceptable values are:
  /// "merchant" and "css". The default value is "merchant".
  /// Possible string values are:
  /// - "MERCHANT"
  /// - "CSS"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountsListResponse> list(
    core.String merchantId, {
    core.String? label,
    core.int? maxResults,
    core.String? pageToken,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (label != null) 'label': [label],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/accounts';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of accounts linked to your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account for which to list links.
  ///
  /// [maxResults] - The maximum number of links to return in the response, used
  /// for pagination. The minimum allowed value is 5 results per page. If
  /// provided value is lower than 5, it will be automatically increased to 5.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountsListLinksResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountsListLinksResponse> listlinks(
    core.String merchantId,
    core.String accountId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/accounts/' +
        commons.escapeVariable('$accountId') +
        '/listlinks';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountsListLinksResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a Merchant Center account.
  ///
  /// Any fields that are not provided are deleted from the resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Account].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Account> update(
    Account request,
    core.String merchantId,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/accounts/' +
        commons.escapeVariable('$accountId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Account.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates labels that are assigned to the Merchant Center account by CSS
  /// user.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account.
  ///
  /// [accountId] - The ID of the account whose labels are updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountsUpdateLabelsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountsUpdateLabelsResponse> updatelabels(
    AccountsUpdateLabelsRequest request,
    core.String merchantId,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/accounts/' +
        commons.escapeVariable('$accountId') +
        '/updatelabels';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AccountsUpdateLabelsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccountsCredentialsResource {
  final commons.ApiRequester _requester;

  AccountsCredentialsResource(commons.ApiRequester client)
      : _requester = client;

  /// Uploads credentials for the Merchant Center account.
  ///
  /// If credentials already exist for this Merchant Center account and purpose,
  /// this method updates them.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Required. The merchant id of the account these credentials
  /// belong to.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountCredentials].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountCredentials> create(
    AccountCredentials request,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'accounts/' + commons.escapeVariable('$accountId') + '/credentials';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AccountCredentials.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccountsLabelsResource {
  final commons.ApiRequester _requester;

  AccountsLabelsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new label, not assigned to any account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Required. The id of the account this label belongs to.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountLabel].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountLabel> create(
    AccountLabel request,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' + commons.escapeVariable('$accountId') + '/labels';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AccountLabel.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a label and removes it from all accounts to which it was assigned.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Required. The id of the account that owns the label.
  ///
  /// [labelId] - Required. The id of the label to delete.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String accountId,
    core.String labelId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' +
        commons.escapeVariable('$accountId') +
        '/labels/' +
        commons.escapeVariable('$labelId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Lists the labels assigned to an account.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Required. The account id for whose labels are to be listed.
  ///
  /// [pageSize] - The maximum number of labels to return. The service may
  /// return fewer than this value. If unspecified, at most 50 labels will be
  /// returned. The maximum value is 1000; values above 1000 will be coerced to
  /// 1000.
  ///
  /// [pageToken] - A page token, received from a previous `ListAccountLabels`
  /// call. Provide this to retrieve the subsequent page. When paginating, all
  /// other parameters provided to `ListAccountLabels` must match the call that
  /// provided the page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAccountLabelsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAccountLabelsResponse> list(
    core.String accountId, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' + commons.escapeVariable('$accountId') + '/labels';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAccountLabelsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a label.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Required. The id of the account this label belongs to.
  ///
  /// [labelId] - Required. The id of the label to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountLabel].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountLabel> patch(
    AccountLabel request,
    core.String accountId,
    core.String labelId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' +
        commons.escapeVariable('$accountId') +
        '/labels/' +
        commons.escapeVariable('$labelId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return AccountLabel.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccountsReturncarrierResource {
  final commons.ApiRequester _requester;

  AccountsReturncarrierResource(commons.ApiRequester client)
      : _requester = client;

  /// Links return carrier to a merchant account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Required. The Merchant Center Account Id under which the
  /// Return Carrier is to be linked.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountReturnCarrier].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountReturnCarrier> create(
    AccountReturnCarrier request,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'accounts/' + commons.escapeVariable('$accountId') + '/returncarrier';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AccountReturnCarrier.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Delete a return carrier in the merchant account.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Required. The Merchant Center Account Id under which the
  /// Return Carrier is to be linked.
  ///
  /// [carrierAccountId] - Required. The Google-provided unique carrier ID, used
  /// to update the resource.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String accountId,
    core.String carrierAccountId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' +
        commons.escapeVariable('$accountId') +
        '/returncarrier/' +
        commons.escapeVariable('$carrierAccountId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Lists available return carriers in the merchant account.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Required. The Merchant Center Account Id under which the
  /// Return Carrier is to be linked.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAccountReturnCarrierResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAccountReturnCarrierResponse> list(
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'accounts/' + commons.escapeVariable('$accountId') + '/returncarrier';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAccountReturnCarrierResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a return carrier in the merchant account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Required. The Merchant Center Account Id under which the
  /// Return Carrier is to be linked.
  ///
  /// [carrierAccountId] - Required. The Google-provided unique carrier ID, used
  /// to update the resource.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountReturnCarrier].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountReturnCarrier> patch(
    AccountReturnCarrier request,
    core.String accountId,
    core.String carrierAccountId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' +
        commons.escapeVariable('$accountId') +
        '/returncarrier/' +
        commons.escapeVariable('$carrierAccountId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return AccountReturnCarrier.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccountstatusesResource {
  final commons.ApiRequester _requester;

  AccountstatusesResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves multiple Merchant Center account statuses in a single request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountstatusesCustomBatchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountstatusesCustomBatchResponse> custombatch(
    AccountstatusesCustomBatchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'accountstatuses/batch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AccountstatusesCustomBatchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the status of a Merchant Center account.
  ///
  /// No itemLevelIssues are returned for multi-client accounts.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account.
  ///
  /// [destinations] - If set, only issues for the specified destinations are
  /// returned, otherwise only issues for the Shopping destination.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountStatus].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountStatus> get(
    core.String merchantId,
    core.String accountId, {
    core.List<core.String>? destinations,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (destinations != null) 'destinations': destinations,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/accountstatuses/' +
        commons.escapeVariable('$accountId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountStatus.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the statuses of the sub-accounts in your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. This must be a multi-client
  /// account.
  ///
  /// [destinations] - If set, only issues for the specified destinations are
  /// returned, otherwise only issues for the Shopping destination.
  ///
  /// [maxResults] - The maximum number of account statuses to return in the
  /// response, used for paging.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountstatusesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountstatusesListResponse> list(
    core.String merchantId, {
    core.List<core.String>? destinations,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (destinations != null) 'destinations': destinations,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/accountstatuses';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountstatusesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccounttaxResource {
  final commons.ApiRequester _requester;

  AccounttaxResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves and updates tax settings of multiple accounts in a single
  /// request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccounttaxCustomBatchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccounttaxCustomBatchResponse> custombatch(
    AccounttaxCustomBatchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'accounttax/batch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AccounttaxCustomBatchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the tax settings of the account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account for which to get/update account tax
  /// settings.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountTax].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountTax> get(
    core.String merchantId,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/accounttax/' +
        commons.escapeVariable('$accountId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountTax.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the tax settings of the sub-accounts in your Merchant Center
  /// account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. This must be a multi-client
  /// account.
  ///
  /// [maxResults] - The maximum number of tax settings to return in the
  /// response, used for paging.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccounttaxListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccounttaxListResponse> list(
    core.String merchantId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/accounttax';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccounttaxListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the tax settings of the account.
  ///
  /// Any fields that are not provided are deleted from the resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account for which to get/update account tax
  /// settings.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountTax].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountTax> update(
    AccountTax request,
    core.String merchantId,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/accounttax/' +
        commons.escapeVariable('$accountId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return AccountTax.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class BuyongoogleprogramsResource {
  final commons.ApiRequester _requester;

  BuyongoogleprogramsResource(commons.ApiRequester client)
      : _requester = client;

  /// Reactivates the BoG program in your Merchant Center account.
  ///
  /// Moves the program to the active state when allowed, e.g. when paused.
  /// Important: This method is only whitelisted for selected merchants.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The ID of the account.
  ///
  /// [regionCode] - The program region code \[ISO 3166-1
  /// alpha-2\](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2). Currently
  /// only US is available.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> activate(
    ActivateBuyOnGoogleProgramRequest request,
    core.String merchantId,
    core.String regionCode, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/buyongoogleprograms/' +
        commons.escapeVariable('$regionCode') +
        '/activate';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a status of the BoG program for your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The ID of the account.
  ///
  /// [regionCode] - The Program region code \[ISO 3166-1
  /// alpha-2\](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2). Currently
  /// only US is available.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BuyOnGoogleProgramStatus].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BuyOnGoogleProgramStatus> get(
    core.String merchantId,
    core.String regionCode, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/buyongoogleprograms/' +
        commons.escapeVariable('$regionCode');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return BuyOnGoogleProgramStatus.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Onboards the BoG program in your Merchant Center account.
  ///
  /// By using this method, you agree to the
  /// [Terms of Service](https://merchants.google.com/mc/termsofservice/transactions/US/latest).
  /// Calling this method is only possible if the authenticated account is the
  /// same as the merchant id in the request. Calling this method multiple times
  /// will only accept Terms of Service if the latest version is not currently
  /// signed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The ID of the account.
  ///
  /// [regionCode] - The program region code \[ISO 3166-1
  /// alpha-2\](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2). Currently
  /// only US is available.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> onboard(
    OnboardBuyOnGoogleProgramRequest request,
    core.String merchantId,
    core.String regionCode, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/buyongoogleprograms/' +
        commons.escapeVariable('$regionCode') +
        '/onboard';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Pauses the BoG program in your Merchant Center account.
  ///
  /// Important: This method is only whitelisted for selected merchants.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The ID of the account.
  ///
  /// [regionCode] - The program region code \[ISO 3166-1
  /// alpha-2\](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2). Currently
  /// only US is available.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> pause(
    PauseBuyOnGoogleProgramRequest request,
    core.String merchantId,
    core.String regionCode, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/buyongoogleprograms/' +
        commons.escapeVariable('$regionCode') +
        '/pause';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Requests review and then activates the BoG program in your Merchant Center
  /// account for the first time.
  ///
  /// Moves the program to the REVIEW_PENDING state. Important: This method is
  /// only whitelisted for selected merchants.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The ID of the account.
  ///
  /// [regionCode] - The program region code \[ISO 3166-1
  /// alpha-2\](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2). Currently
  /// only US is available.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> requestreview(
    RequestReviewBuyOnGoogleProgramRequest request,
    core.String merchantId,
    core.String regionCode, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/buyongoogleprograms/' +
        commons.escapeVariable('$regionCode') +
        '/requestreview';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }
}

class CollectionsResource {
  final commons.ApiRequester _requester;

  CollectionsResource(commons.ApiRequester client) : _requester = client;

  /// Uploads a collection to your Merchant Center account.
  ///
  /// If a collection with the same collectionId already exists, this method
  /// updates that entry. In each update, the collection is completely replaced
  /// by the fields in the body of the update request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The ID of the account that contains the
  /// collection. This account cannot be a multi-client account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Collection].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Collection> create(
    Collection request,
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/collections';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Collection.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a collection from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The ID of the account that contains the
  /// collection. This account cannot be a multi-client account.
  ///
  /// [collectionId] - Required. The collectionId of the collection.
  /// CollectionId is the same as the REST ID of the collection.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String merchantId,
    core.String collectionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/collections/' +
        commons.escapeVariable('$collectionId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a collection from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The ID of the account that contains the
  /// collection. This account cannot be a multi-client account.
  ///
  /// [collectionId] - Required. The REST ID of the collection.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Collection].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Collection> get(
    core.String merchantId,
    core.String collectionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/collections/' +
        commons.escapeVariable('$collectionId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Collection.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the collections in your Merchant Center account.
  ///
  /// The response might contain fewer items than specified by page_size. Rely
  /// on next_page_token to determine if there are more items to be requested.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The ID of the account that contains the
  /// collection. This account cannot be a multi-client account.
  ///
  /// [pageSize] - The maximum number of collections to return in the response,
  /// used for paging. Defaults to 50; values above 1000 will be coerced to
  /// 1000.
  ///
  /// [pageToken] - Token (if provided) to retrieve the subsequent page. All
  /// other parameters must match the original call that provided the page
  /// token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListCollectionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListCollectionsResponse> list(
    core.String merchantId, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/collections';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListCollectionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CollectionstatusesResource {
  final commons.ApiRequester _requester;

  CollectionstatusesResource(commons.ApiRequester client) : _requester = client;

  /// Gets the status of a collection from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The ID of the account that contains the
  /// collection. This account cannot be a multi-client account.
  ///
  /// [collectionId] - Required. The collectionId of the collection.
  /// CollectionId is the same as the REST ID of the collection.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CollectionStatus].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CollectionStatus> get(
    core.String merchantId,
    core.String collectionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/collectionstatuses/' +
        commons.escapeVariable('$collectionId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CollectionStatus.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the statuses of the collections in your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The ID of the account that contains the
  /// collection. This account cannot be a multi-client account.
  ///
  /// [pageSize] - The maximum number of collection statuses to return in the
  /// response, used for paging. Defaults to 50; values above 1000 will be
  /// coerced to 1000.
  ///
  /// [pageToken] - Token (if provided) to retrieve the subsequent page. All
  /// other parameters must match the original call that provided the page
  /// token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListCollectionStatusesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListCollectionStatusesResponse> list(
    core.String merchantId, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/collectionstatuses';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListCollectionStatusesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CssesResource {
  final commons.ApiRequester _requester;

  CssesResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a single CSS domain by ID.
  ///
  /// Request parameters:
  ///
  /// [cssGroupId] - Required. The ID of the managing account. If this parameter
  /// is not the same as \[cssDomainId\](#cssDomainId), then this ID must be a
  /// CSS group ID and `cssDomainId` must be the ID of a CSS domain affiliated
  /// with this group.
  ///
  /// [cssDomainId] - Required. The ID of the CSS domain to return.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Css].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Css> get(
    core.String cssGroupId,
    core.String cssDomainId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$cssGroupId') +
        '/csses/' +
        commons.escapeVariable('$cssDomainId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Css.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists CSS domains affiliated with a CSS group.
  ///
  /// Request parameters:
  ///
  /// [cssGroupId] - Required. The CSS group ID of CSS domains to be listed.
  ///
  /// [pageSize] - The maximum number of CSS domains to return. The service may
  /// return fewer than this value. If unspecified, at most 50 CSS domains will
  /// be returned. The maximum value is 1000; values above 1000 will be coerced
  /// to 1000.
  ///
  /// [pageToken] - A page token, received from a previous `ListCsses` call.
  /// Provide this to retrieve the subsequent page. When paginating, all other
  /// parameters provided to `ListCsses` must match the call that provided the
  /// page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListCssesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListCssesResponse> list(
    core.String cssGroupId, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$cssGroupId') + '/csses';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListCssesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates labels that are assigned to a CSS domain by its CSS group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [cssGroupId] - Required. The CSS group ID of the updated CSS domain.
  ///
  /// [cssDomainId] - Required. The ID of the updated CSS domain.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Css].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Css> updatelabels(
    LabelIds request,
    core.String cssGroupId,
    core.String cssDomainId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$cssGroupId') +
        '/csses/' +
        commons.escapeVariable('$cssDomainId') +
        '/updatelabels';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Css.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class DatafeedsResource {
  final commons.ApiRequester _requester;

  DatafeedsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes, fetches, gets, inserts and updates multiple datafeeds in a single
  /// request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DatafeedsCustomBatchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DatafeedsCustomBatchResponse> custombatch(
    DatafeedsCustomBatchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'datafeeds/batch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DatafeedsCustomBatchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a datafeed configuration from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the datafeed. This
  /// account cannot be a multi-client account.
  ///
  /// [datafeedId] - The ID of the datafeed.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String merchantId,
    core.String datafeedId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/datafeeds/' +
        commons.escapeVariable('$datafeedId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Invokes a fetch for the datafeed in your Merchant Center account.
  ///
  /// If you need to call this method more than once per day, we recommend you
  /// use the Products service to update your product data.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the datafeed. This
  /// account cannot be a multi-client account.
  ///
  /// [datafeedId] - The ID of the datafeed to be fetched.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DatafeedsFetchNowResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DatafeedsFetchNowResponse> fetchnow(
    core.String merchantId,
    core.String datafeedId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/datafeeds/' +
        commons.escapeVariable('$datafeedId') +
        '/fetchNow';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return DatafeedsFetchNowResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a datafeed configuration from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the datafeed. This
  /// account cannot be a multi-client account.
  ///
  /// [datafeedId] - The ID of the datafeed.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Datafeed].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Datafeed> get(
    core.String merchantId,
    core.String datafeedId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/datafeeds/' +
        commons.escapeVariable('$datafeedId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Datafeed.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Registers a datafeed configuration with your Merchant Center account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the datafeed. This
  /// account cannot be a multi-client account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Datafeed].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Datafeed> insert(
    Datafeed request,
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/datafeeds';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Datafeed.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the configurations for datafeeds in your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the datafeeds. This
  /// account cannot be a multi-client account.
  ///
  /// [maxResults] - The maximum number of products to return in the response,
  /// used for paging.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DatafeedsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DatafeedsListResponse> list(
    core.String merchantId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/datafeeds';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DatafeedsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a datafeed configuration of your Merchant Center account.
  ///
  /// Any fields that are not provided are deleted from the resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the datafeed. This
  /// account cannot be a multi-client account.
  ///
  /// [datafeedId] - The ID of the datafeed.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Datafeed].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Datafeed> update(
    Datafeed request,
    core.String merchantId,
    core.String datafeedId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/datafeeds/' +
        commons.escapeVariable('$datafeedId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Datafeed.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class DatafeedstatusesResource {
  final commons.ApiRequester _requester;

  DatafeedstatusesResource(commons.ApiRequester client) : _requester = client;

  /// Gets multiple Merchant Center datafeed statuses in a single request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DatafeedstatusesCustomBatchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DatafeedstatusesCustomBatchResponse> custombatch(
    DatafeedstatusesCustomBatchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'datafeedstatuses/batch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DatafeedstatusesCustomBatchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the status of a datafeed from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the datafeed. This
  /// account cannot be a multi-client account.
  ///
  /// [datafeedId] - The ID of the datafeed.
  ///
  /// [country] - The country for which to get the datafeed status. If this
  /// parameter is provided then language must also be provided. Note that this
  /// parameter is required for feeds targeting multiple countries and
  /// languages, since a feed may have a different status for each target.
  ///
  /// [language] - The language for which to get the datafeed status. If this
  /// parameter is provided then country must also be provided. Note that this
  /// parameter is required for feeds targeting multiple countries and
  /// languages, since a feed may have a different status for each target.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DatafeedStatus].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DatafeedStatus> get(
    core.String merchantId,
    core.String datafeedId, {
    core.String? country,
    core.String? language,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (country != null) 'country': [country],
      if (language != null) 'language': [language],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/datafeedstatuses/' +
        commons.escapeVariable('$datafeedId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DatafeedStatus.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the statuses of the datafeeds in your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the datafeeds. This
  /// account cannot be a multi-client account.
  ///
  /// [maxResults] - The maximum number of products to return in the response,
  /// used for paging.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DatafeedstatusesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DatafeedstatusesListResponse> list(
    core.String merchantId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/datafeedstatuses';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DatafeedstatusesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class LiasettingsResource {
  final commons.ApiRequester _requester;

  LiasettingsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves and/or updates the LIA settings of multiple accounts in a single
  /// request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LiasettingsCustomBatchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LiasettingsCustomBatchResponse> custombatch(
    LiasettingsCustomBatchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'liasettings/batch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LiasettingsCustomBatchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the LIA settings of the account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account for which to get or update LIA
  /// settings.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LiaSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LiaSettings> get(
    core.String merchantId,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/liasettings/' +
        commons.escapeVariable('$accountId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LiaSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the list of accessible Google My Business accounts.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account for which to retrieve accessible
  /// Google My Business accounts.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LiasettingsGetAccessibleGmbAccountsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LiasettingsGetAccessibleGmbAccountsResponse>
      getaccessiblegmbaccounts(
    core.String merchantId,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/liasettings/' +
        commons.escapeVariable('$accountId') +
        '/accessiblegmbaccounts';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LiasettingsGetAccessibleGmbAccountsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the LIA settings of the sub-accounts in your Merchant Center
  /// account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. This must be a multi-client
  /// account.
  ///
  /// [maxResults] - The maximum number of LIA settings to return in the
  /// response, used for paging.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LiasettingsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LiasettingsListResponse> list(
    core.String merchantId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/liasettings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LiasettingsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the list of POS data providers that have active settings for the
  /// all eiligible countries.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LiasettingsListPosDataProvidersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LiasettingsListPosDataProvidersResponse> listposdataproviders({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'liasettings/posdataproviders';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LiasettingsListPosDataProvidersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Requests access to a specified Google My Business account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account for which GMB access is requested.
  ///
  /// [gmbEmail] - The email of the Google My Business account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LiasettingsRequestGmbAccessResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LiasettingsRequestGmbAccessResponse> requestgmbaccess(
    core.String merchantId,
    core.String accountId,
    core.String gmbEmail, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'gmbEmail': [gmbEmail],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/liasettings/' +
        commons.escapeVariable('$accountId') +
        '/requestgmbaccess';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return LiasettingsRequestGmbAccessResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Requests inventory validation for the specified country.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account that manages the order. This cannot be
  /// a multi-client account.
  ///
  /// [country] - The country for which inventory validation is requested.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LiasettingsRequestInventoryVerificationResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LiasettingsRequestInventoryVerificationResponse>
      requestinventoryverification(
    core.String merchantId,
    core.String accountId,
    core.String country, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/liasettings/' +
        commons.escapeVariable('$accountId') +
        '/requestinventoryverification/' +
        commons.escapeVariable('$country');

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return LiasettingsRequestInventoryVerificationResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the inventory verification contract for the specified country.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account that manages the order. This cannot be
  /// a multi-client account.
  ///
  /// [country] - The country for which inventory verification is requested.
  ///
  /// [language] - The language for which inventory verification is requested.
  ///
  /// [contactName] - The name of the inventory verification contact.
  ///
  /// [contactEmail] - The email of the inventory verification contact.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LiasettingsSetInventoryVerificationContactResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LiasettingsSetInventoryVerificationContactResponse>
      setinventoryverificationcontact(
    core.String merchantId,
    core.String accountId,
    core.String country,
    core.String language,
    core.String contactName,
    core.String contactEmail, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'country': [country],
      'language': [language],
      'contactName': [contactName],
      'contactEmail': [contactEmail],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/liasettings/' +
        commons.escapeVariable('$accountId') +
        '/setinventoryverificationcontact';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return LiasettingsSetInventoryVerificationContactResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the POS data provider for the specified country.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account for which to retrieve accessible
  /// Google My Business accounts.
  ///
  /// [country] - The country for which the POS data provider is selected.
  ///
  /// [posDataProviderId] - The ID of POS data provider.
  ///
  /// [posExternalAccountId] - The account ID by which this merchant is known to
  /// the POS data provider.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LiasettingsSetPosDataProviderResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LiasettingsSetPosDataProviderResponse> setposdataprovider(
    core.String merchantId,
    core.String accountId,
    core.String country, {
    core.String? posDataProviderId,
    core.String? posExternalAccountId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'country': [country],
      if (posDataProviderId != null) 'posDataProviderId': [posDataProviderId],
      if (posExternalAccountId != null)
        'posExternalAccountId': [posExternalAccountId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/liasettings/' +
        commons.escapeVariable('$accountId') +
        '/setposdataprovider';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return LiasettingsSetPosDataProviderResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the LIA settings of the account.
  ///
  /// Any fields that are not provided are deleted from the resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account for which to get or update LIA
  /// settings.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LiaSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LiaSettings> update(
    LiaSettings request,
    core.String merchantId,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/liasettings/' +
        commons.escapeVariable('$accountId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return LiaSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class LocalinventoryResource {
  final commons.ApiRequester _requester;

  LocalinventoryResource(commons.ApiRequester client) : _requester = client;

  /// Updates local inventory for multiple products or stores in a single
  /// request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LocalinventoryCustomBatchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LocalinventoryCustomBatchResponse> custombatch(
    LocalinventoryCustomBatchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'localinventory/batch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LocalinventoryCustomBatchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the local inventory of a product in your Merchant Center account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that contains the product. This
  /// account cannot be a multi-client account.
  ///
  /// [productId] - The REST ID of the product for which to update local
  /// inventory.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LocalInventory].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LocalInventory> insert(
    LocalInventory request,
    core.String merchantId,
    core.String productId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/products/' +
        commons.escapeVariable('$productId') +
        '/localinventory';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LocalInventory.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrderinvoicesResource {
  final commons.ApiRequester _requester;

  OrderinvoicesResource(commons.ApiRequester client) : _requester = client;

  /// Creates a charge invoice for a shipment group, and triggers a charge
  /// capture for orderinvoice enabled orders.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrderinvoicesCreateChargeInvoiceResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrderinvoicesCreateChargeInvoiceResponse> createchargeinvoice(
    OrderinvoicesCreateChargeInvoiceRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orderinvoices/' +
        commons.escapeVariable('$orderId') +
        '/createChargeInvoice';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrderinvoicesCreateChargeInvoiceResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a refund invoice for one or more shipment groups, and triggers a
  /// refund for orderinvoice enabled orders.
  ///
  /// This can only be used for line items that have previously been charged
  /// using `createChargeInvoice`. All amounts (except for the summary) are
  /// incremental with respect to the previous invoice.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrderinvoicesCreateRefundInvoiceResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrderinvoicesCreateRefundInvoiceResponse> createrefundinvoice(
    OrderinvoicesCreateRefundInvoiceRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orderinvoices/' +
        commons.escapeVariable('$orderId') +
        '/createRefundInvoice';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrderinvoicesCreateRefundInvoiceResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrderreportsResource {
  final commons.ApiRequester _requester;

  OrderreportsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a report for disbursements from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [disbursementEndDate] - The last date which disbursements occurred. In ISO
  /// 8601 format. Default: current date.
  ///
  /// [disbursementStartDate] - The first date which disbursements occurred. In
  /// ISO 8601 format.
  ///
  /// [maxResults] - The maximum number of disbursements to return in the
  /// response, used for paging.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrderreportsListDisbursementsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrderreportsListDisbursementsResponse> listdisbursements(
    core.String merchantId, {
    core.String? disbursementEndDate,
    core.String? disbursementStartDate,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (disbursementEndDate != null)
        'disbursementEndDate': [disbursementEndDate],
      if (disbursementStartDate != null)
        'disbursementStartDate': [disbursementStartDate],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        commons.escapeVariable('$merchantId') + '/orderreports/disbursements';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OrderreportsListDisbursementsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of transactions for a disbursement from your Merchant
  /// Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [disbursementId] - The Google-provided ID of the disbursement (found in
  /// Wallet).
  ///
  /// [maxResults] - The maximum number of disbursements to return in the
  /// response, used for paging.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [transactionEndDate] - The last date in which transaction occurred. In ISO
  /// 8601 format. Default: current date.
  ///
  /// [transactionStartDate] - The first date in which transaction occurred. In
  /// ISO 8601 format.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrderreportsListTransactionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrderreportsListTransactionsResponse> listtransactions(
    core.String merchantId,
    core.String disbursementId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? transactionEndDate,
    core.String? transactionStartDate,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (transactionEndDate != null)
        'transactionEndDate': [transactionEndDate],
      if (transactionStartDate != null)
        'transactionStartDate': [transactionStartDate],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orderreports/disbursements/' +
        commons.escapeVariable('$disbursementId') +
        '/transactions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OrderreportsListTransactionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrderreturnsResource {
  final commons.ApiRequester _requester;

  OrderreturnsLabelsResource get labels =>
      OrderreturnsLabelsResource(_requester);

  OrderreturnsResource(commons.ApiRequester client) : _requester = client;

  /// Acks an order return in your Merchant Center account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [returnId] - The ID of the return.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrderreturnsAcknowledgeResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrderreturnsAcknowledgeResponse> acknowledge(
    OrderreturnsAcknowledgeRequest request,
    core.String merchantId,
    core.String returnId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orderreturns/' +
        commons.escapeVariable('$returnId') +
        '/acknowledge';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrderreturnsAcknowledgeResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Create return in your Merchant Center account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrderreturnsCreateOrderReturnResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrderreturnsCreateOrderReturnResponse> createorderreturn(
    OrderreturnsCreateOrderReturnRequest request,
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orderreturns/createOrderReturn';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrderreturnsCreateOrderReturnResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves an order return from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [returnId] - Merchant order return ID generated by Google.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [MerchantOrderReturn].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<MerchantOrderReturn> get(
    core.String merchantId,
    core.String returnId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orderreturns/' +
        commons.escapeVariable('$returnId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return MerchantOrderReturn.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists order returns in your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [acknowledged] - Obtains order returns that match the acknowledgement
  /// status. When set to true, obtains order returns that have been
  /// acknowledged. When false, obtains order returns that have not been
  /// acknowledged. When not provided, obtains order returns regardless of their
  /// acknowledgement status. We recommend using this filter set to `false`, in
  /// conjunction with the `acknowledge` call, such that only un-acknowledged
  /// order returns are returned.
  ///
  /// [createdEndDate] - Obtains order returns created before this date
  /// (inclusively), in ISO 8601 format.
  ///
  /// [createdStartDate] - Obtains order returns created after this date
  /// (inclusively), in ISO 8601 format.
  ///
  /// [googleOrderIds] - Obtains order returns with the specified order ids. If
  /// this parameter is provided, createdStartDate, createdEndDate,
  /// shipmentType, shipmentStatus, shipmentState and acknowledged parameters
  /// must be not set. Note: if googleOrderId and shipmentTrackingNumber
  /// parameters are provided, the obtained results will include all order
  /// returns that either match the specified order id or the specified tracking
  /// number.
  ///
  /// [maxResults] - The maximum number of order returns to return in the
  /// response, used for paging. The default value is 25 returns per page, and
  /// the maximum allowed value is 250 returns per page.
  ///
  /// [orderBy] - Return the results in the specified order.
  /// Possible string values are:
  /// - "RETURN_CREATION_TIME_DESC"
  /// - "RETURN_CREATION_TIME_ASC"
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [shipmentStates] - Obtains order returns that match any shipment state
  /// provided in this parameter. When this parameter is not provided, order
  /// returns are obtained regardless of their shipment states.
  ///
  /// [shipmentStatus] - Obtains order returns that match any shipment status
  /// provided in this parameter. When this parameter is not provided, order
  /// returns are obtained regardless of their shipment statuses.
  ///
  /// [shipmentTrackingNumbers] - Obtains order returns with the specified
  /// tracking numbers. If this parameter is provided, createdStartDate,
  /// createdEndDate, shipmentType, shipmentStatus, shipmentState and
  /// acknowledged parameters must be not set. Note: if googleOrderId and
  /// shipmentTrackingNumber parameters are provided, the obtained results will
  /// include all order returns that either match the specified order id or the
  /// specified tracking number.
  ///
  /// [shipmentTypes] - Obtains order returns that match any shipment type
  /// provided in this parameter. When this parameter is not provided, order
  /// returns are obtained regardless of their shipment types.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrderreturnsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrderreturnsListResponse> list(
    core.String merchantId, {
    core.bool? acknowledged,
    core.String? createdEndDate,
    core.String? createdStartDate,
    core.List<core.String>? googleOrderIds,
    core.int? maxResults,
    core.String? orderBy,
    core.String? pageToken,
    core.List<core.String>? shipmentStates,
    core.List<core.String>? shipmentStatus,
    core.List<core.String>? shipmentTrackingNumbers,
    core.List<core.String>? shipmentTypes,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (acknowledged != null) 'acknowledged': ['${acknowledged}'],
      if (createdEndDate != null) 'createdEndDate': [createdEndDate],
      if (createdStartDate != null) 'createdStartDate': [createdStartDate],
      if (googleOrderIds != null) 'googleOrderIds': googleOrderIds,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if (shipmentStates != null) 'shipmentStates': shipmentStates,
      if (shipmentStatus != null) 'shipmentStatus': shipmentStatus,
      if (shipmentTrackingNumbers != null)
        'shipmentTrackingNumbers': shipmentTrackingNumbers,
      if (shipmentTypes != null) 'shipmentTypes': shipmentTypes,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/orderreturns';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OrderreturnsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Processes return in your Merchant Center account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [returnId] - The ID of the return.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrderreturnsProcessResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrderreturnsProcessResponse> process(
    OrderreturnsProcessRequest request,
    core.String merchantId,
    core.String returnId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orderreturns/' +
        commons.escapeVariable('$returnId') +
        '/process';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrderreturnsProcessResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrderreturnsLabelsResource {
  final commons.ApiRequester _requester;

  OrderreturnsLabelsResource(commons.ApiRequester client) : _requester = client;

  /// Links a return shipping label to a return id.
  ///
  /// You can only create one return label per return id. Since the label is
  /// sent to the buyer, the linked return label cannot be updated or deleted.
  /// If you try to create multiple return shipping labels for a single return
  /// id, every create request except the first will fail.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The merchant the Return Shipping Label belongs
  /// to.
  ///
  /// [returnId] - Required. Provide the Google-generated merchant order return
  /// ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReturnShippingLabel].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReturnShippingLabel> create(
    ReturnShippingLabel request,
    core.String merchantId,
    core.String returnId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orderreturns/' +
        commons.escapeVariable('$returnId') +
        '/labels';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ReturnShippingLabel.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrdersResource {
  final commons.ApiRequester _requester;

  OrdersResource(commons.ApiRequester client) : _requester = client;

  /// Marks an order as acknowledged.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersAcknowledgeResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersAcknowledgeResponse> acknowledge(
    OrdersAcknowledgeRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId') +
        '/acknowledge';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersAcknowledgeResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sandbox only.
  ///
  /// Moves a test order from state "`inProgress`" to state "`pendingShipment`".
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the test order to modify.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersAdvanceTestOrderResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersAdvanceTestOrderResponse> advancetestorder(
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/testorders/' +
        commons.escapeVariable('$orderId') +
        '/advance';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return OrdersAdvanceTestOrderResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Cancels all line items in an order, making a full refund.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order to cancel.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersCancelResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersCancelResponse> cancel(
    OrdersCancelRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId') +
        '/cancel';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersCancelResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Cancels a line item, making a full refund.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersCancelLineItemResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersCancelLineItemResponse> cancellineitem(
    OrdersCancelLineItemRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId') +
        '/cancelLineItem';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersCancelLineItemResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sandbox only.
  ///
  /// Cancels a test order for customer-initiated cancellation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the test order to cancel.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersCancelTestOrderByCustomerResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersCancelTestOrderByCustomerResponse>
      canceltestorderbycustomer(
    OrdersCancelTestOrderByCustomerRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/testorders/' +
        commons.escapeVariable('$orderId') +
        '/cancelByCustomer';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersCancelTestOrderByCustomerResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sandbox only.
  ///
  /// Creates a test order.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that should manage the order. This
  /// cannot be a multi-client account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersCreateTestOrderResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersCreateTestOrderResponse> createtestorder(
    OrdersCreateTestOrderRequest request,
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/testorders';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersCreateTestOrderResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sandbox only.
  ///
  /// Creates a test return.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersCreateTestReturnResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersCreateTestReturnResponse> createtestreturn(
    OrdersCreateTestReturnRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId') +
        '/testreturn';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersCreateTestReturnResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves an order from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Order].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Order> get(
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Order.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves an order using merchant order ID.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [merchantOrderId] - The merchant order ID to be looked for.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersGetByMerchantOrderIdResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersGetByMerchantOrderIdResponse> getbymerchantorderid(
    core.String merchantId,
    core.String merchantOrderId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/ordersbymerchantid/' +
        commons.escapeVariable('$merchantOrderId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OrdersGetByMerchantOrderIdResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sandbox only.
  ///
  /// Retrieves an order template that can be used to quickly create a new order
  /// in sandbox.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that should manage the order. This
  /// cannot be a multi-client account.
  ///
  /// [templateName] - The name of the template to retrieve.
  /// Possible string values are:
  /// - "TEMPLATE1"
  /// - "TEMPLATE2"
  /// - "TEMPLATE1A"
  /// - "TEMPLATE1B"
  /// - "TEMPLATE3"
  /// - "TEMPLATE4"
  ///
  /// [country] - The country of the template to retrieve. Defaults to `US`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersGetTestOrderTemplateResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersGetTestOrderTemplateResponse> gettestordertemplate(
    core.String merchantId,
    core.String templateName, {
    core.String? country,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (country != null) 'country': [country],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/testordertemplates/' +
        commons.escapeVariable('$templateName');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OrdersGetTestOrderTemplateResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Notifies that item return and refund was handled directly by merchant
  /// outside of Google payments processing (e.g. cash refund done in store).
  ///
  /// Note: We recommend calling the returnrefundlineitem method to refund
  /// in-store returns. We will issue the refund directly to the customer. This
  /// helps to prevent possible differences arising between merchant and Google
  /// transaction records. We also recommend having the point of sale system
  /// communicate with Google to ensure that customers do not receive a double
  /// refund by first refunding via Google then via an in-store return.
  ///
  /// Deprecated.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersInStoreRefundLineItemResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersInStoreRefundLineItemResponse> instorerefundlineitem(
    OrdersInStoreRefundLineItemRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId') +
        '/inStoreRefundLineItem';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersInStoreRefundLineItemResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the orders in your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [acknowledged] - Obtains orders that match the acknowledgement status.
  /// When set to true, obtains orders that have been acknowledged. When false,
  /// obtains orders that have not been acknowledged. We recommend using this
  /// filter set to `false`, in conjunction with the `acknowledge` call, such
  /// that only un-acknowledged orders are returned.
  ///
  /// [maxResults] - The maximum number of orders to return in the response,
  /// used for paging. The default value is 25 orders per page, and the maximum
  /// allowed value is 250 orders per page.
  ///
  /// [orderBy] - Order results by placement date in descending or ascending
  /// order. Acceptable values are: - placedDateAsc - placedDateDesc
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [placedDateEnd] - Obtains orders placed before this date (exclusively), in
  /// ISO 8601 format.
  ///
  /// [placedDateStart] - Obtains orders placed after this date (inclusively),
  /// in ISO 8601 format.
  ///
  /// [statuses] - Obtains orders that match any of the specified statuses.
  /// Please note that `active` is a shortcut for `pendingShipment` and
  /// `partiallyShipped`, and `completed` is a shortcut for `shipped`,
  /// `partiallyDelivered`, `delivered`, `partiallyReturned`, `returned`, and
  /// `canceled`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersListResponse> list(
    core.String merchantId, {
    core.bool? acknowledged,
    core.int? maxResults,
    core.String? orderBy,
    core.String? pageToken,
    core.String? placedDateEnd,
    core.String? placedDateStart,
    core.List<core.String>? statuses,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (acknowledged != null) 'acknowledged': ['${acknowledged}'],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if (placedDateEnd != null) 'placedDateEnd': [placedDateEnd],
      if (placedDateStart != null) 'placedDateStart': [placedDateStart],
      if (statuses != null) 'statuses': statuses,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/orders';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return OrdersListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Issues a partial or total refund for items and shipment.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order to refund.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersRefundItemResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersRefundItemResponse> refunditem(
    OrdersRefundItemRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId') +
        '/refunditem';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersRefundItemResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Issues a partial or total refund for an order.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order to refund.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersRefundOrderResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersRefundOrderResponse> refundorder(
    OrdersRefundOrderRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId') +
        '/refundorder';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersRefundOrderResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Rejects return on an line item.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersRejectReturnLineItemResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersRejectReturnLineItemResponse> rejectreturnlineitem(
    OrdersRejectReturnLineItemRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId') +
        '/rejectReturnLineItem';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersRejectReturnLineItemResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns and refunds a line item.
  ///
  /// Note that this method can only be called on fully shipped orders. Please
  /// also note that the Orderreturns API is the preferred way to handle returns
  /// after you receive a return from a customer. You can use Orderreturns.list
  /// or Orderreturns.get to search for the return, and then use
  /// Orderreturns.processreturn to issue the refund. If the return cannot be
  /// found, then we recommend using this API to issue a refund.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersReturnRefundLineItemResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersReturnRefundLineItemResponse> returnrefundlineitem(
    OrdersReturnRefundLineItemRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId') +
        '/returnRefundLineItem';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersReturnRefundLineItemResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets (or overrides if it already exists) merchant provided annotations in
  /// the form of key-value pairs.
  ///
  /// A common use case would be to supply us with additional structured
  /// information about a line item that cannot be provided via other methods.
  /// Submitted key-value pairs can be retrieved as part of the orders resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersSetLineItemMetadataResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersSetLineItemMetadataResponse> setlineitemmetadata(
    OrdersSetLineItemMetadataRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId') +
        '/setLineItemMetadata';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersSetLineItemMetadataResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Marks line item(s) as shipped.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersShipLineItemsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersShipLineItemsResponse> shiplineitems(
    OrdersShipLineItemsRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId') +
        '/shipLineItems';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersShipLineItemsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates ship by and delivery by dates for a line item.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersUpdateLineItemShippingDetailsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersUpdateLineItemShippingDetailsResponse>
      updatelineitemshippingdetails(
    OrdersUpdateLineItemShippingDetailsRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId') +
        '/updateLineItemShippingDetails';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersUpdateLineItemShippingDetailsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the merchant order ID for a given order.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersUpdateMerchantOrderIdResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersUpdateMerchantOrderIdResponse> updatemerchantorderid(
    OrdersUpdateMerchantOrderIdRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId') +
        '/updateMerchantOrderId';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersUpdateMerchantOrderIdResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a shipment's status, carrier, and/or tracking ID.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that manages the order. This cannot
  /// be a multi-client account.
  ///
  /// [orderId] - The ID of the order.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrdersUpdateShipmentResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrdersUpdateShipmentResponse> updateshipment(
    OrdersUpdateShipmentRequest request,
    core.String merchantId,
    core.String orderId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/orders/' +
        commons.escapeVariable('$orderId') +
        '/updateShipment';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrdersUpdateShipmentResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrdertrackingsignalsResource {
  final commons.ApiRequester _requester;

  OrdertrackingsignalsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates new order tracking signal.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the merchant for which the order signal is
  /// created.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrderTrackingSignal].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrderTrackingSignal> create(
    OrderTrackingSignal request,
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        commons.escapeVariable('$merchantId') + '/ordertrackingsignals';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrderTrackingSignal.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PosResource {
  final commons.ApiRequester _requester;

  PosResource(commons.ApiRequester client) : _requester = client;

  /// Batches multiple POS-related calls in a single request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PosCustomBatchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PosCustomBatchResponse> custombatch(
    PosCustomBatchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'pos/batch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PosCustomBatchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a store for the given merchant.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the POS or inventory data provider.
  ///
  /// [targetMerchantId] - The ID of the target merchant.
  ///
  /// [storeCode] - A store code that is unique per merchant.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String merchantId,
    core.String targetMerchantId,
    core.String storeCode, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/pos/' +
        commons.escapeVariable('$targetMerchantId') +
        '/store/' +
        commons.escapeVariable('$storeCode');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves information about the given store.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the POS or inventory data provider.
  ///
  /// [targetMerchantId] - The ID of the target merchant.
  ///
  /// [storeCode] - A store code that is unique per merchant.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PosStore].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PosStore> get(
    core.String merchantId,
    core.String targetMerchantId,
    core.String storeCode, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/pos/' +
        commons.escapeVariable('$targetMerchantId') +
        '/store/' +
        commons.escapeVariable('$storeCode');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PosStore.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a store for the given merchant.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the POS or inventory data provider.
  ///
  /// [targetMerchantId] - The ID of the target merchant.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PosStore].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PosStore> insert(
    PosStore request,
    core.String merchantId,
    core.String targetMerchantId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/pos/' +
        commons.escapeVariable('$targetMerchantId') +
        '/store';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PosStore.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Submit inventory for the given merchant.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the POS or inventory data provider.
  ///
  /// [targetMerchantId] - The ID of the target merchant.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PosInventoryResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PosInventoryResponse> inventory(
    PosInventoryRequest request,
    core.String merchantId,
    core.String targetMerchantId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/pos/' +
        commons.escapeVariable('$targetMerchantId') +
        '/inventory';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PosInventoryResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the stores of the target merchant.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the POS or inventory data provider.
  ///
  /// [targetMerchantId] - The ID of the target merchant.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PosListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PosListResponse> list(
    core.String merchantId,
    core.String targetMerchantId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/pos/' +
        commons.escapeVariable('$targetMerchantId') +
        '/store';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PosListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Submit a sale event for the given merchant.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the POS or inventory data provider.
  ///
  /// [targetMerchantId] - The ID of the target merchant.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PosSaleResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PosSaleResponse> sale(
    PosSaleRequest request,
    core.String merchantId,
    core.String targetMerchantId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/pos/' +
        commons.escapeVariable('$targetMerchantId') +
        '/sale';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PosSaleResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProductsResource {
  final commons.ApiRequester _requester;

  ProductsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves, inserts, and deletes multiple products in a single request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ProductsCustomBatchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ProductsCustomBatchResponse> custombatch(
    ProductsCustomBatchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'products/batch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ProductsCustomBatchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a product from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that contains the product. This
  /// account cannot be a multi-client account.
  ///
  /// [productId] - The REST ID of the product.
  ///
  /// [feedId] - The Content API Supplemental Feed ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String merchantId,
    core.String productId, {
    core.String? feedId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (feedId != null) 'feedId': [feedId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/products/' +
        commons.escapeVariable('$productId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a product from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that contains the product. This
  /// account cannot be a multi-client account.
  ///
  /// [productId] - The REST ID of the product.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Product].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Product> get(
    core.String merchantId,
    core.String productId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/products/' +
        commons.escapeVariable('$productId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Product.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Uploads a product to your Merchant Center account.
  ///
  /// If an item with the same channel, contentLanguage, offerId, and
  /// targetCountry already exists, this method updates that entry.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that contains the product. This
  /// account cannot be a multi-client account.
  ///
  /// [feedId] - The Content API Supplemental Feed ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Product].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Product> insert(
    Product request,
    core.String merchantId, {
    core.String? feedId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (feedId != null) 'feedId': [feedId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/products';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Product.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the products in your Merchant Center account.
  ///
  /// The response might contain fewer items than specified by maxResults. Rely
  /// on nextPageToken to determine if there are more items to be requested.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that contains the products. This
  /// account cannot be a multi-client account.
  ///
  /// [maxResults] - The maximum number of products to return in the response,
  /// used for paging.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ProductsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ProductsListResponse> list(
    core.String merchantId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/products';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ProductsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing product in your Merchant Center account.
  ///
  /// Only updates attributes provided in the request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that contains the product. This
  /// account cannot be a multi-client account.
  ///
  /// [productId] - The REST ID of the product for which to update.
  ///
  /// [updateMask] - The list of product attributes to be updated. Attributes
  /// specified in the update mask without a value specified in the body will be
  /// deleted from the product. Only top-level product attributes can be
  /// updated. If not defined, product attributes with set values will be
  /// updated and other attributes will stay unchanged.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Product].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Product> update(
    Product request,
    core.String merchantId,
    core.String productId, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/products/' +
        commons.escapeVariable('$productId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Product.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProductstatusesResource {
  final commons.ApiRequester _requester;

  ProductstatusesRepricingreportsResource get repricingreports =>
      ProductstatusesRepricingreportsResource(_requester);

  ProductstatusesResource(commons.ApiRequester client) : _requester = client;

  /// Gets the statuses of multiple products in a single request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ProductstatusesCustomBatchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ProductstatusesCustomBatchResponse> custombatch(
    ProductstatusesCustomBatchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'productstatuses/batch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ProductstatusesCustomBatchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the status of a product from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that contains the product. This
  /// account cannot be a multi-client account.
  ///
  /// [productId] - The REST ID of the product.
  ///
  /// [destinations] - If set, only issues for the specified destinations are
  /// returned, otherwise only issues for the Shopping destination.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ProductStatus].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ProductStatus> get(
    core.String merchantId,
    core.String productId, {
    core.List<core.String>? destinations,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (destinations != null) 'destinations': destinations,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/productstatuses/' +
        commons.escapeVariable('$productId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ProductStatus.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the statuses of the products in your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that contains the products. This
  /// account cannot be a multi-client account.
  ///
  /// [destinations] - If set, only issues for the specified destinations are
  /// returned, otherwise only issues for the Shopping destination.
  ///
  /// [maxResults] - The maximum number of product statuses to return in the
  /// response, used for paging.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ProductstatusesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ProductstatusesListResponse> list(
    core.String merchantId, {
    core.List<core.String>? destinations,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (destinations != null) 'destinations': destinations,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/productstatuses';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ProductstatusesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProductstatusesRepricingreportsResource {
  final commons.ApiRequester _requester;

  ProductstatusesRepricingreportsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists the metrics report for a given Repricing product.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. Id of the merchant who owns the Repricing rule.
  ///
  /// [productId] - Required. Id of the Repricing product. Also known as the
  /// [REST_ID](https://developers.google.com/shopping-content/reference/rest/v2.1/products#Product.FIELDS.id)
  ///
  /// [endDate] - Gets Repricing reports on and before this date in the
  /// merchant's timezone. You can only retrieve data up to 7 days ago (default)
  /// or earlier. Format is YYYY-MM-DD.
  ///
  /// [pageSize] - Maximum number of days of reports to return. There can be
  /// more than one rule report returned per day. For example, if 3 rule types
  /// got applied to the same product within a 24-hour period, then a page_size
  /// of 1 will return 3 rule reports. The page size defaults to 50 and values
  /// above 1000 are coerced to 1000. This service may return fewer days of
  /// reports than this value, for example, if the time between your start and
  /// end date is less than the page size.
  ///
  /// [pageToken] - Token (if provided) to retrieve the subsequent page. All
  /// other parameters must match the original call that provided the page
  /// token.
  ///
  /// [ruleId] - Id of the Repricing rule. If specified, only gets this rule's
  /// reports.
  ///
  /// [startDate] - Gets Repricing reports on and after this date in the
  /// merchant's timezone, up to one year ago. Do not use a start date later
  /// than 7 days ago (default). Format is YYYY-MM-DD.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListRepricingProductReportsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListRepricingProductReportsResponse> list(
    core.String merchantId,
    core.String productId, {
    core.String? endDate,
    core.int? pageSize,
    core.String? pageToken,
    core.String? ruleId,
    core.String? startDate,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (endDate != null) 'endDate': [endDate],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (ruleId != null) 'ruleId': [ruleId],
      if (startDate != null) 'startDate': [startDate],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/productstatuses/' +
        commons.escapeVariable('$productId') +
        '/repricingreports';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListRepricingProductReportsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PubsubnotificationsettingsResource {
  final commons.ApiRequester _requester;

  PubsubnotificationsettingsResource(commons.ApiRequester client)
      : _requester = client;

  /// Retrieves a Merchant Center account's pubsub notification settings.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account for which to get pubsub notification
  /// settings.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PubsubNotificationSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PubsubNotificationSettings> get(
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        commons.escapeVariable('$merchantId') + '/pubsubnotificationsettings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PubsubNotificationSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Register a Merchant Center account for pubsub notifications.
  ///
  /// Note that cloud topic name should not be provided as part of the request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PubsubNotificationSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PubsubNotificationSettings> update(
    PubsubNotificationSettings request,
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        commons.escapeVariable('$merchantId') + '/pubsubnotificationsettings';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return PubsubNotificationSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class RegionalinventoryResource {
  final commons.ApiRequester _requester;

  RegionalinventoryResource(commons.ApiRequester client) : _requester = client;

  /// Updates regional inventory for multiple products or regions in a single
  /// request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RegionalinventoryCustomBatchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RegionalinventoryCustomBatchResponse> custombatch(
    RegionalinventoryCustomBatchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'regionalinventory/batch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return RegionalinventoryCustomBatchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update the regional inventory of a product in your Merchant Center
  /// account.
  ///
  /// If a regional inventory with the same region ID already exists, this
  /// method updates that entry.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account that contains the product. This
  /// account cannot be a multi-client account.
  ///
  /// [productId] - The REST ID of the product for which to update the regional
  /// inventory.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RegionalInventory].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RegionalInventory> insert(
    RegionalInventory request,
    core.String merchantId,
    core.String productId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/products/' +
        commons.escapeVariable('$productId') +
        '/regionalinventory';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return RegionalInventory.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class RegionsResource {
  final commons.ApiRequester _requester;

  RegionsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a region definition in your Merchant Center account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant for which to create region
  /// definition.
  ///
  /// [regionId] - Required. The id of the region to create.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Region].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Region> create(
    Region request,
    core.String merchantId, {
    core.String? regionId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (regionId != null) 'regionId': [regionId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/regions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Region.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a region definition from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant for which to delete region
  /// definition.
  ///
  /// [regionId] - Required. The id of the region to delete.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String merchantId,
    core.String regionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/regions/' +
        commons.escapeVariable('$regionId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a region defined in your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant for which to retrieve
  /// region definition.
  ///
  /// [regionId] - Required. The id of the region to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Region].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Region> get(
    core.String merchantId,
    core.String regionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/regions/' +
        commons.escapeVariable('$regionId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Region.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the regions in your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant for which to list region
  /// definitions.
  ///
  /// [pageSize] - The maximum number of regions to return. The service may
  /// return fewer than this value. If unspecified, at most 50 rules will be
  /// returned. The maximum value is 1000; values above 1000 will be coerced to
  /// 1000.
  ///
  /// [pageToken] - A page token, received from a previous `ListRegions` call.
  /// Provide this to retrieve the subsequent page. When paginating, all other
  /// parameters provided to `ListRegions` must match the call that provided the
  /// page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListRegionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListRegionsResponse> list(
    core.String merchantId, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/regions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListRegionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a region definition in your Merchant Center account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant for which to update region
  /// definition.
  ///
  /// [regionId] - Required. The id of the region to update.
  ///
  /// [updateMask] - Optional. The field mask indicating the fields to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Region].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Region> patch(
    Region request,
    core.String merchantId,
    core.String regionId, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/regions/' +
        commons.escapeVariable('$regionId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Region.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ReportsResource {
  final commons.ApiRequester _requester;

  ReportsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves merchant performance mertrics matching the search query and
  /// optionally segmented by selected dimensions.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. Id of the merchant making the call. Must be a
  /// standalone account or an MCA subaccount.
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
    SearchRequest request,
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/reports/search';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SearchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class RepricingrulesResource {
  final commons.ApiRequester _requester;

  RepricingrulesRepricingreportsResource get repricingreports =>
      RepricingrulesRepricingreportsResource(_requester);

  RepricingrulesResource(commons.ApiRequester client) : _requester = client;

  /// Creates a repricing rule for your Merchant Center account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant who owns the repricing
  /// rule.
  ///
  /// [ruleId] - Required. The id of the rule to create.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RepricingRule].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RepricingRule> create(
    RepricingRule request,
    core.String merchantId, {
    core.String? ruleId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (ruleId != null) 'ruleId': [ruleId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/repricingrules';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return RepricingRule.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a repricing rule in your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant who owns the repricing
  /// rule.
  ///
  /// [ruleId] - Required. The id of the rule to Delete.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String merchantId,
    core.String ruleId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/repricingrules/' +
        commons.escapeVariable('$ruleId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a repricing rule from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant who owns the repricing
  /// rule.
  ///
  /// [ruleId] - Required. The id of the rule to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RepricingRule].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RepricingRule> get(
    core.String merchantId,
    core.String ruleId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/repricingrules/' +
        commons.escapeVariable('$ruleId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return RepricingRule.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the repricing rules in your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant who owns the repricing
  /// rule.
  ///
  /// [countryCode] -
  /// [CLDR country code](http://www.unicode.org/repos/cldr/tags/latest/common/main/en.xml)
  /// (e.g. "US"), used as a filter on repricing rules.
  ///
  /// [languageCode] - The two-letter ISO 639-1 language code associated with
  /// the repricing rule, used as a filter.
  ///
  /// [pageSize] - The maximum number of repricing rules to return. The service
  /// may return fewer than this value. If unspecified, at most 50 rules will be
  /// returned. The maximum value is 1000; values above 1000 will be coerced to
  /// 1000.
  ///
  /// [pageToken] - A page token, received from a previous `ListRepricingRules`
  /// call. Provide this to retrieve the subsequent page. When paginating, all
  /// other parameters provided to `ListRepricingRules` must match the call that
  /// provided the page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListRepricingRulesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListRepricingRulesResponse> list(
    core.String merchantId, {
    core.String? countryCode,
    core.String? languageCode,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (countryCode != null) 'countryCode': [countryCode],
      if (languageCode != null) 'languageCode': [languageCode],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/repricingrules';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListRepricingRulesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a repricing rule in your Merchant Center account.
  ///
  /// All mutable fields will be overwritten in each update request. In each
  /// update, you must provide all required mutable fields, or an error will be
  /// thrown. If you do not provide an optional field in the update request, if
  /// that field currently exists, it will be deleted from the rule.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant who owns the repricing
  /// rule.
  ///
  /// [ruleId] - Required. The id of the rule to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RepricingRule].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RepricingRule> patch(
    RepricingRule request,
    core.String merchantId,
    core.String ruleId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/repricingrules/' +
        commons.escapeVariable('$ruleId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return RepricingRule.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class RepricingrulesRepricingreportsResource {
  final commons.ApiRequester _requester;

  RepricingrulesRepricingreportsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists the metrics report for a given Repricing rule.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. Id of the merchant who owns the Repricing rule.
  ///
  /// [ruleId] - Required. Id of the Repricing rule.
  ///
  /// [endDate] - Gets Repricing reports on and before this date in the
  /// merchant's timezone. You can only retrieve data up to 7 days ago (default)
  /// or earlier. Format: YYYY-MM-DD.
  ///
  /// [pageSize] - Maximum number of daily reports to return. Each report
  /// includes data from a single 24-hour period. The page size defaults to 50
  /// and values above 1000 are coerced to 1000. This service may return fewer
  /// days than this value, for example, if the time between your start and end
  /// date is less than page size.
  ///
  /// [pageToken] - Token (if provided) to retrieve the subsequent page. All
  /// other parameters must match the original call that provided the page
  /// token.
  ///
  /// [startDate] - Gets Repricing reports on and after this date in the
  /// merchant's timezone, up to one year ago. Do not use a start date later
  /// than 7 days ago (default). Format: YYYY-MM-DD.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListRepricingRuleReportsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListRepricingRuleReportsResponse> list(
    core.String merchantId,
    core.String ruleId, {
    core.String? endDate,
    core.int? pageSize,
    core.String? pageToken,
    core.String? startDate,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (endDate != null) 'endDate': [endDate],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (startDate != null) 'startDate': [startDate],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/repricingrules/' +
        commons.escapeVariable('$ruleId') +
        '/repricingreports';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListRepricingRuleReportsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ReturnaddressResource {
  final commons.ApiRequester _requester;

  ReturnaddressResource(commons.ApiRequester client) : _requester = client;

  /// Batches multiple return address related calls in a single request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReturnaddressCustomBatchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReturnaddressCustomBatchResponse> custombatch(
    ReturnaddressCustomBatchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'returnaddress/batch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ReturnaddressCustomBatchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a return address for the given Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The Merchant Center account from which to delete the given
  /// return address.
  ///
  /// [returnAddressId] - Return address ID generated by Google.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String merchantId,
    core.String returnAddressId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/returnaddress/' +
        commons.escapeVariable('$returnAddressId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets a return address of the Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The Merchant Center account to get a return address for.
  ///
  /// [returnAddressId] - Return address ID generated by Google.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReturnAddress].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReturnAddress> get(
    core.String merchantId,
    core.String returnAddressId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/returnaddress/' +
        commons.escapeVariable('$returnAddressId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ReturnAddress.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a return address for the Merchant Center account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The Merchant Center account to insert a return address for.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReturnAddress].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReturnAddress> insert(
    ReturnAddress request,
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/returnaddress';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ReturnAddress.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the return addresses of the Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The Merchant Center account to list return addresses for.
  ///
  /// [country] - List only return addresses applicable to the given country of
  /// sale. When omitted, all return addresses are listed.
  ///
  /// [maxResults] - The maximum number of addresses in the response, used for
  /// paging.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReturnaddressListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReturnaddressListResponse> list(
    core.String merchantId, {
    core.String? country,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (country != null) 'country': [country],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/returnaddress';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ReturnaddressListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ReturnpolicyResource {
  final commons.ApiRequester _requester;

  ReturnpolicyResource(commons.ApiRequester client) : _requester = client;

  /// Batches multiple return policy related calls in a single request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReturnpolicyCustomBatchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReturnpolicyCustomBatchResponse> custombatch(
    ReturnpolicyCustomBatchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'returnpolicy/batch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ReturnpolicyCustomBatchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a return policy for the given Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The Merchant Center account from which to delete the given
  /// return policy.
  ///
  /// [returnPolicyId] - Return policy ID generated by Google.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String merchantId,
    core.String returnPolicyId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/returnpolicy/' +
        commons.escapeVariable('$returnPolicyId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets a return policy of the Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The Merchant Center account to get a return policy for.
  ///
  /// [returnPolicyId] - Return policy ID generated by Google.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReturnPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReturnPolicy> get(
    core.String merchantId,
    core.String returnPolicyId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/returnpolicy/' +
        commons.escapeVariable('$returnPolicyId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ReturnPolicy.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a return policy for the Merchant Center account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The Merchant Center account to insert a return policy for.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReturnPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReturnPolicy> insert(
    ReturnPolicy request,
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/returnpolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ReturnPolicy.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the return policies of the Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The Merchant Center account to list return policies for.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReturnpolicyListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReturnpolicyListResponse> list(
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/returnpolicy';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ReturnpolicyListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ReturnpolicyonlineResource {
  final commons.ApiRequester _requester;

  ReturnpolicyonlineResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new return policy.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant for which to retrieve the
  /// return policy online object.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReturnPolicyOnline].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReturnPolicyOnline> create(
    ReturnPolicyOnline request,
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/returnpolicyonline';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ReturnPolicyOnline.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an existing return policy.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant for which to retrieve the
  /// return policy online object.
  ///
  /// [returnPolicyId] - Required. The id of the return policy to delete.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String merchantId,
    core.String returnPolicyId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/returnpolicyonline/' +
        commons.escapeVariable('$returnPolicyId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets an existing return policy.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant for which to retrieve the
  /// return policy online object.
  ///
  /// [returnPolicyId] - Required. The id of the return policy to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReturnPolicyOnline].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReturnPolicyOnline> get(
    core.String merchantId,
    core.String returnPolicyId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/returnpolicyonline/' +
        commons.escapeVariable('$returnPolicyId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ReturnPolicyOnline.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all existing return policies.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant for which to retrieve the
  /// return policy online object.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListReturnPolicyOnlineResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListReturnPolicyOnlineResponse> list(
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/returnpolicyonline';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListReturnPolicyOnlineResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing return policy.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - Required. The id of the merchant for which to retrieve the
  /// return policy online object.
  ///
  /// [returnPolicyId] - Required. The id of the return policy to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReturnPolicyOnline].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReturnPolicyOnline> patch(
    ReturnPolicyOnline request,
    core.String merchantId,
    core.String returnPolicyId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/returnpolicyonline/' +
        commons.escapeVariable('$returnPolicyId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return ReturnPolicyOnline.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class SettlementreportsResource {
  final commons.ApiRequester _requester;

  SettlementreportsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a settlement report from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The Merchant Center account of the settlement report.
  ///
  /// [settlementId] - The Google-provided ID of the settlement.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SettlementReport].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SettlementReport> get(
    core.String merchantId,
    core.String settlementId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/settlementreports/' +
        commons.escapeVariable('$settlementId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SettlementReport.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of settlement reports from your Merchant Center account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The Merchant Center account to list settlements for.
  ///
  /// [maxResults] - The maximum number of settlements to return in the
  /// response, used for paging. The default value is 200 returns per page, and
  /// the maximum allowed value is 5000 returns per page.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [transferEndDate] - Obtains settlements which have transactions before
  /// this date (inclusively), in ISO 8601 format.
  ///
  /// [transferStartDate] - Obtains settlements which have transactions after
  /// this date (inclusively), in ISO 8601 format.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SettlementreportsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SettlementreportsListResponse> list(
    core.String merchantId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? transferEndDate,
    core.String? transferStartDate,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (transferEndDate != null) 'transferEndDate': [transferEndDate],
      if (transferStartDate != null) 'transferStartDate': [transferStartDate],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/settlementreports';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SettlementreportsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class SettlementtransactionsResource {
  final commons.ApiRequester _requester;

  SettlementtransactionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Retrieves a list of transactions for the settlement.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The Merchant Center account to list transactions for.
  ///
  /// [settlementId] - The Google-provided ID of the settlement.
  ///
  /// [maxResults] - The maximum number of transactions to return in the
  /// response, used for paging. The default value is 200 transactions per page,
  /// and the maximum allowed value is 5000 transactions per page.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [transactionIds] - The list of transactions to return. If not set, all
  /// transactions will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SettlementtransactionsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SettlementtransactionsListResponse> list(
    core.String merchantId,
    core.String settlementId, {
    core.int? maxResults,
    core.String? pageToken,
    core.List<core.String>? transactionIds,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (transactionIds != null) 'transactionIds': transactionIds,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/settlementreports/' +
        commons.escapeVariable('$settlementId') +
        '/transactions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SettlementtransactionsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ShippingsettingsResource {
  final commons.ApiRequester _requester;

  ShippingsettingsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves and updates the shipping settings of multiple accounts in a
  /// single request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ShippingsettingsCustomBatchResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ShippingsettingsCustomBatchResponse> custombatch(
    ShippingsettingsCustomBatchRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'shippingsettings/batch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ShippingsettingsCustomBatchResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the shipping settings of the account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account for which to get/update shipping
  /// settings.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ShippingSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ShippingSettings> get(
    core.String merchantId,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/shippingsettings/' +
        commons.escapeVariable('$accountId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ShippingSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves supported carriers and carrier services for an account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account for which to retrieve the supported
  /// carriers.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ShippingsettingsGetSupportedCarriersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ShippingsettingsGetSupportedCarriersResponse>
      getsupportedcarriers(
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/supportedCarriers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ShippingsettingsGetSupportedCarriersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves supported holidays for an account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account for which to retrieve the supported
  /// holidays.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ShippingsettingsGetSupportedHolidaysResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ShippingsettingsGetSupportedHolidaysResponse>
      getsupportedholidays(
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/supportedHolidays';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ShippingsettingsGetSupportedHolidaysResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves supported pickup services for an account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the account for which to retrieve the supported
  /// pickup services.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ShippingsettingsGetSupportedPickupServicesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ShippingsettingsGetSupportedPickupServicesResponse>
      getsupportedpickupservices(
    core.String merchantId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        commons.escapeVariable('$merchantId') + '/supportedPickupServices';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ShippingsettingsGetSupportedPickupServicesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the shipping settings of the sub-accounts in your Merchant Center
  /// account.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. This must be a multi-client
  /// account.
  ///
  /// [maxResults] - The maximum number of shipping settings to return in the
  /// response, used for paging.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ShippingsettingsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ShippingsettingsListResponse> list(
    core.String merchantId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') + '/shippingsettings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ShippingsettingsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the shipping settings of the account.
  ///
  /// Any fields that are not provided are deleted from the resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [merchantId] - The ID of the managing account. If this parameter is not
  /// the same as accountId, then this account must be a multi-client account
  /// and `accountId` must be the ID of a sub-account of this account.
  ///
  /// [accountId] - The ID of the account for which to get/update shipping
  /// settings.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ShippingSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ShippingSettings> update(
    ShippingSettings request,
    core.String merchantId,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$merchantId') +
        '/shippingsettings/' +
        commons.escapeVariable('$accountId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return ShippingSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Account data.
///
/// After the creation of a new account it may take a few minutes before it is
/// fully operational. The methods delete, insert, and update require the admin
/// role.
class Account {
  /// Linked Ads accounts that are active or pending approval.
  ///
  /// To create a new link request, add a new link with status `active` to the
  /// list. It will remain in a `pending` state until approved or rejected
  /// either in the Ads interface or through the AdWords API. To delete an
  /// active link, or to cancel a link request, remove it from the list.
  core.List<AccountAdsLink>? adsLinks;

  /// Indicates whether the merchant sells adult content.
  core.bool? adultContent;

  /// Automatically created label IDs that are assigned to the account by CSS
  /// Center.
  core.List<core.String>? automaticLabelIds;

  /// The business information of the account.
  AccountBusinessInformation? businessInformation;

  /// ID of CSS the account belongs to.
  core.String? cssId;

  /// The GMB account which is linked or in the process of being linked with the
  /// Merchant Center account.
  AccountGoogleMyBusinessLink? googleMyBusinessLink;

  /// Required for update.
  ///
  /// Merchant Center account ID.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#account`"
  core.String? kind;

  /// Manually created label IDs that are assigned to the account by CSS.
  core.List<core.String>? labelIds;

  /// Display name for the account.
  ///
  /// Required.
  core.String? name;

  /// Client-specific, locally-unique, internal ID for the child account.
  core.String? sellerId;

  /// Users with access to the account.
  ///
  /// Every account (except for subaccounts) must have at least one admin user.
  core.List<AccountUser>? users;

  /// The merchant's website.
  core.String? websiteUrl;

  /// Linked YouTube channels that are active or pending approval.
  ///
  /// To create a new link request, add a new link with status `active` to the
  /// list. It will remain in a `pending` state until approved or rejected in
  /// the YT Creator Studio interface. To delete an active link, or to cancel a
  /// link request, remove it from the list.
  core.List<AccountYouTubeChannelLink>? youtubeChannelLinks;

  Account();

  Account.fromJson(core.Map _json) {
    if (_json.containsKey('adsLinks')) {
      adsLinks = (_json['adsLinks'] as core.List)
          .map<AccountAdsLink>((value) => AccountAdsLink.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('adultContent')) {
      adultContent = _json['adultContent'] as core.bool;
    }
    if (_json.containsKey('automaticLabelIds')) {
      automaticLabelIds = (_json['automaticLabelIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('businessInformation')) {
      businessInformation = AccountBusinessInformation.fromJson(
          _json['businessInformation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('cssId')) {
      cssId = _json['cssId'] as core.String;
    }
    if (_json.containsKey('googleMyBusinessLink')) {
      googleMyBusinessLink = AccountGoogleMyBusinessLink.fromJson(
          _json['googleMyBusinessLink'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('labelIds')) {
      labelIds = (_json['labelIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('sellerId')) {
      sellerId = _json['sellerId'] as core.String;
    }
    if (_json.containsKey('users')) {
      users = (_json['users'] as core.List)
          .map<AccountUser>((value) => AccountUser.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('websiteUrl')) {
      websiteUrl = _json['websiteUrl'] as core.String;
    }
    if (_json.containsKey('youtubeChannelLinks')) {
      youtubeChannelLinks = (_json['youtubeChannelLinks'] as core.List)
          .map<AccountYouTubeChannelLink>((value) =>
              AccountYouTubeChannelLink.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adsLinks != null)
          'adsLinks': adsLinks!.map((value) => value.toJson()).toList(),
        if (adultContent != null) 'adultContent': adultContent!,
        if (automaticLabelIds != null) 'automaticLabelIds': automaticLabelIds!,
        if (businessInformation != null)
          'businessInformation': businessInformation!.toJson(),
        if (cssId != null) 'cssId': cssId!,
        if (googleMyBusinessLink != null)
          'googleMyBusinessLink': googleMyBusinessLink!.toJson(),
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (labelIds != null) 'labelIds': labelIds!,
        if (name != null) 'name': name!,
        if (sellerId != null) 'sellerId': sellerId!,
        if (users != null)
          'users': users!.map((value) => value.toJson()).toList(),
        if (websiteUrl != null) 'websiteUrl': websiteUrl!,
        if (youtubeChannelLinks != null)
          'youtubeChannelLinks':
              youtubeChannelLinks!.map((value) => value.toJson()).toList(),
      };
}

class AccountAddress {
  /// CLDR country code (e.g. "US").
  ///
  /// This value cannot be set for a sub-account of an MCA. All MCA sub-accounts
  /// inherit the country of their parent MCA.
  core.String? country;

  /// City, town or commune.
  ///
  /// May also include dependent localities or sublocalities (e.g. neighborhoods
  /// or suburbs).
  core.String? locality;

  /// Postal code or ZIP (e.g. "94043").
  core.String? postalCode;

  /// Top-level administrative subdivision of the country.
  ///
  /// For example, a state like California ("CA") or a province like Quebec
  /// ("QC").
  core.String? region;

  /// Street-level part of the address.
  core.String? streetAddress;

  AccountAddress();

  AccountAddress.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('locality')) {
      locality = _json['locality'] as core.String;
    }
    if (_json.containsKey('postalCode')) {
      postalCode = _json['postalCode'] as core.String;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('streetAddress')) {
      streetAddress = _json['streetAddress'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (locality != null) 'locality': locality!,
        if (postalCode != null) 'postalCode': postalCode!,
        if (region != null) 'region': region!,
        if (streetAddress != null) 'streetAddress': streetAddress!,
      };
}

class AccountAdsLink {
  /// Customer ID of the Ads account.
  core.String? adsId;

  /// Status of the link between this Merchant Center account and the Ads
  /// account.
  ///
  /// Upon retrieval, it represents the actual status of the link and can be
  /// either `active` if it was approved in Google Ads or `pending` if it's
  /// pending approval. Upon insertion, it represents the *intended* status of
  /// the link. Re-uploading a link with status `active` when it's still pending
  /// or with status `pending` when it's already active will have no effect: the
  /// status will remain unchanged. Re-uploading a link with deprecated status
  /// `inactive` is equivalent to not submitting the link at all and will delete
  /// the link if it was active or cancel the link request if it was pending.
  /// Acceptable values are: - "`active`" - "`pending`"
  core.String? status;

  AccountAdsLink();

  AccountAdsLink.fromJson(core.Map _json) {
    if (_json.containsKey('adsId')) {
      adsId = _json['adsId'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adsId != null) 'adsId': adsId!,
        if (status != null) 'status': status!,
      };
}

class AccountBusinessInformation {
  /// The address of the business.
  AccountAddress? address;

  /// The customer service information of the business.
  AccountCustomerService? customerService;

  /// The phone number of the business.
  core.String? phoneNumber;

  AccountBusinessInformation();

  AccountBusinessInformation.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = AccountAddress.fromJson(
          _json['address'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('customerService')) {
      customerService = AccountCustomerService.fromJson(
          _json['customerService'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!.toJson(),
        if (customerService != null)
          'customerService': customerService!.toJson(),
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
      };
}

/// Credentials allowing Google to call a partner's API on behalf of a merchant.
class AccountCredentials {
  /// An OAuth access token.
  core.String? accessToken;

  /// The amount of time, in seconds, after which the access token is no longer
  /// valid.
  core.String? expiresIn;

  /// Indicates to Google how Google should use these OAuth tokens.
  /// Possible string values are:
  /// - "ACCOUNT_CREDENTIALS_PURPOSE_UNSPECIFIED" : Unknown purpose.
  /// - "SHOPIFY_ORDER_MANAGEMENT" : The credentials allow Google to manage
  /// Shopify orders on behalf of the merchant.
  core.String? purpose;

  AccountCredentials();

  AccountCredentials.fromJson(core.Map _json) {
    if (_json.containsKey('accessToken')) {
      accessToken = _json['accessToken'] as core.String;
    }
    if (_json.containsKey('expiresIn')) {
      expiresIn = _json['expiresIn'] as core.String;
    }
    if (_json.containsKey('purpose')) {
      purpose = _json['purpose'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessToken != null) 'accessToken': accessToken!,
        if (expiresIn != null) 'expiresIn': expiresIn!,
        if (purpose != null) 'purpose': purpose!,
      };
}

class AccountCustomerService {
  /// Customer service email.
  core.String? email;

  /// Customer service phone number.
  core.String? phoneNumber;

  /// Customer service URL.
  core.String? url;

  AccountCustomerService();

  AccountCustomerService.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
        if (url != null) 'url': url!,
      };
}

class AccountGoogleMyBusinessLink {
  /// The ID of the GMB account.
  ///
  /// If this is provided, then `gmbEmail` is ignored. The value of this field
  /// should match the `accountId` used by the GMB API.
  core.String? gmbAccountId;

  /// The GMB email address of which a specific account within a GMB account.
  ///
  /// A sample account within a GMB account could be a business account with set
  /// of locations, managed under the GMB account.
  core.String? gmbEmail;

  /// Status of the link between this Merchant Center account and the GMB
  /// account.
  ///
  /// Acceptable values are: - "`active`" - "`pending`"
  core.String? status;

  AccountGoogleMyBusinessLink();

  AccountGoogleMyBusinessLink.fromJson(core.Map _json) {
    if (_json.containsKey('gmbAccountId')) {
      gmbAccountId = _json['gmbAccountId'] as core.String;
    }
    if (_json.containsKey('gmbEmail')) {
      gmbEmail = _json['gmbEmail'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gmbAccountId != null) 'gmbAccountId': gmbAccountId!,
        if (gmbEmail != null) 'gmbEmail': gmbEmail!,
        if (status != null) 'status': status!,
      };
}

class AccountIdentifier {
  /// The aggregator ID, set for aggregators and subaccounts (in that case, it
  /// represents the aggregator of the subaccount).
  core.String? aggregatorId;

  /// The merchant account ID, set for individual accounts and subaccounts.
  core.String? merchantId;

  AccountIdentifier();

  AccountIdentifier.fromJson(core.Map _json) {
    if (_json.containsKey('aggregatorId')) {
      aggregatorId = _json['aggregatorId'] as core.String;
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aggregatorId != null) 'aggregatorId': aggregatorId!,
        if (merchantId != null) 'merchantId': merchantId!,
      };
}

/// Label assigned by CSS domain or CSS group to one of its sub-accounts.
class AccountLabel {
  /// The ID of account this label belongs to.
  ///
  /// Immutable.
  core.String? accountId;

  /// The description of this label.
  core.String? description;

  /// The ID of the label.
  ///
  /// Output only.
  core.String? labelId;

  /// The type of this label.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "LABEL_TYPE_UNSPECIFIED" : Unknown label type.
  /// - "MANUAL" : Indicates that the label was created manually.
  /// - "AUTOMATIC" : Indicates that the label was created automatically by CSS
  /// Center.
  core.String? labelType;

  /// The display name of this label.
  core.String? name;

  AccountLabel();

  AccountLabel.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('labelId')) {
      labelId = _json['labelId'] as core.String;
    }
    if (_json.containsKey('labelType')) {
      labelType = _json['labelType'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (description != null) 'description': description!,
        if (labelId != null) 'labelId': labelId!,
        if (labelType != null) 'labelType': labelType!,
        if (name != null) 'name': name!,
      };
}

///  The return carrier information.
///
/// This service is designed for merchants enrolled in the Buy on Google
/// program.
class AccountReturnCarrier {
  /// The Google-provided unique carrier ID, used to update the resource.
  ///
  /// Output only. Immutable.
  core.String? carrierAccountId;

  /// Name of the carrier account.
  core.String? carrierAccountName;

  /// Number of the carrier account.
  core.String? carrierAccountNumber;

  /// The carrier code enum.
  ///
  /// Accepts the values FEDEX or UPS.
  /// Possible string values are:
  /// - "CARRIER_CODE_UNSPECIFIED" : Carrier not specified
  /// - "FEDEX" : FedEx carrier
  /// - "UPS" : UPS carrier
  core.String? carrierCode;

  AccountReturnCarrier();

  AccountReturnCarrier.fromJson(core.Map _json) {
    if (_json.containsKey('carrierAccountId')) {
      carrierAccountId = _json['carrierAccountId'] as core.String;
    }
    if (_json.containsKey('carrierAccountName')) {
      carrierAccountName = _json['carrierAccountName'] as core.String;
    }
    if (_json.containsKey('carrierAccountNumber')) {
      carrierAccountNumber = _json['carrierAccountNumber'] as core.String;
    }
    if (_json.containsKey('carrierCode')) {
      carrierCode = _json['carrierCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrierAccountId != null) 'carrierAccountId': carrierAccountId!,
        if (carrierAccountName != null)
          'carrierAccountName': carrierAccountName!,
        if (carrierAccountNumber != null)
          'carrierAccountNumber': carrierAccountNumber!,
        if (carrierCode != null) 'carrierCode': carrierCode!,
      };
}

/// The status of an account, i.e., information about its products, which is
/// computed offline and not returned immediately at insertion time.
class AccountStatus {
  /// The ID of the account for which the status is reported.
  core.String? accountId;

  /// A list of account level issues.
  core.List<AccountStatusAccountLevelIssue>? accountLevelIssues;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#accountStatus`"
  core.String? kind;

  /// List of product-related data by channel, destination, and country.
  ///
  /// Data in this field may be delayed by up to 30 minutes.
  core.List<AccountStatusProducts>? products;

  /// Whether the account's website is claimed or not.
  core.bool? websiteClaimed;

  AccountStatus();

  AccountStatus.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('accountLevelIssues')) {
      accountLevelIssues = (_json['accountLevelIssues'] as core.List)
          .map<AccountStatusAccountLevelIssue>((value) =>
              AccountStatusAccountLevelIssue.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('products')) {
      products = (_json['products'] as core.List)
          .map<AccountStatusProducts>((value) => AccountStatusProducts.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('websiteClaimed')) {
      websiteClaimed = _json['websiteClaimed'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (accountLevelIssues != null)
          'accountLevelIssues':
              accountLevelIssues!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (products != null)
          'products': products!.map((value) => value.toJson()).toList(),
        if (websiteClaimed != null) 'websiteClaimed': websiteClaimed!,
      };
}

class AccountStatusAccountLevelIssue {
  /// Country for which this issue is reported.
  core.String? country;

  /// The destination the issue applies to.
  ///
  /// If this field is empty then the issue applies to all available
  /// destinations.
  core.String? destination;

  /// Additional details about the issue.
  core.String? detail;

  /// The URL of a web page to help resolving this issue.
  core.String? documentation;

  /// Issue identifier.
  core.String? id;

  /// Severity of the issue.
  ///
  /// Acceptable values are: - "`critical`" - "`error`" - "`suggestion`"
  core.String? severity;

  /// Short description of the issue.
  core.String? title;

  AccountStatusAccountLevelIssue();

  AccountStatusAccountLevelIssue.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('destination')) {
      destination = _json['destination'] as core.String;
    }
    if (_json.containsKey('detail')) {
      detail = _json['detail'] as core.String;
    }
    if (_json.containsKey('documentation')) {
      documentation = _json['documentation'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (destination != null) 'destination': destination!,
        if (detail != null) 'detail': detail!,
        if (documentation != null) 'documentation': documentation!,
        if (id != null) 'id': id!,
        if (severity != null) 'severity': severity!,
        if (title != null) 'title': title!,
      };
}

class AccountStatusItemLevelIssue {
  /// The attribute's name, if the issue is caused by a single attribute.
  core.String? attributeName;

  /// The error code of the issue.
  core.String? code;

  /// A short issue description in English.
  core.String? description;

  /// A detailed issue description in English.
  core.String? detail;

  /// The URL of a web page to help with resolving this issue.
  core.String? documentation;

  /// Number of items with this issue.
  core.String? numItems;

  /// Whether the issue can be resolved by the merchant.
  core.String? resolution;

  /// How this issue affects serving of the offer.
  core.String? servability;

  AccountStatusItemLevelIssue();

  AccountStatusItemLevelIssue.fromJson(core.Map _json) {
    if (_json.containsKey('attributeName')) {
      attributeName = _json['attributeName'] as core.String;
    }
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('detail')) {
      detail = _json['detail'] as core.String;
    }
    if (_json.containsKey('documentation')) {
      documentation = _json['documentation'] as core.String;
    }
    if (_json.containsKey('numItems')) {
      numItems = _json['numItems'] as core.String;
    }
    if (_json.containsKey('resolution')) {
      resolution = _json['resolution'] as core.String;
    }
    if (_json.containsKey('servability')) {
      servability = _json['servability'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributeName != null) 'attributeName': attributeName!,
        if (code != null) 'code': code!,
        if (description != null) 'description': description!,
        if (detail != null) 'detail': detail!,
        if (documentation != null) 'documentation': documentation!,
        if (numItems != null) 'numItems': numItems!,
        if (resolution != null) 'resolution': resolution!,
        if (servability != null) 'servability': servability!,
      };
}

class AccountStatusProducts {
  /// The channel the data applies to.
  ///
  /// Acceptable values are: - "`local`" - "`online`"
  core.String? channel;

  /// The country the data applies to.
  core.String? country;

  /// The destination the data applies to.
  core.String? destination;

  /// List of item-level issues.
  core.List<AccountStatusItemLevelIssue>? itemLevelIssues;

  /// Aggregated product statistics.
  AccountStatusStatistics? statistics;

  AccountStatusProducts();

  AccountStatusProducts.fromJson(core.Map _json) {
    if (_json.containsKey('channel')) {
      channel = _json['channel'] as core.String;
    }
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('destination')) {
      destination = _json['destination'] as core.String;
    }
    if (_json.containsKey('itemLevelIssues')) {
      itemLevelIssues = (_json['itemLevelIssues'] as core.List)
          .map<AccountStatusItemLevelIssue>((value) =>
              AccountStatusItemLevelIssue.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('statistics')) {
      statistics = AccountStatusStatistics.fromJson(
          _json['statistics'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (channel != null) 'channel': channel!,
        if (country != null) 'country': country!,
        if (destination != null) 'destination': destination!,
        if (itemLevelIssues != null)
          'itemLevelIssues':
              itemLevelIssues!.map((value) => value.toJson()).toList(),
        if (statistics != null) 'statistics': statistics!.toJson(),
      };
}

class AccountStatusStatistics {
  /// Number of active offers.
  core.String? active;

  /// Number of disapproved offers.
  core.String? disapproved;

  /// Number of expiring offers.
  core.String? expiring;

  /// Number of pending offers.
  core.String? pending;

  AccountStatusStatistics();

  AccountStatusStatistics.fromJson(core.Map _json) {
    if (_json.containsKey('active')) {
      active = _json['active'] as core.String;
    }
    if (_json.containsKey('disapproved')) {
      disapproved = _json['disapproved'] as core.String;
    }
    if (_json.containsKey('expiring')) {
      expiring = _json['expiring'] as core.String;
    }
    if (_json.containsKey('pending')) {
      pending = _json['pending'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (active != null) 'active': active!,
        if (disapproved != null) 'disapproved': disapproved!,
        if (expiring != null) 'expiring': expiring!,
        if (pending != null) 'pending': pending!,
      };
}

/// The tax settings of a merchant account.
///
/// All methods require the admin role.
class AccountTax {
  /// The ID of the account to which these account tax settings belong.
  ///
  /// Required.
  core.String? accountId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#accountTax".
  core.String? kind;

  /// Tax rules.
  ///
  /// Updating the tax rules will enable US taxes (not reversible). Defining no
  /// rules is equivalent to not charging tax at all.
  core.List<AccountTaxTaxRule>? rules;

  AccountTax();

  AccountTax.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('rules')) {
      rules = (_json['rules'] as core.List)
          .map<AccountTaxTaxRule>((value) => AccountTaxTaxRule.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (kind != null) 'kind': kind!,
        if (rules != null)
          'rules': rules!.map((value) => value.toJson()).toList(),
      };
}

/// Tax calculation rule to apply in a state or province (USA only).
class AccountTaxTaxRule {
  /// Country code in which tax is applicable.
  core.String? country;

  /// State (or province) is which the tax is applicable, described by its
  /// location ID (also called criteria ID).
  ///
  /// Required.
  core.String? locationId;

  /// Explicit tax rate in percent, represented as a floating point number
  /// without the percentage character.
  ///
  /// Must not be negative.
  core.String? ratePercent;

  /// If true, shipping charges are also taxed.
  core.bool? shippingTaxed;

  /// Whether the tax rate is taken from a global tax table or specified
  /// explicitly.
  core.bool? useGlobalRate;

  AccountTaxTaxRule();

  AccountTaxTaxRule.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('locationId')) {
      locationId = _json['locationId'] as core.String;
    }
    if (_json.containsKey('ratePercent')) {
      ratePercent = _json['ratePercent'] as core.String;
    }
    if (_json.containsKey('shippingTaxed')) {
      shippingTaxed = _json['shippingTaxed'] as core.bool;
    }
    if (_json.containsKey('useGlobalRate')) {
      useGlobalRate = _json['useGlobalRate'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (locationId != null) 'locationId': locationId!,
        if (ratePercent != null) 'ratePercent': ratePercent!,
        if (shippingTaxed != null) 'shippingTaxed': shippingTaxed!,
        if (useGlobalRate != null) 'useGlobalRate': useGlobalRate!,
      };
}

class AccountUser {
  /// Whether user is an admin.
  core.bool? admin;

  /// User's email address.
  core.String? emailAddress;

  /// Whether user is an order manager.
  core.bool? orderManager;

  /// Whether user can access payment statements.
  core.bool? paymentsAnalyst;

  /// Whether user can manage payment settings.
  core.bool? paymentsManager;

  AccountUser();

  AccountUser.fromJson(core.Map _json) {
    if (_json.containsKey('admin')) {
      admin = _json['admin'] as core.bool;
    }
    if (_json.containsKey('emailAddress')) {
      emailAddress = _json['emailAddress'] as core.String;
    }
    if (_json.containsKey('orderManager')) {
      orderManager = _json['orderManager'] as core.bool;
    }
    if (_json.containsKey('paymentsAnalyst')) {
      paymentsAnalyst = _json['paymentsAnalyst'] as core.bool;
    }
    if (_json.containsKey('paymentsManager')) {
      paymentsManager = _json['paymentsManager'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (admin != null) 'admin': admin!,
        if (emailAddress != null) 'emailAddress': emailAddress!,
        if (orderManager != null) 'orderManager': orderManager!,
        if (paymentsAnalyst != null) 'paymentsAnalyst': paymentsAnalyst!,
        if (paymentsManager != null) 'paymentsManager': paymentsManager!,
      };
}

class AccountYouTubeChannelLink {
  /// Channel ID.
  core.String? channelId;

  /// Status of the link between this Merchant Center account and the YouTube
  /// channel.
  ///
  /// Upon retrieval, it represents the actual status of the link and can be
  /// either `active` if it was approved in YT Creator Studio or `pending` if
  /// it's pending approval. Upon insertion, it represents the *intended* status
  /// of the link. Re-uploading a link with status `active` when it's still
  /// pending or with status `pending` when it's already active will have no
  /// effect: the status will remain unchanged. Re-uploading a link with
  /// deprecated status `inactive` is equivalent to not submitting the link at
  /// all and will delete the link if it was active or cancel the link request
  /// if it was pending.
  core.String? status;

  AccountYouTubeChannelLink();

  AccountYouTubeChannelLink.fromJson(core.Map _json) {
    if (_json.containsKey('channelId')) {
      channelId = _json['channelId'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (channelId != null) 'channelId': channelId!,
        if (status != null) 'status': status!,
      };
}

class AccountsAuthInfoResponse {
  /// The account identifiers corresponding to the authenticated user.
  ///
  /// - For an individual account: only the merchant ID is defined - For an
  /// aggregator: only the aggregator ID is defined - For a subaccount of an
  /// MCA: both the merchant ID and the aggregator ID are defined.
  core.List<AccountIdentifier>? accountIdentifiers;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#accountsAuthInfoResponse".
  core.String? kind;

  AccountsAuthInfoResponse();

  AccountsAuthInfoResponse.fromJson(core.Map _json) {
    if (_json.containsKey('accountIdentifiers')) {
      accountIdentifiers = (_json['accountIdentifiers'] as core.List)
          .map<AccountIdentifier>((value) => AccountIdentifier.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountIdentifiers != null)
          'accountIdentifiers':
              accountIdentifiers!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class AccountsClaimWebsiteResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#accountsClaimWebsiteResponse".
  core.String? kind;

  AccountsClaimWebsiteResponse();

  AccountsClaimWebsiteResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
      };
}

class AccountsCustomBatchRequest {
  /// The request entries to be processed in the batch.
  core.List<AccountsCustomBatchRequestEntry>? entries;

  AccountsCustomBatchRequest();

  AccountsCustomBatchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<AccountsCustomBatchRequestEntry>((value) =>
              AccountsCustomBatchRequestEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

/// A batch entry encoding a single non-batch accounts request.
class AccountsCustomBatchRequestEntry {
  /// The account to create or update.
  ///
  /// Only defined if the method is `insert` or `update`.
  Account? account;

  /// The ID of the targeted account.
  ///
  /// Only defined if the method is not `insert`.
  core.String? accountId;

  /// An entry ID, unique within the batch request.
  core.int? batchId;

  /// Whether the account should be deleted if the account has offers.
  ///
  /// Only applicable if the method is `delete`.
  core.bool? force;

  /// Label IDs for the 'updatelabels' request.
  core.List<core.String>? labelIds;

  /// Details about the `link` request.
  AccountsCustomBatchRequestEntryLinkRequest? linkRequest;

  /// The ID of the managing account.
  core.String? merchantId;

  /// The method of the batch entry.
  ///
  /// Acceptable values are: - "`claimWebsite`" - "`delete`" - "`get`" -
  /// "`insert`" - "`link`" - "`update`"
  core.String? method;

  /// Only applicable if the method is `claimwebsite`.
  ///
  /// Indicates whether or not to take the claim from another account in case
  /// there is a conflict.
  core.bool? overwrite;

  /// Controls which fields are visible.
  ///
  /// Only applicable if the method is 'get'.
  core.String? view;

  AccountsCustomBatchRequestEntry();

  AccountsCustomBatchRequestEntry.fromJson(core.Map _json) {
    if (_json.containsKey('account')) {
      account = Account.fromJson(
          _json['account'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('force')) {
      force = _json['force'] as core.bool;
    }
    if (_json.containsKey('labelIds')) {
      labelIds = (_json['labelIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('linkRequest')) {
      linkRequest = AccountsCustomBatchRequestEntryLinkRequest.fromJson(
          _json['linkRequest'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('overwrite')) {
      overwrite = _json['overwrite'] as core.bool;
    }
    if (_json.containsKey('view')) {
      view = _json['view'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (account != null) 'account': account!.toJson(),
        if (accountId != null) 'accountId': accountId!,
        if (batchId != null) 'batchId': batchId!,
        if (force != null) 'force': force!,
        if (labelIds != null) 'labelIds': labelIds!,
        if (linkRequest != null) 'linkRequest': linkRequest!.toJson(),
        if (merchantId != null) 'merchantId': merchantId!,
        if (method != null) 'method': method!,
        if (overwrite != null) 'overwrite': overwrite!,
        if (view != null) 'view': view!,
      };
}

class AccountsCustomBatchRequestEntryLinkRequest {
  /// Action to perform for this link.
  ///
  /// The `"request"` action is only available to select merchants. Acceptable
  /// values are: - "`approve`" - "`remove`" - "`request`"
  core.String? action;

  /// Type of the link between the two accounts.
  ///
  /// Acceptable values are: - "`channelPartner`" - "`eCommercePlatform`"
  core.String? linkType;

  /// The ID of the linked account.
  core.String? linkedAccountId;

  /// Provided services.
  ///
  /// Acceptable values are: - "`shoppingAdsProductManagement`" -
  /// "`shoppingActionsProductManagement`" - "`shoppingActionsOrderManagement`"
  core.List<core.String>? services;

  AccountsCustomBatchRequestEntryLinkRequest();

  AccountsCustomBatchRequestEntryLinkRequest.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('linkType')) {
      linkType = _json['linkType'] as core.String;
    }
    if (_json.containsKey('linkedAccountId')) {
      linkedAccountId = _json['linkedAccountId'] as core.String;
    }
    if (_json.containsKey('services')) {
      services = (_json['services'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (linkType != null) 'linkType': linkType!,
        if (linkedAccountId != null) 'linkedAccountId': linkedAccountId!,
        if (services != null) 'services': services!,
      };
}

class AccountsCustomBatchResponse {
  /// The result of the execution of the batch requests.
  core.List<AccountsCustomBatchResponseEntry>? entries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#accountsCustomBatchResponse".
  core.String? kind;

  AccountsCustomBatchResponse();

  AccountsCustomBatchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<AccountsCustomBatchResponseEntry>((value) =>
              AccountsCustomBatchResponseEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// A batch entry encoding a single non-batch accounts response.
class AccountsCustomBatchResponseEntry {
  /// The retrieved, created, or updated account.
  ///
  /// Not defined if the method was `delete`, `claimwebsite` or `link`.
  Account? account;

  /// The ID of the request entry this entry responds to.
  core.int? batchId;

  /// A list of errors defined if and only if the request failed.
  Errors? errors;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#accountsCustomBatchResponseEntry`"
  core.String? kind;

  AccountsCustomBatchResponseEntry();

  AccountsCustomBatchResponseEntry.fromJson(core.Map _json) {
    if (_json.containsKey('account')) {
      account = Account.fromJson(
          _json['account'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('errors')) {
      errors = Errors.fromJson(
          _json['errors'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (account != null) 'account': account!.toJson(),
        if (batchId != null) 'batchId': batchId!,
        if (errors != null) 'errors': errors!.toJson(),
        if (kind != null) 'kind': kind!,
      };
}

class AccountsLinkRequest {
  /// Action to perform for this link.
  ///
  /// The `"request"` action is only available to select merchants. Acceptable
  /// values are: - "`approve`" - "`remove`" - "`request`"
  core.String? action;

  /// Type of the link between the two accounts.
  ///
  /// Acceptable values are: - "`channelPartner`" - "`eCommercePlatform`" -
  /// "`paymentServiceProvider`"
  core.String? linkType;

  /// The ID of the linked account.
  core.String? linkedAccountId;

  /// Additional information required for `paymentServiceProvider` link type.
  PaymentServiceProviderLinkInfo? paymentServiceProviderLinkInfo;

  /// Acceptable values are: - "`shoppingAdsProductManagement`" -
  /// "`shoppingActionsProductManagement`" - "`shoppingActionsOrderManagement`"
  /// - "`paymentProcessing`"
  core.List<core.String>? services;

  AccountsLinkRequest();

  AccountsLinkRequest.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('linkType')) {
      linkType = _json['linkType'] as core.String;
    }
    if (_json.containsKey('linkedAccountId')) {
      linkedAccountId = _json['linkedAccountId'] as core.String;
    }
    if (_json.containsKey('paymentServiceProviderLinkInfo')) {
      paymentServiceProviderLinkInfo = PaymentServiceProviderLinkInfo.fromJson(
          _json['paymentServiceProviderLinkInfo']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('services')) {
      services = (_json['services'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (linkType != null) 'linkType': linkType!,
        if (linkedAccountId != null) 'linkedAccountId': linkedAccountId!,
        if (paymentServiceProviderLinkInfo != null)
          'paymentServiceProviderLinkInfo':
              paymentServiceProviderLinkInfo!.toJson(),
        if (services != null) 'services': services!,
      };
}

class AccountsLinkResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#accountsLinkResponse".
  core.String? kind;

  AccountsLinkResponse();

  AccountsLinkResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
      };
}

class AccountsListLinksResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#accountsListLinksResponse".
  core.String? kind;

  /// The list of available links.
  core.List<LinkedAccount>? links;

  /// The token for the retrieval of the next page of links.
  core.String? nextPageToken;

  AccountsListLinksResponse();

  AccountsListLinksResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('links')) {
      links = (_json['links'] as core.List)
          .map<LinkedAccount>((value) => LinkedAccount.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (links != null)
          'links': links!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class AccountsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#accountsListResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of accounts.
  core.String? nextPageToken;
  core.List<Account>? resources;

  AccountsListResponse();

  AccountsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<Account>((value) =>
              Account.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

class AccountsUpdateLabelsRequest {
  /// The IDs of labels that should be assigned to the account.
  core.List<core.String>? labelIds;

  AccountsUpdateLabelsRequest();

  AccountsUpdateLabelsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('labelIds')) {
      labelIds = (_json['labelIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (labelIds != null) 'labelIds': labelIds!,
      };
}

class AccountsUpdateLabelsResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#accountsUpdateLabelsResponse".
  core.String? kind;

  AccountsUpdateLabelsResponse();

  AccountsUpdateLabelsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
      };
}

class AccountstatusesCustomBatchRequest {
  /// The request entries to be processed in the batch.
  core.List<AccountstatusesCustomBatchRequestEntry>? entries;

  AccountstatusesCustomBatchRequest();

  AccountstatusesCustomBatchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<AccountstatusesCustomBatchRequestEntry>((value) =>
              AccountstatusesCustomBatchRequestEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

/// A batch entry encoding a single non-batch accountstatuses request.
class AccountstatusesCustomBatchRequestEntry {
  /// The ID of the (sub-)account whose status to get.
  core.String? accountId;

  /// An entry ID, unique within the batch request.
  core.int? batchId;

  /// If set, only issues for the specified destinations are returned, otherwise
  /// only issues for the Shopping destination.
  core.List<core.String>? destinations;

  /// The ID of the managing account.
  core.String? merchantId;

  /// The method of the batch entry.
  ///
  /// Acceptable values are: - "`get`"
  core.String? method;

  AccountstatusesCustomBatchRequestEntry();

  AccountstatusesCustomBatchRequestEntry.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('destinations')) {
      destinations = (_json['destinations'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (batchId != null) 'batchId': batchId!,
        if (destinations != null) 'destinations': destinations!,
        if (merchantId != null) 'merchantId': merchantId!,
        if (method != null) 'method': method!,
      };
}

class AccountstatusesCustomBatchResponse {
  /// The result of the execution of the batch requests.
  core.List<AccountstatusesCustomBatchResponseEntry>? entries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#accountstatusesCustomBatchResponse".
  core.String? kind;

  AccountstatusesCustomBatchResponse();

  AccountstatusesCustomBatchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<AccountstatusesCustomBatchResponseEntry>((value) =>
              AccountstatusesCustomBatchResponseEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// A batch entry encoding a single non-batch accountstatuses response.
class AccountstatusesCustomBatchResponseEntry {
  /// The requested account status.
  ///
  /// Defined if and only if the request was successful.
  AccountStatus? accountStatus;

  /// The ID of the request entry this entry responds to.
  core.int? batchId;

  /// A list of errors defined if and only if the request failed.
  Errors? errors;

  AccountstatusesCustomBatchResponseEntry();

  AccountstatusesCustomBatchResponseEntry.fromJson(core.Map _json) {
    if (_json.containsKey('accountStatus')) {
      accountStatus = AccountStatus.fromJson(
          _json['accountStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('errors')) {
      errors = Errors.fromJson(
          _json['errors'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountStatus != null) 'accountStatus': accountStatus!.toJson(),
        if (batchId != null) 'batchId': batchId!,
        if (errors != null) 'errors': errors!.toJson(),
      };
}

class AccountstatusesListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#accountstatusesListResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of account statuses.
  core.String? nextPageToken;
  core.List<AccountStatus>? resources;

  AccountstatusesListResponse();

  AccountstatusesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<AccountStatus>((value) => AccountStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

class AccounttaxCustomBatchRequest {
  /// The request entries to be processed in the batch.
  core.List<AccounttaxCustomBatchRequestEntry>? entries;

  AccounttaxCustomBatchRequest();

  AccounttaxCustomBatchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<AccounttaxCustomBatchRequestEntry>((value) =>
              AccounttaxCustomBatchRequestEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

/// A batch entry encoding a single non-batch accounttax request.
class AccounttaxCustomBatchRequestEntry {
  /// The ID of the account for which to get/update account tax settings.
  core.String? accountId;

  /// The account tax settings to update.
  ///
  /// Only defined if the method is `update`.
  AccountTax? accountTax;

  /// An entry ID, unique within the batch request.
  core.int? batchId;

  /// The ID of the managing account.
  core.String? merchantId;

  /// The method of the batch entry.
  ///
  /// Acceptable values are: - "`get`" - "`update`"
  core.String? method;

  AccounttaxCustomBatchRequestEntry();

  AccounttaxCustomBatchRequestEntry.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('accountTax')) {
      accountTax = AccountTax.fromJson(
          _json['accountTax'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (accountTax != null) 'accountTax': accountTax!.toJson(),
        if (batchId != null) 'batchId': batchId!,
        if (merchantId != null) 'merchantId': merchantId!,
        if (method != null) 'method': method!,
      };
}

class AccounttaxCustomBatchResponse {
  /// The result of the execution of the batch requests.
  core.List<AccounttaxCustomBatchResponseEntry>? entries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#accounttaxCustomBatchResponse".
  core.String? kind;

  AccounttaxCustomBatchResponse();

  AccounttaxCustomBatchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<AccounttaxCustomBatchResponseEntry>((value) =>
              AccounttaxCustomBatchResponseEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// A batch entry encoding a single non-batch accounttax response.
class AccounttaxCustomBatchResponseEntry {
  /// The retrieved or updated account tax settings.
  AccountTax? accountTax;

  /// The ID of the request entry this entry responds to.
  core.int? batchId;

  /// A list of errors defined if and only if the request failed.
  Errors? errors;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#accounttaxCustomBatchResponseEntry`"
  core.String? kind;

  AccounttaxCustomBatchResponseEntry();

  AccounttaxCustomBatchResponseEntry.fromJson(core.Map _json) {
    if (_json.containsKey('accountTax')) {
      accountTax = AccountTax.fromJson(
          _json['accountTax'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('errors')) {
      errors = Errors.fromJson(
          _json['errors'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountTax != null) 'accountTax': accountTax!.toJson(),
        if (batchId != null) 'batchId': batchId!,
        if (errors != null) 'errors': errors!.toJson(),
        if (kind != null) 'kind': kind!,
      };
}

class AccounttaxListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#accounttaxListResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of account tax settings.
  core.String? nextPageToken;
  core.List<AccountTax>? resources;

  AccounttaxListResponse();

  AccounttaxListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<AccountTax>((value) =>
              AccountTax.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

/// Request message for the ActivateProgram method.
class ActivateBuyOnGoogleProgramRequest {
  ActivateBuyOnGoogleProgramRequest();

  ActivateBuyOnGoogleProgramRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

class Amount {
  /// The pre-tax or post-tax price depending on the location of the order.
  ///
  /// Required.
  Price? priceAmount;

  /// Tax value.
  ///
  /// Required.
  Price? taxAmount;

  Amount();

  Amount.fromJson(core.Map _json) {
    if (_json.containsKey('priceAmount')) {
      priceAmount = Price.fromJson(
          _json['priceAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('taxAmount')) {
      taxAmount = Price.fromJson(
          _json['taxAmount'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (priceAmount != null) 'priceAmount': priceAmount!.toJson(),
        if (taxAmount != null) 'taxAmount': taxAmount!.toJson(),
      };
}

class BusinessDayConfig {
  /// Regular business days.
  ///
  /// May not be empty.
  core.List<core.String>? businessDays;

  BusinessDayConfig();

  BusinessDayConfig.fromJson(core.Map _json) {
    if (_json.containsKey('businessDays')) {
      businessDays = (_json['businessDays'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (businessDays != null) 'businessDays': businessDays!,
      };
}

/// Response message for the GetProgramStatus method.
class BuyOnGoogleProgramStatus {
  /// The customer service pending email.
  core.String? customerServicePendingEmail;

  /// The customer service verified email.
  core.String? customerServiceVerifiedEmail;

  /// The current participation stage for the program.
  /// Possible string values are:
  /// - "PROGRAM_PARTICIPATION_STAGE_UNSPECIFIED" : Default value when
  /// participation stage is not set.
  /// - "NOT_ELIGIBLE" : Merchant is not eligible for onboarding to a given
  /// program in a specific region code.
  /// - "ELIGIBLE" : Merchant is eligible for onboarding to a given program in a
  /// specific region code.
  /// - "ONBOARDING" : Merchant is onboarding to a given program in a specific
  /// region code.
  /// - "ELIGIBLE_FOR_REVIEW" : Merchant fulfilled all the requirements and is
  /// ready to request review in a specific region code.
  /// - "PENDING_REVIEW" : Merchant is waiting for the review to be completed in
  /// a specific region code.
  /// - "REVIEW_DISAPPROVED" : The review for a merchant has been rejected in a
  /// specific region code.
  /// - "ACTIVE" : Merchant's program participation is active for a specific
  /// region code.
  /// - "PAUSED" : Participation has been paused.
  core.String? participationStage;

  BuyOnGoogleProgramStatus();

  BuyOnGoogleProgramStatus.fromJson(core.Map _json) {
    if (_json.containsKey('customerServicePendingEmail')) {
      customerServicePendingEmail =
          _json['customerServicePendingEmail'] as core.String;
    }
    if (_json.containsKey('customerServiceVerifiedEmail')) {
      customerServiceVerifiedEmail =
          _json['customerServiceVerifiedEmail'] as core.String;
    }
    if (_json.containsKey('participationStage')) {
      participationStage = _json['participationStage'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customerServicePendingEmail != null)
          'customerServicePendingEmail': customerServicePendingEmail!,
        if (customerServiceVerifiedEmail != null)
          'customerServiceVerifiedEmail': customerServiceVerifiedEmail!,
        if (participationStage != null)
          'participationStage': participationStage!,
      };
}

class CarrierRate {
  /// Carrier service, such as `"UPS"` or `"Fedex"`.
  ///
  /// The list of supported carriers can be retrieved via the
  /// `getSupportedCarriers` method. Required.
  core.String? carrierName;

  /// Carrier service, such as `"ground"` or `"2 days"`.
  ///
  /// The list of supported services for a carrier can be retrieved via the
  /// `getSupportedCarriers` method. Required.
  core.String? carrierService;

  /// Additive shipping rate modifier.
  ///
  /// Can be negative. For example `{ "value": "1", "currency" : "USD" }` adds
  /// $1 to the rate, `{ "value": "-3", "currency" : "USD" }` removes $3 from
  /// the rate. Optional.
  Price? flatAdjustment;

  /// Name of the carrier rate.
  ///
  /// Must be unique per rate group. Required.
  core.String? name;

  /// Shipping origin for this carrier rate.
  ///
  /// Required.
  core.String? originPostalCode;

  /// Multiplicative shipping rate modifier as a number in decimal notation.
  ///
  /// Can be negative. For example `"5.4"` increases the rate by 5.4%, `"-3"`
  /// decreases the rate by 3%. Optional.
  core.String? percentageAdjustment;

  CarrierRate();

  CarrierRate.fromJson(core.Map _json) {
    if (_json.containsKey('carrierName')) {
      carrierName = _json['carrierName'] as core.String;
    }
    if (_json.containsKey('carrierService')) {
      carrierService = _json['carrierService'] as core.String;
    }
    if (_json.containsKey('flatAdjustment')) {
      flatAdjustment = Price.fromJson(
          _json['flatAdjustment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('originPostalCode')) {
      originPostalCode = _json['originPostalCode'] as core.String;
    }
    if (_json.containsKey('percentageAdjustment')) {
      percentageAdjustment = _json['percentageAdjustment'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrierName != null) 'carrierName': carrierName!,
        if (carrierService != null) 'carrierService': carrierService!,
        if (flatAdjustment != null) 'flatAdjustment': flatAdjustment!.toJson(),
        if (name != null) 'name': name!,
        if (originPostalCode != null) 'originPostalCode': originPostalCode!,
        if (percentageAdjustment != null)
          'percentageAdjustment': percentageAdjustment!,
      };
}

class CarriersCarrier {
  /// The CLDR country code of the carrier (e.g., "US").
  ///
  /// Always present.
  core.String? country;

  /// A list of services supported for EDD (Estimated Delivery Date)
  /// calculation.
  ///
  /// This is the list of valid values for
  /// WarehouseBasedDeliveryTime.carrierService.
  core.List<core.String>? eddServices;

  /// The name of the carrier (e.g., `"UPS"`).
  ///
  /// Always present.
  core.String? name;

  /// A list of supported services (e.g., `"ground"`) for that carrier.
  ///
  /// Contains at least one service. This is the list of valid values for
  /// CarrierRate.carrierService.
  core.List<core.String>? services;

  CarriersCarrier();

  CarriersCarrier.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('eddServices')) {
      eddServices = (_json['eddServices'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('services')) {
      services = (_json['services'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (eddServices != null) 'eddServices': eddServices!,
        if (name != null) 'name': name!,
        if (services != null) 'services': services!,
      };
}

/// The collection message.
class Collection {
  /// Label that you assign to a collection to help organize bidding and
  /// reporting in Shopping campaigns.
  ///
  /// [Custom label](https://support.google.com/merchants/answer/9674217)
  core.String? customLabel0;

  /// Label that you assign to a collection to help organize bidding and
  /// reporting in Shopping campaigns.
  core.String? customLabel1;

  /// Label that you assign to a collection to help organize bidding and
  /// reporting in Shopping campaigns.
  core.String? customLabel2;

  /// Label that you assign to a collection to help organize bidding and
  /// reporting in Shopping campaigns.
  core.String? customLabel3;

  /// Label that you assign to a collection to help organize bidding and
  /// reporting in Shopping campaigns.
  core.String? customLabel4;

  /// This identifies one or more products associated with the collection.
  ///
  /// Used as a lookup to the corresponding product ID in your product feeds.
  /// Provide a maximum of 100 featuredProduct (for collections). Provide up to
  /// 10 featuredProduct (for Shoppable Images only) with ID and X and Y
  /// coordinates.
  /// [featured_product attribute](https://support.google.com/merchants/answer/9703736)
  core.List<CollectionFeaturedProduct>? featuredProduct;

  /// Your collection's name.
  ///
  /// [headline attribute](https://support.google.com/merchants/answer/9673580)
  core.List<core.String>? headline;

  /// The REST ID of the collection.
  ///
  /// Content API methods that operate on collections take this as their
  /// collectionId parameter. The REST ID for a collection is of the form
  /// collectionId.
  /// [id attribute](https://support.google.com/merchants/answer/9649290)
  ///
  /// Required.
  core.String? id;

  /// The URL of a collection’s image.
  ///
  /// [image_link attribute](https://support.google.com/merchants/answer/9703236)
  core.List<core.String>? imageLink;

  /// The language of a collection and the language of any featured products
  /// linked to the collection.
  ///
  /// [language attribute](https://support.google.com/merchants/answer/9673781)
  core.String? language;

  /// A collection’s landing page.
  ///
  /// URL directly linking to your collection's page on your website.
  /// [link attribute](https://support.google.com/merchants/answer/9673983)
  core.String? link;

  /// A collection’s mobile-optimized landing page when you have a different URL
  /// for mobile and desktop traffic.
  ///
  /// [mobile_link attribute](https://support.google.com/merchants/answer/9646123)
  core.String? mobileLink;

  /// [product_country attribute](https://support.google.com/merchants/answer/9674155)
  core.String? productCountry;

  Collection();

  Collection.fromJson(core.Map _json) {
    if (_json.containsKey('customLabel0')) {
      customLabel0 = _json['customLabel0'] as core.String;
    }
    if (_json.containsKey('customLabel1')) {
      customLabel1 = _json['customLabel1'] as core.String;
    }
    if (_json.containsKey('customLabel2')) {
      customLabel2 = _json['customLabel2'] as core.String;
    }
    if (_json.containsKey('customLabel3')) {
      customLabel3 = _json['customLabel3'] as core.String;
    }
    if (_json.containsKey('customLabel4')) {
      customLabel4 = _json['customLabel4'] as core.String;
    }
    if (_json.containsKey('featuredProduct')) {
      featuredProduct = (_json['featuredProduct'] as core.List)
          .map<CollectionFeaturedProduct>((value) =>
              CollectionFeaturedProduct.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('headline')) {
      headline = (_json['headline'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('imageLink')) {
      imageLink = (_json['imageLink'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('language')) {
      language = _json['language'] as core.String;
    }
    if (_json.containsKey('link')) {
      link = _json['link'] as core.String;
    }
    if (_json.containsKey('mobileLink')) {
      mobileLink = _json['mobileLink'] as core.String;
    }
    if (_json.containsKey('productCountry')) {
      productCountry = _json['productCountry'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customLabel0 != null) 'customLabel0': customLabel0!,
        if (customLabel1 != null) 'customLabel1': customLabel1!,
        if (customLabel2 != null) 'customLabel2': customLabel2!,
        if (customLabel3 != null) 'customLabel3': customLabel3!,
        if (customLabel4 != null) 'customLabel4': customLabel4!,
        if (featuredProduct != null)
          'featuredProduct':
              featuredProduct!.map((value) => value.toJson()).toList(),
        if (headline != null) 'headline': headline!,
        if (id != null) 'id': id!,
        if (imageLink != null) 'imageLink': imageLink!,
        if (language != null) 'language': language!,
        if (link != null) 'link': link!,
        if (mobileLink != null) 'mobileLink': mobileLink!,
        if (productCountry != null) 'productCountry': productCountry!,
      };
}

/// The message for FeaturedProduct.
///
/// [FeaturedProduct](https://support.google.com/merchants/answer/9703736)
class CollectionFeaturedProduct {
  /// The unique identifier for the product item.
  core.String? offerId;

  /// X-coordinate of the product callout on the Shoppable Image.
  ///
  /// Required.
  core.double? x;

  /// Y-coordinate of the product callout on the Shoppable Image.
  ///
  /// Required.
  core.double? y;

  CollectionFeaturedProduct();

  CollectionFeaturedProduct.fromJson(core.Map _json) {
    if (_json.containsKey('offerId')) {
      offerId = _json['offerId'] as core.String;
    }
    if (_json.containsKey('x')) {
      x = (_json['x'] as core.num).toDouble();
    }
    if (_json.containsKey('y')) {
      y = (_json['y'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (offerId != null) 'offerId': offerId!,
        if (x != null) 'x': x!,
        if (y != null) 'y': y!,
      };
}

/// The collectionstatus message.
class CollectionStatus {
  /// A list of all issues associated with the collection.
  core.List<CollectionStatusItemLevelIssue>? collectionLevelIssuses;

  /// Date on which the collection has been created in
  /// [ISO 8601](http://en.wikipedia.org/wiki/ISO_8601) format: Date, time, and
  /// offset, e.g. "2020-01-02T09:00:00+01:00" or "2020-01-02T09:00:00Z"
  core.String? creationDate;

  /// The intended destinations for the collection.
  core.List<CollectionStatusDestinationStatus>? destinationStatuses;

  /// The ID of the collection for which status is reported.
  ///
  /// Required.
  core.String? id;

  /// Date on which the collection has been last updated in
  /// [ISO 8601](http://en.wikipedia.org/wiki/ISO_8601) format: Date, time, and
  /// offset, e.g. "2020-01-02T09:00:00+01:00" or "2020-01-02T09:00:00Z"
  core.String? lastUpdateDate;

  CollectionStatus();

  CollectionStatus.fromJson(core.Map _json) {
    if (_json.containsKey('collectionLevelIssuses')) {
      collectionLevelIssuses = (_json['collectionLevelIssuses'] as core.List)
          .map<CollectionStatusItemLevelIssue>((value) =>
              CollectionStatusItemLevelIssue.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('creationDate')) {
      creationDate = _json['creationDate'] as core.String;
    }
    if (_json.containsKey('destinationStatuses')) {
      destinationStatuses = (_json['destinationStatuses'] as core.List)
          .map<CollectionStatusDestinationStatus>((value) =>
              CollectionStatusDestinationStatus.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('lastUpdateDate')) {
      lastUpdateDate = _json['lastUpdateDate'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (collectionLevelIssuses != null)
          'collectionLevelIssuses':
              collectionLevelIssuses!.map((value) => value.toJson()).toList(),
        if (creationDate != null) 'creationDate': creationDate!,
        if (destinationStatuses != null)
          'destinationStatuses':
              destinationStatuses!.map((value) => value.toJson()).toList(),
        if (id != null) 'id': id!,
        if (lastUpdateDate != null) 'lastUpdateDate': lastUpdateDate!,
      };
}

/// Destination status message.
class CollectionStatusDestinationStatus {
  /// The name of the destination
  core.String? destination;

  /// The status for the specified destination.
  core.String? status;

  CollectionStatusDestinationStatus();

  CollectionStatusDestinationStatus.fromJson(core.Map _json) {
    if (_json.containsKey('destination')) {
      destination = _json['destination'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destination != null) 'destination': destination!,
        if (status != null) 'status': status!,
      };
}

/// Issue associated with the collection.
class CollectionStatusItemLevelIssue {
  /// The attribute's name, if the issue is caused by a single attribute.
  core.String? attributeName;

  /// The error code of the issue.
  core.String? code;

  /// A short issue description in English.
  core.String? description;

  /// The destination the issue applies to.
  core.String? destination;

  /// A detailed issue description in English.
  core.String? detail;

  /// The URL of a web page to help with resolving this issue.
  core.String? documentation;

  /// Whether the issue can be resolved by the merchant.
  core.String? resolution;

  /// How this issue affects the serving of the collection.
  core.String? servability;

  CollectionStatusItemLevelIssue();

  CollectionStatusItemLevelIssue.fromJson(core.Map _json) {
    if (_json.containsKey('attributeName')) {
      attributeName = _json['attributeName'] as core.String;
    }
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('destination')) {
      destination = _json['destination'] as core.String;
    }
    if (_json.containsKey('detail')) {
      detail = _json['detail'] as core.String;
    }
    if (_json.containsKey('documentation')) {
      documentation = _json['documentation'] as core.String;
    }
    if (_json.containsKey('resolution')) {
      resolution = _json['resolution'] as core.String;
    }
    if (_json.containsKey('servability')) {
      servability = _json['servability'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributeName != null) 'attributeName': attributeName!,
        if (code != null) 'code': code!,
        if (description != null) 'description': description!,
        if (destination != null) 'destination': destination!,
        if (detail != null) 'detail': detail!,
        if (documentation != null) 'documentation': documentation!,
        if (resolution != null) 'resolution': resolution!,
        if (servability != null) 'servability': servability!,
      };
}

/// Information about CSS domain.
class Css {
  /// The CSS domain ID.
  ///
  /// Output only. Immutable.
  core.String? cssDomainId;

  /// The ID of the CSS group this CSS domain is affiliated with.
  ///
  /// Only populated for CSS group users.
  ///
  /// Output only. Immutable.
  core.String? cssGroupId;

  /// The CSS domain's display name, used when space is constrained.
  ///
  /// Output only. Immutable.
  core.String? displayName;

  /// The CSS domain's full name.
  ///
  /// Output only. Immutable.
  core.String? fullName;

  /// The CSS domain's homepage.
  ///
  /// Output only. Immutable.
  core.String? homepageUri;

  /// A list of label IDs that are assigned to this CSS domain by its CSS group.
  ///
  /// Only populated for CSS group users.
  core.List<core.String>? labelIds;

  Css();

  Css.fromJson(core.Map _json) {
    if (_json.containsKey('cssDomainId')) {
      cssDomainId = _json['cssDomainId'] as core.String;
    }
    if (_json.containsKey('cssGroupId')) {
      cssGroupId = _json['cssGroupId'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('fullName')) {
      fullName = _json['fullName'] as core.String;
    }
    if (_json.containsKey('homepageUri')) {
      homepageUri = _json['homepageUri'] as core.String;
    }
    if (_json.containsKey('labelIds')) {
      labelIds = (_json['labelIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cssDomainId != null) 'cssDomainId': cssDomainId!,
        if (cssGroupId != null) 'cssGroupId': cssGroupId!,
        if (displayName != null) 'displayName': displayName!,
        if (fullName != null) 'fullName': fullName!,
        if (homepageUri != null) 'homepageUri': homepageUri!,
        if (labelIds != null) 'labelIds': labelIds!,
      };
}

class CustomAttribute {
  /// Subattributes within this attribute group.
  ///
  /// Exactly one of value or groupValues must be provided.
  core.List<CustomAttribute>? groupValues;

  /// The name of the attribute.
  ///
  /// Underscores will be replaced by spaces upon insertion.
  core.String? name;

  /// The value of the attribute.
  core.String? value;

  CustomAttribute();

  CustomAttribute.fromJson(core.Map _json) {
    if (_json.containsKey('groupValues')) {
      groupValues = (_json['groupValues'] as core.List)
          .map<CustomAttribute>((value) => CustomAttribute.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (groupValues != null)
          'groupValues': groupValues!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (value != null) 'value': value!,
      };
}

class CustomerReturnReason {
  /// Description of the reason.
  core.String? description;

  /// Code of the return reason.
  ///
  /// Acceptable values are: - "`betterPriceFound`" - "`changedMind`" -
  /// "`damagedOrDefectiveItem`" - "`didNotMatchDescription`" - "`doesNotFit`" -
  /// "`expiredItem`" - "`incorrectItemReceived`" - "`noLongerNeeded`" -
  /// "`notSpecified`" - "`orderedWrongItem`" - "`other`" -
  /// "`qualityNotExpected`" - "`receivedTooLate`" - "`undeliverable`"
  core.String? reasonCode;

  CustomerReturnReason();

  CustomerReturnReason.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('reasonCode')) {
      reasonCode = _json['reasonCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (reasonCode != null) 'reasonCode': reasonCode!,
      };
}

class CutoffTime {
  /// Hour of the cutoff time until which an order has to be placed to be
  /// processed in the same day.
  ///
  /// Required.
  core.int? hour;

  /// Minute of the cutoff time until which an order has to be placed to be
  /// processed in the same day.
  ///
  /// Required.
  core.int? minute;

  /// Timezone identifier for the cutoff time.
  ///
  /// A list of identifiers can be found in the AdWords API documentation. E.g.
  /// "Europe/Zurich". Required.
  core.String? timezone;

  CutoffTime();

  CutoffTime.fromJson(core.Map _json) {
    if (_json.containsKey('hour')) {
      hour = _json['hour'] as core.int;
    }
    if (_json.containsKey('minute')) {
      minute = _json['minute'] as core.int;
    }
    if (_json.containsKey('timezone')) {
      timezone = _json['timezone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (hour != null) 'hour': hour!,
        if (minute != null) 'minute': minute!,
        if (timezone != null) 'timezone': timezone!,
      };
}

/// Datafeed configuration data.
class Datafeed {
  /// The two-letter ISO 639-1 language in which the attributes are defined in
  /// the data feed.
  core.String? attributeLanguage;

  /// The type of data feed.
  ///
  /// For product inventory feeds, only feeds for local stores, not online
  /// stores, are supported. Acceptable values are: - "`local products`" -
  /// "`product inventory`" - "`products`"
  ///
  /// Required.
  core.String? contentType;

  /// Fetch schedule for the feed file.
  DatafeedFetchSchedule? fetchSchedule;

  /// The filename of the feed.
  ///
  /// All feeds must have a unique file name.
  ///
  /// Required.
  core.String? fileName;

  /// Format of the feed file.
  DatafeedFormat? format;

  /// Required for update.
  ///
  /// The ID of the data feed.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#datafeed`"
  core.String? kind;

  /// Required for insert.
  ///
  /// A descriptive name of the data feed.
  core.String? name;

  /// The targets this feed should apply to (country, language, destinations).
  core.List<DatafeedTarget>? targets;

  Datafeed();

  Datafeed.fromJson(core.Map _json) {
    if (_json.containsKey('attributeLanguage')) {
      attributeLanguage = _json['attributeLanguage'] as core.String;
    }
    if (_json.containsKey('contentType')) {
      contentType = _json['contentType'] as core.String;
    }
    if (_json.containsKey('fetchSchedule')) {
      fetchSchedule = DatafeedFetchSchedule.fromJson(
          _json['fetchSchedule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fileName')) {
      fileName = _json['fileName'] as core.String;
    }
    if (_json.containsKey('format')) {
      format = DatafeedFormat.fromJson(
          _json['format'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('targets')) {
      targets = (_json['targets'] as core.List)
          .map<DatafeedTarget>((value) => DatafeedTarget.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributeLanguage != null) 'attributeLanguage': attributeLanguage!,
        if (contentType != null) 'contentType': contentType!,
        if (fetchSchedule != null) 'fetchSchedule': fetchSchedule!.toJson(),
        if (fileName != null) 'fileName': fileName!,
        if (format != null) 'format': format!.toJson(),
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (targets != null)
          'targets': targets!.map((value) => value.toJson()).toList(),
      };
}

/// The required fields vary based on the frequency of fetching.
///
/// For a monthly fetch schedule, day_of_month and hour are required. For a
/// weekly fetch schedule, weekday and hour are required. For a daily fetch
/// schedule, only hour is required.
class DatafeedFetchSchedule {
  /// The day of the month the feed file should be fetched (1-31).
  core.int? dayOfMonth;

  /// The URL where the feed file can be fetched.
  ///
  /// Google Merchant Center will support automatic scheduled uploads using the
  /// HTTP, HTTPS, FTP, or SFTP protocols, so the value will need to be a valid
  /// link using one of those four protocols.
  core.String? fetchUrl;

  /// The hour of the day the feed file should be fetched (0-23).
  core.int? hour;

  /// The minute of the hour the feed file should be fetched (0-59).
  ///
  /// Read-only.
  core.int? minuteOfHour;

  /// An optional password for fetch_url.
  core.String? password;

  /// Whether the scheduled fetch is paused or not.
  core.bool? paused;

  /// Time zone used for schedule.
  ///
  /// UTC by default. E.g., "America/Los_Angeles".
  core.String? timeZone;

  /// An optional user name for fetch_url.
  core.String? username;

  /// The day of the week the feed file should be fetched.
  ///
  /// Acceptable values are: - "`monday`" - "`tuesday`" - "`wednesday`" -
  /// "`thursday`" - "`friday`" - "`saturday`" - "`sunday`"
  core.String? weekday;

  DatafeedFetchSchedule();

  DatafeedFetchSchedule.fromJson(core.Map _json) {
    if (_json.containsKey('dayOfMonth')) {
      dayOfMonth = _json['dayOfMonth'] as core.int;
    }
    if (_json.containsKey('fetchUrl')) {
      fetchUrl = _json['fetchUrl'] as core.String;
    }
    if (_json.containsKey('hour')) {
      hour = _json['hour'] as core.int;
    }
    if (_json.containsKey('minuteOfHour')) {
      minuteOfHour = _json['minuteOfHour'] as core.int;
    }
    if (_json.containsKey('password')) {
      password = _json['password'] as core.String;
    }
    if (_json.containsKey('paused')) {
      paused = _json['paused'] as core.bool;
    }
    if (_json.containsKey('timeZone')) {
      timeZone = _json['timeZone'] as core.String;
    }
    if (_json.containsKey('username')) {
      username = _json['username'] as core.String;
    }
    if (_json.containsKey('weekday')) {
      weekday = _json['weekday'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dayOfMonth != null) 'dayOfMonth': dayOfMonth!,
        if (fetchUrl != null) 'fetchUrl': fetchUrl!,
        if (hour != null) 'hour': hour!,
        if (minuteOfHour != null) 'minuteOfHour': minuteOfHour!,
        if (password != null) 'password': password!,
        if (paused != null) 'paused': paused!,
        if (timeZone != null) 'timeZone': timeZone!,
        if (username != null) 'username': username!,
        if (weekday != null) 'weekday': weekday!,
      };
}

class DatafeedFormat {
  /// Delimiter for the separation of values in a delimiter-separated values
  /// feed.
  ///
  /// If not specified, the delimiter will be auto-detected. Ignored for non-DSV
  /// data feeds. Acceptable values are: - "`pipe`" - "`tab`" - "`tilde`"
  core.String? columnDelimiter;

  /// Character encoding scheme of the data feed.
  ///
  /// If not specified, the encoding will be auto-detected. Acceptable values
  /// are: - "`latin-1`" - "`utf-16be`" - "`utf-16le`" - "`utf-8`" -
  /// "`windows-1252`"
  core.String? fileEncoding;

  /// Specifies how double quotes are interpreted.
  ///
  /// If not specified, the mode will be auto-detected. Ignored for non-DSV data
  /// feeds. Acceptable values are: - "`normal character`" - "`value quoting`"
  core.String? quotingMode;

  DatafeedFormat();

  DatafeedFormat.fromJson(core.Map _json) {
    if (_json.containsKey('columnDelimiter')) {
      columnDelimiter = _json['columnDelimiter'] as core.String;
    }
    if (_json.containsKey('fileEncoding')) {
      fileEncoding = _json['fileEncoding'] as core.String;
    }
    if (_json.containsKey('quotingMode')) {
      quotingMode = _json['quotingMode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnDelimiter != null) 'columnDelimiter': columnDelimiter!,
        if (fileEncoding != null) 'fileEncoding': fileEncoding!,
        if (quotingMode != null) 'quotingMode': quotingMode!,
      };
}

/// The status of a datafeed, i.e., the result of the last retrieval of the
/// datafeed computed asynchronously when the feed processing is finished.
class DatafeedStatus {
  /// The country for which the status is reported, represented as a CLDR
  /// territory code.
  core.String? country;

  /// The ID of the feed for which the status is reported.
  core.String? datafeedId;

  /// The list of errors occurring in the feed.
  core.List<DatafeedStatusError>? errors;

  /// The number of items in the feed that were processed.
  core.String? itemsTotal;

  /// The number of items in the feed that were valid.
  core.String? itemsValid;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#datafeedStatus`"
  core.String? kind;

  /// The two-letter ISO 639-1 language for which the status is reported.
  core.String? language;

  /// The last date at which the feed was uploaded.
  core.String? lastUploadDate;

  /// The processing status of the feed.
  ///
  /// Acceptable values are: - "`"`failure`": The feed could not be processed or
  /// all items had errors.`" - "`in progress`": The feed is being processed. -
  /// "`none`": The feed has not yet been processed. For example, a feed that
  /// has never been uploaded will have this processing status. - "`success`":
  /// The feed was processed successfully, though some items might have had
  /// errors.
  core.String? processingStatus;

  /// The list of errors occurring in the feed.
  core.List<DatafeedStatusError>? warnings;

  DatafeedStatus();

  DatafeedStatus.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('datafeedId')) {
      datafeedId = _json['datafeedId'] as core.String;
    }
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<DatafeedStatusError>((value) => DatafeedStatusError.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('itemsTotal')) {
      itemsTotal = _json['itemsTotal'] as core.String;
    }
    if (_json.containsKey('itemsValid')) {
      itemsValid = _json['itemsValid'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('language')) {
      language = _json['language'] as core.String;
    }
    if (_json.containsKey('lastUploadDate')) {
      lastUploadDate = _json['lastUploadDate'] as core.String;
    }
    if (_json.containsKey('processingStatus')) {
      processingStatus = _json['processingStatus'] as core.String;
    }
    if (_json.containsKey('warnings')) {
      warnings = (_json['warnings'] as core.List)
          .map<DatafeedStatusError>((value) => DatafeedStatusError.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (datafeedId != null) 'datafeedId': datafeedId!,
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
        if (itemsTotal != null) 'itemsTotal': itemsTotal!,
        if (itemsValid != null) 'itemsValid': itemsValid!,
        if (kind != null) 'kind': kind!,
        if (language != null) 'language': language!,
        if (lastUploadDate != null) 'lastUploadDate': lastUploadDate!,
        if (processingStatus != null) 'processingStatus': processingStatus!,
        if (warnings != null)
          'warnings': warnings!.map((value) => value.toJson()).toList(),
      };
}

/// An error occurring in the feed, like "invalid price".
class DatafeedStatusError {
  /// The code of the error, e.g., "validation/invalid_value".
  core.String? code;

  /// The number of occurrences of the error in the feed.
  core.String? count;

  /// A list of example occurrences of the error, grouped by product.
  core.List<DatafeedStatusExample>? examples;

  /// The error message, e.g., "Invalid price".
  core.String? message;

  DatafeedStatusError();

  DatafeedStatusError.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('count')) {
      count = _json['count'] as core.String;
    }
    if (_json.containsKey('examples')) {
      examples = (_json['examples'] as core.List)
          .map<DatafeedStatusExample>((value) => DatafeedStatusExample.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (count != null) 'count': count!,
        if (examples != null)
          'examples': examples!.map((value) => value.toJson()).toList(),
        if (message != null) 'message': message!,
      };
}

/// An example occurrence for a particular error.
class DatafeedStatusExample {
  /// The ID of the example item.
  core.String? itemId;

  /// Line number in the data feed where the example is found.
  core.String? lineNumber;

  /// The problematic value.
  core.String? value;

  DatafeedStatusExample();

  DatafeedStatusExample.fromJson(core.Map _json) {
    if (_json.containsKey('itemId')) {
      itemId = _json['itemId'] as core.String;
    }
    if (_json.containsKey('lineNumber')) {
      lineNumber = _json['lineNumber'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (itemId != null) 'itemId': itemId!,
        if (lineNumber != null) 'lineNumber': lineNumber!,
        if (value != null) 'value': value!,
      };
}

class DatafeedTarget {
  /// The country where the items in the feed will be included in the search
  /// index, represented as a CLDR territory code.
  core.String? country;

  /// The list of destinations to exclude for this target (corresponds to
  /// unchecked check boxes in Merchant Center).
  core.List<core.String>? excludedDestinations;

  /// The list of destinations to include for this target (corresponds to
  /// checked check boxes in Merchant Center).
  ///
  /// Default destinations are always included unless provided in
  /// `excludedDestinations`. List of supported destinations (if available to
  /// the account): - DisplayAds - Shopping - ShoppingActions -
  /// SurfacesAcrossGoogle
  core.List<core.String>? includedDestinations;

  /// The two-letter ISO 639-1 language of the items in the feed.
  ///
  /// Must be a valid language for `targets[].country`.
  core.String? language;

  DatafeedTarget();

  DatafeedTarget.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('excludedDestinations')) {
      excludedDestinations = (_json['excludedDestinations'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('includedDestinations')) {
      includedDestinations = (_json['includedDestinations'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('language')) {
      language = _json['language'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (excludedDestinations != null)
          'excludedDestinations': excludedDestinations!,
        if (includedDestinations != null)
          'includedDestinations': includedDestinations!,
        if (language != null) 'language': language!,
      };
}

class DatafeedsCustomBatchRequest {
  /// The request entries to be processed in the batch.
  core.List<DatafeedsCustomBatchRequestEntry>? entries;

  DatafeedsCustomBatchRequest();

  DatafeedsCustomBatchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<DatafeedsCustomBatchRequestEntry>((value) =>
              DatafeedsCustomBatchRequestEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

/// A batch entry encoding a single non-batch datafeeds request.
class DatafeedsCustomBatchRequestEntry {
  /// An entry ID, unique within the batch request.
  core.int? batchId;

  /// The data feed to insert.
  Datafeed? datafeed;

  /// The ID of the data feed to get, delete or fetch.
  core.String? datafeedId;

  /// The ID of the managing account.
  core.String? merchantId;

  /// The method of the batch entry.
  ///
  /// Acceptable values are: - "`delete`" - "`fetchNow`" - "`get`" - "`insert`"
  /// - "`update`"
  core.String? method;

  DatafeedsCustomBatchRequestEntry();

  DatafeedsCustomBatchRequestEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('datafeed')) {
      datafeed = Datafeed.fromJson(
          _json['datafeed'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('datafeedId')) {
      datafeedId = _json['datafeedId'] as core.String;
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (datafeed != null) 'datafeed': datafeed!.toJson(),
        if (datafeedId != null) 'datafeedId': datafeedId!,
        if (merchantId != null) 'merchantId': merchantId!,
        if (method != null) 'method': method!,
      };
}

class DatafeedsCustomBatchResponse {
  /// The result of the execution of the batch requests.
  core.List<DatafeedsCustomBatchResponseEntry>? entries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#datafeedsCustomBatchResponse".
  core.String? kind;

  DatafeedsCustomBatchResponse();

  DatafeedsCustomBatchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<DatafeedsCustomBatchResponseEntry>((value) =>
              DatafeedsCustomBatchResponseEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// A batch entry encoding a single non-batch datafeeds response.
class DatafeedsCustomBatchResponseEntry {
  /// The ID of the request entry this entry responds to.
  core.int? batchId;

  /// The requested data feed.
  ///
  /// Defined if and only if the request was successful.
  Datafeed? datafeed;

  /// A list of errors defined if and only if the request failed.
  Errors? errors;

  DatafeedsCustomBatchResponseEntry();

  DatafeedsCustomBatchResponseEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('datafeed')) {
      datafeed = Datafeed.fromJson(
          _json['datafeed'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('errors')) {
      errors = Errors.fromJson(
          _json['errors'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (datafeed != null) 'datafeed': datafeed!.toJson(),
        if (errors != null) 'errors': errors!.toJson(),
      };
}

class DatafeedsFetchNowResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#datafeedsFetchNowResponse".
  core.String? kind;

  DatafeedsFetchNowResponse();

  DatafeedsFetchNowResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
      };
}

class DatafeedsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#datafeedsListResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of datafeeds.
  core.String? nextPageToken;
  core.List<Datafeed>? resources;

  DatafeedsListResponse();

  DatafeedsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<Datafeed>((value) =>
              Datafeed.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

class DatafeedstatusesCustomBatchRequest {
  /// The request entries to be processed in the batch.
  core.List<DatafeedstatusesCustomBatchRequestEntry>? entries;

  DatafeedstatusesCustomBatchRequest();

  DatafeedstatusesCustomBatchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<DatafeedstatusesCustomBatchRequestEntry>((value) =>
              DatafeedstatusesCustomBatchRequestEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

/// A batch entry encoding a single non-batch datafeedstatuses request.
class DatafeedstatusesCustomBatchRequestEntry {
  /// An entry ID, unique within the batch request.
  core.int? batchId;

  /// The country for which to get the datafeed status.
  ///
  /// If this parameter is provided then language must also be provided. Note
  /// that for multi-target datafeeds this parameter is required.
  core.String? country;

  /// The ID of the data feed to get.
  core.String? datafeedId;

  /// The language for which to get the datafeed status.
  ///
  /// If this parameter is provided then country must also be provided. Note
  /// that for multi-target datafeeds this parameter is required.
  core.String? language;

  /// The ID of the managing account.
  core.String? merchantId;

  /// The method of the batch entry.
  ///
  /// Acceptable values are: - "`get`"
  core.String? method;

  DatafeedstatusesCustomBatchRequestEntry();

  DatafeedstatusesCustomBatchRequestEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('datafeedId')) {
      datafeedId = _json['datafeedId'] as core.String;
    }
    if (_json.containsKey('language')) {
      language = _json['language'] as core.String;
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (country != null) 'country': country!,
        if (datafeedId != null) 'datafeedId': datafeedId!,
        if (language != null) 'language': language!,
        if (merchantId != null) 'merchantId': merchantId!,
        if (method != null) 'method': method!,
      };
}

class DatafeedstatusesCustomBatchResponse {
  /// The result of the execution of the batch requests.
  core.List<DatafeedstatusesCustomBatchResponseEntry>? entries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#datafeedstatusesCustomBatchResponse".
  core.String? kind;

  DatafeedstatusesCustomBatchResponse();

  DatafeedstatusesCustomBatchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<DatafeedstatusesCustomBatchResponseEntry>((value) =>
              DatafeedstatusesCustomBatchResponseEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// A batch entry encoding a single non-batch datafeedstatuses response.
class DatafeedstatusesCustomBatchResponseEntry {
  /// The ID of the request entry this entry responds to.
  core.int? batchId;

  /// The requested data feed status.
  ///
  /// Defined if and only if the request was successful.
  DatafeedStatus? datafeedStatus;

  /// A list of errors defined if and only if the request failed.
  Errors? errors;

  DatafeedstatusesCustomBatchResponseEntry();

  DatafeedstatusesCustomBatchResponseEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('datafeedStatus')) {
      datafeedStatus = DatafeedStatus.fromJson(
          _json['datafeedStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('errors')) {
      errors = Errors.fromJson(
          _json['errors'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (datafeedStatus != null) 'datafeedStatus': datafeedStatus!.toJson(),
        if (errors != null) 'errors': errors!.toJson(),
      };
}

class DatafeedstatusesListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#datafeedstatusesListResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of datafeed statuses.
  core.String? nextPageToken;
  core.List<DatafeedStatus>? resources;

  DatafeedstatusesListResponse();

  DatafeedstatusesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<DatafeedStatus>((value) => DatafeedStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
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

/// Represents civil time (or occasionally physical time).
///
/// This type can represent a civil time in one of a few possible ways: * When
/// utc_offset is set and time_zone is unset: a civil time on a calendar day
/// with a particular offset from UTC. * When time_zone is set and utc_offset is
/// unset: a civil time on a calendar day in a particular time zone. * When
/// neither time_zone nor utc_offset is set: a civil time on a calendar day in
/// local time. The date is relative to the Proleptic Gregorian Calendar. If
/// year is 0, the DateTime is considered not to have a specific year. month and
/// day must have valid, non-zero values. This type may also be used to
/// represent a physical time if all the date and time fields are set and either
/// case of the `time_offset` oneof is set. Consider using `Timestamp` message
/// for physical time instead. If your use case also would like to store the
/// user's timezone, that can be done in another field. This type is more
/// flexible than some applications may want. Make sure to document and validate
/// your application's limitations.
class DateTime {
  /// Day of month.
  ///
  /// Must be from 1 to 31 and valid for the year and month.
  ///
  /// Required.
  core.int? day;

  /// Hours of day in 24 hour format.
  ///
  /// Should be from 0 to 23. An API may choose to allow the value "24:00:00"
  /// for scenarios like business closing time.
  ///
  /// Required.
  core.int? hours;

  /// Minutes of hour of day.
  ///
  /// Must be from 0 to 59.
  ///
  /// Required.
  core.int? minutes;

  /// Month of year.
  ///
  /// Must be from 1 to 12.
  ///
  /// Required.
  core.int? month;

  /// Fractions of seconds in nanoseconds.
  ///
  /// Must be from 0 to 999,999,999.
  ///
  /// Required.
  core.int? nanos;

  /// Seconds of minutes of the time.
  ///
  /// Must normally be from 0 to 59. An API may allow the value 60 if it allows
  /// leap-seconds.
  ///
  /// Required.
  core.int? seconds;

  /// Time zone.
  TimeZone? timeZone;

  /// UTC offset.
  ///
  /// Must be whole seconds, between -18 hours and +18 hours. For example, a UTC
  /// offset of -4:00 would be represented as { seconds: -14400 }.
  core.String? utcOffset;

  /// Year of date.
  ///
  /// Must be from 1 to 9999, or 0 if specifying a datetime without a year.
  ///
  /// Optional.
  core.int? year;

  DateTime();

  DateTime.fromJson(core.Map _json) {
    if (_json.containsKey('day')) {
      day = _json['day'] as core.int;
    }
    if (_json.containsKey('hours')) {
      hours = _json['hours'] as core.int;
    }
    if (_json.containsKey('minutes')) {
      minutes = _json['minutes'] as core.int;
    }
    if (_json.containsKey('month')) {
      month = _json['month'] as core.int;
    }
    if (_json.containsKey('nanos')) {
      nanos = _json['nanos'] as core.int;
    }
    if (_json.containsKey('seconds')) {
      seconds = _json['seconds'] as core.int;
    }
    if (_json.containsKey('timeZone')) {
      timeZone = TimeZone.fromJson(
          _json['timeZone'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('utcOffset')) {
      utcOffset = _json['utcOffset'] as core.String;
    }
    if (_json.containsKey('year')) {
      year = _json['year'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (day != null) 'day': day!,
        if (hours != null) 'hours': hours!,
        if (minutes != null) 'minutes': minutes!,
        if (month != null) 'month': month!,
        if (nanos != null) 'nanos': nanos!,
        if (seconds != null) 'seconds': seconds!,
        if (timeZone != null) 'timeZone': timeZone!.toJson(),
        if (utcOffset != null) 'utcOffset': utcOffset!,
        if (year != null) 'year': year!,
      };
}

class DeliveryTime {
  /// Business days cutoff time definition.
  ///
  /// If not configured the cutoff time will be defaulted to 8AM PST.
  CutoffTime? cutoffTime;

  /// The business days during which orders can be handled.
  ///
  /// If not provided, Monday to Friday business days will be assumed.
  BusinessDayConfig? handlingBusinessDayConfig;

  /// Holiday cutoff definitions.
  ///
  /// If configured, they specify order cutoff times for holiday-specific
  /// shipping.
  core.List<HolidayCutoff>? holidayCutoffs;

  /// Maximum number of business days spent before an order is shipped.
  ///
  /// 0 means same day shipped, 1 means next day shipped. Must be greater than
  /// or equal to `minHandlingTimeInDays`.
  core.int? maxHandlingTimeInDays;

  /// Maximum number of business days that is spent in transit.
  ///
  /// 0 means same day delivery, 1 means next day delivery. Must be greater than
  /// or equal to `minTransitTimeInDays`.
  core.int? maxTransitTimeInDays;

  /// Minimum number of business days spent before an order is shipped.
  ///
  /// 0 means same day shipped, 1 means next day shipped.
  core.int? minHandlingTimeInDays;

  /// Minimum number of business days that is spent in transit.
  ///
  /// 0 means same day delivery, 1 means next day delivery. Either
  /// `{min,max}TransitTimeInDays` or `transitTimeTable` must be set, but not
  /// both.
  core.int? minTransitTimeInDays;

  /// The business days during which orders can be in-transit.
  ///
  /// If not provided, Monday to Friday business days will be assumed.
  BusinessDayConfig? transitBusinessDayConfig;

  /// Transit time table, number of business days spent in transit based on row
  /// and column dimensions.
  ///
  /// Either `{min,max}TransitTimeInDays` or `transitTimeTable` can be set, but
  /// not both.
  TransitTable? transitTimeTable;

  /// Indicates that the delivery time should be calculated per warehouse
  /// (shipping origin location) based on the settings of the selected carrier.
  ///
  /// When set, no other transit time related field in DeliveryTime should be
  /// set.
  core.List<WarehouseBasedDeliveryTime>? warehouseBasedDeliveryTimes;

  DeliveryTime();

  DeliveryTime.fromJson(core.Map _json) {
    if (_json.containsKey('cutoffTime')) {
      cutoffTime = CutoffTime.fromJson(
          _json['cutoffTime'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('handlingBusinessDayConfig')) {
      handlingBusinessDayConfig = BusinessDayConfig.fromJson(
          _json['handlingBusinessDayConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('holidayCutoffs')) {
      holidayCutoffs = (_json['holidayCutoffs'] as core.List)
          .map<HolidayCutoff>((value) => HolidayCutoff.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('maxHandlingTimeInDays')) {
      maxHandlingTimeInDays = _json['maxHandlingTimeInDays'] as core.int;
    }
    if (_json.containsKey('maxTransitTimeInDays')) {
      maxTransitTimeInDays = _json['maxTransitTimeInDays'] as core.int;
    }
    if (_json.containsKey('minHandlingTimeInDays')) {
      minHandlingTimeInDays = _json['minHandlingTimeInDays'] as core.int;
    }
    if (_json.containsKey('minTransitTimeInDays')) {
      minTransitTimeInDays = _json['minTransitTimeInDays'] as core.int;
    }
    if (_json.containsKey('transitBusinessDayConfig')) {
      transitBusinessDayConfig = BusinessDayConfig.fromJson(
          _json['transitBusinessDayConfig']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('transitTimeTable')) {
      transitTimeTable = TransitTable.fromJson(
          _json['transitTimeTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('warehouseBasedDeliveryTimes')) {
      warehouseBasedDeliveryTimes =
          (_json['warehouseBasedDeliveryTimes'] as core.List)
              .map<WarehouseBasedDeliveryTime>((value) =>
                  WarehouseBasedDeliveryTime.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cutoffTime != null) 'cutoffTime': cutoffTime!.toJson(),
        if (handlingBusinessDayConfig != null)
          'handlingBusinessDayConfig': handlingBusinessDayConfig!.toJson(),
        if (holidayCutoffs != null)
          'holidayCutoffs':
              holidayCutoffs!.map((value) => value.toJson()).toList(),
        if (maxHandlingTimeInDays != null)
          'maxHandlingTimeInDays': maxHandlingTimeInDays!,
        if (maxTransitTimeInDays != null)
          'maxTransitTimeInDays': maxTransitTimeInDays!,
        if (minHandlingTimeInDays != null)
          'minHandlingTimeInDays': minHandlingTimeInDays!,
        if (minTransitTimeInDays != null)
          'minTransitTimeInDays': minTransitTimeInDays!,
        if (transitBusinessDayConfig != null)
          'transitBusinessDayConfig': transitBusinessDayConfig!.toJson(),
        if (transitTimeTable != null)
          'transitTimeTable': transitTimeTable!.toJson(),
        if (warehouseBasedDeliveryTimes != null)
          'warehouseBasedDeliveryTimes': warehouseBasedDeliveryTimes!
              .map((value) => value.toJson())
              .toList(),
      };
}

/// An error returned by the API.
class Error {
  /// The domain of the error.
  core.String? domain;

  /// A description of the error.
  core.String? message;

  /// The error code.
  core.String? reason;

  Error();

  Error.fromJson(core.Map _json) {
    if (_json.containsKey('domain')) {
      domain = _json['domain'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (domain != null) 'domain': domain!,
        if (message != null) 'message': message!,
        if (reason != null) 'reason': reason!,
      };
}

/// A list of errors returned by a failed batch entry.
class Errors {
  /// The HTTP status of the first error in `errors`.
  core.int? code;

  /// A list of errors.
  core.List<Error>? errors;

  /// The message of the first error in `errors`.
  core.String? message;

  Errors();

  Errors.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.int;
    }
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<Error>((value) =>
              Error.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
        if (message != null) 'message': message!,
      };
}

class GmbAccounts {
  /// The ID of the Merchant Center account.
  core.String? accountId;

  /// A list of GMB accounts which are available to the merchant.
  core.List<GmbAccountsGmbAccount>? gmbAccounts;

  GmbAccounts();

  GmbAccounts.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('gmbAccounts')) {
      gmbAccounts = (_json['gmbAccounts'] as core.List)
          .map<GmbAccountsGmbAccount>((value) => GmbAccountsGmbAccount.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (gmbAccounts != null)
          'gmbAccounts': gmbAccounts!.map((value) => value.toJson()).toList(),
      };
}

class GmbAccountsGmbAccount {
  /// The email which identifies the GMB account.
  core.String? email;

  /// Number of listings under this account.
  core.String? listingCount;

  /// The name of the GMB account.
  core.String? name;

  /// The type of the GMB account (User or Business).
  core.String? type;

  GmbAccountsGmbAccount();

  GmbAccountsGmbAccount.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('listingCount')) {
      listingCount = _json['listingCount'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
        if (listingCount != null) 'listingCount': listingCount!,
        if (name != null) 'name': name!,
        if (type != null) 'type': type!,
      };
}

/// A non-empty list of row or column headers for a table.
///
/// Exactly one of `prices`, `weights`, `numItems`, `postalCodeGroupNames`, or
/// `location` must be set.
class Headers {
  /// A list of location ID sets.
  ///
  /// Must be non-empty. Can only be set if all other fields are not set.
  core.List<LocationIdSet>? locations;

  /// A list of inclusive number of items upper bounds.
  ///
  /// The last value can be `"infinity"`. For example `["10", "50", "infinity"]`
  /// represents the headers "<= 10 items", "<= 50 items", and "> 50 items".
  /// Must be non-empty. Can only be set if all other fields are not set.
  core.List<core.String>? numberOfItems;

  /// A list of postal group names.
  ///
  /// The last value can be `"all other locations"`. Example: `["zone 1", "zone
  /// 2", "all other locations"]`. The referred postal code groups must match
  /// the delivery country of the service. Must be non-empty. Can only be set if
  /// all other fields are not set.
  core.List<core.String>? postalCodeGroupNames;

  /// A list of inclusive order price upper bounds.
  ///
  /// The last price's value can be `"infinity"`. For example `[{"value": "10",
  /// "currency": "USD"}, {"value": "500", "currency": "USD"}, {"value":
  /// "infinity", "currency": "USD"}]` represents the headers "<= $10", "<=
  /// $500", and "> $500". All prices within a service must have the same
  /// currency. Must be non-empty. Can only be set if all other fields are not
  /// set.
  core.List<Price>? prices;

  /// A list of inclusive order weight upper bounds.
  ///
  /// The last weight's value can be `"infinity"`. For example `[{"value": "10",
  /// "unit": "kg"}, {"value": "50", "unit": "kg"}, {"value": "infinity",
  /// "unit": "kg"}]` represents the headers "<= 10kg", "<= 50kg", and "> 50kg".
  /// All weights within a service must have the same unit. Must be non-empty.
  /// Can only be set if all other fields are not set.
  core.List<Weight>? weights;

  Headers();

  Headers.fromJson(core.Map _json) {
    if (_json.containsKey('locations')) {
      locations = (_json['locations'] as core.List)
          .map<LocationIdSet>((value) => LocationIdSet.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('numberOfItems')) {
      numberOfItems = (_json['numberOfItems'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('postalCodeGroupNames')) {
      postalCodeGroupNames = (_json['postalCodeGroupNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('prices')) {
      prices = (_json['prices'] as core.List)
          .map<Price>((value) =>
              Price.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('weights')) {
      weights = (_json['weights'] as core.List)
          .map<Weight>((value) =>
              Weight.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (locations != null)
          'locations': locations!.map((value) => value.toJson()).toList(),
        if (numberOfItems != null) 'numberOfItems': numberOfItems!,
        if (postalCodeGroupNames != null)
          'postalCodeGroupNames': postalCodeGroupNames!,
        if (prices != null)
          'prices': prices!.map((value) => value.toJson()).toList(),
        if (weights != null)
          'weights': weights!.map((value) => value.toJson()).toList(),
      };
}

class HolidayCutoff {
  /// Date of the order deadline, in ISO 8601 format.
  ///
  /// E.g. "2016-11-29" for 29th November 2016. Required.
  core.String? deadlineDate;

  /// Hour of the day on the deadline date until which the order has to be
  /// placed to qualify for the delivery guarantee.
  ///
  /// Possible values are: 0 (midnight), 1, ..., 12 (noon), 13, ..., 23.
  /// Required.
  core.int? deadlineHour;

  /// Timezone identifier for the deadline hour.
  ///
  /// A list of identifiers can be found in the AdWords API documentation. E.g.
  /// "Europe/Zurich". Required.
  core.String? deadlineTimezone;

  /// Unique identifier for the holiday.
  ///
  /// Required.
  core.String? holidayId;

  /// Date on which the deadline will become visible to consumers in ISO 8601
  /// format.
  ///
  /// E.g. "2016-10-31" for 31st October 2016. Required.
  core.String? visibleFromDate;

  HolidayCutoff();

  HolidayCutoff.fromJson(core.Map _json) {
    if (_json.containsKey('deadlineDate')) {
      deadlineDate = _json['deadlineDate'] as core.String;
    }
    if (_json.containsKey('deadlineHour')) {
      deadlineHour = _json['deadlineHour'] as core.int;
    }
    if (_json.containsKey('deadlineTimezone')) {
      deadlineTimezone = _json['deadlineTimezone'] as core.String;
    }
    if (_json.containsKey('holidayId')) {
      holidayId = _json['holidayId'] as core.String;
    }
    if (_json.containsKey('visibleFromDate')) {
      visibleFromDate = _json['visibleFromDate'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deadlineDate != null) 'deadlineDate': deadlineDate!,
        if (deadlineHour != null) 'deadlineHour': deadlineHour!,
        if (deadlineTimezone != null) 'deadlineTimezone': deadlineTimezone!,
        if (holidayId != null) 'holidayId': holidayId!,
        if (visibleFromDate != null) 'visibleFromDate': visibleFromDate!,
      };
}

class HolidaysHoliday {
  /// The CLDR territory code of the country in which the holiday is available.
  ///
  /// E.g. "US", "DE", "GB". A holiday cutoff can only be configured in a
  /// shipping settings service with matching delivery country. Always present.
  core.String? countryCode;

  /// Date of the holiday, in ISO 8601 format.
  ///
  /// E.g. "2016-12-25" for Christmas 2016. Always present.
  core.String? date;

  /// Date on which the order has to arrive at the customer's, in ISO 8601
  /// format.
  ///
  /// E.g. "2016-12-24" for 24th December 2016. Always present.
  core.String? deliveryGuaranteeDate;

  /// Hour of the day in the delivery location's timezone on the guaranteed
  /// delivery date by which the order has to arrive at the customer's.
  ///
  /// Possible values are: 0 (midnight), 1, ..., 12 (noon), 13, ..., 23. Always
  /// present.
  core.String? deliveryGuaranteeHour;

  /// Unique identifier for the holiday to be used when configuring holiday
  /// cutoffs.
  ///
  /// Always present.
  core.String? id;

  /// The holiday type.
  ///
  /// Always present. Acceptable values are: - "`Christmas`" - "`Easter`" -
  /// "`Father's Day`" - "`Halloween`" - "`Independence Day (USA)`" - "`Mother's
  /// Day`" - "`Thanksgiving`" - "`Valentine's Day`"
  core.String? type;

  HolidaysHoliday();

  HolidaysHoliday.fromJson(core.Map _json) {
    if (_json.containsKey('countryCode')) {
      countryCode = _json['countryCode'] as core.String;
    }
    if (_json.containsKey('date')) {
      date = _json['date'] as core.String;
    }
    if (_json.containsKey('deliveryGuaranteeDate')) {
      deliveryGuaranteeDate = _json['deliveryGuaranteeDate'] as core.String;
    }
    if (_json.containsKey('deliveryGuaranteeHour')) {
      deliveryGuaranteeHour = _json['deliveryGuaranteeHour'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (countryCode != null) 'countryCode': countryCode!,
        if (date != null) 'date': date!,
        if (deliveryGuaranteeDate != null)
          'deliveryGuaranteeDate': deliveryGuaranteeDate!,
        if (deliveryGuaranteeHour != null)
          'deliveryGuaranteeHour': deliveryGuaranteeHour!,
        if (id != null) 'id': id!,
        if (type != null) 'type': type!,
      };
}

/// Map of inapplicability details.
class InapplicabilityDetails {
  /// Count of this inapplicable reason code.
  core.String? inapplicableCount;

  /// Reason code this rule was not applicable.
  /// Possible string values are:
  /// - "INAPPLICABLE_REASON_UNSPECIFIED" : Default value. Should not be used.
  /// - "CANNOT_BEAT_BUYBOX_WINNER" : The rule set for this product cannot beat
  /// the buybox winner.
  /// - "ALREADY_WINNING_BUYBOX" : This product can already win the buybox
  /// without rule.
  /// - "TRIUMPHED_OVER_BY_SAME_TYPE_RULE" : Another rule of the same type takes
  /// precedence over this one.
  /// - "TRIUMPHED_OVER_BY_OTHER_RULE_ON_OFFER" : Another rule of a different
  /// type takes precedence over this one.
  /// - "RESTRICTIONS_NOT_MET" : The rule restrictions are not met. For example,
  /// this may be the case if the calculated rule price is lower than floor
  /// price in the restriction.
  /// - "UNCATEGORIZED" : The reason is not categorized to any known reason.
  /// - "INVALID_AUTO_PRICE_MIN" : The auto_pricing_min_price is invalid. For
  /// example, it is missing or < 0.
  /// - "INVALID_FLOOR_CONFIG" : The floor defined in the rule is invalid. For
  /// example, it has the wrong sign which results in a floor < 0.
  core.String? inapplicableReason;

  InapplicabilityDetails();

  InapplicabilityDetails.fromJson(core.Map _json) {
    if (_json.containsKey('inapplicableCount')) {
      inapplicableCount = _json['inapplicableCount'] as core.String;
    }
    if (_json.containsKey('inapplicableReason')) {
      inapplicableReason = _json['inapplicableReason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inapplicableCount != null) 'inapplicableCount': inapplicableCount!,
        if (inapplicableReason != null)
          'inapplicableReason': inapplicableReason!,
      };
}

class Installment {
  /// The amount the buyer has to pay per month.
  Price? amount;

  /// The number of installments the buyer has to pay.
  core.String? months;

  Installment();

  Installment.fromJson(core.Map _json) {
    if (_json.containsKey('amount')) {
      amount = Price.fromJson(
          _json['amount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('months')) {
      months = _json['months'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (amount != null) 'amount': amount!.toJson(),
        if (months != null) 'months': months!,
      };
}

class InvoiceSummary {
  /// Summary of the total amounts of the additional charges.
  core.List<InvoiceSummaryAdditionalChargeSummary>? additionalChargeSummaries;

  /// Total price for the product.
  ///
  /// Required.
  Amount? productTotal;

  InvoiceSummary();

  InvoiceSummary.fromJson(core.Map _json) {
    if (_json.containsKey('additionalChargeSummaries')) {
      additionalChargeSummaries =
          (_json['additionalChargeSummaries'] as core.List)
              .map<InvoiceSummaryAdditionalChargeSummary>((value) =>
                  InvoiceSummaryAdditionalChargeSummary.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('productTotal')) {
      productTotal = Amount.fromJson(
          _json['productTotal'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalChargeSummaries != null)
          'additionalChargeSummaries': additionalChargeSummaries!
              .map((value) => value.toJson())
              .toList(),
        if (productTotal != null) 'productTotal': productTotal!.toJson(),
      };
}

class InvoiceSummaryAdditionalChargeSummary {
  /// Total additional charge for this type.
  ///
  /// Required.
  Amount? totalAmount;

  /// Type of the additional charge.
  ///
  /// Acceptable values are: - "`shipping`"
  ///
  /// Required.
  core.String? type;

  InvoiceSummaryAdditionalChargeSummary();

  InvoiceSummaryAdditionalChargeSummary.fromJson(core.Map _json) {
    if (_json.containsKey('totalAmount')) {
      totalAmount = Amount.fromJson(
          _json['totalAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (totalAmount != null) 'totalAmount': totalAmount!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// The IDs of labels that should be assigned to the CSS domain.
class LabelIds {
  /// The list of label IDs.
  core.List<core.String>? labelIds;

  LabelIds();

  LabelIds.fromJson(core.Map _json) {
    if (_json.containsKey('labelIds')) {
      labelIds = (_json['labelIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (labelIds != null) 'labelIds': labelIds!,
      };
}

class LiaAboutPageSettings {
  /// The status of the verification process for the About page.
  ///
  /// Acceptable values are: - "`active`" - "`inactive`" - "`pending`"
  core.String? status;

  /// The URL for the About page.
  core.String? url;

  LiaAboutPageSettings();

  LiaAboutPageSettings.fromJson(core.Map _json) {
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (status != null) 'status': status!,
        if (url != null) 'url': url!,
      };
}

class LiaCountrySettings {
  /// The settings for the About page.
  LiaAboutPageSettings? about;

  /// CLDR country code (e.g. "US").
  ///
  /// Required.
  core.String? country;

  /// The status of the "Merchant hosted local storefront" feature.
  core.bool? hostedLocalStorefrontActive;

  /// LIA inventory verification settings.
  LiaInventorySettings? inventory;

  /// LIA "On Display To Order" settings.
  LiaOnDisplayToOrderSettings? onDisplayToOrder;

  /// The POS data provider linked with this country.
  LiaPosDataProvider? posDataProvider;

  /// The status of the "Store pickup" feature.
  core.bool? storePickupActive;

  LiaCountrySettings();

  LiaCountrySettings.fromJson(core.Map _json) {
    if (_json.containsKey('about')) {
      about = LiaAboutPageSettings.fromJson(
          _json['about'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('hostedLocalStorefrontActive')) {
      hostedLocalStorefrontActive =
          _json['hostedLocalStorefrontActive'] as core.bool;
    }
    if (_json.containsKey('inventory')) {
      inventory = LiaInventorySettings.fromJson(
          _json['inventory'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('onDisplayToOrder')) {
      onDisplayToOrder = LiaOnDisplayToOrderSettings.fromJson(
          _json['onDisplayToOrder'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('posDataProvider')) {
      posDataProvider = LiaPosDataProvider.fromJson(
          _json['posDataProvider'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('storePickupActive')) {
      storePickupActive = _json['storePickupActive'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (about != null) 'about': about!.toJson(),
        if (country != null) 'country': country!,
        if (hostedLocalStorefrontActive != null)
          'hostedLocalStorefrontActive': hostedLocalStorefrontActive!,
        if (inventory != null) 'inventory': inventory!.toJson(),
        if (onDisplayToOrder != null)
          'onDisplayToOrder': onDisplayToOrder!.toJson(),
        if (posDataProvider != null)
          'posDataProvider': posDataProvider!.toJson(),
        if (storePickupActive != null) 'storePickupActive': storePickupActive!,
      };
}

class LiaInventorySettings {
  /// The email of the contact for the inventory verification process.
  core.String? inventoryVerificationContactEmail;

  /// The name of the contact for the inventory verification process.
  core.String? inventoryVerificationContactName;

  /// The status of the verification contact.
  ///
  /// Acceptable values are: - "`active`" - "`inactive`" - "`pending`"
  core.String? inventoryVerificationContactStatus;

  /// The status of the inventory verification process.
  ///
  /// Acceptable values are: - "`active`" - "`inactive`" - "`pending`"
  core.String? status;

  LiaInventorySettings();

  LiaInventorySettings.fromJson(core.Map _json) {
    if (_json.containsKey('inventoryVerificationContactEmail')) {
      inventoryVerificationContactEmail =
          _json['inventoryVerificationContactEmail'] as core.String;
    }
    if (_json.containsKey('inventoryVerificationContactName')) {
      inventoryVerificationContactName =
          _json['inventoryVerificationContactName'] as core.String;
    }
    if (_json.containsKey('inventoryVerificationContactStatus')) {
      inventoryVerificationContactStatus =
          _json['inventoryVerificationContactStatus'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inventoryVerificationContactEmail != null)
          'inventoryVerificationContactEmail':
              inventoryVerificationContactEmail!,
        if (inventoryVerificationContactName != null)
          'inventoryVerificationContactName': inventoryVerificationContactName!,
        if (inventoryVerificationContactStatus != null)
          'inventoryVerificationContactStatus':
              inventoryVerificationContactStatus!,
        if (status != null) 'status': status!,
      };
}

class LiaOnDisplayToOrderSettings {
  /// Shipping cost and policy URL.
  core.String? shippingCostPolicyUrl;

  /// The status of the ?On display to order? feature.
  ///
  /// Acceptable values are: - "`active`" - "`inactive`" - "`pending`"
  core.String? status;

  LiaOnDisplayToOrderSettings();

  LiaOnDisplayToOrderSettings.fromJson(core.Map _json) {
    if (_json.containsKey('shippingCostPolicyUrl')) {
      shippingCostPolicyUrl = _json['shippingCostPolicyUrl'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (shippingCostPolicyUrl != null)
          'shippingCostPolicyUrl': shippingCostPolicyUrl!,
        if (status != null) 'status': status!,
      };
}

class LiaPosDataProvider {
  /// The ID of the POS data provider.
  core.String? posDataProviderId;

  /// The account ID by which this merchant is known to the POS data provider.
  core.String? posExternalAccountId;

  LiaPosDataProvider();

  LiaPosDataProvider.fromJson(core.Map _json) {
    if (_json.containsKey('posDataProviderId')) {
      posDataProviderId = _json['posDataProviderId'] as core.String;
    }
    if (_json.containsKey('posExternalAccountId')) {
      posExternalAccountId = _json['posExternalAccountId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (posDataProviderId != null) 'posDataProviderId': posDataProviderId!,
        if (posExternalAccountId != null)
          'posExternalAccountId': posExternalAccountId!,
      };
}

/// Local Inventory ads (LIA) settings.
///
/// All methods except listposdataproviders require the admin role.
class LiaSettings {
  /// The ID of the account to which these LIA settings belong.
  ///
  /// Ignored upon update, always present in get request responses.
  core.String? accountId;

  /// The LIA settings for each country.
  core.List<LiaCountrySettings>? countrySettings;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#liaSettings`"
  core.String? kind;

  LiaSettings();

  LiaSettings.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('countrySettings')) {
      countrySettings = (_json['countrySettings'] as core.List)
          .map<LiaCountrySettings>((value) => LiaCountrySettings.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (countrySettings != null)
          'countrySettings':
              countrySettings!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class LiasettingsCustomBatchRequest {
  /// The request entries to be processed in the batch.
  core.List<LiasettingsCustomBatchRequestEntry>? entries;

  LiasettingsCustomBatchRequest();

  LiasettingsCustomBatchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<LiasettingsCustomBatchRequestEntry>((value) =>
              LiasettingsCustomBatchRequestEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

class LiasettingsCustomBatchRequestEntry {
  /// The ID of the account for which to get/update account LIA settings.
  core.String? accountId;

  /// An entry ID, unique within the batch request.
  core.int? batchId;

  /// Inventory validation contact email.
  ///
  /// Required only for SetInventoryValidationContact.
  core.String? contactEmail;

  /// Inventory validation contact name.
  ///
  /// Required only for SetInventoryValidationContact.
  core.String? contactName;

  /// The country code.
  ///
  /// Required only for RequestInventoryVerification.
  core.String? country;

  /// The GMB account.
  ///
  /// Required only for RequestGmbAccess.
  core.String? gmbEmail;

  /// The account Lia settings to update.
  ///
  /// Only defined if the method is `update`.
  LiaSettings? liaSettings;

  /// The ID of the managing account.
  core.String? merchantId;

  /// The method of the batch entry.
  ///
  /// Acceptable values are: - "`get`" - "`getAccessibleGmbAccounts`" -
  /// "`requestGmbAccess`" - "`requestInventoryVerification`" -
  /// "`setInventoryVerificationContact`" - "`update`"
  core.String? method;

  /// The ID of POS data provider.
  ///
  /// Required only for SetPosProvider.
  core.String? posDataProviderId;

  /// The account ID by which this merchant is known to the POS provider.
  core.String? posExternalAccountId;

  LiasettingsCustomBatchRequestEntry();

  LiasettingsCustomBatchRequestEntry.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('contactEmail')) {
      contactEmail = _json['contactEmail'] as core.String;
    }
    if (_json.containsKey('contactName')) {
      contactName = _json['contactName'] as core.String;
    }
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('gmbEmail')) {
      gmbEmail = _json['gmbEmail'] as core.String;
    }
    if (_json.containsKey('liaSettings')) {
      liaSettings = LiaSettings.fromJson(
          _json['liaSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('posDataProviderId')) {
      posDataProviderId = _json['posDataProviderId'] as core.String;
    }
    if (_json.containsKey('posExternalAccountId')) {
      posExternalAccountId = _json['posExternalAccountId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (batchId != null) 'batchId': batchId!,
        if (contactEmail != null) 'contactEmail': contactEmail!,
        if (contactName != null) 'contactName': contactName!,
        if (country != null) 'country': country!,
        if (gmbEmail != null) 'gmbEmail': gmbEmail!,
        if (liaSettings != null) 'liaSettings': liaSettings!.toJson(),
        if (merchantId != null) 'merchantId': merchantId!,
        if (method != null) 'method': method!,
        if (posDataProviderId != null) 'posDataProviderId': posDataProviderId!,
        if (posExternalAccountId != null)
          'posExternalAccountId': posExternalAccountId!,
      };
}

class LiasettingsCustomBatchResponse {
  /// The result of the execution of the batch requests.
  core.List<LiasettingsCustomBatchResponseEntry>? entries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#liasettingsCustomBatchResponse".
  core.String? kind;

  LiasettingsCustomBatchResponse();

  LiasettingsCustomBatchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<LiasettingsCustomBatchResponseEntry>((value) =>
              LiasettingsCustomBatchResponseEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class LiasettingsCustomBatchResponseEntry {
  /// The ID of the request entry to which this entry responds.
  core.int? batchId;

  /// A list of errors defined if, and only if, the request failed.
  Errors? errors;

  /// The list of accessible GMB accounts.
  GmbAccounts? gmbAccounts;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#liasettingsCustomBatchResponseEntry`"
  core.String? kind;

  /// The retrieved or updated Lia settings.
  LiaSettings? liaSettings;

  /// The list of POS data providers.
  core.List<PosDataProviders>? posDataProviders;

  LiasettingsCustomBatchResponseEntry();

  LiasettingsCustomBatchResponseEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('errors')) {
      errors = Errors.fromJson(
          _json['errors'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gmbAccounts')) {
      gmbAccounts = GmbAccounts.fromJson(
          _json['gmbAccounts'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('liaSettings')) {
      liaSettings = LiaSettings.fromJson(
          _json['liaSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('posDataProviders')) {
      posDataProviders = (_json['posDataProviders'] as core.List)
          .map<PosDataProviders>((value) => PosDataProviders.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (errors != null) 'errors': errors!.toJson(),
        if (gmbAccounts != null) 'gmbAccounts': gmbAccounts!.toJson(),
        if (kind != null) 'kind': kind!,
        if (liaSettings != null) 'liaSettings': liaSettings!.toJson(),
        if (posDataProviders != null)
          'posDataProviders':
              posDataProviders!.map((value) => value.toJson()).toList(),
      };
}

class LiasettingsGetAccessibleGmbAccountsResponse {
  /// The ID of the Merchant Center account.
  core.String? accountId;

  /// A list of GMB accounts which are available to the merchant.
  core.List<GmbAccountsGmbAccount>? gmbAccounts;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "content#liasettingsGetAccessibleGmbAccountsResponse".
  core.String? kind;

  LiasettingsGetAccessibleGmbAccountsResponse();

  LiasettingsGetAccessibleGmbAccountsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('gmbAccounts')) {
      gmbAccounts = (_json['gmbAccounts'] as core.List)
          .map<GmbAccountsGmbAccount>((value) => GmbAccountsGmbAccount.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (gmbAccounts != null)
          'gmbAccounts': gmbAccounts!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class LiasettingsListPosDataProvidersResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#liasettingsListPosDataProvidersResponse".
  core.String? kind;

  /// The list of POS data providers for each eligible country
  core.List<PosDataProviders>? posDataProviders;

  LiasettingsListPosDataProvidersResponse();

  LiasettingsListPosDataProvidersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('posDataProviders')) {
      posDataProviders = (_json['posDataProviders'] as core.List)
          .map<PosDataProviders>((value) => PosDataProviders.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (posDataProviders != null)
          'posDataProviders':
              posDataProviders!.map((value) => value.toJson()).toList(),
      };
}

class LiasettingsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#liasettingsListResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of LIA settings.
  core.String? nextPageToken;
  core.List<LiaSettings>? resources;

  LiasettingsListResponse();

  LiasettingsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<LiaSettings>((value) => LiaSettings.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

class LiasettingsRequestGmbAccessResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#liasettingsRequestGmbAccessResponse".
  core.String? kind;

  LiasettingsRequestGmbAccessResponse();

  LiasettingsRequestGmbAccessResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
      };
}

class LiasettingsRequestInventoryVerificationResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "content#liasettingsRequestInventoryVerificationResponse".
  core.String? kind;

  LiasettingsRequestInventoryVerificationResponse();

  LiasettingsRequestInventoryVerificationResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
      };
}

class LiasettingsSetInventoryVerificationContactResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "content#liasettingsSetInventoryVerificationContactResponse".
  core.String? kind;

  LiasettingsSetInventoryVerificationContactResponse();

  LiasettingsSetInventoryVerificationContactResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
      };
}

class LiasettingsSetPosDataProviderResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#liasettingsSetPosDataProviderResponse".
  core.String? kind;

  LiasettingsSetPosDataProviderResponse();

  LiasettingsSetPosDataProviderResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
      };
}

class LinkService {
  /// Service provided to or by the linked account.
  ///
  /// Acceptable values are: - "`shoppingActionsOrderManagement`" -
  /// "`shoppingActionsProductManagement`" - "`shoppingAdsProductManagement`" -
  /// "`paymentProcessing`"
  core.String? service;

  /// Status of the link Acceptable values are: - "`active`" - "`inactive`" -
  /// "`pending`"
  core.String? status;

  LinkService();

  LinkService.fromJson(core.Map _json) {
    if (_json.containsKey('service')) {
      service = _json['service'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (service != null) 'service': service!,
        if (status != null) 'status': status!,
      };
}

class LinkedAccount {
  /// The ID of the linked account.
  core.String? linkedAccountId;

  /// List of provided services.
  core.List<LinkService>? services;

  LinkedAccount();

  LinkedAccount.fromJson(core.Map _json) {
    if (_json.containsKey('linkedAccountId')) {
      linkedAccountId = _json['linkedAccountId'] as core.String;
    }
    if (_json.containsKey('services')) {
      services = (_json['services'] as core.List)
          .map<LinkService>((value) => LinkService.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (linkedAccountId != null) 'linkedAccountId': linkedAccountId!,
        if (services != null)
          'services': services!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for the `ListAccountLabels` method.
class ListAccountLabelsResponse {
  /// The labels from the specified account.
  core.List<AccountLabel>? accountLabels;

  /// A token, which can be sent as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  ListAccountLabelsResponse();

  ListAccountLabelsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('accountLabels')) {
      accountLabels = (_json['accountLabels'] as core.List)
          .map<AccountLabel>((value) => AccountLabel.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountLabels != null)
          'accountLabels':
              accountLabels!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response for listing account return carriers.
class ListAccountReturnCarrierResponse {
  /// List of all available account return carriers for the merchant.
  core.List<AccountReturnCarrier>? accountReturnCarriers;

  ListAccountReturnCarrierResponse();

  ListAccountReturnCarrierResponse.fromJson(core.Map _json) {
    if (_json.containsKey('accountReturnCarriers')) {
      accountReturnCarriers = (_json['accountReturnCarriers'] as core.List)
          .map<AccountReturnCarrier>((value) => AccountReturnCarrier.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountReturnCarriers != null)
          'accountReturnCarriers':
              accountReturnCarriers!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for the ListCollectionStatuses method.
class ListCollectionStatusesResponse {
  /// A token, which can be sent as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// The collectionstatuses listed.
  core.List<CollectionStatus>? resources;

  ListCollectionStatusesResponse();

  ListCollectionStatusesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<CollectionStatus>((value) => CollectionStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for the ListCollections method.
class ListCollectionsResponse {
  /// A token, which can be sent as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// The collections listed.
  core.List<Collection>? resources;

  ListCollectionsResponse();

  ListCollectionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<Collection>((value) =>
              Collection.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for the `ListCsses` method
class ListCssesResponse {
  /// The CSS domains affiliated with the specified CSS group.
  core.List<Css>? csses;

  /// A token, which can be sent as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  ListCssesResponse();

  ListCssesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('csses')) {
      csses = (_json['csses'] as core.List)
          .map<Css>((value) =>
              Css.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (csses != null)
          'csses': csses!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for the `ListRegions` method.
class ListRegionsResponse {
  /// A token, which can be sent as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// The regions from the specified merchant.
  core.List<Region>? regions;

  ListRegionsResponse();

  ListRegionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('regions')) {
      regions = (_json['regions'] as core.List)
          .map<Region>((value) =>
              Region.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (regions != null)
          'regions': regions!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for the ListRepricingProductReports method.
class ListRepricingProductReportsResponse {
  /// A token for retrieving the next page.
  ///
  /// Its absence means there is no subsequent page.
  core.String? nextPageToken;

  /// Periodic reports for the given Repricing product.
  core.List<RepricingProductReport>? repricingProductReports;

  ListRepricingProductReportsResponse();

  ListRepricingProductReportsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('repricingProductReports')) {
      repricingProductReports = (_json['repricingProductReports'] as core.List)
          .map<RepricingProductReport>((value) =>
              RepricingProductReport.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (repricingProductReports != null)
          'repricingProductReports':
              repricingProductReports!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for the ListRepricingRuleReports method.
class ListRepricingRuleReportsResponse {
  /// A token for retrieving the next page.
  ///
  /// Its absence means there is no subsequent page.
  core.String? nextPageToken;

  /// Daily reports for the given Repricing rule.
  core.List<RepricingRuleReport>? repricingRuleReports;

  ListRepricingRuleReportsResponse();

  ListRepricingRuleReportsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('repricingRuleReports')) {
      repricingRuleReports = (_json['repricingRuleReports'] as core.List)
          .map<RepricingRuleReport>((value) => RepricingRuleReport.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (repricingRuleReports != null)
          'repricingRuleReports':
              repricingRuleReports!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for the `ListRepricingRules` method.
class ListRepricingRulesResponse {
  /// A token, which can be sent as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// The rules from the specified merchant.
  core.List<RepricingRule>? repricingRules;

  ListRepricingRulesResponse();

  ListRepricingRulesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('repricingRules')) {
      repricingRules = (_json['repricingRules'] as core.List)
          .map<RepricingRule>((value) => RepricingRule.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (repricingRules != null)
          'repricingRules':
              repricingRules!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for the `ListReturnPolicyOnline` method.
class ListReturnPolicyOnlineResponse {
  /// The retrieved return policies.
  core.List<ReturnPolicyOnline>? returnPolicies;

  ListReturnPolicyOnlineResponse();

  ListReturnPolicyOnlineResponse.fromJson(core.Map _json) {
    if (_json.containsKey('returnPolicies')) {
      returnPolicies = (_json['returnPolicies'] as core.List)
          .map<ReturnPolicyOnline>((value) => ReturnPolicyOnline.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (returnPolicies != null)
          'returnPolicies':
              returnPolicies!.map((value) => value.toJson()).toList(),
      };
}

/// Local inventory resource.
///
/// For accepted attribute values, see the local product inventory feed
/// specification.
class LocalInventory {
  /// Availability of the product.
  ///
  /// For accepted attribute values, see the local product inventory feed
  /// specification.
  core.String? availability;

  /// In-store product location.
  core.String? instoreProductLocation;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#localInventory`"
  core.String? kind;

  /// Supported pickup method for this offer.
  ///
  /// Unless the value is "not supported", this field must be submitted together
  /// with `pickupSla`. For accepted attribute values, see the local product
  /// inventory feed // specification.
  core.String? pickupMethod;

  /// Expected date that an order will be ready for pickup relative to the order
  /// date.
  ///
  /// Must be submitted together with `pickupMethod`. For accepted attribute
  /// values, see the local product inventory feed specification.
  core.String? pickupSla;

  /// Price of the product.
  Price? price;

  /// Quantity of the product.
  ///
  /// Must be nonnegative.
  core.int? quantity;

  /// Sale price of the product.
  ///
  /// Mandatory if `sale_price_effective_date` is defined.
  Price? salePrice;

  /// A date range represented by a pair of ISO 8601 dates separated by a space,
  /// comma, or slash.
  ///
  /// Both dates may be specified as 'null' if undecided.
  core.String? salePriceEffectiveDate;

  /// Store code of this local inventory resource.
  ///
  /// Required.
  core.String? storeCode;

  LocalInventory();

  LocalInventory.fromJson(core.Map _json) {
    if (_json.containsKey('availability')) {
      availability = _json['availability'] as core.String;
    }
    if (_json.containsKey('instoreProductLocation')) {
      instoreProductLocation = _json['instoreProductLocation'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('pickupMethod')) {
      pickupMethod = _json['pickupMethod'] as core.String;
    }
    if (_json.containsKey('pickupSla')) {
      pickupSla = _json['pickupSla'] as core.String;
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.int;
    }
    if (_json.containsKey('salePrice')) {
      salePrice = Price.fromJson(
          _json['salePrice'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('salePriceEffectiveDate')) {
      salePriceEffectiveDate = _json['salePriceEffectiveDate'] as core.String;
    }
    if (_json.containsKey('storeCode')) {
      storeCode = _json['storeCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (availability != null) 'availability': availability!,
        if (instoreProductLocation != null)
          'instoreProductLocation': instoreProductLocation!,
        if (kind != null) 'kind': kind!,
        if (pickupMethod != null) 'pickupMethod': pickupMethod!,
        if (pickupSla != null) 'pickupSla': pickupSla!,
        if (price != null) 'price': price!.toJson(),
        if (quantity != null) 'quantity': quantity!,
        if (salePrice != null) 'salePrice': salePrice!.toJson(),
        if (salePriceEffectiveDate != null)
          'salePriceEffectiveDate': salePriceEffectiveDate!,
        if (storeCode != null) 'storeCode': storeCode!,
      };
}

class LocalinventoryCustomBatchRequest {
  /// The request entries to be processed in the batch.
  core.List<LocalinventoryCustomBatchRequestEntry>? entries;

  LocalinventoryCustomBatchRequest();

  LocalinventoryCustomBatchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<LocalinventoryCustomBatchRequestEntry>((value) =>
              LocalinventoryCustomBatchRequestEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

/// Batch entry encoding a single local inventory update request.
class LocalinventoryCustomBatchRequestEntry {
  /// An entry ID, unique within the batch request.
  core.int? batchId;

  /// Local inventory of the product.
  LocalInventory? localInventory;

  /// The ID of the managing account.
  core.String? merchantId;

  /// Method of the batch request entry.
  ///
  /// Acceptable values are: - "`insert`"
  core.String? method;

  /// The ID of the product for which to update local inventory.
  core.String? productId;

  LocalinventoryCustomBatchRequestEntry();

  LocalinventoryCustomBatchRequestEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('localInventory')) {
      localInventory = LocalInventory.fromJson(
          _json['localInventory'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (localInventory != null) 'localInventory': localInventory!.toJson(),
        if (merchantId != null) 'merchantId': merchantId!,
        if (method != null) 'method': method!,
        if (productId != null) 'productId': productId!,
      };
}

class LocalinventoryCustomBatchResponse {
  /// The result of the execution of the batch requests.
  core.List<LocalinventoryCustomBatchResponseEntry>? entries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#localinventoryCustomBatchResponse".
  core.String? kind;

  LocalinventoryCustomBatchResponse();

  LocalinventoryCustomBatchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<LocalinventoryCustomBatchResponseEntry>((value) =>
              LocalinventoryCustomBatchResponseEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// Batch entry encoding a single local inventory update response.
class LocalinventoryCustomBatchResponseEntry {
  /// The ID of the request entry this entry responds to.
  core.int? batchId;

  /// A list of errors defined if and only if the request failed.
  Errors? errors;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#localinventoryCustomBatchResponseEntry`"
  core.String? kind;

  LocalinventoryCustomBatchResponseEntry();

  LocalinventoryCustomBatchResponseEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('errors')) {
      errors = Errors.fromJson(
          _json['errors'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (errors != null) 'errors': errors!.toJson(),
        if (kind != null) 'kind': kind!,
      };
}

class LocationIdSet {
  /// A non-empty list of location IDs.
  ///
  /// They must all be of the same location type (e.g., state).
  core.List<core.String>? locationIds;

  LocationIdSet();

  LocationIdSet.fromJson(core.Map _json) {
    if (_json.containsKey('locationIds')) {
      locationIds = (_json['locationIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (locationIds != null) 'locationIds': locationIds!,
      };
}

class LoyaltyPoints {
  /// Name of loyalty points program.
  ///
  /// It is recommended to limit the name to 12 full-width characters or 24
  /// Roman characters.
  core.String? name;

  /// The retailer's loyalty points in absolute value.
  core.String? pointsValue;

  /// The ratio of a point when converted to currency.
  ///
  /// Google assumes currency based on Merchant Center settings. If ratio is
  /// left out, it defaults to 1.0.
  core.double? ratio;

  LoyaltyPoints();

  LoyaltyPoints.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('pointsValue')) {
      pointsValue = _json['pointsValue'] as core.String;
    }
    if (_json.containsKey('ratio')) {
      ratio = (_json['ratio'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (pointsValue != null) 'pointsValue': pointsValue!,
        if (ratio != null) 'ratio': ratio!,
      };
}

/// Order return.
///
/// Production access (all methods) requires the order manager role. Sandbox
/// access does not.
class MerchantOrderReturn {
  /// The date of creation of the return, in ISO 8601 format.
  core.String? creationDate;

  /// Merchant defined order ID.
  core.String? merchantOrderId;

  /// Google order ID.
  core.String? orderId;

  /// Order return ID generated by Google.
  core.String? orderReturnId;

  /// Items of the return.
  core.List<MerchantOrderReturnItem>? returnItems;

  /// Information about shipping costs.
  ReturnPricingInfo? returnPricingInfo;

  /// Shipments of the return.
  core.List<ReturnShipment>? returnShipments;

  MerchantOrderReturn();

  MerchantOrderReturn.fromJson(core.Map _json) {
    if (_json.containsKey('creationDate')) {
      creationDate = _json['creationDate'] as core.String;
    }
    if (_json.containsKey('merchantOrderId')) {
      merchantOrderId = _json['merchantOrderId'] as core.String;
    }
    if (_json.containsKey('orderId')) {
      orderId = _json['orderId'] as core.String;
    }
    if (_json.containsKey('orderReturnId')) {
      orderReturnId = _json['orderReturnId'] as core.String;
    }
    if (_json.containsKey('returnItems')) {
      returnItems = (_json['returnItems'] as core.List)
          .map<MerchantOrderReturnItem>((value) =>
              MerchantOrderReturnItem.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('returnPricingInfo')) {
      returnPricingInfo = ReturnPricingInfo.fromJson(
          _json['returnPricingInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('returnShipments')) {
      returnShipments = (_json['returnShipments'] as core.List)
          .map<ReturnShipment>((value) => ReturnShipment.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creationDate != null) 'creationDate': creationDate!,
        if (merchantOrderId != null) 'merchantOrderId': merchantOrderId!,
        if (orderId != null) 'orderId': orderId!,
        if (orderReturnId != null) 'orderReturnId': orderReturnId!,
        if (returnItems != null)
          'returnItems': returnItems!.map((value) => value.toJson()).toList(),
        if (returnPricingInfo != null)
          'returnPricingInfo': returnPricingInfo!.toJson(),
        if (returnShipments != null)
          'returnShipments':
              returnShipments!.map((value) => value.toJson()).toList(),
      };
}

class MerchantOrderReturnItem {
  /// The reason that the customer chooses to return an item.
  CustomerReturnReason? customerReturnReason;

  /// Product level item ID.
  ///
  /// If the returned items are of the same product, they will have the same ID.
  core.String? itemId;

  /// The reason that the merchant chose to reject an item return.
  MerchantRejectionReason? merchantRejectionReason;

  /// The reason that merchant chooses to accept a return item.
  RefundReason? merchantReturnReason;

  /// Product data from the time of the order placement.
  OrderLineItemProduct? product;

  /// Maximum amount that can be refunded for this return item.
  MonetaryAmount? refundableAmount;

  /// Unit level ID for the return item.
  ///
  /// Different units of the same product will have different IDs.
  core.String? returnItemId;

  /// IDs of the return shipments that this return item belongs to.
  core.List<core.String>? returnShipmentIds;

  /// ID of the original shipment group.
  ///
  /// Provided for shipments with invoice support.
  core.String? shipmentGroupId;

  /// ID of the shipment unit assigned by the merchant.
  ///
  /// Provided for shipments with invoice support.
  core.String? shipmentUnitId;

  /// State of the item.
  ///
  /// Acceptable values are: - "`canceled`" - "`new`" - "`received`" -
  /// "`refunded`" - "`rejected`"
  core.String? state;

  MerchantOrderReturnItem();

  MerchantOrderReturnItem.fromJson(core.Map _json) {
    if (_json.containsKey('customerReturnReason')) {
      customerReturnReason = CustomerReturnReason.fromJson(
          _json['customerReturnReason'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('itemId')) {
      itemId = _json['itemId'] as core.String;
    }
    if (_json.containsKey('merchantRejectionReason')) {
      merchantRejectionReason = MerchantRejectionReason.fromJson(
          _json['merchantRejectionReason']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('merchantReturnReason')) {
      merchantReturnReason = RefundReason.fromJson(
          _json['merchantReturnReason'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('product')) {
      product = OrderLineItemProduct.fromJson(
          _json['product'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('refundableAmount')) {
      refundableAmount = MonetaryAmount.fromJson(
          _json['refundableAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('returnItemId')) {
      returnItemId = _json['returnItemId'] as core.String;
    }
    if (_json.containsKey('returnShipmentIds')) {
      returnShipmentIds = (_json['returnShipmentIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('shipmentGroupId')) {
      shipmentGroupId = _json['shipmentGroupId'] as core.String;
    }
    if (_json.containsKey('shipmentUnitId')) {
      shipmentUnitId = _json['shipmentUnitId'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customerReturnReason != null)
          'customerReturnReason': customerReturnReason!.toJson(),
        if (itemId != null) 'itemId': itemId!,
        if (merchantRejectionReason != null)
          'merchantRejectionReason': merchantRejectionReason!.toJson(),
        if (merchantReturnReason != null)
          'merchantReturnReason': merchantReturnReason!.toJson(),
        if (product != null) 'product': product!.toJson(),
        if (refundableAmount != null)
          'refundableAmount': refundableAmount!.toJson(),
        if (returnItemId != null) 'returnItemId': returnItemId!,
        if (returnShipmentIds != null) 'returnShipmentIds': returnShipmentIds!,
        if (shipmentGroupId != null) 'shipmentGroupId': shipmentGroupId!,
        if (shipmentUnitId != null) 'shipmentUnitId': shipmentUnitId!,
        if (state != null) 'state': state!,
      };
}

class MerchantRejectionReason {
  /// Description of the reason.
  core.String? description;

  /// Code of the rejection reason.
  core.String? reasonCode;

  MerchantRejectionReason();

  MerchantRejectionReason.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('reasonCode')) {
      reasonCode = _json['reasonCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (reasonCode != null) 'reasonCode': reasonCode!,
      };
}

/// Performance metrics.
///
/// Values are only set for metrics requested explicitly in the request's search
/// query.
class Metrics {
  /// Number of clicks.
  core.String? clicks;

  /// Click-through rate - the number of clicks merchant's products receive
  /// (clicks) divided by the number of times the products are shown
  /// (impressions).
  core.double? ctr;

  /// Number of times merchant's products are shown.
  core.String? impressions;

  Metrics();

  Metrics.fromJson(core.Map _json) {
    if (_json.containsKey('clicks')) {
      clicks = _json['clicks'] as core.String;
    }
    if (_json.containsKey('ctr')) {
      ctr = (_json['ctr'] as core.num).toDouble();
    }
    if (_json.containsKey('impressions')) {
      impressions = _json['impressions'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clicks != null) 'clicks': clicks!,
        if (ctr != null) 'ctr': ctr!,
        if (impressions != null) 'impressions': impressions!,
      };
}

class MinimumOrderValueTable {
  core.List<MinimumOrderValueTableStoreCodeSetWithMov>? storeCodeSetWithMovs;

  MinimumOrderValueTable();

  MinimumOrderValueTable.fromJson(core.Map _json) {
    if (_json.containsKey('storeCodeSetWithMovs')) {
      storeCodeSetWithMovs = (_json['storeCodeSetWithMovs'] as core.List)
          .map<MinimumOrderValueTableStoreCodeSetWithMov>((value) =>
              MinimumOrderValueTableStoreCodeSetWithMov.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (storeCodeSetWithMovs != null)
          'storeCodeSetWithMovs':
              storeCodeSetWithMovs!.map((value) => value.toJson()).toList(),
      };
}

/// A list of store code sets sharing the same minimum order value.
///
/// At least two sets are required and the last one must be empty, which
/// signifies 'MOV for all other stores'. Each store code can only appear once
/// across all the sets. All prices within a service must have the same
/// currency.
class MinimumOrderValueTableStoreCodeSetWithMov {
  /// A list of unique store codes or empty for the catch all.
  core.List<core.String>? storeCodes;

  /// The minimum order value for the given stores.
  Price? value;

  MinimumOrderValueTableStoreCodeSetWithMov();

  MinimumOrderValueTableStoreCodeSetWithMov.fromJson(core.Map _json) {
    if (_json.containsKey('storeCodes')) {
      storeCodes = (_json['storeCodes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('value')) {
      value =
          Price.fromJson(_json['value'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (storeCodes != null) 'storeCodes': storeCodes!,
        if (value != null) 'value': value!.toJson(),
      };
}

class MonetaryAmount {
  /// The pre-tax or post-tax price depends on the location of the order.
  ///
  /// - For countries (e.g. US) where price attribute excludes tax, this field
  /// corresponds to the pre-tax value. - For coutries (e.g. France) where price
  /// attribute includes tax, this field corresponds to the post-tax value .
  Price? priceAmount;

  /// Tax value, present only for countries where price attribute excludes tax
  /// (e.g. US).
  ///
  /// No tax is referenced as 0 value with the corresponding `currency`.
  Price? taxAmount;

  MonetaryAmount();

  MonetaryAmount.fromJson(core.Map _json) {
    if (_json.containsKey('priceAmount')) {
      priceAmount = Price.fromJson(
          _json['priceAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('taxAmount')) {
      taxAmount = Price.fromJson(
          _json['taxAmount'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (priceAmount != null) 'priceAmount': priceAmount!.toJson(),
        if (taxAmount != null) 'taxAmount': taxAmount!.toJson(),
      };
}

/// Request message for the OnboardProgram method.
class OnboardBuyOnGoogleProgramRequest {
  /// The customer service email.
  core.String? customerServiceEmail;

  OnboardBuyOnGoogleProgramRequest();

  OnboardBuyOnGoogleProgramRequest.fromJson(core.Map _json) {
    if (_json.containsKey('customerServiceEmail')) {
      customerServiceEmail = _json['customerServiceEmail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customerServiceEmail != null)
          'customerServiceEmail': customerServiceEmail!,
      };
}

/// Order.
///
/// Production access (all methods) requires the order manager role. Sandbox
/// access does not.
class Order {
  /// Whether the order was acknowledged.
  core.bool? acknowledged;

  /// List of key-value pairs that are attached to a given order.
  core.List<OrderOrderAnnotation>? annotations;

  /// The billing address.
  OrderAddress? billingAddress;

  /// The details of the customer who placed the order.
  OrderCustomer? customer;

  /// Delivery details for shipments of type `delivery`.
  OrderDeliveryDetails? deliveryDetails;

  /// The REST ID of the order.
  ///
  /// Globally unique.
  core.String? id;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#order`"
  core.String? kind;

  /// Line items that are ordered.
  core.List<OrderLineItem>? lineItems;
  core.String? merchantId;

  /// Merchant-provided ID of the order.
  core.String? merchantOrderId;

  /// The net amount for the order (price part).
  ///
  /// For example, if an order was originally for $100 and a refund was issued
  /// for $20, the net amount will be $80.
  Price? netPriceAmount;

  /// The net amount for the order (tax part).
  ///
  /// Note that in certain cases due to taxable base adjustment `netTaxAmount`
  /// might not match to a sum of tax field across all lineItems and refunds.
  Price? netTaxAmount;

  /// The status of the payment.
  ///
  /// Acceptable values are: - "`paymentCaptured`" - "`paymentRejected`" -
  /// "`paymentSecured`" - "`pendingAuthorization`"
  core.String? paymentStatus;

  /// Pickup details for shipments of type `pickup`.
  OrderPickupDetails? pickupDetails;

  /// The date when the order was placed, in ISO 8601 format.
  core.String? placedDate;

  /// Promotions associated with the order.
  ///
  /// To determine which promotions apply to which products, check the
  /// `Promotions[].appliedItems[].lineItemId` field against the
  /// `LineItems[].id` field for each promotion. If a promotion is applied to
  /// more than 1 offerId, divide the discount value by the number of affected
  /// offers to determine how much discount to apply to each offerId. Examples:
  /// 1. To calculate price paid by the customer for a single line item
  /// including the discount: For each promotion, subtract the
  /// `LineItems[].adjustments[].priceAdjustment.value` amount from the
  /// `LineItems[].Price.value`. 2. To calculate price paid by the customer for
  /// a single line item including the discount in case of multiple quantity:
  /// For each promotion, divide the
  /// `LineItems[].adjustments[].priceAdjustment.value` by the quantity of
  /// products then subtract the resulting value from the
  /// `LineItems[].Product.Price.value` for each quantity item. Only 1 promotion
  /// can be applied to an offerId in a given order. To refund an item which had
  /// a promotion applied to it, make sure to refund the amount after first
  /// subtracting the promotion discount from the item price. More details about
  /// the program are here.
  core.List<OrderPromotion>? promotions;

  /// Refunds for the order.
  core.List<OrderRefund>? refunds;

  /// Shipments of the order.
  core.List<OrderShipment>? shipments;

  /// The total cost of shipping for all items.
  Price? shippingCost;

  /// The tax for the total shipping cost.
  Price? shippingCostTax;

  /// The status of the order.
  ///
  /// Acceptable values are: - "`canceled`" - "`delivered`" - "`inProgress`" -
  /// "`partiallyDelivered`" - "`partiallyReturned`" - "`partiallyShipped`" -
  /// "`pendingShipment`" - "`returned`" - "`shipped`"
  core.String? status;

  /// The party responsible for collecting and remitting taxes.
  ///
  /// Acceptable values are: - "`marketplaceFacilitator`" - "`merchant`"
  core.String? taxCollector;

  Order();

  Order.fromJson(core.Map _json) {
    if (_json.containsKey('acknowledged')) {
      acknowledged = _json['acknowledged'] as core.bool;
    }
    if (_json.containsKey('annotations')) {
      annotations = (_json['annotations'] as core.List)
          .map<OrderOrderAnnotation>((value) => OrderOrderAnnotation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('billingAddress')) {
      billingAddress = OrderAddress.fromJson(
          _json['billingAddress'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('customer')) {
      customer = OrderCustomer.fromJson(
          _json['customer'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deliveryDetails')) {
      deliveryDetails = OrderDeliveryDetails.fromJson(
          _json['deliveryDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lineItems')) {
      lineItems = (_json['lineItems'] as core.List)
          .map<OrderLineItem>((value) => OrderLineItem.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('merchantOrderId')) {
      merchantOrderId = _json['merchantOrderId'] as core.String;
    }
    if (_json.containsKey('netPriceAmount')) {
      netPriceAmount = Price.fromJson(
          _json['netPriceAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('netTaxAmount')) {
      netTaxAmount = Price.fromJson(
          _json['netTaxAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('paymentStatus')) {
      paymentStatus = _json['paymentStatus'] as core.String;
    }
    if (_json.containsKey('pickupDetails')) {
      pickupDetails = OrderPickupDetails.fromJson(
          _json['pickupDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('placedDate')) {
      placedDate = _json['placedDate'] as core.String;
    }
    if (_json.containsKey('promotions')) {
      promotions = (_json['promotions'] as core.List)
          .map<OrderPromotion>((value) => OrderPromotion.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('refunds')) {
      refunds = (_json['refunds'] as core.List)
          .map<OrderRefund>((value) => OrderRefund.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shipments')) {
      shipments = (_json['shipments'] as core.List)
          .map<OrderShipment>((value) => OrderShipment.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shippingCost')) {
      shippingCost = Price.fromJson(
          _json['shippingCost'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shippingCostTax')) {
      shippingCostTax = Price.fromJson(
          _json['shippingCostTax'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('taxCollector')) {
      taxCollector = _json['taxCollector'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (acknowledged != null) 'acknowledged': acknowledged!,
        if (annotations != null)
          'annotations': annotations!.map((value) => value.toJson()).toList(),
        if (billingAddress != null) 'billingAddress': billingAddress!.toJson(),
        if (customer != null) 'customer': customer!.toJson(),
        if (deliveryDetails != null)
          'deliveryDetails': deliveryDetails!.toJson(),
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (lineItems != null)
          'lineItems': lineItems!.map((value) => value.toJson()).toList(),
        if (merchantId != null) 'merchantId': merchantId!,
        if (merchantOrderId != null) 'merchantOrderId': merchantOrderId!,
        if (netPriceAmount != null) 'netPriceAmount': netPriceAmount!.toJson(),
        if (netTaxAmount != null) 'netTaxAmount': netTaxAmount!.toJson(),
        if (paymentStatus != null) 'paymentStatus': paymentStatus!,
        if (pickupDetails != null) 'pickupDetails': pickupDetails!.toJson(),
        if (placedDate != null) 'placedDate': placedDate!,
        if (promotions != null)
          'promotions': promotions!.map((value) => value.toJson()).toList(),
        if (refunds != null)
          'refunds': refunds!.map((value) => value.toJson()).toList(),
        if (shipments != null)
          'shipments': shipments!.map((value) => value.toJson()).toList(),
        if (shippingCost != null) 'shippingCost': shippingCost!.toJson(),
        if (shippingCostTax != null)
          'shippingCostTax': shippingCostTax!.toJson(),
        if (status != null) 'status': status!,
        if (taxCollector != null) 'taxCollector': taxCollector!,
      };
}

class OrderAddress {
  /// CLDR country code (e.g. "US").
  core.String? country;

  /// Strings representing the lines of the printed label for mailing the order,
  /// for example: John Smith 1600 Amphitheatre Parkway Mountain View, CA, 94043
  /// United States
  core.List<core.String>? fullAddress;

  /// Whether the address is a post office box.
  core.bool? isPostOfficeBox;

  /// City, town or commune.
  ///
  /// May also include dependent localities or sublocalities (e.g. neighborhoods
  /// or suburbs).
  core.String? locality;

  /// Postal Code or ZIP (e.g. "94043").
  core.String? postalCode;

  /// Name of the recipient.
  core.String? recipientName;

  /// Top-level administrative subdivision of the country.
  ///
  /// For example, a state like California ("CA") or a province like Quebec
  /// ("QC").
  core.String? region;

  /// Street-level part of the address.
  core.List<core.String>? streetAddress;

  OrderAddress();

  OrderAddress.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('fullAddress')) {
      fullAddress = (_json['fullAddress'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('isPostOfficeBox')) {
      isPostOfficeBox = _json['isPostOfficeBox'] as core.bool;
    }
    if (_json.containsKey('locality')) {
      locality = _json['locality'] as core.String;
    }
    if (_json.containsKey('postalCode')) {
      postalCode = _json['postalCode'] as core.String;
    }
    if (_json.containsKey('recipientName')) {
      recipientName = _json['recipientName'] as core.String;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('streetAddress')) {
      streetAddress = (_json['streetAddress'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (fullAddress != null) 'fullAddress': fullAddress!,
        if (isPostOfficeBox != null) 'isPostOfficeBox': isPostOfficeBox!,
        if (locality != null) 'locality': locality!,
        if (postalCode != null) 'postalCode': postalCode!,
        if (recipientName != null) 'recipientName': recipientName!,
        if (region != null) 'region': region!,
        if (streetAddress != null) 'streetAddress': streetAddress!,
      };
}

class OrderCancellation {
  /// The actor that created the cancellation.
  ///
  /// Acceptable values are: - "`customer`" - "`googleBot`" -
  /// "`googleCustomerService`" - "`googlePayments`" - "`googleSabre`" -
  /// "`merchant`"
  core.String? actor;

  /// Date on which the cancellation has been created, in ISO 8601 format.
  core.String? creationDate;

  /// The quantity that was canceled.
  core.int? quantity;

  /// The reason for the cancellation.
  ///
  /// Orders that are canceled with a noInventory reason will lead to the
  /// removal of the product from Buy on Google until you make an update to that
  /// product. This will not affect your Shopping ads. Acceptable values are: -
  /// "`autoPostInternal`" - "`autoPostInvalidBillingAddress`" -
  /// "`autoPostNoInventory`" - "`autoPostPriceError`" -
  /// "`autoPostUndeliverableShippingAddress`" - "`couponAbuse`" -
  /// "`customerCanceled`" - "`customerInitiatedCancel`" -
  /// "`customerSupportRequested`" - "`failToPushOrderGoogleError`" -
  /// "`failToPushOrderMerchantError`" -
  /// "`failToPushOrderMerchantFulfillmentError`" -
  /// "`failToPushOrderToMerchant`" - "`failToPushOrderToMerchantOutOfStock`" -
  /// "`invalidCoupon`" - "`malformedShippingAddress`" -
  /// "`merchantDidNotShipOnTime`" - "`noInventory`" - "`orderTimeout`" -
  /// "`other`" - "`paymentAbuse`" - "`paymentDeclined`" - "`priceError`" -
  /// "`returnRefundAbuse`" - "`shippingPriceError`" - "`taxError`" -
  /// "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`"
  core.String? reason;

  /// The explanation of the reason.
  core.String? reasonText;

  OrderCancellation();

  OrderCancellation.fromJson(core.Map _json) {
    if (_json.containsKey('actor')) {
      actor = _json['actor'] as core.String;
    }
    if (_json.containsKey('creationDate')) {
      creationDate = _json['creationDate'] as core.String;
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.int;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('reasonText')) {
      reasonText = _json['reasonText'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (actor != null) 'actor': actor!,
        if (creationDate != null) 'creationDate': creationDate!,
        if (quantity != null) 'quantity': quantity!,
        if (reason != null) 'reason': reason!,
        if (reasonText != null) 'reasonText': reasonText!,
      };
}

class OrderCustomer {
  /// Full name of the customer.
  core.String? fullName;

  /// Email address for the merchant to send value-added tax or invoice
  /// documentation of the order.
  ///
  /// Only the last document sent is made available to the customer. For more
  /// information, see About automated VAT invoicing for Buy on Google.
  core.String? invoiceReceivingEmail;

  /// Loyalty program information.
  OrderCustomerLoyaltyInfo? loyaltyInfo;

  /// Customer's marketing preferences.
  ///
  /// Contains the marketing opt-in information that is current at the time that
  /// the merchant call. User preference selections can change from one order to
  /// the next so preferences must be checked with every order.
  OrderCustomerMarketingRightsInfo? marketingRightsInfo;

  OrderCustomer();

  OrderCustomer.fromJson(core.Map _json) {
    if (_json.containsKey('fullName')) {
      fullName = _json['fullName'] as core.String;
    }
    if (_json.containsKey('invoiceReceivingEmail')) {
      invoiceReceivingEmail = _json['invoiceReceivingEmail'] as core.String;
    }
    if (_json.containsKey('loyaltyInfo')) {
      loyaltyInfo = OrderCustomerLoyaltyInfo.fromJson(
          _json['loyaltyInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('marketingRightsInfo')) {
      marketingRightsInfo = OrderCustomerMarketingRightsInfo.fromJson(
          _json['marketingRightsInfo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fullName != null) 'fullName': fullName!,
        if (invoiceReceivingEmail != null)
          'invoiceReceivingEmail': invoiceReceivingEmail!,
        if (loyaltyInfo != null) 'loyaltyInfo': loyaltyInfo!.toJson(),
        if (marketingRightsInfo != null)
          'marketingRightsInfo': marketingRightsInfo!.toJson(),
      };
}

class OrderCustomerLoyaltyInfo {
  /// The loyalty card/membership number.
  core.String? loyaltyNumber;

  /// Name of card/membership holder, this field will be populated when
  core.String? name;

  OrderCustomerLoyaltyInfo();

  OrderCustomerLoyaltyInfo.fromJson(core.Map _json) {
    if (_json.containsKey('loyaltyNumber')) {
      loyaltyNumber = _json['loyaltyNumber'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (loyaltyNumber != null) 'loyaltyNumber': loyaltyNumber!,
        if (name != null) 'name': name!,
      };
}

class OrderCustomerMarketingRightsInfo {
  /// Last known customer selection regarding marketing preferences.
  ///
  /// In certain cases this selection might not be known, so this field would be
  /// empty. If a customer selected `granted` in their most recent order, they
  /// can be subscribed to marketing emails. Customers who have chosen `denied`
  /// must not be subscribed, or must be unsubscribed if already opted-in.
  /// Acceptable values are: - "`denied`" - "`granted`"
  core.String? explicitMarketingPreference;

  /// Timestamp when last time marketing preference was updated.
  ///
  /// Could be empty, if user wasn't offered a selection yet.
  core.String? lastUpdatedTimestamp;

  /// Email address that can be used for marketing purposes.
  ///
  /// The field may be empty even if `explicitMarketingPreference` is 'granted'.
  /// This happens when retrieving an old order from the customer who deleted
  /// their account.
  core.String? marketingEmailAddress;

  OrderCustomerMarketingRightsInfo();

  OrderCustomerMarketingRightsInfo.fromJson(core.Map _json) {
    if (_json.containsKey('explicitMarketingPreference')) {
      explicitMarketingPreference =
          _json['explicitMarketingPreference'] as core.String;
    }
    if (_json.containsKey('lastUpdatedTimestamp')) {
      lastUpdatedTimestamp = _json['lastUpdatedTimestamp'] as core.String;
    }
    if (_json.containsKey('marketingEmailAddress')) {
      marketingEmailAddress = _json['marketingEmailAddress'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (explicitMarketingPreference != null)
          'explicitMarketingPreference': explicitMarketingPreference!,
        if (lastUpdatedTimestamp != null)
          'lastUpdatedTimestamp': lastUpdatedTimestamp!,
        if (marketingEmailAddress != null)
          'marketingEmailAddress': marketingEmailAddress!,
      };
}

class OrderDeliveryDetails {
  /// The delivery address
  OrderAddress? address;

  /// The phone number of the person receiving the delivery.
  core.String? phoneNumber;

  OrderDeliveryDetails();

  OrderDeliveryDetails.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = OrderAddress.fromJson(
          _json['address'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!.toJson(),
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
      };
}

class OrderLineItem {
  /// Price and tax adjustments applied on the line item.
  core.List<OrderLineItemAdjustment>? adjustments;

  /// Annotations that are attached to the line item.
  core.List<OrderMerchantProvidedAnnotation>? annotations;

  /// Cancellations of the line item.
  core.List<OrderCancellation>? cancellations;

  /// The ID of the line item.
  core.String? id;

  /// Total price for the line item.
  ///
  /// For example, if two items for $10 are purchased, the total price will be
  /// $20.
  Price? price;

  /// Product data as seen by customer from the time of the order placement.
  ///
  /// Note that certain attributes values (e.g. title or gtin) might be
  /// reformatted and no longer match values submitted via product feed.
  OrderLineItemProduct? product;

  /// Number of items canceled.
  core.int? quantityCanceled;

  /// Number of items delivered.
  core.int? quantityDelivered;

  /// Number of items ordered.
  core.int? quantityOrdered;

  /// Number of items pending.
  core.int? quantityPending;

  /// Number of items ready for pickup.
  core.int? quantityReadyForPickup;

  /// Number of items returned.
  core.int? quantityReturned;

  /// Number of items shipped.
  core.int? quantityShipped;

  /// Number of items undeliverable.
  core.int? quantityUndeliverable;

  /// Details of the return policy for the line item.
  OrderLineItemReturnInfo? returnInfo;

  /// Returns of the line item.
  core.List<OrderReturn>? returns;

  /// Details of the requested shipping for the line item.
  OrderLineItemShippingDetails? shippingDetails;

  /// Total tax amount for the line item.
  ///
  /// For example, if two items are purchased, and each have a cost tax of $2,
  /// the total tax amount will be $4.
  Price? tax;

  OrderLineItem();

  OrderLineItem.fromJson(core.Map _json) {
    if (_json.containsKey('adjustments')) {
      adjustments = (_json['adjustments'] as core.List)
          .map<OrderLineItemAdjustment>((value) =>
              OrderLineItemAdjustment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('annotations')) {
      annotations = (_json['annotations'] as core.List)
          .map<OrderMerchantProvidedAnnotation>((value) =>
              OrderMerchantProvidedAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('cancellations')) {
      cancellations = (_json['cancellations'] as core.List)
          .map<OrderCancellation>((value) => OrderCancellation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('product')) {
      product = OrderLineItemProduct.fromJson(
          _json['product'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('quantityCanceled')) {
      quantityCanceled = _json['quantityCanceled'] as core.int;
    }
    if (_json.containsKey('quantityDelivered')) {
      quantityDelivered = _json['quantityDelivered'] as core.int;
    }
    if (_json.containsKey('quantityOrdered')) {
      quantityOrdered = _json['quantityOrdered'] as core.int;
    }
    if (_json.containsKey('quantityPending')) {
      quantityPending = _json['quantityPending'] as core.int;
    }
    if (_json.containsKey('quantityReadyForPickup')) {
      quantityReadyForPickup = _json['quantityReadyForPickup'] as core.int;
    }
    if (_json.containsKey('quantityReturned')) {
      quantityReturned = _json['quantityReturned'] as core.int;
    }
    if (_json.containsKey('quantityShipped')) {
      quantityShipped = _json['quantityShipped'] as core.int;
    }
    if (_json.containsKey('quantityUndeliverable')) {
      quantityUndeliverable = _json['quantityUndeliverable'] as core.int;
    }
    if (_json.containsKey('returnInfo')) {
      returnInfo = OrderLineItemReturnInfo.fromJson(
          _json['returnInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('returns')) {
      returns = (_json['returns'] as core.List)
          .map<OrderReturn>((value) => OrderReturn.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shippingDetails')) {
      shippingDetails = OrderLineItemShippingDetails.fromJson(
          _json['shippingDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tax')) {
      tax = Price.fromJson(_json['tax'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adjustments != null)
          'adjustments': adjustments!.map((value) => value.toJson()).toList(),
        if (annotations != null)
          'annotations': annotations!.map((value) => value.toJson()).toList(),
        if (cancellations != null)
          'cancellations':
              cancellations!.map((value) => value.toJson()).toList(),
        if (id != null) 'id': id!,
        if (price != null) 'price': price!.toJson(),
        if (product != null) 'product': product!.toJson(),
        if (quantityCanceled != null) 'quantityCanceled': quantityCanceled!,
        if (quantityDelivered != null) 'quantityDelivered': quantityDelivered!,
        if (quantityOrdered != null) 'quantityOrdered': quantityOrdered!,
        if (quantityPending != null) 'quantityPending': quantityPending!,
        if (quantityReadyForPickup != null)
          'quantityReadyForPickup': quantityReadyForPickup!,
        if (quantityReturned != null) 'quantityReturned': quantityReturned!,
        if (quantityShipped != null) 'quantityShipped': quantityShipped!,
        if (quantityUndeliverable != null)
          'quantityUndeliverable': quantityUndeliverable!,
        if (returnInfo != null) 'returnInfo': returnInfo!.toJson(),
        if (returns != null)
          'returns': returns!.map((value) => value.toJson()).toList(),
        if (shippingDetails != null)
          'shippingDetails': shippingDetails!.toJson(),
        if (tax != null) 'tax': tax!.toJson(),
      };
}

class OrderLineItemAdjustment {
  /// Adjustment for total price of the line item.
  Price? priceAdjustment;

  /// Adjustment for total tax of the line item.
  Price? taxAdjustment;

  /// Type of this adjustment.
  ///
  /// Acceptable values are: - "`promotion`"
  core.String? type;

  OrderLineItemAdjustment();

  OrderLineItemAdjustment.fromJson(core.Map _json) {
    if (_json.containsKey('priceAdjustment')) {
      priceAdjustment = Price.fromJson(
          _json['priceAdjustment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('taxAdjustment')) {
      taxAdjustment = Price.fromJson(
          _json['taxAdjustment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (priceAdjustment != null)
          'priceAdjustment': priceAdjustment!.toJson(),
        if (taxAdjustment != null) 'taxAdjustment': taxAdjustment!.toJson(),
        if (type != null) 'type': type!,
      };
}

class OrderLineItemProduct {
  /// Brand of the item.
  core.String? brand;

  /// Condition or state of the item.
  ///
  /// Acceptable values are: - "`new`" - "`refurbished`" - "`used`"
  core.String? condition;

  /// The two-letter ISO 639-1 language code for the item.
  core.String? contentLanguage;

  /// Associated fees at order creation time.
  core.List<OrderLineItemProductFee>? fees;

  /// Global Trade Item Number (GTIN) of the item.
  core.String? gtin;

  /// The REST ID of the product.
  core.String? id;

  /// URL of an image of the item.
  core.String? imageLink;

  /// Shared identifier for all variants of the same product.
  core.String? itemGroupId;

  /// Manufacturer Part Number (MPN) of the item.
  core.String? mpn;

  /// An identifier of the item.
  core.String? offerId;

  /// Price of the item.
  Price? price;

  /// URL to the cached image shown to the user when order was placed.
  core.String? shownImage;

  /// The CLDR territory // code of the target country of the product.
  core.String? targetCountry;

  /// The title of the product.
  core.String? title;

  /// Variant attributes for the item.
  ///
  /// These are dimensions of the product, such as color, gender, material,
  /// pattern, and size. You can find a comprehensive list of variant attributes
  /// here.
  core.List<OrderLineItemProductVariantAttribute>? variantAttributes;

  OrderLineItemProduct();

  OrderLineItemProduct.fromJson(core.Map _json) {
    if (_json.containsKey('brand')) {
      brand = _json['brand'] as core.String;
    }
    if (_json.containsKey('condition')) {
      condition = _json['condition'] as core.String;
    }
    if (_json.containsKey('contentLanguage')) {
      contentLanguage = _json['contentLanguage'] as core.String;
    }
    if (_json.containsKey('fees')) {
      fees = (_json['fees'] as core.List)
          .map<OrderLineItemProductFee>((value) =>
              OrderLineItemProductFee.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('gtin')) {
      gtin = _json['gtin'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('imageLink')) {
      imageLink = _json['imageLink'] as core.String;
    }
    if (_json.containsKey('itemGroupId')) {
      itemGroupId = _json['itemGroupId'] as core.String;
    }
    if (_json.containsKey('mpn')) {
      mpn = _json['mpn'] as core.String;
    }
    if (_json.containsKey('offerId')) {
      offerId = _json['offerId'] as core.String;
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shownImage')) {
      shownImage = _json['shownImage'] as core.String;
    }
    if (_json.containsKey('targetCountry')) {
      targetCountry = _json['targetCountry'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('variantAttributes')) {
      variantAttributes = (_json['variantAttributes'] as core.List)
          .map<OrderLineItemProductVariantAttribute>((value) =>
              OrderLineItemProductVariantAttribute.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (brand != null) 'brand': brand!,
        if (condition != null) 'condition': condition!,
        if (contentLanguage != null) 'contentLanguage': contentLanguage!,
        if (fees != null) 'fees': fees!.map((value) => value.toJson()).toList(),
        if (gtin != null) 'gtin': gtin!,
        if (id != null) 'id': id!,
        if (imageLink != null) 'imageLink': imageLink!,
        if (itemGroupId != null) 'itemGroupId': itemGroupId!,
        if (mpn != null) 'mpn': mpn!,
        if (offerId != null) 'offerId': offerId!,
        if (price != null) 'price': price!.toJson(),
        if (shownImage != null) 'shownImage': shownImage!,
        if (targetCountry != null) 'targetCountry': targetCountry!,
        if (title != null) 'title': title!,
        if (variantAttributes != null)
          'variantAttributes':
              variantAttributes!.map((value) => value.toJson()).toList(),
      };
}

class OrderLineItemProductFee {
  /// Amount of the fee.
  Price? amount;

  /// Name of the fee.
  core.String? name;

  OrderLineItemProductFee();

  OrderLineItemProductFee.fromJson(core.Map _json) {
    if (_json.containsKey('amount')) {
      amount = Price.fromJson(
          _json['amount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (amount != null) 'amount': amount!.toJson(),
        if (name != null) 'name': name!,
      };
}

class OrderLineItemProductVariantAttribute {
  /// The dimension of the variant.
  core.String? dimension;

  /// The value for the dimension.
  core.String? value;

  OrderLineItemProductVariantAttribute();

  OrderLineItemProductVariantAttribute.fromJson(core.Map _json) {
    if (_json.containsKey('dimension')) {
      dimension = _json['dimension'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimension != null) 'dimension': dimension!,
        if (value != null) 'value': value!,
      };
}

class OrderLineItemReturnInfo {
  /// How many days later the item can be returned.
  ///
  /// Required.
  core.int? daysToReturn;

  /// Whether the item is returnable.
  ///
  /// Required.
  core.bool? isReturnable;

  /// URL of the item return policy.
  ///
  /// Required.
  core.String? policyUrl;

  OrderLineItemReturnInfo();

  OrderLineItemReturnInfo.fromJson(core.Map _json) {
    if (_json.containsKey('daysToReturn')) {
      daysToReturn = _json['daysToReturn'] as core.int;
    }
    if (_json.containsKey('isReturnable')) {
      isReturnable = _json['isReturnable'] as core.bool;
    }
    if (_json.containsKey('policyUrl')) {
      policyUrl = _json['policyUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (daysToReturn != null) 'daysToReturn': daysToReturn!,
        if (isReturnable != null) 'isReturnable': isReturnable!,
        if (policyUrl != null) 'policyUrl': policyUrl!,
      };
}

class OrderLineItemShippingDetails {
  /// The delivery by date, in ISO 8601 format.
  ///
  /// Required.
  core.String? deliverByDate;

  /// Details of the shipping method.
  ///
  /// Required.
  OrderLineItemShippingDetailsMethod? method;

  /// The promised time in minutes in which the order will be ready for pickup.
  ///
  /// This only applies to buy-online-pickup-in-store same-day order.
  core.int? pickupPromiseInMinutes;

  /// The ship by date, in ISO 8601 format.
  ///
  /// Required.
  core.String? shipByDate;

  /// Type of shipment.
  ///
  /// Indicates whether `deliveryDetails` or `pickupDetails` is applicable for
  /// this shipment. Acceptable values are: - "`delivery`" - "`pickup`"
  core.String? type;

  OrderLineItemShippingDetails();

  OrderLineItemShippingDetails.fromJson(core.Map _json) {
    if (_json.containsKey('deliverByDate')) {
      deliverByDate = _json['deliverByDate'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = OrderLineItemShippingDetailsMethod.fromJson(
          _json['method'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pickupPromiseInMinutes')) {
      pickupPromiseInMinutes = _json['pickupPromiseInMinutes'] as core.int;
    }
    if (_json.containsKey('shipByDate')) {
      shipByDate = _json['shipByDate'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deliverByDate != null) 'deliverByDate': deliverByDate!,
        if (method != null) 'method': method!.toJson(),
        if (pickupPromiseInMinutes != null)
          'pickupPromiseInMinutes': pickupPromiseInMinutes!,
        if (shipByDate != null) 'shipByDate': shipByDate!,
        if (type != null) 'type': type!,
      };
}

class OrderLineItemShippingDetailsMethod {
  /// The carrier for the shipping.
  ///
  /// Optional. See `shipments[].carrier` for a list of acceptable values.
  core.String? carrier;

  /// Maximum transit time.
  ///
  /// Required.
  core.int? maxDaysInTransit;

  /// The name of the shipping method.
  ///
  /// Required.
  core.String? methodName;

  /// Minimum transit time.
  ///
  /// Required.
  core.int? minDaysInTransit;

  OrderLineItemShippingDetailsMethod();

  OrderLineItemShippingDetailsMethod.fromJson(core.Map _json) {
    if (_json.containsKey('carrier')) {
      carrier = _json['carrier'] as core.String;
    }
    if (_json.containsKey('maxDaysInTransit')) {
      maxDaysInTransit = _json['maxDaysInTransit'] as core.int;
    }
    if (_json.containsKey('methodName')) {
      methodName = _json['methodName'] as core.String;
    }
    if (_json.containsKey('minDaysInTransit')) {
      minDaysInTransit = _json['minDaysInTransit'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrier != null) 'carrier': carrier!,
        if (maxDaysInTransit != null) 'maxDaysInTransit': maxDaysInTransit!,
        if (methodName != null) 'methodName': methodName!,
        if (minDaysInTransit != null) 'minDaysInTransit': minDaysInTransit!,
      };
}

class OrderMerchantProvidedAnnotation {
  /// Key for additional merchant provided (as key-value pairs) annotation about
  /// the line item.
  core.String? key;

  /// Value for additional merchant provided (as key-value pairs) annotation
  /// about the line item.
  core.String? value;

  OrderMerchantProvidedAnnotation();

  OrderMerchantProvidedAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (value != null) 'value': value!,
      };
}

class OrderOrderAnnotation {
  /// Key for additional google provided (as key-value pairs) annotation.
  core.String? key;

  /// Value for additional google provided (as key-value pairs) annotation.
  core.String? value;

  OrderOrderAnnotation();

  OrderOrderAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (value != null) 'value': value!,
      };
}

class OrderPickupDetails {
  /// Address of the pickup location where the shipment should be sent.
  ///
  /// Note that `recipientName` in the address is the name of the business at
  /// the pickup location.
  OrderAddress? address;

  /// Collectors authorized to pick up shipment from the pickup location.
  core.List<OrderPickupDetailsCollector>? collectors;

  /// ID of the pickup location.
  core.String? locationId;

  /// The pickup type of this order.
  ///
  /// Acceptable values are: - "`merchantStore`" - "`merchantStoreCurbside`" -
  /// "`merchantStoreLocker`" - "`thirdPartyPickupPoint`" - "`thirdPartyLocker`"
  core.String? pickupType;

  OrderPickupDetails();

  OrderPickupDetails.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = OrderAddress.fromJson(
          _json['address'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('collectors')) {
      collectors = (_json['collectors'] as core.List)
          .map<OrderPickupDetailsCollector>((value) =>
              OrderPickupDetailsCollector.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('locationId')) {
      locationId = _json['locationId'] as core.String;
    }
    if (_json.containsKey('pickupType')) {
      pickupType = _json['pickupType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!.toJson(),
        if (collectors != null)
          'collectors': collectors!.map((value) => value.toJson()).toList(),
        if (locationId != null) 'locationId': locationId!,
        if (pickupType != null) 'pickupType': pickupType!,
      };
}

class OrderPickupDetailsCollector {
  /// Name of the person picking up the shipment.
  core.String? name;

  /// Phone number of the person picking up the shipment.
  core.String? phoneNumber;

  OrderPickupDetailsCollector();

  OrderPickupDetailsCollector.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
      };
}

class OrderPromotion {
  /// Items that this promotion may be applied to.
  ///
  /// If empty, there are no restrictions on applicable items and quantity. This
  /// field will also be empty for shipping promotions because shipping is not
  /// tied to any specific item.
  core.List<OrderPromotionItem>? applicableItems;

  /// Items that this promotion have been applied to.
  ///
  /// Do not provide for `orders.createtestorder`. This field will be empty for
  /// shipping promotions because shipping is not tied to any specific item.
  core.List<OrderPromotionItem>? appliedItems;

  /// Promotion end time in ISO 8601 format.
  ///
  /// Date, time, and offset required, e.g., "2020-01-02T09:00:00+01:00" or
  /// "2020-01-02T09:00:00Z".
  core.String? endTime;

  /// The party funding the promotion.
  ///
  /// Only `merchant` is supported for `orders.createtestorder`. Acceptable
  /// values are: - "`google`" - "`merchant`"
  ///
  /// Required.
  core.String? funder;

  /// This field is used to identify promotions within merchants' own systems.
  ///
  /// Required.
  core.String? merchantPromotionId;

  /// Estimated discount applied to price.
  ///
  /// Amount is pre-tax or post-tax depending on location of order.
  Price? priceValue;

  /// A short title of the promotion to be shown on the checkout page.
  ///
  /// Do not provide for `orders.createtestorder`.
  core.String? shortTitle;

  /// Promotion start time in ISO 8601 format.
  ///
  /// Date, time, and offset required, e.g., "2020-01-02T09:00:00+01:00" or
  /// "2020-01-02T09:00:00Z".
  core.String? startTime;

  /// The category of the promotion.
  ///
  /// Only `moneyOff` is supported for `orders.createtestorder`. Acceptable
  /// values are: - "`buyMGetMoneyOff`" - "`buyMGetNMoneyOff`" -
  /// "`buyMGetNPercentOff`" - "`buyMGetPercentOff`" - "`freeGift`" -
  /// "`freeGiftWithItemId`" - "`freeGiftWithValue`" - "`freeShippingOvernight`"
  /// - "`freeShippingStandard`" - "`freeShippingTwoDay`" - "`moneyOff`" -
  /// "`percentOff`" - "`rewardPoints`" - "`salePrice`"
  ///
  /// Required.
  core.String? subtype;

  /// Estimated discount applied to tax (if allowed by law).
  ///
  /// Do not provide for `orders.createtestorder`.
  Price? taxValue;

  /// The title of the promotion.
  ///
  /// Required.
  core.String? title;

  /// The scope of the promotion.
  ///
  /// Only `product` is supported for `orders.createtestorder`. Acceptable
  /// values are: - "`product`" - "`shipping`"
  ///
  /// Required.
  core.String? type;

  OrderPromotion();

  OrderPromotion.fromJson(core.Map _json) {
    if (_json.containsKey('applicableItems')) {
      applicableItems = (_json['applicableItems'] as core.List)
          .map<OrderPromotionItem>((value) => OrderPromotionItem.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('appliedItems')) {
      appliedItems = (_json['appliedItems'] as core.List)
          .map<OrderPromotionItem>((value) => OrderPromotionItem.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('funder')) {
      funder = _json['funder'] as core.String;
    }
    if (_json.containsKey('merchantPromotionId')) {
      merchantPromotionId = _json['merchantPromotionId'] as core.String;
    }
    if (_json.containsKey('priceValue')) {
      priceValue = Price.fromJson(
          _json['priceValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shortTitle')) {
      shortTitle = _json['shortTitle'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('subtype')) {
      subtype = _json['subtype'] as core.String;
    }
    if (_json.containsKey('taxValue')) {
      taxValue = Price.fromJson(
          _json['taxValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applicableItems != null)
          'applicableItems':
              applicableItems!.map((value) => value.toJson()).toList(),
        if (appliedItems != null)
          'appliedItems': appliedItems!.map((value) => value.toJson()).toList(),
        if (endTime != null) 'endTime': endTime!,
        if (funder != null) 'funder': funder!,
        if (merchantPromotionId != null)
          'merchantPromotionId': merchantPromotionId!,
        if (priceValue != null) 'priceValue': priceValue!.toJson(),
        if (shortTitle != null) 'shortTitle': shortTitle!,
        if (startTime != null) 'startTime': startTime!,
        if (subtype != null) 'subtype': subtype!,
        if (taxValue != null) 'taxValue': taxValue!.toJson(),
        if (title != null) 'title': title!,
        if (type != null) 'type': type!,
      };
}

class OrderPromotionItem {
  /// The line item ID of a product.
  ///
  /// Do not provide for `orders.createtestorder`.
  core.String? lineItemId;

  /// Offer ID of a product.
  ///
  /// Only for `orders.createtestorder`.
  ///
  /// Required.
  core.String? offerId;

  /// `orders.createtestorder`.
  core.String? productId;

  /// The quantity of the associated product.
  ///
  /// Do not provide for `orders.createtestorder`.
  core.int? quantity;

  OrderPromotionItem();

  OrderPromotionItem.fromJson(core.Map _json) {
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('offerId')) {
      offerId = _json['offerId'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (offerId != null) 'offerId': offerId!,
        if (productId != null) 'productId': productId!,
        if (quantity != null) 'quantity': quantity!,
      };
}

class OrderRefund {
  /// The actor that created the refund.
  ///
  /// Acceptable values are: - "`customer`" - "`googleBot`" -
  /// "`googleCustomerService`" - "`googlePayments`" - "`googleSabre`" -
  /// "`merchant`"
  core.String? actor;

  /// The amount that is refunded.
  Price? amount;

  /// Date on which the item has been created, in ISO 8601 format.
  core.String? creationDate;

  /// The reason for the refund.
  ///
  /// Acceptable values are: - "`adjustment`" - "`autoPostInternal`" -
  /// "`autoPostInvalidBillingAddress`" - "`autoPostNoInventory`" -
  /// "`autoPostPriceError`" - "`autoPostUndeliverableShippingAddress`" -
  /// "`couponAbuse`" - "`courtesyAdjustment`" - "`customerCanceled`" -
  /// "`customerDiscretionaryReturn`" - "`customerInitiatedMerchantCancel`" -
  /// "`customerSupportRequested`" - "`deliveredLateByCarrier`" -
  /// "`deliveredTooLate`" - "`expiredItem`" - "`failToPushOrderGoogleError`" -
  /// "`failToPushOrderMerchantError`" -
  /// "`failToPushOrderMerchantFulfillmentError`" -
  /// "`failToPushOrderToMerchant`" - "`failToPushOrderToMerchantOutOfStock`" -
  /// "`feeAdjustment`" - "`invalidCoupon`" - "`lateShipmentCredit`" -
  /// "`malformedShippingAddress`" - "`merchantDidNotShipOnTime`" -
  /// "`noInventory`" - "`orderTimeout`" - "`other`" - "`paymentAbuse`" -
  /// "`paymentDeclined`" - "`priceAdjustment`" - "`priceError`" -
  /// "`productArrivedDamaged`" - "`productNotAsDescribed`" -
  /// "`promoReallocation`" - "`qualityNotAsExpected`" - "`returnRefundAbuse`" -
  /// "`shippingCostAdjustment`" - "`shippingPriceError`" - "`taxAdjustment`" -
  /// "`taxError`" - "`undeliverableShippingAddress`" -
  /// "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  core.String? reason;

  /// The explanation of the reason.
  core.String? reasonText;

  OrderRefund();

  OrderRefund.fromJson(core.Map _json) {
    if (_json.containsKey('actor')) {
      actor = _json['actor'] as core.String;
    }
    if (_json.containsKey('amount')) {
      amount = Price.fromJson(
          _json['amount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('creationDate')) {
      creationDate = _json['creationDate'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('reasonText')) {
      reasonText = _json['reasonText'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (actor != null) 'actor': actor!,
        if (amount != null) 'amount': amount!.toJson(),
        if (creationDate != null) 'creationDate': creationDate!,
        if (reason != null) 'reason': reason!,
        if (reasonText != null) 'reasonText': reasonText!,
      };
}

/// Order disbursement.
///
/// All methods require the payment analyst role.
class OrderReportDisbursement {
  /// The disbursement amount.
  Price? disbursementAmount;

  /// The disbursement date, in ISO 8601 format.
  core.String? disbursementCreationDate;

  /// The date the disbursement was initiated, in ISO 8601 format.
  core.String? disbursementDate;

  /// The ID of the disbursement.
  core.String? disbursementId;

  /// The ID of the managing account.
  core.String? merchantId;

  OrderReportDisbursement();

  OrderReportDisbursement.fromJson(core.Map _json) {
    if (_json.containsKey('disbursementAmount')) {
      disbursementAmount = Price.fromJson(
          _json['disbursementAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('disbursementCreationDate')) {
      disbursementCreationDate =
          _json['disbursementCreationDate'] as core.String;
    }
    if (_json.containsKey('disbursementDate')) {
      disbursementDate = _json['disbursementDate'] as core.String;
    }
    if (_json.containsKey('disbursementId')) {
      disbursementId = _json['disbursementId'] as core.String;
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disbursementAmount != null)
          'disbursementAmount': disbursementAmount!.toJson(),
        if (disbursementCreationDate != null)
          'disbursementCreationDate': disbursementCreationDate!,
        if (disbursementDate != null) 'disbursementDate': disbursementDate!,
        if (disbursementId != null) 'disbursementId': disbursementId!,
        if (merchantId != null) 'merchantId': merchantId!,
      };
}

class OrderReportTransaction {
  /// The disbursement amount.
  Price? disbursementAmount;

  /// The date the disbursement was created, in ISO 8601 format.
  core.String? disbursementCreationDate;

  /// The date the disbursement was initiated, in ISO 8601 format.
  core.String? disbursementDate;

  /// The ID of the disbursement.
  core.String? disbursementId;

  /// The ID of the managing account.
  core.String? merchantId;

  /// Merchant-provided ID of the order.
  core.String? merchantOrderId;

  /// The ID of the order.
  core.String? orderId;

  /// Total amount for the items.
  ProductAmount? productAmount;

  /// The date of the transaction, in ISO 8601 format.
  core.String? transactionDate;

  OrderReportTransaction();

  OrderReportTransaction.fromJson(core.Map _json) {
    if (_json.containsKey('disbursementAmount')) {
      disbursementAmount = Price.fromJson(
          _json['disbursementAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('disbursementCreationDate')) {
      disbursementCreationDate =
          _json['disbursementCreationDate'] as core.String;
    }
    if (_json.containsKey('disbursementDate')) {
      disbursementDate = _json['disbursementDate'] as core.String;
    }
    if (_json.containsKey('disbursementId')) {
      disbursementId = _json['disbursementId'] as core.String;
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('merchantOrderId')) {
      merchantOrderId = _json['merchantOrderId'] as core.String;
    }
    if (_json.containsKey('orderId')) {
      orderId = _json['orderId'] as core.String;
    }
    if (_json.containsKey('productAmount')) {
      productAmount = ProductAmount.fromJson(
          _json['productAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('transactionDate')) {
      transactionDate = _json['transactionDate'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disbursementAmount != null)
          'disbursementAmount': disbursementAmount!.toJson(),
        if (disbursementCreationDate != null)
          'disbursementCreationDate': disbursementCreationDate!,
        if (disbursementDate != null) 'disbursementDate': disbursementDate!,
        if (disbursementId != null) 'disbursementId': disbursementId!,
        if (merchantId != null) 'merchantId': merchantId!,
        if (merchantOrderId != null) 'merchantOrderId': merchantOrderId!,
        if (orderId != null) 'orderId': orderId!,
        if (productAmount != null) 'productAmount': productAmount!.toJson(),
        if (transactionDate != null) 'transactionDate': transactionDate!,
      };
}

class OrderReturn {
  /// The actor that created the refund.
  ///
  /// Acceptable values are: - "`customer`" - "`googleBot`" -
  /// "`googleCustomerService`" - "`googlePayments`" - "`googleSabre`" -
  /// "`merchant`"
  core.String? actor;

  /// Date on which the item has been created, in ISO 8601 format.
  core.String? creationDate;

  /// Quantity that is returned.
  core.int? quantity;

  /// The reason for the return.
  ///
  /// Acceptable values are: - "`customerDiscretionaryReturn`" -
  /// "`customerInitiatedMerchantCancel`" - "`deliveredTooLate`" -
  /// "`expiredItem`" - "`invalidCoupon`" - "`malformedShippingAddress`" -
  /// "`other`" - "`productArrivedDamaged`" - "`productNotAsDescribed`" -
  /// "`qualityNotAsExpected`" - "`undeliverableShippingAddress`" -
  /// "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  core.String? reason;

  /// The explanation of the reason.
  core.String? reasonText;

  OrderReturn();

  OrderReturn.fromJson(core.Map _json) {
    if (_json.containsKey('actor')) {
      actor = _json['actor'] as core.String;
    }
    if (_json.containsKey('creationDate')) {
      creationDate = _json['creationDate'] as core.String;
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.int;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('reasonText')) {
      reasonText = _json['reasonText'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (actor != null) 'actor': actor!,
        if (creationDate != null) 'creationDate': creationDate!,
        if (quantity != null) 'quantity': quantity!,
        if (reason != null) 'reason': reason!,
        if (reasonText != null) 'reasonText': reasonText!,
      };
}

class OrderShipment {
  /// The carrier handling the shipment.
  ///
  /// For supported carriers, Google includes the carrier name and tracking URL
  /// in emails to customers. For select supported carriers, Google also
  /// automatically updates the shipment status based on the provided shipment
  /// ID. *Note:* You can also use unsupported carriers, but emails to customers
  /// will not include the carrier name or tracking URL, and there will be no
  /// automatic order status updates. Supported carriers for US are: - "`ups`"
  /// (United Parcel Service) *automatic status updates* - "`usps`" (United
  /// States Postal Service) *automatic status updates* - "`fedex`" (FedEx)
  /// *automatic status updates * - "`dhl`" (DHL eCommerce) *automatic status
  /// updates* (US only) - "`ontrac`" (OnTrac) *automatic status updates * -
  /// "`dhl express`" (DHL Express) - "`deliv`" (Deliv) - "`dynamex`" (TForce) -
  /// "`lasership`" (LaserShip) - "`mpx`" (Military Parcel Xpress) - "`uds`"
  /// (United Delivery Service) - "`efw`" (Estes Forwarding Worldwide) - "`jd
  /// logistics`" (JD Logistics) - "`yunexpress`" (YunExpress) - "`china post`"
  /// (China Post) - "`china ems`" (China Post Express Mail Service) -
  /// "`singapore post`" (Singapore Post) - "`pos malaysia`" (Pos Malaysia) -
  /// "`postnl`" (PostNL) - "`ptt`" (PTT Turkish Post) - "`eub`" (ePacket) -
  /// "`chukou1`" (Chukou1 Logistics) - "`bestex`" (Best Express) - "`canada
  /// post`" (Canada Post) - "`purolator`" (Purolator) - "`canpar`" (Canpar) -
  /// "`india post`" (India Post) - "`blue dart`" (Blue Dart) - "`delhivery`"
  /// (Delhivery) - "`dtdc`" (DTDC) - "`tpc india`" (TPC India) Supported
  /// carriers for FR are: - "`la poste`" (La Poste) *automatic status updates *
  /// - "`colissimo`" (Colissimo by La Poste) *automatic status updates* -
  /// "`ups`" (United Parcel Service) *automatic status updates * -
  /// "`chronopost`" (Chronopost by La Poste) - "`gls`" (General Logistics
  /// Systems France) - "`dpd`" (DPD Group by GeoPost) - "`bpost`" (Belgian Post
  /// Group) - "`colis prive`" (Colis Privé) - "`boxtal`" (Boxtal) - "`geodis`"
  /// (GEODIS) - "`tnt`" (TNT) - "`db schenker`" (DB Schenker) - "`aramex`"
  /// (Aramex)
  core.String? carrier;

  /// Date on which the shipment has been created, in ISO 8601 format.
  core.String? creationDate;

  /// Date on which the shipment has been delivered, in ISO 8601 format.
  ///
  /// Present only if `status` is `delivered`
  core.String? deliveryDate;

  /// The ID of the shipment.
  core.String? id;

  /// The line items that are shipped.
  core.List<OrderShipmentLineItemShipment>? lineItems;

  /// Delivery details of the shipment if scheduling is needed.
  OrderShipmentScheduledDeliveryDetails? scheduledDeliveryDetails;

  /// The shipment group ID of the shipment.
  ///
  /// This is set in shiplineitems request.
  core.String? shipmentGroupId;

  /// The status of the shipment.
  ///
  /// Acceptable values are: - "`delivered`" - "`readyForPickup`" - "`shipped`"
  /// - "`undeliverable`"
  core.String? status;

  /// The tracking ID for the shipment.
  core.String? trackingId;

  OrderShipment();

  OrderShipment.fromJson(core.Map _json) {
    if (_json.containsKey('carrier')) {
      carrier = _json['carrier'] as core.String;
    }
    if (_json.containsKey('creationDate')) {
      creationDate = _json['creationDate'] as core.String;
    }
    if (_json.containsKey('deliveryDate')) {
      deliveryDate = _json['deliveryDate'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('lineItems')) {
      lineItems = (_json['lineItems'] as core.List)
          .map<OrderShipmentLineItemShipment>((value) =>
              OrderShipmentLineItemShipment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('scheduledDeliveryDetails')) {
      scheduledDeliveryDetails = OrderShipmentScheduledDeliveryDetails.fromJson(
          _json['scheduledDeliveryDetails']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shipmentGroupId')) {
      shipmentGroupId = _json['shipmentGroupId'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('trackingId')) {
      trackingId = _json['trackingId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrier != null) 'carrier': carrier!,
        if (creationDate != null) 'creationDate': creationDate!,
        if (deliveryDate != null) 'deliveryDate': deliveryDate!,
        if (id != null) 'id': id!,
        if (lineItems != null)
          'lineItems': lineItems!.map((value) => value.toJson()).toList(),
        if (scheduledDeliveryDetails != null)
          'scheduledDeliveryDetails': scheduledDeliveryDetails!.toJson(),
        if (shipmentGroupId != null) 'shipmentGroupId': shipmentGroupId!,
        if (status != null) 'status': status!,
        if (trackingId != null) 'trackingId': trackingId!,
      };
}

class OrderShipmentLineItemShipment {
  /// The ID of the line item that is shipped.
  ///
  /// This value is assigned by Google when an order is created. Either
  /// lineItemId or productId is required.
  core.String? lineItemId;

  /// The ID of the product to ship.
  ///
  /// This is the REST ID used in the products service. Either lineItemId or
  /// productId is required.
  core.String? productId;

  /// The quantity that is shipped.
  core.int? quantity;

  OrderShipmentLineItemShipment();

  OrderShipmentLineItemShipment.fromJson(core.Map _json) {
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (productId != null) 'productId': productId!,
        if (quantity != null) 'quantity': quantity!,
      };
}

class OrderShipmentScheduledDeliveryDetails {
  /// The phone number of the carrier fulfilling the delivery.
  ///
  /// The phone number is formatted as the international notation in ITU-T
  /// Recommendation E.123 (e.g., "+41 44 668 1800").
  core.String? carrierPhoneNumber;

  /// The date a shipment is scheduled for delivery, in ISO 8601 format.
  core.String? scheduledDate;

  OrderShipmentScheduledDeliveryDetails();

  OrderShipmentScheduledDeliveryDetails.fromJson(core.Map _json) {
    if (_json.containsKey('carrierPhoneNumber')) {
      carrierPhoneNumber = _json['carrierPhoneNumber'] as core.String;
    }
    if (_json.containsKey('scheduledDate')) {
      scheduledDate = _json['scheduledDate'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrierPhoneNumber != null)
          'carrierPhoneNumber': carrierPhoneNumber!,
        if (scheduledDate != null) 'scheduledDate': scheduledDate!,
      };
}

/// Represents a merchant trade from which signals are extracted, e.g. shipping.
class OrderTrackingSignal {
  /// The shipping fee of the order; this value should be set to zero in the
  /// case of free shipping.
  PriceAmount? customerShippingFee;

  /// The delivery postal code, as a continuous string without spaces or dashes,
  /// e.g. "95016".
  ///
  /// This field will be anonymized in returned OrderTrackingSignal creation
  /// response.
  ///
  /// Required.
  core.String? deliveryPostalCode;

  /// The
  /// [CLDR territory code](http://www.unicode.org/repos/cldr/tags/latest/common/main/en.xml)
  /// for the shipping destination.
  ///
  /// Required.
  core.String? deliveryRegionCode;

  /// Information about line items in the order.
  core.List<OrderTrackingSignalLineItemDetails>? lineItems;

  /// The Google merchant ID of this order tracking signal.
  ///
  /// This value is optional. If left unset, the caller's merchant ID is used.
  /// You must request access in order to provide data on behalf of another
  /// merchant. For more information, see \[Submitting Order Tracking
  /// Signals\](/shopping-content/guides/order-tracking-signals).
  core.String? merchantId;

  /// The time when the order was created on the merchant side.
  ///
  /// Include the year and timezone string, if available.
  ///
  /// Required.
  DateTime? orderCreatedTime;

  /// The ID of the order on the merchant side.
  ///
  /// This field will be hashed in returned OrderTrackingSignal creation
  /// response.
  ///
  /// Required.
  core.String? orderId;

  /// The ID that uniquely identifies this order tracking signal.
  ///
  /// Output only.
  core.String? orderTrackingSignalId;

  /// The mapping of the line items to the shipment information.
  core.List<OrderTrackingSignalShipmentLineItemMapping>?
      shipmentLineItemMapping;

  /// The shipping information for the order.
  core.List<OrderTrackingSignalShippingInfo>? shippingInfo;

  OrderTrackingSignal();

  OrderTrackingSignal.fromJson(core.Map _json) {
    if (_json.containsKey('customerShippingFee')) {
      customerShippingFee = PriceAmount.fromJson(
          _json['customerShippingFee'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deliveryPostalCode')) {
      deliveryPostalCode = _json['deliveryPostalCode'] as core.String;
    }
    if (_json.containsKey('deliveryRegionCode')) {
      deliveryRegionCode = _json['deliveryRegionCode'] as core.String;
    }
    if (_json.containsKey('lineItems')) {
      lineItems = (_json['lineItems'] as core.List)
          .map<OrderTrackingSignalLineItemDetails>((value) =>
              OrderTrackingSignalLineItemDetails.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('orderCreatedTime')) {
      orderCreatedTime = DateTime.fromJson(
          _json['orderCreatedTime'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('orderId')) {
      orderId = _json['orderId'] as core.String;
    }
    if (_json.containsKey('orderTrackingSignalId')) {
      orderTrackingSignalId = _json['orderTrackingSignalId'] as core.String;
    }
    if (_json.containsKey('shipmentLineItemMapping')) {
      shipmentLineItemMapping = (_json['shipmentLineItemMapping'] as core.List)
          .map<OrderTrackingSignalShipmentLineItemMapping>((value) =>
              OrderTrackingSignalShipmentLineItemMapping.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shippingInfo')) {
      shippingInfo = (_json['shippingInfo'] as core.List)
          .map<OrderTrackingSignalShippingInfo>((value) =>
              OrderTrackingSignalShippingInfo.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customerShippingFee != null)
          'customerShippingFee': customerShippingFee!.toJson(),
        if (deliveryPostalCode != null)
          'deliveryPostalCode': deliveryPostalCode!,
        if (deliveryRegionCode != null)
          'deliveryRegionCode': deliveryRegionCode!,
        if (lineItems != null)
          'lineItems': lineItems!.map((value) => value.toJson()).toList(),
        if (merchantId != null) 'merchantId': merchantId!,
        if (orderCreatedTime != null)
          'orderCreatedTime': orderCreatedTime!.toJson(),
        if (orderId != null) 'orderId': orderId!,
        if (orderTrackingSignalId != null)
          'orderTrackingSignalId': orderTrackingSignalId!,
        if (shipmentLineItemMapping != null)
          'shipmentLineItemMapping':
              shipmentLineItemMapping!.map((value) => value.toJson()).toList(),
        if (shippingInfo != null)
          'shippingInfo': shippingInfo!.map((value) => value.toJson()).toList(),
      };
}

/// The line items of the order.
class OrderTrackingSignalLineItemDetails {
  /// The Global Trade Item Number.
  core.String? gtin;

  /// The ID for this line item.
  ///
  /// Required.
  core.String? lineItemId;

  /// The manufacturer part number.
  core.String? mpn;

  /// The Content API REST ID of the product, in the form
  /// channel:contentLanguage:targetCountry:offerId.
  ///
  /// Required.
  core.String? productId;

  /// The quantity of the line item in the order.
  ///
  /// Required.
  core.String? quantity;

  OrderTrackingSignalLineItemDetails();

  OrderTrackingSignalLineItemDetails.fromJson(core.Map _json) {
    if (_json.containsKey('gtin')) {
      gtin = _json['gtin'] as core.String;
    }
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('mpn')) {
      mpn = _json['mpn'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gtin != null) 'gtin': gtin!,
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (mpn != null) 'mpn': mpn!,
        if (productId != null) 'productId': productId!,
        if (quantity != null) 'quantity': quantity!,
      };
}

/// Represents how many items are in the shipment for the given shipment_id and
/// line_item_id.
class OrderTrackingSignalShipmentLineItemMapping {
  /// The line item ID.
  ///
  /// Required.
  core.String? lineItemId;

  /// The line item quantity in the shipment.
  ///
  /// Required.
  core.String? quantity;

  /// The shipment ID.
  ///
  /// This field will be hashed in returned OrderTrackingSignal creation
  /// response.
  ///
  /// Required.
  core.String? shipmentId;

  OrderTrackingSignalShipmentLineItemMapping();

  OrderTrackingSignalShipmentLineItemMapping.fromJson(core.Map _json) {
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.String;
    }
    if (_json.containsKey('shipmentId')) {
      shipmentId = _json['shipmentId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (quantity != null) 'quantity': quantity!,
        if (shipmentId != null) 'shipmentId': shipmentId!,
      };
}

/// The shipping information for the order.
class OrderTrackingSignalShippingInfo {
  /// The time when the shipment was actually delivered.
  ///
  /// Include the year and timezone string, if available. This field is
  /// required, if one of the following fields is absent: tracking_id or
  /// carrier_name.
  DateTime? actualDeliveryTime;

  /// The name of the shipping carrier for the delivery.
  ///
  /// This field is required if one of the following fields is absent:
  /// earliest_delivery_promise_time, latest_delivery_promise_time, and
  /// actual_delivery_time.
  core.String? carrierName;

  /// The service type for fulfillment, e.g., GROUND, FIRST_CLASS, etc.
  core.String? carrierServiceName;

  /// The earliest delivery promised time.
  ///
  /// Include the year and timezone string, if available. This field is
  /// required, if one of the following fields is absent: tracking_id or
  /// carrier_name.
  DateTime? earliestDeliveryPromiseTime;

  /// The latest delivery promised time.
  ///
  /// Include the year and timezone string, if available. This field is
  /// required, if one of the following fields is absent: tracking_id or
  /// carrier_name.
  DateTime? latestDeliveryPromiseTime;

  /// The origin postal code, as a continuous string without spaces or dashes,
  /// e.g. "95016".
  ///
  /// This field will be anonymized in returned OrderTrackingSignal creation
  /// response.
  core.String? originPostalCode;

  /// The
  /// [CLDR territory code](http://www.unicode.org/repos/cldr/tags/latest/common/main/en.xml)
  /// for the shipping origin.
  core.String? originRegionCode;

  /// The shipment ID.
  ///
  /// This field will be hashed in returned OrderTrackingSignal creation
  /// response.
  ///
  /// Required.
  core.String? shipmentId;

  /// The time when the shipment was shipped.
  ///
  /// Include the year and timezone string, if available.
  DateTime? shippedTime;

  /// The status of the shipment.
  /// Possible string values are:
  /// - "SHIPPING_STATE_UNSPECIFIED" : The shipping status is not known to
  /// merchant.
  /// - "SHIPPED" : All items are shipped.
  /// - "DELIVERED" : The shipment is already delivered.
  core.String? shippingStatus;

  /// The tracking ID of the shipment.
  ///
  /// This field is required if one of the following fields is absent:
  /// earliest_delivery_promise_time, latest_delivery_promise_time, and
  /// actual_delivery_time.
  core.String? trackingId;

  OrderTrackingSignalShippingInfo();

  OrderTrackingSignalShippingInfo.fromJson(core.Map _json) {
    if (_json.containsKey('actualDeliveryTime')) {
      actualDeliveryTime = DateTime.fromJson(
          _json['actualDeliveryTime'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('carrierName')) {
      carrierName = _json['carrierName'] as core.String;
    }
    if (_json.containsKey('carrierServiceName')) {
      carrierServiceName = _json['carrierServiceName'] as core.String;
    }
    if (_json.containsKey('earliestDeliveryPromiseTime')) {
      earliestDeliveryPromiseTime = DateTime.fromJson(
          _json['earliestDeliveryPromiseTime']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('latestDeliveryPromiseTime')) {
      latestDeliveryPromiseTime = DateTime.fromJson(
          _json['latestDeliveryPromiseTime']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('originPostalCode')) {
      originPostalCode = _json['originPostalCode'] as core.String;
    }
    if (_json.containsKey('originRegionCode')) {
      originRegionCode = _json['originRegionCode'] as core.String;
    }
    if (_json.containsKey('shipmentId')) {
      shipmentId = _json['shipmentId'] as core.String;
    }
    if (_json.containsKey('shippedTime')) {
      shippedTime = DateTime.fromJson(
          _json['shippedTime'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shippingStatus')) {
      shippingStatus = _json['shippingStatus'] as core.String;
    }
    if (_json.containsKey('trackingId')) {
      trackingId = _json['trackingId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (actualDeliveryTime != null)
          'actualDeliveryTime': actualDeliveryTime!.toJson(),
        if (carrierName != null) 'carrierName': carrierName!,
        if (carrierServiceName != null)
          'carrierServiceName': carrierServiceName!,
        if (earliestDeliveryPromiseTime != null)
          'earliestDeliveryPromiseTime': earliestDeliveryPromiseTime!.toJson(),
        if (latestDeliveryPromiseTime != null)
          'latestDeliveryPromiseTime': latestDeliveryPromiseTime!.toJson(),
        if (originPostalCode != null) 'originPostalCode': originPostalCode!,
        if (originRegionCode != null) 'originRegionCode': originRegionCode!,
        if (shipmentId != null) 'shipmentId': shipmentId!,
        if (shippedTime != null) 'shippedTime': shippedTime!.toJson(),
        if (shippingStatus != null) 'shippingStatus': shippingStatus!,
        if (trackingId != null) 'trackingId': trackingId!,
      };
}

class OrderinvoicesCreateChargeInvoiceRequest {
  /// The ID of the invoice.
  ///
  /// Required.
  core.String? invoiceId;

  /// Invoice summary.
  ///
  /// Required.
  InvoiceSummary? invoiceSummary;

  /// Invoice details per line item.
  ///
  /// Required.
  core.List<ShipmentInvoiceLineItemInvoice>? lineItemInvoices;

  /// The ID of the operation, unique across all operations for a given order.
  ///
  /// Required.
  core.String? operationId;

  /// ID of the shipment group.
  ///
  /// It is assigned by the merchant in the `shipLineItems` method and is used
  /// to group multiple line items that have the same kind of shipping charges.
  ///
  /// Required.
  core.String? shipmentGroupId;

  OrderinvoicesCreateChargeInvoiceRequest();

  OrderinvoicesCreateChargeInvoiceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('invoiceId')) {
      invoiceId = _json['invoiceId'] as core.String;
    }
    if (_json.containsKey('invoiceSummary')) {
      invoiceSummary = InvoiceSummary.fromJson(
          _json['invoiceSummary'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lineItemInvoices')) {
      lineItemInvoices = (_json['lineItemInvoices'] as core.List)
          .map<ShipmentInvoiceLineItemInvoice>((value) =>
              ShipmentInvoiceLineItemInvoice.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('shipmentGroupId')) {
      shipmentGroupId = _json['shipmentGroupId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (invoiceId != null) 'invoiceId': invoiceId!,
        if (invoiceSummary != null) 'invoiceSummary': invoiceSummary!.toJson(),
        if (lineItemInvoices != null)
          'lineItemInvoices':
              lineItemInvoices!.map((value) => value.toJson()).toList(),
        if (operationId != null) 'operationId': operationId!,
        if (shipmentGroupId != null) 'shipmentGroupId': shipmentGroupId!,
      };
}

class OrderinvoicesCreateChargeInvoiceResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "content#orderinvoicesCreateChargeInvoiceResponse".
  core.String? kind;

  OrderinvoicesCreateChargeInvoiceResponse();

  OrderinvoicesCreateChargeInvoiceResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrderinvoicesCreateRefundInvoiceRequest {
  /// The ID of the invoice.
  ///
  /// Required.
  core.String? invoiceId;

  /// The ID of the operation, unique across all operations for a given order.
  ///
  /// Required.
  core.String? operationId;

  /// Option to create a refund-only invoice.
  ///
  /// Exactly one of `refundOnlyOption` or `returnOption` must be provided.
  OrderinvoicesCustomBatchRequestEntryCreateRefundInvoiceRefundOption?
      refundOnlyOption;

  /// Option to create an invoice for a refund and mark all items within the
  /// invoice as returned.
  ///
  /// Exactly one of `refundOnlyOption` or `returnOption` must be provided.
  OrderinvoicesCustomBatchRequestEntryCreateRefundInvoiceReturnOption?
      returnOption;

  /// Invoice details for different shipment groups.
  core.List<ShipmentInvoice>? shipmentInvoices;

  OrderinvoicesCreateRefundInvoiceRequest();

  OrderinvoicesCreateRefundInvoiceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('invoiceId')) {
      invoiceId = _json['invoiceId'] as core.String;
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('refundOnlyOption')) {
      refundOnlyOption =
          OrderinvoicesCustomBatchRequestEntryCreateRefundInvoiceRefundOption
              .fromJson(_json['refundOnlyOption']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('returnOption')) {
      returnOption =
          OrderinvoicesCustomBatchRequestEntryCreateRefundInvoiceReturnOption
              .fromJson(
                  _json['returnOption'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shipmentInvoices')) {
      shipmentInvoices = (_json['shipmentInvoices'] as core.List)
          .map<ShipmentInvoice>((value) => ShipmentInvoice.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (invoiceId != null) 'invoiceId': invoiceId!,
        if (operationId != null) 'operationId': operationId!,
        if (refundOnlyOption != null)
          'refundOnlyOption': refundOnlyOption!.toJson(),
        if (returnOption != null) 'returnOption': returnOption!.toJson(),
        if (shipmentInvoices != null)
          'shipmentInvoices':
              shipmentInvoices!.map((value) => value.toJson()).toList(),
      };
}

class OrderinvoicesCreateRefundInvoiceResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "content#orderinvoicesCreateRefundInvoiceResponse".
  core.String? kind;

  OrderinvoicesCreateRefundInvoiceResponse();

  OrderinvoicesCreateRefundInvoiceResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrderinvoicesCustomBatchRequestEntryCreateRefundInvoiceRefundOption {
  /// Optional description of the refund reason.
  core.String? description;

  /// Reason for the refund.
  ///
  /// Acceptable values are: - "`adjustment`" - "`autoPostInternal`" -
  /// "`autoPostInvalidBillingAddress`" - "`autoPostNoInventory`" -
  /// "`autoPostPriceError`" - "`autoPostUndeliverableShippingAddress`" -
  /// "`couponAbuse`" - "`courtesyAdjustment`" - "`customerCanceled`" -
  /// "`customerDiscretionaryReturn`" - "`customerInitiatedMerchantCancel`" -
  /// "`customerSupportRequested`" - "`deliveredLateByCarrier`" -
  /// "`deliveredTooLate`" - "`expiredItem`" - "`failToPushOrderGoogleError`" -
  /// "`failToPushOrderMerchantError`" -
  /// "`failToPushOrderMerchantFulfillmentError`" -
  /// "`failToPushOrderToMerchant`" - "`failToPushOrderToMerchantOutOfStock`" -
  /// "`feeAdjustment`" - "`invalidCoupon`" - "`lateShipmentCredit`" -
  /// "`malformedShippingAddress`" - "`merchantDidNotShipOnTime`" -
  /// "`noInventory`" - "`orderTimeout`" - "`other`" - "`paymentAbuse`" -
  /// "`paymentDeclined`" - "`priceAdjustment`" - "`priceError`" -
  /// "`productArrivedDamaged`" - "`productNotAsDescribed`" -
  /// "`promoReallocation`" - "`qualityNotAsExpected`" - "`returnRefundAbuse`" -
  /// "`shippingCostAdjustment`" - "`shippingPriceError`" - "`taxAdjustment`" -
  /// "`taxError`" - "`undeliverableShippingAddress`" -
  /// "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  ///
  /// Required.
  core.String? reason;

  OrderinvoicesCustomBatchRequestEntryCreateRefundInvoiceRefundOption();

  OrderinvoicesCustomBatchRequestEntryCreateRefundInvoiceRefundOption.fromJson(
      core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (reason != null) 'reason': reason!,
      };
}

class OrderinvoicesCustomBatchRequestEntryCreateRefundInvoiceReturnOption {
  /// Optional description of the return reason.
  core.String? description;

  /// Reason for the return.
  ///
  /// Acceptable values are: - "`customerDiscretionaryReturn`" -
  /// "`customerInitiatedMerchantCancel`" - "`deliveredTooLate`" -
  /// "`expiredItem`" - "`invalidCoupon`" - "`malformedShippingAddress`" -
  /// "`other`" - "`productArrivedDamaged`" - "`productNotAsDescribed`" -
  /// "`qualityNotAsExpected`" - "`undeliverableShippingAddress`" -
  /// "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  ///
  /// Required.
  core.String? reason;

  OrderinvoicesCustomBatchRequestEntryCreateRefundInvoiceReturnOption();

  OrderinvoicesCustomBatchRequestEntryCreateRefundInvoiceReturnOption.fromJson(
      core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (reason != null) 'reason': reason!,
      };
}

class OrderreportsListDisbursementsResponse {
  /// The list of disbursements.
  core.List<OrderReportDisbursement>? disbursements;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#orderreportsListDisbursementsResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of disbursements.
  core.String? nextPageToken;

  OrderreportsListDisbursementsResponse();

  OrderreportsListDisbursementsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('disbursements')) {
      disbursements = (_json['disbursements'] as core.List)
          .map<OrderReportDisbursement>((value) =>
              OrderReportDisbursement.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disbursements != null)
          'disbursements':
              disbursements!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class OrderreportsListTransactionsResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#orderreportsListTransactionsResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of transactions.
  core.String? nextPageToken;

  /// The list of transactions.
  core.List<OrderReportTransaction>? transactions;

  OrderreportsListTransactionsResponse();

  OrderreportsListTransactionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('transactions')) {
      transactions = (_json['transactions'] as core.List)
          .map<OrderReportTransaction>((value) =>
              OrderReportTransaction.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (transactions != null)
          'transactions': transactions!.map((value) => value.toJson()).toList(),
      };
}

class OrderreturnsAcknowledgeRequest {
  /// The ID of the operation, unique across all operations for a given order
  /// return.
  ///
  /// Required.
  core.String? operationId;

  OrderreturnsAcknowledgeRequest();

  OrderreturnsAcknowledgeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operationId != null) 'operationId': operationId!,
      };
}

class OrderreturnsAcknowledgeResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#orderreturnsAcknowledgeResponse".
  core.String? kind;

  OrderreturnsAcknowledgeResponse();

  OrderreturnsAcknowledgeResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrderreturnsCreateOrderReturnRequest {
  /// The list of line items to return.
  core.List<OrderreturnsLineItem>? lineItems;

  /// The ID of the operation.
  ///
  /// Unique across all operations for a given order.
  core.String? operationId;

  /// The ID of the order.
  core.String? orderId;

  /// The way of the package being returned.
  core.String? returnMethodType;

  OrderreturnsCreateOrderReturnRequest();

  OrderreturnsCreateOrderReturnRequest.fromJson(core.Map _json) {
    if (_json.containsKey('lineItems')) {
      lineItems = (_json['lineItems'] as core.List)
          .map<OrderreturnsLineItem>((value) => OrderreturnsLineItem.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('orderId')) {
      orderId = _json['orderId'] as core.String;
    }
    if (_json.containsKey('returnMethodType')) {
      returnMethodType = _json['returnMethodType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineItems != null)
          'lineItems': lineItems!.map((value) => value.toJson()).toList(),
        if (operationId != null) 'operationId': operationId!,
        if (orderId != null) 'orderId': orderId!,
        if (returnMethodType != null) 'returnMethodType': returnMethodType!,
      };
}

class OrderreturnsCreateOrderReturnResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#orderreturnsCreateOrderReturnResponse".
  core.String? kind;

  /// Created order return.
  MerchantOrderReturn? orderReturn;

  OrderreturnsCreateOrderReturnResponse();

  OrderreturnsCreateOrderReturnResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('orderReturn')) {
      orderReturn = MerchantOrderReturn.fromJson(
          _json['orderReturn'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
        if (orderReturn != null) 'orderReturn': orderReturn!.toJson(),
      };
}

class OrderreturnsLineItem {
  /// The ID of the line item.
  ///
  /// This value is assigned by Google when an order is created. Either
  /// lineItemId or productId is required.
  core.String? lineItemId;

  /// The ID of the product to cancel.
  ///
  /// This is the REST ID used in the products service. Either lineItemId or
  /// productId is required.
  core.String? productId;

  /// The quantity of this line item.
  core.int? quantity;

  OrderreturnsLineItem();

  OrderreturnsLineItem.fromJson(core.Map _json) {
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (productId != null) 'productId': productId!,
        if (quantity != null) 'quantity': quantity!,
      };
}

class OrderreturnsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#orderreturnsListResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of returns.
  core.String? nextPageToken;
  core.List<MerchantOrderReturn>? resources;

  OrderreturnsListResponse();

  OrderreturnsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<MerchantOrderReturn>((value) => MerchantOrderReturn.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

class OrderreturnsPartialRefund {
  /// The pre-tax or post-tax amount to be refunded, depending on the location
  /// of the order.
  Price? priceAmount;

  /// Tax amount to be refunded.
  ///
  /// Note: This has different meaning depending on the location of the order.
  Price? taxAmount;

  OrderreturnsPartialRefund();

  OrderreturnsPartialRefund.fromJson(core.Map _json) {
    if (_json.containsKey('priceAmount')) {
      priceAmount = Price.fromJson(
          _json['priceAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('taxAmount')) {
      taxAmount = Price.fromJson(
          _json['taxAmount'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (priceAmount != null) 'priceAmount': priceAmount!.toJson(),
        if (taxAmount != null) 'taxAmount': taxAmount!.toJson(),
      };
}

class OrderreturnsProcessRequest {
  /// Option to charge the customer return shipping cost.
  core.bool? fullChargeReturnShippingCost;

  /// The ID of the operation, unique across all operations for a given order
  /// return.
  ///
  /// Required.
  core.String? operationId;

  /// Refunds for original shipping fee.
  OrderreturnsRefundOperation? refundShippingFee;

  /// The list of items to return.
  core.List<OrderreturnsReturnItem>? returnItems;

  OrderreturnsProcessRequest();

  OrderreturnsProcessRequest.fromJson(core.Map _json) {
    if (_json.containsKey('fullChargeReturnShippingCost')) {
      fullChargeReturnShippingCost =
          _json['fullChargeReturnShippingCost'] as core.bool;
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('refundShippingFee')) {
      refundShippingFee = OrderreturnsRefundOperation.fromJson(
          _json['refundShippingFee'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('returnItems')) {
      returnItems = (_json['returnItems'] as core.List)
          .map<OrderreturnsReturnItem>((value) =>
              OrderreturnsReturnItem.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fullChargeReturnShippingCost != null)
          'fullChargeReturnShippingCost': fullChargeReturnShippingCost!,
        if (operationId != null) 'operationId': operationId!,
        if (refundShippingFee != null)
          'refundShippingFee': refundShippingFee!.toJson(),
        if (returnItems != null)
          'returnItems': returnItems!.map((value) => value.toJson()).toList(),
      };
}

class OrderreturnsProcessResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#orderreturnsProcessResponse".
  core.String? kind;

  OrderreturnsProcessResponse();

  OrderreturnsProcessResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrderreturnsRefundOperation {
  /// If true, the item will be fully refunded.
  ///
  /// Allowed only when payment_type is FOP. Merchant can choose this refund
  /// option to indicate the full remaining amount of corresponding object to be
  /// refunded to the customer via FOP.
  core.bool? fullRefund;

  /// If this is set, the item will be partially refunded.
  ///
  /// Merchant can choose this refund option to specify the customized amount
  /// that to be refunded to the customer.
  OrderreturnsPartialRefund? partialRefund;

  /// The payment way of issuing refund.
  ///
  /// Default value is ORIGINAL_FOP if not set.
  core.String? paymentType;

  /// The explanation of the reason.
  core.String? reasonText;

  /// Code of the refund reason.
  core.String? returnRefundReason;

  OrderreturnsRefundOperation();

  OrderreturnsRefundOperation.fromJson(core.Map _json) {
    if (_json.containsKey('fullRefund')) {
      fullRefund = _json['fullRefund'] as core.bool;
    }
    if (_json.containsKey('partialRefund')) {
      partialRefund = OrderreturnsPartialRefund.fromJson(
          _json['partialRefund'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('paymentType')) {
      paymentType = _json['paymentType'] as core.String;
    }
    if (_json.containsKey('reasonText')) {
      reasonText = _json['reasonText'] as core.String;
    }
    if (_json.containsKey('returnRefundReason')) {
      returnRefundReason = _json['returnRefundReason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fullRefund != null) 'fullRefund': fullRefund!,
        if (partialRefund != null) 'partialRefund': partialRefund!.toJson(),
        if (paymentType != null) 'paymentType': paymentType!,
        if (reasonText != null) 'reasonText': reasonText!,
        if (returnRefundReason != null)
          'returnRefundReason': returnRefundReason!,
      };
}

class OrderreturnsRejectOperation {
  /// The reason for the return.
  core.String? reason;

  /// The explanation of the reason.
  core.String? reasonText;

  OrderreturnsRejectOperation();

  OrderreturnsRejectOperation.fromJson(core.Map _json) {
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('reasonText')) {
      reasonText = _json['reasonText'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (reason != null) 'reason': reason!,
        if (reasonText != null) 'reasonText': reasonText!,
      };
}

class OrderreturnsReturnItem {
  /// Refunds the item.
  OrderreturnsRefundOperation? refund;

  /// Rejects the item.
  OrderreturnsRejectOperation? reject;

  /// Unit level ID for the return item.
  ///
  /// Different units of the same product will have different IDs.
  core.String? returnItemId;

  OrderreturnsReturnItem();

  OrderreturnsReturnItem.fromJson(core.Map _json) {
    if (_json.containsKey('refund')) {
      refund = OrderreturnsRefundOperation.fromJson(
          _json['refund'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('reject')) {
      reject = OrderreturnsRejectOperation.fromJson(
          _json['reject'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('returnItemId')) {
      returnItemId = _json['returnItemId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (refund != null) 'refund': refund!.toJson(),
        if (reject != null) 'reject': reject!.toJson(),
        if (returnItemId != null) 'returnItemId': returnItemId!,
      };
}

class OrdersAcknowledgeRequest {
  /// The ID of the operation.
  ///
  /// Unique across all operations for a given order.
  core.String? operationId;

  OrdersAcknowledgeRequest();

  OrdersAcknowledgeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operationId != null) 'operationId': operationId!,
      };
}

class OrdersAcknowledgeResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersAcknowledgeResponse".
  core.String? kind;

  OrdersAcknowledgeResponse();

  OrdersAcknowledgeResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrdersAdvanceTestOrderResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersAdvanceTestOrderResponse".
  core.String? kind;

  OrdersAdvanceTestOrderResponse();

  OrdersAdvanceTestOrderResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
      };
}

class OrdersCancelLineItemRequest {
  /// The ID of the line item to cancel.
  ///
  /// Either lineItemId or productId is required.
  core.String? lineItemId;

  /// The ID of the operation.
  ///
  /// Unique across all operations for a given order.
  core.String? operationId;

  /// The ID of the product to cancel.
  ///
  /// This is the REST ID used in the products service. Either lineItemId or
  /// productId is required.
  core.String? productId;

  /// The quantity to cancel.
  core.int? quantity;

  /// The reason for the cancellation.
  ///
  /// Acceptable values are: - "`customerInitiatedCancel`" - "`invalidCoupon`" -
  /// "`malformedShippingAddress`" - "`noInventory`" - "`other`" -
  /// "`priceError`" - "`shippingPriceError`" - "`taxError`" -
  /// "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`"
  core.String? reason;

  /// The explanation of the reason.
  core.String? reasonText;

  OrdersCancelLineItemRequest();

  OrdersCancelLineItemRequest.fromJson(core.Map _json) {
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.int;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('reasonText')) {
      reasonText = _json['reasonText'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (operationId != null) 'operationId': operationId!,
        if (productId != null) 'productId': productId!,
        if (quantity != null) 'quantity': quantity!,
        if (reason != null) 'reason': reason!,
        if (reasonText != null) 'reasonText': reasonText!,
      };
}

class OrdersCancelLineItemResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersCancelLineItemResponse".
  core.String? kind;

  OrdersCancelLineItemResponse();

  OrdersCancelLineItemResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrdersCancelRequest {
  /// The ID of the operation.
  ///
  /// Unique across all operations for a given order.
  core.String? operationId;

  /// The reason for the cancellation.
  ///
  /// Acceptable values are: - "`customerInitiatedCancel`" - "`invalidCoupon`" -
  /// "`malformedShippingAddress`" - "`noInventory`" - "`other`" -
  /// "`priceError`" - "`shippingPriceError`" - "`taxError`" -
  /// "`undeliverableShippingAddress`" - "`unsupportedPoBoxAddress`"
  core.String? reason;

  /// The explanation of the reason.
  core.String? reasonText;

  OrdersCancelRequest();

  OrdersCancelRequest.fromJson(core.Map _json) {
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('reasonText')) {
      reasonText = _json['reasonText'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operationId != null) 'operationId': operationId!,
        if (reason != null) 'reason': reason!,
        if (reasonText != null) 'reasonText': reasonText!,
      };
}

class OrdersCancelResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersCancelResponse".
  core.String? kind;

  OrdersCancelResponse();

  OrdersCancelResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrdersCancelTestOrderByCustomerRequest {
  /// The reason for the cancellation.
  ///
  /// Acceptable values are: - "`changedMind`" - "`orderedWrongItem`" -
  /// "`other`"
  core.String? reason;

  OrdersCancelTestOrderByCustomerRequest();

  OrdersCancelTestOrderByCustomerRequest.fromJson(core.Map _json) {
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (reason != null) 'reason': reason!,
      };
}

class OrdersCancelTestOrderByCustomerResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersCancelTestOrderByCustomerResponse".
  core.String? kind;

  OrdersCancelTestOrderByCustomerResponse();

  OrdersCancelTestOrderByCustomerResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
      };
}

class OrdersCreateTestOrderRequest {
  /// The CLDR territory code of the country of the test order to create.
  ///
  /// Affects the currency and addresses of orders created via `template_name`,
  /// or the addresses of orders created via `test_order`. Acceptable values
  /// are: - "`US`" - "`FR`" Defaults to `US`.
  core.String? country;

  /// The test order template to use.
  ///
  /// Specify as an alternative to `testOrder` as a shortcut for retrieving a
  /// template and then creating an order using that template. Acceptable values
  /// are: - "`template1`" - "`template1a`" - "`template1b`" - "`template2`" -
  /// "`template3`"
  core.String? templateName;

  /// The test order to create.
  TestOrder? testOrder;

  OrdersCreateTestOrderRequest();

  OrdersCreateTestOrderRequest.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('templateName')) {
      templateName = _json['templateName'] as core.String;
    }
    if (_json.containsKey('testOrder')) {
      testOrder = TestOrder.fromJson(
          _json['testOrder'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (templateName != null) 'templateName': templateName!,
        if (testOrder != null) 'testOrder': testOrder!.toJson(),
      };
}

class OrdersCreateTestOrderResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersCreateTestOrderResponse".
  core.String? kind;

  /// The ID of the newly created test order.
  core.String? orderId;

  OrdersCreateTestOrderResponse();

  OrdersCreateTestOrderResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('orderId')) {
      orderId = _json['orderId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (orderId != null) 'orderId': orderId!,
      };
}

class OrdersCreateTestReturnRequest {
  /// Returned items.
  core.List<OrdersCustomBatchRequestEntryCreateTestReturnReturnItem>? items;

  OrdersCreateTestReturnRequest();

  OrdersCreateTestReturnRequest.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<OrdersCustomBatchRequestEntryCreateTestReturnReturnItem>(
              (value) => OrdersCustomBatchRequestEntryCreateTestReturnReturnItem
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
      };
}

class OrdersCreateTestReturnResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersCreateTestReturnResponse".
  core.String? kind;

  /// The ID of the newly created test order return.
  core.String? returnId;

  OrdersCreateTestReturnResponse();

  OrdersCreateTestReturnResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('returnId')) {
      returnId = _json['returnId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (returnId != null) 'returnId': returnId!,
      };
}

class OrdersCustomBatchRequestEntryCreateTestReturnReturnItem {
  /// The ID of the line item to return.
  core.String? lineItemId;

  /// Quantity that is returned.
  core.int? quantity;

  OrdersCustomBatchRequestEntryCreateTestReturnReturnItem();

  OrdersCustomBatchRequestEntryCreateTestReturnReturnItem.fromJson(
      core.Map _json) {
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (quantity != null) 'quantity': quantity!,
      };
}

class OrdersCustomBatchRequestEntryRefundItemItem {
  /// The total amount that is refunded.
  ///
  /// (e.g. refunding $5 each for 2 products should be done by setting quantity
  /// to 2 and amount to 10$) In case of multiple refunds, this should be the
  /// amount you currently want to refund to the customer.
  MonetaryAmount? amount;

  /// If true, the full item will be refunded.
  ///
  /// If this is true, amount should not be provided and will be ignored.
  core.bool? fullRefund;

  /// The ID of the line item.
  ///
  /// Either lineItemId or productId is required.
  core.String? lineItemId;

  /// The ID of the product.
  ///
  /// This is the REST ID used in the products service. Either lineItemId or
  /// productId is required.
  core.String? productId;

  /// The number of products that are refunded.
  core.int? quantity;

  OrdersCustomBatchRequestEntryRefundItemItem();

  OrdersCustomBatchRequestEntryRefundItemItem.fromJson(core.Map _json) {
    if (_json.containsKey('amount')) {
      amount = MonetaryAmount.fromJson(
          _json['amount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fullRefund')) {
      fullRefund = _json['fullRefund'] as core.bool;
    }
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (amount != null) 'amount': amount!.toJson(),
        if (fullRefund != null) 'fullRefund': fullRefund!,
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (productId != null) 'productId': productId!,
        if (quantity != null) 'quantity': quantity!,
      };
}

class OrdersCustomBatchRequestEntryRefundItemShipping {
  /// The amount that is refunded.
  ///
  /// If this is not the first refund for the shipment, this should be the newly
  /// refunded amount.
  Price? amount;

  /// If set to true, all shipping costs for the order will be refunded.
  ///
  /// If this is true, amount should not be provided and will be ignored. If set
  /// to false, submit the amount of the partial shipping refund, excluding the
  /// shipping tax. The shipping tax is calculated and handled on Google's side.
  core.bool? fullRefund;

  OrdersCustomBatchRequestEntryRefundItemShipping();

  OrdersCustomBatchRequestEntryRefundItemShipping.fromJson(core.Map _json) {
    if (_json.containsKey('amount')) {
      amount = Price.fromJson(
          _json['amount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fullRefund')) {
      fullRefund = _json['fullRefund'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (amount != null) 'amount': amount!.toJson(),
        if (fullRefund != null) 'fullRefund': fullRefund!,
      };
}

class OrdersCustomBatchRequestEntryShipLineItemsShipmentInfo {
  /// The carrier handling the shipment.
  ///
  /// See `shipments[].carrier` in the Orders resource representation for a list
  /// of acceptable values.
  core.String? carrier;

  /// The ID of the shipment.
  ///
  /// This is assigned by the merchant and is unique to each shipment.
  ///
  /// Required.
  core.String? shipmentId;

  /// The tracking ID for the shipment.
  core.String? trackingId;

  OrdersCustomBatchRequestEntryShipLineItemsShipmentInfo();

  OrdersCustomBatchRequestEntryShipLineItemsShipmentInfo.fromJson(
      core.Map _json) {
    if (_json.containsKey('carrier')) {
      carrier = _json['carrier'] as core.String;
    }
    if (_json.containsKey('shipmentId')) {
      shipmentId = _json['shipmentId'] as core.String;
    }
    if (_json.containsKey('trackingId')) {
      trackingId = _json['trackingId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrier != null) 'carrier': carrier!,
        if (shipmentId != null) 'shipmentId': shipmentId!,
        if (trackingId != null) 'trackingId': trackingId!,
      };
}

/// ScheduledDeliveryDetails used to update the scheduled delivery order.
class OrdersCustomBatchRequestEntryUpdateShipmentScheduledDeliveryDetails {
  /// The phone number of the carrier fulfilling the delivery.
  ///
  /// The phone number should be formatted as the international notation in
  core.String? carrierPhoneNumber;

  /// The date a shipment is scheduled for delivery, in ISO 8601 format.
  core.String? scheduledDate;

  OrdersCustomBatchRequestEntryUpdateShipmentScheduledDeliveryDetails();

  OrdersCustomBatchRequestEntryUpdateShipmentScheduledDeliveryDetails.fromJson(
      core.Map _json) {
    if (_json.containsKey('carrierPhoneNumber')) {
      carrierPhoneNumber = _json['carrierPhoneNumber'] as core.String;
    }
    if (_json.containsKey('scheduledDate')) {
      scheduledDate = _json['scheduledDate'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrierPhoneNumber != null)
          'carrierPhoneNumber': carrierPhoneNumber!,
        if (scheduledDate != null) 'scheduledDate': scheduledDate!,
      };
}

class OrdersGetByMerchantOrderIdResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersGetByMerchantOrderIdResponse".
  core.String? kind;

  /// The requested order.
  Order? order;

  OrdersGetByMerchantOrderIdResponse();

  OrdersGetByMerchantOrderIdResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('order')) {
      order =
          Order.fromJson(_json['order'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (order != null) 'order': order!.toJson(),
      };
}

class OrdersGetTestOrderTemplateResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersGetTestOrderTemplateResponse".
  core.String? kind;

  /// The requested test order template.
  TestOrder? template;

  OrdersGetTestOrderTemplateResponse();

  OrdersGetTestOrderTemplateResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('template')) {
      template = TestOrder.fromJson(
          _json['template'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (template != null) 'template': template!.toJson(),
      };
}

class OrdersInStoreRefundLineItemRequest {
  /// The ID of the line item to return.
  ///
  /// Either lineItemId or productId is required.
  core.String? lineItemId;

  /// The ID of the operation.
  ///
  /// Unique across all operations for a given order.
  core.String? operationId;

  /// The amount to be refunded.
  ///
  /// This may be pre-tax or post-tax depending on the location of the order.
  /// Required.
  Price? priceAmount;

  /// The ID of the product to return.
  ///
  /// This is the REST ID used in the products service. Either lineItemId or
  /// productId is required.
  core.String? productId;

  /// The quantity to return and refund.
  core.int? quantity;

  /// The reason for the return.
  ///
  /// Acceptable values are: - "`customerDiscretionaryReturn`" -
  /// "`customerInitiatedMerchantCancel`" - "`deliveredTooLate`" -
  /// "`expiredItem`" - "`invalidCoupon`" - "`malformedShippingAddress`" -
  /// "`other`" - "`productArrivedDamaged`" - "`productNotAsDescribed`" -
  /// "`qualityNotAsExpected`" - "`undeliverableShippingAddress`" -
  /// "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  core.String? reason;

  /// The explanation of the reason.
  core.String? reasonText;

  /// The amount of tax to be refunded.
  ///
  /// Required.
  Price? taxAmount;

  OrdersInStoreRefundLineItemRequest();

  OrdersInStoreRefundLineItemRequest.fromJson(core.Map _json) {
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('priceAmount')) {
      priceAmount = Price.fromJson(
          _json['priceAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.int;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('reasonText')) {
      reasonText = _json['reasonText'] as core.String;
    }
    if (_json.containsKey('taxAmount')) {
      taxAmount = Price.fromJson(
          _json['taxAmount'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (operationId != null) 'operationId': operationId!,
        if (priceAmount != null) 'priceAmount': priceAmount!.toJson(),
        if (productId != null) 'productId': productId!,
        if (quantity != null) 'quantity': quantity!,
        if (reason != null) 'reason': reason!,
        if (reasonText != null) 'reasonText': reasonText!,
        if (taxAmount != null) 'taxAmount': taxAmount!.toJson(),
      };
}

class OrdersInStoreRefundLineItemResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersInStoreRefundLineItemResponse".
  core.String? kind;

  OrdersInStoreRefundLineItemResponse();

  OrdersInStoreRefundLineItemResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrdersListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersListResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of orders.
  core.String? nextPageToken;
  core.List<Order>? resources;

  OrdersListResponse();

  OrdersListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<Order>((value) =>
              Order.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

class OrdersRefundItemRequest {
  /// The items that are refunded.
  ///
  /// Either Item or Shipping must be provided in the request.
  core.List<OrdersCustomBatchRequestEntryRefundItemItem>? items;

  /// The ID of the operation.
  ///
  /// Unique across all operations for a given order.
  core.String? operationId;

  /// The reason for the refund.
  ///
  /// Acceptable values are: - "`shippingCostAdjustment`" - "`priceAdjustment`"
  /// - "`taxAdjustment`" - "`feeAdjustment`" - "`courtesyAdjustment`" -
  /// "`adjustment`" - "`customerCancelled`" - "`noInventory`" -
  /// "`productNotAsDescribed`" - "`undeliverableShippingAddress`" -
  /// "`wrongProductShipped`" - "`lateShipmentCredit`" -
  /// "`deliveredLateByCarrier`" - "`productArrivedDamaged`"
  core.String? reason;

  /// The explanation of the reason.
  core.String? reasonText;

  /// The refund on shipping.
  ///
  /// Optional, but either Item or Shipping must be provided in the request.
  OrdersCustomBatchRequestEntryRefundItemShipping? shipping;

  OrdersRefundItemRequest();

  OrdersRefundItemRequest.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<OrdersCustomBatchRequestEntryRefundItemItem>((value) =>
              OrdersCustomBatchRequestEntryRefundItemItem.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('reasonText')) {
      reasonText = _json['reasonText'] as core.String;
    }
    if (_json.containsKey('shipping')) {
      shipping = OrdersCustomBatchRequestEntryRefundItemShipping.fromJson(
          _json['shipping'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (operationId != null) 'operationId': operationId!,
        if (reason != null) 'reason': reason!,
        if (reasonText != null) 'reasonText': reasonText!,
        if (shipping != null) 'shipping': shipping!.toJson(),
      };
}

class OrdersRefundItemResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersRefundItemResponse".
  core.String? kind;

  OrdersRefundItemResponse();

  OrdersRefundItemResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrdersRefundOrderRequest {
  /// The amount that is refunded.
  ///
  /// If this is not the first refund for the order, this should be the newly
  /// refunded amount.
  MonetaryAmount? amount;

  /// If true, the full order will be refunded, including shipping.
  ///
  /// If this is true, amount should not be provided and will be ignored.
  core.bool? fullRefund;

  /// The ID of the operation.
  ///
  /// Unique across all operations for a given order.
  core.String? operationId;

  /// The reason for the refund.
  ///
  /// Acceptable values are: - "`courtesyAdjustment`" - "`other`"
  core.String? reason;

  /// The explanation of the reason.
  core.String? reasonText;

  OrdersRefundOrderRequest();

  OrdersRefundOrderRequest.fromJson(core.Map _json) {
    if (_json.containsKey('amount')) {
      amount = MonetaryAmount.fromJson(
          _json['amount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fullRefund')) {
      fullRefund = _json['fullRefund'] as core.bool;
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('reasonText')) {
      reasonText = _json['reasonText'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (amount != null) 'amount': amount!.toJson(),
        if (fullRefund != null) 'fullRefund': fullRefund!,
        if (operationId != null) 'operationId': operationId!,
        if (reason != null) 'reason': reason!,
        if (reasonText != null) 'reasonText': reasonText!,
      };
}

class OrdersRefundOrderResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersRefundOrderResponse".
  core.String? kind;

  OrdersRefundOrderResponse();

  OrdersRefundOrderResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrdersRejectReturnLineItemRequest {
  /// The ID of the line item to return.
  ///
  /// Either lineItemId or productId is required.
  core.String? lineItemId;

  /// The ID of the operation.
  ///
  /// Unique across all operations for a given order.
  core.String? operationId;

  /// The ID of the product to return.
  ///
  /// This is the REST ID used in the products service. Either lineItemId or
  /// productId is required.
  core.String? productId;

  /// The quantity to return and refund.
  core.int? quantity;

  /// The reason for the return.
  ///
  /// Acceptable values are: - "`damagedOrUsed`" - "`missingComponent`" -
  /// "`notEligible`" - "`other`" - "`outOfReturnWindow`"
  core.String? reason;

  /// The explanation of the reason.
  core.String? reasonText;

  OrdersRejectReturnLineItemRequest();

  OrdersRejectReturnLineItemRequest.fromJson(core.Map _json) {
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.int;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('reasonText')) {
      reasonText = _json['reasonText'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (operationId != null) 'operationId': operationId!,
        if (productId != null) 'productId': productId!,
        if (quantity != null) 'quantity': quantity!,
        if (reason != null) 'reason': reason!,
        if (reasonText != null) 'reasonText': reasonText!,
      };
}

class OrdersRejectReturnLineItemResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersRejectReturnLineItemResponse".
  core.String? kind;

  OrdersRejectReturnLineItemResponse();

  OrdersRejectReturnLineItemResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrdersReturnRefundLineItemRequest {
  /// The ID of the line item to return.
  ///
  /// Either lineItemId or productId is required.
  core.String? lineItemId;

  /// The ID of the operation.
  ///
  /// Unique across all operations for a given order.
  core.String? operationId;

  /// The amount to be refunded.
  ///
  /// This may be pre-tax or post-tax depending on the location of the order. If
  /// omitted, refundless return is assumed.
  Price? priceAmount;

  /// The ID of the product to return.
  ///
  /// This is the REST ID used in the products service. Either lineItemId or
  /// productId is required.
  core.String? productId;

  /// The quantity to return and refund.
  ///
  /// Quantity is required.
  core.int? quantity;

  /// The reason for the return.
  ///
  /// Acceptable values are: - "`customerDiscretionaryReturn`" -
  /// "`customerInitiatedMerchantCancel`" - "`deliveredTooLate`" -
  /// "`expiredItem`" - "`invalidCoupon`" - "`malformedShippingAddress`" -
  /// "`other`" - "`productArrivedDamaged`" - "`productNotAsDescribed`" -
  /// "`qualityNotAsExpected`" - "`undeliverableShippingAddress`" -
  /// "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  core.String? reason;

  /// The explanation of the reason.
  core.String? reasonText;

  /// The amount of tax to be refunded.
  ///
  /// Optional, but if filled, then priceAmount must be set. Calculated
  /// automatically if not provided.
  Price? taxAmount;

  OrdersReturnRefundLineItemRequest();

  OrdersReturnRefundLineItemRequest.fromJson(core.Map _json) {
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('priceAmount')) {
      priceAmount = Price.fromJson(
          _json['priceAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.int;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('reasonText')) {
      reasonText = _json['reasonText'] as core.String;
    }
    if (_json.containsKey('taxAmount')) {
      taxAmount = Price.fromJson(
          _json['taxAmount'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (operationId != null) 'operationId': operationId!,
        if (priceAmount != null) 'priceAmount': priceAmount!.toJson(),
        if (productId != null) 'productId': productId!,
        if (quantity != null) 'quantity': quantity!,
        if (reason != null) 'reason': reason!,
        if (reasonText != null) 'reasonText': reasonText!,
        if (taxAmount != null) 'taxAmount': taxAmount!.toJson(),
      };
}

class OrdersReturnRefundLineItemResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersReturnRefundLineItemResponse".
  core.String? kind;

  OrdersReturnRefundLineItemResponse();

  OrdersReturnRefundLineItemResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrdersSetLineItemMetadataRequest {
  core.List<OrderMerchantProvidedAnnotation>? annotations;

  /// The ID of the line item to set metadata.
  ///
  /// Either lineItemId or productId is required.
  core.String? lineItemId;

  /// The ID of the operation.
  ///
  /// Unique across all operations for a given order.
  core.String? operationId;

  /// The ID of the product to set metadata.
  ///
  /// This is the REST ID used in the products service. Either lineItemId or
  /// productId is required.
  core.String? productId;

  OrdersSetLineItemMetadataRequest();

  OrdersSetLineItemMetadataRequest.fromJson(core.Map _json) {
    if (_json.containsKey('annotations')) {
      annotations = (_json['annotations'] as core.List)
          .map<OrderMerchantProvidedAnnotation>((value) =>
              OrderMerchantProvidedAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotations != null)
          'annotations': annotations!.map((value) => value.toJson()).toList(),
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (operationId != null) 'operationId': operationId!,
        if (productId != null) 'productId': productId!,
      };
}

class OrdersSetLineItemMetadataResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersSetLineItemMetadataResponse".
  core.String? kind;

  OrdersSetLineItemMetadataResponse();

  OrdersSetLineItemMetadataResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrdersShipLineItemsRequest {
  /// Line items to ship.
  core.List<OrderShipmentLineItemShipment>? lineItems;

  /// The ID of the operation.
  ///
  /// Unique across all operations for a given order.
  core.String? operationId;

  /// ID of the shipment group.
  ///
  /// Required for orders that use the orderinvoices service.
  core.String? shipmentGroupId;

  /// Shipment information.
  ///
  /// This field is repeated because a single line item can be shipped in
  /// several packages (and have several tracking IDs).
  core.List<OrdersCustomBatchRequestEntryShipLineItemsShipmentInfo>?
      shipmentInfos;

  OrdersShipLineItemsRequest();

  OrdersShipLineItemsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('lineItems')) {
      lineItems = (_json['lineItems'] as core.List)
          .map<OrderShipmentLineItemShipment>((value) =>
              OrderShipmentLineItemShipment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('shipmentGroupId')) {
      shipmentGroupId = _json['shipmentGroupId'] as core.String;
    }
    if (_json.containsKey('shipmentInfos')) {
      shipmentInfos = (_json['shipmentInfos'] as core.List)
          .map<OrdersCustomBatchRequestEntryShipLineItemsShipmentInfo>(
              (value) => OrdersCustomBatchRequestEntryShipLineItemsShipmentInfo
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineItems != null)
          'lineItems': lineItems!.map((value) => value.toJson()).toList(),
        if (operationId != null) 'operationId': operationId!,
        if (shipmentGroupId != null) 'shipmentGroupId': shipmentGroupId!,
        if (shipmentInfos != null)
          'shipmentInfos':
              shipmentInfos!.map((value) => value.toJson()).toList(),
      };
}

class OrdersShipLineItemsResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersShipLineItemsResponse".
  core.String? kind;

  OrdersShipLineItemsResponse();

  OrdersShipLineItemsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrdersUpdateLineItemShippingDetailsRequest {
  /// Updated delivery by date, in ISO 8601 format.
  ///
  /// If not specified only ship by date is updated. Provided date should be
  /// within 1 year timeframe and can not be a date in the past.
  core.String? deliverByDate;

  /// The ID of the line item to set metadata.
  ///
  /// Either lineItemId or productId is required.
  core.String? lineItemId;

  /// The ID of the operation.
  ///
  /// Unique across all operations for a given order.
  core.String? operationId;

  /// The ID of the product to set metadata.
  ///
  /// This is the REST ID used in the products service. Either lineItemId or
  /// productId is required.
  core.String? productId;

  /// Updated ship by date, in ISO 8601 format.
  ///
  /// If not specified only deliver by date is updated. Provided date should be
  /// within 1 year timeframe and can not be a date in the past.
  core.String? shipByDate;

  OrdersUpdateLineItemShippingDetailsRequest();

  OrdersUpdateLineItemShippingDetailsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('deliverByDate')) {
      deliverByDate = _json['deliverByDate'] as core.String;
    }
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('shipByDate')) {
      shipByDate = _json['shipByDate'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deliverByDate != null) 'deliverByDate': deliverByDate!,
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (operationId != null) 'operationId': operationId!,
        if (productId != null) 'productId': productId!,
        if (shipByDate != null) 'shipByDate': shipByDate!,
      };
}

class OrdersUpdateLineItemShippingDetailsResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "content#ordersUpdateLineItemShippingDetailsResponse".
  core.String? kind;

  OrdersUpdateLineItemShippingDetailsResponse();

  OrdersUpdateLineItemShippingDetailsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrdersUpdateMerchantOrderIdRequest {
  /// The merchant order id to be assigned to the order.
  ///
  /// Must be unique per merchant.
  core.String? merchantOrderId;

  /// The ID of the operation.
  ///
  /// Unique across all operations for a given order.
  core.String? operationId;

  OrdersUpdateMerchantOrderIdRequest();

  OrdersUpdateMerchantOrderIdRequest.fromJson(core.Map _json) {
    if (_json.containsKey('merchantOrderId')) {
      merchantOrderId = _json['merchantOrderId'] as core.String;
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (merchantOrderId != null) 'merchantOrderId': merchantOrderId!,
        if (operationId != null) 'operationId': operationId!,
      };
}

class OrdersUpdateMerchantOrderIdResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersUpdateMerchantOrderIdResponse".
  core.String? kind;

  OrdersUpdateMerchantOrderIdResponse();

  OrdersUpdateMerchantOrderIdResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

class OrdersUpdateShipmentRequest {
  /// The carrier handling the shipment.
  ///
  /// Not updated if missing. See `shipments[].carrier` in the Orders resource
  /// representation for a list of acceptable values.
  core.String? carrier;

  /// Date on which the shipment has been delivered, in ISO 8601 format.
  ///
  /// Optional and can be provided only if `status` is `delivered`.
  core.String? deliveryDate;

  /// Date after which the pickup will expire, in ISO 8601 format.
  ///
  /// Required only when order is buy-online-pickup-in-store(BOPIS) and `status`
  /// is `ready for pickup`.
  core.String? lastPickupDate;

  /// The ID of the operation.
  ///
  /// Unique across all operations for a given order.
  core.String? operationId;

  /// Date on which the shipment has been ready for pickup, in ISO 8601 format.
  ///
  /// Optional and can be provided only if `status` is `ready for pickup`.
  core.String? readyPickupDate;

  /// Delivery details of the shipment if scheduling is needed.
  OrdersCustomBatchRequestEntryUpdateShipmentScheduledDeliveryDetails?
      scheduledDeliveryDetails;

  /// The ID of the shipment.
  core.String? shipmentId;

  /// New status for the shipment.
  ///
  /// Not updated if missing. Acceptable values are: - "`delivered`" -
  /// "`undeliverable`" - "`readyForPickup`"
  core.String? status;

  /// The tracking ID for the shipment.
  ///
  /// Not updated if missing.
  core.String? trackingId;

  /// Date on which the shipment has been undeliverable, in ISO 8601 format.
  ///
  /// Optional and can be provided only if `status` is `undeliverable`.
  core.String? undeliveredDate;

  OrdersUpdateShipmentRequest();

  OrdersUpdateShipmentRequest.fromJson(core.Map _json) {
    if (_json.containsKey('carrier')) {
      carrier = _json['carrier'] as core.String;
    }
    if (_json.containsKey('deliveryDate')) {
      deliveryDate = _json['deliveryDate'] as core.String;
    }
    if (_json.containsKey('lastPickupDate')) {
      lastPickupDate = _json['lastPickupDate'] as core.String;
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('readyPickupDate')) {
      readyPickupDate = _json['readyPickupDate'] as core.String;
    }
    if (_json.containsKey('scheduledDeliveryDetails')) {
      scheduledDeliveryDetails =
          OrdersCustomBatchRequestEntryUpdateShipmentScheduledDeliveryDetails
              .fromJson(_json['scheduledDeliveryDetails']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shipmentId')) {
      shipmentId = _json['shipmentId'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('trackingId')) {
      trackingId = _json['trackingId'] as core.String;
    }
    if (_json.containsKey('undeliveredDate')) {
      undeliveredDate = _json['undeliveredDate'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrier != null) 'carrier': carrier!,
        if (deliveryDate != null) 'deliveryDate': deliveryDate!,
        if (lastPickupDate != null) 'lastPickupDate': lastPickupDate!,
        if (operationId != null) 'operationId': operationId!,
        if (readyPickupDate != null) 'readyPickupDate': readyPickupDate!,
        if (scheduledDeliveryDetails != null)
          'scheduledDeliveryDetails': scheduledDeliveryDetails!.toJson(),
        if (shipmentId != null) 'shipmentId': shipmentId!,
        if (status != null) 'status': status!,
        if (trackingId != null) 'trackingId': trackingId!,
        if (undeliveredDate != null) 'undeliveredDate': undeliveredDate!,
      };
}

class OrdersUpdateShipmentResponse {
  /// The status of the execution.
  ///
  /// Acceptable values are: - "`duplicate`" - "`executed`"
  core.String? executionStatus;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#ordersUpdateShipmentResponse".
  core.String? kind;

  OrdersUpdateShipmentResponse();

  OrdersUpdateShipmentResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executionStatus')) {
      executionStatus = _json['executionStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executionStatus != null) 'executionStatus': executionStatus!,
        if (kind != null) 'kind': kind!,
      };
}

/// Request message for the PauseProgram method.
class PauseBuyOnGoogleProgramRequest {
  PauseBuyOnGoogleProgramRequest();

  PauseBuyOnGoogleProgramRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Additional information required for PAYMENT_SERVICE_PROVIDER link type.
class PaymentServiceProviderLinkInfo {
  /// The business country of the merchant account as identified by the third
  /// party service provider.
  core.String? externalAccountBusinessCountry;

  /// The id used by the third party service provider to identify the merchant.
  core.String? externalAccountId;

  PaymentServiceProviderLinkInfo();

  PaymentServiceProviderLinkInfo.fromJson(core.Map _json) {
    if (_json.containsKey('externalAccountBusinessCountry')) {
      externalAccountBusinessCountry =
          _json['externalAccountBusinessCountry'] as core.String;
    }
    if (_json.containsKey('externalAccountId')) {
      externalAccountId = _json['externalAccountId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (externalAccountBusinessCountry != null)
          'externalAccountBusinessCountry': externalAccountBusinessCountry!,
        if (externalAccountId != null) 'externalAccountId': externalAccountId!,
      };
}

class PickupCarrierService {
  /// The name of the pickup carrier (e.g., `"UPS"`).
  ///
  /// Required.
  core.String? carrierName;

  /// The name of the pickup service (e.g., `"Access point"`).
  ///
  /// Required.
  core.String? serviceName;

  PickupCarrierService();

  PickupCarrierService.fromJson(core.Map _json) {
    if (_json.containsKey('carrierName')) {
      carrierName = _json['carrierName'] as core.String;
    }
    if (_json.containsKey('serviceName')) {
      serviceName = _json['serviceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrierName != null) 'carrierName': carrierName!,
        if (serviceName != null) 'serviceName': serviceName!,
      };
}

class PickupServicesPickupService {
  /// The name of the carrier (e.g., `"UPS"`).
  ///
  /// Always present.
  core.String? carrierName;

  /// The CLDR country code of the carrier (e.g., "US").
  ///
  /// Always present.
  core.String? country;

  /// The name of the pickup service (e.g., `"Access point"`).
  ///
  /// Always present.
  core.String? serviceName;

  PickupServicesPickupService();

  PickupServicesPickupService.fromJson(core.Map _json) {
    if (_json.containsKey('carrierName')) {
      carrierName = _json['carrierName'] as core.String;
    }
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('serviceName')) {
      serviceName = _json['serviceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrierName != null) 'carrierName': carrierName!,
        if (country != null) 'country': country!,
        if (serviceName != null) 'serviceName': serviceName!,
      };
}

class PosCustomBatchRequest {
  /// The request entries to be processed in the batch.
  core.List<PosCustomBatchRequestEntry>? entries;

  PosCustomBatchRequest();

  PosCustomBatchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<PosCustomBatchRequestEntry>((value) =>
              PosCustomBatchRequestEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

class PosCustomBatchRequestEntry {
  /// An entry ID, unique within the batch request.
  core.int? batchId;

  /// The inventory to submit.
  ///
  /// This should be set only if the method is `inventory`.
  PosInventory? inventory;

  /// The ID of the POS data provider.
  core.String? merchantId;

  /// The method of the batch entry.
  ///
  /// Acceptable values are: - "`delete`" - "`get`" - "`insert`" - "`inventory`"
  /// - "`sale`"
  core.String? method;

  /// The sale information to submit.
  ///
  /// This should be set only if the method is `sale`.
  PosSale? sale;

  /// The store information to submit.
  ///
  /// This should be set only if the method is `insert`.
  PosStore? store;

  /// The store code.
  ///
  /// This should be set only if the method is `delete` or `get`.
  core.String? storeCode;

  /// The ID of the account for which to get/submit data.
  core.String? targetMerchantId;

  PosCustomBatchRequestEntry();

  PosCustomBatchRequestEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('inventory')) {
      inventory = PosInventory.fromJson(
          _json['inventory'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('sale')) {
      sale = PosSale.fromJson(
          _json['sale'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('store')) {
      store = PosStore.fromJson(
          _json['store'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('storeCode')) {
      storeCode = _json['storeCode'] as core.String;
    }
    if (_json.containsKey('targetMerchantId')) {
      targetMerchantId = _json['targetMerchantId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (inventory != null) 'inventory': inventory!.toJson(),
        if (merchantId != null) 'merchantId': merchantId!,
        if (method != null) 'method': method!,
        if (sale != null) 'sale': sale!.toJson(),
        if (store != null) 'store': store!.toJson(),
        if (storeCode != null) 'storeCode': storeCode!,
        if (targetMerchantId != null) 'targetMerchantId': targetMerchantId!,
      };
}

class PosCustomBatchResponse {
  /// The result of the execution of the batch requests.
  core.List<PosCustomBatchResponseEntry>? entries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#posCustomBatchResponse".
  core.String? kind;

  PosCustomBatchResponse();

  PosCustomBatchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<PosCustomBatchResponseEntry>((value) =>
              PosCustomBatchResponseEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class PosCustomBatchResponseEntry {
  /// The ID of the request entry to which this entry responds.
  core.int? batchId;

  /// A list of errors defined if, and only if, the request failed.
  Errors? errors;

  /// The updated inventory information.
  PosInventory? inventory;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#posCustomBatchResponseEntry`"
  core.String? kind;

  /// The updated sale information.
  PosSale? sale;

  /// The retrieved or updated store information.
  PosStore? store;

  PosCustomBatchResponseEntry();

  PosCustomBatchResponseEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('errors')) {
      errors = Errors.fromJson(
          _json['errors'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inventory')) {
      inventory = PosInventory.fromJson(
          _json['inventory'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('sale')) {
      sale = PosSale.fromJson(
          _json['sale'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('store')) {
      store = PosStore.fromJson(
          _json['store'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (errors != null) 'errors': errors!.toJson(),
        if (inventory != null) 'inventory': inventory!.toJson(),
        if (kind != null) 'kind': kind!,
        if (sale != null) 'sale': sale!.toJson(),
        if (store != null) 'store': store!.toJson(),
      };
}

class PosDataProviders {
  /// Country code.
  core.String? country;

  /// A list of POS data providers.
  core.List<PosDataProvidersPosDataProvider>? posDataProviders;

  PosDataProviders();

  PosDataProviders.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('posDataProviders')) {
      posDataProviders = (_json['posDataProviders'] as core.List)
          .map<PosDataProvidersPosDataProvider>((value) =>
              PosDataProvidersPosDataProvider.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (posDataProviders != null)
          'posDataProviders':
              posDataProviders!.map((value) => value.toJson()).toList(),
      };
}

class PosDataProvidersPosDataProvider {
  /// The display name of Pos data Provider.
  core.String? displayName;

  /// The full name of this POS data Provider.
  core.String? fullName;

  /// The ID of the account.
  core.String? providerId;

  PosDataProvidersPosDataProvider();

  PosDataProvidersPosDataProvider.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('fullName')) {
      fullName = _json['fullName'] as core.String;
    }
    if (_json.containsKey('providerId')) {
      providerId = _json['providerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (fullName != null) 'fullName': fullName!,
        if (providerId != null) 'providerId': providerId!,
      };
}

/// The absolute quantity of an item available at the given store.
class PosInventory {
  /// The two-letter ISO 639-1 language code for the item.
  ///
  /// Required.
  core.String? contentLanguage;

  /// Global Trade Item Number.
  core.String? gtin;

  /// A unique identifier for the item.
  ///
  /// Required.
  core.String? itemId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#posInventory`"
  core.String? kind;

  /// The current price of the item.
  ///
  /// Required.
  Price? price;

  /// The available quantity of the item.
  ///
  /// Required.
  core.String? quantity;

  /// The identifier of the merchant's store.
  ///
  /// Either a `storeCode` inserted via the API or the code of the store in
  /// Google My Business.
  ///
  /// Required.
  core.String? storeCode;

  /// The CLDR territory code for the item.
  ///
  /// Required.
  core.String? targetCountry;

  /// The inventory timestamp, in ISO 8601 format.
  ///
  /// Required.
  core.String? timestamp;

  PosInventory();

  PosInventory.fromJson(core.Map _json) {
    if (_json.containsKey('contentLanguage')) {
      contentLanguage = _json['contentLanguage'] as core.String;
    }
    if (_json.containsKey('gtin')) {
      gtin = _json['gtin'] as core.String;
    }
    if (_json.containsKey('itemId')) {
      itemId = _json['itemId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.String;
    }
    if (_json.containsKey('storeCode')) {
      storeCode = _json['storeCode'] as core.String;
    }
    if (_json.containsKey('targetCountry')) {
      targetCountry = _json['targetCountry'] as core.String;
    }
    if (_json.containsKey('timestamp')) {
      timestamp = _json['timestamp'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentLanguage != null) 'contentLanguage': contentLanguage!,
        if (gtin != null) 'gtin': gtin!,
        if (itemId != null) 'itemId': itemId!,
        if (kind != null) 'kind': kind!,
        if (price != null) 'price': price!.toJson(),
        if (quantity != null) 'quantity': quantity!,
        if (storeCode != null) 'storeCode': storeCode!,
        if (targetCountry != null) 'targetCountry': targetCountry!,
        if (timestamp != null) 'timestamp': timestamp!,
      };
}

class PosInventoryRequest {
  /// The two-letter ISO 639-1 language code for the item.
  ///
  /// Required.
  core.String? contentLanguage;

  /// Global Trade Item Number.
  core.String? gtin;

  /// A unique identifier for the item.
  ///
  /// Required.
  core.String? itemId;

  /// The current price of the item.
  ///
  /// Required.
  Price? price;

  /// The available quantity of the item.
  ///
  /// Required.
  core.String? quantity;

  /// The identifier of the merchant's store.
  ///
  /// Either a `storeCode` inserted via the API or the code of the store in
  /// Google My Business.
  ///
  /// Required.
  core.String? storeCode;

  /// The CLDR territory code for the item.
  ///
  /// Required.
  core.String? targetCountry;

  /// The inventory timestamp, in ISO 8601 format.
  ///
  /// Required.
  core.String? timestamp;

  PosInventoryRequest();

  PosInventoryRequest.fromJson(core.Map _json) {
    if (_json.containsKey('contentLanguage')) {
      contentLanguage = _json['contentLanguage'] as core.String;
    }
    if (_json.containsKey('gtin')) {
      gtin = _json['gtin'] as core.String;
    }
    if (_json.containsKey('itemId')) {
      itemId = _json['itemId'] as core.String;
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.String;
    }
    if (_json.containsKey('storeCode')) {
      storeCode = _json['storeCode'] as core.String;
    }
    if (_json.containsKey('targetCountry')) {
      targetCountry = _json['targetCountry'] as core.String;
    }
    if (_json.containsKey('timestamp')) {
      timestamp = _json['timestamp'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentLanguage != null) 'contentLanguage': contentLanguage!,
        if (gtin != null) 'gtin': gtin!,
        if (itemId != null) 'itemId': itemId!,
        if (price != null) 'price': price!.toJson(),
        if (quantity != null) 'quantity': quantity!,
        if (storeCode != null) 'storeCode': storeCode!,
        if (targetCountry != null) 'targetCountry': targetCountry!,
        if (timestamp != null) 'timestamp': timestamp!,
      };
}

class PosInventoryResponse {
  /// The two-letter ISO 639-1 language code for the item.
  ///
  /// Required.
  core.String? contentLanguage;

  /// Global Trade Item Number.
  core.String? gtin;

  /// A unique identifier for the item.
  ///
  /// Required.
  core.String? itemId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#posInventoryResponse".
  core.String? kind;

  /// The current price of the item.
  ///
  /// Required.
  Price? price;

  /// The available quantity of the item.
  ///
  /// Required.
  core.String? quantity;

  /// The identifier of the merchant's store.
  ///
  /// Either a `storeCode` inserted via the API or the code of the store in
  /// Google My Business.
  ///
  /// Required.
  core.String? storeCode;

  /// The CLDR territory code for the item.
  ///
  /// Required.
  core.String? targetCountry;

  /// The inventory timestamp, in ISO 8601 format.
  ///
  /// Required.
  core.String? timestamp;

  PosInventoryResponse();

  PosInventoryResponse.fromJson(core.Map _json) {
    if (_json.containsKey('contentLanguage')) {
      contentLanguage = _json['contentLanguage'] as core.String;
    }
    if (_json.containsKey('gtin')) {
      gtin = _json['gtin'] as core.String;
    }
    if (_json.containsKey('itemId')) {
      itemId = _json['itemId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.String;
    }
    if (_json.containsKey('storeCode')) {
      storeCode = _json['storeCode'] as core.String;
    }
    if (_json.containsKey('targetCountry')) {
      targetCountry = _json['targetCountry'] as core.String;
    }
    if (_json.containsKey('timestamp')) {
      timestamp = _json['timestamp'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentLanguage != null) 'contentLanguage': contentLanguage!,
        if (gtin != null) 'gtin': gtin!,
        if (itemId != null) 'itemId': itemId!,
        if (kind != null) 'kind': kind!,
        if (price != null) 'price': price!.toJson(),
        if (quantity != null) 'quantity': quantity!,
        if (storeCode != null) 'storeCode': storeCode!,
        if (targetCountry != null) 'targetCountry': targetCountry!,
        if (timestamp != null) 'timestamp': timestamp!,
      };
}

class PosListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#posListResponse".
  core.String? kind;
  core.List<PosStore>? resources;

  PosListResponse();

  PosListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<PosStore>((value) =>
              PosStore.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

/// The change of the available quantity of an item at the given store.
class PosSale {
  /// The two-letter ISO 639-1 language code for the item.
  ///
  /// Required.
  core.String? contentLanguage;

  /// Global Trade Item Number.
  core.String? gtin;

  /// A unique identifier for the item.
  ///
  /// Required.
  core.String? itemId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#posSale`"
  core.String? kind;

  /// The price of the item.
  ///
  /// Required.
  Price? price;

  /// The relative change of the available quantity.
  ///
  /// Negative for items returned.
  ///
  /// Required.
  core.String? quantity;

  /// A unique ID to group items from the same sale event.
  core.String? saleId;

  /// The identifier of the merchant's store.
  ///
  /// Either a `storeCode` inserted via the API or the code of the store in
  /// Google My Business.
  ///
  /// Required.
  core.String? storeCode;

  /// The CLDR territory code for the item.
  ///
  /// Required.
  core.String? targetCountry;

  /// The inventory timestamp, in ISO 8601 format.
  ///
  /// Required.
  core.String? timestamp;

  PosSale();

  PosSale.fromJson(core.Map _json) {
    if (_json.containsKey('contentLanguage')) {
      contentLanguage = _json['contentLanguage'] as core.String;
    }
    if (_json.containsKey('gtin')) {
      gtin = _json['gtin'] as core.String;
    }
    if (_json.containsKey('itemId')) {
      itemId = _json['itemId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.String;
    }
    if (_json.containsKey('saleId')) {
      saleId = _json['saleId'] as core.String;
    }
    if (_json.containsKey('storeCode')) {
      storeCode = _json['storeCode'] as core.String;
    }
    if (_json.containsKey('targetCountry')) {
      targetCountry = _json['targetCountry'] as core.String;
    }
    if (_json.containsKey('timestamp')) {
      timestamp = _json['timestamp'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentLanguage != null) 'contentLanguage': contentLanguage!,
        if (gtin != null) 'gtin': gtin!,
        if (itemId != null) 'itemId': itemId!,
        if (kind != null) 'kind': kind!,
        if (price != null) 'price': price!.toJson(),
        if (quantity != null) 'quantity': quantity!,
        if (saleId != null) 'saleId': saleId!,
        if (storeCode != null) 'storeCode': storeCode!,
        if (targetCountry != null) 'targetCountry': targetCountry!,
        if (timestamp != null) 'timestamp': timestamp!,
      };
}

class PosSaleRequest {
  /// The two-letter ISO 639-1 language code for the item.
  ///
  /// Required.
  core.String? contentLanguage;

  /// Global Trade Item Number.
  core.String? gtin;

  /// A unique identifier for the item.
  ///
  /// Required.
  core.String? itemId;

  /// The price of the item.
  ///
  /// Required.
  Price? price;

  /// The relative change of the available quantity.
  ///
  /// Negative for items returned.
  ///
  /// Required.
  core.String? quantity;

  /// A unique ID to group items from the same sale event.
  core.String? saleId;

  /// The identifier of the merchant's store.
  ///
  /// Either a `storeCode` inserted via the API or the code of the store in
  /// Google My Business.
  ///
  /// Required.
  core.String? storeCode;

  /// The CLDR territory code for the item.
  ///
  /// Required.
  core.String? targetCountry;

  /// The inventory timestamp, in ISO 8601 format.
  ///
  /// Required.
  core.String? timestamp;

  PosSaleRequest();

  PosSaleRequest.fromJson(core.Map _json) {
    if (_json.containsKey('contentLanguage')) {
      contentLanguage = _json['contentLanguage'] as core.String;
    }
    if (_json.containsKey('gtin')) {
      gtin = _json['gtin'] as core.String;
    }
    if (_json.containsKey('itemId')) {
      itemId = _json['itemId'] as core.String;
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.String;
    }
    if (_json.containsKey('saleId')) {
      saleId = _json['saleId'] as core.String;
    }
    if (_json.containsKey('storeCode')) {
      storeCode = _json['storeCode'] as core.String;
    }
    if (_json.containsKey('targetCountry')) {
      targetCountry = _json['targetCountry'] as core.String;
    }
    if (_json.containsKey('timestamp')) {
      timestamp = _json['timestamp'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentLanguage != null) 'contentLanguage': contentLanguage!,
        if (gtin != null) 'gtin': gtin!,
        if (itemId != null) 'itemId': itemId!,
        if (price != null) 'price': price!.toJson(),
        if (quantity != null) 'quantity': quantity!,
        if (saleId != null) 'saleId': saleId!,
        if (storeCode != null) 'storeCode': storeCode!,
        if (targetCountry != null) 'targetCountry': targetCountry!,
        if (timestamp != null) 'timestamp': timestamp!,
      };
}

class PosSaleResponse {
  /// The two-letter ISO 639-1 language code for the item.
  ///
  /// Required.
  core.String? contentLanguage;

  /// Global Trade Item Number.
  core.String? gtin;

  /// A unique identifier for the item.
  ///
  /// Required.
  core.String? itemId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#posSaleResponse".
  core.String? kind;

  /// The price of the item.
  ///
  /// Required.
  Price? price;

  /// The relative change of the available quantity.
  ///
  /// Negative for items returned.
  ///
  /// Required.
  core.String? quantity;

  /// A unique ID to group items from the same sale event.
  core.String? saleId;

  /// The identifier of the merchant's store.
  ///
  /// Either a `storeCode` inserted via the API or the code of the store in
  /// Google My Business.
  ///
  /// Required.
  core.String? storeCode;

  /// The CLDR territory code for the item.
  ///
  /// Required.
  core.String? targetCountry;

  /// The inventory timestamp, in ISO 8601 format.
  ///
  /// Required.
  core.String? timestamp;

  PosSaleResponse();

  PosSaleResponse.fromJson(core.Map _json) {
    if (_json.containsKey('contentLanguage')) {
      contentLanguage = _json['contentLanguage'] as core.String;
    }
    if (_json.containsKey('gtin')) {
      gtin = _json['gtin'] as core.String;
    }
    if (_json.containsKey('itemId')) {
      itemId = _json['itemId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('quantity')) {
      quantity = _json['quantity'] as core.String;
    }
    if (_json.containsKey('saleId')) {
      saleId = _json['saleId'] as core.String;
    }
    if (_json.containsKey('storeCode')) {
      storeCode = _json['storeCode'] as core.String;
    }
    if (_json.containsKey('targetCountry')) {
      targetCountry = _json['targetCountry'] as core.String;
    }
    if (_json.containsKey('timestamp')) {
      timestamp = _json['timestamp'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentLanguage != null) 'contentLanguage': contentLanguage!,
        if (gtin != null) 'gtin': gtin!,
        if (itemId != null) 'itemId': itemId!,
        if (kind != null) 'kind': kind!,
        if (price != null) 'price': price!.toJson(),
        if (quantity != null) 'quantity': quantity!,
        if (saleId != null) 'saleId': saleId!,
        if (storeCode != null) 'storeCode': storeCode!,
        if (targetCountry != null) 'targetCountry': targetCountry!,
        if (timestamp != null) 'timestamp': timestamp!,
      };
}

/// Store resource.
class PosStore {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#posStore`"
  core.String? kind;

  /// The street address of the store.
  ///
  /// Required.
  core.String? storeAddress;

  /// A store identifier that is unique for the given merchant.
  ///
  /// Required.
  core.String? storeCode;

  PosStore();

  PosStore.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('storeAddress')) {
      storeAddress = _json['storeAddress'] as core.String;
    }
    if (_json.containsKey('storeCode')) {
      storeCode = _json['storeCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (storeAddress != null) 'storeAddress': storeAddress!,
        if (storeCode != null) 'storeCode': storeCode!,
      };
}

class PostalCodeGroup {
  /// The CLDR territory code of the country the postal code group applies to.
  ///
  /// Required.
  core.String? country;

  /// The name of the postal code group, referred to in headers.
  ///
  /// Required.
  core.String? name;

  /// A range of postal codes.
  ///
  /// Required.
  core.List<PostalCodeRange>? postalCodeRanges;

  PostalCodeGroup();

  PostalCodeGroup.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('postalCodeRanges')) {
      postalCodeRanges = (_json['postalCodeRanges'] as core.List)
          .map<PostalCodeRange>((value) => PostalCodeRange.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (name != null) 'name': name!,
        if (postalCodeRanges != null)
          'postalCodeRanges':
              postalCodeRanges!.map((value) => value.toJson()).toList(),
      };
}

class PostalCodeRange {
  /// A postal code or a pattern of the form `prefix*` denoting the inclusive
  /// lower bound of the range defining the area.
  ///
  /// Examples values: `"94108"`, `"9410*"`, `"9*"`. Required.
  core.String? postalCodeRangeBegin;

  /// A postal code or a pattern of the form `prefix*` denoting the inclusive
  /// upper bound of the range defining the area.
  ///
  /// It must have the same length as `postalCodeRangeBegin`: if
  /// `postalCodeRangeBegin` is a postal code then `postalCodeRangeEnd` must be
  /// a postal code too; if `postalCodeRangeBegin` is a pattern then
  /// `postalCodeRangeEnd` must be a pattern with the same prefix length.
  /// Optional: if not set, then the area is defined as being all the postal
  /// codes matching `postalCodeRangeBegin`.
  core.String? postalCodeRangeEnd;

  PostalCodeRange();

  PostalCodeRange.fromJson(core.Map _json) {
    if (_json.containsKey('postalCodeRangeBegin')) {
      postalCodeRangeBegin = _json['postalCodeRangeBegin'] as core.String;
    }
    if (_json.containsKey('postalCodeRangeEnd')) {
      postalCodeRangeEnd = _json['postalCodeRangeEnd'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (postalCodeRangeBegin != null)
          'postalCodeRangeBegin': postalCodeRangeBegin!,
        if (postalCodeRangeEnd != null)
          'postalCodeRangeEnd': postalCodeRangeEnd!,
      };
}

class Price {
  /// The currency of the price.
  core.String? currency;

  /// The price represented as a number.
  core.String? value;

  Price();

  Price.fromJson(core.Map _json) {
    if (_json.containsKey('currency')) {
      currency = _json['currency'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currency != null) 'currency': currency!,
        if (value != null) 'value': value!,
      };
}

/// The price represented as a number and currency.
class PriceAmount {
  /// The currency of the price.
  core.String? currency;

  /// The price represented as a number.
  core.String? value;

  PriceAmount();

  PriceAmount.fromJson(core.Map _json) {
    if (_json.containsKey('currency')) {
      currency = _json['currency'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currency != null) 'currency': currency!,
        if (value != null) 'value': value!,
      };
}

/// Required product attributes are primarily defined by the products data
/// specification.
///
/// See the Products Data Specification Help Center article for information.
/// Product data. After inserting, updating, or deleting a product, it may take
/// several minutes before changes take effect.
class Product {
  /// Additional URLs of images of the item.
  core.List<core.String>? additionalImageLinks;

  /// Additional cut of the item.
  ///
  /// Used together with size_type to represent combined size types for apparel
  /// items.
  core.String? additionalSizeType;

  /// Used to group items in an arbitrary way.
  ///
  /// Only for CPA%, discouraged otherwise.
  core.String? adsGrouping;

  /// Similar to ads_grouping, but only works on CPC.
  core.List<core.String>? adsLabels;

  /// Allows advertisers to override the item URL when the product is shown
  /// within the context of Product Ads.
  core.String? adsRedirect;

  /// Should be set to true if the item is targeted towards adults.
  core.bool? adult;

  /// Target age group of the item.
  core.String? ageGroup;

  /// Availability status of the item.
  core.String? availability;

  /// The day a pre-ordered product becomes available for delivery, in ISO 8601
  /// format.
  core.String? availabilityDate;

  /// Brand of the item.
  core.String? brand;

  /// URL for the canonical version of your item's landing page.
  core.String? canonicalLink;

  /// The item's channel (online or local).
  ///
  /// Acceptable values are: - "`local`" - "`online`"
  ///
  /// Required.
  core.String? channel;

  /// Color of the item.
  core.String? color;

  /// Condition or state of the item.
  core.String? condition;

  /// The two-letter ISO 639-1 language code for the item.
  ///
  /// Required.
  core.String? contentLanguage;

  /// Cost of goods sold.
  ///
  /// Used for gross profit reporting.
  Price? costOfGoodsSold;

  /// A list of custom (merchant-provided) attributes.
  ///
  /// It can also be used for submitting any attribute of the feed specification
  /// in its generic form (e.g., `{ "name": "size type", "value": "regular" }`).
  /// This is useful for submitting attributes not explicitly exposed by the
  /// API, such as additional attributes used for Buy on Google (formerly known
  /// as Shopping Actions).
  core.List<CustomAttribute>? customAttributes;

  /// Custom label 0 for custom grouping of items in a Shopping campaign.
  core.String? customLabel0;

  /// Custom label 1 for custom grouping of items in a Shopping campaign.
  core.String? customLabel1;

  /// Custom label 2 for custom grouping of items in a Shopping campaign.
  core.String? customLabel2;

  /// Custom label 3 for custom grouping of items in a Shopping campaign.
  core.String? customLabel3;

  /// Custom label 4 for custom grouping of items in a Shopping campaign.
  core.String? customLabel4;

  /// Description of the item.
  core.String? description;

  /// An identifier for an item for dynamic remarketing campaigns.
  core.String? displayAdsId;

  /// URL directly to your item's landing page for dynamic remarketing
  /// campaigns.
  core.String? displayAdsLink;

  /// Advertiser-specified recommendations.
  core.List<core.String>? displayAdsSimilarIds;

  /// Title of an item for dynamic remarketing campaigns.
  core.String? displayAdsTitle;

  /// Offer margin for dynamic remarketing campaigns.
  core.double? displayAdsValue;

  /// The energy efficiency class as defined in EU directive 2010/30/EU.
  core.String? energyEfficiencyClass;

  /// The list of destinations to exclude for this target (corresponds to
  /// unchecked check boxes in Merchant Center).
  core.List<core.String>? excludedDestinations;

  /// Date on which the item should expire, as specified upon insertion, in ISO
  /// 8601 format.
  ///
  /// The actual expiration date in Google Shopping is exposed in
  /// `productstatuses` as `googleExpirationDate` and might be earlier if
  /// `expirationDate` is too far in the future.
  core.String? expirationDate;

  /// Target gender of the item.
  core.String? gender;

  /// Google's category of the item (see
  /// [Google product taxonomy](https://support.google.com/merchants/answer/1705911)).
  ///
  /// When querying products, this field will contain the user provided value.
  /// There is currently no way to get back the auto assigned google product
  /// categories through the API.
  core.String? googleProductCategory;

  /// Global Trade Item Number (GTIN) of the item.
  core.String? gtin;

  /// The REST ID of the product.
  ///
  /// Content API methods that operate on products take this as their
  /// `productId` parameter. The REST ID for a product is of the form
  /// channel:contentLanguage: targetCountry: offerId.
  core.String? id;

  /// False when the item does not have unique product identifiers appropriate
  /// to its category, such as GTIN, MPN, and brand.
  ///
  /// Required according to the Unique Product Identifier Rules for all target
  /// countries except for Canada.
  core.bool? identifierExists;

  /// URL of an image of the item.
  core.String? imageLink;

  /// The list of destinations to include for this target (corresponds to
  /// checked check boxes in Merchant Center).
  ///
  /// Default destinations are always included unless provided in
  /// `excludedDestinations`.
  core.List<core.String>? includedDestinations;

  /// Number and amount of installments to pay for an item.
  Installment? installment;

  /// Whether the item is a merchant-defined bundle.
  ///
  /// A bundle is a custom grouping of different products sold by a merchant for
  /// a single price.
  core.bool? isBundle;

  /// Shared identifier for all variants of the same product.
  core.String? itemGroupId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#product`"
  core.String? kind;

  /// URL directly linking to your item's page on your website.
  core.String? link;

  /// Loyalty points that users receive after purchasing the item.
  ///
  /// Japan only.
  LoyaltyPoints? loyaltyPoints;

  /// The material of which the item is made.
  core.String? material;

  /// The energy efficiency class as defined in EU directive 2010/30/EU.
  core.String? maxEnergyEfficiencyClass;

  /// Maximal product handling time (in business days).
  core.String? maxHandlingTime;

  /// The energy efficiency class as defined in EU directive 2010/30/EU.
  core.String? minEnergyEfficiencyClass;

  /// Minimal product handling time (in business days).
  core.String? minHandlingTime;

  /// URL for the mobile-optimized version of your item's landing page.
  core.String? mobileLink;

  /// Manufacturer Part Number (MPN) of the item.
  core.String? mpn;

  /// The number of identical products in a merchant-defined multipack.
  core.String? multipack;

  /// A unique identifier for the item.
  ///
  /// Leading and trailing whitespaces are stripped and multiple whitespaces are
  /// replaced by a single whitespace upon submission. Only valid unicode
  /// characters are accepted. See the products feed specification for details.
  /// *Note:* Content API methods that operate on products take the REST ID of
  /// the product, *not* this identifier.
  ///
  /// Required.
  core.String? offerId;

  /// The item's pattern (e.g. polka dots).
  core.String? pattern;

  /// Price of the item.
  Price? price;

  /// Technical specification or additional product details.
  core.List<ProductProductDetail>? productDetails;

  /// Bullet points describing the most relevant highlights of a product.
  core.List<core.String>? productHighlights;

  /// Categories of the item (formatted as in products data specification).
  core.List<core.String>? productTypes;

  /// The unique ID of a promotion.
  core.List<core.String>? promotionIds;

  /// Advertised sale price of the item.
  Price? salePrice;

  /// Date range during which the item is on sale (see products data
  /// specification ).
  core.String? salePriceEffectiveDate;

  /// The quantity of the product that is available for selling on Google.
  ///
  /// Supported only for online products.
  core.String? sellOnGoogleQuantity;

  /// Shipping rules.
  core.List<ProductShipping>? shipping;

  /// Height of the item for shipping.
  ProductShippingDimension? shippingHeight;

  /// The shipping label of the product, used to group product in account-level
  /// shipping rules.
  core.String? shippingLabel;

  /// Length of the item for shipping.
  ProductShippingDimension? shippingLength;

  /// Weight of the item for shipping.
  ProductShippingWeight? shippingWeight;

  /// Width of the item for shipping.
  ProductShippingDimension? shippingWidth;

  /// List of country codes (ISO 3166-1 alpha-2) to exclude the offer from
  /// Shopping Ads destination.
  ///
  /// Countries from this list are removed from countries configured in MC feed
  /// settings.
  core.List<core.String>? shoppingAdsExcludedCountries;

  /// System in which the size is specified.
  ///
  /// Recommended for apparel items.
  core.String? sizeSystem;

  /// The cut of the item.
  ///
  /// Recommended for apparel items.
  core.String? sizeType;

  /// Size of the item.
  ///
  /// Only one value is allowed. For variants with different sizes, insert a
  /// separate product for each size with the same `itemGroupId` value (see size
  /// definition).
  core.List<core.String>? sizes;

  /// The source of the offer, i.e., how the offer was created.
  ///
  /// Acceptable values are: - "`api`" - "`crawl`" - "`feed`"
  core.String? source;

  /// Number of periods (months or years) and amount of payment per period for
  /// an item with an associated subscription contract.
  ProductSubscriptionCost? subscriptionCost;

  /// The CLDR territory code for the item.
  ///
  /// Required.
  core.String? targetCountry;

  /// The tax category of the product, used to configure detailed tax nexus in
  /// account-level tax settings.
  core.String? taxCategory;

  /// Tax information.
  core.List<ProductTax>? taxes;

  /// Title of the item.
  core.String? title;

  /// The transit time label of the product, used to group product in
  /// account-level transit time tables.
  core.String? transitTimeLabel;

  /// The preference of the denominator of the unit price.
  ProductUnitPricingBaseMeasure? unitPricingBaseMeasure;

  /// The measure and dimension of an item.
  ProductUnitPricingMeasure? unitPricingMeasure;

  Product();

  Product.fromJson(core.Map _json) {
    if (_json.containsKey('additionalImageLinks')) {
      additionalImageLinks = (_json['additionalImageLinks'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('additionalSizeType')) {
      additionalSizeType = _json['additionalSizeType'] as core.String;
    }
    if (_json.containsKey('adsGrouping')) {
      adsGrouping = _json['adsGrouping'] as core.String;
    }
    if (_json.containsKey('adsLabels')) {
      adsLabels = (_json['adsLabels'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('adsRedirect')) {
      adsRedirect = _json['adsRedirect'] as core.String;
    }
    if (_json.containsKey('adult')) {
      adult = _json['adult'] as core.bool;
    }
    if (_json.containsKey('ageGroup')) {
      ageGroup = _json['ageGroup'] as core.String;
    }
    if (_json.containsKey('availability')) {
      availability = _json['availability'] as core.String;
    }
    if (_json.containsKey('availabilityDate')) {
      availabilityDate = _json['availabilityDate'] as core.String;
    }
    if (_json.containsKey('brand')) {
      brand = _json['brand'] as core.String;
    }
    if (_json.containsKey('canonicalLink')) {
      canonicalLink = _json['canonicalLink'] as core.String;
    }
    if (_json.containsKey('channel')) {
      channel = _json['channel'] as core.String;
    }
    if (_json.containsKey('color')) {
      color = _json['color'] as core.String;
    }
    if (_json.containsKey('condition')) {
      condition = _json['condition'] as core.String;
    }
    if (_json.containsKey('contentLanguage')) {
      contentLanguage = _json['contentLanguage'] as core.String;
    }
    if (_json.containsKey('costOfGoodsSold')) {
      costOfGoodsSold = Price.fromJson(
          _json['costOfGoodsSold'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('customAttributes')) {
      customAttributes = (_json['customAttributes'] as core.List)
          .map<CustomAttribute>((value) => CustomAttribute.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('customLabel0')) {
      customLabel0 = _json['customLabel0'] as core.String;
    }
    if (_json.containsKey('customLabel1')) {
      customLabel1 = _json['customLabel1'] as core.String;
    }
    if (_json.containsKey('customLabel2')) {
      customLabel2 = _json['customLabel2'] as core.String;
    }
    if (_json.containsKey('customLabel3')) {
      customLabel3 = _json['customLabel3'] as core.String;
    }
    if (_json.containsKey('customLabel4')) {
      customLabel4 = _json['customLabel4'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayAdsId')) {
      displayAdsId = _json['displayAdsId'] as core.String;
    }
    if (_json.containsKey('displayAdsLink')) {
      displayAdsLink = _json['displayAdsLink'] as core.String;
    }
    if (_json.containsKey('displayAdsSimilarIds')) {
      displayAdsSimilarIds = (_json['displayAdsSimilarIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('displayAdsTitle')) {
      displayAdsTitle = _json['displayAdsTitle'] as core.String;
    }
    if (_json.containsKey('displayAdsValue')) {
      displayAdsValue = (_json['displayAdsValue'] as core.num).toDouble();
    }
    if (_json.containsKey('energyEfficiencyClass')) {
      energyEfficiencyClass = _json['energyEfficiencyClass'] as core.String;
    }
    if (_json.containsKey('excludedDestinations')) {
      excludedDestinations = (_json['excludedDestinations'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('expirationDate')) {
      expirationDate = _json['expirationDate'] as core.String;
    }
    if (_json.containsKey('gender')) {
      gender = _json['gender'] as core.String;
    }
    if (_json.containsKey('googleProductCategory')) {
      googleProductCategory = _json['googleProductCategory'] as core.String;
    }
    if (_json.containsKey('gtin')) {
      gtin = _json['gtin'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('identifierExists')) {
      identifierExists = _json['identifierExists'] as core.bool;
    }
    if (_json.containsKey('imageLink')) {
      imageLink = _json['imageLink'] as core.String;
    }
    if (_json.containsKey('includedDestinations')) {
      includedDestinations = (_json['includedDestinations'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('installment')) {
      installment = Installment.fromJson(
          _json['installment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('isBundle')) {
      isBundle = _json['isBundle'] as core.bool;
    }
    if (_json.containsKey('itemGroupId')) {
      itemGroupId = _json['itemGroupId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('link')) {
      link = _json['link'] as core.String;
    }
    if (_json.containsKey('loyaltyPoints')) {
      loyaltyPoints = LoyaltyPoints.fromJson(
          _json['loyaltyPoints'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('material')) {
      material = _json['material'] as core.String;
    }
    if (_json.containsKey('maxEnergyEfficiencyClass')) {
      maxEnergyEfficiencyClass =
          _json['maxEnergyEfficiencyClass'] as core.String;
    }
    if (_json.containsKey('maxHandlingTime')) {
      maxHandlingTime = _json['maxHandlingTime'] as core.String;
    }
    if (_json.containsKey('minEnergyEfficiencyClass')) {
      minEnergyEfficiencyClass =
          _json['minEnergyEfficiencyClass'] as core.String;
    }
    if (_json.containsKey('minHandlingTime')) {
      minHandlingTime = _json['minHandlingTime'] as core.String;
    }
    if (_json.containsKey('mobileLink')) {
      mobileLink = _json['mobileLink'] as core.String;
    }
    if (_json.containsKey('mpn')) {
      mpn = _json['mpn'] as core.String;
    }
    if (_json.containsKey('multipack')) {
      multipack = _json['multipack'] as core.String;
    }
    if (_json.containsKey('offerId')) {
      offerId = _json['offerId'] as core.String;
    }
    if (_json.containsKey('pattern')) {
      pattern = _json['pattern'] as core.String;
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('productDetails')) {
      productDetails = (_json['productDetails'] as core.List)
          .map<ProductProductDetail>((value) => ProductProductDetail.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('productHighlights')) {
      productHighlights = (_json['productHighlights'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('productTypes')) {
      productTypes = (_json['productTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('promotionIds')) {
      promotionIds = (_json['promotionIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('salePrice')) {
      salePrice = Price.fromJson(
          _json['salePrice'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('salePriceEffectiveDate')) {
      salePriceEffectiveDate = _json['salePriceEffectiveDate'] as core.String;
    }
    if (_json.containsKey('sellOnGoogleQuantity')) {
      sellOnGoogleQuantity = _json['sellOnGoogleQuantity'] as core.String;
    }
    if (_json.containsKey('shipping')) {
      shipping = (_json['shipping'] as core.List)
          .map<ProductShipping>((value) => ProductShipping.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shippingHeight')) {
      shippingHeight = ProductShippingDimension.fromJson(
          _json['shippingHeight'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shippingLabel')) {
      shippingLabel = _json['shippingLabel'] as core.String;
    }
    if (_json.containsKey('shippingLength')) {
      shippingLength = ProductShippingDimension.fromJson(
          _json['shippingLength'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shippingWeight')) {
      shippingWeight = ProductShippingWeight.fromJson(
          _json['shippingWeight'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shippingWidth')) {
      shippingWidth = ProductShippingDimension.fromJson(
          _json['shippingWidth'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shoppingAdsExcludedCountries')) {
      shoppingAdsExcludedCountries =
          (_json['shoppingAdsExcludedCountries'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('sizeSystem')) {
      sizeSystem = _json['sizeSystem'] as core.String;
    }
    if (_json.containsKey('sizeType')) {
      sizeType = _json['sizeType'] as core.String;
    }
    if (_json.containsKey('sizes')) {
      sizes = (_json['sizes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
    if (_json.containsKey('subscriptionCost')) {
      subscriptionCost = ProductSubscriptionCost.fromJson(
          _json['subscriptionCost'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('targetCountry')) {
      targetCountry = _json['targetCountry'] as core.String;
    }
    if (_json.containsKey('taxCategory')) {
      taxCategory = _json['taxCategory'] as core.String;
    }
    if (_json.containsKey('taxes')) {
      taxes = (_json['taxes'] as core.List)
          .map<ProductTax>((value) =>
              ProductTax.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('transitTimeLabel')) {
      transitTimeLabel = _json['transitTimeLabel'] as core.String;
    }
    if (_json.containsKey('unitPricingBaseMeasure')) {
      unitPricingBaseMeasure = ProductUnitPricingBaseMeasure.fromJson(
          _json['unitPricingBaseMeasure']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unitPricingMeasure')) {
      unitPricingMeasure = ProductUnitPricingMeasure.fromJson(
          _json['unitPricingMeasure'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalImageLinks != null)
          'additionalImageLinks': additionalImageLinks!,
        if (additionalSizeType != null)
          'additionalSizeType': additionalSizeType!,
        if (adsGrouping != null) 'adsGrouping': adsGrouping!,
        if (adsLabels != null) 'adsLabels': adsLabels!,
        if (adsRedirect != null) 'adsRedirect': adsRedirect!,
        if (adult != null) 'adult': adult!,
        if (ageGroup != null) 'ageGroup': ageGroup!,
        if (availability != null) 'availability': availability!,
        if (availabilityDate != null) 'availabilityDate': availabilityDate!,
        if (brand != null) 'brand': brand!,
        if (canonicalLink != null) 'canonicalLink': canonicalLink!,
        if (channel != null) 'channel': channel!,
        if (color != null) 'color': color!,
        if (condition != null) 'condition': condition!,
        if (contentLanguage != null) 'contentLanguage': contentLanguage!,
        if (costOfGoodsSold != null)
          'costOfGoodsSold': costOfGoodsSold!.toJson(),
        if (customAttributes != null)
          'customAttributes':
              customAttributes!.map((value) => value.toJson()).toList(),
        if (customLabel0 != null) 'customLabel0': customLabel0!,
        if (customLabel1 != null) 'customLabel1': customLabel1!,
        if (customLabel2 != null) 'customLabel2': customLabel2!,
        if (customLabel3 != null) 'customLabel3': customLabel3!,
        if (customLabel4 != null) 'customLabel4': customLabel4!,
        if (description != null) 'description': description!,
        if (displayAdsId != null) 'displayAdsId': displayAdsId!,
        if (displayAdsLink != null) 'displayAdsLink': displayAdsLink!,
        if (displayAdsSimilarIds != null)
          'displayAdsSimilarIds': displayAdsSimilarIds!,
        if (displayAdsTitle != null) 'displayAdsTitle': displayAdsTitle!,
        if (displayAdsValue != null) 'displayAdsValue': displayAdsValue!,
        if (energyEfficiencyClass != null)
          'energyEfficiencyClass': energyEfficiencyClass!,
        if (excludedDestinations != null)
          'excludedDestinations': excludedDestinations!,
        if (expirationDate != null) 'expirationDate': expirationDate!,
        if (gender != null) 'gender': gender!,
        if (googleProductCategory != null)
          'googleProductCategory': googleProductCategory!,
        if (gtin != null) 'gtin': gtin!,
        if (id != null) 'id': id!,
        if (identifierExists != null) 'identifierExists': identifierExists!,
        if (imageLink != null) 'imageLink': imageLink!,
        if (includedDestinations != null)
          'includedDestinations': includedDestinations!,
        if (installment != null) 'installment': installment!.toJson(),
        if (isBundle != null) 'isBundle': isBundle!,
        if (itemGroupId != null) 'itemGroupId': itemGroupId!,
        if (kind != null) 'kind': kind!,
        if (link != null) 'link': link!,
        if (loyaltyPoints != null) 'loyaltyPoints': loyaltyPoints!.toJson(),
        if (material != null) 'material': material!,
        if (maxEnergyEfficiencyClass != null)
          'maxEnergyEfficiencyClass': maxEnergyEfficiencyClass!,
        if (maxHandlingTime != null) 'maxHandlingTime': maxHandlingTime!,
        if (minEnergyEfficiencyClass != null)
          'minEnergyEfficiencyClass': minEnergyEfficiencyClass!,
        if (minHandlingTime != null) 'minHandlingTime': minHandlingTime!,
        if (mobileLink != null) 'mobileLink': mobileLink!,
        if (mpn != null) 'mpn': mpn!,
        if (multipack != null) 'multipack': multipack!,
        if (offerId != null) 'offerId': offerId!,
        if (pattern != null) 'pattern': pattern!,
        if (price != null) 'price': price!.toJson(),
        if (productDetails != null)
          'productDetails':
              productDetails!.map((value) => value.toJson()).toList(),
        if (productHighlights != null) 'productHighlights': productHighlights!,
        if (productTypes != null) 'productTypes': productTypes!,
        if (promotionIds != null) 'promotionIds': promotionIds!,
        if (salePrice != null) 'salePrice': salePrice!.toJson(),
        if (salePriceEffectiveDate != null)
          'salePriceEffectiveDate': salePriceEffectiveDate!,
        if (sellOnGoogleQuantity != null)
          'sellOnGoogleQuantity': sellOnGoogleQuantity!,
        if (shipping != null)
          'shipping': shipping!.map((value) => value.toJson()).toList(),
        if (shippingHeight != null) 'shippingHeight': shippingHeight!.toJson(),
        if (shippingLabel != null) 'shippingLabel': shippingLabel!,
        if (shippingLength != null) 'shippingLength': shippingLength!.toJson(),
        if (shippingWeight != null) 'shippingWeight': shippingWeight!.toJson(),
        if (shippingWidth != null) 'shippingWidth': shippingWidth!.toJson(),
        if (shoppingAdsExcludedCountries != null)
          'shoppingAdsExcludedCountries': shoppingAdsExcludedCountries!,
        if (sizeSystem != null) 'sizeSystem': sizeSystem!,
        if (sizeType != null) 'sizeType': sizeType!,
        if (sizes != null) 'sizes': sizes!,
        if (source != null) 'source': source!,
        if (subscriptionCost != null)
          'subscriptionCost': subscriptionCost!.toJson(),
        if (targetCountry != null) 'targetCountry': targetCountry!,
        if (taxCategory != null) 'taxCategory': taxCategory!,
        if (taxes != null)
          'taxes': taxes!.map((value) => value.toJson()).toList(),
        if (title != null) 'title': title!,
        if (transitTimeLabel != null) 'transitTimeLabel': transitTimeLabel!,
        if (unitPricingBaseMeasure != null)
          'unitPricingBaseMeasure': unitPricingBaseMeasure!.toJson(),
        if (unitPricingMeasure != null)
          'unitPricingMeasure': unitPricingMeasure!.toJson(),
      };
}

class ProductAmount {
  /// The pre-tax or post-tax price depending on the location of the order.
  Price? priceAmount;

  /// Remitted tax value.
  Price? remittedTaxAmount;

  /// Tax value.
  Price? taxAmount;

  ProductAmount();

  ProductAmount.fromJson(core.Map _json) {
    if (_json.containsKey('priceAmount')) {
      priceAmount = Price.fromJson(
          _json['priceAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('remittedTaxAmount')) {
      remittedTaxAmount = Price.fromJson(
          _json['remittedTaxAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('taxAmount')) {
      taxAmount = Price.fromJson(
          _json['taxAmount'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (priceAmount != null) 'priceAmount': priceAmount!.toJson(),
        if (remittedTaxAmount != null)
          'remittedTaxAmount': remittedTaxAmount!.toJson(),
        if (taxAmount != null) 'taxAmount': taxAmount!.toJson(),
      };
}

class ProductProductDetail {
  /// The name of the product detail.
  core.String? attributeName;

  /// The value of the product detail.
  core.String? attributeValue;

  /// The section header used to group a set of product details.
  core.String? sectionName;

  ProductProductDetail();

  ProductProductDetail.fromJson(core.Map _json) {
    if (_json.containsKey('attributeName')) {
      attributeName = _json['attributeName'] as core.String;
    }
    if (_json.containsKey('attributeValue')) {
      attributeValue = _json['attributeValue'] as core.String;
    }
    if (_json.containsKey('sectionName')) {
      sectionName = _json['sectionName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributeName != null) 'attributeName': attributeName!,
        if (attributeValue != null) 'attributeValue': attributeValue!,
        if (sectionName != null) 'sectionName': sectionName!,
      };
}

class ProductShipping {
  /// The CLDR territory code of the country to which an item will ship.
  core.String? country;

  /// The location where the shipping is applicable, represented by a location
  /// group name.
  core.String? locationGroupName;

  /// The numeric ID of a location that the shipping rate applies to as defined
  /// in the AdWords API.
  core.String? locationId;

  /// Maximum handling time (inclusive) between when the order is received and
  /// shipped in business days.
  ///
  /// 0 means that the order is shipped on the same day as it is received if it
  /// happens before the cut-off time. Both maxHandlingTime and maxTransitTime
  /// are required if providing shipping speeds.
  core.String? maxHandlingTime;

  /// Maximum transit time (inclusive) between when the order has shipped and
  /// when it is delivered in business days.
  ///
  /// 0 means that the order is delivered on the same day as it ships. Both
  /// maxHandlingTime and maxTransitTime are required if providing shipping
  /// speeds.
  core.String? maxTransitTime;

  /// Minimum handling time (inclusive) between when the order is received and
  /// shipped in business days.
  ///
  /// 0 means that the order is shipped on the same day as it is received if it
  /// happens before the cut-off time. minHandlingTime can only be present
  /// together with maxHandlingTime; but it is not required if maxHandlingTime
  /// is present.
  core.String? minHandlingTime;

  /// Minimum transit time (inclusive) between when the order has shipped and
  /// when it is delivered in business days.
  ///
  /// 0 means that the order is delivered on the same day as it ships.
  /// minTransitTime can only be present together with maxTransitTime; but it is
  /// not required if maxTransitTime is present.
  core.String? minTransitTime;

  /// The postal code range that the shipping rate applies to, represented by a
  /// postal code, a postal code prefix followed by a * wildcard, a range
  /// between two postal codes or two postal code prefixes of equal length.
  core.String? postalCode;

  /// Fixed shipping price, represented as a number.
  Price? price;

  /// The geographic region to which a shipping rate applies.
  core.String? region;

  /// A free-form description of the service class or delivery speed.
  core.String? service;

  ProductShipping();

  ProductShipping.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('locationGroupName')) {
      locationGroupName = _json['locationGroupName'] as core.String;
    }
    if (_json.containsKey('locationId')) {
      locationId = _json['locationId'] as core.String;
    }
    if (_json.containsKey('maxHandlingTime')) {
      maxHandlingTime = _json['maxHandlingTime'] as core.String;
    }
    if (_json.containsKey('maxTransitTime')) {
      maxTransitTime = _json['maxTransitTime'] as core.String;
    }
    if (_json.containsKey('minHandlingTime')) {
      minHandlingTime = _json['minHandlingTime'] as core.String;
    }
    if (_json.containsKey('minTransitTime')) {
      minTransitTime = _json['minTransitTime'] as core.String;
    }
    if (_json.containsKey('postalCode')) {
      postalCode = _json['postalCode'] as core.String;
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('service')) {
      service = _json['service'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (locationGroupName != null) 'locationGroupName': locationGroupName!,
        if (locationId != null) 'locationId': locationId!,
        if (maxHandlingTime != null) 'maxHandlingTime': maxHandlingTime!,
        if (maxTransitTime != null) 'maxTransitTime': maxTransitTime!,
        if (minHandlingTime != null) 'minHandlingTime': minHandlingTime!,
        if (minTransitTime != null) 'minTransitTime': minTransitTime!,
        if (postalCode != null) 'postalCode': postalCode!,
        if (price != null) 'price': price!.toJson(),
        if (region != null) 'region': region!,
        if (service != null) 'service': service!,
      };
}

class ProductShippingDimension {
  /// The unit of value.
  core.String? unit;

  /// The dimension of the product used to calculate the shipping cost of the
  /// item.
  core.double? value;

  ProductShippingDimension();

  ProductShippingDimension.fromJson(core.Map _json) {
    if (_json.containsKey('unit')) {
      unit = _json['unit'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = (_json['value'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (unit != null) 'unit': unit!,
        if (value != null) 'value': value!,
      };
}

class ProductShippingWeight {
  /// The unit of value.
  core.String? unit;

  /// The weight of the product used to calculate the shipping cost of the item.
  core.double? value;

  ProductShippingWeight();

  ProductShippingWeight.fromJson(core.Map _json) {
    if (_json.containsKey('unit')) {
      unit = _json['unit'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = (_json['value'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (unit != null) 'unit': unit!,
        if (value != null) 'value': value!,
      };
}

/// The status of a product, i.e., information about a product computed
/// asynchronously.
class ProductStatus {
  /// Date on which the item has been created, in ISO 8601 format.
  core.String? creationDate;

  /// The intended destinations for the product.
  core.List<ProductStatusDestinationStatus>? destinationStatuses;

  /// Date on which the item expires in Google Shopping, in ISO 8601 format.
  core.String? googleExpirationDate;

  /// A list of all issues associated with the product.
  core.List<ProductStatusItemLevelIssue>? itemLevelIssues;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#productStatus`"
  core.String? kind;

  /// Date on which the item has been last updated, in ISO 8601 format.
  core.String? lastUpdateDate;

  /// The link to the product.
  core.String? link;

  /// The ID of the product for which status is reported.
  core.String? productId;

  /// The title of the product.
  core.String? title;

  ProductStatus();

  ProductStatus.fromJson(core.Map _json) {
    if (_json.containsKey('creationDate')) {
      creationDate = _json['creationDate'] as core.String;
    }
    if (_json.containsKey('destinationStatuses')) {
      destinationStatuses = (_json['destinationStatuses'] as core.List)
          .map<ProductStatusDestinationStatus>((value) =>
              ProductStatusDestinationStatus.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('googleExpirationDate')) {
      googleExpirationDate = _json['googleExpirationDate'] as core.String;
    }
    if (_json.containsKey('itemLevelIssues')) {
      itemLevelIssues = (_json['itemLevelIssues'] as core.List)
          .map<ProductStatusItemLevelIssue>((value) =>
              ProductStatusItemLevelIssue.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastUpdateDate')) {
      lastUpdateDate = _json['lastUpdateDate'] as core.String;
    }
    if (_json.containsKey('link')) {
      link = _json['link'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creationDate != null) 'creationDate': creationDate!,
        if (destinationStatuses != null)
          'destinationStatuses':
              destinationStatuses!.map((value) => value.toJson()).toList(),
        if (googleExpirationDate != null)
          'googleExpirationDate': googleExpirationDate!,
        if (itemLevelIssues != null)
          'itemLevelIssues':
              itemLevelIssues!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (lastUpdateDate != null) 'lastUpdateDate': lastUpdateDate!,
        if (link != null) 'link': link!,
        if (productId != null) 'productId': productId!,
        if (title != null) 'title': title!,
      };
}

class ProductStatusDestinationStatus {
  /// List of country codes (ISO 3166-1 alpha-2) where the offer is approved.
  core.List<core.String>? approvedCountries;

  /// The name of the destination
  core.String? destination;

  /// List of country codes (ISO 3166-1 alpha-2) where the offer is disapproved.
  core.List<core.String>? disapprovedCountries;

  /// List of country codes (ISO 3166-1 alpha-2) where the offer is pending
  /// approval.
  core.List<core.String>? pendingCountries;

  /// Destination approval status in `targetCountry` of the offer.
  core.String? status;

  ProductStatusDestinationStatus();

  ProductStatusDestinationStatus.fromJson(core.Map _json) {
    if (_json.containsKey('approvedCountries')) {
      approvedCountries = (_json['approvedCountries'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('destination')) {
      destination = _json['destination'] as core.String;
    }
    if (_json.containsKey('disapprovedCountries')) {
      disapprovedCountries = (_json['disapprovedCountries'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('pendingCountries')) {
      pendingCountries = (_json['pendingCountries'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (approvedCountries != null) 'approvedCountries': approvedCountries!,
        if (destination != null) 'destination': destination!,
        if (disapprovedCountries != null)
          'disapprovedCountries': disapprovedCountries!,
        if (pendingCountries != null) 'pendingCountries': pendingCountries!,
        if (status != null) 'status': status!,
      };
}

class ProductStatusItemLevelIssue {
  /// List of country codes (ISO 3166-1 alpha-2) where issue applies to the
  /// offer.
  core.List<core.String>? applicableCountries;

  /// The attribute's name, if the issue is caused by a single attribute.
  core.String? attributeName;

  /// The error code of the issue.
  core.String? code;

  /// A short issue description in English.
  core.String? description;

  /// The destination the issue applies to.
  core.String? destination;

  /// A detailed issue description in English.
  core.String? detail;

  /// The URL of a web page to help with resolving this issue.
  core.String? documentation;

  /// Whether the issue can be resolved by the merchant.
  core.String? resolution;

  /// How this issue affects serving of the offer.
  core.String? servability;

  ProductStatusItemLevelIssue();

  ProductStatusItemLevelIssue.fromJson(core.Map _json) {
    if (_json.containsKey('applicableCountries')) {
      applicableCountries = (_json['applicableCountries'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('attributeName')) {
      attributeName = _json['attributeName'] as core.String;
    }
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('destination')) {
      destination = _json['destination'] as core.String;
    }
    if (_json.containsKey('detail')) {
      detail = _json['detail'] as core.String;
    }
    if (_json.containsKey('documentation')) {
      documentation = _json['documentation'] as core.String;
    }
    if (_json.containsKey('resolution')) {
      resolution = _json['resolution'] as core.String;
    }
    if (_json.containsKey('servability')) {
      servability = _json['servability'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applicableCountries != null)
          'applicableCountries': applicableCountries!,
        if (attributeName != null) 'attributeName': attributeName!,
        if (code != null) 'code': code!,
        if (description != null) 'description': description!,
        if (destination != null) 'destination': destination!,
        if (detail != null) 'detail': detail!,
        if (documentation != null) 'documentation': documentation!,
        if (resolution != null) 'resolution': resolution!,
        if (servability != null) 'servability': servability!,
      };
}

class ProductSubscriptionCost {
  /// The amount the buyer has to pay per subscription period.
  Price? amount;

  /// The type of subscription period.
  core.String? period;

  /// The number of subscription periods the buyer has to pay.
  core.String? periodLength;

  ProductSubscriptionCost();

  ProductSubscriptionCost.fromJson(core.Map _json) {
    if (_json.containsKey('amount')) {
      amount = Price.fromJson(
          _json['amount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('period')) {
      period = _json['period'] as core.String;
    }
    if (_json.containsKey('periodLength')) {
      periodLength = _json['periodLength'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (amount != null) 'amount': amount!.toJson(),
        if (period != null) 'period': period!,
        if (periodLength != null) 'periodLength': periodLength!,
      };
}

class ProductTax {
  /// The country within which the item is taxed, specified as a CLDR territory
  /// code.
  core.String? country;

  /// The numeric ID of a location that the tax rate applies to as defined in
  /// the AdWords API.
  core.String? locationId;

  /// The postal code range that the tax rate applies to, represented by a ZIP
  /// code, a ZIP code prefix using * wildcard, a range between two ZIP codes or
  /// two ZIP code prefixes of equal length.
  ///
  /// Examples: 94114, 94*, 94002-95460, 94*-95*.
  core.String? postalCode;

  /// The percentage of tax rate that applies to the item price.
  core.double? rate;

  /// The geographic region to which the tax rate applies.
  core.String? region;

  /// Should be set to true if tax is charged on shipping.
  core.bool? taxShip;

  ProductTax();

  ProductTax.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('locationId')) {
      locationId = _json['locationId'] as core.String;
    }
    if (_json.containsKey('postalCode')) {
      postalCode = _json['postalCode'] as core.String;
    }
    if (_json.containsKey('rate')) {
      rate = (_json['rate'] as core.num).toDouble();
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('taxShip')) {
      taxShip = _json['taxShip'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (locationId != null) 'locationId': locationId!,
        if (postalCode != null) 'postalCode': postalCode!,
        if (rate != null) 'rate': rate!,
        if (region != null) 'region': region!,
        if (taxShip != null) 'taxShip': taxShip!,
      };
}

class ProductUnitPricingBaseMeasure {
  /// The unit of the denominator.
  core.String? unit;

  /// The denominator of the unit price.
  core.String? value;

  ProductUnitPricingBaseMeasure();

  ProductUnitPricingBaseMeasure.fromJson(core.Map _json) {
    if (_json.containsKey('unit')) {
      unit = _json['unit'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (unit != null) 'unit': unit!,
        if (value != null) 'value': value!,
      };
}

class ProductUnitPricingMeasure {
  /// The unit of the measure.
  core.String? unit;

  /// The measure of an item.
  core.double? value;

  ProductUnitPricingMeasure();

  ProductUnitPricingMeasure.fromJson(core.Map _json) {
    if (_json.containsKey('unit')) {
      unit = _json['unit'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = (_json['value'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (unit != null) 'unit': unit!,
        if (value != null) 'value': value!,
      };
}

class ProductsCustomBatchRequest {
  /// The request entries to be processed in the batch.
  core.List<ProductsCustomBatchRequestEntry>? entries;

  ProductsCustomBatchRequest();

  ProductsCustomBatchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<ProductsCustomBatchRequestEntry>((value) =>
              ProductsCustomBatchRequestEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

/// A batch entry encoding a single non-batch products request.
class ProductsCustomBatchRequestEntry {
  /// An entry ID, unique within the batch request.
  core.int? batchId;

  /// The Content API feed id.
  core.String? feedId;

  /// The ID of the managing account.
  core.String? merchantId;

  /// The method of the batch entry.
  ///
  /// Acceptable values are: - "`delete`" - "`get`" - "`insert`" - "`update`"
  core.String? method;

  /// The product to insert.
  ///
  /// Only required if the method is `insert`.
  Product? product;

  /// The ID of the product to get or delete.
  ///
  /// Only defined if the method is `get` or `delete`.
  core.String? productId;

  /// The list of product attributes to be updated.
  ///
  /// Attributes specified in the update mask without a value specified in the
  /// body will be deleted from the product. Only top-level product attributes
  /// can be updated. If not defined, product attributes with set values will be
  /// updated and other attributes will stay unchanged. Only defined if the
  /// method is `update`.
  core.String? updateMask;

  ProductsCustomBatchRequestEntry();

  ProductsCustomBatchRequestEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('feedId')) {
      feedId = _json['feedId'] as core.String;
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('product')) {
      product = Product.fromJson(
          _json['product'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('updateMask')) {
      updateMask = _json['updateMask'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (feedId != null) 'feedId': feedId!,
        if (merchantId != null) 'merchantId': merchantId!,
        if (method != null) 'method': method!,
        if (product != null) 'product': product!.toJson(),
        if (productId != null) 'productId': productId!,
        if (updateMask != null) 'updateMask': updateMask!,
      };
}

class ProductsCustomBatchResponse {
  /// The result of the execution of the batch requests.
  core.List<ProductsCustomBatchResponseEntry>? entries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#productsCustomBatchResponse".
  core.String? kind;

  ProductsCustomBatchResponse();

  ProductsCustomBatchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<ProductsCustomBatchResponseEntry>((value) =>
              ProductsCustomBatchResponseEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// A batch entry encoding a single non-batch products response.
class ProductsCustomBatchResponseEntry {
  /// The ID of the request entry this entry responds to.
  core.int? batchId;

  /// A list of errors defined if and only if the request failed.
  Errors? errors;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#productsCustomBatchResponseEntry`"
  core.String? kind;

  /// The inserted product.
  ///
  /// Only defined if the method is `insert` and if the request was successful.
  Product? product;

  ProductsCustomBatchResponseEntry();

  ProductsCustomBatchResponseEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('errors')) {
      errors = Errors.fromJson(
          _json['errors'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('product')) {
      product = Product.fromJson(
          _json['product'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (errors != null) 'errors': errors!.toJson(),
        if (kind != null) 'kind': kind!,
        if (product != null) 'product': product!.toJson(),
      };
}

class ProductsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#productsListResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of products.
  core.String? nextPageToken;
  core.List<Product>? resources;

  ProductsListResponse();

  ProductsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<Product>((value) =>
              Product.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

class ProductstatusesCustomBatchRequest {
  /// The request entries to be processed in the batch.
  core.List<ProductstatusesCustomBatchRequestEntry>? entries;

  ProductstatusesCustomBatchRequest();

  ProductstatusesCustomBatchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<ProductstatusesCustomBatchRequestEntry>((value) =>
              ProductstatusesCustomBatchRequestEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

/// A batch entry encoding a single non-batch productstatuses request.
class ProductstatusesCustomBatchRequestEntry {
  /// An entry ID, unique within the batch request.
  core.int? batchId;

  /// If set, only issues for the specified destinations are returned, otherwise
  /// only issues for the Shopping destination.
  core.List<core.String>? destinations;
  core.bool? includeAttributes;

  /// The ID of the managing account.
  core.String? merchantId;

  /// The method of the batch entry.
  ///
  /// Acceptable values are: - "`get`"
  core.String? method;

  /// The ID of the product whose status to get.
  core.String? productId;

  ProductstatusesCustomBatchRequestEntry();

  ProductstatusesCustomBatchRequestEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('destinations')) {
      destinations = (_json['destinations'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('includeAttributes')) {
      includeAttributes = _json['includeAttributes'] as core.bool;
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (destinations != null) 'destinations': destinations!,
        if (includeAttributes != null) 'includeAttributes': includeAttributes!,
        if (merchantId != null) 'merchantId': merchantId!,
        if (method != null) 'method': method!,
        if (productId != null) 'productId': productId!,
      };
}

class ProductstatusesCustomBatchResponse {
  /// The result of the execution of the batch requests.
  core.List<ProductstatusesCustomBatchResponseEntry>? entries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#productstatusesCustomBatchResponse".
  core.String? kind;

  ProductstatusesCustomBatchResponse();

  ProductstatusesCustomBatchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<ProductstatusesCustomBatchResponseEntry>((value) =>
              ProductstatusesCustomBatchResponseEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// A batch entry encoding a single non-batch productstatuses response.
class ProductstatusesCustomBatchResponseEntry {
  /// The ID of the request entry this entry responds to.
  core.int? batchId;

  /// A list of errors, if the request failed.
  Errors? errors;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "`content#productstatusesCustomBatchResponseEntry`"
  core.String? kind;

  /// The requested product status.
  ///
  /// Only defined if the request was successful.
  ProductStatus? productStatus;

  ProductstatusesCustomBatchResponseEntry();

  ProductstatusesCustomBatchResponseEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('errors')) {
      errors = Errors.fromJson(
          _json['errors'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('productStatus')) {
      productStatus = ProductStatus.fromJson(
          _json['productStatus'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (errors != null) 'errors': errors!.toJson(),
        if (kind != null) 'kind': kind!,
        if (productStatus != null) 'productStatus': productStatus!.toJson(),
      };
}

class ProductstatusesListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#productstatusesListResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of products statuses.
  core.String? nextPageToken;
  core.List<ProductStatus>? resources;

  ProductstatusesListResponse();

  ProductstatusesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<ProductStatus>((value) => ProductStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

/// Settings for Pub/Sub notifications, all methods require that the caller is a
/// direct user of the merchant center account.
class PubsubNotificationSettings {
  /// Cloud pub/sub topic to which notifications are sent (read-only).
  core.String? cloudTopicName;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#pubsubNotificationSettings`"
  core.String? kind;

  /// List of event types.
  ///
  /// Acceptable values are: - "`orderPendingShipment`"
  core.List<core.String>? registeredEvents;

  PubsubNotificationSettings();

  PubsubNotificationSettings.fromJson(core.Map _json) {
    if (_json.containsKey('cloudTopicName')) {
      cloudTopicName = _json['cloudTopicName'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('registeredEvents')) {
      registeredEvents = (_json['registeredEvents'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudTopicName != null) 'cloudTopicName': cloudTopicName!,
        if (kind != null) 'kind': kind!,
        if (registeredEvents != null) 'registeredEvents': registeredEvents!,
      };
}

class RateGroup {
  /// A list of shipping labels defining the products to which this rate group
  /// applies to.
  ///
  /// This is a disjunction: only one of the labels has to match for the rate
  /// group to apply. May only be empty for the last rate group of a service.
  /// Required.
  core.List<core.String>? applicableShippingLabels;

  /// A list of carrier rates that can be referred to by `mainTable` or
  /// `singleValue`.
  core.List<CarrierRate>? carrierRates;

  /// A table defining the rate group, when `singleValue` is not expressive
  /// enough.
  ///
  /// Can only be set if `singleValue` is not set.
  Table? mainTable;

  /// Name of the rate group.
  ///
  /// Optional. If set has to be unique within shipping service.
  core.String? name;

  /// The value of the rate group (e.g. flat rate $10).
  ///
  /// Can only be set if `mainTable` and `subtables` are not set.
  Value? singleValue;

  /// A list of subtables referred to by `mainTable`.
  ///
  /// Can only be set if `mainTable` is set.
  core.List<Table>? subtables;

  RateGroup();

  RateGroup.fromJson(core.Map _json) {
    if (_json.containsKey('applicableShippingLabels')) {
      applicableShippingLabels =
          (_json['applicableShippingLabels'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('carrierRates')) {
      carrierRates = (_json['carrierRates'] as core.List)
          .map<CarrierRate>((value) => CarrierRate.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('mainTable')) {
      mainTable = Table.fromJson(
          _json['mainTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('singleValue')) {
      singleValue = Value.fromJson(
          _json['singleValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subtables')) {
      subtables = (_json['subtables'] as core.List)
          .map<Table>((value) =>
              Table.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applicableShippingLabels != null)
          'applicableShippingLabels': applicableShippingLabels!,
        if (carrierRates != null)
          'carrierRates': carrierRates!.map((value) => value.toJson()).toList(),
        if (mainTable != null) 'mainTable': mainTable!.toJson(),
        if (name != null) 'name': name!,
        if (singleValue != null) 'singleValue': singleValue!.toJson(),
        if (subtables != null)
          'subtables': subtables!.map((value) => value.toJson()).toList(),
      };
}

class RefundReason {
  /// Description of the reason.
  core.String? description;

  /// Code of the refund reason.
  ///
  /// Acceptable values are: - "`adjustment`" - "`autoPostInternal`" -
  /// "`autoPostInvalidBillingAddress`" - "`autoPostNoInventory`" -
  /// "`autoPostPriceError`" - "`autoPostUndeliverableShippingAddress`" -
  /// "`couponAbuse`" - "`courtesyAdjustment`" - "`customerCanceled`" -
  /// "`customerDiscretionaryReturn`" - "`customerInitiatedMerchantCancel`" -
  /// "`customerSupportRequested`" - "`deliveredLateByCarrier`" -
  /// "`deliveredTooLate`" - "`expiredItem`" - "`failToPushOrderGoogleError`" -
  /// "`failToPushOrderMerchantError`" -
  /// "`failToPushOrderMerchantFulfillmentError`" -
  /// "`failToPushOrderToMerchant`" - "`failToPushOrderToMerchantOutOfStock`" -
  /// "`feeAdjustment`" - "`invalidCoupon`" - "`lateShipmentCredit`" -
  /// "`malformedShippingAddress`" - "`merchantDidNotShipOnTime`" -
  /// "`noInventory`" - "`orderTimeout`" - "`other`" - "`paymentAbuse`" -
  /// "`paymentDeclined`" - "`priceAdjustment`" - "`priceError`" -
  /// "`productArrivedDamaged`" - "`productNotAsDescribed`" -
  /// "`promoReallocation`" - "`qualityNotAsExpected`" - "`returnRefundAbuse`" -
  /// "`shippingCostAdjustment`" - "`shippingPriceError`" - "`taxAdjustment`" -
  /// "`taxError`" - "`undeliverableShippingAddress`" -
  /// "`unsupportedPoBoxAddress`" - "`wrongProductShipped`"
  core.String? reasonCode;

  RefundReason();

  RefundReason.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('reasonCode')) {
      reasonCode = _json['reasonCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (reasonCode != null) 'reasonCode': reasonCode!,
      };
}

/// Represents a geographic region that you can use as a target with both the
/// `RegionalInventory` and `ShippingSettings` services.
///
/// You can define regions as collections of either postal codes or, in some
/// countries, using predefined geotargets.
class Region {
  /// The display name of the region.
  core.String? displayName;

  /// A list of geotargets that defines the region area.
  RegionGeoTargetArea? geotargetArea;

  /// Merchant that owns the region.
  ///
  /// Output only. Immutable.
  core.String? merchantId;

  /// A list of postal codes that defines the region area.
  RegionPostalCodeArea? postalCodeArea;

  /// The ID uniquely identifying each region.
  ///
  /// Output only. Immutable.
  core.String? regionId;

  /// Indicates if the region is eligible to use in the Regional Inventory
  /// configuration.
  ///
  /// Output only.
  core.bool? regionalInventoryEligible;

  /// Indicates if the region is eligible to use in the Shipping Services
  /// configuration.
  ///
  /// Output only.
  core.bool? shippingEligible;

  Region();

  Region.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('geotargetArea')) {
      geotargetArea = RegionGeoTargetArea.fromJson(
          _json['geotargetArea'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('postalCodeArea')) {
      postalCodeArea = RegionPostalCodeArea.fromJson(
          _json['postalCodeArea'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('regionId')) {
      regionId = _json['regionId'] as core.String;
    }
    if (_json.containsKey('regionalInventoryEligible')) {
      regionalInventoryEligible =
          _json['regionalInventoryEligible'] as core.bool;
    }
    if (_json.containsKey('shippingEligible')) {
      shippingEligible = _json['shippingEligible'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (geotargetArea != null) 'geotargetArea': geotargetArea!.toJson(),
        if (merchantId != null) 'merchantId': merchantId!,
        if (postalCodeArea != null) 'postalCodeArea': postalCodeArea!.toJson(),
        if (regionId != null) 'regionId': regionId!,
        if (regionalInventoryEligible != null)
          'regionalInventoryEligible': regionalInventoryEligible!,
        if (shippingEligible != null) 'shippingEligible': shippingEligible!,
      };
}

/// A list of geotargets that defines the region area.
class RegionGeoTargetArea {
  /// A non-empty list of
  /// [location IDs](https://developers.google.com/adwords/api/docs/appendix/geotargeting).
  ///
  /// They must all be of the same location type (e.g., state).
  ///
  /// Required.
  core.List<core.String>? geotargetCriteriaIds;

  RegionGeoTargetArea();

  RegionGeoTargetArea.fromJson(core.Map _json) {
    if (_json.containsKey('geotargetCriteriaIds')) {
      geotargetCriteriaIds = (_json['geotargetCriteriaIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (geotargetCriteriaIds != null)
          'geotargetCriteriaIds': geotargetCriteriaIds!,
      };
}

/// A list of postal codes that defines the region area.
///
/// Note: All regions defined using postal codes are accessible via the
/// account's `ShippingSettings.postalCodeGroups` resource.
class RegionPostalCodeArea {
  /// A range of postal codes.
  ///
  /// Required.
  core.List<RegionPostalCodeAreaPostalCodeRange>? postalCodes;

  /// CLDR territory code or the country the postal code group applies to.
  ///
  /// Required.
  core.String? regionCode;

  RegionPostalCodeArea();

  RegionPostalCodeArea.fromJson(core.Map _json) {
    if (_json.containsKey('postalCodes')) {
      postalCodes = (_json['postalCodes'] as core.List)
          .map<RegionPostalCodeAreaPostalCodeRange>((value) =>
              RegionPostalCodeAreaPostalCodeRange.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('regionCode')) {
      regionCode = _json['regionCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (postalCodes != null)
          'postalCodes': postalCodes!.map((value) => value.toJson()).toList(),
        if (regionCode != null) 'regionCode': regionCode!,
      };
}

/// A range of postal codes that defines the region area.
class RegionPostalCodeAreaPostalCodeRange {
  /// A postal code or a pattern of the form prefix* denoting the inclusive
  /// lower bound of the range defining the area.
  ///
  /// Examples values: "94108", "9410*", "9*".
  ///
  /// Required.
  core.String? begin;

  /// A postal code or a pattern of the form prefix* denoting the inclusive
  /// upper bound of the range defining the area.
  ///
  /// It must have the same length as postalCodeRangeBegin: if
  /// postalCodeRangeBegin is a postal code then postalCodeRangeEnd must be a
  /// postal code too; if postalCodeRangeBegin is a pattern then
  /// postalCodeRangeEnd must be a pattern with the same prefix length.
  /// Optional: if not set, then the area is defined as being all the postal
  /// codes matching postalCodeRangeBegin.
  ///
  /// Optional.
  core.String? end;

  RegionPostalCodeAreaPostalCodeRange();

  RegionPostalCodeAreaPostalCodeRange.fromJson(core.Map _json) {
    if (_json.containsKey('begin')) {
      begin = _json['begin'] as core.String;
    }
    if (_json.containsKey('end')) {
      end = _json['end'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (begin != null) 'begin': begin!,
        if (end != null) 'end': end!,
      };
}

/// Regional inventory resource.
///
/// contains the regional name and all attributes which are overridden for the
/// specified region.
class RegionalInventory {
  /// The availability of the product.
  core.String? availability;

  /// A list of custom (merchant-provided) attributes.
  ///
  /// It can also be used for submitting any attribute of the feed specification
  /// in its generic form.
  core.List<CustomAttribute>? customAttributes;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#regionalInventory".
  core.String? kind;

  /// The price of the product.
  Price? price;

  /// The ID uniquely identifying each region.
  core.String? regionId;

  /// The sale price of the product.
  ///
  /// Mandatory if `sale_price_effective_date` is defined.
  Price? salePrice;

  /// A date range represented by a pair of ISO 8601 dates separated by a space,
  /// comma, or slash.
  ///
  /// Both dates might be specified as 'null' if undecided.
  core.String? salePriceEffectiveDate;

  RegionalInventory();

  RegionalInventory.fromJson(core.Map _json) {
    if (_json.containsKey('availability')) {
      availability = _json['availability'] as core.String;
    }
    if (_json.containsKey('customAttributes')) {
      customAttributes = (_json['customAttributes'] as core.List)
          .map<CustomAttribute>((value) => CustomAttribute.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('regionId')) {
      regionId = _json['regionId'] as core.String;
    }
    if (_json.containsKey('salePrice')) {
      salePrice = Price.fromJson(
          _json['salePrice'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('salePriceEffectiveDate')) {
      salePriceEffectiveDate = _json['salePriceEffectiveDate'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (availability != null) 'availability': availability!,
        if (customAttributes != null)
          'customAttributes':
              customAttributes!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (price != null) 'price': price!.toJson(),
        if (regionId != null) 'regionId': regionId!,
        if (salePrice != null) 'salePrice': salePrice!.toJson(),
        if (salePriceEffectiveDate != null)
          'salePriceEffectiveDate': salePriceEffectiveDate!,
      };
}

class RegionalinventoryCustomBatchRequest {
  /// The request entries to be processed in the batch.
  core.List<RegionalinventoryCustomBatchRequestEntry>? entries;

  RegionalinventoryCustomBatchRequest();

  RegionalinventoryCustomBatchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<RegionalinventoryCustomBatchRequestEntry>((value) =>
              RegionalinventoryCustomBatchRequestEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

/// A batch entry encoding a single non-batch regional inventory request.
class RegionalinventoryCustomBatchRequestEntry {
  /// An entry ID, unique within the batch request.
  core.int? batchId;

  /// The ID of the managing account.
  core.String? merchantId;

  /// Method of the batch request entry.
  ///
  /// Acceptable values are: - "`insert`"
  core.String? method;

  /// The ID of the product for which to update price and availability.
  core.String? productId;

  /// Price and availability of the product.
  RegionalInventory? regionalInventory;

  RegionalinventoryCustomBatchRequestEntry();

  RegionalinventoryCustomBatchRequestEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('regionalInventory')) {
      regionalInventory = RegionalInventory.fromJson(
          _json['regionalInventory'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (merchantId != null) 'merchantId': merchantId!,
        if (method != null) 'method': method!,
        if (productId != null) 'productId': productId!,
        if (regionalInventory != null)
          'regionalInventory': regionalInventory!.toJson(),
      };
}

class RegionalinventoryCustomBatchResponse {
  /// The result of the execution of the batch requests.
  core.List<RegionalinventoryCustomBatchResponseEntry>? entries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#regionalinventoryCustomBatchResponse".
  core.String? kind;

  RegionalinventoryCustomBatchResponse();

  RegionalinventoryCustomBatchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<RegionalinventoryCustomBatchResponseEntry>((value) =>
              RegionalinventoryCustomBatchResponseEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// A batch entry encoding a single non-batch regional inventory response.
class RegionalinventoryCustomBatchResponseEntry {
  /// The ID of the request entry this entry responds to.
  core.int? batchId;

  /// A list of errors defined if and only if the request failed.
  Errors? errors;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "content#regionalinventoryCustomBatchResponseEntry".
  core.String? kind;

  /// Price and availability of the product.
  RegionalInventory? regionalInventory;

  RegionalinventoryCustomBatchResponseEntry();

  RegionalinventoryCustomBatchResponseEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('errors')) {
      errors = Errors.fromJson(
          _json['errors'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('regionalInventory')) {
      regionalInventory = RegionalInventory.fromJson(
          _json['regionalInventory'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (errors != null) 'errors': errors!.toJson(),
        if (kind != null) 'kind': kind!,
        if (regionalInventory != null)
          'regionalInventory': regionalInventory!.toJson(),
      };
}

/// Result row returned from the search query.
class ReportRow {
  /// Metrics requested by the merchant in the query.
  ///
  /// Metric values are only set for metrics requested explicitly in the query.
  Metrics? metrics;

  /// Segmentation dimensions requested by the merchant in the query.
  ///
  /// Dimension values are only set for dimensions requested explicitly in the
  /// query.
  Segments? segments;

  ReportRow();

  ReportRow.fromJson(core.Map _json) {
    if (_json.containsKey('metrics')) {
      metrics = Metrics.fromJson(
          _json['metrics'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('segments')) {
      segments = Segments.fromJson(
          _json['segments'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (metrics != null) 'metrics': metrics!.toJson(),
        if (segments != null) 'segments': segments!.toJson(),
      };
}

/// Resource that represents a daily Repricing product report.
///
/// Each report contains stats for a single type of Repricing rule for a single
/// product on a given day. If there are multiple rules of the same type for the
/// product on that day, the report lists all the rules by rule ids, combines
/// the stats, and paginates the results by date. To retrieve the stats of a
/// particular rule, provide the rule_id in the request.
class RepricingProductReport {
  /// Total count of Repricer applications.
  ///
  /// This value captures how many times the rule of this type was applied to
  /// this product during this reporting period.
  core.String? applicationCount;

  /// Stats specific to buybox winning rules for product report (deprecated).
  RepricingProductReportBuyboxWinningProductStats? buyboxWinningProductStats;

  /// Date of the stats in this report.
  ///
  /// The report starts and ends according to the merchant's timezone.
  Date? date;

  /// Maximum displayed price after repriced during this reporting period.
  PriceAmount? highWatermark;

  /// List of all reasons the rule did not apply to the product during the
  /// specified reporting period.
  core.List<InapplicabilityDetails>? inapplicabilityDetails;

  /// Minimum displayed price after repriced during this reporting period.
  PriceAmount? lowWatermark;

  /// Total unit count of impacted products ordered while the rule was active on
  /// the date of the report.
  ///
  /// This count includes all orders that were started while the rule was
  /// active, even if the rule was no longer active when the order was
  /// completed.
  core.int? orderItemCount;

  /// Ids of the Repricing rule for this report.
  core.List<core.String>? ruleIds;

  /// Total GMV generated by impacted products while the rule was active on the
  /// date of the report.
  ///
  /// This value includes all orders that were started while the rule was
  /// active, even if the rule was no longer active when the order was
  /// completed.
  PriceAmount? totalGmv;

  /// Type of the rule.
  /// Possible string values are:
  /// - "REPRICING_RULE_TYPE_UNSPECIFIED" : Unused.
  /// - "TYPE_STATS_BASED" : Statistical measurement based rules among Google SA
  /// merchants. If this rule is chosen, repricer will adjust the offer price
  /// based on statistical metrics (currently only min is available) among other
  /// merchants who sell the same product. Details need to be provdided in the
  /// RuleDefinition.
  /// - "TYPE_COGS_BASED" : Cost of goods sale based rule. Repricer will adjust
  /// the offer price based on the offer's sale cost which is provided by the
  /// merchant.
  core.String? type;

  RepricingProductReport();

  RepricingProductReport.fromJson(core.Map _json) {
    if (_json.containsKey('applicationCount')) {
      applicationCount = _json['applicationCount'] as core.String;
    }
    if (_json.containsKey('buyboxWinningProductStats')) {
      buyboxWinningProductStats =
          RepricingProductReportBuyboxWinningProductStats.fromJson(
              _json['buyboxWinningProductStats']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('date')) {
      date =
          Date.fromJson(_json['date'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('highWatermark')) {
      highWatermark = PriceAmount.fromJson(
          _json['highWatermark'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('inapplicabilityDetails')) {
      inapplicabilityDetails = (_json['inapplicabilityDetails'] as core.List)
          .map<InapplicabilityDetails>((value) =>
              InapplicabilityDetails.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('lowWatermark')) {
      lowWatermark = PriceAmount.fromJson(
          _json['lowWatermark'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('orderItemCount')) {
      orderItemCount = _json['orderItemCount'] as core.int;
    }
    if (_json.containsKey('ruleIds')) {
      ruleIds = (_json['ruleIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('totalGmv')) {
      totalGmv = PriceAmount.fromJson(
          _json['totalGmv'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applicationCount != null) 'applicationCount': applicationCount!,
        if (buyboxWinningProductStats != null)
          'buyboxWinningProductStats': buyboxWinningProductStats!.toJson(),
        if (date != null) 'date': date!.toJson(),
        if (highWatermark != null) 'highWatermark': highWatermark!.toJson(),
        if (inapplicabilityDetails != null)
          'inapplicabilityDetails':
              inapplicabilityDetails!.map((value) => value.toJson()).toList(),
        if (lowWatermark != null) 'lowWatermark': lowWatermark!.toJson(),
        if (orderItemCount != null) 'orderItemCount': orderItemCount!,
        if (ruleIds != null) 'ruleIds': ruleIds!,
        if (totalGmv != null) 'totalGmv': totalGmv!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// Stats specific to buybox winning rules for product report.
class RepricingProductReportBuyboxWinningProductStats {
  /// Number of times this product won the buybox with these rules during this
  /// time period.
  core.int? buyboxWinsCount;

  RepricingProductReportBuyboxWinningProductStats();

  RepricingProductReportBuyboxWinningProductStats.fromJson(core.Map _json) {
    if (_json.containsKey('buyboxWinsCount')) {
      buyboxWinsCount = _json['buyboxWinsCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buyboxWinsCount != null) 'buyboxWinsCount': buyboxWinsCount!,
      };
}

/// Represents a repricing rule.
///
/// A repricing rule is used by shopping serving to adjust transactable offer
/// prices if conditions are met. Next ID: 24
class RepricingRule {
  /// The rule definition for TYPE_COGS_BASED.
  ///
  /// Required when the rule type is TYPE_COGS_BASED.
  RepricingRuleCostOfGoodsSaleRule? cogsBasedRule;

  /// [CLDR country code](http://www.unicode.org/repos/cldr/tags/latest/common/main/en.xml)
  /// (e.g. "US").
  ///
  /// Required. Immutable.
  core.String? countryCode;

  /// Time period when the rule should take effect.
  ///
  /// Required.
  RepricingRuleEffectiveTime? effectiveTimePeriod;

  /// Match criteria for the eligible offers.
  ///
  /// Required.
  RepricingRuleEligibleOfferMatcher? eligibleOfferMatcher;

  /// The two-letter ISO 639-1 language code associated with the repricing rule.
  ///
  /// Required. Immutable.
  core.String? languageCode;

  /// Merchant that owns the repricing rule.
  ///
  /// Output only. Immutable.
  core.String? merchantId;

  /// Represents whether a rule is paused.
  ///
  /// A paused rule will behave like a non-paused rule within CRUD operations,
  /// with the major difference that a paused rule will not be evaluated and
  /// will have no effect on offers.
  core.bool? paused;

  /// Restriction of the rule appliance.
  ///
  /// Required.
  RepricingRuleRestriction? restriction;

  /// The ID to uniquely identify each repricing rule.
  ///
  /// Output only. Immutable.
  core.String? ruleId;

  /// The rule definition for TYPE_STATS_BASED.
  ///
  /// Required when the rule type is TYPE_STATS_BASED.
  RepricingRuleStatsBasedRule? statsBasedRule;

  /// The title for the rule.
  core.String? title;

  /// The type of the rule.
  ///
  /// Required. Immutable.
  /// Possible string values are:
  /// - "REPRICING_RULE_TYPE_UNSPECIFIED" : Unused.
  /// - "TYPE_STATS_BASED" : Statistical measurement based rules among Google SA
  /// merchants. If this rule is chosen, repricer will adjust the offer price
  /// based on statistical metrics (currently only min is available) among other
  /// merchants who sell the same product. Details need to be provdided in the
  /// RuleDefinition.
  /// - "TYPE_COGS_BASED" : Cost of goods sale based rule. Repricer will adjust
  /// the offer price based on the offer's sale cost which is provided by the
  /// merchant.
  core.String? type;

  RepricingRule();

  RepricingRule.fromJson(core.Map _json) {
    if (_json.containsKey('cogsBasedRule')) {
      cogsBasedRule = RepricingRuleCostOfGoodsSaleRule.fromJson(
          _json['cogsBasedRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('countryCode')) {
      countryCode = _json['countryCode'] as core.String;
    }
    if (_json.containsKey('effectiveTimePeriod')) {
      effectiveTimePeriod = RepricingRuleEffectiveTime.fromJson(
          _json['effectiveTimePeriod'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('eligibleOfferMatcher')) {
      eligibleOfferMatcher = RepricingRuleEligibleOfferMatcher.fromJson(
          _json['eligibleOfferMatcher'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('paused')) {
      paused = _json['paused'] as core.bool;
    }
    if (_json.containsKey('restriction')) {
      restriction = RepricingRuleRestriction.fromJson(
          _json['restriction'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ruleId')) {
      ruleId = _json['ruleId'] as core.String;
    }
    if (_json.containsKey('statsBasedRule')) {
      statsBasedRule = RepricingRuleStatsBasedRule.fromJson(
          _json['statsBasedRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cogsBasedRule != null) 'cogsBasedRule': cogsBasedRule!.toJson(),
        if (countryCode != null) 'countryCode': countryCode!,
        if (effectiveTimePeriod != null)
          'effectiveTimePeriod': effectiveTimePeriod!.toJson(),
        if (eligibleOfferMatcher != null)
          'eligibleOfferMatcher': eligibleOfferMatcher!.toJson(),
        if (languageCode != null) 'languageCode': languageCode!,
        if (merchantId != null) 'merchantId': merchantId!,
        if (paused != null) 'paused': paused!,
        if (restriction != null) 'restriction': restriction!.toJson(),
        if (ruleId != null) 'ruleId': ruleId!,
        if (statsBasedRule != null) 'statsBasedRule': statsBasedRule!.toJson(),
        if (title != null) 'title': title!,
        if (type != null) 'type': type!,
      };
}

/// A repricing rule that changes the sale price based on cost of goods sale.
class RepricingRuleCostOfGoodsSaleRule {
  /// The percent change against the COGS.
  ///
  /// Ex: 20 would mean to set the adjusted price 1.2X of the COGS data.
  core.int? percentageDelta;

  /// The price delta against the COGS.
  ///
  /// E.g. 2 means $2 more of the COGS.
  core.String? priceDelta;

  RepricingRuleCostOfGoodsSaleRule();

  RepricingRuleCostOfGoodsSaleRule.fromJson(core.Map _json) {
    if (_json.containsKey('percentageDelta')) {
      percentageDelta = _json['percentageDelta'] as core.int;
    }
    if (_json.containsKey('priceDelta')) {
      priceDelta = _json['priceDelta'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (percentageDelta != null) 'percentageDelta': percentageDelta!,
        if (priceDelta != null) 'priceDelta': priceDelta!,
      };
}

class RepricingRuleEffectiveTime {
  /// A list of fixed time periods combined with OR.
  ///
  /// The maximum number of entries is limited to 5.
  core.List<RepricingRuleEffectiveTimeFixedTimePeriod>? fixedTimePeriods;

  RepricingRuleEffectiveTime();

  RepricingRuleEffectiveTime.fromJson(core.Map _json) {
    if (_json.containsKey('fixedTimePeriods')) {
      fixedTimePeriods = (_json['fixedTimePeriods'] as core.List)
          .map<RepricingRuleEffectiveTimeFixedTimePeriod>((value) =>
              RepricingRuleEffectiveTimeFixedTimePeriod.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fixedTimePeriods != null)
          'fixedTimePeriods':
              fixedTimePeriods!.map((value) => value.toJson()).toList(),
      };
}

/// Definition of a fixed time period.
class RepricingRuleEffectiveTimeFixedTimePeriod {
  /// The end time (exclusive) of the period.
  ///
  /// It can only be hour granularity.
  core.String? endTime;

  /// The start time (inclusive) of the period.
  ///
  /// It can only be hour granularity.
  core.String? startTime;

  RepricingRuleEffectiveTimeFixedTimePeriod();

  RepricingRuleEffectiveTimeFixedTimePeriod.fromJson(core.Map _json) {
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

/// Matcher that specifies eligible offers.
///
/// When the USE_FEED_ATTRIBUTE option is selected, only the repricing_rule_id
/// attribute on the product feed is used to specify offer-rule mapping. When
/// the CUSTOM_FILTER option is selected, only the *_matcher fields are used to
/// filter the offers for offer-rule mapping. If the CUSTOM_FILTER option is
/// selected, an offer needs to satisfy each custom filter matcher to be
/// eligible for a rule. Size limit: the sum of the number of entries in all the
/// matchers should not exceed 20. For example, there can be 15 product ids and
/// 5 brands, but not 10 product ids and 11 brands.
class RepricingRuleEligibleOfferMatcher {
  /// Filter by the brand.
  RepricingRuleEligibleOfferMatcherStringMatcher? brandMatcher;

  /// Filter by the item group id.
  RepricingRuleEligibleOfferMatcherStringMatcher? itemGroupIdMatcher;

  /// Determines whether to use the custom matchers or the product feed
  /// attribute "repricing_rule_id" to specify offer-rule mapping.
  /// Possible string values are:
  /// - "MATCHER_OPTION_UNSPECIFIED" : Unused.
  /// - "MATCHER_OPTION_CUSTOM_FILTER" : Use custom filters.
  /// - "MATCHER_OPTION_USE_FEED_ATTRIBUTE" : Use repricing_rule_id feed
  /// attribute on the product resource to specify offer-rule mapping.
  /// - "MATCHER_OPTION_ALL_PRODUCTS" : Matching all products.
  core.String? matcherOption;

  /// Filter by the offer id.
  RepricingRuleEligibleOfferMatcherStringMatcher? offerIdMatcher;

  /// When true, the rule won't be applied to offers with active promotions.
  core.bool? skipWhenOnPromotion;

  RepricingRuleEligibleOfferMatcher();

  RepricingRuleEligibleOfferMatcher.fromJson(core.Map _json) {
    if (_json.containsKey('brandMatcher')) {
      brandMatcher = RepricingRuleEligibleOfferMatcherStringMatcher.fromJson(
          _json['brandMatcher'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('itemGroupIdMatcher')) {
      itemGroupIdMatcher =
          RepricingRuleEligibleOfferMatcherStringMatcher.fromJson(
              _json['itemGroupIdMatcher']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('matcherOption')) {
      matcherOption = _json['matcherOption'] as core.String;
    }
    if (_json.containsKey('offerIdMatcher')) {
      offerIdMatcher = RepricingRuleEligibleOfferMatcherStringMatcher.fromJson(
          _json['offerIdMatcher'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('skipWhenOnPromotion')) {
      skipWhenOnPromotion = _json['skipWhenOnPromotion'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (brandMatcher != null) 'brandMatcher': brandMatcher!.toJson(),
        if (itemGroupIdMatcher != null)
          'itemGroupIdMatcher': itemGroupIdMatcher!.toJson(),
        if (matcherOption != null) 'matcherOption': matcherOption!,
        if (offerIdMatcher != null) 'offerIdMatcher': offerIdMatcher!.toJson(),
        if (skipWhenOnPromotion != null)
          'skipWhenOnPromotion': skipWhenOnPromotion!,
      };
}

/// Matcher by string attributes.
class RepricingRuleEligibleOfferMatcherStringMatcher {
  /// String attributes, as long as such attribute of an offer is one of the
  /// string attribute values, the offer is considered as passing the matcher.
  ///
  /// The string matcher checks an offer for inclusivity in the string
  /// attributes, not equality. Only literal string matching is supported, no
  /// regex.
  core.List<core.String>? strAttributes;

  RepricingRuleEligibleOfferMatcherStringMatcher();

  RepricingRuleEligibleOfferMatcherStringMatcher.fromJson(core.Map _json) {
    if (_json.containsKey('strAttributes')) {
      strAttributes = (_json['strAttributes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (strAttributes != null) 'strAttributes': strAttributes!,
      };
}

/// Resource that represents a daily Repricing rule report.
///
/// Next ID: 11
class RepricingRuleReport {
  /// Stats specific to buybox winning rules for rule report (deprecated).
  RepricingRuleReportBuyboxWinningRuleStats? buyboxWinningRuleStats;

  /// Date of the stats in this report.
  ///
  /// The report starts and ends according to the merchant's timezone.
  Date? date;

  /// List of product ids that are impacted by this rule during this reporting
  /// period.
  ///
  /// Out of stock products and products not searched for by customers are
  /// examples of non-impacted products.
  core.List<core.String>? impactedProducts;

  /// List of all reasons the rule did not apply to the inapplicable products
  /// during the specified reporting period.
  core.List<InapplicabilityDetails>? inapplicabilityDetails;

  /// List of product ids that are inapplicable to this rule during this
  /// reporting period.
  ///
  /// To get the inapplicable reason for a specific product, see
  /// RepricingProductReport.
  core.List<core.String>? inapplicableProducts;

  /// Total unit count of impacted products ordered while the rule was active on
  /// the date of the report.
  ///
  /// This count includes all orders that were started while the rule was
  /// active, even if the rule was no longer active when the order was
  /// completed.
  core.int? orderItemCount;

  /// Id of the Repricing rule for this report.
  core.String? ruleId;

  /// Total GMV generated by impacted products while the rule was active on the
  /// date of the report.
  ///
  /// This value includes all orders that were started while the rule was
  /// active, even if the rule was no longer active when the order was
  /// completed.
  PriceAmount? totalGmv;

  /// Type of the rule.
  /// Possible string values are:
  /// - "REPRICING_RULE_TYPE_UNSPECIFIED" : Unused.
  /// - "TYPE_STATS_BASED" : Statistical measurement based rules among Google SA
  /// merchants. If this rule is chosen, repricer will adjust the offer price
  /// based on statistical metrics (currently only min is available) among other
  /// merchants who sell the same product. Details need to be provdided in the
  /// RuleDefinition.
  /// - "TYPE_COGS_BASED" : Cost of goods sale based rule. Repricer will adjust
  /// the offer price based on the offer's sale cost which is provided by the
  /// merchant.
  core.String? type;

  RepricingRuleReport();

  RepricingRuleReport.fromJson(core.Map _json) {
    if (_json.containsKey('buyboxWinningRuleStats')) {
      buyboxWinningRuleStats =
          RepricingRuleReportBuyboxWinningRuleStats.fromJson(
              _json['buyboxWinningRuleStats']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('date')) {
      date =
          Date.fromJson(_json['date'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('impactedProducts')) {
      impactedProducts = (_json['impactedProducts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('inapplicabilityDetails')) {
      inapplicabilityDetails = (_json['inapplicabilityDetails'] as core.List)
          .map<InapplicabilityDetails>((value) =>
              InapplicabilityDetails.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('inapplicableProducts')) {
      inapplicableProducts = (_json['inapplicableProducts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('orderItemCount')) {
      orderItemCount = _json['orderItemCount'] as core.int;
    }
    if (_json.containsKey('ruleId')) {
      ruleId = _json['ruleId'] as core.String;
    }
    if (_json.containsKey('totalGmv')) {
      totalGmv = PriceAmount.fromJson(
          _json['totalGmv'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buyboxWinningRuleStats != null)
          'buyboxWinningRuleStats': buyboxWinningRuleStats!.toJson(),
        if (date != null) 'date': date!.toJson(),
        if (impactedProducts != null) 'impactedProducts': impactedProducts!,
        if (inapplicabilityDetails != null)
          'inapplicabilityDetails':
              inapplicabilityDetails!.map((value) => value.toJson()).toList(),
        if (inapplicableProducts != null)
          'inapplicableProducts': inapplicableProducts!,
        if (orderItemCount != null) 'orderItemCount': orderItemCount!,
        if (ruleId != null) 'ruleId': ruleId!,
        if (totalGmv != null) 'totalGmv': totalGmv!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// Stats specific to buybox winning rules for rule report.
class RepricingRuleReportBuyboxWinningRuleStats {
  /// Number of unique products that won the buybox with this rule during this
  /// period of time.
  core.int? buyboxWonProductCount;

  RepricingRuleReportBuyboxWinningRuleStats();

  RepricingRuleReportBuyboxWinningRuleStats.fromJson(core.Map _json) {
    if (_json.containsKey('buyboxWonProductCount')) {
      buyboxWonProductCount = _json['buyboxWonProductCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buyboxWonProductCount != null)
          'buyboxWonProductCount': buyboxWonProductCount!,
      };
}

/// Definition of a rule restriction.
///
/// At least one of the following needs to be true: (1)
/// use_auto_pricing_min_price is true (2) floor.price_delta exists (3)
/// floor.percentage_delta exists If floor.price_delta and
/// floor.percentage_delta are both set on a rule, the highest value will be
/// chosen by the Repricer. In other words, for a product with a price of $50,
/// if the `floor.percentage_delta` is "-10" and the floor.price_delta is "-12",
/// the offer price will only be lowered $5 (10% lower than the original offer
/// price).
class RepricingRuleRestriction {
  /// The inclusive floor lower bound.
  ///
  /// The repricing rule only applies when new price >= floor.
  RepricingRuleRestrictionBoundary? floor;

  /// If true, use the AUTO_PRICING_MIN_PRICE offer attribute as the lower bound
  /// of the rule.
  ///
  /// If use_auto_pricing_min_price is true, then only offers with
  /// `AUTO_PRICING_MIN_PRICE` existing on the offer will get Repricer
  /// treatment, even if a floor value is set on the rule. Also, if
  /// use_auto_pricing_min_price is true, the floor restriction will be ignored.
  core.bool? useAutoPricingMinPrice;

  RepricingRuleRestriction();

  RepricingRuleRestriction.fromJson(core.Map _json) {
    if (_json.containsKey('floor')) {
      floor = RepricingRuleRestrictionBoundary.fromJson(
          _json['floor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('useAutoPricingMinPrice')) {
      useAutoPricingMinPrice = _json['useAutoPricingMinPrice'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (floor != null) 'floor': floor!.toJson(),
        if (useAutoPricingMinPrice != null)
          'useAutoPricingMinPrice': useAutoPricingMinPrice!,
      };
}

/// Definition of a boundary.
class RepricingRuleRestrictionBoundary {
  /// The percentage delta relative to the offer selling price.
  ///
  /// This field is signed. It must be negative in floor. When it is used in
  /// floor, it should be > -100. For example, if an offer is selling at $10 and
  /// this field is -30 in floor, the repricing rule only applies if the
  /// calculated new price is >= $7.
  core.int? percentageDelta;

  /// The price micros relative to the offer selling price.
  ///
  /// This field is signed. It must be negative in floor. For example, if an
  /// offer is selling at $10 and this field is -$2 in floor, the repricing rule
  /// only applies if the calculated new price is >= $8.
  core.String? priceDelta;

  RepricingRuleRestrictionBoundary();

  RepricingRuleRestrictionBoundary.fromJson(core.Map _json) {
    if (_json.containsKey('percentageDelta')) {
      percentageDelta = _json['percentageDelta'] as core.int;
    }
    if (_json.containsKey('priceDelta')) {
      priceDelta = _json['priceDelta'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (percentageDelta != null) 'percentageDelta': percentageDelta!,
        if (priceDelta != null) 'priceDelta': priceDelta!,
      };
}

/// Definition of stats based rule.
class RepricingRuleStatsBasedRule {
  /// The percent change against the price target.
  ///
  /// Valid from 0 to 100 inclusively.
  core.int? percentageDelta;

  /// The price delta against the above price target.
  ///
  /// A positive value means the price should be adjusted to be above
  /// statistical measure, and a negative value means below. Currency code must
  /// not be included.
  core.String? priceDelta;

  RepricingRuleStatsBasedRule();

  RepricingRuleStatsBasedRule.fromJson(core.Map _json) {
    if (_json.containsKey('percentageDelta')) {
      percentageDelta = _json['percentageDelta'] as core.int;
    }
    if (_json.containsKey('priceDelta')) {
      priceDelta = _json['priceDelta'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (percentageDelta != null) 'percentageDelta': percentageDelta!,
        if (priceDelta != null) 'priceDelta': priceDelta!,
      };
}

/// Request message for the RequestReviewProgram method.
class RequestReviewBuyOnGoogleProgramRequest {
  RequestReviewBuyOnGoogleProgramRequest();

  RequestReviewBuyOnGoogleProgramRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Return address resource.
class ReturnAddress {
  /// The address.
  ///
  /// Required.
  ReturnAddressAddress? address;

  /// The country of sale where the return address is applicable.
  ///
  /// Required.
  core.String? country;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#returnAddress`"
  core.String? kind;

  /// The user-defined label of the return address.
  ///
  /// For the default address, use the label "default".
  ///
  /// Required.
  core.String? label;

  /// The merchant's contact phone number regarding the return.
  ///
  /// Required.
  core.String? phoneNumber;

  /// Return address ID generated by Google.
  core.String? returnAddressId;

  ReturnAddress();

  ReturnAddress.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = ReturnAddressAddress.fromJson(
          _json['address'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('label')) {
      label = _json['label'] as core.String;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
    if (_json.containsKey('returnAddressId')) {
      returnAddressId = _json['returnAddressId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!.toJson(),
        if (country != null) 'country': country!,
        if (kind != null) 'kind': kind!,
        if (label != null) 'label': label!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
        if (returnAddressId != null) 'returnAddressId': returnAddressId!,
      };
}

class ReturnAddressAddress {
  /// CLDR country code (e.g. "US").
  core.String? country;

  /// City, town or commune.
  ///
  /// May also include dependent localities or sublocalities (e.g. neighborhoods
  /// or suburbs).
  core.String? locality;

  /// Postal code or ZIP (e.g. "94043").
  core.String? postalCode;

  /// Name of the recipient to address returns to.
  core.String? recipientName;

  /// Top-level administrative subdivision of the country.
  ///
  /// For example, a state like California ("CA") or a province like Quebec
  /// ("QC").
  core.String? region;

  /// Street-level part of the address.
  ///
  /// May be up to two lines, each line specified as an array element.
  core.List<core.String>? streetAddress;

  ReturnAddressAddress();

  ReturnAddressAddress.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('locality')) {
      locality = _json['locality'] as core.String;
    }
    if (_json.containsKey('postalCode')) {
      postalCode = _json['postalCode'] as core.String;
    }
    if (_json.containsKey('recipientName')) {
      recipientName = _json['recipientName'] as core.String;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('streetAddress')) {
      streetAddress = (_json['streetAddress'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (locality != null) 'locality': locality!,
        if (postalCode != null) 'postalCode': postalCode!,
        if (recipientName != null) 'recipientName': recipientName!,
        if (region != null) 'region': region!,
        if (streetAddress != null) 'streetAddress': streetAddress!,
      };
}

/// Return policy resource.
class ReturnPolicy {
  /// The country of sale where the return policy is applicable.
  ///
  /// Required.
  core.String? country;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#returnPolicy`"
  core.String? kind;

  /// The user-defined label of the return policy.
  ///
  /// For the default policy, use the label "default".
  ///
  /// Required.
  core.String? label;

  /// The name of the policy as shown in Merchant Center.
  ///
  /// Required.
  core.String? name;

  /// Return reasons that will incur return fees.
  core.List<core.String>? nonFreeReturnReasons;

  /// The policy.
  ///
  /// Required.
  ReturnPolicyPolicy? policy;

  /// Return policy ID generated by Google.
  core.String? returnPolicyId;

  /// The return shipping fee that will apply to non free return reasons.
  Price? returnShippingFee;

  /// An optional list of seasonal overrides.
  core.List<ReturnPolicySeasonalOverride>? seasonalOverrides;

  ReturnPolicy();

  ReturnPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('label')) {
      label = _json['label'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nonFreeReturnReasons')) {
      nonFreeReturnReasons = (_json['nonFreeReturnReasons'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('policy')) {
      policy = ReturnPolicyPolicy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('returnPolicyId')) {
      returnPolicyId = _json['returnPolicyId'] as core.String;
    }
    if (_json.containsKey('returnShippingFee')) {
      returnShippingFee = Price.fromJson(
          _json['returnShippingFee'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('seasonalOverrides')) {
      seasonalOverrides = (_json['seasonalOverrides'] as core.List)
          .map<ReturnPolicySeasonalOverride>((value) =>
              ReturnPolicySeasonalOverride.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (kind != null) 'kind': kind!,
        if (label != null) 'label': label!,
        if (name != null) 'name': name!,
        if (nonFreeReturnReasons != null)
          'nonFreeReturnReasons': nonFreeReturnReasons!,
        if (policy != null) 'policy': policy!.toJson(),
        if (returnPolicyId != null) 'returnPolicyId': returnPolicyId!,
        if (returnShippingFee != null)
          'returnShippingFee': returnShippingFee!.toJson(),
        if (seasonalOverrides != null)
          'seasonalOverrides':
              seasonalOverrides!.map((value) => value.toJson()).toList(),
      };
}

/// Return policy online object.
///
/// This is currently used to represent return policies for ads and free
/// listings programs.
class ReturnPolicyOnline {
  /// The countries of sale where the return policy is applicable.
  ///
  /// The values must be a valid 2 letter ISO 3166 code, e.g. "US".
  core.List<core.String>? countries;

  /// The item conditions that are accepted for returns.
  ///
  /// This is required to not be empty unless the type of return policy is
  /// noReturns.
  core.List<core.String>? itemConditions;

  /// The unique user-defined label of the return policy.
  ///
  /// The same label cannot be used in different return policies for the same
  /// country. Policies with the label 'default' will apply to all products,
  /// unless a product specifies a return_policy_label attribute.
  core.String? label;

  /// The name of the policy as shown in Merchant Center.
  core.String? name;

  /// The return policy.
  ReturnPolicyOnlinePolicy? policy;

  /// The restocking fee that applies to all return reason categories.
  ///
  /// This would be treated as a free restocking fee if the value is not set.
  ReturnPolicyOnlineRestockingFee? restockingFee;

  /// The return methods of how customers can return an item.
  ///
  /// This value is required to not be empty unless the type of return policy is
  /// noReturns.
  core.List<core.String>? returnMethods;

  /// Return policy ID generated by Google.
  ///
  /// Output only.
  core.String? returnPolicyId;

  /// The return policy uri.
  ///
  /// This can used by Google to do a sanity check for the policy.
  core.String? returnPolicyUri;

  /// The return reason category information.
  ///
  /// This required to not be empty unless the type of return policy is
  /// noReturns.
  core.List<ReturnPolicyOnlineReturnReasonCategoryInfo>?
      returnReasonCategoryInfo;

  ReturnPolicyOnline();

  ReturnPolicyOnline.fromJson(core.Map _json) {
    if (_json.containsKey('countries')) {
      countries = (_json['countries'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('itemConditions')) {
      itemConditions = (_json['itemConditions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('label')) {
      label = _json['label'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('policy')) {
      policy = ReturnPolicyOnlinePolicy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('restockingFee')) {
      restockingFee = ReturnPolicyOnlineRestockingFee.fromJson(
          _json['restockingFee'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('returnMethods')) {
      returnMethods = (_json['returnMethods'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('returnPolicyId')) {
      returnPolicyId = _json['returnPolicyId'] as core.String;
    }
    if (_json.containsKey('returnPolicyUri')) {
      returnPolicyUri = _json['returnPolicyUri'] as core.String;
    }
    if (_json.containsKey('returnReasonCategoryInfo')) {
      returnReasonCategoryInfo =
          (_json['returnReasonCategoryInfo'] as core.List)
              .map<ReturnPolicyOnlineReturnReasonCategoryInfo>((value) =>
                  ReturnPolicyOnlineReturnReasonCategoryInfo.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (countries != null) 'countries': countries!,
        if (itemConditions != null) 'itemConditions': itemConditions!,
        if (label != null) 'label': label!,
        if (name != null) 'name': name!,
        if (policy != null) 'policy': policy!.toJson(),
        if (restockingFee != null) 'restockingFee': restockingFee!.toJson(),
        if (returnMethods != null) 'returnMethods': returnMethods!,
        if (returnPolicyId != null) 'returnPolicyId': returnPolicyId!,
        if (returnPolicyUri != null) 'returnPolicyUri': returnPolicyUri!,
        if (returnReasonCategoryInfo != null)
          'returnReasonCategoryInfo':
              returnReasonCategoryInfo!.map((value) => value.toJson()).toList(),
      };
}

/// The available policies.
class ReturnPolicyOnlinePolicy {
  /// The number of days items can be returned after delivery, where one day is
  /// defined to be 24 hours after the delivery timestamp.
  ///
  /// Required for `numberOfDaysAfterDelivery` returns.
  core.String? days;

  /// Policy type.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Default value. This value is unused.
  /// - "NUMBER_OF_DAYS_AFTER_DELIVERY" : Number of days after a return is
  /// delivered.
  /// - "NO_RETURNS" : No returns.
  /// - "LIFETIME_RETURNS" : Life time returns.
  core.String? type;

  ReturnPolicyOnlinePolicy();

  ReturnPolicyOnlinePolicy.fromJson(core.Map _json) {
    if (_json.containsKey('days')) {
      days = _json['days'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (days != null) 'days': days!,
        if (type != null) 'type': type!,
      };
}

/// The restocking fee.
///
/// This can either be a fixed fee or a micro percent.
class ReturnPolicyOnlineRestockingFee {
  /// Fixed restocking fee.
  PriceAmount? fixedFee;

  /// Percent of total price in micros.
  ///
  /// 15,000,000 means 15% of the total price would be charged.
  core.int? microPercent;

  ReturnPolicyOnlineRestockingFee();

  ReturnPolicyOnlineRestockingFee.fromJson(core.Map _json) {
    if (_json.containsKey('fixedFee')) {
      fixedFee = PriceAmount.fromJson(
          _json['fixedFee'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('microPercent')) {
      microPercent = _json['microPercent'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fixedFee != null) 'fixedFee': fixedFee!.toJson(),
        if (microPercent != null) 'microPercent': microPercent!,
      };
}

/// The return reason category info wrapper.
class ReturnPolicyOnlineReturnReasonCategoryInfo {
  /// The corresponding return label source.
  /// Possible string values are:
  /// - "RETURN_LABEL_SOURCE_UNSPECIFIED" : Default value. This value is unused.
  /// - "DOWNLOAD_AND_PRINT" : Download and print the label.
  /// - "IN_THE_BOX" : Label in the box.
  /// - "CUSTOMER_RESPONSIBILITY" : Customers' responsibility to get the label.
  core.String? returnLabelSource;

  /// The return reason category.
  /// Possible string values are:
  /// - "RETURN_REASON_CATEGORY_UNSPECIFIED" : Default value. This value is
  /// unused.
  /// - "BUYER_REMORSE" : Buyer remorse.
  /// - "ITEM_DEFECT" : Item defect.
  core.String? returnReasonCategory;

  /// The corresponding return shipping fee.
  ///
  /// This is only applicable when returnLabelSource is not the customer's
  /// responsibility.
  ReturnPolicyOnlineReturnShippingFee? returnShippingFee;

  ReturnPolicyOnlineReturnReasonCategoryInfo();

  ReturnPolicyOnlineReturnReasonCategoryInfo.fromJson(core.Map _json) {
    if (_json.containsKey('returnLabelSource')) {
      returnLabelSource = _json['returnLabelSource'] as core.String;
    }
    if (_json.containsKey('returnReasonCategory')) {
      returnReasonCategory = _json['returnReasonCategory'] as core.String;
    }
    if (_json.containsKey('returnShippingFee')) {
      returnShippingFee = ReturnPolicyOnlineReturnShippingFee.fromJson(
          _json['returnShippingFee'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (returnLabelSource != null) 'returnLabelSource': returnLabelSource!,
        if (returnReasonCategory != null)
          'returnReasonCategory': returnReasonCategory!,
        if (returnShippingFee != null)
          'returnShippingFee': returnShippingFee!.toJson(),
      };
}

/// The return shipping fee.
///
/// This can either be a fixed fee or a boolean to indicate that the customer
/// pays the actual shipping cost.
class ReturnPolicyOnlineReturnShippingFee {
  /// Fixed return shipping fee amount.
  ///
  /// This value is only applicable when type is FIXED. We will treat the return
  /// shipping fee as free if type is FIXED and this value is not set.
  PriceAmount? fixedFee;

  /// Type of return shipping fee.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Default value. This value is unused.
  /// - "FIXED" : The return shipping fee is a fixed value.
  /// - "CUSTOMER_PAYING_ACTUAL_FEE" : Customer will pay the actual return
  /// shipping fee.
  core.String? type;

  ReturnPolicyOnlineReturnShippingFee();

  ReturnPolicyOnlineReturnShippingFee.fromJson(core.Map _json) {
    if (_json.containsKey('fixedFee')) {
      fixedFee = PriceAmount.fromJson(
          _json['fixedFee'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fixedFee != null) 'fixedFee': fixedFee!.toJson(),
        if (type != null) 'type': type!,
      };
}

class ReturnPolicyPolicy {
  /// Last day for returning the items.
  ///
  /// In ISO 8601 format. When specifying the return window like this, set the
  /// policy type to "lastReturnDate". Use this for seasonal overrides only.
  ///
  /// Required.
  core.String? lastReturnDate;

  /// The number of days items can be returned after delivery, where one day is
  /// defined to be 24 hours after the delivery timestamp.
  ///
  /// When specifying the return window like this, set the policy type to
  /// "numberOfDaysAfterDelivery". Acceptable values are 30, 45, 60, 90, 100,
  /// 180, 270 and 365 for the default policy. Additional policies further allow
  /// 14, 15, 21 and 28 days, but note that for most items a minimum of 30 days
  /// is required for returns. Exceptions may be made for electronics. A policy
  /// of less than 30 days can only be applied to those items.
  core.String? numberOfDays;

  /// Policy type.
  ///
  /// Use "lastReturnDate" for seasonal overrides only. Note that for most items
  /// a minimum of 30 days is required for returns. Exceptions may be made for
  /// electronics or non-returnable items such as food, perishables, and living
  /// things. A policy of less than 30 days can only be applied to those items.
  /// Acceptable values are: - "`lastReturnDate`" - "`lifetimeReturns`" -
  /// "`noReturns`" - "`numberOfDaysAfterDelivery`"
  core.String? type;

  ReturnPolicyPolicy();

  ReturnPolicyPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('lastReturnDate')) {
      lastReturnDate = _json['lastReturnDate'] as core.String;
    }
    if (_json.containsKey('numberOfDays')) {
      numberOfDays = _json['numberOfDays'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lastReturnDate != null) 'lastReturnDate': lastReturnDate!,
        if (numberOfDays != null) 'numberOfDays': numberOfDays!,
        if (type != null) 'type': type!,
      };
}

class ReturnPolicySeasonalOverride {
  /// Last day on which the override applies.
  ///
  /// In ISO 8601 format.
  ///
  /// Required.
  core.String? endDate;

  /// The name of the seasonal override as shown in Merchant Center.
  ///
  /// Required.
  core.String? name;

  /// The policy which is in effect during that time.
  ///
  /// Required.
  ReturnPolicyPolicy? policy;

  /// First day on which the override applies.
  ///
  /// In ISO 8601 format.
  ///
  /// Required.
  core.String? startDate;

  ReturnPolicySeasonalOverride();

  ReturnPolicySeasonalOverride.fromJson(core.Map _json) {
    if (_json.containsKey('endDate')) {
      endDate = _json['endDate'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('policy')) {
      policy = ReturnPolicyPolicy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startDate')) {
      startDate = _json['startDate'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endDate != null) 'endDate': endDate!,
        if (name != null) 'name': name!,
        if (policy != null) 'policy': policy!.toJson(),
        if (startDate != null) 'startDate': startDate!,
      };
}

class ReturnPricingInfo {
  /// Default option for whether merchant should charge the customer for return
  /// shipping costs, based on customer selected return reason and merchant's
  /// return policy for the items being returned.
  core.bool? chargeReturnShippingFee;

  /// Maximum return shipping costs that may be charged to the customer
  /// depending on merchant's assessment of the return reason and the merchant's
  /// return policy for the items being returned.
  MonetaryAmount? maxReturnShippingFee;

  /// Total amount that can be refunded for the items in this return.
  ///
  /// It represents the total amount received by the merchant for the items,
  /// after applying merchant coupons.
  MonetaryAmount? refundableItemsTotalAmount;

  /// Maximum amount that can be refunded for the original shipping fee.
  MonetaryAmount? refundableShippingAmount;

  /// Total amount already refunded by the merchant.
  ///
  /// It includes all types of refunds (items, shipping, etc.) Not provided if
  /// no refund has been applied yet.
  MonetaryAmount? totalRefundedAmount;

  ReturnPricingInfo();

  ReturnPricingInfo.fromJson(core.Map _json) {
    if (_json.containsKey('chargeReturnShippingFee')) {
      chargeReturnShippingFee = _json['chargeReturnShippingFee'] as core.bool;
    }
    if (_json.containsKey('maxReturnShippingFee')) {
      maxReturnShippingFee = MonetaryAmount.fromJson(
          _json['maxReturnShippingFee'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('refundableItemsTotalAmount')) {
      refundableItemsTotalAmount = MonetaryAmount.fromJson(
          _json['refundableItemsTotalAmount']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('refundableShippingAmount')) {
      refundableShippingAmount = MonetaryAmount.fromJson(
          _json['refundableShippingAmount']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('totalRefundedAmount')) {
      totalRefundedAmount = MonetaryAmount.fromJson(
          _json['totalRefundedAmount'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (chargeReturnShippingFee != null)
          'chargeReturnShippingFee': chargeReturnShippingFee!,
        if (maxReturnShippingFee != null)
          'maxReturnShippingFee': maxReturnShippingFee!.toJson(),
        if (refundableItemsTotalAmount != null)
          'refundableItemsTotalAmount': refundableItemsTotalAmount!.toJson(),
        if (refundableShippingAmount != null)
          'refundableShippingAmount': refundableShippingAmount!.toJson(),
        if (totalRefundedAmount != null)
          'totalRefundedAmount': totalRefundedAmount!.toJson(),
      };
}

class ReturnShipment {
  /// The date of creation of the shipment, in ISO 8601 format.
  core.String? creationDate;

  /// The date of delivery of the shipment, in ISO 8601 format.
  core.String? deliveryDate;

  /// Type of the return method.
  ///
  /// Acceptable values are: - "`byMail`" - "`contactCustomerSupport`" -
  /// "`returnless`" - "`inStore`"
  core.String? returnMethodType;

  /// Shipment ID generated by Google.
  core.String? shipmentId;

  /// Tracking information of the shipment.
  ///
  /// One return shipment might be handled by several shipping carriers
  /// sequentially.
  core.List<ShipmentTrackingInfo>? shipmentTrackingInfos;

  /// The date of shipping of the shipment, in ISO 8601 format.
  core.String? shippingDate;

  /// State of the shipment.
  ///
  /// Acceptable values are: - "`completed`" - "`new`" - "`shipped`" -
  /// "`undeliverable`" - "`pending`"
  core.String? state;

  ReturnShipment();

  ReturnShipment.fromJson(core.Map _json) {
    if (_json.containsKey('creationDate')) {
      creationDate = _json['creationDate'] as core.String;
    }
    if (_json.containsKey('deliveryDate')) {
      deliveryDate = _json['deliveryDate'] as core.String;
    }
    if (_json.containsKey('returnMethodType')) {
      returnMethodType = _json['returnMethodType'] as core.String;
    }
    if (_json.containsKey('shipmentId')) {
      shipmentId = _json['shipmentId'] as core.String;
    }
    if (_json.containsKey('shipmentTrackingInfos')) {
      shipmentTrackingInfos = (_json['shipmentTrackingInfos'] as core.List)
          .map<ShipmentTrackingInfo>((value) => ShipmentTrackingInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shippingDate')) {
      shippingDate = _json['shippingDate'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creationDate != null) 'creationDate': creationDate!,
        if (deliveryDate != null) 'deliveryDate': deliveryDate!,
        if (returnMethodType != null) 'returnMethodType': returnMethodType!,
        if (shipmentId != null) 'shipmentId': shipmentId!,
        if (shipmentTrackingInfos != null)
          'shipmentTrackingInfos':
              shipmentTrackingInfos!.map((value) => value.toJson()).toList(),
        if (shippingDate != null) 'shippingDate': shippingDate!,
        if (state != null) 'state': state!,
      };
}

/// Return shipping label for a Buy on Google merchant-managed return.
class ReturnShippingLabel {
  /// Name of the carrier.
  core.String? carrier;

  /// The URL for the return shipping label in PDF format
  core.String? labelUri;

  /// The tracking id of this return label.
  core.String? trackingId;

  ReturnShippingLabel();

  ReturnShippingLabel.fromJson(core.Map _json) {
    if (_json.containsKey('carrier')) {
      carrier = _json['carrier'] as core.String;
    }
    if (_json.containsKey('labelUri')) {
      labelUri = _json['labelUri'] as core.String;
    }
    if (_json.containsKey('trackingId')) {
      trackingId = _json['trackingId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrier != null) 'carrier': carrier!,
        if (labelUri != null) 'labelUri': labelUri!,
        if (trackingId != null) 'trackingId': trackingId!,
      };
}

class ReturnaddressCustomBatchRequest {
  /// The request entries to be processed in the batch.
  core.List<ReturnaddressCustomBatchRequestEntry>? entries;

  ReturnaddressCustomBatchRequest();

  ReturnaddressCustomBatchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<ReturnaddressCustomBatchRequestEntry>((value) =>
              ReturnaddressCustomBatchRequestEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

class ReturnaddressCustomBatchRequestEntry {
  /// An entry ID, unique within the batch request.
  core.int? batchId;

  /// The Merchant Center account ID.
  core.String? merchantId;

  /// Method of the batch request entry.
  ///
  /// Acceptable values are: - "`delete`" - "`get`" - "`insert`"
  core.String? method;

  /// The return address to submit.
  ///
  /// This should be set only if the method is `insert`.
  ReturnAddress? returnAddress;

  /// The return address ID.
  ///
  /// This should be set only if the method is `delete` or `get`.
  core.String? returnAddressId;

  ReturnaddressCustomBatchRequestEntry();

  ReturnaddressCustomBatchRequestEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('returnAddress')) {
      returnAddress = ReturnAddress.fromJson(
          _json['returnAddress'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('returnAddressId')) {
      returnAddressId = _json['returnAddressId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (merchantId != null) 'merchantId': merchantId!,
        if (method != null) 'method': method!,
        if (returnAddress != null) 'returnAddress': returnAddress!.toJson(),
        if (returnAddressId != null) 'returnAddressId': returnAddressId!,
      };
}

class ReturnaddressCustomBatchResponse {
  /// The result of the execution of the batch requests.
  core.List<ReturnaddressCustomBatchResponseEntry>? entries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#returnaddressCustomBatchResponse".
  core.String? kind;

  ReturnaddressCustomBatchResponse();

  ReturnaddressCustomBatchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<ReturnaddressCustomBatchResponseEntry>((value) =>
              ReturnaddressCustomBatchResponseEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class ReturnaddressCustomBatchResponseEntry {
  /// The ID of the request entry to which this entry responds.
  core.int? batchId;

  /// A list of errors defined if, and only if, the request failed.
  Errors? errors;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#returnaddressCustomBatchResponseEntry`"
  core.String? kind;

  /// The retrieved return address.
  ReturnAddress? returnAddress;

  ReturnaddressCustomBatchResponseEntry();

  ReturnaddressCustomBatchResponseEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('errors')) {
      errors = Errors.fromJson(
          _json['errors'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('returnAddress')) {
      returnAddress = ReturnAddress.fromJson(
          _json['returnAddress'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (errors != null) 'errors': errors!.toJson(),
        if (kind != null) 'kind': kind!,
        if (returnAddress != null) 'returnAddress': returnAddress!.toJson(),
      };
}

class ReturnaddressListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#returnaddressListResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of addresses.
  core.String? nextPageToken;
  core.List<ReturnAddress>? resources;

  ReturnaddressListResponse();

  ReturnaddressListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<ReturnAddress>((value) => ReturnAddress.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

class ReturnpolicyCustomBatchRequest {
  /// The request entries to be processed in the batch.
  core.List<ReturnpolicyCustomBatchRequestEntry>? entries;

  ReturnpolicyCustomBatchRequest();

  ReturnpolicyCustomBatchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<ReturnpolicyCustomBatchRequestEntry>((value) =>
              ReturnpolicyCustomBatchRequestEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

class ReturnpolicyCustomBatchRequestEntry {
  /// An entry ID, unique within the batch request.
  core.int? batchId;

  /// The Merchant Center account ID.
  core.String? merchantId;

  /// Method of the batch request entry.
  ///
  /// Acceptable values are: - "`delete`" - "`get`" - "`insert`"
  core.String? method;

  /// The return policy to submit.
  ///
  /// This should be set only if the method is `insert`.
  ReturnPolicy? returnPolicy;

  /// The return policy ID.
  ///
  /// This should be set only if the method is `delete` or `get`.
  core.String? returnPolicyId;

  ReturnpolicyCustomBatchRequestEntry();

  ReturnpolicyCustomBatchRequestEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('returnPolicy')) {
      returnPolicy = ReturnPolicy.fromJson(
          _json['returnPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('returnPolicyId')) {
      returnPolicyId = _json['returnPolicyId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (merchantId != null) 'merchantId': merchantId!,
        if (method != null) 'method': method!,
        if (returnPolicy != null) 'returnPolicy': returnPolicy!.toJson(),
        if (returnPolicyId != null) 'returnPolicyId': returnPolicyId!,
      };
}

class ReturnpolicyCustomBatchResponse {
  /// The result of the execution of the batch requests.
  core.List<ReturnpolicyCustomBatchResponseEntry>? entries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#returnpolicyCustomBatchResponse".
  core.String? kind;

  ReturnpolicyCustomBatchResponse();

  ReturnpolicyCustomBatchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<ReturnpolicyCustomBatchResponseEntry>((value) =>
              ReturnpolicyCustomBatchResponseEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class ReturnpolicyCustomBatchResponseEntry {
  /// The ID of the request entry to which this entry responds.
  core.int? batchId;

  /// A list of errors defined if, and only if, the request failed.
  Errors? errors;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#returnpolicyCustomBatchResponseEntry`"
  core.String? kind;

  /// The retrieved return policy.
  ReturnPolicy? returnPolicy;

  ReturnpolicyCustomBatchResponseEntry();

  ReturnpolicyCustomBatchResponseEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('errors')) {
      errors = Errors.fromJson(
          _json['errors'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('returnPolicy')) {
      returnPolicy = ReturnPolicy.fromJson(
          _json['returnPolicy'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (errors != null) 'errors': errors!.toJson(),
        if (kind != null) 'kind': kind!,
        if (returnPolicy != null) 'returnPolicy': returnPolicy!.toJson(),
      };
}

class ReturnpolicyListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#returnpolicyListResponse".
  core.String? kind;
  core.List<ReturnPolicy>? resources;

  ReturnpolicyListResponse();

  ReturnpolicyListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<ReturnPolicy>((value) => ReturnPolicy.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

class Row {
  /// The list of cells that constitute the row.
  ///
  /// Must have the same length as `columnHeaders` for two-dimensional tables, a
  /// length of 1 for one-dimensional tables. Required.
  core.List<Value>? cells;

  Row();

  Row.fromJson(core.Map _json) {
    if (_json.containsKey('cells')) {
      cells = (_json['cells'] as core.List)
          .map<Value>((value) =>
              Value.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cells != null)
          'cells': cells!.map((value) => value.toJson()).toList(),
      };
}

/// Request message for the ReportService.Search method.
class SearchRequest {
  /// Number of ReportRows to retrieve in a single page.
  ///
  /// Defaults to the maximum of 1000. Values above 1000 are coerced to 1000.
  core.int? pageSize;

  /// Token of the page to retrieve.
  ///
  /// If not specified, the first page of results is returned. In order to
  /// request the next page of results, the value obtained from
  /// `next_page_token` in the previous response should be used.
  core.String? pageToken;

  /// Query that defines performance metrics to retrieve and dimensions
  /// according to which the metrics are to be segmented.
  ///
  /// Required.
  core.String? query;

  SearchRequest();

  SearchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('pageSize')) {
      pageSize = _json['pageSize'] as core.int;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
    if (_json.containsKey('query')) {
      query = _json['query'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pageSize != null) 'pageSize': pageSize!,
        if (pageToken != null) 'pageToken': pageToken!,
        if (query != null) 'query': query!,
      };
}

/// Response message for the ReportService.Search method.
class SearchResponse {
  /// Token which can be sent as `page_token` to retrieve the next page.
  ///
  /// If omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// Rows that matched the search query.
  core.List<ReportRow>? results;

  SearchResponse();

  SearchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('results')) {
      results = (_json['results'] as core.List)
          .map<ReportRow>((value) =>
              ReportRow.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (results != null)
          'results': results!.map((value) => value.toJson()).toList(),
      };
}

/// Dimensions according to which metrics are segmented in the response.
///
/// Values of product dimensions, e.g., offer id, reflect the state of a product
/// at the time of the corresponding event, e.g., impression or order. Segment
/// fields cannot be selected in queries without also selecting at least one
/// metric field. Values are only set for dimensions requested explicitly in the
/// request's search query.
class Segments {
  /// Date in the merchant timezone to which metrics apply.
  Date? date;

  /// Merchant-provided id of the product.
  core.String? offerId;

  /// Program to which metrics apply, e.g., Free Product Listing.
  /// Possible string values are:
  /// - "PROGRAM_UNSPECIFIED" : Not specified.
  /// - "SHOPPING_ADS" : Shopping Ads.
  /// - "FREE_PRODUCT_LISTING" : Free Product Listing.
  /// - "FREE_LOCAL_PRODUCT_LISTING" : Free Local Product Listing.
  /// - "BUY_ON_GOOGLE_LISTING" : Buy on Google Listing.
  core.String? program;

  Segments();

  Segments.fromJson(core.Map _json) {
    if (_json.containsKey('date')) {
      date =
          Date.fromJson(_json['date'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('offerId')) {
      offerId = _json['offerId'] as core.String;
    }
    if (_json.containsKey('program')) {
      program = _json['program'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (date != null) 'date': date!.toJson(),
        if (offerId != null) 'offerId': offerId!,
        if (program != null) 'program': program!,
      };
}

class Service {
  /// A boolean exposing the active status of the shipping service.
  ///
  /// Required.
  core.bool? active;

  /// The CLDR code of the currency to which this service applies.
  ///
  /// Must match that of the prices in rate groups.
  core.String? currency;

  /// The CLDR territory code of the country to which the service applies.
  ///
  /// Required.
  core.String? deliveryCountry;

  /// Time spent in various aspects from order to the delivery of the product.
  ///
  /// Required.
  DeliveryTime? deliveryTime;

  /// Eligibility for this service.
  ///
  /// Acceptable values are: - "`All scenarios`" - "`All scenarios except
  /// Shopping Actions`" - "`Shopping Actions`"
  core.String? eligibility;

  /// Minimum order value for this service.
  ///
  /// If set, indicates that customers will have to spend at least this amount.
  /// All prices within a service must have the same currency. Cannot be set
  /// together with minimum_order_value_table.
  Price? minimumOrderValue;

  /// Table of per store minimum order values for the pickup fulfillment type.
  ///
  /// Cannot be set together with minimum_order_value.
  MinimumOrderValueTable? minimumOrderValueTable;

  /// Free-form name of the service.
  ///
  /// Must be unique within target account. Required.
  core.String? name;

  /// The carrier-service pair delivering items to collection points.
  ///
  /// The list of supported pickup services can be retrieved via the
  /// `getSupportedPickupServices` method. Required if and only if the service
  /// delivery type is `pickup`.
  PickupCarrierService? pickupService;

  /// Shipping rate group definitions.
  ///
  /// Only the last one is allowed to have an empty `applicableShippingLabels`,
  /// which means "everything else". The other `applicableShippingLabels` must
  /// not overlap.
  core.List<RateGroup>? rateGroups;

  /// Type of locations this service ships orders to.
  ///
  /// Acceptable values are: - "`delivery`" - "`pickup`"
  core.String? shipmentType;

  Service();

  Service.fromJson(core.Map _json) {
    if (_json.containsKey('active')) {
      active = _json['active'] as core.bool;
    }
    if (_json.containsKey('currency')) {
      currency = _json['currency'] as core.String;
    }
    if (_json.containsKey('deliveryCountry')) {
      deliveryCountry = _json['deliveryCountry'] as core.String;
    }
    if (_json.containsKey('deliveryTime')) {
      deliveryTime = DeliveryTime.fromJson(
          _json['deliveryTime'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('eligibility')) {
      eligibility = _json['eligibility'] as core.String;
    }
    if (_json.containsKey('minimumOrderValue')) {
      minimumOrderValue = Price.fromJson(
          _json['minimumOrderValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('minimumOrderValueTable')) {
      minimumOrderValueTable = MinimumOrderValueTable.fromJson(
          _json['minimumOrderValueTable']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('pickupService')) {
      pickupService = PickupCarrierService.fromJson(
          _json['pickupService'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rateGroups')) {
      rateGroups = (_json['rateGroups'] as core.List)
          .map<RateGroup>((value) =>
              RateGroup.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shipmentType')) {
      shipmentType = _json['shipmentType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (active != null) 'active': active!,
        if (currency != null) 'currency': currency!,
        if (deliveryCountry != null) 'deliveryCountry': deliveryCountry!,
        if (deliveryTime != null) 'deliveryTime': deliveryTime!.toJson(),
        if (eligibility != null) 'eligibility': eligibility!,
        if (minimumOrderValue != null)
          'minimumOrderValue': minimumOrderValue!.toJson(),
        if (minimumOrderValueTable != null)
          'minimumOrderValueTable': minimumOrderValueTable!.toJson(),
        if (name != null) 'name': name!,
        if (pickupService != null) 'pickupService': pickupService!.toJson(),
        if (rateGroups != null)
          'rateGroups': rateGroups!.map((value) => value.toJson()).toList(),
        if (shipmentType != null) 'shipmentType': shipmentType!,
      };
}

/// Settlement reports detail order-level and item-level credits and debits
/// between you and Google.
class SettlementReport {
  /// The end date on which all transactions are included in the report, in ISO
  /// 8601 format.
  core.String? endDate;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#settlementReport`"
  core.String? kind;

  /// The residual amount from the previous invoice.
  ///
  /// This is set only if the previous invoices are not paid because of negative
  /// balance.
  Price? previousBalance;

  /// The ID of the settlement report.
  core.String? settlementId;

  /// The start date on which all transactions are included in the report, in
  /// ISO 8601 format.
  core.String? startDate;

  /// The money due to the merchant.
  Price? transferAmount;

  /// Date on which transfer for this payment was initiated by Google, in ISO
  /// 8601 format.
  core.String? transferDate;

  /// The list of bank identifiers used for the transfer.
  ///
  /// e.g. Trace ID for Federal Automated Clearing House (ACH). This may also be
  /// known as the Wire ID.
  core.List<core.String>? transferIds;

  SettlementReport();

  SettlementReport.fromJson(core.Map _json) {
    if (_json.containsKey('endDate')) {
      endDate = _json['endDate'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('previousBalance')) {
      previousBalance = Price.fromJson(
          _json['previousBalance'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('settlementId')) {
      settlementId = _json['settlementId'] as core.String;
    }
    if (_json.containsKey('startDate')) {
      startDate = _json['startDate'] as core.String;
    }
    if (_json.containsKey('transferAmount')) {
      transferAmount = Price.fromJson(
          _json['transferAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('transferDate')) {
      transferDate = _json['transferDate'] as core.String;
    }
    if (_json.containsKey('transferIds')) {
      transferIds = (_json['transferIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endDate != null) 'endDate': endDate!,
        if (kind != null) 'kind': kind!,
        if (previousBalance != null)
          'previousBalance': previousBalance!.toJson(),
        if (settlementId != null) 'settlementId': settlementId!,
        if (startDate != null) 'startDate': startDate!,
        if (transferAmount != null) 'transferAmount': transferAmount!.toJson(),
        if (transferDate != null) 'transferDate': transferDate!,
        if (transferIds != null) 'transferIds': transferIds!,
      };
}

/// Settlement transactions give a detailed breakdown of the settlement report.
class SettlementTransaction {
  /// The amount for the transaction.
  SettlementTransactionAmount? amount;

  /// Identifiers of the transaction.
  SettlementTransactionIdentifiers? identifiers;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#settlementTransaction`"
  core.String? kind;

  /// Details of the transaction.
  SettlementTransactionTransaction? transaction;

  SettlementTransaction();

  SettlementTransaction.fromJson(core.Map _json) {
    if (_json.containsKey('amount')) {
      amount = SettlementTransactionAmount.fromJson(
          _json['amount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('identifiers')) {
      identifiers = SettlementTransactionIdentifiers.fromJson(
          _json['identifiers'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('transaction')) {
      transaction = SettlementTransactionTransaction.fromJson(
          _json['transaction'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (amount != null) 'amount': amount!.toJson(),
        if (identifiers != null) 'identifiers': identifiers!.toJson(),
        if (kind != null) 'kind': kind!,
        if (transaction != null) 'transaction': transaction!.toJson(),
      };
}

class SettlementTransactionAmount {
  SettlementTransactionAmountCommission? commission;

  /// The description of the event.
  ///
  /// Acceptable values are: - "`taxWithhold`" - "`principal`" -
  /// "`principalAdjustment`" - "`shippingFee`" - "`merchantRemittedSalesTax`" -
  /// "`googleRemittedSalesTax`" - "`merchantCoupon`" - "`merchantCouponTax`" -
  /// "`merchantRemittedDisposalTax`" - "`googleRemittedDisposalTax`" -
  /// "`merchantRemittedRedemptionFee`" - "`googleRemittedRedemptionFee`" -
  /// "`eeeEcoFee`" - "`furnitureEcoFee`" - "`copyPrivateFee`" -
  /// "`eeeEcoFeeCommission`" - "`furnitureEcoFeeCommission`" -
  /// "`copyPrivateFeeCommission`" - "`principalRefund`" -
  /// "`principalRefundTax`" - "`itemCommission`" - "`adjustmentCommission`" -
  /// "`shippingFeeCommission`" - "`commissionRefund`" - "`damaged`" -
  /// "`damagedOrDefectiveItem`" - "`expiredItem`" - "`faultyItem`" -
  /// "`incorrectItemReceived`" - "`itemMissing`" - "`qualityNotExpected`" -
  /// "`receivedTooLate`" - "`storePackageMissing`" - "`transitPackageMissing`"
  /// - "`unsuccessfulDeliveryUndeliverable`" - "`wrongChargeInStore`" -
  /// "`wrongItem`" - "`returns`" - "`undeliverable`" -
  /// "`issueRelatedRefundAndReplacementAmountDescription`" -
  /// "`refundFromMerchant`" - "`returnLabelShippingFee`" -
  /// "`lumpSumCorrection`" - "`pspFee`" - "`principalRefundDoesNotFit`" -
  /// "`principalRefundOrderedWrongItem`" -
  /// "`principalRefundQualityNotExpected`" -
  /// "`principalRefundBetterPriceFound`" - "`principalRefundNoLongerNeeded`" -
  /// "`principalRefundChangedMind`" - "`principalRefundReceivedTooLate`" -
  /// "`principalRefundIncorrectItemReceived`" -
  /// "`principalRefundDamagedOrDefectiveItem`" -
  /// "`principalRefundDidNotMatchDescription`" - "`principalRefundExpiredItem`"
  core.String? description;

  /// The amount that contributes to the line item price.
  Price? transactionAmount;

  /// The type of the amount.
  ///
  /// Acceptable values are: - "`itemPrice`" - "`orderPrice`" - "`refund`" -
  /// "`earlyRefund`" - "`courtesyRefund`" - "`returnRefund`" -
  /// "`returnLabelShippingFeeAmount`" - "`lumpSumCorrectionAmount`"
  core.String? type;

  SettlementTransactionAmount();

  SettlementTransactionAmount.fromJson(core.Map _json) {
    if (_json.containsKey('commission')) {
      commission = SettlementTransactionAmountCommission.fromJson(
          _json['commission'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('transactionAmount')) {
      transactionAmount = Price.fromJson(
          _json['transactionAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (commission != null) 'commission': commission!.toJson(),
        if (description != null) 'description': description!,
        if (transactionAmount != null)
          'transactionAmount': transactionAmount!.toJson(),
        if (type != null) 'type': type!,
      };
}

class SettlementTransactionAmountCommission {
  /// The category of the commission.
  ///
  /// Acceptable values are: - "`animalsAndPetSupplies`" -
  /// "`dogCatFoodAndCatLitter`" - "`apparelAndAccessories`" -
  /// "`shoesHandbagsAndSunglasses`" - "`costumesAndAccessories`" - "`jewelry`"
  /// - "`watches`" - "`hobbiesArtsAndCrafts`" - "`homeAndGarden`" -
  /// "`entertainmentCollectibles`" - "`collectibleCoins`" -
  /// "`sportsCollectibles`" - "`sportingGoods`" - "`toysAndGames`" -
  /// "`musicalInstruments`" - "`giftCards`" - "`babyAndToddler`" -
  /// "`babyFoodWipesAndDiapers`" - "`businessAndIndustrial`" -
  /// "`camerasOpticsAndPhotography`" - "`consumerElectronics`" -
  /// "`electronicsAccessories`" - "`personalComputers`" - "`videoGameConsoles`"
  /// - "`foodAndGrocery`" - "`beverages`" - "`tobaccoProducts`" - "`furniture`"
  /// - "`hardware`" - "`buildingMaterials`" - "`tools`" -
  /// "`healthAndPersonalCare`" - "`beauty`" - "`householdSupplies`" -
  /// "`kitchenAndDining`" - "`majorAppliances`" - "`luggageAndBags`" -
  /// "`media`" - "`officeSupplies`" - "`softwareAndVideoGames`" -
  /// "`vehiclePartsAndAccessories`" - "`vehicleTiresAndWheels`" - "`vehicles`"
  /// - "`everythingElse`"
  core.String? category;

  /// Rate of the commission in percentage.
  core.String? rate;

  SettlementTransactionAmountCommission();

  SettlementTransactionAmountCommission.fromJson(core.Map _json) {
    if (_json.containsKey('category')) {
      category = _json['category'] as core.String;
    }
    if (_json.containsKey('rate')) {
      rate = _json['rate'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (category != null) 'category': category!,
        if (rate != null) 'rate': rate!,
      };
}

class SettlementTransactionIdentifiers {
  /// The identifier of the adjustments, if it is available.
  core.String? adjustmentId;

  /// The merchant provided order ID.
  core.String? merchantOrderId;

  /// The identifier of the item.
  core.String? orderItemId;

  /// The unique ID of the settlement transaction entry.
  core.String? settlementEntryId;

  /// The shipment ids for the item.
  core.List<core.String>? shipmentIds;

  /// The Google transaction ID.
  core.String? transactionId;

  SettlementTransactionIdentifiers();

  SettlementTransactionIdentifiers.fromJson(core.Map _json) {
    if (_json.containsKey('adjustmentId')) {
      adjustmentId = _json['adjustmentId'] as core.String;
    }
    if (_json.containsKey('merchantOrderId')) {
      merchantOrderId = _json['merchantOrderId'] as core.String;
    }
    if (_json.containsKey('orderItemId')) {
      orderItemId = _json['orderItemId'] as core.String;
    }
    if (_json.containsKey('settlementEntryId')) {
      settlementEntryId = _json['settlementEntryId'] as core.String;
    }
    if (_json.containsKey('shipmentIds')) {
      shipmentIds = (_json['shipmentIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('transactionId')) {
      transactionId = _json['transactionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adjustmentId != null) 'adjustmentId': adjustmentId!,
        if (merchantOrderId != null) 'merchantOrderId': merchantOrderId!,
        if (orderItemId != null) 'orderItemId': orderItemId!,
        if (settlementEntryId != null) 'settlementEntryId': settlementEntryId!,
        if (shipmentIds != null) 'shipmentIds': shipmentIds!,
        if (transactionId != null) 'transactionId': transactionId!,
      };
}

class SettlementTransactionTransaction {
  /// The time on which the event occurred in ISO 8601 format.
  core.String? postDate;

  /// The type of the transaction that occurred.
  ///
  /// Acceptable values are: - "`order`" - "`reversal`" - "`orderRefund`" -
  /// "`reversalRefund`" - "`issueRelatedRefundAndReplacement`" -
  /// "`returnLabelShippingFeeTransaction`" -
  /// "`reversalIssueRelatedRefundAndReplacement`" -
  /// "`reversalReturnLabelShippingFeeTransaction`" -
  /// "`lumpSumCorrectionTransaction`"
  core.String? type;

  SettlementTransactionTransaction();

  SettlementTransactionTransaction.fromJson(core.Map _json) {
    if (_json.containsKey('postDate')) {
      postDate = _json['postDate'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (postDate != null) 'postDate': postDate!,
        if (type != null) 'type': type!,
      };
}

class SettlementreportsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#settlementreportsListResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of returns.
  core.String? nextPageToken;
  core.List<SettlementReport>? resources;

  SettlementreportsListResponse();

  SettlementreportsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<SettlementReport>((value) => SettlementReport.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

class SettlementtransactionsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#settlementtransactionsListResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of returns.
  core.String? nextPageToken;
  core.List<SettlementTransaction>? resources;

  SettlementtransactionsListResponse();

  SettlementtransactionsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<SettlementTransaction>((value) => SettlementTransaction.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

class ShipmentInvoice {
  /// Invoice summary.
  ///
  /// Required.
  InvoiceSummary? invoiceSummary;

  /// Invoice details per line item.
  ///
  /// Required.
  core.List<ShipmentInvoiceLineItemInvoice>? lineItemInvoices;

  /// ID of the shipment group.
  ///
  /// It is assigned by the merchant in the `shipLineItems` method and is used
  /// to group multiple line items that have the same kind of shipping charges.
  ///
  /// Required.
  core.String? shipmentGroupId;

  ShipmentInvoice();

  ShipmentInvoice.fromJson(core.Map _json) {
    if (_json.containsKey('invoiceSummary')) {
      invoiceSummary = InvoiceSummary.fromJson(
          _json['invoiceSummary'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lineItemInvoices')) {
      lineItemInvoices = (_json['lineItemInvoices'] as core.List)
          .map<ShipmentInvoiceLineItemInvoice>((value) =>
              ShipmentInvoiceLineItemInvoice.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shipmentGroupId')) {
      shipmentGroupId = _json['shipmentGroupId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (invoiceSummary != null) 'invoiceSummary': invoiceSummary!.toJson(),
        if (lineItemInvoices != null)
          'lineItemInvoices':
              lineItemInvoices!.map((value) => value.toJson()).toList(),
        if (shipmentGroupId != null) 'shipmentGroupId': shipmentGroupId!,
      };
}

class ShipmentInvoiceLineItemInvoice {
  /// ID of the line item.
  ///
  /// Either lineItemId or productId must be set.
  core.String? lineItemId;

  /// ID of the product.
  ///
  /// This is the REST ID used in the products service. Either lineItemId or
  /// productId must be set.
  core.String? productId;

  /// The shipment unit ID is assigned by the merchant and defines individual
  /// quantities within a line item.
  ///
  /// The same ID can be assigned to units that are the same while units that
  /// differ must be assigned a different ID (for example: free or promotional
  /// units).
  ///
  /// Required.
  core.List<core.String>? shipmentUnitIds;

  /// Invoice details for a single unit.
  ///
  /// Required.
  UnitInvoice? unitInvoice;

  ShipmentInvoiceLineItemInvoice();

  ShipmentInvoiceLineItemInvoice.fromJson(core.Map _json) {
    if (_json.containsKey('lineItemId')) {
      lineItemId = _json['lineItemId'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('shipmentUnitIds')) {
      shipmentUnitIds = (_json['shipmentUnitIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('unitInvoice')) {
      unitInvoice = UnitInvoice.fromJson(
          _json['unitInvoice'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lineItemId != null) 'lineItemId': lineItemId!,
        if (productId != null) 'productId': productId!,
        if (shipmentUnitIds != null) 'shipmentUnitIds': shipmentUnitIds!,
        if (unitInvoice != null) 'unitInvoice': unitInvoice!.toJson(),
      };
}

class ShipmentTrackingInfo {
  /// The shipping carrier that handles the package.
  ///
  /// Acceptable values are: - "`boxtal`" - "`bpost`" - "`chronopost`" -
  /// "`colisPrive`" - "`colissimo`" - "`cxt`" - "`deliv`" - "`dhl`" - "`dpd`" -
  /// "`dynamex`" - "`eCourier`" - "`easypost`" - "`efw`" - "`fedex`" -
  /// "`fedexSmartpost`" - "`geodis`" - "`gls`" - "`googleCourier`" - "`gsx`" -
  /// "`jdLogistics`" - "`laPoste`" - "`lasership`" - "`manual`" - "`mpx`" -
  /// "`onTrac`" - "`other`" - "`tnt`" - "`uds`" - "`ups`" - "`usps`"
  core.String? carrier;

  /// The tracking number for the package.
  core.String? trackingNumber;

  ShipmentTrackingInfo();

  ShipmentTrackingInfo.fromJson(core.Map _json) {
    if (_json.containsKey('carrier')) {
      carrier = _json['carrier'] as core.String;
    }
    if (_json.containsKey('trackingNumber')) {
      trackingNumber = _json['trackingNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrier != null) 'carrier': carrier!,
        if (trackingNumber != null) 'trackingNumber': trackingNumber!,
      };
}

/// The merchant account's shipping settings.
///
/// All methods except getsupportedcarriers and getsupportedholidays require the
/// admin role.
class ShippingSettings {
  /// The ID of the account to which these account shipping settings belong.
  ///
  /// Ignored upon update, always present in get request responses.
  core.String? accountId;

  /// A list of postal code groups that can be referred to in `services`.
  ///
  /// Optional.
  core.List<PostalCodeGroup>? postalCodeGroups;

  /// The target account's list of services.
  ///
  /// Optional.
  core.List<Service>? services;

  ShippingSettings();

  ShippingSettings.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('postalCodeGroups')) {
      postalCodeGroups = (_json['postalCodeGroups'] as core.List)
          .map<PostalCodeGroup>((value) => PostalCodeGroup.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('services')) {
      services = (_json['services'] as core.List)
          .map<Service>((value) =>
              Service.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (postalCodeGroups != null)
          'postalCodeGroups':
              postalCodeGroups!.map((value) => value.toJson()).toList(),
        if (services != null)
          'services': services!.map((value) => value.toJson()).toList(),
      };
}

class ShippingsettingsCustomBatchRequest {
  /// The request entries to be processed in the batch.
  core.List<ShippingsettingsCustomBatchRequestEntry>? entries;

  ShippingsettingsCustomBatchRequest();

  ShippingsettingsCustomBatchRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<ShippingsettingsCustomBatchRequestEntry>((value) =>
              ShippingsettingsCustomBatchRequestEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

/// A batch entry encoding a single non-batch shippingsettings request.
class ShippingsettingsCustomBatchRequestEntry {
  /// The ID of the account for which to get/update account shipping settings.
  core.String? accountId;

  /// An entry ID, unique within the batch request.
  core.int? batchId;

  /// The ID of the managing account.
  core.String? merchantId;

  /// The method of the batch entry.
  ///
  /// Acceptable values are: - "`get`" - "`update`"
  core.String? method;

  /// The account shipping settings to update.
  ///
  /// Only defined if the method is `update`.
  ShippingSettings? shippingSettings;

  ShippingsettingsCustomBatchRequestEntry();

  ShippingsettingsCustomBatchRequestEntry.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('merchantId')) {
      merchantId = _json['merchantId'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('shippingSettings')) {
      shippingSettings = ShippingSettings.fromJson(
          _json['shippingSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (batchId != null) 'batchId': batchId!,
        if (merchantId != null) 'merchantId': merchantId!,
        if (method != null) 'method': method!,
        if (shippingSettings != null)
          'shippingSettings': shippingSettings!.toJson(),
      };
}

class ShippingsettingsCustomBatchResponse {
  /// The result of the execution of the batch requests.
  core.List<ShippingsettingsCustomBatchResponseEntry>? entries;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#shippingsettingsCustomBatchResponse".
  core.String? kind;

  ShippingsettingsCustomBatchResponse();

  ShippingsettingsCustomBatchResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<ShippingsettingsCustomBatchResponseEntry>((value) =>
              ShippingsettingsCustomBatchResponseEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// A batch entry encoding a single non-batch shipping settings response.
class ShippingsettingsCustomBatchResponseEntry {
  /// The ID of the request entry to which this entry responds.
  core.int? batchId;

  /// A list of errors defined if, and only if, the request failed.
  Errors? errors;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "`content#shippingsettingsCustomBatchResponseEntry`"
  core.String? kind;

  /// The retrieved or updated account shipping settings.
  ShippingSettings? shippingSettings;

  ShippingsettingsCustomBatchResponseEntry();

  ShippingsettingsCustomBatchResponseEntry.fromJson(core.Map _json) {
    if (_json.containsKey('batchId')) {
      batchId = _json['batchId'] as core.int;
    }
    if (_json.containsKey('errors')) {
      errors = Errors.fromJson(
          _json['errors'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('shippingSettings')) {
      shippingSettings = ShippingSettings.fromJson(
          _json['shippingSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchId != null) 'batchId': batchId!,
        if (errors != null) 'errors': errors!.toJson(),
        if (kind != null) 'kind': kind!,
        if (shippingSettings != null)
          'shippingSettings': shippingSettings!.toJson(),
      };
}

class ShippingsettingsGetSupportedCarriersResponse {
  /// A list of supported carriers.
  ///
  /// May be empty.
  core.List<CarriersCarrier>? carriers;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "content#shippingsettingsGetSupportedCarriersResponse".
  core.String? kind;

  ShippingsettingsGetSupportedCarriersResponse();

  ShippingsettingsGetSupportedCarriersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('carriers')) {
      carriers = (_json['carriers'] as core.List)
          .map<CarriersCarrier>((value) => CarriersCarrier.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carriers != null)
          'carriers': carriers!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class ShippingsettingsGetSupportedHolidaysResponse {
  /// A list of holidays applicable for delivery guarantees.
  ///
  /// May be empty.
  core.List<HolidaysHoliday>? holidays;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "content#shippingsettingsGetSupportedHolidaysResponse".
  core.String? kind;

  ShippingsettingsGetSupportedHolidaysResponse();

  ShippingsettingsGetSupportedHolidaysResponse.fromJson(core.Map _json) {
    if (_json.containsKey('holidays')) {
      holidays = (_json['holidays'] as core.List)
          .map<HolidaysHoliday>((value) => HolidaysHoliday.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (holidays != null)
          'holidays': holidays!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class ShippingsettingsGetSupportedPickupServicesResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string
  /// "content#shippingsettingsGetSupportedPickupServicesResponse".
  core.String? kind;

  /// A list of supported pickup services.
  ///
  /// May be empty.
  core.List<PickupServicesPickupService>? pickupServices;

  ShippingsettingsGetSupportedPickupServicesResponse();

  ShippingsettingsGetSupportedPickupServicesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('pickupServices')) {
      pickupServices = (_json['pickupServices'] as core.List)
          .map<PickupServicesPickupService>((value) =>
              PickupServicesPickupService.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (pickupServices != null)
          'pickupServices':
              pickupServices!.map((value) => value.toJson()).toList(),
      };
}

class ShippingsettingsListResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "content#shippingsettingsListResponse".
  core.String? kind;

  /// The token for the retrieval of the next page of shipping settings.
  core.String? nextPageToken;
  core.List<ShippingSettings>? resources;

  ShippingsettingsListResponse();

  ShippingsettingsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<ShippingSettings>((value) => ShippingSettings.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

class Table {
  /// Headers of the table's columns.
  ///
  /// Optional: if not set then the table has only one dimension.
  Headers? columnHeaders;

  /// Name of the table.
  ///
  /// Required for subtables, ignored for the main table.
  core.String? name;

  /// Headers of the table's rows.
  ///
  /// Required.
  Headers? rowHeaders;

  /// The list of rows that constitute the table.
  ///
  /// Must have the same length as `rowHeaders`. Required.
  core.List<Row>? rows;

  Table();

  Table.fromJson(core.Map _json) {
    if (_json.containsKey('columnHeaders')) {
      columnHeaders = Headers.fromJson(
          _json['columnHeaders'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('rowHeaders')) {
      rowHeaders = Headers.fromJson(
          _json['rowHeaders'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rows')) {
      rows = (_json['rows'] as core.List)
          .map<Row>((value) =>
              Row.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnHeaders != null) 'columnHeaders': columnHeaders!.toJson(),
        if (name != null) 'name': name!,
        if (rowHeaders != null) 'rowHeaders': rowHeaders!.toJson(),
        if (rows != null) 'rows': rows!.map((value) => value.toJson()).toList(),
      };
}

class TestOrder {
  /// Overrides the predefined delivery details if provided.
  TestOrderDeliveryDetails? deliveryDetails;

  /// Whether the orderinvoices service should support this order.
  core.bool? enableOrderinvoices;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "`content#testOrder`"
  core.String? kind;

  /// Line items that are ordered.
  ///
  /// At least one line item must be provided.
  ///
  /// Required.
  core.List<TestOrderLineItem>? lineItems;

  /// Restricted.
  ///
  /// Do not use.
  core.String? notificationMode;

  /// Overrides the predefined pickup details if provided.
  TestOrderPickupDetails? pickupDetails;

  /// The billing address.
  ///
  /// Acceptable values are: - "`dwight`" - "`jim`" - "`pam`"
  ///
  /// Required.
  core.String? predefinedBillingAddress;

  /// Identifier of one of the predefined delivery addresses for the delivery.
  ///
  /// Acceptable values are: - "`dwight`" - "`jim`" - "`pam`"
  ///
  /// Required.
  core.String? predefinedDeliveryAddress;

  /// Email address of the customer.
  ///
  /// Acceptable values are: - "`pog.dwight.schrute@gmail.com`" -
  /// "`pog.jim.halpert@gmail.com`" - "`penpog.pam.beesly@gmail.comding`"
  ///
  /// Required.
  core.String? predefinedEmail;

  /// Identifier of one of the predefined pickup details.
  ///
  /// Required for orders containing line items with shipping type `pickup`.
  /// Acceptable values are: - "`dwight`" - "`jim`" - "`pam`"
  core.String? predefinedPickupDetails;

  /// Promotions associated with the order.
  core.List<OrderPromotion>? promotions;

  /// The price of shipping for all items.
  ///
  /// Shipping tax is automatically calculated for orders where marketplace
  /// facilitator tax laws are applicable. Otherwise, tax settings from Merchant
  /// Center are applied. Note that shipping is not taxed in certain states.
  ///
  /// Required.
  Price? shippingCost;

  /// The requested shipping option.
  ///
  /// Acceptable values are: - "`economy`" - "`expedited`" - "`oneDay`" -
  /// "`sameDay`" - "`standard`" - "`twoDay`"
  ///
  /// Required.
  core.String? shippingOption;

  TestOrder();

  TestOrder.fromJson(core.Map _json) {
    if (_json.containsKey('deliveryDetails')) {
      deliveryDetails = TestOrderDeliveryDetails.fromJson(
          _json['deliveryDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('enableOrderinvoices')) {
      enableOrderinvoices = _json['enableOrderinvoices'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lineItems')) {
      lineItems = (_json['lineItems'] as core.List)
          .map<TestOrderLineItem>((value) => TestOrderLineItem.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('notificationMode')) {
      notificationMode = _json['notificationMode'] as core.String;
    }
    if (_json.containsKey('pickupDetails')) {
      pickupDetails = TestOrderPickupDetails.fromJson(
          _json['pickupDetails'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('predefinedBillingAddress')) {
      predefinedBillingAddress =
          _json['predefinedBillingAddress'] as core.String;
    }
    if (_json.containsKey('predefinedDeliveryAddress')) {
      predefinedDeliveryAddress =
          _json['predefinedDeliveryAddress'] as core.String;
    }
    if (_json.containsKey('predefinedEmail')) {
      predefinedEmail = _json['predefinedEmail'] as core.String;
    }
    if (_json.containsKey('predefinedPickupDetails')) {
      predefinedPickupDetails = _json['predefinedPickupDetails'] as core.String;
    }
    if (_json.containsKey('promotions')) {
      promotions = (_json['promotions'] as core.List)
          .map<OrderPromotion>((value) => OrderPromotion.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shippingCost')) {
      shippingCost = Price.fromJson(
          _json['shippingCost'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shippingOption')) {
      shippingOption = _json['shippingOption'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deliveryDetails != null)
          'deliveryDetails': deliveryDetails!.toJson(),
        if (enableOrderinvoices != null)
          'enableOrderinvoices': enableOrderinvoices!,
        if (kind != null) 'kind': kind!,
        if (lineItems != null)
          'lineItems': lineItems!.map((value) => value.toJson()).toList(),
        if (notificationMode != null) 'notificationMode': notificationMode!,
        if (pickupDetails != null) 'pickupDetails': pickupDetails!.toJson(),
        if (predefinedBillingAddress != null)
          'predefinedBillingAddress': predefinedBillingAddress!,
        if (predefinedDeliveryAddress != null)
          'predefinedDeliveryAddress': predefinedDeliveryAddress!,
        if (predefinedEmail != null) 'predefinedEmail': predefinedEmail!,
        if (predefinedPickupDetails != null)
          'predefinedPickupDetails': predefinedPickupDetails!,
        if (promotions != null)
          'promotions': promotions!.map((value) => value.toJson()).toList(),
        if (shippingCost != null) 'shippingCost': shippingCost!.toJson(),
        if (shippingOption != null) 'shippingOption': shippingOption!,
      };
}

class TestOrderAddress {
  /// CLDR country code (e.g. "US").
  core.String? country;

  /// Strings representing the lines of the printed label for mailing the order,
  /// for example: John Smith 1600 Amphitheatre Parkway Mountain View, CA, 94043
  /// United States
  core.List<core.String>? fullAddress;

  /// Whether the address is a post office box.
  core.bool? isPostOfficeBox;

  /// City, town or commune.
  ///
  /// May also include dependent localities or sublocalities (e.g. neighborhoods
  /// or suburbs).
  core.String? locality;

  /// Postal Code or ZIP (e.g. "94043").
  core.String? postalCode;

  /// Name of the recipient.
  core.String? recipientName;

  /// Top-level administrative subdivision of the country.
  ///
  /// For example, a state like California ("CA") or a province like Quebec
  /// ("QC").
  core.String? region;

  /// Street-level part of the address.
  core.List<core.String>? streetAddress;

  TestOrderAddress();

  TestOrderAddress.fromJson(core.Map _json) {
    if (_json.containsKey('country')) {
      country = _json['country'] as core.String;
    }
    if (_json.containsKey('fullAddress')) {
      fullAddress = (_json['fullAddress'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('isPostOfficeBox')) {
      isPostOfficeBox = _json['isPostOfficeBox'] as core.bool;
    }
    if (_json.containsKey('locality')) {
      locality = _json['locality'] as core.String;
    }
    if (_json.containsKey('postalCode')) {
      postalCode = _json['postalCode'] as core.String;
    }
    if (_json.containsKey('recipientName')) {
      recipientName = _json['recipientName'] as core.String;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('streetAddress')) {
      streetAddress = (_json['streetAddress'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (country != null) 'country': country!,
        if (fullAddress != null) 'fullAddress': fullAddress!,
        if (isPostOfficeBox != null) 'isPostOfficeBox': isPostOfficeBox!,
        if (locality != null) 'locality': locality!,
        if (postalCode != null) 'postalCode': postalCode!,
        if (recipientName != null) 'recipientName': recipientName!,
        if (region != null) 'region': region!,
        if (streetAddress != null) 'streetAddress': streetAddress!,
      };
}

class TestOrderDeliveryDetails {
  /// The delivery address
  TestOrderAddress? address;

  /// Whether the order is scheduled delivery order.
  core.bool? isScheduledDelivery;

  /// The phone number of the person receiving the delivery.
  core.String? phoneNumber;

  TestOrderDeliveryDetails();

  TestOrderDeliveryDetails.fromJson(core.Map _json) {
    if (_json.containsKey('address')) {
      address = TestOrderAddress.fromJson(
          _json['address'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('isScheduledDelivery')) {
      isScheduledDelivery = _json['isScheduledDelivery'] as core.bool;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (address != null) 'address': address!.toJson(),
        if (isScheduledDelivery != null)
          'isScheduledDelivery': isScheduledDelivery!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
      };
}

class TestOrderLineItem {
  /// Product data from the time of the order placement.
  ///
  /// Required.
  TestOrderLineItemProduct? product;

  /// Number of items ordered.
  ///
  /// Required.
  core.int? quantityOrdered;

  /// Details of the return policy for the line item.
  ///
  /// Required.
  OrderLineItemReturnInfo? returnInfo;

  /// Details of the requested shipping for the line item.
  ///
  /// Required.
  OrderLineItemShippingDetails? shippingDetails;

  TestOrderLineItem();

  TestOrderLineItem.fromJson(core.Map _json) {
    if (_json.containsKey('product')) {
      product = TestOrderLineItemProduct.fromJson(
          _json['product'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('quantityOrdered')) {
      quantityOrdered = _json['quantityOrdered'] as core.int;
    }
    if (_json.containsKey('returnInfo')) {
      returnInfo = OrderLineItemReturnInfo.fromJson(
          _json['returnInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('shippingDetails')) {
      shippingDetails = OrderLineItemShippingDetails.fromJson(
          _json['shippingDetails'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (product != null) 'product': product!.toJson(),
        if (quantityOrdered != null) 'quantityOrdered': quantityOrdered!,
        if (returnInfo != null) 'returnInfo': returnInfo!.toJson(),
        if (shippingDetails != null)
          'shippingDetails': shippingDetails!.toJson(),
      };
}

class TestOrderLineItemProduct {
  /// Brand of the item.
  ///
  /// Required.
  core.String? brand;

  /// Condition or state of the item.
  ///
  /// Acceptable values are: - "`new`"
  ///
  /// Required.
  core.String? condition;

  /// The two-letter ISO 639-1 language code for the item.
  ///
  /// Acceptable values are: - "`en`" - "`fr`"
  ///
  /// Required.
  core.String? contentLanguage;

  /// Fees for the item.
  ///
  /// Optional.
  core.List<OrderLineItemProductFee>? fees;

  /// Global Trade Item Number (GTIN) of the item.
  ///
  /// Optional.
  core.String? gtin;

  /// URL of an image of the item.
  ///
  /// Required.
  core.String? imageLink;

  /// Shared identifier for all variants of the same product.
  ///
  /// Optional.
  core.String? itemGroupId;

  /// Manufacturer Part Number (MPN) of the item.
  ///
  /// Optional.
  core.String? mpn;

  /// An identifier of the item.
  ///
  /// Required.
  core.String? offerId;

  /// The price for the product.
  ///
  /// Tax is automatically calculated for orders where marketplace facilitator
  /// tax laws are applicable. Otherwise, tax settings from Merchant Center are
  /// applied.
  ///
  /// Required.
  Price? price;

  /// The CLDR territory // code of the target country of the product.
  ///
  /// Required.
  core.String? targetCountry;

  /// The title of the product.
  ///
  /// Required.
  core.String? title;

  /// Variant attributes for the item.
  ///
  /// Optional.
  core.List<OrderLineItemProductVariantAttribute>? variantAttributes;

  TestOrderLineItemProduct();

  TestOrderLineItemProduct.fromJson(core.Map _json) {
    if (_json.containsKey('brand')) {
      brand = _json['brand'] as core.String;
    }
    if (_json.containsKey('condition')) {
      condition = _json['condition'] as core.String;
    }
    if (_json.containsKey('contentLanguage')) {
      contentLanguage = _json['contentLanguage'] as core.String;
    }
    if (_json.containsKey('fees')) {
      fees = (_json['fees'] as core.List)
          .map<OrderLineItemProductFee>((value) =>
              OrderLineItemProductFee.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('gtin')) {
      gtin = _json['gtin'] as core.String;
    }
    if (_json.containsKey('imageLink')) {
      imageLink = _json['imageLink'] as core.String;
    }
    if (_json.containsKey('itemGroupId')) {
      itemGroupId = _json['itemGroupId'] as core.String;
    }
    if (_json.containsKey('mpn')) {
      mpn = _json['mpn'] as core.String;
    }
    if (_json.containsKey('offerId')) {
      offerId = _json['offerId'] as core.String;
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('targetCountry')) {
      targetCountry = _json['targetCountry'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('variantAttributes')) {
      variantAttributes = (_json['variantAttributes'] as core.List)
          .map<OrderLineItemProductVariantAttribute>((value) =>
              OrderLineItemProductVariantAttribute.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (brand != null) 'brand': brand!,
        if (condition != null) 'condition': condition!,
        if (contentLanguage != null) 'contentLanguage': contentLanguage!,
        if (fees != null) 'fees': fees!.map((value) => value.toJson()).toList(),
        if (gtin != null) 'gtin': gtin!,
        if (imageLink != null) 'imageLink': imageLink!,
        if (itemGroupId != null) 'itemGroupId': itemGroupId!,
        if (mpn != null) 'mpn': mpn!,
        if (offerId != null) 'offerId': offerId!,
        if (price != null) 'price': price!.toJson(),
        if (targetCountry != null) 'targetCountry': targetCountry!,
        if (title != null) 'title': title!,
        if (variantAttributes != null)
          'variantAttributes':
              variantAttributes!.map((value) => value.toJson()).toList(),
      };
}

class TestOrderPickupDetails {
  /// Code of the location defined by provider or merchant.
  ///
  /// Required.
  core.String? locationCode;

  /// Pickup location address.
  ///
  /// Required.
  TestOrderAddress? pickupLocationAddress;

  /// Pickup location type.
  ///
  /// Acceptable values are: - "`locker`" - "`store`" - "`curbside`"
  core.String? pickupLocationType;

  /// all pickup persons set by users.
  ///
  /// Required.
  core.List<TestOrderPickupDetailsPickupPerson>? pickupPersons;

  TestOrderPickupDetails();

  TestOrderPickupDetails.fromJson(core.Map _json) {
    if (_json.containsKey('locationCode')) {
      locationCode = _json['locationCode'] as core.String;
    }
    if (_json.containsKey('pickupLocationAddress')) {
      pickupLocationAddress = TestOrderAddress.fromJson(
          _json['pickupLocationAddress']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pickupLocationType')) {
      pickupLocationType = _json['pickupLocationType'] as core.String;
    }
    if (_json.containsKey('pickupPersons')) {
      pickupPersons = (_json['pickupPersons'] as core.List)
          .map<TestOrderPickupDetailsPickupPerson>((value) =>
              TestOrderPickupDetailsPickupPerson.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (locationCode != null) 'locationCode': locationCode!,
        if (pickupLocationAddress != null)
          'pickupLocationAddress': pickupLocationAddress!.toJson(),
        if (pickupLocationType != null)
          'pickupLocationType': pickupLocationType!,
        if (pickupPersons != null)
          'pickupPersons':
              pickupPersons!.map((value) => value.toJson()).toList(),
      };
}

class TestOrderPickupDetailsPickupPerson {
  /// Full name of the pickup person.
  ///
  /// Required.
  core.String? name;

  /// The phone number of the person picking up the items.
  ///
  /// Required.
  core.String? phoneNumber;

  TestOrderPickupDetailsPickupPerson();

  TestOrderPickupDetailsPickupPerson.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
      };
}

/// Represents a time zone from the
/// [IANA Time Zone Database](https://www.iana.org/time-zones).
class TimeZone {
  /// IANA Time Zone Database time zone, e.g. "America/New_York".
  core.String? id;

  /// IANA Time Zone Database version number, e.g. "2019a".
  ///
  /// Optional.
  core.String? version;

  TimeZone();

  TimeZone.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (version != null) 'version': version!,
      };
}

class TransitTable {
  /// A list of postal group names.
  ///
  /// The last value can be `"all other locations"`. Example: `["zone 1", "zone
  /// 2", "all other locations"]`. The referred postal code groups must match
  /// the delivery country of the service.
  core.List<core.String>? postalCodeGroupNames;
  core.List<TransitTableTransitTimeRow>? rows;

  /// A list of transit time labels.
  ///
  /// The last value can be `"all other labels"`. Example: `["food",
  /// "electronics", "all other labels"]`.
  core.List<core.String>? transitTimeLabels;

  TransitTable();

  TransitTable.fromJson(core.Map _json) {
    if (_json.containsKey('postalCodeGroupNames')) {
      postalCodeGroupNames = (_json['postalCodeGroupNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('rows')) {
      rows = (_json['rows'] as core.List)
          .map<TransitTableTransitTimeRow>((value) =>
              TransitTableTransitTimeRow.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('transitTimeLabels')) {
      transitTimeLabels = (_json['transitTimeLabels'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (postalCodeGroupNames != null)
          'postalCodeGroupNames': postalCodeGroupNames!,
        if (rows != null) 'rows': rows!.map((value) => value.toJson()).toList(),
        if (transitTimeLabels != null) 'transitTimeLabels': transitTimeLabels!,
      };
}

class TransitTableTransitTimeRow {
  core.List<TransitTableTransitTimeRowTransitTimeValue>? values;

  TransitTableTransitTimeRow();

  TransitTableTransitTimeRow.fromJson(core.Map _json) {
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<TransitTableTransitTimeRowTransitTimeValue>((value) =>
              TransitTableTransitTimeRowTransitTimeValue.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (values != null)
          'values': values!.map((value) => value.toJson()).toList(),
      };
}

class TransitTableTransitTimeRowTransitTimeValue {
  /// Must be greater than or equal to `minTransitTimeInDays`.
  core.int? maxTransitTimeInDays;

  /// Transit time range (min-max) in business days.
  ///
  /// 0 means same day delivery, 1 means next day delivery.
  core.int? minTransitTimeInDays;

  TransitTableTransitTimeRowTransitTimeValue();

  TransitTableTransitTimeRowTransitTimeValue.fromJson(core.Map _json) {
    if (_json.containsKey('maxTransitTimeInDays')) {
      maxTransitTimeInDays = _json['maxTransitTimeInDays'] as core.int;
    }
    if (_json.containsKey('minTransitTimeInDays')) {
      minTransitTimeInDays = _json['minTransitTimeInDays'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maxTransitTimeInDays != null)
          'maxTransitTimeInDays': maxTransitTimeInDays!,
        if (minTransitTimeInDays != null)
          'minTransitTimeInDays': minTransitTimeInDays!,
      };
}

class UnitInvoice {
  /// Additional charges for a unit, e.g. shipping costs.
  core.List<UnitInvoiceAdditionalCharge>? additionalCharges;

  /// Pre-tax or post-tax price of the unit depending on the locality of the
  /// order.
  ///
  /// Required.
  Price? unitPrice;

  /// Tax amounts to apply to the unit price.
  core.List<UnitInvoiceTaxLine>? unitPriceTaxes;

  UnitInvoice();

  UnitInvoice.fromJson(core.Map _json) {
    if (_json.containsKey('additionalCharges')) {
      additionalCharges = (_json['additionalCharges'] as core.List)
          .map<UnitInvoiceAdditionalCharge>((value) =>
              UnitInvoiceAdditionalCharge.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('unitPrice')) {
      unitPrice = Price.fromJson(
          _json['unitPrice'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unitPriceTaxes')) {
      unitPriceTaxes = (_json['unitPriceTaxes'] as core.List)
          .map<UnitInvoiceTaxLine>((value) => UnitInvoiceTaxLine.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalCharges != null)
          'additionalCharges':
              additionalCharges!.map((value) => value.toJson()).toList(),
        if (unitPrice != null) 'unitPrice': unitPrice!.toJson(),
        if (unitPriceTaxes != null)
          'unitPriceTaxes':
              unitPriceTaxes!.map((value) => value.toJson()).toList(),
      };
}

class UnitInvoiceAdditionalCharge {
  /// Amount of the additional charge.
  ///
  /// Required.
  Amount? additionalChargeAmount;

  /// Type of the additional charge.
  ///
  /// Acceptable values are: - "`shipping`"
  ///
  /// Required.
  core.String? type;

  UnitInvoiceAdditionalCharge();

  UnitInvoiceAdditionalCharge.fromJson(core.Map _json) {
    if (_json.containsKey('additionalChargeAmount')) {
      additionalChargeAmount = Amount.fromJson(_json['additionalChargeAmount']
          as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalChargeAmount != null)
          'additionalChargeAmount': additionalChargeAmount!.toJson(),
        if (type != null) 'type': type!,
      };
}

class UnitInvoiceTaxLine {
  /// Tax amount for the tax type.
  ///
  /// Required.
  Price? taxAmount;

  /// Optional name of the tax type.
  ///
  /// This should only be provided if `taxType` is `otherFeeTax`.
  core.String? taxName;

  /// Type of the tax.
  ///
  /// Acceptable values are: - "`otherFee`" - "`otherFeeTax`" - "`sales`"
  ///
  /// Required.
  core.String? taxType;

  UnitInvoiceTaxLine();

  UnitInvoiceTaxLine.fromJson(core.Map _json) {
    if (_json.containsKey('taxAmount')) {
      taxAmount = Price.fromJson(
          _json['taxAmount'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('taxName')) {
      taxName = _json['taxName'] as core.String;
    }
    if (_json.containsKey('taxType')) {
      taxType = _json['taxType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (taxAmount != null) 'taxAmount': taxAmount!.toJson(),
        if (taxName != null) 'taxName': taxName!,
        if (taxType != null) 'taxType': taxType!,
      };
}

/// The single value of a rate group or the value of a rate group table's cell.
///
/// Exactly one of `noShipping`, `flatRate`, `pricePercentage`,
/// `carrierRateName`, `subtableName` must be set.
class Value {
  /// The name of a carrier rate referring to a carrier rate defined in the same
  /// rate group.
  ///
  /// Can only be set if all other fields are not set.
  core.String? carrierRateName;

  /// A flat rate.
  ///
  /// Can only be set if all other fields are not set.
  Price? flatRate;

  /// If true, then the product can't ship.
  ///
  /// Must be true when set, can only be set if all other fields are not set.
  core.bool? noShipping;

  /// A percentage of the price represented as a number in decimal notation
  /// (e.g., `"5.4"`).
  ///
  /// Can only be set if all other fields are not set.
  core.String? pricePercentage;

  /// The name of a subtable.
  ///
  /// Can only be set in table cells (i.e., not for single values), and only if
  /// all other fields are not set.
  core.String? subtableName;

  Value();

  Value.fromJson(core.Map _json) {
    if (_json.containsKey('carrierRateName')) {
      carrierRateName = _json['carrierRateName'] as core.String;
    }
    if (_json.containsKey('flatRate')) {
      flatRate = Price.fromJson(
          _json['flatRate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('noShipping')) {
      noShipping = _json['noShipping'] as core.bool;
    }
    if (_json.containsKey('pricePercentage')) {
      pricePercentage = _json['pricePercentage'] as core.String;
    }
    if (_json.containsKey('subtableName')) {
      subtableName = _json['subtableName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrierRateName != null) 'carrierRateName': carrierRateName!,
        if (flatRate != null) 'flatRate': flatRate!.toJson(),
        if (noShipping != null) 'noShipping': noShipping!,
        if (pricePercentage != null) 'pricePercentage': pricePercentage!,
        if (subtableName != null) 'subtableName': subtableName!,
      };
}

class WarehouseBasedDeliveryTime {
  /// Carrier, such as `"UPS"` or `"Fedex"`.
  ///
  /// The list of supported carriers can be retrieved via the
  /// `listSupportedCarriers` method.
  ///
  /// Required.
  core.String? carrier;

  /// Carrier service, such as `"ground"` or `"2 days"`.
  ///
  /// The list of supported services for a carrier can be retrieved via the
  /// `listSupportedCarriers` method. The name of the service must be in the
  /// eddSupportedServices list.
  ///
  /// Required.
  core.String? carrierService;

  /// Shipping origin's state.
  ///
  /// Required.
  core.String? originAdministrativeArea;

  /// Shipping origin's city.
  ///
  /// Required.
  core.String? originCity;

  /// Shipping origin's country represented as a
  /// [CLDR territory code](http://www.unicode.org/repos/cldr/tags/latest/common/main/en.xml).
  ///
  /// Required.
  core.String? originCountry;

  /// Shipping origin.
  ///
  /// Required.
  core.String? originPostalCode;

  /// Shipping origin's street address.
  core.String? originStreetAddress;

  WarehouseBasedDeliveryTime();

  WarehouseBasedDeliveryTime.fromJson(core.Map _json) {
    if (_json.containsKey('carrier')) {
      carrier = _json['carrier'] as core.String;
    }
    if (_json.containsKey('carrierService')) {
      carrierService = _json['carrierService'] as core.String;
    }
    if (_json.containsKey('originAdministrativeArea')) {
      originAdministrativeArea =
          _json['originAdministrativeArea'] as core.String;
    }
    if (_json.containsKey('originCity')) {
      originCity = _json['originCity'] as core.String;
    }
    if (_json.containsKey('originCountry')) {
      originCountry = _json['originCountry'] as core.String;
    }
    if (_json.containsKey('originPostalCode')) {
      originPostalCode = _json['originPostalCode'] as core.String;
    }
    if (_json.containsKey('originStreetAddress')) {
      originStreetAddress = _json['originStreetAddress'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrier != null) 'carrier': carrier!,
        if (carrierService != null) 'carrierService': carrierService!,
        if (originAdministrativeArea != null)
          'originAdministrativeArea': originAdministrativeArea!,
        if (originCity != null) 'originCity': originCity!,
        if (originCountry != null) 'originCountry': originCountry!,
        if (originPostalCode != null) 'originPostalCode': originPostalCode!,
        if (originStreetAddress != null)
          'originStreetAddress': originStreetAddress!,
      };
}

class Weight {
  /// The weight unit.
  ///
  /// Acceptable values are: - "`kg`" - "`lb`"
  ///
  /// Required.
  core.String? unit;

  /// The weight represented as a number.
  ///
  /// Required.
  core.String? value;

  Weight();

  Weight.fromJson(core.Map _json) {
    if (_json.containsKey('unit')) {
      unit = _json['unit'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (unit != null) 'unit': unit!,
        if (value != null) 'value': value!,
      };
}

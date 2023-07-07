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

/// Ad Exchange Buyer API - v1.4
///
/// Accesses your bidding-account information, submits creatives for validation,
/// finds available direct deals, and retrieves performance reports.
///
/// For more information, see
/// <https://developers.google.com/ad-exchange/buyer-rest>
///
/// Create an instance of [AdExchangeBuyerApi] to access these resources:
///
/// - [AccountsResource]
/// - [BillingInfoResource]
/// - [BudgetResource]
/// - [CreativesResource]
/// - [MarketplacedealsResource]
/// - [MarketplacenotesResource]
/// - [MarketplaceprivateauctionResource]
/// - [PerformanceReportResource]
/// - [PretargetingConfigResource]
/// - [ProductsResource]
/// - [ProposalsResource]
/// - [PubprofilesResource]
library adexchangebuyer.v1_4;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Accesses your bidding-account information, submits creatives for validation,
/// finds available direct deals, and retrieves performance reports.
class AdExchangeBuyerApi {
  /// Manage your Ad Exchange buyer account configuration
  static const adexchangeBuyerScope =
      'https://www.googleapis.com/auth/adexchange.buyer';

  final commons.ApiRequester _requester;

  AccountsResource get accounts => AccountsResource(_requester);
  BillingInfoResource get billingInfo => BillingInfoResource(_requester);
  BudgetResource get budget => BudgetResource(_requester);
  CreativesResource get creatives => CreativesResource(_requester);
  MarketplacedealsResource get marketplacedeals =>
      MarketplacedealsResource(_requester);
  MarketplacenotesResource get marketplacenotes =>
      MarketplacenotesResource(_requester);
  MarketplaceprivateauctionResource get marketplaceprivateauction =>
      MarketplaceprivateauctionResource(_requester);
  PerformanceReportResource get performanceReport =>
      PerformanceReportResource(_requester);
  PretargetingConfigResource get pretargetingConfig =>
      PretargetingConfigResource(_requester);
  ProductsResource get products => ProductsResource(_requester);
  ProposalsResource get proposals => ProposalsResource(_requester);
  PubprofilesResource get pubprofiles => PubprofilesResource(_requester);

  AdExchangeBuyerApi(http.Client client,
      {core.String rootUrl = 'https://www.googleapis.com/',
      core.String servicePath = 'adexchangebuyer/v1.4/'})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AccountsResource {
  final commons.ApiRequester _requester;

  AccountsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one account by ID.
  ///
  /// Request parameters:
  ///
  /// [id] - The account id
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
    core.int id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' + commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Account.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the authenticated user's list of accounts.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AccountsList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AccountsList> list({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'accounts';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AccountsList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing account.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [id] - The account id
  ///
  /// [confirmUnsafeAccountChange] - Confirmation for erasing bidder and cookie
  /// matching urls.
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
  async.Future<Account> patch(
    Account request,
    core.int id, {
    core.bool? confirmUnsafeAccountChange,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (confirmUnsafeAccountChange != null)
        'confirmUnsafeAccountChange': ['${confirmUnsafeAccountChange}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' + commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Account.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [id] - The account id
  ///
  /// [confirmUnsafeAccountChange] - Confirmation for erasing bidder and cookie
  /// matching urls.
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
    core.int id, {
    core.bool? confirmUnsafeAccountChange,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (confirmUnsafeAccountChange != null)
        'confirmUnsafeAccountChange': ['${confirmUnsafeAccountChange}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' + commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Account.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class BillingInfoResource {
  final commons.ApiRequester _requester;

  BillingInfoResource(commons.ApiRequester client) : _requester = client;

  /// Returns the billing information for one account specified by account ID.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The account id.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BillingInfo].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BillingInfo> get(
    core.int accountId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'billinginfo/' + commons.escapeVariable('$accountId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return BillingInfo.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of billing information for all accounts of the
  /// authenticated user.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BillingInfoList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BillingInfoList> list({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'billinginfo';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return BillingInfoList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class BudgetResource {
  final commons.ApiRequester _requester;

  BudgetResource(commons.ApiRequester client) : _requester = client;

  /// Returns the budget information for the adgroup specified by the accountId
  /// and billingId.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The account id to get the budget information for.
  ///
  /// [billingId] - The billing id to get the budget information for.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Budget].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Budget> get(
    core.String accountId,
    core.String billingId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'billinginfo/' +
        commons.escapeVariable('$accountId') +
        '/' +
        commons.escapeVariable('$billingId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Budget.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the budget amount for the budget of the adgroup specified by the
  /// accountId and billingId, with the budget amount in the request.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The account id associated with the budget being updated.
  ///
  /// [billingId] - The billing id associated with the budget being updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Budget].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Budget> patch(
    Budget request,
    core.String accountId,
    core.String billingId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'billinginfo/' +
        commons.escapeVariable('$accountId') +
        '/' +
        commons.escapeVariable('$billingId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Budget.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the budget amount for the budget of the adgroup specified by the
  /// accountId and billingId, with the budget amount in the request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The account id associated with the budget being updated.
  ///
  /// [billingId] - The billing id associated with the budget being updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Budget].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Budget> update(
    Budget request,
    core.String accountId,
    core.String billingId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'billinginfo/' +
        commons.escapeVariable('$accountId') +
        '/' +
        commons.escapeVariable('$billingId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Budget.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class CreativesResource {
  final commons.ApiRequester _requester;

  CreativesResource(commons.ApiRequester client) : _requester = client;

  /// Add a deal id association for the creative.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The id for the account that will serve this creative.
  ///
  /// [buyerCreativeId] - The buyer-specific id for this creative.
  ///
  /// [dealId] - The id of the deal id to associate with this creative.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> addDeal(
    core.int accountId,
    core.String buyerCreativeId,
    core.String dealId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'creatives/' +
        commons.escapeVariable('$accountId') +
        '/' +
        commons.escapeVariable('$buyerCreativeId') +
        '/addDeal/' +
        commons.escapeVariable('$dealId');

    await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets the status for a single creative.
  ///
  /// A creative will be available 30-40 minutes after submission.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The id for the account that will serve this creative.
  ///
  /// [buyerCreativeId] - The buyer-specific id for this creative.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Creative].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Creative> get(
    core.int accountId,
    core.String buyerCreativeId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'creatives/' +
        commons.escapeVariable('$accountId') +
        '/' +
        commons.escapeVariable('$buyerCreativeId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Creative.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Submit a new creative.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Creative].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Creative> insert(
    Creative request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'creatives';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Creative.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of the authenticated user's active creatives.
  ///
  /// A creative will be available 30-40 minutes after submission.
  ///
  /// Request parameters:
  ///
  /// [accountId] - When specified, only creatives for the given account ids are
  /// returned.
  ///
  /// [buyerCreativeId] - When specified, only creatives for the given buyer
  /// creative ids are returned.
  ///
  /// [dealsStatusFilter] - When specified, only creatives having the given
  /// deals status are returned.
  /// Possible string values are:
  /// - "approved" : Creatives which have been approved for serving on deals.
  /// - "conditionally_approved" : Creatives which have been conditionally
  /// approved for serving on deals.
  /// - "disapproved" : Creatives which have been disapproved for serving on
  /// deals.
  /// - "not_checked" : Creatives whose deals status is not yet checked.
  ///
  /// [maxResults] - Maximum number of entries returned on one result page. If
  /// not set, the default is 100. Optional.
  /// Value must be between "1" and "1000".
  ///
  /// [openAuctionStatusFilter] - When specified, only creatives having the
  /// given open auction status are returned.
  /// Possible string values are:
  /// - "approved" : Creatives which have been approved for serving on the open
  /// auction.
  /// - "conditionally_approved" : Creatives which have been conditionally
  /// approved for serving on the open auction.
  /// - "disapproved" : Creatives which have been disapproved for serving on the
  /// open auction.
  /// - "not_checked" : Creatives whose open auction status is not yet checked.
  ///
  /// [pageToken] - A continuation token, used to page through ad clients. To
  /// retrieve the next page, set this parameter to the value of "nextPageToken"
  /// from the previous response. Optional.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativesList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativesList> list({
    core.List<core.int>? accountId,
    core.List<core.String>? buyerCreativeId,
    core.String? dealsStatusFilter,
    core.int? maxResults,
    core.String? openAuctionStatusFilter,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (accountId != null)
        'accountId': accountId.map((item) => '${item}').toList(),
      if (buyerCreativeId != null) 'buyerCreativeId': buyerCreativeId,
      if (dealsStatusFilter != null) 'dealsStatusFilter': [dealsStatusFilter],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (openAuctionStatusFilter != null)
        'openAuctionStatusFilter': [openAuctionStatusFilter],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'creatives';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CreativesList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the external deal ids associated with the creative.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The id for the account that will serve this creative.
  ///
  /// [buyerCreativeId] - The buyer-specific id for this creative.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreativeDealIds].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreativeDealIds> listDeals(
    core.int accountId,
    core.String buyerCreativeId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'creatives/' +
        commons.escapeVariable('$accountId') +
        '/' +
        commons.escapeVariable('$buyerCreativeId') +
        '/listDeals';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CreativeDealIds.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Remove a deal id associated with the creative.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The id for the account that will serve this creative.
  ///
  /// [buyerCreativeId] - The buyer-specific id for this creative.
  ///
  /// [dealId] - The id of the deal id to disassociate with this creative.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> removeDeal(
    core.int accountId,
    core.String buyerCreativeId,
    core.String dealId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'creatives/' +
        commons.escapeVariable('$accountId') +
        '/' +
        commons.escapeVariable('$buyerCreativeId') +
        '/removeDeal/' +
        commons.escapeVariable('$dealId');

    await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }
}

class MarketplacedealsResource {
  final commons.ApiRequester _requester;

  MarketplacedealsResource(commons.ApiRequester client) : _requester = client;

  /// Delete the specified deals from the proposal
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [proposalId] - The proposalId to delete deals from.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DeleteOrderDealsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DeleteOrderDealsResponse> delete(
    DeleteOrderDealsRequest request,
    core.String proposalId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'proposals/' + commons.escapeVariable('$proposalId') + '/deals/delete';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DeleteOrderDealsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Add new deals for the specified proposal
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [proposalId] - proposalId for which deals need to be added.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AddOrderDealsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AddOrderDealsResponse> insert(
    AddOrderDealsRequest request,
    core.String proposalId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'proposals/' + commons.escapeVariable('$proposalId') + '/deals/insert';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AddOrderDealsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List all the deals for a given proposal
  ///
  /// Request parameters:
  ///
  /// [proposalId] - The proposalId to get deals for. To search across all
  /// proposals specify order_id = '-' as part of the URL.
  ///
  /// [pqlQuery] - Query string to retrieve specific deals.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetOrderDealsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetOrderDealsResponse> list(
    core.String proposalId, {
    core.String? pqlQuery,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pqlQuery != null) 'pqlQuery': [pqlQuery],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'proposals/' + commons.escapeVariable('$proposalId') + '/deals';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetOrderDealsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Replaces all the deals in the proposal with the passed in deals
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [proposalId] - The proposalId to edit deals on.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EditAllOrderDealsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EditAllOrderDealsResponse> update(
    EditAllOrderDealsRequest request,
    core.String proposalId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'proposals/' + commons.escapeVariable('$proposalId') + '/deals/update';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return EditAllOrderDealsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MarketplacenotesResource {
  final commons.ApiRequester _requester;

  MarketplacenotesResource(commons.ApiRequester client) : _requester = client;

  /// Add notes to the proposal
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [proposalId] - The proposalId to add notes for.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AddOrderNotesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AddOrderNotesResponse> insert(
    AddOrderNotesRequest request,
    core.String proposalId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'proposals/' + commons.escapeVariable('$proposalId') + '/notes/insert';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AddOrderNotesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Get all the notes associated with a proposal
  ///
  /// Request parameters:
  ///
  /// [proposalId] - The proposalId to get notes for. To search across all
  /// proposals specify order_id = '-' as part of the URL.
  ///
  /// [pqlQuery] - Query string to retrieve specific notes. To search the text
  /// contents of notes, please use syntax like "WHERE note.note = "foo" or
  /// "WHERE note.note LIKE "%bar%"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetOrderNotesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetOrderNotesResponse> list(
    core.String proposalId, {
    core.String? pqlQuery,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pqlQuery != null) 'pqlQuery': [pqlQuery],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'proposals/' + commons.escapeVariable('$proposalId') + '/notes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetOrderNotesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MarketplaceprivateauctionResource {
  final commons.ApiRequester _requester;

  MarketplaceprivateauctionResource(commons.ApiRequester client)
      : _requester = client;

  /// Update a given private auction proposal
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [privateAuctionId] - The private auction id to be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> updateproposal(
    UpdatePrivateAuctionProposalRequest request,
    core.String privateAuctionId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'privateauction/' +
        commons.escapeVariable('$privateAuctionId') +
        '/updateproposal';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }
}

class PerformanceReportResource {
  final commons.ApiRequester _requester;

  PerformanceReportResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves the authenticated user's list of performance metrics.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The account id to get the reports.
  ///
  /// [endDateTime] - The end time of the report in ISO 8601 timestamp format
  /// using UTC.
  ///
  /// [startDateTime] - The start time of the report in ISO 8601 timestamp
  /// format using UTC.
  ///
  /// [maxResults] - Maximum number of entries returned on one result page. If
  /// not set, the default is 100. Optional.
  /// Value must be between "1" and "1000".
  ///
  /// [pageToken] - A continuation token, used to page through performance
  /// reports. To retrieve the next page, set this parameter to the value of
  /// "nextPageToken" from the previous response. Optional.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PerformanceReportList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PerformanceReportList> list(
    core.String accountId,
    core.String endDateTime,
    core.String startDateTime, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'accountId': [accountId],
      'endDateTime': [endDateTime],
      'startDateTime': [startDateTime],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'performancereport';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PerformanceReportList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PretargetingConfigResource {
  final commons.ApiRequester _requester;

  PretargetingConfigResource(commons.ApiRequester client) : _requester = client;

  /// Deletes an existing pretargeting config.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The account id to delete the pretargeting config for.
  ///
  /// [configId] - The specific id of the configuration to delete.
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
    core.String configId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'pretargetingconfigs/' +
        commons.escapeVariable('$accountId') +
        '/' +
        commons.escapeVariable('$configId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets a specific pretargeting configuration
  ///
  /// Request parameters:
  ///
  /// [accountId] - The account id to get the pretargeting config for.
  ///
  /// [configId] - The specific id of the configuration to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PretargetingConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PretargetingConfig> get(
    core.String accountId,
    core.String configId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'pretargetingconfigs/' +
        commons.escapeVariable('$accountId') +
        '/' +
        commons.escapeVariable('$configId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new pretargeting configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The account id to insert the pretargeting config for.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PretargetingConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PretargetingConfig> insert(
    PretargetingConfig request,
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'pretargetingconfigs/' + commons.escapeVariable('$accountId');

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of the authenticated user's pretargeting configurations.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The account id to get the pretargeting configs for.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PretargetingConfigList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PretargetingConfigList> list(
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'pretargetingconfigs/' + commons.escapeVariable('$accountId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PretargetingConfigList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing pretargeting config.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The account id to update the pretargeting config for.
  ///
  /// [configId] - The specific id of the configuration to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PretargetingConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PretargetingConfig> patch(
    PretargetingConfig request,
    core.String accountId,
    core.String configId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'pretargetingconfigs/' +
        commons.escapeVariable('$accountId') +
        '/' +
        commons.escapeVariable('$configId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing pretargeting config.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The account id to update the pretargeting config for.
  ///
  /// [configId] - The specific id of the configuration to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PretargetingConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PretargetingConfig> update(
    PretargetingConfig request,
    core.String accountId,
    core.String configId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'pretargetingconfigs/' +
        commons.escapeVariable('$accountId') +
        '/' +
        commons.escapeVariable('$configId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProductsResource {
  final commons.ApiRequester _requester;

  ProductsResource(commons.ApiRequester client) : _requester = client;

  /// Gets the requested product by id.
  ///
  /// Request parameters:
  ///
  /// [productId] - The id for the product to get the head revision for.
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
    core.String productId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'products/' + commons.escapeVariable('$productId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Product.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the requested product.
  ///
  /// Request parameters:
  ///
  /// [pqlQuery] - The pql query used to query for products.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetOffersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetOffersResponse> search({
    core.String? pqlQuery,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pqlQuery != null) 'pqlQuery': [pqlQuery],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'products/search';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetOffersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProposalsResource {
  final commons.ApiRequester _requester;

  ProposalsResource(commons.ApiRequester client) : _requester = client;

  /// Get a proposal given its id
  ///
  /// Request parameters:
  ///
  /// [proposalId] - Id of the proposal to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Proposal].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Proposal> get(
    core.String proposalId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'proposals/' + commons.escapeVariable('$proposalId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Proposal.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Create the given list of proposals
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CreateOrdersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CreateOrdersResponse> insert(
    CreateOrdersRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'proposals/insert';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CreateOrdersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update the given proposal.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [proposalId] - The proposal id to update.
  ///
  /// [revisionNumber] - The last known revision number to update. If the head
  /// revision in the marketplace database has since changed, an error will be
  /// thrown. The caller should then fetch the latest proposal at head revision
  /// and retry the update at that revision.
  ///
  /// [updateAction] - The proposed action to take on the proposal. This field
  /// is required and it must be set when updating a proposal.
  /// Possible string values are:
  /// - "accept"
  /// - "cancel"
  /// - "propose"
  /// - "proposeAndAccept"
  /// - "unknownAction"
  /// - "updateNonTerms"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Proposal].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Proposal> patch(
    Proposal request,
    core.String proposalId,
    core.String revisionNumber,
    core.String updateAction, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'proposals/' +
        commons.escapeVariable('$proposalId') +
        '/' +
        commons.escapeVariable('$revisionNumber') +
        '/' +
        commons.escapeVariable('$updateAction');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Proposal.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Search for proposals using pql query
  ///
  /// Request parameters:
  ///
  /// [pqlQuery] - Query string to retrieve specific proposals.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetOrdersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetOrdersResponse> search({
    core.String? pqlQuery,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pqlQuery != null) 'pqlQuery': [pqlQuery],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'proposals/search';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetOrdersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update the given proposal to indicate that setup has been completed.
  ///
  /// Request parameters:
  ///
  /// [proposalId] - The proposal id for which the setup is complete
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> setupcomplete(
    core.String proposalId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'proposals/' + commons.escapeVariable('$proposalId') + '/setupcomplete';

    await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Update the given proposal
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [proposalId] - The proposal id to update.
  ///
  /// [revisionNumber] - The last known revision number to update. If the head
  /// revision in the marketplace database has since changed, an error will be
  /// thrown. The caller should then fetch the latest proposal at head revision
  /// and retry the update at that revision.
  ///
  /// [updateAction] - The proposed action to take on the proposal. This field
  /// is required and it must be set when updating a proposal.
  /// Possible string values are:
  /// - "accept"
  /// - "cancel"
  /// - "propose"
  /// - "proposeAndAccept"
  /// - "unknownAction"
  /// - "updateNonTerms"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Proposal].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Proposal> update(
    Proposal request,
    core.String proposalId,
    core.String revisionNumber,
    core.String updateAction, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'proposals/' +
        commons.escapeVariable('$proposalId') +
        '/' +
        commons.escapeVariable('$revisionNumber') +
        '/' +
        commons.escapeVariable('$updateAction');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Proposal.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class PubprofilesResource {
  final commons.ApiRequester _requester;

  PubprofilesResource(commons.ApiRequester client) : _requester = client;

  /// Gets the requested publisher profile(s) by publisher accountId.
  ///
  /// Request parameters:
  ///
  /// [accountId] - The accountId of the publisher to get profiles for.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetPublisherProfilesByAccountIdResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetPublisherProfilesByAccountIdResponse> list(
    core.int accountId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'publisher/' + commons.escapeVariable('$accountId') + '/profiles';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetPublisherProfilesByAccountIdResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccountBidderLocation {
  /// The protocol that the bidder endpoint is using.
  ///
  /// OpenRTB protocols with prefix PROTOCOL_OPENRTB_PROTOBUF use proto buffer,
  /// otherwise use JSON. Allowed values:
  /// - PROTOCOL_ADX
  /// - PROTOCOL_OPENRTB_2_2
  /// - PROTOCOL_OPENRTB_2_3
  /// - PROTOCOL_OPENRTB_2_4
  /// - PROTOCOL_OPENRTB_2_5
  /// - PROTOCOL_OPENRTB_PROTOBUF_2_3
  /// - PROTOCOL_OPENRTB_PROTOBUF_2_4
  /// - PROTOCOL_OPENRTB_PROTOBUF_2_5
  core.String? bidProtocol;

  /// The maximum queries per second the Ad Exchange will send.
  core.int? maximumQps;

  /// The geographical region the Ad Exchange should send requests from.
  ///
  /// Only used by some quota systems, but always setting the value is
  /// recommended. Allowed values:
  /// - ASIA
  /// - EUROPE
  /// - US_EAST
  /// - US_WEST
  core.String? region;

  /// The URL to which the Ad Exchange will send bid requests.
  core.String? url;

  AccountBidderLocation();

  AccountBidderLocation.fromJson(core.Map _json) {
    if (_json.containsKey('bidProtocol')) {
      bidProtocol = _json['bidProtocol'] as core.String;
    }
    if (_json.containsKey('maximumQps')) {
      maximumQps = _json['maximumQps'] as core.int;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bidProtocol != null) 'bidProtocol': bidProtocol!,
        if (maximumQps != null) 'maximumQps': maximumQps!,
        if (region != null) 'region': region!,
        if (url != null) 'url': url!,
      };
}

/// Configuration data for an Ad Exchange buyer account.
class Account {
  /// When this is false, bid requests that include a deal ID for a private
  /// auction or preferred deal are always sent to your bidder.
  ///
  /// When true, all active pretargeting configs will be applied to private
  /// auctions and preferred deals. Programmatic Guaranteed deals (when enabled)
  /// are always sent to your bidder.
  core.bool? applyPretargetingToNonGuaranteedDeals;

  /// Your bidder locations that have distinct URLs.
  core.List<AccountBidderLocation>? bidderLocation;

  /// The nid parameter value used in cookie match requests.
  ///
  /// Please contact your technical account manager if you need to change this.
  core.String? cookieMatchingNid;

  /// The base URL used in cookie match requests.
  core.String? cookieMatchingUrl;

  /// Account id.
  core.int? id;

  /// Resource type.
  core.String? kind;

  /// The maximum number of active creatives that an account can have, where a
  /// creative is active if it was inserted or bid with in the last 30 days.
  ///
  /// Please contact your technical account manager if you need to change this.
  core.int? maximumActiveCreatives;

  /// The sum of all bidderLocation.maximumQps values cannot exceed this.
  ///
  /// Please contact your technical account manager if you need to change this.
  core.int? maximumTotalQps;

  /// The number of creatives that this account inserted or bid with in the last
  /// 30 days.
  core.int? numberActiveCreatives;

  Account();

  Account.fromJson(core.Map _json) {
    if (_json.containsKey('applyPretargetingToNonGuaranteedDeals')) {
      applyPretargetingToNonGuaranteedDeals =
          _json['applyPretargetingToNonGuaranteedDeals'] as core.bool;
    }
    if (_json.containsKey('bidderLocation')) {
      bidderLocation = (_json['bidderLocation'] as core.List)
          .map<AccountBidderLocation>((value) => AccountBidderLocation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('cookieMatchingNid')) {
      cookieMatchingNid = _json['cookieMatchingNid'] as core.String;
    }
    if (_json.containsKey('cookieMatchingUrl')) {
      cookieMatchingUrl = _json['cookieMatchingUrl'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.int;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('maximumActiveCreatives')) {
      maximumActiveCreatives = _json['maximumActiveCreatives'] as core.int;
    }
    if (_json.containsKey('maximumTotalQps')) {
      maximumTotalQps = _json['maximumTotalQps'] as core.int;
    }
    if (_json.containsKey('numberActiveCreatives')) {
      numberActiveCreatives = _json['numberActiveCreatives'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applyPretargetingToNonGuaranteedDeals != null)
          'applyPretargetingToNonGuaranteedDeals':
              applyPretargetingToNonGuaranteedDeals!,
        if (bidderLocation != null)
          'bidderLocation':
              bidderLocation!.map((value) => value.toJson()).toList(),
        if (cookieMatchingNid != null) 'cookieMatchingNid': cookieMatchingNid!,
        if (cookieMatchingUrl != null) 'cookieMatchingUrl': cookieMatchingUrl!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (maximumActiveCreatives != null)
          'maximumActiveCreatives': maximumActiveCreatives!,
        if (maximumTotalQps != null) 'maximumTotalQps': maximumTotalQps!,
        if (numberActiveCreatives != null)
          'numberActiveCreatives': numberActiveCreatives!,
      };
}

/// An account feed lists Ad Exchange buyer accounts that the user has access
/// to.
///
/// Each entry in the feed corresponds to a single buyer account.
class AccountsList {
  /// A list of accounts.
  core.List<Account>? items;

  /// Resource type.
  core.String? kind;

  AccountsList();

  AccountsList.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Account>((value) =>
              Account.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class AddOrderDealsRequest {
  /// The list of deals to add
  core.List<MarketplaceDeal>? deals;

  /// The last known proposal revision number.
  core.String? proposalRevisionNumber;

  /// Indicates an optional action to take on the proposal
  core.String? updateAction;

  AddOrderDealsRequest();

  AddOrderDealsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('deals')) {
      deals = (_json['deals'] as core.List)
          .map<MarketplaceDeal>((value) => MarketplaceDeal.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('proposalRevisionNumber')) {
      proposalRevisionNumber = _json['proposalRevisionNumber'] as core.String;
    }
    if (_json.containsKey('updateAction')) {
      updateAction = _json['updateAction'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deals != null)
          'deals': deals!.map((value) => value.toJson()).toList(),
        if (proposalRevisionNumber != null)
          'proposalRevisionNumber': proposalRevisionNumber!,
        if (updateAction != null) 'updateAction': updateAction!,
      };
}

class AddOrderDealsResponse {
  /// List of deals added (in the same proposal as passed in the request)
  core.List<MarketplaceDeal>? deals;

  /// The updated revision number for the proposal.
  core.String? proposalRevisionNumber;

  AddOrderDealsResponse();

  AddOrderDealsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('deals')) {
      deals = (_json['deals'] as core.List)
          .map<MarketplaceDeal>((value) => MarketplaceDeal.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('proposalRevisionNumber')) {
      proposalRevisionNumber = _json['proposalRevisionNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deals != null)
          'deals': deals!.map((value) => value.toJson()).toList(),
        if (proposalRevisionNumber != null)
          'proposalRevisionNumber': proposalRevisionNumber!,
      };
}

class AddOrderNotesRequest {
  /// The list of notes to add.
  core.List<MarketplaceNote>? notes;

  AddOrderNotesRequest();

  AddOrderNotesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('notes')) {
      notes = (_json['notes'] as core.List)
          .map<MarketplaceNote>((value) => MarketplaceNote.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (notes != null)
          'notes': notes!.map((value) => value.toJson()).toList(),
      };
}

class AddOrderNotesResponse {
  core.List<MarketplaceNote>? notes;

  AddOrderNotesResponse();

  AddOrderNotesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('notes')) {
      notes = (_json['notes'] as core.List)
          .map<MarketplaceNote>((value) => MarketplaceNote.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (notes != null)
          'notes': notes!.map((value) => value.toJson()).toList(),
      };
}

/// The configuration data for an Ad Exchange billing info.
class BillingInfo {
  /// Account id.
  core.int? accountId;

  /// Account name.
  core.String? accountName;

  /// A list of adgroup IDs associated with this particular account.
  ///
  /// These IDs may show up as part of a realtime bidding BidRequest, which
  /// indicates a bid request for this account.
  core.List<core.String>? billingId;

  /// Resource type.
  core.String? kind;

  BillingInfo();

  BillingInfo.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.int;
    }
    if (_json.containsKey('accountName')) {
      accountName = _json['accountName'] as core.String;
    }
    if (_json.containsKey('billingId')) {
      billingId = (_json['billingId'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (accountName != null) 'accountName': accountName!,
        if (billingId != null) 'billingId': billingId!,
        if (kind != null) 'kind': kind!,
      };
}

/// A billing info feed lists Billing Info the Ad Exchange buyer account has
/// access to.
///
/// Each entry in the feed corresponds to a single billing info.
class BillingInfoList {
  /// A list of billing info relevant for your account.
  core.List<BillingInfo>? items;

  /// Resource type.
  core.String? kind;

  BillingInfoList();

  BillingInfoList.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<BillingInfo>((value) => BillingInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// The configuration data for Ad Exchange RTB - Budget API.
class Budget {
  /// The id of the account.
  ///
  /// This is required for get and update requests.
  core.String? accountId;

  /// The billing id to determine which adgroup to provide budget information
  /// for.
  ///
  /// This is required for get and update requests.
  core.String? billingId;

  /// The daily budget amount in unit amount of the account currency to apply
  /// for the billingId provided.
  ///
  /// This is required for update requests.
  core.String? budgetAmount;

  /// The currency code for the buyer.
  ///
  /// This cannot be altered here.
  core.String? currencyCode;

  /// The unique id that describes this item.
  core.String? id;

  /// The kind of the resource, i.e. "adexchangebuyer#budget".
  core.String? kind;

  Budget();

  Budget.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('billingId')) {
      billingId = _json['billingId'] as core.String;
    }
    if (_json.containsKey('budgetAmount')) {
      budgetAmount = _json['budgetAmount'] as core.String;
    }
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (billingId != null) 'billingId': billingId!,
        if (budgetAmount != null) 'budgetAmount': budgetAmount!,
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
      };
}

class Buyer {
  /// Adx account id of the buyer.
  core.String? accountId;

  Buyer();

  Buyer.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
      };
}

class ContactInformation {
  /// Email address of the contact.
  core.String? email;

  /// The name of the contact.
  core.String? name;

  ContactInformation();

  ContactInformation.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
        if (name != null) 'name': name!,
      };
}

class CreateOrdersRequest {
  /// The list of proposals to create.
  core.List<Proposal>? proposals;

  /// Web property id of the seller creating these orders
  core.String? webPropertyCode;

  CreateOrdersRequest();

  CreateOrdersRequest.fromJson(core.Map _json) {
    if (_json.containsKey('proposals')) {
      proposals = (_json['proposals'] as core.List)
          .map<Proposal>((value) =>
              Proposal.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('webPropertyCode')) {
      webPropertyCode = _json['webPropertyCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (proposals != null)
          'proposals': proposals!.map((value) => value.toJson()).toList(),
        if (webPropertyCode != null) 'webPropertyCode': webPropertyCode!,
      };
}

class CreateOrdersResponse {
  /// The list of proposals successfully created.
  core.List<Proposal>? proposals;

  CreateOrdersResponse();

  CreateOrdersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('proposals')) {
      proposals = (_json['proposals'] as core.List)
          .map<Proposal>((value) =>
              Proposal.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (proposals != null)
          'proposals': proposals!.map((value) => value.toJson()).toList(),
      };
}

class CreativeAdTechnologyProviders {
  /// The detected ad technology provider IDs for this creative.
  ///
  /// See https://storage.googleapis.com/adx-rtb-dictionaries/providers.csv for
  /// mapping of provider ID to provided name, a privacy policy URL, and a list
  /// of domains which can be attributed to the provider. If this creative
  /// contains provider IDs that are outside of those listed in the
  /// `BidRequest.adslot.consented_providers_settings.consented_providers` field
  /// on the Authorized Buyers Real-Time Bidding protocol or the
  /// `BidRequest.user.ext.consented_providers_settings.consented_providers`
  /// field on the OpenRTB protocol, a bid submitted for a European Economic
  /// Area (EEA) user with this creative is not compliant with the GDPR policies
  /// as mentioned in the "Third-party Ad Technology Vendors" section of
  /// Authorized Buyers Program Guidelines.
  core.List<core.String>? detectedProviderIds;

  /// Whether the creative contains an unidentified ad technology provider.
  ///
  /// If true, a bid submitted for a European Economic Area (EEA) user with this
  /// creative is not compliant with the GDPR policies as mentioned in the
  /// "Third-party Ad Technology Vendors" section of Authorized Buyers Program
  /// Guidelines.
  core.bool? hasUnidentifiedProvider;

  CreativeAdTechnologyProviders();

  CreativeAdTechnologyProviders.fromJson(core.Map _json) {
    if (_json.containsKey('detectedProviderIds')) {
      detectedProviderIds = (_json['detectedProviderIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('hasUnidentifiedProvider')) {
      hasUnidentifiedProvider = _json['hasUnidentifiedProvider'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (detectedProviderIds != null)
          'detectedProviderIds': detectedProviderIds!,
        if (hasUnidentifiedProvider != null)
          'hasUnidentifiedProvider': hasUnidentifiedProvider!,
      };
}

class CreativeCorrectionsContexts {
  /// Only set when contextType=AUCTION_TYPE.
  ///
  /// Represents the auction types this correction applies to.
  core.List<core.String>? auctionType;

  /// The type of context (e.g., location, platform, auction type, SSL-ness).
  core.String? contextType;

  /// Only set when contextType=LOCATION.
  ///
  /// Represents the geo criterias this correction applies to.
  core.List<core.int>? geoCriteriaId;

  /// Only set when contextType=PLATFORM.
  ///
  /// Represents the platforms this correction applies to.
  core.List<core.String>? platform;

  CreativeCorrectionsContexts();

  CreativeCorrectionsContexts.fromJson(core.Map _json) {
    if (_json.containsKey('auctionType')) {
      auctionType = (_json['auctionType'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('contextType')) {
      contextType = _json['contextType'] as core.String;
    }
    if (_json.containsKey('geoCriteriaId')) {
      geoCriteriaId = (_json['geoCriteriaId'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('platform')) {
      platform = (_json['platform'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auctionType != null) 'auctionType': auctionType!,
        if (contextType != null) 'contextType': contextType!,
        if (geoCriteriaId != null) 'geoCriteriaId': geoCriteriaId!,
        if (platform != null) 'platform': platform!,
      };
}

class CreativeCorrections {
  /// All known serving contexts containing serving status information.
  core.List<CreativeCorrectionsContexts>? contexts;

  /// Additional details about the correction.
  core.List<core.String>? details;

  /// The type of correction that was applied to the creative.
  core.String? reason;

  CreativeCorrections();

  CreativeCorrections.fromJson(core.Map _json) {
    if (_json.containsKey('contexts')) {
      contexts = (_json['contexts'] as core.List)
          .map<CreativeCorrectionsContexts>((value) =>
              CreativeCorrectionsContexts.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('details')) {
      details = (_json['details'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contexts != null)
          'contexts': contexts!.map((value) => value.toJson()).toList(),
        if (details != null) 'details': details!,
        if (reason != null) 'reason': reason!,
      };
}

class CreativeFilteringReasonsReasons {
  /// The number of times the creative was filtered for the status.
  ///
  /// The count is aggregated across all publishers on the exchange.
  core.String? filteringCount;

  /// The filtering status code as defined in  creative-status-codes.txt.
  core.int? filteringStatus;

  CreativeFilteringReasonsReasons();

  CreativeFilteringReasonsReasons.fromJson(core.Map _json) {
    if (_json.containsKey('filteringCount')) {
      filteringCount = _json['filteringCount'] as core.String;
    }
    if (_json.containsKey('filteringStatus')) {
      filteringStatus = _json['filteringStatus'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filteringCount != null) 'filteringCount': filteringCount!,
        if (filteringStatus != null) 'filteringStatus': filteringStatus!,
      };
}

/// The filtering reasons for the creative.
///
/// Read-only. This field should not be set in requests.
class CreativeFilteringReasons {
  /// The date in ISO 8601 format for the data.
  ///
  /// The data is collected from 00:00:00 to 23:59:59 in PST.
  core.String? date;

  /// The filtering reasons.
  core.List<CreativeFilteringReasonsReasons>? reasons;

  CreativeFilteringReasons();

  CreativeFilteringReasons.fromJson(core.Map _json) {
    if (_json.containsKey('date')) {
      date = _json['date'] as core.String;
    }
    if (_json.containsKey('reasons')) {
      reasons = (_json['reasons'] as core.List)
          .map<CreativeFilteringReasonsReasons>((value) =>
              CreativeFilteringReasonsReasons.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (date != null) 'date': date!,
        if (reasons != null)
          'reasons': reasons!.map((value) => value.toJson()).toList(),
      };
}

/// The app icon, for app download ads.
class CreativeNativeAdAppIcon {
  core.int? height;
  core.String? url;
  core.int? width;

  CreativeNativeAdAppIcon();

  CreativeNativeAdAppIcon.fromJson(core.Map _json) {
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (height != null) 'height': height!,
        if (url != null) 'url': url!,
        if (width != null) 'width': width!,
      };
}

/// A large image.
class CreativeNativeAdImage {
  core.int? height;
  core.String? url;
  core.int? width;

  CreativeNativeAdImage();

  CreativeNativeAdImage.fromJson(core.Map _json) {
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (height != null) 'height': height!,
        if (url != null) 'url': url!,
        if (width != null) 'width': width!,
      };
}

/// A smaller image, for the advertiser logo.
class CreativeNativeAdLogo {
  core.int? height;
  core.String? url;
  core.int? width;

  CreativeNativeAdLogo();

  CreativeNativeAdLogo.fromJson(core.Map _json) {
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (height != null) 'height': height!,
        if (url != null) 'url': url!,
        if (width != null) 'width': width!,
      };
}

/// If nativeAd is set, HTMLSnippet, videoVastXML, and the videoURL outside of
/// nativeAd should not be set.
///
/// (The videoURL inside nativeAd can be set.)
class CreativeNativeAd {
  core.String? advertiser;

  /// The app icon, for app download ads.
  CreativeNativeAdAppIcon? appIcon;

  /// A long description of the ad.
  core.String? body;

  /// A label for the button that the user is supposed to click.
  core.String? callToAction;

  /// The URL that the browser/SDK will load when the user clicks the ad.
  core.String? clickLinkUrl;

  /// The URL to use for click tracking.
  core.String? clickTrackingUrl;

  /// A short title for the ad.
  core.String? headline;

  /// A large image.
  CreativeNativeAdImage? image;

  /// The URLs are called when the impression is rendered.
  core.List<core.String>? impressionTrackingUrl;

  /// A smaller image, for the advertiser logo.
  CreativeNativeAdLogo? logo;

  /// The price of the promoted app including the currency info.
  core.String? price;

  /// The app rating in the app store.
  ///
  /// Must be in the range \[0-5\].
  core.double? starRating;

  /// The URL of the XML VAST for a native ad.
  ///
  /// Note this is a separate field from resource.video_url.
  core.String? videoURL;

  CreativeNativeAd();

  CreativeNativeAd.fromJson(core.Map _json) {
    if (_json.containsKey('advertiser')) {
      advertiser = _json['advertiser'] as core.String;
    }
    if (_json.containsKey('appIcon')) {
      appIcon = CreativeNativeAdAppIcon.fromJson(
          _json['appIcon'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('body')) {
      body = _json['body'] as core.String;
    }
    if (_json.containsKey('callToAction')) {
      callToAction = _json['callToAction'] as core.String;
    }
    if (_json.containsKey('clickLinkUrl')) {
      clickLinkUrl = _json['clickLinkUrl'] as core.String;
    }
    if (_json.containsKey('clickTrackingUrl')) {
      clickTrackingUrl = _json['clickTrackingUrl'] as core.String;
    }
    if (_json.containsKey('headline')) {
      headline = _json['headline'] as core.String;
    }
    if (_json.containsKey('image')) {
      image = CreativeNativeAdImage.fromJson(
          _json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('impressionTrackingUrl')) {
      impressionTrackingUrl = (_json['impressionTrackingUrl'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('logo')) {
      logo = CreativeNativeAdLogo.fromJson(
          _json['logo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('price')) {
      price = _json['price'] as core.String;
    }
    if (_json.containsKey('starRating')) {
      starRating = (_json['starRating'] as core.num).toDouble();
    }
    if (_json.containsKey('videoURL')) {
      videoURL = _json['videoURL'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiser != null) 'advertiser': advertiser!,
        if (appIcon != null) 'appIcon': appIcon!.toJson(),
        if (body != null) 'body': body!,
        if (callToAction != null) 'callToAction': callToAction!,
        if (clickLinkUrl != null) 'clickLinkUrl': clickLinkUrl!,
        if (clickTrackingUrl != null) 'clickTrackingUrl': clickTrackingUrl!,
        if (headline != null) 'headline': headline!,
        if (image != null) 'image': image!.toJson(),
        if (impressionTrackingUrl != null)
          'impressionTrackingUrl': impressionTrackingUrl!,
        if (logo != null) 'logo': logo!.toJson(),
        if (price != null) 'price': price!,
        if (starRating != null) 'starRating': starRating!,
        if (videoURL != null) 'videoURL': videoURL!,
      };
}

class CreativeServingRestrictionsContexts {
  /// Only set when contextType=AUCTION_TYPE.
  ///
  /// Represents the auction types this restriction applies to.
  core.List<core.String>? auctionType;

  /// The type of context (e.g., location, platform, auction type, SSL-ness).
  core.String? contextType;

  /// Only set when contextType=LOCATION.
  ///
  /// Represents the geo criterias this restriction applies to. Impressions are
  /// considered to match a context if either the user location or publisher
  /// location matches a given geoCriteriaId.
  core.List<core.int>? geoCriteriaId;

  /// Only set when contextType=PLATFORM.
  ///
  /// Represents the platforms this restriction applies to.
  core.List<core.String>? platform;

  CreativeServingRestrictionsContexts();

  CreativeServingRestrictionsContexts.fromJson(core.Map _json) {
    if (_json.containsKey('auctionType')) {
      auctionType = (_json['auctionType'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('contextType')) {
      contextType = _json['contextType'] as core.String;
    }
    if (_json.containsKey('geoCriteriaId')) {
      geoCriteriaId = (_json['geoCriteriaId'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('platform')) {
      platform = (_json['platform'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auctionType != null) 'auctionType': auctionType!,
        if (contextType != null) 'contextType': contextType!,
        if (geoCriteriaId != null) 'geoCriteriaId': geoCriteriaId!,
        if (platform != null) 'platform': platform!,
      };
}

class CreativeServingRestrictionsDisapprovalReasons {
  /// Additional details about the reason for disapproval.
  core.List<core.String>? details;

  /// The categorized reason for disapproval.
  core.String? reason;

  CreativeServingRestrictionsDisapprovalReasons();

  CreativeServingRestrictionsDisapprovalReasons.fromJson(core.Map _json) {
    if (_json.containsKey('details')) {
      details = (_json['details'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (details != null) 'details': details!,
        if (reason != null) 'reason': reason!,
      };
}

class CreativeServingRestrictions {
  /// All known contexts/restrictions.
  core.List<CreativeServingRestrictionsContexts>? contexts;

  /// The reasons for disapproval within this restriction, if any.
  ///
  /// Note that not all disapproval reasons may be categorized, so it is
  /// possible for the creative to have a status of DISAPPROVED or
  /// CONDITIONALLY_APPROVED with an empty list for disapproval_reasons. In this
  /// case, please reach out to your TAM to help debug the issue.
  core.List<CreativeServingRestrictionsDisapprovalReasons>? disapprovalReasons;

  /// Why the creative is ineligible to serve in this context (e.g., it has been
  /// explicitly disapproved or is pending review).
  core.String? reason;

  CreativeServingRestrictions();

  CreativeServingRestrictions.fromJson(core.Map _json) {
    if (_json.containsKey('contexts')) {
      contexts = (_json['contexts'] as core.List)
          .map<CreativeServingRestrictionsContexts>((value) =>
              CreativeServingRestrictionsContexts.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('disapprovalReasons')) {
      disapprovalReasons = (_json['disapprovalReasons'] as core.List)
          .map<CreativeServingRestrictionsDisapprovalReasons>((value) =>
              CreativeServingRestrictionsDisapprovalReasons.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contexts != null)
          'contexts': contexts!.map((value) => value.toJson()).toList(),
        if (disapprovalReasons != null)
          'disapprovalReasons':
              disapprovalReasons!.map((value) => value.toJson()).toList(),
        if (reason != null) 'reason': reason!,
      };
}

/// A creative and its classification data.
class Creative {
  /// The HTML snippet that displays the ad when inserted in the web page.
  ///
  /// If set, videoURL, videoVastXML, and nativeAd should not be set.
  core.String? HTMLSnippet;

  /// Account id.
  core.int? accountId;

  /// The link to the Ad Preferences page.
  ///
  /// This is only supported for native ads.
  core.String? adChoicesDestinationUrl;
  CreativeAdTechnologyProviders? adTechnologyProviders;

  /// Detected advertiser id, if any.
  ///
  /// Read-only. This field should not be set in requests.
  core.List<core.String>? advertiserId;

  /// The name of the company being advertised in the creative.
  ///
  /// A list of advertisers is provided in the advertisers.txt file.
  core.String? advertiserName;

  /// The agency id for this creative.
  core.String? agencyId;

  /// The last upload timestamp of this creative if it was uploaded via API.
  ///
  /// Read-only. The value of this field is generated, and will be ignored for
  /// uploads. (formatted RFC 3339 timestamp).
  core.DateTime? apiUploadTimestamp;

  /// List of buyer selectable attributes for the ads that may be shown from
  /// this snippet.
  ///
  /// Each attribute is represented by an integer as defined in
  /// buyer-declarable-creative-attributes.txt.
  core.List<core.int>? attribute;

  /// A buyer-specific id identifying the creative in this ad.
  core.String? buyerCreativeId;

  /// The set of destination urls for the snippet.
  core.List<core.String>? clickThroughUrl;

  /// Shows any corrections that were applied to this creative.
  ///
  /// Read-only. This field should not be set in requests.
  core.List<CreativeCorrections>? corrections;

  /// Creative status identity type that the creative item applies to.
  ///
  /// Ad Exchange real-time bidding is migrating to the sizeless creative
  /// verification. Originally, Ad Exchange assigned creative verification
  /// status to a unique combination of a buyer creative ID and creative
  /// dimensions. Post-migration, a single verification status will be assigned
  /// at the buyer creative ID level. This field allows to distinguish whether a
  /// given creative status applies to a unique combination of a buyer creative
  /// ID and creative dimensions, or to a buyer creative ID as a whole.
  core.String? creativeStatusIdentityType;

  /// Top-level deals status.
  ///
  /// Read-only. This field should not be set in requests. If disapproved, an
  /// entry for auctionType=DIRECT_DEALS (or ALL) in servingRestrictions will
  /// also exist. Note that this may be nuanced with other contextual
  /// restrictions, in which case it may be preferable to read from
  /// servingRestrictions directly.
  core.String? dealsStatus;

  /// Detected domains for this creative.
  ///
  /// Read-only. This field should not be set in requests.
  core.List<core.String>? detectedDomains;

  /// The filtering reasons for the creative.
  ///
  /// Read-only. This field should not be set in requests.
  CreativeFilteringReasons? filteringReasons;

  /// Ad height.
  core.int? height;

  /// The set of urls to be called to record an impression.
  core.List<core.String>? impressionTrackingUrl;

  /// Resource type.
  core.String? kind;

  /// Detected languages for this creative.
  ///
  /// Read-only. This field should not be set in requests.
  core.List<core.String>? languages;

  /// If nativeAd is set, HTMLSnippet, videoVastXML, and the videoURL outside of
  /// nativeAd should not be set.
  ///
  /// (The videoURL inside nativeAd can be set.)
  CreativeNativeAd? nativeAd;

  /// Top-level open auction status.
  ///
  /// Read-only. This field should not be set in requests. If disapproved, an
  /// entry for auctionType=OPEN_AUCTION (or ALL) in servingRestrictions will
  /// also exist. Note that this may be nuanced with other contextual
  /// restrictions, in which case it may be preferable to read from
  /// ServingRestrictions directly.
  core.String? openAuctionStatus;

  /// Detected product categories, if any.
  ///
  /// Each category is represented by an integer as defined in
  /// ad-product-categories.txt. Read-only. This field should not be set in
  /// requests.
  core.List<core.int>? productCategories;

  /// All restricted categories for the ads that may be shown from this snippet.
  ///
  /// Each category is represented by an integer as defined in the
  /// ad-restricted-categories.txt.
  core.List<core.int>? restrictedCategories;

  /// Detected sensitive categories, if any.
  ///
  /// Each category is represented by an integer as defined in
  /// ad-sensitive-categories.txt. Read-only. This field should not be set in
  /// requests.
  core.List<core.int>? sensitiveCategories;

  /// The granular status of this ad in specific contexts.
  ///
  /// A context here relates to where something ultimately serves (for example,
  /// a physical location, a platform, an HTTPS vs HTTP request, or the type of
  /// auction). Read-only. This field should not be set in requests. See the
  /// examples in the Creatives guide for more details.
  core.List<CreativeServingRestrictions>? servingRestrictions;

  /// List of vendor types for the ads that may be shown from this snippet.
  ///
  /// Each vendor type is represented by an integer as defined in vendors.txt.
  core.List<core.int>? vendorType;

  /// The version for this creative.
  ///
  /// Read-only. This field should not be set in requests.
  core.int? version;

  /// The URL to fetch a video ad.
  ///
  /// If set, HTMLSnippet, videoVastXML, and nativeAd should not be set. Note,
  /// this is different from resource.native_ad.video_url above.
  core.String? videoURL;

  /// The contents of a VAST document for a video ad.
  ///
  /// This document should conform to the VAST 2.0 or 3.0 standard. If set,
  /// HTMLSnippet, videoURL, and nativeAd and should not be set.
  core.String? videoVastXML;

  /// Ad width.
  core.int? width;

  Creative();

  Creative.fromJson(core.Map _json) {
    if (_json.containsKey('HTMLSnippet')) {
      HTMLSnippet = _json['HTMLSnippet'] as core.String;
    }
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.int;
    }
    if (_json.containsKey('adChoicesDestinationUrl')) {
      adChoicesDestinationUrl = _json['adChoicesDestinationUrl'] as core.String;
    }
    if (_json.containsKey('adTechnologyProviders')) {
      adTechnologyProviders = CreativeAdTechnologyProviders.fromJson(
          _json['adTechnologyProviders']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('advertiserId')) {
      advertiserId = (_json['advertiserId'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('advertiserName')) {
      advertiserName = _json['advertiserName'] as core.String;
    }
    if (_json.containsKey('agencyId')) {
      agencyId = _json['agencyId'] as core.String;
    }
    if (_json.containsKey('apiUploadTimestamp')) {
      apiUploadTimestamp =
          core.DateTime.parse(_json['apiUploadTimestamp'] as core.String);
    }
    if (_json.containsKey('attribute')) {
      attribute = (_json['attribute'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('buyerCreativeId')) {
      buyerCreativeId = _json['buyerCreativeId'] as core.String;
    }
    if (_json.containsKey('clickThroughUrl')) {
      clickThroughUrl = (_json['clickThroughUrl'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('corrections')) {
      corrections = (_json['corrections'] as core.List)
          .map<CreativeCorrections>((value) => CreativeCorrections.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('creativeStatusIdentityType')) {
      creativeStatusIdentityType =
          _json['creativeStatusIdentityType'] as core.String;
    }
    if (_json.containsKey('dealsStatus')) {
      dealsStatus = _json['dealsStatus'] as core.String;
    }
    if (_json.containsKey('detectedDomains')) {
      detectedDomains = (_json['detectedDomains'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('filteringReasons')) {
      filteringReasons = CreativeFilteringReasons.fromJson(
          _json['filteringReasons'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('impressionTrackingUrl')) {
      impressionTrackingUrl = (_json['impressionTrackingUrl'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('languages')) {
      languages = (_json['languages'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('nativeAd')) {
      nativeAd = CreativeNativeAd.fromJson(
          _json['nativeAd'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('openAuctionStatus')) {
      openAuctionStatus = _json['openAuctionStatus'] as core.String;
    }
    if (_json.containsKey('productCategories')) {
      productCategories = (_json['productCategories'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('restrictedCategories')) {
      restrictedCategories = (_json['restrictedCategories'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('sensitiveCategories')) {
      sensitiveCategories = (_json['sensitiveCategories'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('servingRestrictions')) {
      servingRestrictions = (_json['servingRestrictions'] as core.List)
          .map<CreativeServingRestrictions>((value) =>
              CreativeServingRestrictions.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('vendorType')) {
      vendorType = (_json['vendorType'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.int;
    }
    if (_json.containsKey('videoURL')) {
      videoURL = _json['videoURL'] as core.String;
    }
    if (_json.containsKey('videoVastXML')) {
      videoVastXML = _json['videoVastXML'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (HTMLSnippet != null) 'HTMLSnippet': HTMLSnippet!,
        if (accountId != null) 'accountId': accountId!,
        if (adChoicesDestinationUrl != null)
          'adChoicesDestinationUrl': adChoicesDestinationUrl!,
        if (adTechnologyProviders != null)
          'adTechnologyProviders': adTechnologyProviders!.toJson(),
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserName != null) 'advertiserName': advertiserName!,
        if (agencyId != null) 'agencyId': agencyId!,
        if (apiUploadTimestamp != null)
          'apiUploadTimestamp': apiUploadTimestamp!.toIso8601String(),
        if (attribute != null) 'attribute': attribute!,
        if (buyerCreativeId != null) 'buyerCreativeId': buyerCreativeId!,
        if (clickThroughUrl != null) 'clickThroughUrl': clickThroughUrl!,
        if (corrections != null)
          'corrections': corrections!.map((value) => value.toJson()).toList(),
        if (creativeStatusIdentityType != null)
          'creativeStatusIdentityType': creativeStatusIdentityType!,
        if (dealsStatus != null) 'dealsStatus': dealsStatus!,
        if (detectedDomains != null) 'detectedDomains': detectedDomains!,
        if (filteringReasons != null)
          'filteringReasons': filteringReasons!.toJson(),
        if (height != null) 'height': height!,
        if (impressionTrackingUrl != null)
          'impressionTrackingUrl': impressionTrackingUrl!,
        if (kind != null) 'kind': kind!,
        if (languages != null) 'languages': languages!,
        if (nativeAd != null) 'nativeAd': nativeAd!.toJson(),
        if (openAuctionStatus != null) 'openAuctionStatus': openAuctionStatus!,
        if (productCategories != null) 'productCategories': productCategories!,
        if (restrictedCategories != null)
          'restrictedCategories': restrictedCategories!,
        if (sensitiveCategories != null)
          'sensitiveCategories': sensitiveCategories!,
        if (servingRestrictions != null)
          'servingRestrictions':
              servingRestrictions!.map((value) => value.toJson()).toList(),
        if (vendorType != null) 'vendorType': vendorType!,
        if (version != null) 'version': version!,
        if (videoURL != null) 'videoURL': videoURL!,
        if (videoVastXML != null) 'videoVastXML': videoVastXML!,
        if (width != null) 'width': width!,
      };
}

class CreativeDealIdsDealStatuses {
  /// ARC approval status.
  core.String? arcStatus;

  /// External deal ID.
  core.String? dealId;

  /// Publisher ID.
  core.int? webPropertyId;

  CreativeDealIdsDealStatuses();

  CreativeDealIdsDealStatuses.fromJson(core.Map _json) {
    if (_json.containsKey('arcStatus')) {
      arcStatus = _json['arcStatus'] as core.String;
    }
    if (_json.containsKey('dealId')) {
      dealId = _json['dealId'] as core.String;
    }
    if (_json.containsKey('webPropertyId')) {
      webPropertyId = _json['webPropertyId'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arcStatus != null) 'arcStatus': arcStatus!,
        if (dealId != null) 'dealId': dealId!,
        if (webPropertyId != null) 'webPropertyId': webPropertyId!,
      };
}

/// The external deal ids associated with a creative.
class CreativeDealIds {
  /// A list of external deal ids and ARC approval status.
  core.List<CreativeDealIdsDealStatuses>? dealStatuses;

  /// Resource type.
  core.String? kind;

  CreativeDealIds();

  CreativeDealIds.fromJson(core.Map _json) {
    if (_json.containsKey('dealStatuses')) {
      dealStatuses = (_json['dealStatuses'] as core.List)
          .map<CreativeDealIdsDealStatuses>((value) =>
              CreativeDealIdsDealStatuses.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dealStatuses != null)
          'dealStatuses': dealStatuses!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

/// The creatives feed lists the active creatives for the Ad Exchange buyer
/// accounts that the user has access to.
///
/// Each entry in the feed corresponds to a single creative.
class CreativesList {
  /// A list of creatives.
  core.List<Creative>? items;

  /// Resource type.
  core.String? kind;

  /// Continuation token used to page through creatives.
  ///
  /// To retrieve the next page of results, set the next request's "pageToken"
  /// value to this.
  core.String? nextPageToken;

  CreativesList();

  CreativesList.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Creative>((value) =>
              Creative.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class DealServingMetadata {
  /// True if alcohol ads are allowed for this deal (read-only).
  ///
  /// This field is only populated when querying for finalized orders using the
  /// method GetFinalizedOrderDeals
  core.bool? alcoholAdsAllowed;

  /// Tracks which parties (if any) have paused a deal.
  ///
  /// (readonly, except via PauseResumeOrderDeals action)
  DealServingMetadataDealPauseStatus? dealPauseStatus;

  DealServingMetadata();

  DealServingMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('alcoholAdsAllowed')) {
      alcoholAdsAllowed = _json['alcoholAdsAllowed'] as core.bool;
    }
    if (_json.containsKey('dealPauseStatus')) {
      dealPauseStatus = DealServingMetadataDealPauseStatus.fromJson(
          _json['dealPauseStatus'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alcoholAdsAllowed != null) 'alcoholAdsAllowed': alcoholAdsAllowed!,
        if (dealPauseStatus != null)
          'dealPauseStatus': dealPauseStatus!.toJson(),
      };
}

/// Tracks which parties (if any) have paused a deal.
///
/// The deal is considered paused if has_buyer_paused || has_seller_paused. Each
/// of the has_buyer_paused or the has_seller_paused bits can be set
/// independently.
class DealServingMetadataDealPauseStatus {
  core.String? buyerPauseReason;

  /// If the deal is paused, records which party paused the deal first.
  core.String? firstPausedBy;
  core.bool? hasBuyerPaused;
  core.bool? hasSellerPaused;
  core.String? sellerPauseReason;

  DealServingMetadataDealPauseStatus();

  DealServingMetadataDealPauseStatus.fromJson(core.Map _json) {
    if (_json.containsKey('buyerPauseReason')) {
      buyerPauseReason = _json['buyerPauseReason'] as core.String;
    }
    if (_json.containsKey('firstPausedBy')) {
      firstPausedBy = _json['firstPausedBy'] as core.String;
    }
    if (_json.containsKey('hasBuyerPaused')) {
      hasBuyerPaused = _json['hasBuyerPaused'] as core.bool;
    }
    if (_json.containsKey('hasSellerPaused')) {
      hasSellerPaused = _json['hasSellerPaused'] as core.bool;
    }
    if (_json.containsKey('sellerPauseReason')) {
      sellerPauseReason = _json['sellerPauseReason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buyerPauseReason != null) 'buyerPauseReason': buyerPauseReason!,
        if (firstPausedBy != null) 'firstPausedBy': firstPausedBy!,
        if (hasBuyerPaused != null) 'hasBuyerPaused': hasBuyerPaused!,
        if (hasSellerPaused != null) 'hasSellerPaused': hasSellerPaused!,
        if (sellerPauseReason != null) 'sellerPauseReason': sellerPauseReason!,
      };
}

class DealTerms {
  /// Visibility of the URL in bid requests.
  core.String? brandingType;

  /// Indicates that this ExternalDealId exists under at least two different
  /// AdxInventoryDeals.
  ///
  /// Currently, the only case that the same ExternalDealId will exist is
  /// programmatic cross sell case.
  core.String? crossListedExternalDealIdType;

  /// Description for the proposed terms of the deal.
  core.String? description;

  /// Non-binding estimate of the estimated gross spend for this deal Can be set
  /// by buyer or seller.
  Price? estimatedGrossSpend;

  /// Non-binding estimate of the impressions served per day Can be set by buyer
  /// or seller.
  core.String? estimatedImpressionsPerDay;

  /// The terms for guaranteed fixed price deals.
  DealTermsGuaranteedFixedPriceTerms? guaranteedFixedPriceTerms;

  /// The terms for non-guaranteed auction deals.
  DealTermsNonGuaranteedAuctionTerms? nonGuaranteedAuctionTerms;

  /// The terms for non-guaranteed fixed price deals.
  DealTermsNonGuaranteedFixedPriceTerms? nonGuaranteedFixedPriceTerms;

  /// The terms for rubicon non-guaranteed deals.
  DealTermsRubiconNonGuaranteedTerms? rubiconNonGuaranteedTerms;

  /// For deals with Cost Per Day billing, defines the timezone used to mark the
  /// boundaries of a day (buyer-readonly)
  core.String? sellerTimeZone;

  DealTerms();

  DealTerms.fromJson(core.Map _json) {
    if (_json.containsKey('brandingType')) {
      brandingType = _json['brandingType'] as core.String;
    }
    if (_json.containsKey('crossListedExternalDealIdType')) {
      crossListedExternalDealIdType =
          _json['crossListedExternalDealIdType'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('estimatedGrossSpend')) {
      estimatedGrossSpend = Price.fromJson(
          _json['estimatedGrossSpend'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('estimatedImpressionsPerDay')) {
      estimatedImpressionsPerDay =
          _json['estimatedImpressionsPerDay'] as core.String;
    }
    if (_json.containsKey('guaranteedFixedPriceTerms')) {
      guaranteedFixedPriceTerms = DealTermsGuaranteedFixedPriceTerms.fromJson(
          _json['guaranteedFixedPriceTerms']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nonGuaranteedAuctionTerms')) {
      nonGuaranteedAuctionTerms = DealTermsNonGuaranteedAuctionTerms.fromJson(
          _json['nonGuaranteedAuctionTerms']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nonGuaranteedFixedPriceTerms')) {
      nonGuaranteedFixedPriceTerms =
          DealTermsNonGuaranteedFixedPriceTerms.fromJson(
              _json['nonGuaranteedFixedPriceTerms']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rubiconNonGuaranteedTerms')) {
      rubiconNonGuaranteedTerms = DealTermsRubiconNonGuaranteedTerms.fromJson(
          _json['rubiconNonGuaranteedTerms']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sellerTimeZone')) {
      sellerTimeZone = _json['sellerTimeZone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (brandingType != null) 'brandingType': brandingType!,
        if (crossListedExternalDealIdType != null)
          'crossListedExternalDealIdType': crossListedExternalDealIdType!,
        if (description != null) 'description': description!,
        if (estimatedGrossSpend != null)
          'estimatedGrossSpend': estimatedGrossSpend!.toJson(),
        if (estimatedImpressionsPerDay != null)
          'estimatedImpressionsPerDay': estimatedImpressionsPerDay!,
        if (guaranteedFixedPriceTerms != null)
          'guaranteedFixedPriceTerms': guaranteedFixedPriceTerms!.toJson(),
        if (nonGuaranteedAuctionTerms != null)
          'nonGuaranteedAuctionTerms': nonGuaranteedAuctionTerms!.toJson(),
        if (nonGuaranteedFixedPriceTerms != null)
          'nonGuaranteedFixedPriceTerms':
              nonGuaranteedFixedPriceTerms!.toJson(),
        if (rubiconNonGuaranteedTerms != null)
          'rubiconNonGuaranteedTerms': rubiconNonGuaranteedTerms!.toJson(),
        if (sellerTimeZone != null) 'sellerTimeZone': sellerTimeZone!,
      };
}

class DealTermsGuaranteedFixedPriceTerms {
  /// External billing info for this Deal.
  ///
  /// This field is relevant when external billing info such as price has a
  /// different currency code than DFP/AdX.
  DealTermsGuaranteedFixedPriceTermsBillingInfo? billingInfo;

  /// Fixed price for the specified buyer.
  core.List<PricePerBuyer>? fixedPrices;

  /// Guaranteed impressions as a percentage.
  ///
  /// This is the percentage of guaranteed looks that the buyer is guaranteeing
  /// to buy.
  core.String? guaranteedImpressions;

  /// Count of guaranteed looks.
  ///
  /// Required for deal, optional for product. For CPD deals, buyer changes to
  /// guaranteed_looks will be ignored.
  core.String? guaranteedLooks;

  /// Count of minimum daily looks for a CPD deal.
  ///
  /// For CPD deals, buyer should negotiate on this field instead of
  /// guaranteed_looks.
  core.String? minimumDailyLooks;

  DealTermsGuaranteedFixedPriceTerms();

  DealTermsGuaranteedFixedPriceTerms.fromJson(core.Map _json) {
    if (_json.containsKey('billingInfo')) {
      billingInfo = DealTermsGuaranteedFixedPriceTermsBillingInfo.fromJson(
          _json['billingInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fixedPrices')) {
      fixedPrices = (_json['fixedPrices'] as core.List)
          .map<PricePerBuyer>((value) => PricePerBuyer.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('guaranteedImpressions')) {
      guaranteedImpressions = _json['guaranteedImpressions'] as core.String;
    }
    if (_json.containsKey('guaranteedLooks')) {
      guaranteedLooks = _json['guaranteedLooks'] as core.String;
    }
    if (_json.containsKey('minimumDailyLooks')) {
      minimumDailyLooks = _json['minimumDailyLooks'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (billingInfo != null) 'billingInfo': billingInfo!.toJson(),
        if (fixedPrices != null)
          'fixedPrices': fixedPrices!.map((value) => value.toJson()).toList(),
        if (guaranteedImpressions != null)
          'guaranteedImpressions': guaranteedImpressions!,
        if (guaranteedLooks != null) 'guaranteedLooks': guaranteedLooks!,
        if (minimumDailyLooks != null) 'minimumDailyLooks': minimumDailyLooks!,
      };
}

class DealTermsGuaranteedFixedPriceTermsBillingInfo {
  /// The timestamp (in ms since epoch) when the original reservation price for
  /// the deal was first converted to DFP currency.
  ///
  /// This is used to convert the contracted price into buyer's currency without
  /// discrepancy.
  core.String? currencyConversionTimeMs;

  /// The DFP line item id associated with this deal.
  ///
  /// For features like CPD, buyers can retrieve the DFP line item for billing
  /// reconciliation.
  core.String? dfpLineItemId;

  /// The original contracted quantity (# impressions) for this deal.
  ///
  /// To ensure delivery, sometimes the publisher will book the deal with a
  /// impression buffer, such that guaranteed_looks is greater than the
  /// contracted quantity. However clients are billed using the original
  /// contracted quantity.
  core.String? originalContractedQuantity;

  /// The original reservation price for the deal, if the currency code is
  /// different from the one used in negotiation.
  Price? price;

  DealTermsGuaranteedFixedPriceTermsBillingInfo();

  DealTermsGuaranteedFixedPriceTermsBillingInfo.fromJson(core.Map _json) {
    if (_json.containsKey('currencyConversionTimeMs')) {
      currencyConversionTimeMs =
          _json['currencyConversionTimeMs'] as core.String;
    }
    if (_json.containsKey('dfpLineItemId')) {
      dfpLineItemId = _json['dfpLineItemId'] as core.String;
    }
    if (_json.containsKey('originalContractedQuantity')) {
      originalContractedQuantity =
          _json['originalContractedQuantity'] as core.String;
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currencyConversionTimeMs != null)
          'currencyConversionTimeMs': currencyConversionTimeMs!,
        if (dfpLineItemId != null) 'dfpLineItemId': dfpLineItemId!,
        if (originalContractedQuantity != null)
          'originalContractedQuantity': originalContractedQuantity!,
        if (price != null) 'price': price!.toJson(),
      };
}

class DealTermsNonGuaranteedAuctionTerms {
  /// True if open auction buyers are allowed to compete with invited buyers in
  /// this private auction (buyer-readonly).
  core.bool? autoOptimizePrivateAuction;

  /// Reserve price for the specified buyer.
  core.List<PricePerBuyer>? reservePricePerBuyers;

  DealTermsNonGuaranteedAuctionTerms();

  DealTermsNonGuaranteedAuctionTerms.fromJson(core.Map _json) {
    if (_json.containsKey('autoOptimizePrivateAuction')) {
      autoOptimizePrivateAuction =
          _json['autoOptimizePrivateAuction'] as core.bool;
    }
    if (_json.containsKey('reservePricePerBuyers')) {
      reservePricePerBuyers = (_json['reservePricePerBuyers'] as core.List)
          .map<PricePerBuyer>((value) => PricePerBuyer.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoOptimizePrivateAuction != null)
          'autoOptimizePrivateAuction': autoOptimizePrivateAuction!,
        if (reservePricePerBuyers != null)
          'reservePricePerBuyers':
              reservePricePerBuyers!.map((value) => value.toJson()).toList(),
      };
}

class DealTermsNonGuaranteedFixedPriceTerms {
  /// Fixed price for the specified buyer.
  core.List<PricePerBuyer>? fixedPrices;

  DealTermsNonGuaranteedFixedPriceTerms();

  DealTermsNonGuaranteedFixedPriceTerms.fromJson(core.Map _json) {
    if (_json.containsKey('fixedPrices')) {
      fixedPrices = (_json['fixedPrices'] as core.List)
          .map<PricePerBuyer>((value) => PricePerBuyer.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fixedPrices != null)
          'fixedPrices': fixedPrices!.map((value) => value.toJson()).toList(),
      };
}

class DealTermsRubiconNonGuaranteedTerms {
  /// Optional price for Rubicon priority access in the auction.
  Price? priorityPrice;

  /// Optional price for Rubicon standard access in the auction.
  Price? standardPrice;

  DealTermsRubiconNonGuaranteedTerms();

  DealTermsRubiconNonGuaranteedTerms.fromJson(core.Map _json) {
    if (_json.containsKey('priorityPrice')) {
      priorityPrice = Price.fromJson(
          _json['priorityPrice'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('standardPrice')) {
      standardPrice = Price.fromJson(
          _json['standardPrice'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (priorityPrice != null) 'priorityPrice': priorityPrice!.toJson(),
        if (standardPrice != null) 'standardPrice': standardPrice!.toJson(),
      };
}

class DeleteOrderDealsRequest {
  /// List of deals to delete for a given proposal
  core.List<core.String>? dealIds;

  /// The last known proposal revision number.
  core.String? proposalRevisionNumber;

  /// Indicates an optional action to take on the proposal
  core.String? updateAction;

  DeleteOrderDealsRequest();

  DeleteOrderDealsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dealIds')) {
      dealIds = (_json['dealIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('proposalRevisionNumber')) {
      proposalRevisionNumber = _json['proposalRevisionNumber'] as core.String;
    }
    if (_json.containsKey('updateAction')) {
      updateAction = _json['updateAction'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dealIds != null) 'dealIds': dealIds!,
        if (proposalRevisionNumber != null)
          'proposalRevisionNumber': proposalRevisionNumber!,
        if (updateAction != null) 'updateAction': updateAction!,
      };
}

class DeleteOrderDealsResponse {
  /// List of deals deleted (in the same proposal as passed in the request)
  core.List<MarketplaceDeal>? deals;

  /// The updated revision number for the proposal.
  core.String? proposalRevisionNumber;

  DeleteOrderDealsResponse();

  DeleteOrderDealsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('deals')) {
      deals = (_json['deals'] as core.List)
          .map<MarketplaceDeal>((value) => MarketplaceDeal.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('proposalRevisionNumber')) {
      proposalRevisionNumber = _json['proposalRevisionNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deals != null)
          'deals': deals!.map((value) => value.toJson()).toList(),
        if (proposalRevisionNumber != null)
          'proposalRevisionNumber': proposalRevisionNumber!,
      };
}

class DeliveryControl {
  core.String? creativeBlockingLevel;
  core.String? deliveryRateType;
  core.List<DeliveryControlFrequencyCap>? frequencyCaps;

  DeliveryControl();

  DeliveryControl.fromJson(core.Map _json) {
    if (_json.containsKey('creativeBlockingLevel')) {
      creativeBlockingLevel = _json['creativeBlockingLevel'] as core.String;
    }
    if (_json.containsKey('deliveryRateType')) {
      deliveryRateType = _json['deliveryRateType'] as core.String;
    }
    if (_json.containsKey('frequencyCaps')) {
      frequencyCaps = (_json['frequencyCaps'] as core.List)
          .map<DeliveryControlFrequencyCap>((value) =>
              DeliveryControlFrequencyCap.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creativeBlockingLevel != null)
          'creativeBlockingLevel': creativeBlockingLevel!,
        if (deliveryRateType != null) 'deliveryRateType': deliveryRateType!,
        if (frequencyCaps != null)
          'frequencyCaps':
              frequencyCaps!.map((value) => value.toJson()).toList(),
      };
}

class DeliveryControlFrequencyCap {
  core.int? maxImpressions;
  core.int? numTimeUnits;
  core.String? timeUnitType;

  DeliveryControlFrequencyCap();

  DeliveryControlFrequencyCap.fromJson(core.Map _json) {
    if (_json.containsKey('maxImpressions')) {
      maxImpressions = _json['maxImpressions'] as core.int;
    }
    if (_json.containsKey('numTimeUnits')) {
      numTimeUnits = _json['numTimeUnits'] as core.int;
    }
    if (_json.containsKey('timeUnitType')) {
      timeUnitType = _json['timeUnitType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maxImpressions != null) 'maxImpressions': maxImpressions!,
        if (numTimeUnits != null) 'numTimeUnits': numTimeUnits!,
        if (timeUnitType != null) 'timeUnitType': timeUnitType!,
      };
}

/// This message carries publisher provided breakdown.
///
/// E.g. {dimension_type: 'COUNTRY', \[{dimension_value: {id: 1, name: 'US'}},
/// {dimension_value: {id: 2, name: 'UK'}}\]}
class Dimension {
  core.String? dimensionType;
  core.List<DimensionDimensionValue>? dimensionValues;

  Dimension();

  Dimension.fromJson(core.Map _json) {
    if (_json.containsKey('dimensionType')) {
      dimensionType = _json['dimensionType'] as core.String;
    }
    if (_json.containsKey('dimensionValues')) {
      dimensionValues = (_json['dimensionValues'] as core.List)
          .map<DimensionDimensionValue>((value) =>
              DimensionDimensionValue.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensionType != null) 'dimensionType': dimensionType!,
        if (dimensionValues != null)
          'dimensionValues':
              dimensionValues!.map((value) => value.toJson()).toList(),
      };
}

/// Value of the dimension.
class DimensionDimensionValue {
  /// Id of the dimension.
  core.int? id;

  /// Name of the dimension mainly for debugging purposes, except for the case
  /// of CREATIVE_SIZE.
  ///
  /// For CREATIVE_SIZE, strings are used instead of ids.
  core.String? name;

  /// Percent of total impressions for a dimension type.
  ///
  /// e.g. {dimension_type: 'GENDER', \[{dimension_value: {id: 1, name: 'MALE',
  /// percentage: 60}}\]} Gender MALE is 60% of all impressions which have
  /// gender.
  core.int? percentage;

  DimensionDimensionValue();

  DimensionDimensionValue.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.int;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('percentage')) {
      percentage = _json['percentage'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
        if (percentage != null) 'percentage': percentage!,
      };
}

class EditAllOrderDealsRequest {
  /// List of deals to edit.
  ///
  /// Service may perform 3 different operations based on comparison of deals in
  /// this list vs deals already persisted in database: 1. Add new deal to
  /// proposal If a deal in this list does not exist in the proposal, the
  /// service will create a new deal and add it to the proposal. Validation will
  /// follow AddOrderDealsRequest. 2. Update existing deal in the proposal If a
  /// deal in this list already exist in the proposal, the service will update
  /// that existing deal to this new deal in the request. Validation will follow
  /// UpdateOrderDealsRequest. 3. Delete deals from the proposal (just need the
  /// id) If a existing deal in the proposal is not present in this list, the
  /// service will delete that deal from the proposal. Validation will follow
  /// DeleteOrderDealsRequest.
  core.List<MarketplaceDeal>? deals;

  /// If specified, also updates the proposal in the batch transaction.
  ///
  /// This is useful when the proposal and the deals need to be updated in one
  /// transaction.
  Proposal? proposal;

  /// The last known revision number for the proposal.
  core.String? proposalRevisionNumber;

  /// Indicates an optional action to take on the proposal
  core.String? updateAction;

  EditAllOrderDealsRequest();

  EditAllOrderDealsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('deals')) {
      deals = (_json['deals'] as core.List)
          .map<MarketplaceDeal>((value) => MarketplaceDeal.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('proposal')) {
      proposal = Proposal.fromJson(
          _json['proposal'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('proposalRevisionNumber')) {
      proposalRevisionNumber = _json['proposalRevisionNumber'] as core.String;
    }
    if (_json.containsKey('updateAction')) {
      updateAction = _json['updateAction'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deals != null)
          'deals': deals!.map((value) => value.toJson()).toList(),
        if (proposal != null) 'proposal': proposal!.toJson(),
        if (proposalRevisionNumber != null)
          'proposalRevisionNumber': proposalRevisionNumber!,
        if (updateAction != null) 'updateAction': updateAction!,
      };
}

class EditAllOrderDealsResponse {
  /// List of all deals in the proposal after edit.
  core.List<MarketplaceDeal>? deals;

  /// The latest revision number after the update has been applied.
  core.String? orderRevisionNumber;

  EditAllOrderDealsResponse();

  EditAllOrderDealsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('deals')) {
      deals = (_json['deals'] as core.List)
          .map<MarketplaceDeal>((value) => MarketplaceDeal.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('orderRevisionNumber')) {
      orderRevisionNumber = _json['orderRevisionNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deals != null)
          'deals': deals!.map((value) => value.toJson()).toList(),
        if (orderRevisionNumber != null)
          'orderRevisionNumber': orderRevisionNumber!,
      };
}

class GetOffersResponse {
  /// The returned list of products.
  core.List<Product>? products;

  GetOffersResponse();

  GetOffersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('products')) {
      products = (_json['products'] as core.List)
          .map<Product>((value) =>
              Product.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (products != null)
          'products': products!.map((value) => value.toJson()).toList(),
      };
}

class GetOrderDealsResponse {
  /// List of deals for the proposal
  core.List<MarketplaceDeal>? deals;

  GetOrderDealsResponse();

  GetOrderDealsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('deals')) {
      deals = (_json['deals'] as core.List)
          .map<MarketplaceDeal>((value) => MarketplaceDeal.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deals != null)
          'deals': deals!.map((value) => value.toJson()).toList(),
      };
}

class GetOrderNotesResponse {
  /// The list of matching notes.
  ///
  /// The notes for a proposal are ordered from oldest to newest. If the notes
  /// span multiple proposals, they will be grouped by proposal, with the notes
  /// for the most recently modified proposal appearing first.
  core.List<MarketplaceNote>? notes;

  GetOrderNotesResponse();

  GetOrderNotesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('notes')) {
      notes = (_json['notes'] as core.List)
          .map<MarketplaceNote>((value) => MarketplaceNote.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (notes != null)
          'notes': notes!.map((value) => value.toJson()).toList(),
      };
}

class GetOrdersResponse {
  /// The list of matching proposals.
  core.List<Proposal>? proposals;

  GetOrdersResponse();

  GetOrdersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('proposals')) {
      proposals = (_json['proposals'] as core.List)
          .map<Proposal>((value) =>
              Proposal.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (proposals != null)
          'proposals': proposals!.map((value) => value.toJson()).toList(),
      };
}

class GetPublisherProfilesByAccountIdResponse {
  /// Profiles for the requested publisher
  core.List<PublisherProfileApiProto>? profiles;

  GetPublisherProfilesByAccountIdResponse();

  GetPublisherProfilesByAccountIdResponse.fromJson(core.Map _json) {
    if (_json.containsKey('profiles')) {
      profiles = (_json['profiles'] as core.List)
          .map<PublisherProfileApiProto>((value) =>
              PublisherProfileApiProto.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (profiles != null)
          'profiles': profiles!.map((value) => value.toJson()).toList(),
      };
}

/// A proposal can contain multiple deals.
///
/// A deal contains the terms and targeting information that is used for
/// serving.
class MarketplaceDeal {
  /// Buyer private data (hidden from seller).
  PrivateData? buyerPrivateData;

  /// The time (ms since epoch) of the deal creation.
  ///
  /// (readonly)
  core.String? creationTimeMs;

  /// Specifies the creative pre-approval policy (buyer-readonly)
  core.String? creativePreApprovalPolicy;

  /// Specifies whether the creative is safeFrame compatible (buyer-readonly)
  core.String? creativeSafeFrameCompatibility;

  /// A unique deal-id for the deal (readonly).
  core.String? dealId;

  /// Metadata about the serving status of this deal (readonly, writes via
  /// custom actions)
  DealServingMetadata? dealServingMetadata;

  /// The set of fields around delivery control that are interesting for a buyer
  /// to see but are non-negotiable.
  ///
  /// These are set by the publisher. This message is assigned an id of 100
  /// since some day we would want to model this as a protobuf extension.
  DeliveryControl? deliveryControl;

  /// The external deal id assigned to this deal once the deal is finalized.
  ///
  /// This is the deal-id that shows up in serving/reporting etc. (readonly)
  core.String? externalDealId;

  /// Proposed flight end time of the deal (ms since epoch) This will generally
  /// be stored in a granularity of a second.
  ///
  /// (updatable)
  core.String? flightEndTimeMs;

  /// Proposed flight start time of the deal (ms since epoch) This will
  /// generally be stored in a granularity of a second.
  ///
  /// (updatable)
  core.String? flightStartTimeMs;

  /// Description for the deal terms.
  ///
  /// (buyer-readonly)
  core.String? inventoryDescription;

  /// Indicates whether the current deal is a RFP template.
  ///
  /// RFP template is created by buyer and not based on seller created products.
  core.bool? isRfpTemplate;

  /// True, if the buyside inventory setup is complete for this deal.
  ///
  /// (readonly, except via OrderSetupCompleted action)
  core.bool? isSetupComplete;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "adexchangebuyer#marketplaceDeal".
  core.String? kind;

  /// The time (ms since epoch) when the deal was last updated.
  ///
  /// (readonly)
  core.String? lastUpdateTimeMs;
  core.String? makegoodRequestedReason;

  /// The name of the deal.
  ///
  /// (updatable)
  core.String? name;

  /// The product-id from which this deal was created.
  ///
  /// (readonly, except on create)
  core.String? productId;

  /// The revision number of the product that the deal was created from
  /// (readonly, except on create)
  core.String? productRevisionNumber;

  /// Specifies the creative source for programmatic deals, PUBLISHER means
  /// creative is provided by seller and ADVERTISR means creative is provided by
  /// buyer.
  ///
  /// (buyer-readonly)
  core.String? programmaticCreativeSource;
  core.String? proposalId;

  /// Optional Seller contact information for the deal (buyer-readonly)
  core.List<ContactInformation>? sellerContacts;

  /// The shared targeting visible to buyers and sellers.
  ///
  /// Each shared targeting entity is AND'd together. (updatable)
  core.List<SharedTargeting>? sharedTargetings;

  /// The syndication product associated with the deal.
  ///
  /// (readonly, except on create)
  core.String? syndicationProduct;

  /// The negotiable terms of the deal.
  ///
  /// (updatable)
  DealTerms? terms;
  core.String? webPropertyCode;

  MarketplaceDeal();

  MarketplaceDeal.fromJson(core.Map _json) {
    if (_json.containsKey('buyerPrivateData')) {
      buyerPrivateData = PrivateData.fromJson(
          _json['buyerPrivateData'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('creationTimeMs')) {
      creationTimeMs = _json['creationTimeMs'] as core.String;
    }
    if (_json.containsKey('creativePreApprovalPolicy')) {
      creativePreApprovalPolicy =
          _json['creativePreApprovalPolicy'] as core.String;
    }
    if (_json.containsKey('creativeSafeFrameCompatibility')) {
      creativeSafeFrameCompatibility =
          _json['creativeSafeFrameCompatibility'] as core.String;
    }
    if (_json.containsKey('dealId')) {
      dealId = _json['dealId'] as core.String;
    }
    if (_json.containsKey('dealServingMetadata')) {
      dealServingMetadata = DealServingMetadata.fromJson(
          _json['dealServingMetadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deliveryControl')) {
      deliveryControl = DeliveryControl.fromJson(
          _json['deliveryControl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('externalDealId')) {
      externalDealId = _json['externalDealId'] as core.String;
    }
    if (_json.containsKey('flightEndTimeMs')) {
      flightEndTimeMs = _json['flightEndTimeMs'] as core.String;
    }
    if (_json.containsKey('flightStartTimeMs')) {
      flightStartTimeMs = _json['flightStartTimeMs'] as core.String;
    }
    if (_json.containsKey('inventoryDescription')) {
      inventoryDescription = _json['inventoryDescription'] as core.String;
    }
    if (_json.containsKey('isRfpTemplate')) {
      isRfpTemplate = _json['isRfpTemplate'] as core.bool;
    }
    if (_json.containsKey('isSetupComplete')) {
      isSetupComplete = _json['isSetupComplete'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastUpdateTimeMs')) {
      lastUpdateTimeMs = _json['lastUpdateTimeMs'] as core.String;
    }
    if (_json.containsKey('makegoodRequestedReason')) {
      makegoodRequestedReason = _json['makegoodRequestedReason'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('productRevisionNumber')) {
      productRevisionNumber = _json['productRevisionNumber'] as core.String;
    }
    if (_json.containsKey('programmaticCreativeSource')) {
      programmaticCreativeSource =
          _json['programmaticCreativeSource'] as core.String;
    }
    if (_json.containsKey('proposalId')) {
      proposalId = _json['proposalId'] as core.String;
    }
    if (_json.containsKey('sellerContacts')) {
      sellerContacts = (_json['sellerContacts'] as core.List)
          .map<ContactInformation>((value) => ContactInformation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('sharedTargetings')) {
      sharedTargetings = (_json['sharedTargetings'] as core.List)
          .map<SharedTargeting>((value) => SharedTargeting.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('syndicationProduct')) {
      syndicationProduct = _json['syndicationProduct'] as core.String;
    }
    if (_json.containsKey('terms')) {
      terms = DealTerms.fromJson(
          _json['terms'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('webPropertyCode')) {
      webPropertyCode = _json['webPropertyCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buyerPrivateData != null)
          'buyerPrivateData': buyerPrivateData!.toJson(),
        if (creationTimeMs != null) 'creationTimeMs': creationTimeMs!,
        if (creativePreApprovalPolicy != null)
          'creativePreApprovalPolicy': creativePreApprovalPolicy!,
        if (creativeSafeFrameCompatibility != null)
          'creativeSafeFrameCompatibility': creativeSafeFrameCompatibility!,
        if (dealId != null) 'dealId': dealId!,
        if (dealServingMetadata != null)
          'dealServingMetadata': dealServingMetadata!.toJson(),
        if (deliveryControl != null)
          'deliveryControl': deliveryControl!.toJson(),
        if (externalDealId != null) 'externalDealId': externalDealId!,
        if (flightEndTimeMs != null) 'flightEndTimeMs': flightEndTimeMs!,
        if (flightStartTimeMs != null) 'flightStartTimeMs': flightStartTimeMs!,
        if (inventoryDescription != null)
          'inventoryDescription': inventoryDescription!,
        if (isRfpTemplate != null) 'isRfpTemplate': isRfpTemplate!,
        if (isSetupComplete != null) 'isSetupComplete': isSetupComplete!,
        if (kind != null) 'kind': kind!,
        if (lastUpdateTimeMs != null) 'lastUpdateTimeMs': lastUpdateTimeMs!,
        if (makegoodRequestedReason != null)
          'makegoodRequestedReason': makegoodRequestedReason!,
        if (name != null) 'name': name!,
        if (productId != null) 'productId': productId!,
        if (productRevisionNumber != null)
          'productRevisionNumber': productRevisionNumber!,
        if (programmaticCreativeSource != null)
          'programmaticCreativeSource': programmaticCreativeSource!,
        if (proposalId != null) 'proposalId': proposalId!,
        if (sellerContacts != null)
          'sellerContacts':
              sellerContacts!.map((value) => value.toJson()).toList(),
        if (sharedTargetings != null)
          'sharedTargetings':
              sharedTargetings!.map((value) => value.toJson()).toList(),
        if (syndicationProduct != null)
          'syndicationProduct': syndicationProduct!,
        if (terms != null) 'terms': terms!.toJson(),
        if (webPropertyCode != null) 'webPropertyCode': webPropertyCode!,
      };
}

class MarketplaceDealParty {
  /// The buyer/seller associated with the deal.
  ///
  /// One of buyer/seller is specified for a deal-party.
  Buyer? buyer;

  /// The buyer/seller associated with the deal.
  ///
  /// One of buyer/seller is specified for a deal party.
  Seller? seller;

  MarketplaceDealParty();

  MarketplaceDealParty.fromJson(core.Map _json) {
    if (_json.containsKey('buyer')) {
      buyer =
          Buyer.fromJson(_json['buyer'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('seller')) {
      seller = Seller.fromJson(
          _json['seller'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buyer != null) 'buyer': buyer!.toJson(),
        if (seller != null) 'seller': seller!.toJson(),
      };
}

class MarketplaceLabel {
  /// The accountId of the party that created the label.
  core.String? accountId;

  /// The creation time (in ms since epoch) for the label.
  core.String? createTimeMs;

  /// Information about the party that created the label.
  MarketplaceDealParty? deprecatedMarketplaceDealParty;

  /// The label to use.
  core.String? label;

  MarketplaceLabel();

  MarketplaceLabel.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('createTimeMs')) {
      createTimeMs = _json['createTimeMs'] as core.String;
    }
    if (_json.containsKey('deprecatedMarketplaceDealParty')) {
      deprecatedMarketplaceDealParty = MarketplaceDealParty.fromJson(
          _json['deprecatedMarketplaceDealParty']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('label')) {
      label = _json['label'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (createTimeMs != null) 'createTimeMs': createTimeMs!,
        if (deprecatedMarketplaceDealParty != null)
          'deprecatedMarketplaceDealParty':
              deprecatedMarketplaceDealParty!.toJson(),
        if (label != null) 'label': label!,
      };
}

/// A proposal is associated with a bunch of notes which may optionally be
/// associated with a deal and/or revision number.
class MarketplaceNote {
  /// The role of the person (buyer/seller) creating the note.
  ///
  /// (readonly)
  core.String? creatorRole;

  /// Notes can optionally be associated with a deal.
  ///
  /// (readonly, except on create)
  core.String? dealId;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "adexchangebuyer#marketplaceNote".
  core.String? kind;

  /// The actual note to attach.
  ///
  /// (readonly, except on create)
  core.String? note;

  /// The unique id for the note.
  ///
  /// (readonly)
  core.String? noteId;

  /// The proposalId that a note is attached to.
  ///
  /// (readonly)
  core.String? proposalId;

  /// If the note is associated with a proposal revision number, then store that
  /// here.
  ///
  /// (readonly, except on create)
  core.String? proposalRevisionNumber;

  /// The timestamp (ms since epoch) that this note was created.
  ///
  /// (readonly)
  core.String? timestampMs;

  MarketplaceNote();

  MarketplaceNote.fromJson(core.Map _json) {
    if (_json.containsKey('creatorRole')) {
      creatorRole = _json['creatorRole'] as core.String;
    }
    if (_json.containsKey('dealId')) {
      dealId = _json['dealId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('note')) {
      note = _json['note'] as core.String;
    }
    if (_json.containsKey('noteId')) {
      noteId = _json['noteId'] as core.String;
    }
    if (_json.containsKey('proposalId')) {
      proposalId = _json['proposalId'] as core.String;
    }
    if (_json.containsKey('proposalRevisionNumber')) {
      proposalRevisionNumber = _json['proposalRevisionNumber'] as core.String;
    }
    if (_json.containsKey('timestampMs')) {
      timestampMs = _json['timestampMs'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creatorRole != null) 'creatorRole': creatorRole!,
        if (dealId != null) 'dealId': dealId!,
        if (kind != null) 'kind': kind!,
        if (note != null) 'note': note!,
        if (noteId != null) 'noteId': noteId!,
        if (proposalId != null) 'proposalId': proposalId!,
        if (proposalRevisionNumber != null)
          'proposalRevisionNumber': proposalRevisionNumber!,
        if (timestampMs != null) 'timestampMs': timestampMs!,
      };
}

class MobileApplication {
  core.String? appStore;
  core.String? externalAppId;

  MobileApplication();

  MobileApplication.fromJson(core.Map _json) {
    if (_json.containsKey('appStore')) {
      appStore = _json['appStore'] as core.String;
    }
    if (_json.containsKey('externalAppId')) {
      externalAppId = _json['externalAppId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appStore != null) 'appStore': appStore!,
        if (externalAppId != null) 'externalAppId': externalAppId!,
      };
}

/// The configuration data for an Ad Exchange performance report list.
class PerformanceReport {
  /// The number of bid responses with an ad.
  core.double? bidRate;

  /// The number of bid requests sent to your bidder.
  core.double? bidRequestRate;

  /// Rate of various prefiltering statuses per match.
  ///
  /// Please refer to the callout-status-codes.txt file for different statuses.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Object>? calloutStatusRate;

  /// Average QPS for cookie matcher operations.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Object>? cookieMatcherStatusRate;

  /// Rate of ads with a given status.
  ///
  /// Please refer to the creative-status-codes.txt file for different statuses.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Object>? creativeStatusRate;

  /// The number of bid responses that were filtered due to a policy violation
  /// or other errors.
  core.double? filteredBidRate;

  /// Average QPS for hosted match operations.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Object>? hostedMatchStatusRate;

  /// The number of potential queries based on your pretargeting settings.
  core.double? inventoryMatchRate;

  /// Resource type.
  core.String? kind;

  /// The 50th percentile round trip latency(ms) as perceived from Google
  /// servers for the duration period covered by the report.
  core.double? latency50thPercentile;

  /// The 85th percentile round trip latency(ms) as perceived from Google
  /// servers for the duration period covered by the report.
  core.double? latency85thPercentile;

  /// The 95th percentile round trip latency(ms) as perceived from Google
  /// servers for the duration period covered by the report.
  core.double? latency95thPercentile;

  /// Rate of various quota account statuses per quota check.
  core.double? noQuotaInRegion;

  /// Rate of various quota account statuses per quota check.
  core.double? outOfQuota;

  /// Average QPS for pixel match requests from clients.
  core.double? pixelMatchRequests;

  /// Average QPS for pixel match responses from clients.
  core.double? pixelMatchResponses;

  /// The configured quota limits for this account.
  core.double? quotaConfiguredLimit;

  /// The throttled quota limits for this account.
  core.double? quotaThrottledLimit;

  /// The trading location of this data.
  core.String? region;

  /// The number of properly formed bid responses received by our servers within
  /// the deadline.
  core.double? successfulRequestRate;

  /// The unix timestamp of the starting time of this performance data.
  core.String? timestamp;

  /// The number of bid responses that were unsuccessful due to timeouts,
  /// incorrect formatting, etc.
  core.double? unsuccessfulRequestRate;

  PerformanceReport();

  PerformanceReport.fromJson(core.Map _json) {
    if (_json.containsKey('bidRate')) {
      bidRate = (_json['bidRate'] as core.num).toDouble();
    }
    if (_json.containsKey('bidRequestRate')) {
      bidRequestRate = (_json['bidRequestRate'] as core.num).toDouble();
    }
    if (_json.containsKey('calloutStatusRate')) {
      calloutStatusRate = (_json['calloutStatusRate'] as core.List)
          .map<core.Object>((value) => value as core.Object)
          .toList();
    }
    if (_json.containsKey('cookieMatcherStatusRate')) {
      cookieMatcherStatusRate = (_json['cookieMatcherStatusRate'] as core.List)
          .map<core.Object>((value) => value as core.Object)
          .toList();
    }
    if (_json.containsKey('creativeStatusRate')) {
      creativeStatusRate = (_json['creativeStatusRate'] as core.List)
          .map<core.Object>((value) => value as core.Object)
          .toList();
    }
    if (_json.containsKey('filteredBidRate')) {
      filteredBidRate = (_json['filteredBidRate'] as core.num).toDouble();
    }
    if (_json.containsKey('hostedMatchStatusRate')) {
      hostedMatchStatusRate = (_json['hostedMatchStatusRate'] as core.List)
          .map<core.Object>((value) => value as core.Object)
          .toList();
    }
    if (_json.containsKey('inventoryMatchRate')) {
      inventoryMatchRate = (_json['inventoryMatchRate'] as core.num).toDouble();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('latency50thPercentile')) {
      latency50thPercentile =
          (_json['latency50thPercentile'] as core.num).toDouble();
    }
    if (_json.containsKey('latency85thPercentile')) {
      latency85thPercentile =
          (_json['latency85thPercentile'] as core.num).toDouble();
    }
    if (_json.containsKey('latency95thPercentile')) {
      latency95thPercentile =
          (_json['latency95thPercentile'] as core.num).toDouble();
    }
    if (_json.containsKey('noQuotaInRegion')) {
      noQuotaInRegion = (_json['noQuotaInRegion'] as core.num).toDouble();
    }
    if (_json.containsKey('outOfQuota')) {
      outOfQuota = (_json['outOfQuota'] as core.num).toDouble();
    }
    if (_json.containsKey('pixelMatchRequests')) {
      pixelMatchRequests = (_json['pixelMatchRequests'] as core.num).toDouble();
    }
    if (_json.containsKey('pixelMatchResponses')) {
      pixelMatchResponses =
          (_json['pixelMatchResponses'] as core.num).toDouble();
    }
    if (_json.containsKey('quotaConfiguredLimit')) {
      quotaConfiguredLimit =
          (_json['quotaConfiguredLimit'] as core.num).toDouble();
    }
    if (_json.containsKey('quotaThrottledLimit')) {
      quotaThrottledLimit =
          (_json['quotaThrottledLimit'] as core.num).toDouble();
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('successfulRequestRate')) {
      successfulRequestRate =
          (_json['successfulRequestRate'] as core.num).toDouble();
    }
    if (_json.containsKey('timestamp')) {
      timestamp = _json['timestamp'] as core.String;
    }
    if (_json.containsKey('unsuccessfulRequestRate')) {
      unsuccessfulRequestRate =
          (_json['unsuccessfulRequestRate'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bidRate != null) 'bidRate': bidRate!,
        if (bidRequestRate != null) 'bidRequestRate': bidRequestRate!,
        if (calloutStatusRate != null) 'calloutStatusRate': calloutStatusRate!,
        if (cookieMatcherStatusRate != null)
          'cookieMatcherStatusRate': cookieMatcherStatusRate!,
        if (creativeStatusRate != null)
          'creativeStatusRate': creativeStatusRate!,
        if (filteredBidRate != null) 'filteredBidRate': filteredBidRate!,
        if (hostedMatchStatusRate != null)
          'hostedMatchStatusRate': hostedMatchStatusRate!,
        if (inventoryMatchRate != null)
          'inventoryMatchRate': inventoryMatchRate!,
        if (kind != null) 'kind': kind!,
        if (latency50thPercentile != null)
          'latency50thPercentile': latency50thPercentile!,
        if (latency85thPercentile != null)
          'latency85thPercentile': latency85thPercentile!,
        if (latency95thPercentile != null)
          'latency95thPercentile': latency95thPercentile!,
        if (noQuotaInRegion != null) 'noQuotaInRegion': noQuotaInRegion!,
        if (outOfQuota != null) 'outOfQuota': outOfQuota!,
        if (pixelMatchRequests != null)
          'pixelMatchRequests': pixelMatchRequests!,
        if (pixelMatchResponses != null)
          'pixelMatchResponses': pixelMatchResponses!,
        if (quotaConfiguredLimit != null)
          'quotaConfiguredLimit': quotaConfiguredLimit!,
        if (quotaThrottledLimit != null)
          'quotaThrottledLimit': quotaThrottledLimit!,
        if (region != null) 'region': region!,
        if (successfulRequestRate != null)
          'successfulRequestRate': successfulRequestRate!,
        if (timestamp != null) 'timestamp': timestamp!,
        if (unsuccessfulRequestRate != null)
          'unsuccessfulRequestRate': unsuccessfulRequestRate!,
      };
}

/// The configuration data for an Ad Exchange performance report list.
class PerformanceReportList {
  /// Resource type.
  core.String? kind;

  /// A list of performance reports relevant for the account.
  core.List<PerformanceReport>? performanceReport;

  PerformanceReportList();

  PerformanceReportList.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('performanceReport')) {
      performanceReport = (_json['performanceReport'] as core.List)
          .map<PerformanceReport>((value) => PerformanceReport.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (performanceReport != null)
          'performanceReport':
              performanceReport!.map((value) => value.toJson()).toList(),
      };
}

class PretargetingConfigDimensions {
  /// Height in pixels.
  core.String? height;

  /// Width in pixels.
  core.String? width;

  PretargetingConfigDimensions();

  PretargetingConfigDimensions.fromJson(core.Map _json) {
    if (_json.containsKey('height')) {
      height = _json['height'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (height != null) 'height': height!,
        if (width != null) 'width': width!,
      };
}

class PretargetingConfigExcludedPlacements {
  /// The value of the placement.
  ///
  /// Interpretation depends on the placement type, e.g. URL for a site
  /// placement, channel name for a channel placement, app id for a mobile app
  /// placement.
  core.String? token;

  /// The type of the placement.
  core.String? type;

  PretargetingConfigExcludedPlacements();

  PretargetingConfigExcludedPlacements.fromJson(core.Map _json) {
    if (_json.containsKey('token')) {
      token = _json['token'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (token != null) 'token': token!,
        if (type != null) 'type': type!,
      };
}

class PretargetingConfigPlacements {
  /// The value of the placement.
  ///
  /// Interpretation depends on the placement type, e.g. URL for a site
  /// placement, channel name for a channel placement, app id for a mobile app
  /// placement.
  core.String? token;

  /// The type of the placement.
  core.String? type;

  PretargetingConfigPlacements();

  PretargetingConfigPlacements.fromJson(core.Map _json) {
    if (_json.containsKey('token')) {
      token = _json['token'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (token != null) 'token': token!,
        if (type != null) 'type': type!,
      };
}

class PretargetingConfigVideoPlayerSizes {
  /// The type of aspect ratio.
  ///
  /// Leave this field blank to match all aspect ratios.
  core.String? aspectRatio;

  /// The minimum player height in pixels.
  ///
  /// Leave this field blank to match any player height.
  core.String? minHeight;

  /// The minimum player width in pixels.
  ///
  /// Leave this field blank to match any player width.
  core.String? minWidth;

  PretargetingConfigVideoPlayerSizes();

  PretargetingConfigVideoPlayerSizes.fromJson(core.Map _json) {
    if (_json.containsKey('aspectRatio')) {
      aspectRatio = _json['aspectRatio'] as core.String;
    }
    if (_json.containsKey('minHeight')) {
      minHeight = _json['minHeight'] as core.String;
    }
    if (_json.containsKey('minWidth')) {
      minWidth = _json['minWidth'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aspectRatio != null) 'aspectRatio': aspectRatio!,
        if (minHeight != null) 'minHeight': minHeight!,
        if (minWidth != null) 'minWidth': minWidth!,
      };
}

class PretargetingConfig {
  /// The id for billing purposes, provided for reference.
  ///
  /// Leave this field blank for insert requests; the id will be generated
  /// automatically.
  core.String? billingId;

  /// The config id; generated automatically.
  ///
  /// Leave this field blank for insert requests.
  core.String? configId;

  /// The name of the config.
  ///
  /// Must be unique. Required for all requests.
  core.String? configName;

  /// List must contain exactly one of PRETARGETING_CREATIVE_TYPE_HTML or
  /// PRETARGETING_CREATIVE_TYPE_VIDEO.
  core.List<core.String>? creativeType;

  /// Requests which allow one of these (width, height) pairs will match.
  ///
  /// All pairs must be supported ad dimensions.
  core.List<PretargetingConfigDimensions>? dimensions;

  /// Requests with any of these content labels will not match.
  ///
  /// Values are from content-labels.txt in the downloadable files section.
  core.List<core.String>? excludedContentLabels;

  /// Requests containing any of these geo criteria ids will not match.
  core.List<core.String>? excludedGeoCriteriaIds;

  /// Requests containing any of these placements will not match.
  core.List<PretargetingConfigExcludedPlacements>? excludedPlacements;

  /// Requests containing any of these users list ids will not match.
  core.List<core.String>? excludedUserLists;

  /// Requests containing any of these vertical ids will not match.
  ///
  /// Values are from the publisher-verticals.txt file in the downloadable files
  /// section.
  core.List<core.String>? excludedVerticals;

  /// Requests containing any of these geo criteria ids will match.
  core.List<core.String>? geoCriteriaIds;

  /// Whether this config is active.
  ///
  /// Required for all requests.
  core.bool? isActive;

  /// The kind of the resource, i.e. "adexchangebuyer#pretargetingConfig".
  core.String? kind;

  /// Request containing any of these language codes will match.
  core.List<core.String>? languages;

  /// The maximum QPS allocated to this pretargeting configuration, used for
  /// pretargeting-level QPS limits.
  ///
  /// By default, this is not set, which indicates that there is no QPS limit at
  /// the configuration level (a global or account-level limit may still be
  /// imposed).
  core.String? maximumQps;

  /// Requests where the predicted viewability is below the specified decile
  /// will not match.
  ///
  /// E.g. if the buyer sets this value to 5, requests from slots where the
  /// predicted viewability is below 50% will not match. If the predicted
  /// viewability is unknown this field will be ignored.
  core.int? minimumViewabilityDecile;

  /// Requests containing any of these mobile carrier ids will match.
  ///
  /// Values are from mobile-carriers.csv in the downloadable files section.
  core.List<core.String>? mobileCarriers;

  /// Requests containing any of these mobile device ids will match.
  ///
  /// Values are from mobile-devices.csv in the downloadable files section.
  core.List<core.String>? mobileDevices;

  /// Requests containing any of these mobile operating system version ids will
  /// match.
  ///
  /// Values are from mobile-os.csv in the downloadable files section.
  core.List<core.String>? mobileOperatingSystemVersions;

  /// Requests containing any of these placements will match.
  core.List<PretargetingConfigPlacements>? placements;

  /// Requests matching any of these platforms will match.
  ///
  /// Possible values are PRETARGETING_PLATFORM_MOBILE,
  /// PRETARGETING_PLATFORM_DESKTOP, and PRETARGETING_PLATFORM_TABLET.
  core.List<core.String>? platforms;

  /// Creative attributes should be declared here if all creatives corresponding
  /// to this pretargeting configuration have that creative attribute.
  ///
  /// Values are from pretargetable-creative-attributes.txt in the downloadable
  /// files section.
  core.List<core.String>? supportedCreativeAttributes;

  /// Requests containing the specified type of user data will match.
  ///
  /// Possible values are HOSTED_MATCH_DATA, which means the request is
  /// cookie-targetable and has a match in the buyer's hosted match table, and
  /// COOKIE_OR_IDFA, which means the request has either a targetable cookie or
  /// an iOS IDFA.
  core.List<core.String>? userIdentifierDataRequired;

  /// Requests containing any of these user list ids will match.
  core.List<core.String>? userLists;

  /// Requests that allow any of these vendor ids will match.
  ///
  /// Values are from vendors.txt in the downloadable files section.
  core.List<core.String>? vendorTypes;

  /// Requests containing any of these vertical ids will match.
  core.List<core.String>? verticals;

  /// Video requests satisfying any of these player size constraints will match.
  core.List<PretargetingConfigVideoPlayerSizes>? videoPlayerSizes;

  PretargetingConfig();

  PretargetingConfig.fromJson(core.Map _json) {
    if (_json.containsKey('billingId')) {
      billingId = _json['billingId'] as core.String;
    }
    if (_json.containsKey('configId')) {
      configId = _json['configId'] as core.String;
    }
    if (_json.containsKey('configName')) {
      configName = _json['configName'] as core.String;
    }
    if (_json.containsKey('creativeType')) {
      creativeType = (_json['creativeType'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('dimensions')) {
      dimensions = (_json['dimensions'] as core.List)
          .map<PretargetingConfigDimensions>((value) =>
              PretargetingConfigDimensions.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('excludedContentLabels')) {
      excludedContentLabels = (_json['excludedContentLabels'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('excludedGeoCriteriaIds')) {
      excludedGeoCriteriaIds = (_json['excludedGeoCriteriaIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('excludedPlacements')) {
      excludedPlacements = (_json['excludedPlacements'] as core.List)
          .map<PretargetingConfigExcludedPlacements>((value) =>
              PretargetingConfigExcludedPlacements.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('excludedUserLists')) {
      excludedUserLists = (_json['excludedUserLists'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('excludedVerticals')) {
      excludedVerticals = (_json['excludedVerticals'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('geoCriteriaIds')) {
      geoCriteriaIds = (_json['geoCriteriaIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('isActive')) {
      isActive = _json['isActive'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('languages')) {
      languages = (_json['languages'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('maximumQps')) {
      maximumQps = _json['maximumQps'] as core.String;
    }
    if (_json.containsKey('minimumViewabilityDecile')) {
      minimumViewabilityDecile = _json['minimumViewabilityDecile'] as core.int;
    }
    if (_json.containsKey('mobileCarriers')) {
      mobileCarriers = (_json['mobileCarriers'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('mobileDevices')) {
      mobileDevices = (_json['mobileDevices'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('mobileOperatingSystemVersions')) {
      mobileOperatingSystemVersions =
          (_json['mobileOperatingSystemVersions'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('placements')) {
      placements = (_json['placements'] as core.List)
          .map<PretargetingConfigPlacements>((value) =>
              PretargetingConfigPlacements.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('platforms')) {
      platforms = (_json['platforms'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('supportedCreativeAttributes')) {
      supportedCreativeAttributes =
          (_json['supportedCreativeAttributes'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('userIdentifierDataRequired')) {
      userIdentifierDataRequired =
          (_json['userIdentifierDataRequired'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('userLists')) {
      userLists = (_json['userLists'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('vendorTypes')) {
      vendorTypes = (_json['vendorTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('verticals')) {
      verticals = (_json['verticals'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('videoPlayerSizes')) {
      videoPlayerSizes = (_json['videoPlayerSizes'] as core.List)
          .map<PretargetingConfigVideoPlayerSizes>((value) =>
              PretargetingConfigVideoPlayerSizes.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (billingId != null) 'billingId': billingId!,
        if (configId != null) 'configId': configId!,
        if (configName != null) 'configName': configName!,
        if (creativeType != null) 'creativeType': creativeType!,
        if (dimensions != null)
          'dimensions': dimensions!.map((value) => value.toJson()).toList(),
        if (excludedContentLabels != null)
          'excludedContentLabels': excludedContentLabels!,
        if (excludedGeoCriteriaIds != null)
          'excludedGeoCriteriaIds': excludedGeoCriteriaIds!,
        if (excludedPlacements != null)
          'excludedPlacements':
              excludedPlacements!.map((value) => value.toJson()).toList(),
        if (excludedUserLists != null) 'excludedUserLists': excludedUserLists!,
        if (excludedVerticals != null) 'excludedVerticals': excludedVerticals!,
        if (geoCriteriaIds != null) 'geoCriteriaIds': geoCriteriaIds!,
        if (isActive != null) 'isActive': isActive!,
        if (kind != null) 'kind': kind!,
        if (languages != null) 'languages': languages!,
        if (maximumQps != null) 'maximumQps': maximumQps!,
        if (minimumViewabilityDecile != null)
          'minimumViewabilityDecile': minimumViewabilityDecile!,
        if (mobileCarriers != null) 'mobileCarriers': mobileCarriers!,
        if (mobileDevices != null) 'mobileDevices': mobileDevices!,
        if (mobileOperatingSystemVersions != null)
          'mobileOperatingSystemVersions': mobileOperatingSystemVersions!,
        if (placements != null)
          'placements': placements!.map((value) => value.toJson()).toList(),
        if (platforms != null) 'platforms': platforms!,
        if (supportedCreativeAttributes != null)
          'supportedCreativeAttributes': supportedCreativeAttributes!,
        if (userIdentifierDataRequired != null)
          'userIdentifierDataRequired': userIdentifierDataRequired!,
        if (userLists != null) 'userLists': userLists!,
        if (vendorTypes != null) 'vendorTypes': vendorTypes!,
        if (verticals != null) 'verticals': verticals!,
        if (videoPlayerSizes != null)
          'videoPlayerSizes':
              videoPlayerSizes!.map((value) => value.toJson()).toList(),
      };
}

class PretargetingConfigList {
  /// A list of pretargeting configs
  core.List<PretargetingConfig>? items;

  /// Resource type.
  core.String? kind;

  PretargetingConfigList();

  PretargetingConfigList.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<PretargetingConfig>((value) => PretargetingConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class Price {
  /// The price value in micros.
  core.double? amountMicros;

  /// The currency code for the price.
  core.String? currencyCode;

  /// In case of CPD deals, the expected CPM in micros.
  core.double? expectedCpmMicros;

  /// The pricing type for the deal/product.
  core.String? pricingType;

  Price();

  Price.fromJson(core.Map _json) {
    if (_json.containsKey('amountMicros')) {
      amountMicros = (_json['amountMicros'] as core.num).toDouble();
    }
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('expectedCpmMicros')) {
      expectedCpmMicros = (_json['expectedCpmMicros'] as core.num).toDouble();
    }
    if (_json.containsKey('pricingType')) {
      pricingType = _json['pricingType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (amountMicros != null) 'amountMicros': amountMicros!,
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (expectedCpmMicros != null) 'expectedCpmMicros': expectedCpmMicros!,
        if (pricingType != null) 'pricingType': pricingType!,
      };
}

/// Used to specify pricing rules for buyers.
///
/// Each PricePerBuyer in a product can become \[0,1\] deals. To check if there
/// is a PricePerBuyer for a particular buyer we look for the most specific
/// matching rule - we first look for a rule matching the buyer and otherwise
/// look for a matching rule where no buyer is set.
class PricePerBuyer {
  /// Optional access type for this buyer.
  core.String? auctionTier;

  /// Reference to the buyer that will get billed.
  Buyer? billedBuyer;

  /// The buyer who will pay this price.
  ///
  /// If unset, all buyers can pay this price (if the advertisers match, and
  /// there's no more specific rule matching the buyer).
  Buyer? buyer;

  /// The specified price
  Price? price;

  PricePerBuyer();

  PricePerBuyer.fromJson(core.Map _json) {
    if (_json.containsKey('auctionTier')) {
      auctionTier = _json['auctionTier'] as core.String;
    }
    if (_json.containsKey('billedBuyer')) {
      billedBuyer = Buyer.fromJson(
          _json['billedBuyer'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('buyer')) {
      buyer =
          Buyer.fromJson(_json['buyer'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('price')) {
      price =
          Price.fromJson(_json['price'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auctionTier != null) 'auctionTier': auctionTier!,
        if (billedBuyer != null) 'billedBuyer': billedBuyer!.toJson(),
        if (buyer != null) 'buyer': buyer!.toJson(),
        if (price != null) 'price': price!.toJson(),
      };
}

class PrivateData {
  core.String? referenceId;
  core.String? referencePayload;
  core.List<core.int> get referencePayloadAsBytes =>
      convert.base64.decode(referencePayload!);

  set referencePayloadAsBytes(core.List<core.int> _bytes) {
    referencePayload =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  PrivateData();

  PrivateData.fromJson(core.Map _json) {
    if (_json.containsKey('referenceId')) {
      referenceId = _json['referenceId'] as core.String;
    }
    if (_json.containsKey('referencePayload')) {
      referencePayload = _json['referencePayload'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (referenceId != null) 'referenceId': referenceId!,
        if (referencePayload != null) 'referencePayload': referencePayload!,
      };
}

/// A product is segment of inventory that a seller wishes to sell.
///
/// It is associated with certain terms and targeting information which helps
/// buyer know more about the inventory. Each field in a product can have one of
/// the following setting:
///
/// (readonly) - It is an error to try and set this field. (buyer-readonly) -
/// Only the seller can set this field. (seller-readonly) - Only the buyer can
/// set this field. (updatable) - The field is updatable at all times by either
/// buyer or the seller.
class Product {
  /// The billed buyer corresponding to the buyer that created the offer.
  ///
  /// (readonly, except on create)
  Buyer? billedBuyer;

  /// The buyer that created the offer if this is a buyer initiated offer
  /// (readonly, except on create)
  Buyer? buyer;

  /// Creation time in ms.
  ///
  /// since epoch (readonly)
  core.String? creationTimeMs;

  /// Optional contact information for the creator of this product.
  ///
  /// (buyer-readonly)
  core.List<ContactInformation>? creatorContacts;

  /// The role that created the offer.
  ///
  /// Set to BUYER for buyer initiated offers.
  core.String? creatorRole;

  /// The set of fields around delivery control that are interesting for a buyer
  /// to see but are non-negotiable.
  ///
  /// These are set by the publisher. This message is assigned an id of 100
  /// since some day we would want to model this as a protobuf extension.
  DeliveryControl? deliveryControl;

  /// The proposed end time for the deal (ms since epoch) (buyer-readonly)
  core.String? flightEndTimeMs;

  /// Inventory availability dates.
  ///
  /// (times are in ms since epoch) The granularity is generally in the order of
  /// seconds. (buyer-readonly)
  core.String? flightStartTimeMs;

  /// If the creator has already signed off on the product, then the buyer can
  /// finalize the deal by accepting the product as is.
  ///
  /// When copying to a proposal, if any of the terms are changed, then
  /// auto_finalize is automatically set to false.
  core.bool? hasCreatorSignedOff;

  /// What exchange will provide this inventory (readonly, except on create).
  core.String? inventorySource;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "adexchangebuyer#product".
  core.String? kind;

  /// Optional List of labels for the product (optional, buyer-readonly).
  core.List<MarketplaceLabel>? labels;

  /// Time of last update in ms.
  ///
  /// since epoch (readonly)
  core.String? lastUpdateTimeMs;

  /// Optional legacy offer id if this offer is a preferred deal offer.
  core.String? legacyOfferId;

  /// Marketplace publisher profile Id.
  ///
  /// This Id differs from the regular publisher_profile_id in that 1. This is a
  /// new id, the old Id will be deprecated in 2017. 2. This id uniquely
  /// identifies a publisher profile by itself.
  core.String? marketplacePublisherProfileId;

  /// The name for this product as set by the seller.
  ///
  /// (buyer-readonly)
  core.String? name;

  /// Optional private auction id if this offer is a private auction offer.
  core.String? privateAuctionId;

  /// The unique id for the product (readonly)
  core.String? productId;

  /// Id of the publisher profile for a given seller.
  ///
  /// A (seller.account_id, publisher_profile_id) pair uniquely identifies a
  /// publisher profile. Buyers can call the PublisherProfiles::List endpoint to
  /// get a list of publisher profiles for a given seller.
  core.String? publisherProfileId;

  /// Publisher self-provided forecast information.
  PublisherProvidedForecast? publisherProvidedForecast;

  /// The revision number of the product.
  ///
  /// (readonly)
  core.String? revisionNumber;

  /// Information about the seller that created this product (readonly, except
  /// on create)
  Seller? seller;

  /// Targeting that is shared between the buyer and the seller.
  ///
  /// Each targeting criteria has a specified key and for each key there is a
  /// list of inclusion value or exclusion values. (buyer-readonly)
  core.List<SharedTargeting>? sharedTargetings;

  /// The state of the product.
  ///
  /// (buyer-readonly)
  core.String? state;

  /// The syndication product associated with the deal.
  ///
  /// (readonly, except on create)
  core.String? syndicationProduct;

  /// The negotiable terms of the deal (buyer-readonly)
  DealTerms? terms;

  /// The web property code for the seller.
  ///
  /// This field is meant to be copied over as is when creating deals.
  core.String? webPropertyCode;

  Product();

  Product.fromJson(core.Map _json) {
    if (_json.containsKey('billedBuyer')) {
      billedBuyer = Buyer.fromJson(
          _json['billedBuyer'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('buyer')) {
      buyer =
          Buyer.fromJson(_json['buyer'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('creationTimeMs')) {
      creationTimeMs = _json['creationTimeMs'] as core.String;
    }
    if (_json.containsKey('creatorContacts')) {
      creatorContacts = (_json['creatorContacts'] as core.List)
          .map<ContactInformation>((value) => ContactInformation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('creatorRole')) {
      creatorRole = _json['creatorRole'] as core.String;
    }
    if (_json.containsKey('deliveryControl')) {
      deliveryControl = DeliveryControl.fromJson(
          _json['deliveryControl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('flightEndTimeMs')) {
      flightEndTimeMs = _json['flightEndTimeMs'] as core.String;
    }
    if (_json.containsKey('flightStartTimeMs')) {
      flightStartTimeMs = _json['flightStartTimeMs'] as core.String;
    }
    if (_json.containsKey('hasCreatorSignedOff')) {
      hasCreatorSignedOff = _json['hasCreatorSignedOff'] as core.bool;
    }
    if (_json.containsKey('inventorySource')) {
      inventorySource = _json['inventorySource'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.List)
          .map<MarketplaceLabel>((value) => MarketplaceLabel.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('lastUpdateTimeMs')) {
      lastUpdateTimeMs = _json['lastUpdateTimeMs'] as core.String;
    }
    if (_json.containsKey('legacyOfferId')) {
      legacyOfferId = _json['legacyOfferId'] as core.String;
    }
    if (_json.containsKey('marketplacePublisherProfileId')) {
      marketplacePublisherProfileId =
          _json['marketplacePublisherProfileId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('privateAuctionId')) {
      privateAuctionId = _json['privateAuctionId'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('publisherProfileId')) {
      publisherProfileId = _json['publisherProfileId'] as core.String;
    }
    if (_json.containsKey('publisherProvidedForecast')) {
      publisherProvidedForecast = PublisherProvidedForecast.fromJson(
          _json['publisherProvidedForecast']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('revisionNumber')) {
      revisionNumber = _json['revisionNumber'] as core.String;
    }
    if (_json.containsKey('seller')) {
      seller = Seller.fromJson(
          _json['seller'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sharedTargetings')) {
      sharedTargetings = (_json['sharedTargetings'] as core.List)
          .map<SharedTargeting>((value) => SharedTargeting.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('syndicationProduct')) {
      syndicationProduct = _json['syndicationProduct'] as core.String;
    }
    if (_json.containsKey('terms')) {
      terms = DealTerms.fromJson(
          _json['terms'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('webPropertyCode')) {
      webPropertyCode = _json['webPropertyCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (billedBuyer != null) 'billedBuyer': billedBuyer!.toJson(),
        if (buyer != null) 'buyer': buyer!.toJson(),
        if (creationTimeMs != null) 'creationTimeMs': creationTimeMs!,
        if (creatorContacts != null)
          'creatorContacts':
              creatorContacts!.map((value) => value.toJson()).toList(),
        if (creatorRole != null) 'creatorRole': creatorRole!,
        if (deliveryControl != null)
          'deliveryControl': deliveryControl!.toJson(),
        if (flightEndTimeMs != null) 'flightEndTimeMs': flightEndTimeMs!,
        if (flightStartTimeMs != null) 'flightStartTimeMs': flightStartTimeMs!,
        if (hasCreatorSignedOff != null)
          'hasCreatorSignedOff': hasCreatorSignedOff!,
        if (inventorySource != null) 'inventorySource': inventorySource!,
        if (kind != null) 'kind': kind!,
        if (labels != null)
          'labels': labels!.map((value) => value.toJson()).toList(),
        if (lastUpdateTimeMs != null) 'lastUpdateTimeMs': lastUpdateTimeMs!,
        if (legacyOfferId != null) 'legacyOfferId': legacyOfferId!,
        if (marketplacePublisherProfileId != null)
          'marketplacePublisherProfileId': marketplacePublisherProfileId!,
        if (name != null) 'name': name!,
        if (privateAuctionId != null) 'privateAuctionId': privateAuctionId!,
        if (productId != null) 'productId': productId!,
        if (publisherProfileId != null)
          'publisherProfileId': publisherProfileId!,
        if (publisherProvidedForecast != null)
          'publisherProvidedForecast': publisherProvidedForecast!.toJson(),
        if (revisionNumber != null) 'revisionNumber': revisionNumber!,
        if (seller != null) 'seller': seller!.toJson(),
        if (sharedTargetings != null)
          'sharedTargetings':
              sharedTargetings!.map((value) => value.toJson()).toList(),
        if (state != null) 'state': state!,
        if (syndicationProduct != null)
          'syndicationProduct': syndicationProduct!,
        if (terms != null) 'terms': terms!.toJson(),
        if (webPropertyCode != null) 'webPropertyCode': webPropertyCode!,
      };
}

/// Represents a proposal in the marketplace.
///
/// A proposal is the unit of negotiation between a seller and a buyer and
/// contains deals which are served. Each field in a proposal can have one of
/// the following setting:
///
/// (readonly) - It is an error to try and set this field. (buyer-readonly) -
/// Only the seller can set this field. (seller-readonly) - Only the buyer can
/// set this field. (updatable) - The field is updatable at all times by either
/// buyer or the seller.
class Proposal {
  /// Reference to the buyer that will get billed for this proposal.
  ///
  /// (readonly)
  Buyer? billedBuyer;

  /// Reference to the buyer on the proposal.
  ///
  /// (readonly, except on create)
  Buyer? buyer;

  /// Optional contact information of the buyer.
  ///
  /// (seller-readonly)
  core.List<ContactInformation>? buyerContacts;

  /// Private data for buyer.
  ///
  /// (hidden from seller).
  PrivateData? buyerPrivateData;

  /// IDs of DBM advertisers permission to this proposal.
  core.List<core.String>? dbmAdvertiserIds;

  /// When an proposal is in an accepted state, indicates whether the buyer has
  /// signed off.
  ///
  /// Once both sides have signed off on a deal, the proposal can be finalized
  /// by the seller. (seller-readonly)
  core.bool? hasBuyerSignedOff;

  /// When an proposal is in an accepted state, indicates whether the buyer has
  /// signed off Once both sides have signed off on a deal, the proposal can be
  /// finalized by the seller.
  ///
  /// (buyer-readonly)
  core.bool? hasSellerSignedOff;

  /// What exchange will provide this inventory (readonly, except on create).
  core.String? inventorySource;

  /// True if the proposal is being renegotiated (readonly).
  core.bool? isRenegotiating;

  /// True, if the buyside inventory setup is complete for this proposal.
  ///
  /// (readonly, except via OrderSetupCompleted action) Deprecated in favor of
  /// deal level setup complete flag.
  core.bool? isSetupComplete;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "adexchangebuyer#proposal".
  core.String? kind;

  /// List of labels associated with the proposal.
  ///
  /// (readonly)
  core.List<MarketplaceLabel>? labels;

  /// The role of the last user that either updated the proposal or left a
  /// comment.
  ///
  /// (readonly)
  core.String? lastUpdaterOrCommentorRole;

  /// The name for the proposal (updatable)
  core.String? name;

  /// Optional negotiation id if this proposal is a preferred deal proposal.
  core.String? negotiationId;

  /// Indicates whether the buyer/seller created the proposal.(readonly)
  core.String? originatorRole;

  /// Optional private auction id if this proposal is a private auction
  /// proposal.
  core.String? privateAuctionId;

  /// The unique id of the proposal.
  ///
  /// (readonly).
  core.String? proposalId;

  /// The current state of the proposal.
  ///
  /// (readonly)
  core.String? proposalState;

  /// The revision number for the proposal (readonly).
  core.String? revisionNumber;

  /// The time (ms since epoch) when the proposal was last revised (readonly).
  core.String? revisionTimeMs;

  /// Reference to the seller on the proposal.
  ///
  /// (readonly, except on create)
  Seller? seller;

  /// Optional contact information of the seller (buyer-readonly).
  core.List<ContactInformation>? sellerContacts;

  Proposal();

  Proposal.fromJson(core.Map _json) {
    if (_json.containsKey('billedBuyer')) {
      billedBuyer = Buyer.fromJson(
          _json['billedBuyer'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('buyer')) {
      buyer =
          Buyer.fromJson(_json['buyer'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('buyerContacts')) {
      buyerContacts = (_json['buyerContacts'] as core.List)
          .map<ContactInformation>((value) => ContactInformation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('buyerPrivateData')) {
      buyerPrivateData = PrivateData.fromJson(
          _json['buyerPrivateData'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dbmAdvertiserIds')) {
      dbmAdvertiserIds = (_json['dbmAdvertiserIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('hasBuyerSignedOff')) {
      hasBuyerSignedOff = _json['hasBuyerSignedOff'] as core.bool;
    }
    if (_json.containsKey('hasSellerSignedOff')) {
      hasSellerSignedOff = _json['hasSellerSignedOff'] as core.bool;
    }
    if (_json.containsKey('inventorySource')) {
      inventorySource = _json['inventorySource'] as core.String;
    }
    if (_json.containsKey('isRenegotiating')) {
      isRenegotiating = _json['isRenegotiating'] as core.bool;
    }
    if (_json.containsKey('isSetupComplete')) {
      isSetupComplete = _json['isSetupComplete'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.List)
          .map<MarketplaceLabel>((value) => MarketplaceLabel.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('lastUpdaterOrCommentorRole')) {
      lastUpdaterOrCommentorRole =
          _json['lastUpdaterOrCommentorRole'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('negotiationId')) {
      negotiationId = _json['negotiationId'] as core.String;
    }
    if (_json.containsKey('originatorRole')) {
      originatorRole = _json['originatorRole'] as core.String;
    }
    if (_json.containsKey('privateAuctionId')) {
      privateAuctionId = _json['privateAuctionId'] as core.String;
    }
    if (_json.containsKey('proposalId')) {
      proposalId = _json['proposalId'] as core.String;
    }
    if (_json.containsKey('proposalState')) {
      proposalState = _json['proposalState'] as core.String;
    }
    if (_json.containsKey('revisionNumber')) {
      revisionNumber = _json['revisionNumber'] as core.String;
    }
    if (_json.containsKey('revisionTimeMs')) {
      revisionTimeMs = _json['revisionTimeMs'] as core.String;
    }
    if (_json.containsKey('seller')) {
      seller = Seller.fromJson(
          _json['seller'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sellerContacts')) {
      sellerContacts = (_json['sellerContacts'] as core.List)
          .map<ContactInformation>((value) => ContactInformation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (billedBuyer != null) 'billedBuyer': billedBuyer!.toJson(),
        if (buyer != null) 'buyer': buyer!.toJson(),
        if (buyerContacts != null)
          'buyerContacts':
              buyerContacts!.map((value) => value.toJson()).toList(),
        if (buyerPrivateData != null)
          'buyerPrivateData': buyerPrivateData!.toJson(),
        if (dbmAdvertiserIds != null) 'dbmAdvertiserIds': dbmAdvertiserIds!,
        if (hasBuyerSignedOff != null) 'hasBuyerSignedOff': hasBuyerSignedOff!,
        if (hasSellerSignedOff != null)
          'hasSellerSignedOff': hasSellerSignedOff!,
        if (inventorySource != null) 'inventorySource': inventorySource!,
        if (isRenegotiating != null) 'isRenegotiating': isRenegotiating!,
        if (isSetupComplete != null) 'isSetupComplete': isSetupComplete!,
        if (kind != null) 'kind': kind!,
        if (labels != null)
          'labels': labels!.map((value) => value.toJson()).toList(),
        if (lastUpdaterOrCommentorRole != null)
          'lastUpdaterOrCommentorRole': lastUpdaterOrCommentorRole!,
        if (name != null) 'name': name!,
        if (negotiationId != null) 'negotiationId': negotiationId!,
        if (originatorRole != null) 'originatorRole': originatorRole!,
        if (privateAuctionId != null) 'privateAuctionId': privateAuctionId!,
        if (proposalId != null) 'proposalId': proposalId!,
        if (proposalState != null) 'proposalState': proposalState!,
        if (revisionNumber != null) 'revisionNumber': revisionNumber!,
        if (revisionTimeMs != null) 'revisionTimeMs': revisionTimeMs!,
        if (seller != null) 'seller': seller!.toJson(),
        if (sellerContacts != null)
          'sellerContacts':
              sellerContacts!.map((value) => value.toJson()).toList(),
      };
}

class PublisherProfileApiProto {
  /// Publisher provided info on its audience.
  core.String? audience;

  /// A pitch statement for the buyer
  core.String? buyerPitchStatement;

  /// Direct contact for the publisher profile.
  core.String? directContact;

  /// Exchange where this publisher profile is from.
  ///
  /// E.g. AdX, Rubicon etc...
  core.String? exchange;
  core.String? forecastInventory;

  /// Link to publisher's Google+ page.
  core.String? googlePlusLink;

  /// True, if this is the parent profile, which represents all domains owned by
  /// the publisher.
  core.bool? isParent;

  /// True, if this profile is published.
  ///
  /// Deprecated for state.
  core.bool? isPublished;

  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "adexchangebuyer#publisherProfileApiProto".
  core.String? kind;

  /// The url to the logo for the publisher.
  core.String? logoUrl;

  /// The url for additional marketing and sales materials.
  core.String? mediaKitLink;
  core.String? name;

  /// Publisher provided overview.
  core.String? overview;

  /// The pair of (seller.account_id, profile_id) uniquely identifies a
  /// publisher profile for a given publisher.
  core.int? profileId;

  /// Programmatic contact for the publisher profile.
  core.String? programmaticContact;

  /// The list of app IDs represented in this publisher profile.
  ///
  /// Empty if this is a parent profile. Deprecated in favor of publisher_app.
  core.List<core.String>? publisherAppIds;

  /// The list of apps represented in this publisher profile.
  ///
  /// Empty if this is a parent profile.
  core.List<MobileApplication>? publisherApps;

  /// The list of domains represented in this publisher profile.
  ///
  /// Empty if this is a parent profile.
  core.List<core.String>? publisherDomains;

  /// Unique Id for publisher profile.
  core.String? publisherProfileId;

  /// Publisher provided forecasting information.
  PublisherProvidedForecast? publisherProvidedForecast;

  /// Link to publisher rate card
  core.String? rateCardInfoLink;

  /// Link for a sample content page.
  core.String? samplePageLink;

  /// Seller of the publisher profile.
  Seller? seller;

  /// State of the publisher profile.
  core.String? state;

  /// Publisher provided key metrics and rankings.
  core.List<core.String>? topHeadlines;

  PublisherProfileApiProto();

  PublisherProfileApiProto.fromJson(core.Map _json) {
    if (_json.containsKey('audience')) {
      audience = _json['audience'] as core.String;
    }
    if (_json.containsKey('buyerPitchStatement')) {
      buyerPitchStatement = _json['buyerPitchStatement'] as core.String;
    }
    if (_json.containsKey('directContact')) {
      directContact = _json['directContact'] as core.String;
    }
    if (_json.containsKey('exchange')) {
      exchange = _json['exchange'] as core.String;
    }
    if (_json.containsKey('forecastInventory')) {
      forecastInventory = _json['forecastInventory'] as core.String;
    }
    if (_json.containsKey('googlePlusLink')) {
      googlePlusLink = _json['googlePlusLink'] as core.String;
    }
    if (_json.containsKey('isParent')) {
      isParent = _json['isParent'] as core.bool;
    }
    if (_json.containsKey('isPublished')) {
      isPublished = _json['isPublished'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('logoUrl')) {
      logoUrl = _json['logoUrl'] as core.String;
    }
    if (_json.containsKey('mediaKitLink')) {
      mediaKitLink = _json['mediaKitLink'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('overview')) {
      overview = _json['overview'] as core.String;
    }
    if (_json.containsKey('profileId')) {
      profileId = _json['profileId'] as core.int;
    }
    if (_json.containsKey('programmaticContact')) {
      programmaticContact = _json['programmaticContact'] as core.String;
    }
    if (_json.containsKey('publisherAppIds')) {
      publisherAppIds = (_json['publisherAppIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('publisherApps')) {
      publisherApps = (_json['publisherApps'] as core.List)
          .map<MobileApplication>((value) => MobileApplication.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('publisherDomains')) {
      publisherDomains = (_json['publisherDomains'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('publisherProfileId')) {
      publisherProfileId = _json['publisherProfileId'] as core.String;
    }
    if (_json.containsKey('publisherProvidedForecast')) {
      publisherProvidedForecast = PublisherProvidedForecast.fromJson(
          _json['publisherProvidedForecast']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rateCardInfoLink')) {
      rateCardInfoLink = _json['rateCardInfoLink'] as core.String;
    }
    if (_json.containsKey('samplePageLink')) {
      samplePageLink = _json['samplePageLink'] as core.String;
    }
    if (_json.containsKey('seller')) {
      seller = Seller.fromJson(
          _json['seller'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('topHeadlines')) {
      topHeadlines = (_json['topHeadlines'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audience != null) 'audience': audience!,
        if (buyerPitchStatement != null)
          'buyerPitchStatement': buyerPitchStatement!,
        if (directContact != null) 'directContact': directContact!,
        if (exchange != null) 'exchange': exchange!,
        if (forecastInventory != null) 'forecastInventory': forecastInventory!,
        if (googlePlusLink != null) 'googlePlusLink': googlePlusLink!,
        if (isParent != null) 'isParent': isParent!,
        if (isPublished != null) 'isPublished': isPublished!,
        if (kind != null) 'kind': kind!,
        if (logoUrl != null) 'logoUrl': logoUrl!,
        if (mediaKitLink != null) 'mediaKitLink': mediaKitLink!,
        if (name != null) 'name': name!,
        if (overview != null) 'overview': overview!,
        if (profileId != null) 'profileId': profileId!,
        if (programmaticContact != null)
          'programmaticContact': programmaticContact!,
        if (publisherAppIds != null) 'publisherAppIds': publisherAppIds!,
        if (publisherApps != null)
          'publisherApps':
              publisherApps!.map((value) => value.toJson()).toList(),
        if (publisherDomains != null) 'publisherDomains': publisherDomains!,
        if (publisherProfileId != null)
          'publisherProfileId': publisherProfileId!,
        if (publisherProvidedForecast != null)
          'publisherProvidedForecast': publisherProvidedForecast!.toJson(),
        if (rateCardInfoLink != null) 'rateCardInfoLink': rateCardInfoLink!,
        if (samplePageLink != null) 'samplePageLink': samplePageLink!,
        if (seller != null) 'seller': seller!.toJson(),
        if (state != null) 'state': state!,
        if (topHeadlines != null) 'topHeadlines': topHeadlines!,
      };
}

/// This message carries publisher provided forecasting information.
class PublisherProvidedForecast {
  /// Publisher provided dimensions.
  ///
  /// E.g. geo, sizes etc...
  core.List<Dimension>? dimensions;

  /// Publisher provided weekly impressions.
  core.String? weeklyImpressions;

  /// Publisher provided weekly uniques.
  core.String? weeklyUniques;

  PublisherProvidedForecast();

  PublisherProvidedForecast.fromJson(core.Map _json) {
    if (_json.containsKey('dimensions')) {
      dimensions = (_json['dimensions'] as core.List)
          .map<Dimension>((value) =>
              Dimension.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('weeklyImpressions')) {
      weeklyImpressions = _json['weeklyImpressions'] as core.String;
    }
    if (_json.containsKey('weeklyUniques')) {
      weeklyUniques = _json['weeklyUniques'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensions != null)
          'dimensions': dimensions!.map((value) => value.toJson()).toList(),
        if (weeklyImpressions != null) 'weeklyImpressions': weeklyImpressions!,
        if (weeklyUniques != null) 'weeklyUniques': weeklyUniques!,
      };
}

class Seller {
  /// The unique id for the seller.
  ///
  /// The seller fills in this field. The seller account id is then available to
  /// buyer in the product.
  core.String? accountId;

  /// Optional sub-account id for the seller.
  core.String? subAccountId;

  Seller();

  Seller.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('subAccountId')) {
      subAccountId = _json['subAccountId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (subAccountId != null) 'subAccountId': subAccountId!,
      };
}

class SharedTargeting {
  /// The list of values to exclude from targeting.
  ///
  /// Each value is AND'd together.
  core.List<TargetingValue>? exclusions;

  /// The list of value to include as part of the targeting.
  ///
  /// Each value is OR'd together.
  core.List<TargetingValue>? inclusions;

  /// The key representing the shared targeting criterion.
  core.String? key;

  SharedTargeting();

  SharedTargeting.fromJson(core.Map _json) {
    if (_json.containsKey('exclusions')) {
      exclusions = (_json['exclusions'] as core.List)
          .map<TargetingValue>((value) => TargetingValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('inclusions')) {
      inclusions = (_json['inclusions'] as core.List)
          .map<TargetingValue>((value) => TargetingValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exclusions != null)
          'exclusions': exclusions!.map((value) => value.toJson()).toList(),
        if (inclusions != null)
          'inclusions': inclusions!.map((value) => value.toJson()).toList(),
        if (key != null) 'key': key!,
      };
}

class TargetingValue {
  /// The creative size value to exclude/include.
  TargetingValueCreativeSize? creativeSizeValue;

  /// The daypart targeting to include / exclude.
  ///
  /// Filled in when the key is GOOG_DAYPART_TARGETING.
  TargetingValueDayPartTargeting? dayPartTargetingValue;
  TargetingValueDemogAgeCriteria? demogAgeCriteriaValue;
  TargetingValueDemogGenderCriteria? demogGenderCriteriaValue;

  /// The long value to exclude/include.
  core.String? longValue;
  TargetingValueRequestPlatformTargeting? requestPlatformTargetingValue;

  /// The string value to exclude/include.
  core.String? stringValue;

  TargetingValue();

  TargetingValue.fromJson(core.Map _json) {
    if (_json.containsKey('creativeSizeValue')) {
      creativeSizeValue = TargetingValueCreativeSize.fromJson(
          _json['creativeSizeValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dayPartTargetingValue')) {
      dayPartTargetingValue = TargetingValueDayPartTargeting.fromJson(
          _json['dayPartTargetingValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('demogAgeCriteriaValue')) {
      demogAgeCriteriaValue = TargetingValueDemogAgeCriteria.fromJson(
          _json['demogAgeCriteriaValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('demogGenderCriteriaValue')) {
      demogGenderCriteriaValue = TargetingValueDemogGenderCriteria.fromJson(
          _json['demogGenderCriteriaValue']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('longValue')) {
      longValue = _json['longValue'] as core.String;
    }
    if (_json.containsKey('requestPlatformTargetingValue')) {
      requestPlatformTargetingValue =
          TargetingValueRequestPlatformTargeting.fromJson(
              _json['requestPlatformTargetingValue']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('stringValue')) {
      stringValue = _json['stringValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creativeSizeValue != null)
          'creativeSizeValue': creativeSizeValue!.toJson(),
        if (dayPartTargetingValue != null)
          'dayPartTargetingValue': dayPartTargetingValue!.toJson(),
        if (demogAgeCriteriaValue != null)
          'demogAgeCriteriaValue': demogAgeCriteriaValue!.toJson(),
        if (demogGenderCriteriaValue != null)
          'demogGenderCriteriaValue': demogGenderCriteriaValue!.toJson(),
        if (longValue != null) 'longValue': longValue!,
        if (requestPlatformTargetingValue != null)
          'requestPlatformTargetingValue':
              requestPlatformTargetingValue!.toJson(),
        if (stringValue != null) 'stringValue': stringValue!,
      };
}

/// Next Id: 7
class TargetingValueCreativeSize {
  /// The formats allowed by the publisher.
  core.List<core.String>? allowedFormats;

  /// For video size type, the list of companion sizes.
  core.List<TargetingValueSize>? companionSizes;

  /// The Creative size type.
  core.String? creativeSizeType;

  /// The native template for native ad.
  core.String? nativeTemplate;

  /// For regular or video creative size type, specifies the size of the
  /// creative.
  TargetingValueSize? size;

  /// The skippable ad type for video size.
  core.String? skippableAdType;

  TargetingValueCreativeSize();

  TargetingValueCreativeSize.fromJson(core.Map _json) {
    if (_json.containsKey('allowedFormats')) {
      allowedFormats = (_json['allowedFormats'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('companionSizes')) {
      companionSizes = (_json['companionSizes'] as core.List)
          .map<TargetingValueSize>((value) => TargetingValueSize.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('creativeSizeType')) {
      creativeSizeType = _json['creativeSizeType'] as core.String;
    }
    if (_json.containsKey('nativeTemplate')) {
      nativeTemplate = _json['nativeTemplate'] as core.String;
    }
    if (_json.containsKey('size')) {
      size = TargetingValueSize.fromJson(
          _json['size'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('skippableAdType')) {
      skippableAdType = _json['skippableAdType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedFormats != null) 'allowedFormats': allowedFormats!,
        if (companionSizes != null)
          'companionSizes':
              companionSizes!.map((value) => value.toJson()).toList(),
        if (creativeSizeType != null) 'creativeSizeType': creativeSizeType!,
        if (nativeTemplate != null) 'nativeTemplate': nativeTemplate!,
        if (size != null) 'size': size!.toJson(),
        if (skippableAdType != null) 'skippableAdType': skippableAdType!,
      };
}

class TargetingValueDayPartTargeting {
  core.List<TargetingValueDayPartTargetingDayPart>? dayParts;
  core.String? timeZoneType;

  TargetingValueDayPartTargeting();

  TargetingValueDayPartTargeting.fromJson(core.Map _json) {
    if (_json.containsKey('dayParts')) {
      dayParts = (_json['dayParts'] as core.List)
          .map<TargetingValueDayPartTargetingDayPart>((value) =>
              TargetingValueDayPartTargetingDayPart.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('timeZoneType')) {
      timeZoneType = _json['timeZoneType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dayParts != null)
          'dayParts': dayParts!.map((value) => value.toJson()).toList(),
        if (timeZoneType != null) 'timeZoneType': timeZoneType!,
      };
}

class TargetingValueDayPartTargetingDayPart {
  core.String? dayOfWeek;
  core.int? endHour;
  core.int? endMinute;
  core.int? startHour;
  core.int? startMinute;

  TargetingValueDayPartTargetingDayPart();

  TargetingValueDayPartTargetingDayPart.fromJson(core.Map _json) {
    if (_json.containsKey('dayOfWeek')) {
      dayOfWeek = _json['dayOfWeek'] as core.String;
    }
    if (_json.containsKey('endHour')) {
      endHour = _json['endHour'] as core.int;
    }
    if (_json.containsKey('endMinute')) {
      endMinute = _json['endMinute'] as core.int;
    }
    if (_json.containsKey('startHour')) {
      startHour = _json['startHour'] as core.int;
    }
    if (_json.containsKey('startMinute')) {
      startMinute = _json['startMinute'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dayOfWeek != null) 'dayOfWeek': dayOfWeek!,
        if (endHour != null) 'endHour': endHour!,
        if (endMinute != null) 'endMinute': endMinute!,
        if (startHour != null) 'startHour': startHour!,
        if (startMinute != null) 'startMinute': startMinute!,
      };
}

class TargetingValueDemogAgeCriteria {
  core.List<core.String>? demogAgeCriteriaIds;

  TargetingValueDemogAgeCriteria();

  TargetingValueDemogAgeCriteria.fromJson(core.Map _json) {
    if (_json.containsKey('demogAgeCriteriaIds')) {
      demogAgeCriteriaIds = (_json['demogAgeCriteriaIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (demogAgeCriteriaIds != null)
          'demogAgeCriteriaIds': demogAgeCriteriaIds!,
      };
}

class TargetingValueDemogGenderCriteria {
  core.List<core.String>? demogGenderCriteriaIds;

  TargetingValueDemogGenderCriteria();

  TargetingValueDemogGenderCriteria.fromJson(core.Map _json) {
    if (_json.containsKey('demogGenderCriteriaIds')) {
      demogGenderCriteriaIds = (_json['demogGenderCriteriaIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (demogGenderCriteriaIds != null)
          'demogGenderCriteriaIds': demogGenderCriteriaIds!,
      };
}

class TargetingValueRequestPlatformTargeting {
  core.List<core.String>? requestPlatforms;

  TargetingValueRequestPlatformTargeting();

  TargetingValueRequestPlatformTargeting.fromJson(core.Map _json) {
    if (_json.containsKey('requestPlatforms')) {
      requestPlatforms = (_json['requestPlatforms'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (requestPlatforms != null) 'requestPlatforms': requestPlatforms!,
      };
}

class TargetingValueSize {
  /// The height of the creative.
  core.int? height;

  /// The width of the creative.
  core.int? width;

  TargetingValueSize();

  TargetingValueSize.fromJson(core.Map _json) {
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (height != null) 'height': height!,
        if (width != null) 'width': width!,
      };
}

class UpdatePrivateAuctionProposalRequest {
  /// The externalDealId of the deal to be updated.
  core.String? externalDealId;

  /// Optional note to be added.
  MarketplaceNote? note;

  /// The current revision number of the proposal to be updated.
  core.String? proposalRevisionNumber;

  /// The proposed action on the private auction proposal.
  core.String? updateAction;

  UpdatePrivateAuctionProposalRequest();

  UpdatePrivateAuctionProposalRequest.fromJson(core.Map _json) {
    if (_json.containsKey('externalDealId')) {
      externalDealId = _json['externalDealId'] as core.String;
    }
    if (_json.containsKey('note')) {
      note = MarketplaceNote.fromJson(
          _json['note'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('proposalRevisionNumber')) {
      proposalRevisionNumber = _json['proposalRevisionNumber'] as core.String;
    }
    if (_json.containsKey('updateAction')) {
      updateAction = _json['updateAction'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (externalDealId != null) 'externalDealId': externalDealId!,
        if (note != null) 'note': note!.toJson(),
        if (proposalRevisionNumber != null)
          'proposalRevisionNumber': proposalRevisionNumber!,
        if (updateAction != null) 'updateAction': updateAction!,
      };
}

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

/// Ad Exchange Buyer API - v1.3
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
/// - [DirectDealsResource]
/// - [PerformanceReportResource]
/// - [PretargetingConfigResource]
library adexchangebuyer.v1_3;

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
  DirectDealsResource get directDeals => DirectDealsResource(_requester);
  PerformanceReportResource get performanceReport =>
      PerformanceReportResource(_requester);
  PretargetingConfigResource get pretargetingConfig =>
      PretargetingConfigResource(_requester);

  AdExchangeBuyerApi(http.Client client,
      {core.String rootUrl = 'https://www.googleapis.com/',
      core.String servicePath = 'adexchangebuyer/v1.3/'})
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
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
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
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
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
  /// [maxResults] - Maximum number of entries returned on one result page. If
  /// not set, the default is 100. Optional.
  /// Value must be between "1" and "1000".
  ///
  /// [pageToken] - A continuation token, used to page through ad clients. To
  /// retrieve the next page, set this parameter to the value of "nextPageToken"
  /// from the previous response. Optional.
  ///
  /// [statusFilter] - When specified, only creatives having the given status
  /// are returned.
  /// Possible string values are:
  /// - "approved" : Creatives which have been approved.
  /// - "disapproved" : Creatives which have been disapproved.
  /// - "not_checked" : Creatives whose status is not yet checked.
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
    core.int? maxResults,
    core.String? pageToken,
    core.String? statusFilter,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (accountId != null)
        'accountId': accountId.map((item) => '${item}').toList(),
      if (buyerCreativeId != null) 'buyerCreativeId': buyerCreativeId,
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (statusFilter != null) 'statusFilter': [statusFilter],
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
}

class DirectDealsResource {
  final commons.ApiRequester _requester;

  DirectDealsResource(commons.ApiRequester client) : _requester = client;

  /// Gets one direct deal by ID.
  ///
  /// Request parameters:
  ///
  /// [id] - The direct deal id
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DirectDeal].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DirectDeal> get(
    core.String id, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'directdeals/' + commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DirectDeal.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the authenticated user's list of direct deals.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DirectDealsList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DirectDealsList> list({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'directdeals';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DirectDealsList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
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

class AccountBidderLocation {
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
        if (maximumQps != null) 'maximumQps': maximumQps!,
        if (region != null) 'region': region!,
        if (url != null) 'url': url!,
      };
}

/// Configuration data for an Ad Exchange buyer account.
class Account {
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

class CreativeCorrections {
  /// Additional details about the correction.
  core.List<core.String>? details;

  /// The type of correction that was applied to the creative.
  core.String? reason;

  CreativeCorrections();

  CreativeCorrections.fromJson(core.Map _json) {
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

class CreativeDisapprovalReasons {
  /// Additional details about the reason for disapproval.
  core.List<core.String>? details;

  /// The categorized reason for disapproval.
  core.String? reason;

  CreativeDisapprovalReasons();

  CreativeDisapprovalReasons.fromJson(core.Map _json) {
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

class CreativeFilteringReasonsReasons {
  /// The number of times the creative was filtered for the status.
  ///
  /// The count is aggregated across all publishers on the exchange.
  core.String? filteringCount;

  /// The filtering status code.
  ///
  /// Please refer to the creative-status-codes.txt file for different statuses.
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

/// If nativeAd is set, HTMLSnippet and videoURL should not be set.
class CreativeNativeAd {
  core.String? advertiser;

  /// The app icon, for app download ads.
  CreativeNativeAdAppIcon? appIcon;

  /// A long description of the ad.
  core.String? body;

  /// A label for the button that the user is supposed to click.
  core.String? callToAction;

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
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiser != null) 'advertiser': advertiser!,
        if (appIcon != null) 'appIcon': appIcon!.toJson(),
        if (body != null) 'body': body!,
        if (callToAction != null) 'callToAction': callToAction!,
        if (clickTrackingUrl != null) 'clickTrackingUrl': clickTrackingUrl!,
        if (headline != null) 'headline': headline!,
        if (image != null) 'image': image!.toJson(),
        if (impressionTrackingUrl != null)
          'impressionTrackingUrl': impressionTrackingUrl!,
        if (logo != null) 'logo': logo!.toJson(),
        if (price != null) 'price': price!,
        if (starRating != null) 'starRating': starRating!,
      };
}

/// A creative and its classification data.
class Creative {
  /// The HTML snippet that displays the ad when inserted in the web page.
  ///
  /// If set, videoURL should not be set.
  core.String? HTMLSnippet;

  /// Account id.
  core.int? accountId;
  CreativeAdTechnologyProviders? adTechnologyProviders;

  /// Detected advertiser id, if any.
  ///
  /// Read-only. This field should not be set in requests.
  core.List<core.String>? advertiserId;

  /// The name of the company being advertised in the creative.
  core.String? advertiserName;

  /// The agency id for this creative.
  core.String? agencyId;

  /// The last upload timestamp of this creative if it was uploaded via API.
  ///
  /// Read-only. The value of this field is generated, and will be ignored for
  /// uploads. (formatted RFC 3339 timestamp).
  core.DateTime? apiUploadTimestamp;

  /// All attributes for the ads that may be shown from this snippet.
  core.List<core.int>? attribute;

  /// A buyer-specific id identifying the creative in this ad.
  core.String? buyerCreativeId;

  /// The set of destination urls for the snippet.
  core.List<core.String>? clickThroughUrl;

  /// Shows any corrections that were applied to this creative.
  ///
  /// Read-only. This field should not be set in requests.
  core.List<CreativeCorrections>? corrections;

  /// The reasons for disapproval, if any.
  ///
  /// Note that not all disapproval reasons may be categorized, so it is
  /// possible for the creative to have a status of DISAPPROVED with an empty
  /// list for disapproval_reasons. In this case, please reach out to your TAM
  /// to help debug the issue. Read-only. This field should not be set in
  /// requests.
  core.List<CreativeDisapprovalReasons>? disapprovalReasons;

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

  /// If nativeAd is set, HTMLSnippet and videoURL should not be set.
  CreativeNativeAd? nativeAd;

  /// Detected product categories, if any.
  ///
  /// Read-only. This field should not be set in requests.
  core.List<core.int>? productCategories;

  /// All restricted categories for the ads that may be shown from this snippet.
  core.List<core.int>? restrictedCategories;

  /// Detected sensitive categories, if any.
  ///
  /// Read-only. This field should not be set in requests.
  core.List<core.int>? sensitiveCategories;

  /// Creative serving status.
  ///
  /// Read-only. This field should not be set in requests.
  core.String? status;

  /// All vendor types for the ads that may be shown from this snippet.
  core.List<core.int>? vendorType;

  /// The version for this creative.
  ///
  /// Read-only. This field should not be set in requests.
  core.int? version;

  /// The URL to fetch a video ad.
  ///
  /// If set, HTMLSnippet and the nativeAd should not be set.
  core.String? videoURL;

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
    if (_json.containsKey('disapprovalReasons')) {
      disapprovalReasons = (_json['disapprovalReasons'] as core.List)
          .map<CreativeDisapprovalReasons>((value) =>
              CreativeDisapprovalReasons.fromJson(
                  value as core.Map<core.String, core.dynamic>))
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
    if (_json.containsKey('nativeAd')) {
      nativeAd = CreativeNativeAd.fromJson(
          _json['nativeAd'] as core.Map<core.String, core.dynamic>);
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
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
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
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (HTMLSnippet != null) 'HTMLSnippet': HTMLSnippet!,
        if (accountId != null) 'accountId': accountId!,
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
        if (disapprovalReasons != null)
          'disapprovalReasons':
              disapprovalReasons!.map((value) => value.toJson()).toList(),
        if (filteringReasons != null)
          'filteringReasons': filteringReasons!.toJson(),
        if (height != null) 'height': height!,
        if (impressionTrackingUrl != null)
          'impressionTrackingUrl': impressionTrackingUrl!,
        if (kind != null) 'kind': kind!,
        if (nativeAd != null) 'nativeAd': nativeAd!.toJson(),
        if (productCategories != null) 'productCategories': productCategories!,
        if (restrictedCategories != null)
          'restrictedCategories': restrictedCategories!,
        if (sensitiveCategories != null)
          'sensitiveCategories': sensitiveCategories!,
        if (status != null) 'status': status!,
        if (vendorType != null) 'vendorType': vendorType!,
        if (version != null) 'version': version!,
        if (videoURL != null) 'videoURL': videoURL!,
        if (width != null) 'width': width!,
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

/// The configuration data for an Ad Exchange direct deal.
class DirectDeal {
  /// The account id of the buyer this deal is for.
  core.int? accountId;

  /// The name of the advertiser this deal is for.
  core.String? advertiser;

  /// Whether the publisher for this deal is eligible for alcohol ads.
  core.bool? allowsAlcohol;

  /// The account id that this deal was negotiated for.
  ///
  /// It is either the buyer or the client that this deal was negotiated on
  /// behalf of.
  core.String? buyerAccountId;

  /// The currency code that applies to the fixed_cpm value.
  ///
  /// If not set then assumed to be USD.
  core.String? currencyCode;

  /// The deal type such as programmatic reservation or fixed price and so on.
  core.String? dealTier;

  /// End time for when this deal stops being active.
  ///
  /// If not set then this deal is valid until manually disabled by the
  /// publisher. In seconds since the epoch.
  core.String? endTime;

  /// The fixed price for this direct deal.
  ///
  /// In cpm micros of currency according to currency_code. If set, then this
  /// deal is eligible for the fixed price tier of buying (highest priority, pay
  /// exactly the configured fixed price).
  core.String? fixedCpm;

  /// Deal id.
  core.String? id;

  /// Resource type.
  core.String? kind;

  /// Deal name.
  core.String? name;

  /// The minimum price for this direct deal.
  ///
  /// In cpm micros of currency according to currency_code. If set, then this
  /// deal is eligible for the private exchange tier of buying (below fixed
  /// price priority, run as a second price auction).
  core.String? privateExchangeMinCpm;

  /// If true, the publisher has opted to have their blocks ignored when a
  /// creative is bid with for this deal.
  core.bool? publisherBlocksOverriden;

  /// The name of the publisher offering this direct deal.
  core.String? sellerNetwork;

  /// Start time for when this deal becomes active.
  ///
  /// If not set then this deal is active immediately upon creation. In seconds
  /// since the epoch.
  core.String? startTime;

  DirectDeal();

  DirectDeal.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.int;
    }
    if (_json.containsKey('advertiser')) {
      advertiser = _json['advertiser'] as core.String;
    }
    if (_json.containsKey('allowsAlcohol')) {
      allowsAlcohol = _json['allowsAlcohol'] as core.bool;
    }
    if (_json.containsKey('buyerAccountId')) {
      buyerAccountId = _json['buyerAccountId'] as core.String;
    }
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('dealTier')) {
      dealTier = _json['dealTier'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('fixedCpm')) {
      fixedCpm = _json['fixedCpm'] as core.String;
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
    if (_json.containsKey('privateExchangeMinCpm')) {
      privateExchangeMinCpm = _json['privateExchangeMinCpm'] as core.String;
    }
    if (_json.containsKey('publisherBlocksOverriden')) {
      publisherBlocksOverriden = _json['publisherBlocksOverriden'] as core.bool;
    }
    if (_json.containsKey('sellerNetwork')) {
      sellerNetwork = _json['sellerNetwork'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (advertiser != null) 'advertiser': advertiser!,
        if (allowsAlcohol != null) 'allowsAlcohol': allowsAlcohol!,
        if (buyerAccountId != null) 'buyerAccountId': buyerAccountId!,
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (dealTier != null) 'dealTier': dealTier!,
        if (endTime != null) 'endTime': endTime!,
        if (fixedCpm != null) 'fixedCpm': fixedCpm!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (privateExchangeMinCpm != null)
          'privateExchangeMinCpm': privateExchangeMinCpm!,
        if (publisherBlocksOverriden != null)
          'publisherBlocksOverriden': publisherBlocksOverriden!,
        if (sellerNetwork != null) 'sellerNetwork': sellerNetwork!,
        if (startTime != null) 'startTime': startTime!,
      };
}

/// A direct deals feed lists Direct Deals the Ad Exchange buyer account has
/// access to.
///
/// This includes direct deals set up for the buyer account as well as its
/// merged stream seats.
class DirectDealsList {
  /// A list of direct deals relevant for your account.
  core.List<DirectDeal>? directDeals;

  /// Resource type.
  core.String? kind;

  DirectDealsList();

  DirectDealsList.fromJson(core.Map _json) {
    if (_json.containsKey('directDeals')) {
      directDeals = (_json['directDeals'] as core.List)
          .map<DirectDeal>((value) =>
              DirectDeal.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (directDeals != null)
          'directDeals': directDeals!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
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

  /// Requests containing any of these user list ids will match.
  core.List<core.String>? userLists;

  /// Requests that allow any of these vendor ids will match.
  ///
  /// Values are from vendors.txt in the downloadable files section.
  core.List<core.String>? vendorTypes;

  /// Requests containing any of these vertical ids will match.
  core.List<core.String>? verticals;

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
        if (mobileCarriers != null) 'mobileCarriers': mobileCarriers!,
        if (mobileDevices != null) 'mobileDevices': mobileDevices!,
        if (mobileOperatingSystemVersions != null)
          'mobileOperatingSystemVersions': mobileOperatingSystemVersions!,
        if (placements != null)
          'placements': placements!.map((value) => value.toJson()).toList(),
        if (platforms != null) 'platforms': platforms!,
        if (supportedCreativeAttributes != null)
          'supportedCreativeAttributes': supportedCreativeAttributes!,
        if (userLists != null) 'userLists': userLists!,
        if (vendorTypes != null) 'vendorTypes': vendorTypes!,
        if (verticals != null) 'verticals': verticals!,
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

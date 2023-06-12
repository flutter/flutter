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

/// AdSense Host API - v4.1
///
/// Generates performance reports, generates ad codes, and provides publisher
/// management capabilities for AdSense Hosts.
///
/// For more information, see <https://developers.google.com/adsense/host/>
///
/// Create an instance of [AdSenseHostApi] to access these resources:
///
/// - [AccountsResource]
///   - [AccountsAdclientsResource]
///   - [AccountsAdunitsResource]
///   - [AccountsReportsResource]
/// - [AdclientsResource]
/// - [AssociationsessionsResource]
/// - [CustomchannelsResource]
/// - [ReportsResource]
/// - [UrlchannelsResource]
library adsensehost.v4_1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Generates performance reports, generates ad codes, and provides publisher
/// management capabilities for AdSense Hosts.
class AdSenseHostApi {
  /// View and manage your AdSense host data and associated accounts
  static const adsensehostScope = 'https://www.googleapis.com/auth/adsensehost';

  final commons.ApiRequester _requester;

  AccountsResource get accounts => AccountsResource(_requester);
  AdclientsResource get adclients => AdclientsResource(_requester);
  AssociationsessionsResource get associationsessions =>
      AssociationsessionsResource(_requester);
  CustomchannelsResource get customchannels =>
      CustomchannelsResource(_requester);
  ReportsResource get reports => ReportsResource(_requester);
  UrlchannelsResource get urlchannels => UrlchannelsResource(_requester);

  AdSenseHostApi(http.Client client,
      {core.String rootUrl = 'https://www.googleapis.com/',
      core.String servicePath = 'adsensehost/v4.1/'})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AccountsResource {
  final commons.ApiRequester _requester;

  AccountsAdclientsResource get adclients =>
      AccountsAdclientsResource(_requester);
  AccountsAdunitsResource get adunits => AccountsAdunitsResource(_requester);
  AccountsReportsResource get reports => AccountsReportsResource(_requester);

  AccountsResource(commons.ApiRequester client) : _requester = client;

  /// Get information about the selected associated AdSense account.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Account to get information about.
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
    core.String accountId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' + commons.escapeVariable('$accountId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Account.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List hosted accounts associated with this AdSense account by ad client id.
  ///
  /// Request parameters:
  ///
  /// [filterAdClientId] - Ad clients to list accounts for.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Accounts].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Accounts> list(
    core.List<core.String> filterAdClientId, {
    core.String? $fields,
  }) async {
    if (filterAdClientId.isEmpty) {
      throw core.ArgumentError('Parameter filterAdClientId cannot be empty.');
    }
    final _queryParams = <core.String, core.List<core.String>>{
      'filterAdClientId': filterAdClientId,
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'accounts';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Accounts.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AccountsAdclientsResource {
  final commons.ApiRequester _requester;

  AccountsAdclientsResource(commons.ApiRequester client) : _requester = client;

  /// Get information about one of the ad clients in the specified publisher's
  /// AdSense account.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Account which contains the ad client.
  ///
  /// [adClientId] - Ad client to get.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdClient].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdClient> get(
    core.String accountId,
    core.String adClientId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' +
        commons.escapeVariable('$accountId') +
        '/adclients/' +
        commons.escapeVariable('$adClientId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AdClient.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List all hosted ad clients in the specified hosted account.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Account for which to list ad clients.
  ///
  /// [maxResults] - The maximum number of ad clients to include in the
  /// response, used for paging.
  /// Value must be between "0" and "10000".
  ///
  /// [pageToken] - A continuation token, used to page through ad clients. To
  /// retrieve the next page, set this parameter to the value of "nextPageToken"
  /// from the previous response.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdClients].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdClients> list(
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

    final _url =
        'accounts/' + commons.escapeVariable('$accountId') + '/adclients';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AdClients.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AccountsAdunitsResource {
  final commons.ApiRequester _requester;

  AccountsAdunitsResource(commons.ApiRequester client) : _requester = client;

  /// Delete the specified ad unit from the specified publisher AdSense account.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Account which contains the ad unit.
  ///
  /// [adClientId] - Ad client for which to get ad unit.
  ///
  /// [adUnitId] - Ad unit to delete.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdUnit].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdUnit> delete(
    core.String accountId,
    core.String adClientId,
    core.String adUnitId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' +
        commons.escapeVariable('$accountId') +
        '/adclients/' +
        commons.escapeVariable('$adClientId') +
        '/adunits/' +
        commons.escapeVariable('$adUnitId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return AdUnit.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Get the specified host ad unit in this AdSense account.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Account which contains the ad unit.
  ///
  /// [adClientId] - Ad client for which to get ad unit.
  ///
  /// [adUnitId] - Ad unit to get.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdUnit].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdUnit> get(
    core.String accountId,
    core.String adClientId,
    core.String adUnitId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' +
        commons.escapeVariable('$accountId') +
        '/adclients/' +
        commons.escapeVariable('$adClientId') +
        '/adunits/' +
        commons.escapeVariable('$adUnitId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AdUnit.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Get ad code for the specified ad unit, attaching the specified host custom
  /// channels.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Account which contains the ad client.
  ///
  /// [adClientId] - Ad client with contains the ad unit.
  ///
  /// [adUnitId] - Ad unit to get the code for.
  ///
  /// [hostCustomChannelId] - Host custom channel to attach to the ad code.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdCode].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdCode> getAdCode(
    core.String accountId,
    core.String adClientId,
    core.String adUnitId, {
    core.List<core.String>? hostCustomChannelId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (hostCustomChannelId != null)
        'hostCustomChannelId': hostCustomChannelId,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' +
        commons.escapeVariable('$accountId') +
        '/adclients/' +
        commons.escapeVariable('$adClientId') +
        '/adunits/' +
        commons.escapeVariable('$adUnitId') +
        '/adcode';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AdCode.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Insert the supplied ad unit into the specified publisher AdSense account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Account which will contain the ad unit.
  ///
  /// [adClientId] - Ad client into which to insert the ad unit.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdUnit].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdUnit> insert(
    AdUnit request,
    core.String accountId,
    core.String adClientId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' +
        commons.escapeVariable('$accountId') +
        '/adclients/' +
        commons.escapeVariable('$adClientId') +
        '/adunits';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AdUnit.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List all ad units in the specified publisher's AdSense account.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Account which contains the ad client.
  ///
  /// [adClientId] - Ad client for which to list ad units.
  ///
  /// [includeInactive] - Whether to include inactive ad units. Default: true.
  ///
  /// [maxResults] - The maximum number of ad units to include in the response,
  /// used for paging.
  /// Value must be between "0" and "10000".
  ///
  /// [pageToken] - A continuation token, used to page through ad units. To
  /// retrieve the next page, set this parameter to the value of "nextPageToken"
  /// from the previous response.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdUnits].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdUnits> list(
    core.String accountId,
    core.String adClientId, {
    core.bool? includeInactive,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeInactive != null) 'includeInactive': ['${includeInactive}'],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' +
        commons.escapeVariable('$accountId') +
        '/adclients/' +
        commons.escapeVariable('$adClientId') +
        '/adunits';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AdUnits.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Update the supplied ad unit in the specified publisher AdSense account.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Account which contains the ad client.
  ///
  /// [adClientId] - Ad client which contains the ad unit.
  ///
  /// [adUnitId] - Ad unit to get.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdUnit].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdUnit> patch(
    AdUnit request,
    core.String accountId,
    core.String adClientId,
    core.String adUnitId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'adUnitId': [adUnitId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' +
        commons.escapeVariable('$accountId') +
        '/adclients/' +
        commons.escapeVariable('$adClientId') +
        '/adunits';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return AdUnit.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Update the supplied ad unit in the specified publisher AdSense account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Account which contains the ad client.
  ///
  /// [adClientId] - Ad client which contains the ad unit.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdUnit].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdUnit> update(
    AdUnit request,
    core.String accountId,
    core.String adClientId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'accounts/' +
        commons.escapeVariable('$accountId') +
        '/adclients/' +
        commons.escapeVariable('$adClientId') +
        '/adunits';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return AdUnit.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AccountsReportsResource {
  final commons.ApiRequester _requester;

  AccountsReportsResource(commons.ApiRequester client) : _requester = client;

  /// Generate an AdSense report based on the report request sent in the query
  /// parameters.
  ///
  /// Returns the result as JSON; to retrieve output in CSV format specify
  /// "alt=csv" as a query parameter.
  ///
  /// Request parameters:
  ///
  /// [accountId] - Hosted account upon which to report.
  ///
  /// [startDate] - Start of the date range to report on in "YYYY-MM-DD" format,
  /// inclusive.
  /// Value must have pattern
  /// `\d{4}-\d{2}-\d{2}|(today|startOfMonth|startOfYear)((\[\-\+\]\d+\[dwmy\]){0,3}?)`.
  ///
  /// [endDate] - End of the date range to report on in "YYYY-MM-DD" format,
  /// inclusive.
  /// Value must have pattern
  /// `\d{4}-\d{2}-\d{2}|(today|startOfMonth|startOfYear)((\[\-\+\]\d+\[dwmy\]){0,3}?)`.
  ///
  /// [dimension] - Dimensions to base the report on.
  /// Value must have pattern `\[a-zA-Z_\]+`.
  ///
  /// [filter] - Filters to be run on the report.
  /// Value must have pattern `\[a-zA-Z_\]+(==|=@).+`.
  ///
  /// [locale] - Optional locale to use for translating report output to a local
  /// language. Defaults to "en_US" if not specified.
  /// Value must have pattern `\[a-zA-Z_\]+`.
  ///
  /// [maxResults] - The maximum number of rows of report data to return.
  /// Value must be between "0" and "50000".
  ///
  /// [metric] - Numeric columns to include in the report.
  /// Value must have pattern `\[a-zA-Z_\]+`.
  ///
  /// [sort] - The name of a dimension or metric to sort the resulting report
  /// on, optionally prefixed with "+" to sort ascending or "-" to sort
  /// descending. If no prefix is specified, the column is sorted ascending.
  /// Value must have pattern `(\+|-)?\[a-zA-Z_\]+`.
  ///
  /// [startIndex] - Index of the first row of report data to return.
  /// Value must be between "0" and "5000".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Report].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Report> generate(
    core.String accountId,
    core.String startDate,
    core.String endDate, {
    core.List<core.String>? dimension,
    core.List<core.String>? filter,
    core.String? locale,
    core.int? maxResults,
    core.List<core.String>? metric,
    core.List<core.String>? sort,
    core.int? startIndex,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'startDate': [startDate],
      'endDate': [endDate],
      if (dimension != null) 'dimension': dimension,
      if (filter != null) 'filter': filter,
      if (locale != null) 'locale': [locale],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (metric != null) 'metric': metric,
      if (sort != null) 'sort': sort,
      if (startIndex != null) 'startIndex': ['${startIndex}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'accounts/' + commons.escapeVariable('$accountId') + '/reports';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Report.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AdclientsResource {
  final commons.ApiRequester _requester;

  AdclientsResource(commons.ApiRequester client) : _requester = client;

  /// Get information about one of the ad clients in the Host AdSense account.
  ///
  /// Request parameters:
  ///
  /// [adClientId] - Ad client to get.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdClient].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdClient> get(
    core.String adClientId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'adclients/' + commons.escapeVariable('$adClientId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AdClient.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List all host ad clients in this AdSense account.
  ///
  /// Request parameters:
  ///
  /// [maxResults] - The maximum number of ad clients to include in the
  /// response, used for paging.
  /// Value must be between "0" and "10000".
  ///
  /// [pageToken] - A continuation token, used to page through ad clients. To
  /// retrieve the next page, set this parameter to the value of "nextPageToken"
  /// from the previous response.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdClients].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdClients> list({
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'adclients';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AdClients.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AssociationsessionsResource {
  final commons.ApiRequester _requester;

  AssociationsessionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Create an association session for initiating an association with an
  /// AdSense user.
  ///
  /// Request parameters:
  ///
  /// [productCode] - Products to associate with the user.
  ///
  /// [websiteUrl] - The URL of the user's hosted website.
  ///
  /// [callbackUrl] - The URL to redirect the user to once association is
  /// completed. It receives a token parameter that can then be used to retrieve
  /// the associated account.
  ///
  /// [userLocale] - The preferred locale of the user.
  ///
  /// [websiteLocale] - The locale of the user's hosted website.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AssociationSession].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AssociationSession> start(
    core.List<core.String> productCode,
    core.String websiteUrl, {
    core.String? callbackUrl,
    core.String? userLocale,
    core.String? websiteLocale,
    core.String? $fields,
  }) async {
    if (productCode.isEmpty) {
      throw core.ArgumentError('Parameter productCode cannot be empty.');
    }
    final _queryParams = <core.String, core.List<core.String>>{
      'productCode': productCode,
      'websiteUrl': [websiteUrl],
      if (callbackUrl != null) 'callbackUrl': [callbackUrl],
      if (userLocale != null) 'userLocale': [userLocale],
      if (websiteLocale != null) 'websiteLocale': [websiteLocale],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'associationsessions/start';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AssociationSession.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Verify an association session after the association callback returns from
  /// AdSense signup.
  ///
  /// Request parameters:
  ///
  /// [token] - The token returned to the association callback URL.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AssociationSession].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AssociationSession> verify(
    core.String token, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'token': [token],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'associationsessions/verify';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AssociationSession.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class CustomchannelsResource {
  final commons.ApiRequester _requester;

  CustomchannelsResource(commons.ApiRequester client) : _requester = client;

  /// Delete a specific custom channel from the host AdSense account.
  ///
  /// Request parameters:
  ///
  /// [adClientId] - Ad client from which to delete the custom channel.
  ///
  /// [customChannelId] - Custom channel to delete.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CustomChannel].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CustomChannel> delete(
    core.String adClientId,
    core.String customChannelId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'adclients/' +
        commons.escapeVariable('$adClientId') +
        '/customchannels/' +
        commons.escapeVariable('$customChannelId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return CustomChannel.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Get a specific custom channel from the host AdSense account.
  ///
  /// Request parameters:
  ///
  /// [adClientId] - Ad client from which to get the custom channel.
  ///
  /// [customChannelId] - Custom channel to get.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CustomChannel].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CustomChannel> get(
    core.String adClientId,
    core.String customChannelId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'adclients/' +
        commons.escapeVariable('$adClientId') +
        '/customchannels/' +
        commons.escapeVariable('$customChannelId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CustomChannel.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Add a new custom channel to the host AdSense account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [adClientId] - Ad client to which the new custom channel will be added.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CustomChannel].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CustomChannel> insert(
    CustomChannel request,
    core.String adClientId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'adclients/' +
        commons.escapeVariable('$adClientId') +
        '/customchannels';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CustomChannel.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List all host custom channels in this AdSense account.
  ///
  /// Request parameters:
  ///
  /// [adClientId] - Ad client for which to list custom channels.
  ///
  /// [maxResults] - The maximum number of custom channels to include in the
  /// response, used for paging.
  /// Value must be between "0" and "10000".
  ///
  /// [pageToken] - A continuation token, used to page through custom channels.
  /// To retrieve the next page, set this parameter to the value of
  /// "nextPageToken" from the previous response.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CustomChannels].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CustomChannels> list(
    core.String adClientId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'adclients/' +
        commons.escapeVariable('$adClientId') +
        '/customchannels';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CustomChannels.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update a custom channel in the host AdSense account.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [adClientId] - Ad client in which the custom channel will be updated.
  ///
  /// [customChannelId] - Custom channel to get.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CustomChannel].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CustomChannel> patch(
    CustomChannel request,
    core.String adClientId,
    core.String customChannelId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'customChannelId': [customChannelId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'adclients/' +
        commons.escapeVariable('$adClientId') +
        '/customchannels';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return CustomChannel.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update a custom channel in the host AdSense account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [adClientId] - Ad client in which the custom channel will be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CustomChannel].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CustomChannel> update(
    CustomChannel request,
    core.String adClientId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'adclients/' +
        commons.escapeVariable('$adClientId') +
        '/customchannels';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return CustomChannel.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ReportsResource {
  final commons.ApiRequester _requester;

  ReportsResource(commons.ApiRequester client) : _requester = client;

  /// Generate an AdSense report based on the report request sent in the query
  /// parameters.
  ///
  /// Returns the result as JSON; to retrieve output in CSV format specify
  /// "alt=csv" as a query parameter.
  ///
  /// Request parameters:
  ///
  /// [startDate] - Start of the date range to report on in "YYYY-MM-DD" format,
  /// inclusive.
  /// Value must have pattern
  /// `\d{4}-\d{2}-\d{2}|(today|startOfMonth|startOfYear)((\[\-\+\]\d+\[dwmy\]){0,3}?)`.
  ///
  /// [endDate] - End of the date range to report on in "YYYY-MM-DD" format,
  /// inclusive.
  /// Value must have pattern
  /// `\d{4}-\d{2}-\d{2}|(today|startOfMonth|startOfYear)((\[\-\+\]\d+\[dwmy\]){0,3}?)`.
  ///
  /// [dimension] - Dimensions to base the report on.
  /// Value must have pattern `\[a-zA-Z_\]+`.
  ///
  /// [filter] - Filters to be run on the report.
  /// Value must have pattern `\[a-zA-Z_\]+(==|=@).+`.
  ///
  /// [locale] - Optional locale to use for translating report output to a local
  /// language. Defaults to "en_US" if not specified.
  /// Value must have pattern `\[a-zA-Z_\]+`.
  ///
  /// [maxResults] - The maximum number of rows of report data to return.
  /// Value must be between "0" and "50000".
  ///
  /// [metric] - Numeric columns to include in the report.
  /// Value must have pattern `\[a-zA-Z_\]+`.
  ///
  /// [sort] - The name of a dimension or metric to sort the resulting report
  /// on, optionally prefixed with "+" to sort ascending or "-" to sort
  /// descending. If no prefix is specified, the column is sorted ascending.
  /// Value must have pattern `(\+|-)?\[a-zA-Z_\]+`.
  ///
  /// [startIndex] - Index of the first row of report data to return.
  /// Value must be between "0" and "5000".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Report].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Report> generate(
    core.String startDate,
    core.String endDate, {
    core.List<core.String>? dimension,
    core.List<core.String>? filter,
    core.String? locale,
    core.int? maxResults,
    core.List<core.String>? metric,
    core.List<core.String>? sort,
    core.int? startIndex,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'startDate': [startDate],
      'endDate': [endDate],
      if (dimension != null) 'dimension': dimension,
      if (filter != null) 'filter': filter,
      if (locale != null) 'locale': [locale],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (metric != null) 'metric': metric,
      if (sort != null) 'sort': sort,
      if (startIndex != null) 'startIndex': ['${startIndex}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'reports';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Report.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class UrlchannelsResource {
  final commons.ApiRequester _requester;

  UrlchannelsResource(commons.ApiRequester client) : _requester = client;

  /// Delete a URL channel from the host AdSense account.
  ///
  /// Request parameters:
  ///
  /// [adClientId] - Ad client from which to delete the URL channel.
  ///
  /// [urlChannelId] - URL channel to delete.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UrlChannel].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UrlChannel> delete(
    core.String adClientId,
    core.String urlChannelId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'adclients/' +
        commons.escapeVariable('$adClientId') +
        '/urlchannels/' +
        commons.escapeVariable('$urlChannelId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return UrlChannel.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Add a new URL channel to the host AdSense account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [adClientId] - Ad client to which the new URL channel will be added.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UrlChannel].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UrlChannel> insert(
    UrlChannel request,
    core.String adClientId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'adclients/' + commons.escapeVariable('$adClientId') + '/urlchannels';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return UrlChannel.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List all host URL channels in the host AdSense account.
  ///
  /// Request parameters:
  ///
  /// [adClientId] - Ad client for which to list URL channels.
  ///
  /// [maxResults] - The maximum number of URL channels to include in the
  /// response, used for paging.
  /// Value must be between "0" and "10000".
  ///
  /// [pageToken] - A continuation token, used to page through URL channels. To
  /// retrieve the next page, set this parameter to the value of "nextPageToken"
  /// from the previous response.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UrlChannels].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UrlChannels> list(
    core.String adClientId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'adclients/' + commons.escapeVariable('$adClientId') + '/urlchannels';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UrlChannels.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class Account {
  /// Unique identifier of this account.
  core.String? id;

  /// Kind of resource this is, in this case adsensehost#account.
  core.String? kind;

  /// Name of this account.
  core.String? name;

  /// Approval status of this account.
  ///
  /// One of: PENDING, APPROVED, DISABLED.
  core.String? status;

  Account();

  Account.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (status != null) 'status': status!,
      };
}

class Accounts {
  /// ETag of this response for caching purposes.
  core.String? etag;

  /// The accounts returned in this list response.
  core.List<Account>? items;

  /// Kind of list this is, in this case adsensehost#accounts.
  core.String? kind;

  Accounts();

  Accounts.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
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
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class AdClient {
  /// Whether this ad client is opted in to ARC.
  core.bool? arcOptIn;

  /// Unique identifier of this ad client.
  core.String? id;

  /// Kind of resource this is, in this case adsensehost#adClient.
  core.String? kind;

  /// This ad client's product code, which corresponds to the PRODUCT_CODE
  /// report dimension.
  core.String? productCode;

  /// Whether this ad client supports being reported on.
  core.bool? supportsReporting;

  AdClient();

  AdClient.fromJson(core.Map _json) {
    if (_json.containsKey('arcOptIn')) {
      arcOptIn = _json['arcOptIn'] as core.bool;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('productCode')) {
      productCode = _json['productCode'] as core.String;
    }
    if (_json.containsKey('supportsReporting')) {
      supportsReporting = _json['supportsReporting'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arcOptIn != null) 'arcOptIn': arcOptIn!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (productCode != null) 'productCode': productCode!,
        if (supportsReporting != null) 'supportsReporting': supportsReporting!,
      };
}

class AdClients {
  /// ETag of this response for caching purposes.
  core.String? etag;

  /// The ad clients returned in this list response.
  core.List<AdClient>? items;

  /// Kind of list this is, in this case adsensehost#adClients.
  core.String? kind;

  /// Continuation token used to page through ad clients.
  ///
  /// To retrieve the next page of results, set the next request's "pageToken"
  /// value to this.
  core.String? nextPageToken;

  AdClients();

  AdClients.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<AdClient>((value) =>
              AdClient.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class AdCode {
  /// The ad code snippet.
  core.String? adCode;

  /// Kind this is, in this case adsensehost#adCode.
  core.String? kind;

  AdCode();

  AdCode.fromJson(core.Map _json) {
    if (_json.containsKey('adCode')) {
      adCode = _json['adCode'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adCode != null) 'adCode': adCode!,
        if (kind != null) 'kind': kind!,
      };
}

/// The colors included in the style.
///
/// These are represented as six hexadecimal characters, similar to HTML color
/// codes, but without the leading hash.
class AdStyleColors {
  /// The color of the ad background.
  core.String? background;

  /// The color of the ad border.
  core.String? border;

  /// The color of the ad text.
  core.String? text;

  /// The color of the ad title.
  core.String? title;

  /// The color of the ad url.
  core.String? url;

  AdStyleColors();

  AdStyleColors.fromJson(core.Map _json) {
    if (_json.containsKey('background')) {
      background = _json['background'] as core.String;
    }
    if (_json.containsKey('border')) {
      border = _json['border'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (background != null) 'background': background!,
        if (border != null) 'border': border!,
        if (text != null) 'text': text!,
        if (title != null) 'title': title!,
        if (url != null) 'url': url!,
      };
}

/// The font which is included in the style.
class AdStyleFont {
  /// The family of the font.
  ///
  /// Possible values are: ACCOUNT_DEFAULT_FAMILY, ADSENSE_DEFAULT_FAMILY,
  /// ARIAL, TIMES and VERDANA.
  core.String? family;

  /// The size of the font.
  ///
  /// Possible values are: ACCOUNT_DEFAULT_SIZE, ADSENSE_DEFAULT_SIZE, SMALL,
  /// MEDIUM and LARGE.
  core.String? size;

  AdStyleFont();

  AdStyleFont.fromJson(core.Map _json) {
    if (_json.containsKey('family')) {
      family = _json['family'] as core.String;
    }
    if (_json.containsKey('size')) {
      size = _json['size'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (family != null) 'family': family!,
        if (size != null) 'size': size!,
      };
}

class AdStyle {
  /// The colors included in the style.
  ///
  /// These are represented as six hexadecimal characters, similar to HTML color
  /// codes, but without the leading hash.
  AdStyleColors? colors;

  /// The style of the corners in the ad (deprecated: never populated, ignored).
  core.String? corners;

  /// The font which is included in the style.
  AdStyleFont? font;

  /// Kind this is, in this case adsensehost#adStyle.
  core.String? kind;

  AdStyle();

  AdStyle.fromJson(core.Map _json) {
    if (_json.containsKey('colors')) {
      colors = AdStyleColors.fromJson(
          _json['colors'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('corners')) {
      corners = _json['corners'] as core.String;
    }
    if (_json.containsKey('font')) {
      font = AdStyleFont.fromJson(
          _json['font'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (colors != null) 'colors': colors!.toJson(),
        if (corners != null) 'corners': corners!,
        if (font != null) 'font': font!.toJson(),
        if (kind != null) 'kind': kind!,
      };
}

/// The backup option to be used in instances where no ad is available.
class AdUnitContentAdsSettingsBackupOption {
  /// Color to use when type is set to COLOR.
  ///
  /// These are represented as six hexadecimal characters, similar to HTML color
  /// codes, but without the leading hash.
  core.String? color;

  /// Type of the backup option.
  ///
  /// Possible values are BLANK, COLOR and URL.
  core.String? type;

  /// URL to use when type is set to URL.
  core.String? url;

  AdUnitContentAdsSettingsBackupOption();

  AdUnitContentAdsSettingsBackupOption.fromJson(core.Map _json) {
    if (_json.containsKey('color')) {
      color = _json['color'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (color != null) 'color': color!,
        if (type != null) 'type': type!,
        if (url != null) 'url': url!,
      };
}

/// Settings specific to content ads (AFC) and highend mobile content ads (AFMC
/// - deprecated).
class AdUnitContentAdsSettings {
  /// The backup option to be used in instances where no ad is available.
  AdUnitContentAdsSettingsBackupOption? backupOption;

  /// Size of this ad unit.
  ///
  /// Size values are in the form SIZE_{width}_{height}.
  core.String? size;

  /// Type of this ad unit.
  ///
  /// Possible values are TEXT, TEXT_IMAGE, IMAGE and LINK.
  core.String? type;

  AdUnitContentAdsSettings();

  AdUnitContentAdsSettings.fromJson(core.Map _json) {
    if (_json.containsKey('backupOption')) {
      backupOption = AdUnitContentAdsSettingsBackupOption.fromJson(
          _json['backupOption'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('size')) {
      size = _json['size'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backupOption != null) 'backupOption': backupOption!.toJson(),
        if (size != null) 'size': size!,
        if (type != null) 'type': type!,
      };
}

/// Settings specific to WAP mobile content ads (AFMC - deprecated).
class AdUnitMobileContentAdsSettings {
  /// The markup language to use for this ad unit.
  core.String? markupLanguage;

  /// The scripting language to use for this ad unit.
  core.String? scriptingLanguage;

  /// Size of this ad unit.
  core.String? size;

  /// Type of this ad unit.
  core.String? type;

  AdUnitMobileContentAdsSettings();

  AdUnitMobileContentAdsSettings.fromJson(core.Map _json) {
    if (_json.containsKey('markupLanguage')) {
      markupLanguage = _json['markupLanguage'] as core.String;
    }
    if (_json.containsKey('scriptingLanguage')) {
      scriptingLanguage = _json['scriptingLanguage'] as core.String;
    }
    if (_json.containsKey('size')) {
      size = _json['size'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (markupLanguage != null) 'markupLanguage': markupLanguage!,
        if (scriptingLanguage != null) 'scriptingLanguage': scriptingLanguage!,
        if (size != null) 'size': size!,
        if (type != null) 'type': type!,
      };
}

class AdUnit {
  /// Identity code of this ad unit, not necessarily unique across ad clients.
  core.String? code;

  /// Settings specific to content ads (AFC) and highend mobile content ads
  /// (AFMC - deprecated).
  AdUnitContentAdsSettings? contentAdsSettings;

  /// Custom style information specific to this ad unit.
  AdStyle? customStyle;

  /// Unique identifier of this ad unit.
  ///
  /// This should be considered an opaque identifier; it is not safe to rely on
  /// it being in any particular format.
  core.String? id;

  /// Kind of resource this is, in this case adsensehost#adUnit.
  core.String? kind;

  /// Settings specific to WAP mobile content ads (AFMC - deprecated).
  AdUnitMobileContentAdsSettings? mobileContentAdsSettings;

  /// Name of this ad unit.
  core.String? name;

  /// Status of this ad unit.
  ///
  /// Possible values are:
  /// NEW: Indicates that the ad unit was created within the last seven days and
  /// does not yet have any activity associated with it.
  ///
  /// ACTIVE: Indicates that there has been activity on this ad unit in the last
  /// seven days.
  ///
  /// INACTIVE: Indicates that there has been no activity on this ad unit in the
  /// last seven days.
  core.String? status;

  AdUnit();

  AdUnit.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('contentAdsSettings')) {
      contentAdsSettings = AdUnitContentAdsSettings.fromJson(
          _json['contentAdsSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('customStyle')) {
      customStyle = AdStyle.fromJson(
          _json['customStyle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('mobileContentAdsSettings')) {
      mobileContentAdsSettings = AdUnitMobileContentAdsSettings.fromJson(
          _json['mobileContentAdsSettings']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (contentAdsSettings != null)
          'contentAdsSettings': contentAdsSettings!.toJson(),
        if (customStyle != null) 'customStyle': customStyle!.toJson(),
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (mobileContentAdsSettings != null)
          'mobileContentAdsSettings': mobileContentAdsSettings!.toJson(),
        if (name != null) 'name': name!,
        if (status != null) 'status': status!,
      };
}

class AdUnits {
  /// ETag of this response for caching purposes.
  core.String? etag;

  /// The ad units returned in this list response.
  core.List<AdUnit>? items;

  /// Kind of list this is, in this case adsensehost#adUnits.
  core.String? kind;

  /// Continuation token used to page through ad units.
  ///
  /// To retrieve the next page of results, set the next request's "pageToken"
  /// value to this.
  core.String? nextPageToken;

  AdUnits();

  AdUnits.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<AdUnit>((value) =>
              AdUnit.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class AssociationSession {
  /// Hosted account id of the associated publisher after association.
  ///
  /// Present if status is ACCEPTED.
  core.String? accountId;

  /// Unique identifier of this association session.
  core.String? id;

  /// Kind of resource this is, in this case adsensehost#associationSession.
  core.String? kind;

  /// The products to associate with the user.
  ///
  /// Options: AFC, AFG, AFV, AFS (deprecated), AFMC (deprecated)
  core.List<core.String>? productCodes;

  /// Redirect URL of this association session.
  ///
  /// Used to redirect users into the AdSense association flow.
  core.String? redirectUrl;

  /// Status of the completed association, available once the association
  /// callback token has been verified.
  ///
  /// One of ACCEPTED, REJECTED, or ERROR.
  core.String? status;

  /// The preferred locale of the user themselves when going through the AdSense
  /// association flow.
  core.String? userLocale;

  /// The locale of the user's hosted website.
  core.String? websiteLocale;

  /// The URL of the user's hosted website.
  core.String? websiteUrl;

  AssociationSession();

  AssociationSession.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('productCodes')) {
      productCodes = (_json['productCodes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('redirectUrl')) {
      redirectUrl = _json['redirectUrl'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('userLocale')) {
      userLocale = _json['userLocale'] as core.String;
    }
    if (_json.containsKey('websiteLocale')) {
      websiteLocale = _json['websiteLocale'] as core.String;
    }
    if (_json.containsKey('websiteUrl')) {
      websiteUrl = _json['websiteUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (productCodes != null) 'productCodes': productCodes!,
        if (redirectUrl != null) 'redirectUrl': redirectUrl!,
        if (status != null) 'status': status!,
        if (userLocale != null) 'userLocale': userLocale!,
        if (websiteLocale != null) 'websiteLocale': websiteLocale!,
        if (websiteUrl != null) 'websiteUrl': websiteUrl!,
      };
}

class CustomChannel {
  /// Code of this custom channel, not necessarily unique across ad clients.
  core.String? code;

  /// Unique identifier of this custom channel.
  ///
  /// This should be considered an opaque identifier; it is not safe to rely on
  /// it being in any particular format.
  core.String? id;

  /// Kind of resource this is, in this case adsensehost#customChannel.
  core.String? kind;

  /// Name of this custom channel.
  core.String? name;

  CustomChannel();

  CustomChannel.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
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
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

class CustomChannels {
  /// ETag of this response for caching purposes.
  core.String? etag;

  /// The custom channels returned in this list response.
  core.List<CustomChannel>? items;

  /// Kind of list this is, in this case adsensehost#customChannels.
  core.String? kind;

  /// Continuation token used to page through custom channels.
  ///
  /// To retrieve the next page of results, set the next request's "pageToken"
  /// value to this.
  core.String? nextPageToken;

  CustomChannels();

  CustomChannels.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<CustomChannel>((value) => CustomChannel.fromJson(
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
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ReportHeaders {
  /// The currency of this column.
  ///
  /// Only present if the header type is METRIC_CURRENCY.
  core.String? currency;

  /// The name of the header.
  core.String? name;

  /// The type of the header; one of DIMENSION, METRIC_TALLY, METRIC_RATIO, or
  /// METRIC_CURRENCY.
  core.String? type;

  ReportHeaders();

  ReportHeaders.fromJson(core.Map _json) {
    if (_json.containsKey('currency')) {
      currency = _json['currency'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currency != null) 'currency': currency!,
        if (name != null) 'name': name!,
        if (type != null) 'type': type!,
      };
}

class Report {
  /// The averages of the report.
  ///
  /// This is the same length as any other row in the report; cells
  /// corresponding to dimension columns are empty.
  core.List<core.String>? averages;

  /// The header information of the columns requested in the report.
  ///
  /// This is a list of headers; one for each dimension in the request, followed
  /// by one for each metric in the request.
  core.List<ReportHeaders>? headers;

  /// Kind this is, in this case adsensehost#report.
  core.String? kind;

  /// The output rows of the report.
  ///
  /// Each row is a list of cells; one for each dimension in the request,
  /// followed by one for each metric in the request. The dimension cells
  /// contain strings, and the metric cells contain numbers.
  core.List<core.List<core.String>>? rows;

  /// The total number of rows matched by the report request.
  ///
  /// Fewer rows may be returned in the response due to being limited by the row
  /// count requested or the report row limit.
  core.String? totalMatchedRows;

  /// The totals of the report.
  ///
  /// This is the same length as any other row in the report; cells
  /// corresponding to dimension columns are empty.
  core.List<core.String>? totals;

  /// Any warnings associated with generation of the report.
  core.List<core.String>? warnings;

  Report();

  Report.fromJson(core.Map _json) {
    if (_json.containsKey('averages')) {
      averages = (_json['averages'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('headers')) {
      headers = (_json['headers'] as core.List)
          .map<ReportHeaders>((value) => ReportHeaders.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('rows')) {
      rows = (_json['rows'] as core.List)
          .map<core.List<core.String>>((value) => (value as core.List)
              .map<core.String>((value) => value as core.String)
              .toList())
          .toList();
    }
    if (_json.containsKey('totalMatchedRows')) {
      totalMatchedRows = _json['totalMatchedRows'] as core.String;
    }
    if (_json.containsKey('totals')) {
      totals = (_json['totals'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('warnings')) {
      warnings = (_json['warnings'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (averages != null) 'averages': averages!,
        if (headers != null)
          'headers': headers!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (rows != null) 'rows': rows!,
        if (totalMatchedRows != null) 'totalMatchedRows': totalMatchedRows!,
        if (totals != null) 'totals': totals!,
        if (warnings != null) 'warnings': warnings!,
      };
}

class UrlChannel {
  /// Unique identifier of this URL channel.
  ///
  /// This should be considered an opaque identifier; it is not safe to rely on
  /// it being in any particular format.
  core.String? id;

  /// Kind of resource this is, in this case adsensehost#urlChannel.
  core.String? kind;

  /// URL Pattern of this URL channel.
  ///
  /// Does not include "http://" or "https://". Example: www.example.com/home
  core.String? urlPattern;

  UrlChannel();

  UrlChannel.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('urlPattern')) {
      urlPattern = _json['urlPattern'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (urlPattern != null) 'urlPattern': urlPattern!,
      };
}

class UrlChannels {
  /// ETag of this response for caching purposes.
  core.String? etag;

  /// The URL channels returned in this list response.
  core.List<UrlChannel>? items;

  /// Kind of list this is, in this case adsensehost#urlChannels.
  core.String? kind;

  /// Continuation token used to page through URL channels.
  ///
  /// To retrieve the next page of results, set the next request's "pageToken"
  /// value to this.
  core.String? nextPageToken;

  UrlChannels();

  UrlChannels.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<UrlChannel>((value) =>
              UrlChannel.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (etag != null) 'etag': etag!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

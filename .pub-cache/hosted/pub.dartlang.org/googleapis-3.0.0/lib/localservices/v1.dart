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

/// Local Services API - v1
///
/// For more information, see <https://ads.google.com/local-services-ads/>
///
/// Create an instance of [LocalservicesApi] to access these resources:
///
/// - [AccountReportsResource]
/// - [DetailedLeadReportsResource]
library localservices.v1;

import 'dart:async' as async;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

class LocalservicesApi {
  /// Manage your AdWords campaigns
  static const adwordsScope = 'https://www.googleapis.com/auth/adwords';

  final commons.ApiRequester _requester;

  AccountReportsResource get accountReports =>
      AccountReportsResource(_requester);
  DetailedLeadReportsResource get detailedLeadReports =>
      DetailedLeadReportsResource(_requester);

  LocalservicesApi(http.Client client,
      {core.String rootUrl = 'https://localservices.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AccountReportsResource {
  final commons.ApiRequester _requester;

  AccountReportsResource(commons.ApiRequester client) : _requester = client;

  /// Get account reports containing aggregate account data of all linked GLS
  /// accounts.
  ///
  /// Caller needs to provide their manager customer id and the associated auth
  /// credential that allows them read permissions on their linked accounts.
  ///
  /// Request parameters:
  ///
  /// [endDate_day] - Day of a month. Must be from 1 to 31 and valid for the
  /// year and month, or 0 to specify a year by itself or a year and month where
  /// the day isn't significant.
  ///
  /// [endDate_month] - Month of a year. Must be from 1 to 12, or 0 to specify a
  /// year without a month and day.
  ///
  /// [endDate_year] - Year of the date. Must be from 1 to 9999, or 0 to specify
  /// a date without a year.
  ///
  /// [pageSize] - The maximum number of accounts to return. If the page size is
  /// unset, page size will default to 1000. Maximum page_size is 10000.
  /// Optional.
  ///
  /// [pageToken] - The `next_page_token` value returned from a previous request
  /// to SearchAccountReports that indicates where listing should continue.
  /// Optional.
  ///
  /// [query] - A query string for searching for account reports. Caller must
  /// provide a customer id of their MCC account with an associated Gaia Mint
  /// that allows read permission on their linked accounts. Search expressions
  /// are case insensitive. Example query: | Query | Description |
  /// |-------------------------|-----------------------------------------------|
  /// | manager_customer_id:123 | Get Account Report for Manager with id 123. |
  /// Required.
  ///
  /// [startDate_day] - Day of a month. Must be from 1 to 31 and valid for the
  /// year and month, or 0 to specify a year by itself or a year and month where
  /// the day isn't significant.
  ///
  /// [startDate_month] - Month of a year. Must be from 1 to 12, or 0 to specify
  /// a year without a month and day.
  ///
  /// [startDate_year] - Year of the date. Must be from 1 to 9999, or 0 to
  /// specify a date without a year.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleAdsHomeservicesLocalservicesV1SearchAccountReportsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleAdsHomeservicesLocalservicesV1SearchAccountReportsResponse>
      search({
    core.int? endDate_day,
    core.int? endDate_month,
    core.int? endDate_year,
    core.int? pageSize,
    core.String? pageToken,
    core.String? query,
    core.int? startDate_day,
    core.int? startDate_month,
    core.int? startDate_year,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (endDate_day != null) 'endDate.day': ['${endDate_day}'],
      if (endDate_month != null) 'endDate.month': ['${endDate_month}'],
      if (endDate_year != null) 'endDate.year': ['${endDate_year}'],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (query != null) 'query': [query],
      if (startDate_day != null) 'startDate.day': ['${startDate_day}'],
      if (startDate_month != null) 'startDate.month': ['${startDate_month}'],
      if (startDate_year != null) 'startDate.year': ['${startDate_year}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/accountReports:search';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleAdsHomeservicesLocalservicesV1SearchAccountReportsResponse
        .fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class DetailedLeadReportsResource {
  final commons.ApiRequester _requester;

  DetailedLeadReportsResource(commons.ApiRequester client)
      : _requester = client;

  /// Get detailed lead reports containing leads that have been received by all
  /// linked GLS accounts.
  ///
  /// Caller needs to provide their manager customer id and the associated auth
  /// credential that allows them read permissions on their linked accounts.
  ///
  /// Request parameters:
  ///
  /// [endDate_day] - Day of a month. Must be from 1 to 31 and valid for the
  /// year and month, or 0 to specify a year by itself or a year and month where
  /// the day isn't significant.
  ///
  /// [endDate_month] - Month of a year. Must be from 1 to 12, or 0 to specify a
  /// year without a month and day.
  ///
  /// [endDate_year] - Year of the date. Must be from 1 to 9999, or 0 to specify
  /// a date without a year.
  ///
  /// [pageSize] - The maximum number of accounts to return. If the page size is
  /// unset, page size will default to 1000. Maximum page_size is 10000.
  /// Optional.
  ///
  /// [pageToken] - The `next_page_token` value returned from a previous request
  /// to SearchDetailedLeadReports that indicates where listing should continue.
  /// Optional.
  ///
  /// [query] - A query string for searching for account reports. Caller must
  /// provide a customer id of their MCC account with an associated Gaia Mint
  /// that allows read permission on their linked accounts. Search expressions
  /// are case insensitive. Example query: | Query | Description |
  /// |-------------------------|-----------------------------------------------|
  /// | manager_customer_id:123 | Get Detailed Lead Report for Manager with id |
  /// | | 123. | Required.
  ///
  /// [startDate_day] - Day of a month. Must be from 1 to 31 and valid for the
  /// year and month, or 0 to specify a year by itself or a year and month where
  /// the day isn't significant.
  ///
  /// [startDate_month] - Month of a year. Must be from 1 to 12, or 0 to specify
  /// a year without a month and day.
  ///
  /// [startDate_year] - Year of the date. Must be from 1 to 9999, or 0 to
  /// specify a date without a year.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleAdsHomeservicesLocalservicesV1SearchDetailedLeadReportsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<
          GoogleAdsHomeservicesLocalservicesV1SearchDetailedLeadReportsResponse>
      search({
    core.int? endDate_day,
    core.int? endDate_month,
    core.int? endDate_year,
    core.int? pageSize,
    core.String? pageToken,
    core.String? query,
    core.int? startDate_day,
    core.int? startDate_month,
    core.int? startDate_year,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (endDate_day != null) 'endDate.day': ['${endDate_day}'],
      if (endDate_month != null) 'endDate.month': ['${endDate_month}'],
      if (endDate_year != null) 'endDate.year': ['${endDate_year}'],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (query != null) 'query': [query],
      if (startDate_day != null) 'startDate.day': ['${startDate_day}'],
      if (startDate_month != null) 'startDate.month': ['${startDate_month}'],
      if (startDate_year != null) 'startDate.year': ['${startDate_year}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/detailedLeadReports:search';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleAdsHomeservicesLocalservicesV1SearchDetailedLeadReportsResponse
        .fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// An Account Report of a GLS account identified by their account id containing
/// aggregate data gathered from a particular date range.
///
/// Next ID: 18
class GoogleAdsHomeservicesLocalservicesV1AccountReport {
  /// Unique identifier of the GLS account.
  core.String? accountId;

  /// Aggregator specific information related to the account.
  GoogleAdsHomeservicesLocalservicesV1AggregatorInfo? aggregatorInfo;

  /// Average review rating score from 1-5 stars.
  core.double? averageFiveStarRating;

  /// Average weekly budget in the currency code of the account.
  core.double? averageWeeklyBudget;

  /// Business name of the account.
  core.String? businessName;

  /// Currency code of the account.
  core.String? currencyCode;

  /// Number of charged leads the account received in current specified period.
  core.String? currentPeriodChargedLeads;

  /// Number of connected phone calls (duration over 30s) in current specified
  /// period.
  core.String? currentPeriodConnectedPhoneCalls;

  /// Number of phone calls in current specified period, including both
  /// connected and unconnected calls.
  core.String? currentPeriodPhoneCalls;

  /// Total cost of the account in current specified period in the account's
  /// specified currency.
  core.double? currentPeriodTotalCost;

  /// Number of impressions that customers have had in the past 2 days.
  core.String? impressionsLastTwoDays;

  /// Phone lead responsiveness of the account for the past 90 days from current
  /// date.
  ///
  /// This is computed by taking the total number of connected calls from
  /// charged phone leads and dividing by the total number of calls received.
  core.double? phoneLeadResponsiveness;

  /// Number of charged leads the account received in previous specified period.
  core.String? previousPeriodChargedLeads;

  /// Number of connected phone calls (duration over 30s) in previous specified
  /// period.
  core.String? previousPeriodConnectedPhoneCalls;

  /// Number of phone calls in previous specified period, including both
  /// connected and unconnected calls.
  core.String? previousPeriodPhoneCalls;

  /// Total cost of the account in previous specified period in the account's
  /// specified currency.
  core.double? previousPeriodTotalCost;

  /// Total number of reviews the account has up to current date.
  core.int? totalReview;

  GoogleAdsHomeservicesLocalservicesV1AccountReport();

  GoogleAdsHomeservicesLocalservicesV1AccountReport.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('aggregatorInfo')) {
      aggregatorInfo =
          GoogleAdsHomeservicesLocalservicesV1AggregatorInfo.fromJson(
              _json['aggregatorInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('averageFiveStarRating')) {
      averageFiveStarRating =
          (_json['averageFiveStarRating'] as core.num).toDouble();
    }
    if (_json.containsKey('averageWeeklyBudget')) {
      averageWeeklyBudget =
          (_json['averageWeeklyBudget'] as core.num).toDouble();
    }
    if (_json.containsKey('businessName')) {
      businessName = _json['businessName'] as core.String;
    }
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('currentPeriodChargedLeads')) {
      currentPeriodChargedLeads =
          _json['currentPeriodChargedLeads'] as core.String;
    }
    if (_json.containsKey('currentPeriodConnectedPhoneCalls')) {
      currentPeriodConnectedPhoneCalls =
          _json['currentPeriodConnectedPhoneCalls'] as core.String;
    }
    if (_json.containsKey('currentPeriodPhoneCalls')) {
      currentPeriodPhoneCalls = _json['currentPeriodPhoneCalls'] as core.String;
    }
    if (_json.containsKey('currentPeriodTotalCost')) {
      currentPeriodTotalCost =
          (_json['currentPeriodTotalCost'] as core.num).toDouble();
    }
    if (_json.containsKey('impressionsLastTwoDays')) {
      impressionsLastTwoDays = _json['impressionsLastTwoDays'] as core.String;
    }
    if (_json.containsKey('phoneLeadResponsiveness')) {
      phoneLeadResponsiveness =
          (_json['phoneLeadResponsiveness'] as core.num).toDouble();
    }
    if (_json.containsKey('previousPeriodChargedLeads')) {
      previousPeriodChargedLeads =
          _json['previousPeriodChargedLeads'] as core.String;
    }
    if (_json.containsKey('previousPeriodConnectedPhoneCalls')) {
      previousPeriodConnectedPhoneCalls =
          _json['previousPeriodConnectedPhoneCalls'] as core.String;
    }
    if (_json.containsKey('previousPeriodPhoneCalls')) {
      previousPeriodPhoneCalls =
          _json['previousPeriodPhoneCalls'] as core.String;
    }
    if (_json.containsKey('previousPeriodTotalCost')) {
      previousPeriodTotalCost =
          (_json['previousPeriodTotalCost'] as core.num).toDouble();
    }
    if (_json.containsKey('totalReview')) {
      totalReview = _json['totalReview'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (aggregatorInfo != null) 'aggregatorInfo': aggregatorInfo!.toJson(),
        if (averageFiveStarRating != null)
          'averageFiveStarRating': averageFiveStarRating!,
        if (averageWeeklyBudget != null)
          'averageWeeklyBudget': averageWeeklyBudget!,
        if (businessName != null) 'businessName': businessName!,
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (currentPeriodChargedLeads != null)
          'currentPeriodChargedLeads': currentPeriodChargedLeads!,
        if (currentPeriodConnectedPhoneCalls != null)
          'currentPeriodConnectedPhoneCalls': currentPeriodConnectedPhoneCalls!,
        if (currentPeriodPhoneCalls != null)
          'currentPeriodPhoneCalls': currentPeriodPhoneCalls!,
        if (currentPeriodTotalCost != null)
          'currentPeriodTotalCost': currentPeriodTotalCost!,
        if (impressionsLastTwoDays != null)
          'impressionsLastTwoDays': impressionsLastTwoDays!,
        if (phoneLeadResponsiveness != null)
          'phoneLeadResponsiveness': phoneLeadResponsiveness!,
        if (previousPeriodChargedLeads != null)
          'previousPeriodChargedLeads': previousPeriodChargedLeads!,
        if (previousPeriodConnectedPhoneCalls != null)
          'previousPeriodConnectedPhoneCalls':
              previousPeriodConnectedPhoneCalls!,
        if (previousPeriodPhoneCalls != null)
          'previousPeriodPhoneCalls': previousPeriodPhoneCalls!,
        if (previousPeriodTotalCost != null)
          'previousPeriodTotalCost': previousPeriodTotalCost!,
        if (totalReview != null) 'totalReview': totalReview!,
      };
}

/// Conatiner for aggregator specific information if lead is for an aggregator
/// GLS account.
class GoogleAdsHomeservicesLocalservicesV1AggregatorInfo {
  /// Provider id (listed in aggregator system) which maps to a account id in
  /// GLS system.
  core.String? aggregatorProviderId;

  GoogleAdsHomeservicesLocalservicesV1AggregatorInfo();

  GoogleAdsHomeservicesLocalservicesV1AggregatorInfo.fromJson(core.Map _json) {
    if (_json.containsKey('aggregatorProviderId')) {
      aggregatorProviderId = _json['aggregatorProviderId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aggregatorProviderId != null)
          'aggregatorProviderId': aggregatorProviderId!,
      };
}

/// A Detailed Lead Report of a lead identified by their lead id and contains
/// consumer, account, monetization, and lead data.
class GoogleAdsHomeservicesLocalservicesV1DetailedLeadReport {
  /// Identifies account that received the lead.
  core.String? accountId;

  /// Aggregator specific information related to the lead.
  GoogleAdsHomeservicesLocalservicesV1AggregatorInfo? aggregatorInfo;

  /// Business name associated to the account.
  core.String? businessName;

  /// Whether the lead has been charged.
  /// Possible string values are:
  /// - "CHARGE_STATUS_UNSPECIFIED" : Not specified.
  /// - "CHARGED" : Charged.
  /// - "NOT_CHARGED" : Not charged.
  core.String? chargeStatus;

  /// Currency code.
  core.String? currencyCode;

  /// Dispute status related to the lead.
  core.String? disputeStatus;

  /// Location of the associated account's home city.
  core.String? geo;

  /// Lead category (e.g. hvac, plumber)
  core.String? leadCategory;

  /// Timestamp of when the lead was created.
  core.String? leadCreationTimestamp;

  /// Unique identifier of a Detailed Lead Report.
  core.String? leadId;

  /// Price of the lead (available only after it has been charged).
  core.double? leadPrice;

  /// Lead type.
  /// Possible string values are:
  /// - "LEAD_TYPE_UNSPECIFIED" : Not specified.
  /// - "MESSAGE" : Message lead.
  /// - "PHONE_CALL" : Phone call lead.
  core.String? leadType;

  /// More information associated to only message leads.
  GoogleAdsHomeservicesLocalservicesV1MessageLead? messageLead;

  /// More information associated to only phone leads.
  GoogleAdsHomeservicesLocalservicesV1PhoneLead? phoneLead;

  /// Timezone of the particular provider associated to a lead.
  GoogleTypeTimeZone? timezone;

  GoogleAdsHomeservicesLocalservicesV1DetailedLeadReport();

  GoogleAdsHomeservicesLocalservicesV1DetailedLeadReport.fromJson(
      core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('aggregatorInfo')) {
      aggregatorInfo =
          GoogleAdsHomeservicesLocalservicesV1AggregatorInfo.fromJson(
              _json['aggregatorInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('businessName')) {
      businessName = _json['businessName'] as core.String;
    }
    if (_json.containsKey('chargeStatus')) {
      chargeStatus = _json['chargeStatus'] as core.String;
    }
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('disputeStatus')) {
      disputeStatus = _json['disputeStatus'] as core.String;
    }
    if (_json.containsKey('geo')) {
      geo = _json['geo'] as core.String;
    }
    if (_json.containsKey('leadCategory')) {
      leadCategory = _json['leadCategory'] as core.String;
    }
    if (_json.containsKey('leadCreationTimestamp')) {
      leadCreationTimestamp = _json['leadCreationTimestamp'] as core.String;
    }
    if (_json.containsKey('leadId')) {
      leadId = _json['leadId'] as core.String;
    }
    if (_json.containsKey('leadPrice')) {
      leadPrice = (_json['leadPrice'] as core.num).toDouble();
    }
    if (_json.containsKey('leadType')) {
      leadType = _json['leadType'] as core.String;
    }
    if (_json.containsKey('messageLead')) {
      messageLead = GoogleAdsHomeservicesLocalservicesV1MessageLead.fromJson(
          _json['messageLead'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('phoneLead')) {
      phoneLead = GoogleAdsHomeservicesLocalservicesV1PhoneLead.fromJson(
          _json['phoneLead'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timezone')) {
      timezone = GoogleTypeTimeZone.fromJson(
          _json['timezone'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (aggregatorInfo != null) 'aggregatorInfo': aggregatorInfo!.toJson(),
        if (businessName != null) 'businessName': businessName!,
        if (chargeStatus != null) 'chargeStatus': chargeStatus!,
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (disputeStatus != null) 'disputeStatus': disputeStatus!,
        if (geo != null) 'geo': geo!,
        if (leadCategory != null) 'leadCategory': leadCategory!,
        if (leadCreationTimestamp != null)
          'leadCreationTimestamp': leadCreationTimestamp!,
        if (leadId != null) 'leadId': leadId!,
        if (leadPrice != null) 'leadPrice': leadPrice!,
        if (leadType != null) 'leadType': leadType!,
        if (messageLead != null) 'messageLead': messageLead!.toJson(),
        if (phoneLead != null) 'phoneLead': phoneLead!.toJson(),
        if (timezone != null) 'timezone': timezone!.toJson(),
      };
}

/// Container for message lead specific information.
class GoogleAdsHomeservicesLocalservicesV1MessageLead {
  /// Consumer phone number associated with the message lead.
  core.String? consumerPhoneNumber;

  /// Name of the customer who created the lead.
  core.String? customerName;

  /// The job type of the specified lead.
  core.String? jobType;

  /// The postal code of the customer who created the lead.
  core.String? postalCode;

  GoogleAdsHomeservicesLocalservicesV1MessageLead();

  GoogleAdsHomeservicesLocalservicesV1MessageLead.fromJson(core.Map _json) {
    if (_json.containsKey('consumerPhoneNumber')) {
      consumerPhoneNumber = _json['consumerPhoneNumber'] as core.String;
    }
    if (_json.containsKey('customerName')) {
      customerName = _json['customerName'] as core.String;
    }
    if (_json.containsKey('jobType')) {
      jobType = _json['jobType'] as core.String;
    }
    if (_json.containsKey('postalCode')) {
      postalCode = _json['postalCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (consumerPhoneNumber != null)
          'consumerPhoneNumber': consumerPhoneNumber!,
        if (customerName != null) 'customerName': customerName!,
        if (jobType != null) 'jobType': jobType!,
        if (postalCode != null) 'postalCode': postalCode!,
      };
}

/// Container for phone lead specific information.
class GoogleAdsHomeservicesLocalservicesV1PhoneLead {
  /// Timestamp of the phone call which resulted in a charged phone lead.
  core.String? chargedCallTimestamp;

  /// Duration of the charged phone call in seconds.
  core.String? chargedConnectedCallDurationSeconds;

  /// Consumer phone number associated with the phone lead.
  core.String? consumerPhoneNumber;

  GoogleAdsHomeservicesLocalservicesV1PhoneLead();

  GoogleAdsHomeservicesLocalservicesV1PhoneLead.fromJson(core.Map _json) {
    if (_json.containsKey('chargedCallTimestamp')) {
      chargedCallTimestamp = _json['chargedCallTimestamp'] as core.String;
    }
    if (_json.containsKey('chargedConnectedCallDurationSeconds')) {
      chargedConnectedCallDurationSeconds =
          _json['chargedConnectedCallDurationSeconds'] as core.String;
    }
    if (_json.containsKey('consumerPhoneNumber')) {
      consumerPhoneNumber = _json['consumerPhoneNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (chargedCallTimestamp != null)
          'chargedCallTimestamp': chargedCallTimestamp!,
        if (chargedConnectedCallDurationSeconds != null)
          'chargedConnectedCallDurationSeconds':
              chargedConnectedCallDurationSeconds!,
        if (consumerPhoneNumber != null)
          'consumerPhoneNumber': consumerPhoneNumber!,
      };
}

/// A page of the response received from the SearchAccountReports method.
///
/// A paginated response where more pages are available has `next_page_token`
/// set. This token can be used in a subsequent request to retrieve the next
/// request page.
class GoogleAdsHomeservicesLocalservicesV1SearchAccountReportsResponse {
  /// List of account reports which maps 1:1 to a particular linked GLS account.
  core.List<GoogleAdsHomeservicesLocalservicesV1AccountReport>? accountReports;

  /// Pagination token to retrieve the next page of results.
  ///
  /// When `next_page_token` is not filled in, there is no next page and the
  /// list returned is the last page in the result set.
  core.String? nextPageToken;

  GoogleAdsHomeservicesLocalservicesV1SearchAccountReportsResponse();

  GoogleAdsHomeservicesLocalservicesV1SearchAccountReportsResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('accountReports')) {
      accountReports = (_json['accountReports'] as core.List)
          .map<GoogleAdsHomeservicesLocalservicesV1AccountReport>((value) =>
              GoogleAdsHomeservicesLocalservicesV1AccountReport.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountReports != null)
          'accountReports':
              accountReports!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A page of the response received from the SearchDetailedLeadReports method.
///
/// A paginated response where more pages are available has `next_page_token`
/// set. This token can be used in a subsequent request to retrieve the next
/// request page.
class GoogleAdsHomeservicesLocalservicesV1SearchDetailedLeadReportsResponse {
  /// List of detailed lead reports uniquely identified by external lead id.
  core.List<GoogleAdsHomeservicesLocalservicesV1DetailedLeadReport>?
      detailedLeadReports;

  /// Pagination token to retrieve the next page of results.
  ///
  /// When `next_page_token` is not filled in, there is no next page and the
  /// list returned is the last page in the result set.
  core.String? nextPageToken;

  GoogleAdsHomeservicesLocalservicesV1SearchDetailedLeadReportsResponse();

  GoogleAdsHomeservicesLocalservicesV1SearchDetailedLeadReportsResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('detailedLeadReports')) {
      detailedLeadReports = (_json['detailedLeadReports'] as core.List)
          .map<GoogleAdsHomeservicesLocalservicesV1DetailedLeadReport>(
              (value) => GoogleAdsHomeservicesLocalservicesV1DetailedLeadReport
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (detailedLeadReports != null)
          'detailedLeadReports':
              detailedLeadReports!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Represents a time zone from the
/// [IANA Time Zone Database](https://www.iana.org/time-zones).
class GoogleTypeTimeZone {
  /// IANA Time Zone Database time zone, e.g. "America/New_York".
  core.String? id;

  /// IANA Time Zone Database version number, e.g. "2019a".
  ///
  /// Optional.
  core.String? version;

  GoogleTypeTimeZone();

  GoogleTypeTimeZone.fromJson(core.Map _json) {
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

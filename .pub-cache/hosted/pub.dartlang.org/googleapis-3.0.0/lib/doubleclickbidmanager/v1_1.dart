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

/// DoubleClick Bid Manager API - v1.1
///
/// DoubleClick Bid Manager API allows users to manage and create campaigns and
/// reports.
///
/// For more information, see <https://developers.google.com/bid-manager/>
///
/// Create an instance of [DoubleClickBidManagerApi] to access these resources:
///
/// - [QueriesResource]
/// - [ReportsResource]
library doubleclickbidmanager.v1_1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// DoubleClick Bid Manager API allows users to manage and create campaigns and
/// reports.
class DoubleClickBidManagerApi {
  /// View and manage your reports in DoubleClick Bid Manager
  static const doubleclickbidmanagerScope =
      'https://www.googleapis.com/auth/doubleclickbidmanager';

  final commons.ApiRequester _requester;

  QueriesResource get queries => QueriesResource(_requester);
  ReportsResource get reports => ReportsResource(_requester);

  DoubleClickBidManagerApi(http.Client client,
      {core.String rootUrl = 'https://doubleclickbidmanager.googleapis.com/',
      core.String servicePath = 'doubleclickbidmanager/v1.1/'})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class QueriesResource {
  final commons.ApiRequester _requester;

  QueriesResource(commons.ApiRequester client) : _requester = client;

  /// Creates a query.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [asynchronous] - If true, tries to run the query asynchronously. Only
  /// applicable when the frequency is ONE_TIME.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Query].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Query> createquery(
    Query request, {
    core.bool? asynchronous,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (asynchronous != null) 'asynchronous': ['${asynchronous}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'query';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Query.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a stored query as well as the associated stored reports.
  ///
  /// Request parameters:
  ///
  /// [queryId] - Query ID to delete.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> deletequery(
    core.String queryId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'query/' + commons.escapeVariable('$queryId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves a stored query.
  ///
  /// Request parameters:
  ///
  /// [queryId] - Query ID to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Query].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Query> getquery(
    core.String queryId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'query/' + commons.escapeVariable('$queryId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Query.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves stored queries.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Maximum number of results per page. Must be between 1 and
  /// 100. Defaults to 100 if unspecified.
  ///
  /// [pageToken] - Optional pagination token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListQueriesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListQueriesResponse> listqueries({
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'queries';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListQueriesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Runs a stored query to generate a report.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [queryId] - Query ID to run.
  ///
  /// [asynchronous] - If true, tries to run the query asynchronously.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> runquery(
    RunQueryRequest request,
    core.String queryId, {
    core.bool? asynchronous,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (asynchronous != null) 'asynchronous': ['${asynchronous}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'query/' + commons.escapeVariable('$queryId');

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }
}

class ReportsResource {
  final commons.ApiRequester _requester;

  ReportsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves stored reports.
  ///
  /// Request parameters:
  ///
  /// [queryId] - Query ID with which the reports are associated.
  ///
  /// [pageSize] - Maximum number of results per page. Must be between 1 and
  /// 100. Defaults to 100 if unspecified.
  ///
  /// [pageToken] - Optional pagination token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListReportsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListReportsResponse> listreports(
    core.String queryId, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'queries/' + commons.escapeVariable('$queryId') + '/reports';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListReportsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// A channel grouping defines a set of rules that can be used to categorize
/// events in a path report.
class ChannelGrouping {
  /// The name to apply to an event that does not match any of the rules in the
  /// channel grouping.
  core.String? fallbackName;

  /// Channel Grouping name.
  core.String? name;

  /// Rules within Channel Grouping.
  ///
  /// There is a limit of 100 rules that can be set per channel grouping.
  core.List<Rule>? rules;

  ChannelGrouping();

  ChannelGrouping.fromJson(core.Map _json) {
    if (_json.containsKey('fallbackName')) {
      fallbackName = _json['fallbackName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('rules')) {
      rules = (_json['rules'] as core.List)
          .map<Rule>((value) =>
              Rule.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fallbackName != null) 'fallbackName': fallbackName!,
        if (name != null) 'name': name!,
        if (rules != null)
          'rules': rules!.map((value) => value.toJson()).toList(),
      };
}

/// DisjunctiveMatchStatement that OR's all contained filters.
class DisjunctiveMatchStatement {
  /// Filters.
  ///
  /// There is a limit of 100 filters that can be set per disjunctive match
  /// statement.
  core.List<EventFilter>? eventFilters;

  DisjunctiveMatchStatement();

  DisjunctiveMatchStatement.fromJson(core.Map _json) {
    if (_json.containsKey('eventFilters')) {
      eventFilters = (_json['eventFilters'] as core.List)
          .map<EventFilter>((value) => EventFilter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (eventFilters != null)
          'eventFilters': eventFilters!.map((value) => value.toJson()).toList(),
      };
}

/// Defines the type of filter to be applied to the path, a DV360 event
/// dimension filter.
class EventFilter {
  /// Filter on a dimension.
  PathQueryOptionsFilter? dimensionFilter;

  EventFilter();

  EventFilter.fromJson(core.Map _json) {
    if (_json.containsKey('dimensionFilter')) {
      dimensionFilter = PathQueryOptionsFilter.fromJson(
          _json['dimensionFilter'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dimensionFilter != null)
          'dimensionFilter': dimensionFilter!.toJson(),
      };
}

/// Filter used to match traffic data in your report.
class FilterPair {
  /// Filter type.
  /// Possible string values are:
  /// - "FILTER_UNKNOWN"
  /// - "FILTER_DATE"
  /// - "FILTER_DAY_OF_WEEK"
  /// - "FILTER_WEEK"
  /// - "FILTER_MONTH"
  /// - "FILTER_YEAR"
  /// - "FILTER_TIME_OF_DAY"
  /// - "FILTER_CONVERSION_DELAY"
  /// - "FILTER_CREATIVE_ID"
  /// - "FILTER_CREATIVE_SIZE"
  /// - "FILTER_CREATIVE_TYPE"
  /// - "FILTER_EXCHANGE_ID"
  /// - "FILTER_AD_POSITION"
  /// - "FILTER_PUBLIC_INVENTORY"
  /// - "FILTER_INVENTORY_SOURCE"
  /// - "FILTER_CITY"
  /// - "FILTER_REGION"
  /// - "FILTER_DMA"
  /// - "FILTER_COUNTRY"
  /// - "FILTER_SITE_ID"
  /// - "FILTER_CHANNEL_ID"
  /// - "FILTER_PARTNER"
  /// - "FILTER_ADVERTISER"
  /// - "FILTER_INSERTION_ORDER"
  /// - "FILTER_LINE_ITEM"
  /// - "FILTER_PARTNER_CURRENCY"
  /// - "FILTER_ADVERTISER_CURRENCY"
  /// - "FILTER_ADVERTISER_TIMEZONE"
  /// - "FILTER_LINE_ITEM_TYPE"
  /// - "FILTER_USER_LIST"
  /// - "FILTER_USER_LIST_FIRST_PARTY"
  /// - "FILTER_USER_LIST_THIRD_PARTY"
  /// - "FILTER_TARGETED_USER_LIST"
  /// - "FILTER_DATA_PROVIDER"
  /// - "FILTER_ORDER_ID"
  /// - "FILTER_VIDEO_PLAYER_SIZE"
  /// - "FILTER_VIDEO_DURATION_SECONDS"
  /// - "FILTER_KEYWORD"
  /// - "FILTER_PAGE_CATEGORY"
  /// - "FILTER_CAMPAIGN_DAILY_FREQUENCY"
  /// - "FILTER_LINE_ITEM_DAILY_FREQUENCY"
  /// - "FILTER_LINE_ITEM_LIFETIME_FREQUENCY"
  /// - "FILTER_OS"
  /// - "FILTER_BROWSER"
  /// - "FILTER_CARRIER"
  /// - "FILTER_SITE_LANGUAGE"
  /// - "FILTER_INVENTORY_FORMAT"
  /// - "FILTER_ZIP_CODE"
  /// - "FILTER_VIDEO_RATING_TIER"
  /// - "FILTER_VIDEO_FORMAT_SUPPORT"
  /// - "FILTER_VIDEO_SKIPPABLE_SUPPORT"
  /// - "FILTER_VIDEO_CREATIVE_DURATION"
  /// - "FILTER_PAGE_LAYOUT"
  /// - "FILTER_VIDEO_AD_POSITION_IN_STREAM"
  /// - "FILTER_AGE"
  /// - "FILTER_GENDER"
  /// - "FILTER_QUARTER"
  /// - "FILTER_TRUEVIEW_CONVERSION_TYPE"
  /// - "FILTER_MOBILE_GEO"
  /// - "FILTER_MRAID_SUPPORT"
  /// - "FILTER_ACTIVE_VIEW_EXPECTED_VIEWABILITY"
  /// - "FILTER_VIDEO_CREATIVE_DURATION_SKIPPABLE"
  /// - "FILTER_NIELSEN_COUNTRY_CODE"
  /// - "FILTER_NIELSEN_DEVICE_ID"
  /// - "FILTER_NIELSEN_GENDER"
  /// - "FILTER_NIELSEN_AGE"
  /// - "FILTER_INVENTORY_SOURCE_TYPE"
  /// - "FILTER_CREATIVE_WIDTH"
  /// - "FILTER_CREATIVE_HEIGHT"
  /// - "FILTER_DFP_ORDER_ID"
  /// - "FILTER_TRUEVIEW_AGE"
  /// - "FILTER_TRUEVIEW_GENDER"
  /// - "FILTER_TRUEVIEW_PARENTAL_STATUS"
  /// - "FILTER_TRUEVIEW_REMARKETING_LIST"
  /// - "FILTER_TRUEVIEW_INTEREST"
  /// - "FILTER_TRUEVIEW_AD_GROUP_ID"
  /// - "FILTER_TRUEVIEW_AD_GROUP_AD_ID"
  /// - "FILTER_TRUEVIEW_IAR_LANGUAGE"
  /// - "FILTER_TRUEVIEW_IAR_GENDER"
  /// - "FILTER_TRUEVIEW_IAR_AGE"
  /// - "FILTER_TRUEVIEW_IAR_CATEGORY"
  /// - "FILTER_TRUEVIEW_IAR_COUNTRY"
  /// - "FILTER_TRUEVIEW_IAR_CITY"
  /// - "FILTER_TRUEVIEW_IAR_REGION"
  /// - "FILTER_TRUEVIEW_IAR_ZIPCODE"
  /// - "FILTER_TRUEVIEW_IAR_REMARKETING_LIST"
  /// - "FILTER_TRUEVIEW_IAR_INTEREST"
  /// - "FILTER_TRUEVIEW_IAR_PARENTAL_STATUS"
  /// - "FILTER_TRUEVIEW_IAR_TIME_OF_DAY"
  /// - "FILTER_TRUEVIEW_CUSTOM_AFFINITY"
  /// - "FILTER_TRUEVIEW_CATEGORY"
  /// - "FILTER_TRUEVIEW_KEYWORD"
  /// - "FILTER_TRUEVIEW_PLACEMENT"
  /// - "FILTER_TRUEVIEW_URL"
  /// - "FILTER_TRUEVIEW_COUNTRY"
  /// - "FILTER_TRUEVIEW_REGION"
  /// - "FILTER_TRUEVIEW_CITY"
  /// - "FILTER_TRUEVIEW_DMA"
  /// - "FILTER_TRUEVIEW_ZIPCODE"
  /// - "FILTER_NOT_SUPPORTED"
  /// - "FILTER_MEDIA_PLAN"
  /// - "FILTER_TRUEVIEW_IAR_YOUTUBE_CHANNEL"
  /// - "FILTER_TRUEVIEW_IAR_YOUTUBE_VIDEO"
  /// - "FILTER_SKIPPABLE_SUPPORT"
  /// - "FILTER_COMPANION_CREATIVE_ID"
  /// - "FILTER_BUDGET_SEGMENT_DESCRIPTION"
  /// - "FILTER_FLOODLIGHT_ACTIVITY_ID"
  /// - "FILTER_DEVICE_MODEL"
  /// - "FILTER_DEVICE_MAKE"
  /// - "FILTER_DEVICE_TYPE"
  /// - "FILTER_CREATIVE_ATTRIBUTE"
  /// - "FILTER_INVENTORY_COMMITMENT_TYPE"
  /// - "FILTER_INVENTORY_RATE_TYPE"
  /// - "FILTER_INVENTORY_DELIVERY_METHOD"
  /// - "FILTER_INVENTORY_SOURCE_EXTERNAL_ID"
  /// - "FILTER_AUTHORIZED_SELLER_STATE"
  /// - "FILTER_VIDEO_DURATION_SECONDS_RANGE"
  /// - "FILTER_PARTNER_NAME"
  /// - "FILTER_PARTNER_STATUS"
  /// - "FILTER_ADVERTISER_NAME"
  /// - "FILTER_ADVERTISER_INTEGRATION_CODE"
  /// - "FILTER_ADVERTISER_INTEGRATION_STATUS"
  /// - "FILTER_CARRIER_NAME"
  /// - "FILTER_CHANNEL_NAME"
  /// - "FILTER_CITY_NAME"
  /// - "FILTER_COMPANION_CREATIVE_NAME"
  /// - "FILTER_USER_LIST_FIRST_PARTY_NAME"
  /// - "FILTER_USER_LIST_THIRD_PARTY_NAME"
  /// - "FILTER_NIELSEN_RESTATEMENT_DATE"
  /// - "FILTER_NIELSEN_DATE_RANGE"
  /// - "FILTER_INSERTION_ORDER_NAME"
  /// - "FILTER_REGION_NAME"
  /// - "FILTER_DMA_NAME"
  /// - "FILTER_TRUEVIEW_IAR_REGION_NAME"
  /// - "FILTER_TRUEVIEW_DMA_NAME"
  /// - "FILTER_TRUEVIEW_REGION_NAME"
  /// - "FILTER_ACTIVE_VIEW_CUSTOM_METRIC_ID"
  /// - "FILTER_ACTIVE_VIEW_CUSTOM_METRIC_NAME"
  /// - "FILTER_AD_TYPE"
  /// - "FILTER_ALGORITHM"
  /// - "FILTER_ALGORITHM_ID"
  /// - "FILTER_AMP_PAGE_REQUEST"
  /// - "FILTER_ANONYMOUS_INVENTORY_MODELING"
  /// - "FILTER_APP_URL"
  /// - "FILTER_APP_URL_EXCLUDED"
  /// - "FILTER_ATTRIBUTED_USERLIST"
  /// - "FILTER_ATTRIBUTED_USERLIST_COST"
  /// - "FILTER_ATTRIBUTED_USERLIST_TYPE"
  /// - "FILTER_ATTRIBUTION_MODEL"
  /// - "FILTER_AUDIENCE_LIST"
  /// - "FILTER_AUDIENCE_LIST_COST"
  /// - "FILTER_AUDIENCE_LIST_TYPE"
  /// - "FILTER_AUDIENCE_NAME"
  /// - "FILTER_AUDIENCE_TYPE"
  /// - "FILTER_BILLABLE_OUTCOME"
  /// - "FILTER_BRAND_LIFT_TYPE"
  /// - "FILTER_CHANNEL_TYPE"
  /// - "FILTER_CM_PLACEMENT_ID"
  /// - "FILTER_CONVERSION_SOURCE"
  /// - "FILTER_CONVERSION_SOURCE_ID"
  /// - "FILTER_COUNTRY_ID"
  /// - "FILTER_CREATIVE"
  /// - "FILTER_CREATIVE_ASSET"
  /// - "FILTER_CREATIVE_INTEGRATION_CODE"
  /// - "FILTER_CREATIVE_RENDERED_IN_AMP"
  /// - "FILTER_CREATIVE_SOURCE"
  /// - "FILTER_CREATIVE_STATUS"
  /// - "FILTER_DATA_PROVIDER_NAME"
  /// - "FILTER_DETAILED_DEMOGRAPHICS"
  /// - "FILTER_DETAILED_DEMOGRAPHICS_ID"
  /// - "FILTER_DEVICE"
  /// - "FILTER_GAM_INSERTION_ORDER"
  /// - "FILTER_GAM_LINE_ITEM"
  /// - "FILTER_GAM_LINE_ITEM_ID"
  /// - "FILTER_DIGITAL_CONTENT_LABEL"
  /// - "FILTER_DOMAIN"
  /// - "FILTER_ELIGIBLE_COOKIES_ON_FIRST_PARTY_AUDIENCE_LIST"
  /// - "FILTER_ELIGIBLE_COOKIES_ON_THIRD_PARTY_AUDIENCE_LIST_AND_INTEREST"
  /// - "FILTER_EXCHANGE"
  /// - "FILTER_EXCHANGE_CODE"
  /// - "FILTER_EXTENSION"
  /// - "FILTER_EXTENSION_STATUS"
  /// - "FILTER_EXTENSION_TYPE"
  /// - "FILTER_FIRST_PARTY_AUDIENCE_LIST_COST"
  /// - "FILTER_FIRST_PARTY_AUDIENCE_LIST_TYPE"
  /// - "FILTER_FLOODLIGHT_ACTIVITY"
  /// - "FILTER_FORMAT"
  /// - "FILTER_GMAIL_AGE"
  /// - "FILTER_GMAIL_CITY"
  /// - "FILTER_GMAIL_COUNTRY"
  /// - "FILTER_GMAIL_COUNTRY_NAME"
  /// - "FILTER_GMAIL_DEVICE_TYPE"
  /// - "FILTER_GMAIL_DEVICE_TYPE_NAME"
  /// - "FILTER_GMAIL_GENDER"
  /// - "FILTER_GMAIL_REGION"
  /// - "FILTER_GMAIL_REMARKETING_LIST"
  /// - "FILTER_HOUSEHOLD_INCOME"
  /// - "FILTER_IMPRESSION_COUNTING_METHOD"
  /// - "FILTER_YOUTUBE_PROGRAMMATIC_GUARANTEED_INSERTION_ORDER"
  /// - "FILTER_INSERTION_ORDER_INTEGRATION_CODE"
  /// - "FILTER_INSERTION_ORDER_STATUS"
  /// - "FILTER_INTEREST"
  /// - "FILTER_INVENTORY_SOURCE_GROUP"
  /// - "FILTER_INVENTORY_SOURCE_GROUP_ID"
  /// - "FILTER_INVENTORY_SOURCE_ID"
  /// - "FILTER_INVENTORY_SOURCE_NAME"
  /// - "FILTER_LIFE_EVENT"
  /// - "FILTER_LIFE_EVENTS"
  /// - "FILTER_LINE_ITEM_INTEGRATION_CODE"
  /// - "FILTER_LINE_ITEM_NAME"
  /// - "FILTER_LINE_ITEM_STATUS"
  /// - "FILTER_MATCH_RATIO"
  /// - "FILTER_MEASUREMENT_SOURCE"
  /// - "FILTER_MEDIA_PLAN_NAME"
  /// - "FILTER_PARENTAL_STATUS"
  /// - "FILTER_PLACEMENT_ALL_YOUTUBE_CHANNELS"
  /// - "FILTER_PLATFORM"
  /// - "FILTER_PLAYBACK_METHOD"
  /// - "FILTER_POSITION_IN_CONTENT"
  /// - "FILTER_PUBLISHER_PROPERTY"
  /// - "FILTER_PUBLISHER_PROPERTY_ID"
  /// - "FILTER_PUBLISHER_PROPERTY_SECTION"
  /// - "FILTER_PUBLISHER_PROPERTY_SECTION_ID"
  /// - "FILTER_REFUND_REASON"
  /// - "FILTER_REMARKETING_LIST"
  /// - "FILTER_REWARDED"
  /// - "FILTER_SENSITIVE_CATEGORY"
  /// - "FILTER_SERVED_PIXEL_DENSITY"
  /// - "FILTER_TARGETED_DATA_PROVIDERS"
  /// - "FILTER_THIRD_PARTY_AUDIENCE_LIST_COST"
  /// - "FILTER_THIRD_PARTY_AUDIENCE_LIST_TYPE"
  /// - "FILTER_TRUEVIEW_AD"
  /// - "FILTER_TRUEVIEW_AD_GROUP"
  /// - "FILTER_TRUEVIEW_DETAILED_DEMOGRAPHICS"
  /// - "FILTER_TRUEVIEW_DETAILED_DEMOGRAPHICS_ID"
  /// - "FILTER_TRUEVIEW_HOUSEHOLD_INCOME"
  /// - "FILTER_TRUEVIEW_IAR_COUNTRY_NAME"
  /// - "FILTER_TRUEVIEW_REMARKETING_LIST_NAME"
  /// - "FILTER_VARIANT_ID"
  /// - "FILTER_VARIANT_NAME"
  /// - "FILTER_VARIANT_VERSION"
  /// - "FILTER_VERIFICATION_VIDEO_PLAYER_SIZE"
  /// - "FILTER_VERIFICATION_VIDEO_POSITION"
  /// - "FILTER_VIDEO_COMPANION_CREATIVE_SIZE"
  /// - "FILTER_VIDEO_CONTINUOUS_PLAY"
  /// - "FILTER_VIDEO_DURATION"
  /// - "FILTER_YOUTUBE_ADAPTED_AUDIENCE_LIST"
  /// - "FILTER_YOUTUBE_AD_VIDEO"
  /// - "FILTER_YOUTUBE_AD_VIDEO_ID"
  /// - "FILTER_YOUTUBE_CHANNEL"
  /// - "FILTER_YOUTUBE_PROGRAMMATIC_GUARANTEED_ADVERTISER"
  /// - "FILTER_YOUTUBE_PROGRAMMATIC_GUARANTEED_PARTNER"
  /// - "FILTER_YOUTUBE_VIDEO"
  /// - "FILTER_ZIP_POSTAL_CODE"
  /// - "FILTER_PLACEMENT_NAME_ALL_YOUTUBE_CHANNELS"
  /// - "FILTER_TRUEVIEW_PLACEMENT_ID"
  /// - "FILTER_PATH_PATTERN_ID"
  /// - "FILTER_PATH_EVENT_INDEX"
  /// - "FILTER_EVENT_TYPE"
  /// - "FILTER_CHANNEL_GROUPING"
  /// - "FILTER_OM_SDK_AVAILABLE"
  /// - "FILTER_DATA_SOURCE"
  /// - "FILTER_CM360_PLACEMENT_ID"
  /// - "FILTER_TRUEVIEW_CLICK_TYPE_NAME"
  /// - "FILTER_TRUEVIEW_AD_TYPE_NAME"
  /// - "FILTER_VIDEO_CONTENT_DURATION"
  /// - "FILTER_MATCHED_GENRE_TARGET"
  /// - "FILTER_VIDEO_CONTENT_LIVE_STREAM"
  /// - "FILTER_BUDGET_SEGMENT_TYPE"
  /// - "FILTER_BUDGET_SEGMENT_BUDGET"
  /// - "FILTER_BUDGET_SEGMENT_START_DATE"
  /// - "FILTER_BUDGET_SEGMENT_END_DATE"
  /// - "FILTER_BUDGET_SEGMENT_PACING_PERCENTAGE"
  /// - "FILTER_LINE_ITEM_BUDGET"
  /// - "FILTER_LINE_ITEM_START_DATE"
  /// - "FILTER_LINE_ITEM_END_DATE"
  /// - "FILTER_INSERTION_ORDER_GOAL_TYPE"
  /// - "FILTER_LINE_ITEM_PACING_PERCENTAGE"
  /// - "FILTER_INSERTION_ORDER_GOAL_VALUE"
  /// - "FILTER_OMID_CAPABLE"
  core.String? type;

  /// Filter value.
  core.String? value;

  FilterPair();

  FilterPair.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
      };
}

/// List queries response.
class ListQueriesResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "doubleclickbidmanager#listQueriesResponse".
  core.String? kind;

  /// Next page's pagination token if one exists.
  core.String? nextPageToken;

  /// Retrieved queries.
  core.List<Query>? queries;

  ListQueriesResponse();

  ListQueriesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('queries')) {
      queries = (_json['queries'] as core.List)
          .map<Query>((value) =>
              Query.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (queries != null)
          'queries': queries!.map((value) => value.toJson()).toList(),
      };
}

/// List reports response.
class ListReportsResponse {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "doubleclickbidmanager#listReportsResponse".
  core.String? kind;

  /// Next page's pagination token if one exists.
  core.String? nextPageToken;

  /// Retrieved reports.
  core.List<Report>? reports;

  ListReportsResponse();

  ListReportsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('reports')) {
      reports = (_json['reports'] as core.List)
          .map<Report>((value) =>
              Report.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (reports != null)
          'reports': reports!.map((value) => value.toJson()).toList(),
      };
}

/// Additional query options.
class Options {
  /// Set to true and filter your report by `FILTER_INSERTION_ORDER` or
  /// `FILTER_LINE_ITEM` to include data for audience lists specifically
  /// targeted by those items.
  core.bool? includeOnlyTargetedUserLists;

  /// Options that contain Path Filters and Custom Channel Groupings.
  PathQueryOptions? pathQueryOptions;

  Options();

  Options.fromJson(core.Map _json) {
    if (_json.containsKey('includeOnlyTargetedUserLists')) {
      includeOnlyTargetedUserLists =
          _json['includeOnlyTargetedUserLists'] as core.bool;
    }
    if (_json.containsKey('pathQueryOptions')) {
      pathQueryOptions = PathQueryOptions.fromJson(
          _json['pathQueryOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (includeOnlyTargetedUserLists != null)
          'includeOnlyTargetedUserLists': includeOnlyTargetedUserLists!,
        if (pathQueryOptions != null)
          'pathQueryOptions': pathQueryOptions!.toJson(),
      };
}

/// Parameters of a query or report.
class Parameters {
  /// Filters used to match traffic data in your report.
  core.List<FilterPair>? filters;

  /// Data is grouped by the filters listed in this field.
  core.List<core.String>? groupBys;

  /// This field is no longer in use.
  ///
  /// Deprecated.
  core.bool? includeInviteData;

  /// Metrics to include as columns in your report.
  core.List<core.String>? metrics;

  /// Additional query options.
  Options? options;

  /// Report type.
  /// Possible string values are:
  /// - "TYPE_GENERAL"
  /// - "TYPE_AUDIENCE_PERFORMANCE"
  /// - "TYPE_INVENTORY_AVAILABILITY"
  /// - "TYPE_KEYWORD"
  /// - "TYPE_PIXEL_LOAD"
  /// - "TYPE_AUDIENCE_COMPOSITION"
  /// - "TYPE_CROSS_PARTNER"
  /// - "TYPE_PAGE_CATEGORY"
  /// - "TYPE_THIRD_PARTY_DATA_PROVIDER"
  /// - "TYPE_CROSS_PARTNER_THIRD_PARTY_DATA_PROVIDER"
  /// - "TYPE_CLIENT_SAFE"
  /// - "TYPE_ORDER_ID"
  /// - "TYPE_FEE"
  /// - "TYPE_CROSS_FEE"
  /// - "TYPE_ACTIVE_GRP"
  /// - "TYPE_YOUTUBE_VERTICAL"
  /// - "TYPE_COMSCORE_VCE"
  /// - "TYPE_TRUEVIEW"
  /// - "TYPE_NIELSEN_AUDIENCE_PROFILE"
  /// - "TYPE_NIELSEN_DAILY_REACH_BUILD"
  /// - "TYPE_NIELSEN_SITE"
  /// - "TYPE_REACH_AND_FREQUENCY"
  /// - "TYPE_ESTIMATED_CONVERSION"
  /// - "TYPE_VERIFICATION"
  /// - "TYPE_TRUEVIEW_IAR"
  /// - "TYPE_NIELSEN_ONLINE_GLOBAL_MARKET"
  /// - "TYPE_PETRA_NIELSEN_AUDIENCE_PROFILE"
  /// - "TYPE_PETRA_NIELSEN_DAILY_REACH_BUILD"
  /// - "TYPE_PETRA_NIELSEN_ONLINE_GLOBAL_MARKET"
  /// - "TYPE_NOT_SUPPORTED"
  /// - "TYPE_REACH_AUDIENCE"
  /// - "TYPE_LINEAR_TV_SEARCH_LIFT"
  /// - "TYPE_PATH"
  /// - "TYPE_PATH_ATTRIBUTION"
  core.String? type;

  Parameters();

  Parameters.fromJson(core.Map _json) {
    if (_json.containsKey('filters')) {
      filters = (_json['filters'] as core.List)
          .map<FilterPair>((value) =>
              FilterPair.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('groupBys')) {
      groupBys = (_json['groupBys'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('includeInviteData')) {
      includeInviteData = _json['includeInviteData'] as core.bool;
    }
    if (_json.containsKey('metrics')) {
      metrics = (_json['metrics'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('options')) {
      options = Options.fromJson(
          _json['options'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filters != null)
          'filters': filters!.map((value) => value.toJson()).toList(),
        if (groupBys != null) 'groupBys': groupBys!,
        if (includeInviteData != null) 'includeInviteData': includeInviteData!,
        if (metrics != null) 'metrics': metrics!,
        if (options != null) 'options': options!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// Path filters specify which paths to include in a report.
///
/// A path is the result of combining DV360 events based on User ID to create a
/// workflow of users' actions. When a path filter is set, the resulting report
/// will only include paths that match the specified event at the specified
/// position. All other paths will be excluded.
class PathFilter {
  /// Filter on an event to be applied to some part of the path.
  core.List<EventFilter>? eventFilters;

  /// Indicates the position of the path the filter should match to (first,
  /// last, or any event in path).
  /// Possible string values are:
  /// - "ANY"
  /// - "FIRST"
  /// - "LAST"
  core.String? pathMatchPosition;

  PathFilter();

  PathFilter.fromJson(core.Map _json) {
    if (_json.containsKey('eventFilters')) {
      eventFilters = (_json['eventFilters'] as core.List)
          .map<EventFilter>((value) => EventFilter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('pathMatchPosition')) {
      pathMatchPosition = _json['pathMatchPosition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (eventFilters != null)
          'eventFilters': eventFilters!.map((value) => value.toJson()).toList(),
        if (pathMatchPosition != null) 'pathMatchPosition': pathMatchPosition!,
      };
}

/// Path Query Options for Report Options.
class PathQueryOptions {
  /// Custom Channel Groupings.
  ChannelGrouping? channelGrouping;

  /// Path Filters.
  ///
  /// There is a limit of 100 path filters that can be set per report.
  core.List<PathFilter>? pathFilters;

  PathQueryOptions();

  PathQueryOptions.fromJson(core.Map _json) {
    if (_json.containsKey('channelGrouping')) {
      channelGrouping = ChannelGrouping.fromJson(
          _json['channelGrouping'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pathFilters')) {
      pathFilters = (_json['pathFilters'] as core.List)
          .map<PathFilter>((value) =>
              PathFilter.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (channelGrouping != null)
          'channelGrouping': channelGrouping!.toJson(),
        if (pathFilters != null)
          'pathFilters': pathFilters!.map((value) => value.toJson()).toList(),
      };
}

/// Dimension Filter on path events.
class PathQueryOptionsFilter {
  /// Dimension the filter is applied to.
  /// Possible string values are:
  /// - "FILTER_UNKNOWN"
  /// - "FILTER_DATE"
  /// - "FILTER_DAY_OF_WEEK"
  /// - "FILTER_WEEK"
  /// - "FILTER_MONTH"
  /// - "FILTER_YEAR"
  /// - "FILTER_TIME_OF_DAY"
  /// - "FILTER_CONVERSION_DELAY"
  /// - "FILTER_CREATIVE_ID"
  /// - "FILTER_CREATIVE_SIZE"
  /// - "FILTER_CREATIVE_TYPE"
  /// - "FILTER_EXCHANGE_ID"
  /// - "FILTER_AD_POSITION"
  /// - "FILTER_PUBLIC_INVENTORY"
  /// - "FILTER_INVENTORY_SOURCE"
  /// - "FILTER_CITY"
  /// - "FILTER_REGION"
  /// - "FILTER_DMA"
  /// - "FILTER_COUNTRY"
  /// - "FILTER_SITE_ID"
  /// - "FILTER_CHANNEL_ID"
  /// - "FILTER_PARTNER"
  /// - "FILTER_ADVERTISER"
  /// - "FILTER_INSERTION_ORDER"
  /// - "FILTER_LINE_ITEM"
  /// - "FILTER_PARTNER_CURRENCY"
  /// - "FILTER_ADVERTISER_CURRENCY"
  /// - "FILTER_ADVERTISER_TIMEZONE"
  /// - "FILTER_LINE_ITEM_TYPE"
  /// - "FILTER_USER_LIST"
  /// - "FILTER_USER_LIST_FIRST_PARTY"
  /// - "FILTER_USER_LIST_THIRD_PARTY"
  /// - "FILTER_TARGETED_USER_LIST"
  /// - "FILTER_DATA_PROVIDER"
  /// - "FILTER_ORDER_ID"
  /// - "FILTER_VIDEO_PLAYER_SIZE"
  /// - "FILTER_VIDEO_DURATION_SECONDS"
  /// - "FILTER_KEYWORD"
  /// - "FILTER_PAGE_CATEGORY"
  /// - "FILTER_CAMPAIGN_DAILY_FREQUENCY"
  /// - "FILTER_LINE_ITEM_DAILY_FREQUENCY"
  /// - "FILTER_LINE_ITEM_LIFETIME_FREQUENCY"
  /// - "FILTER_OS"
  /// - "FILTER_BROWSER"
  /// - "FILTER_CARRIER"
  /// - "FILTER_SITE_LANGUAGE"
  /// - "FILTER_INVENTORY_FORMAT"
  /// - "FILTER_ZIP_CODE"
  /// - "FILTER_VIDEO_RATING_TIER"
  /// - "FILTER_VIDEO_FORMAT_SUPPORT"
  /// - "FILTER_VIDEO_SKIPPABLE_SUPPORT"
  /// - "FILTER_VIDEO_CREATIVE_DURATION"
  /// - "FILTER_PAGE_LAYOUT"
  /// - "FILTER_VIDEO_AD_POSITION_IN_STREAM"
  /// - "FILTER_AGE"
  /// - "FILTER_GENDER"
  /// - "FILTER_QUARTER"
  /// - "FILTER_TRUEVIEW_CONVERSION_TYPE"
  /// - "FILTER_MOBILE_GEO"
  /// - "FILTER_MRAID_SUPPORT"
  /// - "FILTER_ACTIVE_VIEW_EXPECTED_VIEWABILITY"
  /// - "FILTER_VIDEO_CREATIVE_DURATION_SKIPPABLE"
  /// - "FILTER_NIELSEN_COUNTRY_CODE"
  /// - "FILTER_NIELSEN_DEVICE_ID"
  /// - "FILTER_NIELSEN_GENDER"
  /// - "FILTER_NIELSEN_AGE"
  /// - "FILTER_INVENTORY_SOURCE_TYPE"
  /// - "FILTER_CREATIVE_WIDTH"
  /// - "FILTER_CREATIVE_HEIGHT"
  /// - "FILTER_DFP_ORDER_ID"
  /// - "FILTER_TRUEVIEW_AGE"
  /// - "FILTER_TRUEVIEW_GENDER"
  /// - "FILTER_TRUEVIEW_PARENTAL_STATUS"
  /// - "FILTER_TRUEVIEW_REMARKETING_LIST"
  /// - "FILTER_TRUEVIEW_INTEREST"
  /// - "FILTER_TRUEVIEW_AD_GROUP_ID"
  /// - "FILTER_TRUEVIEW_AD_GROUP_AD_ID"
  /// - "FILTER_TRUEVIEW_IAR_LANGUAGE"
  /// - "FILTER_TRUEVIEW_IAR_GENDER"
  /// - "FILTER_TRUEVIEW_IAR_AGE"
  /// - "FILTER_TRUEVIEW_IAR_CATEGORY"
  /// - "FILTER_TRUEVIEW_IAR_COUNTRY"
  /// - "FILTER_TRUEVIEW_IAR_CITY"
  /// - "FILTER_TRUEVIEW_IAR_REGION"
  /// - "FILTER_TRUEVIEW_IAR_ZIPCODE"
  /// - "FILTER_TRUEVIEW_IAR_REMARKETING_LIST"
  /// - "FILTER_TRUEVIEW_IAR_INTEREST"
  /// - "FILTER_TRUEVIEW_IAR_PARENTAL_STATUS"
  /// - "FILTER_TRUEVIEW_IAR_TIME_OF_DAY"
  /// - "FILTER_TRUEVIEW_CUSTOM_AFFINITY"
  /// - "FILTER_TRUEVIEW_CATEGORY"
  /// - "FILTER_TRUEVIEW_KEYWORD"
  /// - "FILTER_TRUEVIEW_PLACEMENT"
  /// - "FILTER_TRUEVIEW_URL"
  /// - "FILTER_TRUEVIEW_COUNTRY"
  /// - "FILTER_TRUEVIEW_REGION"
  /// - "FILTER_TRUEVIEW_CITY"
  /// - "FILTER_TRUEVIEW_DMA"
  /// - "FILTER_TRUEVIEW_ZIPCODE"
  /// - "FILTER_NOT_SUPPORTED"
  /// - "FILTER_MEDIA_PLAN"
  /// - "FILTER_TRUEVIEW_IAR_YOUTUBE_CHANNEL"
  /// - "FILTER_TRUEVIEW_IAR_YOUTUBE_VIDEO"
  /// - "FILTER_SKIPPABLE_SUPPORT"
  /// - "FILTER_COMPANION_CREATIVE_ID"
  /// - "FILTER_BUDGET_SEGMENT_DESCRIPTION"
  /// - "FILTER_FLOODLIGHT_ACTIVITY_ID"
  /// - "FILTER_DEVICE_MODEL"
  /// - "FILTER_DEVICE_MAKE"
  /// - "FILTER_DEVICE_TYPE"
  /// - "FILTER_CREATIVE_ATTRIBUTE"
  /// - "FILTER_INVENTORY_COMMITMENT_TYPE"
  /// - "FILTER_INVENTORY_RATE_TYPE"
  /// - "FILTER_INVENTORY_DELIVERY_METHOD"
  /// - "FILTER_INVENTORY_SOURCE_EXTERNAL_ID"
  /// - "FILTER_AUTHORIZED_SELLER_STATE"
  /// - "FILTER_VIDEO_DURATION_SECONDS_RANGE"
  /// - "FILTER_PARTNER_NAME"
  /// - "FILTER_PARTNER_STATUS"
  /// - "FILTER_ADVERTISER_NAME"
  /// - "FILTER_ADVERTISER_INTEGRATION_CODE"
  /// - "FILTER_ADVERTISER_INTEGRATION_STATUS"
  /// - "FILTER_CARRIER_NAME"
  /// - "FILTER_CHANNEL_NAME"
  /// - "FILTER_CITY_NAME"
  /// - "FILTER_COMPANION_CREATIVE_NAME"
  /// - "FILTER_USER_LIST_FIRST_PARTY_NAME"
  /// - "FILTER_USER_LIST_THIRD_PARTY_NAME"
  /// - "FILTER_NIELSEN_RESTATEMENT_DATE"
  /// - "FILTER_NIELSEN_DATE_RANGE"
  /// - "FILTER_INSERTION_ORDER_NAME"
  /// - "FILTER_REGION_NAME"
  /// - "FILTER_DMA_NAME"
  /// - "FILTER_TRUEVIEW_IAR_REGION_NAME"
  /// - "FILTER_TRUEVIEW_DMA_NAME"
  /// - "FILTER_TRUEVIEW_REGION_NAME"
  /// - "FILTER_ACTIVE_VIEW_CUSTOM_METRIC_ID"
  /// - "FILTER_ACTIVE_VIEW_CUSTOM_METRIC_NAME"
  /// - "FILTER_AD_TYPE"
  /// - "FILTER_ALGORITHM"
  /// - "FILTER_ALGORITHM_ID"
  /// - "FILTER_AMP_PAGE_REQUEST"
  /// - "FILTER_ANONYMOUS_INVENTORY_MODELING"
  /// - "FILTER_APP_URL"
  /// - "FILTER_APP_URL_EXCLUDED"
  /// - "FILTER_ATTRIBUTED_USERLIST"
  /// - "FILTER_ATTRIBUTED_USERLIST_COST"
  /// - "FILTER_ATTRIBUTED_USERLIST_TYPE"
  /// - "FILTER_ATTRIBUTION_MODEL"
  /// - "FILTER_AUDIENCE_LIST"
  /// - "FILTER_AUDIENCE_LIST_COST"
  /// - "FILTER_AUDIENCE_LIST_TYPE"
  /// - "FILTER_AUDIENCE_NAME"
  /// - "FILTER_AUDIENCE_TYPE"
  /// - "FILTER_BILLABLE_OUTCOME"
  /// - "FILTER_BRAND_LIFT_TYPE"
  /// - "FILTER_CHANNEL_TYPE"
  /// - "FILTER_CM_PLACEMENT_ID"
  /// - "FILTER_CONVERSION_SOURCE"
  /// - "FILTER_CONVERSION_SOURCE_ID"
  /// - "FILTER_COUNTRY_ID"
  /// - "FILTER_CREATIVE"
  /// - "FILTER_CREATIVE_ASSET"
  /// - "FILTER_CREATIVE_INTEGRATION_CODE"
  /// - "FILTER_CREATIVE_RENDERED_IN_AMP"
  /// - "FILTER_CREATIVE_SOURCE"
  /// - "FILTER_CREATIVE_STATUS"
  /// - "FILTER_DATA_PROVIDER_NAME"
  /// - "FILTER_DETAILED_DEMOGRAPHICS"
  /// - "FILTER_DETAILED_DEMOGRAPHICS_ID"
  /// - "FILTER_DEVICE"
  /// - "FILTER_GAM_INSERTION_ORDER"
  /// - "FILTER_GAM_LINE_ITEM"
  /// - "FILTER_GAM_LINE_ITEM_ID"
  /// - "FILTER_DIGITAL_CONTENT_LABEL"
  /// - "FILTER_DOMAIN"
  /// - "FILTER_ELIGIBLE_COOKIES_ON_FIRST_PARTY_AUDIENCE_LIST"
  /// - "FILTER_ELIGIBLE_COOKIES_ON_THIRD_PARTY_AUDIENCE_LIST_AND_INTEREST"
  /// - "FILTER_EXCHANGE"
  /// - "FILTER_EXCHANGE_CODE"
  /// - "FILTER_EXTENSION"
  /// - "FILTER_EXTENSION_STATUS"
  /// - "FILTER_EXTENSION_TYPE"
  /// - "FILTER_FIRST_PARTY_AUDIENCE_LIST_COST"
  /// - "FILTER_FIRST_PARTY_AUDIENCE_LIST_TYPE"
  /// - "FILTER_FLOODLIGHT_ACTIVITY"
  /// - "FILTER_FORMAT"
  /// - "FILTER_GMAIL_AGE"
  /// - "FILTER_GMAIL_CITY"
  /// - "FILTER_GMAIL_COUNTRY"
  /// - "FILTER_GMAIL_COUNTRY_NAME"
  /// - "FILTER_GMAIL_DEVICE_TYPE"
  /// - "FILTER_GMAIL_DEVICE_TYPE_NAME"
  /// - "FILTER_GMAIL_GENDER"
  /// - "FILTER_GMAIL_REGION"
  /// - "FILTER_GMAIL_REMARKETING_LIST"
  /// - "FILTER_HOUSEHOLD_INCOME"
  /// - "FILTER_IMPRESSION_COUNTING_METHOD"
  /// - "FILTER_YOUTUBE_PROGRAMMATIC_GUARANTEED_INSERTION_ORDER"
  /// - "FILTER_INSERTION_ORDER_INTEGRATION_CODE"
  /// - "FILTER_INSERTION_ORDER_STATUS"
  /// - "FILTER_INTEREST"
  /// - "FILTER_INVENTORY_SOURCE_GROUP"
  /// - "FILTER_INVENTORY_SOURCE_GROUP_ID"
  /// - "FILTER_INVENTORY_SOURCE_ID"
  /// - "FILTER_INVENTORY_SOURCE_NAME"
  /// - "FILTER_LIFE_EVENT"
  /// - "FILTER_LIFE_EVENTS"
  /// - "FILTER_LINE_ITEM_INTEGRATION_CODE"
  /// - "FILTER_LINE_ITEM_NAME"
  /// - "FILTER_LINE_ITEM_STATUS"
  /// - "FILTER_MATCH_RATIO"
  /// - "FILTER_MEASUREMENT_SOURCE"
  /// - "FILTER_MEDIA_PLAN_NAME"
  /// - "FILTER_PARENTAL_STATUS"
  /// - "FILTER_PLACEMENT_ALL_YOUTUBE_CHANNELS"
  /// - "FILTER_PLATFORM"
  /// - "FILTER_PLAYBACK_METHOD"
  /// - "FILTER_POSITION_IN_CONTENT"
  /// - "FILTER_PUBLISHER_PROPERTY"
  /// - "FILTER_PUBLISHER_PROPERTY_ID"
  /// - "FILTER_PUBLISHER_PROPERTY_SECTION"
  /// - "FILTER_PUBLISHER_PROPERTY_SECTION_ID"
  /// - "FILTER_REFUND_REASON"
  /// - "FILTER_REMARKETING_LIST"
  /// - "FILTER_REWARDED"
  /// - "FILTER_SENSITIVE_CATEGORY"
  /// - "FILTER_SERVED_PIXEL_DENSITY"
  /// - "FILTER_TARGETED_DATA_PROVIDERS"
  /// - "FILTER_THIRD_PARTY_AUDIENCE_LIST_COST"
  /// - "FILTER_THIRD_PARTY_AUDIENCE_LIST_TYPE"
  /// - "FILTER_TRUEVIEW_AD"
  /// - "FILTER_TRUEVIEW_AD_GROUP"
  /// - "FILTER_TRUEVIEW_DETAILED_DEMOGRAPHICS"
  /// - "FILTER_TRUEVIEW_DETAILED_DEMOGRAPHICS_ID"
  /// - "FILTER_TRUEVIEW_HOUSEHOLD_INCOME"
  /// - "FILTER_TRUEVIEW_IAR_COUNTRY_NAME"
  /// - "FILTER_TRUEVIEW_REMARKETING_LIST_NAME"
  /// - "FILTER_VARIANT_ID"
  /// - "FILTER_VARIANT_NAME"
  /// - "FILTER_VARIANT_VERSION"
  /// - "FILTER_VERIFICATION_VIDEO_PLAYER_SIZE"
  /// - "FILTER_VERIFICATION_VIDEO_POSITION"
  /// - "FILTER_VIDEO_COMPANION_CREATIVE_SIZE"
  /// - "FILTER_VIDEO_CONTINUOUS_PLAY"
  /// - "FILTER_VIDEO_DURATION"
  /// - "FILTER_YOUTUBE_ADAPTED_AUDIENCE_LIST"
  /// - "FILTER_YOUTUBE_AD_VIDEO"
  /// - "FILTER_YOUTUBE_AD_VIDEO_ID"
  /// - "FILTER_YOUTUBE_CHANNEL"
  /// - "FILTER_YOUTUBE_PROGRAMMATIC_GUARANTEED_ADVERTISER"
  /// - "FILTER_YOUTUBE_PROGRAMMATIC_GUARANTEED_PARTNER"
  /// - "FILTER_YOUTUBE_VIDEO"
  /// - "FILTER_ZIP_POSTAL_CODE"
  /// - "FILTER_PLACEMENT_NAME_ALL_YOUTUBE_CHANNELS"
  /// - "FILTER_TRUEVIEW_PLACEMENT_ID"
  /// - "FILTER_PATH_PATTERN_ID"
  /// - "FILTER_PATH_EVENT_INDEX"
  /// - "FILTER_EVENT_TYPE"
  /// - "FILTER_CHANNEL_GROUPING"
  /// - "FILTER_OM_SDK_AVAILABLE"
  /// - "FILTER_DATA_SOURCE"
  /// - "FILTER_CM360_PLACEMENT_ID"
  /// - "FILTER_TRUEVIEW_CLICK_TYPE_NAME"
  /// - "FILTER_TRUEVIEW_AD_TYPE_NAME"
  /// - "FILTER_VIDEO_CONTENT_DURATION"
  /// - "FILTER_MATCHED_GENRE_TARGET"
  /// - "FILTER_VIDEO_CONTENT_LIVE_STREAM"
  /// - "FILTER_BUDGET_SEGMENT_TYPE"
  /// - "FILTER_BUDGET_SEGMENT_BUDGET"
  /// - "FILTER_BUDGET_SEGMENT_START_DATE"
  /// - "FILTER_BUDGET_SEGMENT_END_DATE"
  /// - "FILTER_BUDGET_SEGMENT_PACING_PERCENTAGE"
  /// - "FILTER_LINE_ITEM_BUDGET"
  /// - "FILTER_LINE_ITEM_START_DATE"
  /// - "FILTER_LINE_ITEM_END_DATE"
  /// - "FILTER_INSERTION_ORDER_GOAL_TYPE"
  /// - "FILTER_LINE_ITEM_PACING_PERCENTAGE"
  /// - "FILTER_INSERTION_ORDER_GOAL_VALUE"
  /// - "FILTER_OMID_CAPABLE"
  core.String? filter;

  /// Indicates how the filter should be matched to the value.
  /// Possible string values are:
  /// - "UNKNOWN"
  /// - "EXACT"
  /// - "PARTIAL"
  /// - "BEGINS_WITH"
  /// - "WILDCARD_EXPRESSION"
  core.String? match;

  /// Value to filter on.
  core.List<core.String>? values;

  PathQueryOptionsFilter();

  PathQueryOptionsFilter.fromJson(core.Map _json) {
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
    if (_json.containsKey('match')) {
      match = _json['match'] as core.String;
    }
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filter != null) 'filter': filter!,
        if (match != null) 'match': match!,
        if (values != null) 'values': values!,
      };
}

/// Represents a query.
class Query {
  /// Identifies what kind of resource this is.
  ///
  /// Value: the fixed string "doubleclickbidmanager#query".
  core.String? kind;

  /// Query metadata.
  QueryMetadata? metadata;

  /// Query parameters.
  Parameters? params;

  /// Query ID.
  core.String? queryId;

  /// The ending time for the data that is shown in the report.
  ///
  /// Note, reportDataEndTimeMs is required if metadata.dataRange is
  /// CUSTOM_DATES and ignored otherwise.
  core.String? reportDataEndTimeMs;

  /// The starting time for the data that is shown in the report.
  ///
  /// Note, reportDataStartTimeMs is required if metadata.dataRange is
  /// CUSTOM_DATES and ignored otherwise.
  core.String? reportDataStartTimeMs;

  /// Information on how often and when to run a query.
  QuerySchedule? schedule;

  /// Canonical timezone code for report data time.
  ///
  /// Defaults to America/New_York.
  core.String? timezoneCode;

  Query();

  Query.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = QueryMetadata.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('params')) {
      params = Parameters.fromJson(
          _json['params'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('queryId')) {
      queryId = _json['queryId'] as core.String;
    }
    if (_json.containsKey('reportDataEndTimeMs')) {
      reportDataEndTimeMs = _json['reportDataEndTimeMs'] as core.String;
    }
    if (_json.containsKey('reportDataStartTimeMs')) {
      reportDataStartTimeMs = _json['reportDataStartTimeMs'] as core.String;
    }
    if (_json.containsKey('schedule')) {
      schedule = QuerySchedule.fromJson(
          _json['schedule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timezoneCode')) {
      timezoneCode = _json['timezoneCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (params != null) 'params': params!.toJson(),
        if (queryId != null) 'queryId': queryId!,
        if (reportDataEndTimeMs != null)
          'reportDataEndTimeMs': reportDataEndTimeMs!,
        if (reportDataStartTimeMs != null)
          'reportDataStartTimeMs': reportDataStartTimeMs!,
        if (schedule != null) 'schedule': schedule!.toJson(),
        if (timezoneCode != null) 'timezoneCode': timezoneCode!,
      };
}

/// Query metadata.
class QueryMetadata {
  /// Range of report data.
  /// Possible string values are:
  /// - "CUSTOM_DATES"
  /// - "CURRENT_DAY"
  /// - "PREVIOUS_DAY"
  /// - "WEEK_TO_DATE"
  /// - "MONTH_TO_DATE"
  /// - "QUARTER_TO_DATE"
  /// - "YEAR_TO_DATE"
  /// - "PREVIOUS_WEEK"
  /// - "PREVIOUS_HALF_MONTH"
  /// - "PREVIOUS_MONTH"
  /// - "PREVIOUS_QUARTER"
  /// - "PREVIOUS_YEAR"
  /// - "LAST_7_DAYS"
  /// - "LAST_30_DAYS"
  /// - "LAST_90_DAYS"
  /// - "LAST_365_DAYS"
  /// - "ALL_TIME"
  /// - "LAST_14_DAYS"
  /// - "TYPE_NOT_SUPPORTED"
  /// - "LAST_60_DAYS"
  core.String? dataRange;

  /// Format of the generated report.
  /// Possible string values are:
  /// - "CSV"
  /// - "EXCEL_CSV"
  /// - "XLSX"
  core.String? format;

  /// The path to the location in Google Cloud Storage where the latest report
  /// is stored.
  core.String? googleCloudStoragePathForLatestReport;

  /// The path in Google Drive for the latest report.
  core.String? googleDrivePathForLatestReport;

  /// The time when the latest report started to run.
  core.String? latestReportRunTimeMs;

  /// Locale of the generated reports.
  ///
  /// Valid values are cs CZECH de GERMAN en ENGLISH es SPANISH fr FRENCH it
  /// ITALIAN ja JAPANESE ko KOREAN pl POLISH pt-BR BRAZILIAN_PORTUGUESE ru
  /// RUSSIAN tr TURKISH uk UKRAINIAN zh-CN CHINA_CHINESE zh-TW TAIWAN_CHINESE
  /// An locale string not in the list above will generate reports in English.
  core.String? locale;

  /// Number of reports that have been generated for the query.
  core.int? reportCount;

  /// Whether the latest report is currently running.
  core.bool? running;

  /// Whether to send an email notification when a report is ready.
  ///
  /// Default to false.
  core.bool? sendNotification;

  /// List of email addresses which are sent email notifications when the report
  /// is finished.
  ///
  /// Separate from sendNotification.
  core.List<core.String>? shareEmailAddress;

  /// Query title.
  ///
  /// It is used to name the reports generated from this query.
  core.String? title;

  QueryMetadata();

  QueryMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('dataRange')) {
      dataRange = _json['dataRange'] as core.String;
    }
    if (_json.containsKey('format')) {
      format = _json['format'] as core.String;
    }
    if (_json.containsKey('googleCloudStoragePathForLatestReport')) {
      googleCloudStoragePathForLatestReport =
          _json['googleCloudStoragePathForLatestReport'] as core.String;
    }
    if (_json.containsKey('googleDrivePathForLatestReport')) {
      googleDrivePathForLatestReport =
          _json['googleDrivePathForLatestReport'] as core.String;
    }
    if (_json.containsKey('latestReportRunTimeMs')) {
      latestReportRunTimeMs = _json['latestReportRunTimeMs'] as core.String;
    }
    if (_json.containsKey('locale')) {
      locale = _json['locale'] as core.String;
    }
    if (_json.containsKey('reportCount')) {
      reportCount = _json['reportCount'] as core.int;
    }
    if (_json.containsKey('running')) {
      running = _json['running'] as core.bool;
    }
    if (_json.containsKey('sendNotification')) {
      sendNotification = _json['sendNotification'] as core.bool;
    }
    if (_json.containsKey('shareEmailAddress')) {
      shareEmailAddress = (_json['shareEmailAddress'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataRange != null) 'dataRange': dataRange!,
        if (format != null) 'format': format!,
        if (googleCloudStoragePathForLatestReport != null)
          'googleCloudStoragePathForLatestReport':
              googleCloudStoragePathForLatestReport!,
        if (googleDrivePathForLatestReport != null)
          'googleDrivePathForLatestReport': googleDrivePathForLatestReport!,
        if (latestReportRunTimeMs != null)
          'latestReportRunTimeMs': latestReportRunTimeMs!,
        if (locale != null) 'locale': locale!,
        if (reportCount != null) 'reportCount': reportCount!,
        if (running != null) 'running': running!,
        if (sendNotification != null) 'sendNotification': sendNotification!,
        if (shareEmailAddress != null) 'shareEmailAddress': shareEmailAddress!,
        if (title != null) 'title': title!,
      };
}

/// Information on how frequently and when to run a query.
class QuerySchedule {
  /// Datetime to periodically run the query until.
  core.String? endTimeMs;

  /// How often the query is run.
  /// Possible string values are:
  /// - "ONE_TIME"
  /// - "DAILY"
  /// - "WEEKLY"
  /// - "SEMI_MONTHLY"
  /// - "MONTHLY"
  /// - "QUARTERLY"
  /// - "YEARLY"
  core.String? frequency;

  /// Time of day at which a new report will be generated, represented as
  /// minutes past midnight.
  ///
  /// Range is 0 to 1439. Only applies to scheduled reports.
  core.int? nextRunMinuteOfDay;

  /// Canonical timezone code for report generation time.
  ///
  /// Defaults to America/New_York.
  core.String? nextRunTimezoneCode;

  /// When to start running the query.
  ///
  /// Not applicable to `ONE_TIME` frequency.
  core.String? startTimeMs;

  QuerySchedule();

  QuerySchedule.fromJson(core.Map _json) {
    if (_json.containsKey('endTimeMs')) {
      endTimeMs = _json['endTimeMs'] as core.String;
    }
    if (_json.containsKey('frequency')) {
      frequency = _json['frequency'] as core.String;
    }
    if (_json.containsKey('nextRunMinuteOfDay')) {
      nextRunMinuteOfDay = _json['nextRunMinuteOfDay'] as core.int;
    }
    if (_json.containsKey('nextRunTimezoneCode')) {
      nextRunTimezoneCode = _json['nextRunTimezoneCode'] as core.String;
    }
    if (_json.containsKey('startTimeMs')) {
      startTimeMs = _json['startTimeMs'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTimeMs != null) 'endTimeMs': endTimeMs!,
        if (frequency != null) 'frequency': frequency!,
        if (nextRunMinuteOfDay != null)
          'nextRunMinuteOfDay': nextRunMinuteOfDay!,
        if (nextRunTimezoneCode != null)
          'nextRunTimezoneCode': nextRunTimezoneCode!,
        if (startTimeMs != null) 'startTimeMs': startTimeMs!,
      };
}

/// Represents a report.
class Report {
  /// Key used to identify a report.
  ReportKey? key;

  /// Report metadata.
  ReportMetadata? metadata;

  /// Report parameters.
  Parameters? params;

  Report();

  Report.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = ReportKey.fromJson(
          _json['key'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metadata')) {
      metadata = ReportMetadata.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('params')) {
      params = Parameters.fromJson(
          _json['params'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!.toJson(),
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (params != null) 'params': params!.toJson(),
      };
}

/// An explanation of a report failure.
class ReportFailure {
  /// Error code that shows why the report was not created.
  /// Possible string values are:
  /// - "AUTHENTICATION_ERROR"
  /// - "UNAUTHORIZED_API_ACCESS"
  /// - "SERVER_ERROR"
  /// - "VALIDATION_ERROR"
  /// - "REPORTING_FATAL_ERROR"
  /// - "REPORTING_TRANSIENT_ERROR"
  /// - "REPORTING_IMCOMPATIBLE_METRICS"
  /// - "REPORTING_ILLEGAL_FILENAME"
  /// - "REPORTING_QUERY_NOT_FOUND"
  /// - "REPORTING_BUCKET_NOT_FOUND"
  /// - "REPORTING_CREATE_BUCKET_FAILED"
  /// - "REPORTING_DELETE_BUCKET_FAILED"
  /// - "REPORTING_UPDATE_BUCKET_PERMISSION_FAILED"
  /// - "REPORTING_WRITE_BUCKET_OBJECT_FAILED"
  /// - "DEPRECATED_REPORTING_INVALID_QUERY"
  /// - "REPORTING_INVALID_QUERY_TOO_MANY_UNFILTERED_LARGE_GROUP_BYS"
  /// - "REPORTING_INVALID_QUERY_TITLE_MISSING"
  /// - "REPORTING_INVALID_QUERY_MISSING_PARTNER_AND_ADVERTISER_FILTERS"
  core.String? errorCode;

  ReportFailure();

  ReportFailure.fromJson(core.Map _json) {
    if (_json.containsKey('errorCode')) {
      errorCode = _json['errorCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorCode != null) 'errorCode': errorCode!,
      };
}

/// Key used to identify a report.
class ReportKey {
  /// Query ID.
  core.String? queryId;

  /// Report ID.
  core.String? reportId;

  ReportKey();

  ReportKey.fromJson(core.Map _json) {
    if (_json.containsKey('queryId')) {
      queryId = _json['queryId'] as core.String;
    }
    if (_json.containsKey('reportId')) {
      reportId = _json['reportId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (queryId != null) 'queryId': queryId!,
        if (reportId != null) 'reportId': reportId!,
      };
}

/// Report metadata.
class ReportMetadata {
  /// The path to the location in Google Cloud Storage where the report is
  /// stored.
  core.String? googleCloudStoragePath;

  /// The ending time for the data that is shown in the report.
  core.String? reportDataEndTimeMs;

  /// The starting time for the data that is shown in the report.
  core.String? reportDataStartTimeMs;

  /// Report status.
  ReportStatus? status;

  ReportMetadata();

  ReportMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('googleCloudStoragePath')) {
      googleCloudStoragePath = _json['googleCloudStoragePath'] as core.String;
    }
    if (_json.containsKey('reportDataEndTimeMs')) {
      reportDataEndTimeMs = _json['reportDataEndTimeMs'] as core.String;
    }
    if (_json.containsKey('reportDataStartTimeMs')) {
      reportDataStartTimeMs = _json['reportDataStartTimeMs'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = ReportStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (googleCloudStoragePath != null)
          'googleCloudStoragePath': googleCloudStoragePath!,
        if (reportDataEndTimeMs != null)
          'reportDataEndTimeMs': reportDataEndTimeMs!,
        if (reportDataStartTimeMs != null)
          'reportDataStartTimeMs': reportDataStartTimeMs!,
        if (status != null) 'status': status!.toJson(),
      };
}

/// Report status.
class ReportStatus {
  /// If the report failed, this records the cause.
  ReportFailure? failure;

  /// The time when this report either completed successfully or failed.
  core.String? finishTimeMs;

  /// The file type of the report.
  /// Possible string values are:
  /// - "CSV"
  /// - "EXCEL_CSV"
  /// - "XLSX"
  core.String? format;

  /// The state of the report.
  /// Possible string values are:
  /// - "RUNNING"
  /// - "DONE"
  /// - "FAILED"
  core.String? state;

  ReportStatus();

  ReportStatus.fromJson(core.Map _json) {
    if (_json.containsKey('failure')) {
      failure = ReportFailure.fromJson(
          _json['failure'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('finishTimeMs')) {
      finishTimeMs = _json['finishTimeMs'] as core.String;
    }
    if (_json.containsKey('format')) {
      format = _json['format'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (failure != null) 'failure': failure!.toJson(),
        if (finishTimeMs != null) 'finishTimeMs': finishTimeMs!,
        if (format != null) 'format': format!,
        if (state != null) 'state': state!,
      };
}

/// A Rule defines a name, and a boolean expression in \[conjunctive normal
/// form\](http: //mathworld.wolfram.com/ConjunctiveNormalForm.html){.external}
/// that can be // applied to a path event to determine if that name should be
/// applied.
class Rule {
  core.List<DisjunctiveMatchStatement>? disjunctiveMatchStatements;

  /// Rule name.
  core.String? name;

  Rule();

  Rule.fromJson(core.Map _json) {
    if (_json.containsKey('disjunctiveMatchStatements')) {
      disjunctiveMatchStatements =
          (_json['disjunctiveMatchStatements'] as core.List)
              .map<DisjunctiveMatchStatement>((value) =>
                  DisjunctiveMatchStatement.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disjunctiveMatchStatements != null)
          'disjunctiveMatchStatements': disjunctiveMatchStatements!
              .map((value) => value.toJson())
              .toList(),
        if (name != null) 'name': name!,
      };
}

/// Request to run a stored query to generate a report.
class RunQueryRequest {
  /// Report data range used to generate the report.
  /// Possible string values are:
  /// - "CUSTOM_DATES"
  /// - "CURRENT_DAY"
  /// - "PREVIOUS_DAY"
  /// - "WEEK_TO_DATE"
  /// - "MONTH_TO_DATE"
  /// - "QUARTER_TO_DATE"
  /// - "YEAR_TO_DATE"
  /// - "PREVIOUS_WEEK"
  /// - "PREVIOUS_HALF_MONTH"
  /// - "PREVIOUS_MONTH"
  /// - "PREVIOUS_QUARTER"
  /// - "PREVIOUS_YEAR"
  /// - "LAST_7_DAYS"
  /// - "LAST_30_DAYS"
  /// - "LAST_90_DAYS"
  /// - "LAST_365_DAYS"
  /// - "ALL_TIME"
  /// - "LAST_14_DAYS"
  /// - "TYPE_NOT_SUPPORTED"
  /// - "LAST_60_DAYS"
  core.String? dataRange;

  /// The ending time for the data that is shown in the report.
  ///
  /// Note, reportDataEndTimeMs is required if dataRange is CUSTOM_DATES and
  /// ignored otherwise.
  core.String? reportDataEndTimeMs;

  /// The starting time for the data that is shown in the report.
  ///
  /// Note, reportDataStartTimeMs is required if dataRange is CUSTOM_DATES and
  /// ignored otherwise.
  core.String? reportDataStartTimeMs;

  /// Canonical timezone code for report data time.
  ///
  /// Defaults to America/New_York.
  core.String? timezoneCode;

  RunQueryRequest();

  RunQueryRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataRange')) {
      dataRange = _json['dataRange'] as core.String;
    }
    if (_json.containsKey('reportDataEndTimeMs')) {
      reportDataEndTimeMs = _json['reportDataEndTimeMs'] as core.String;
    }
    if (_json.containsKey('reportDataStartTimeMs')) {
      reportDataStartTimeMs = _json['reportDataStartTimeMs'] as core.String;
    }
    if (_json.containsKey('timezoneCode')) {
      timezoneCode = _json['timezoneCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataRange != null) 'dataRange': dataRange!,
        if (reportDataEndTimeMs != null)
          'reportDataEndTimeMs': reportDataEndTimeMs!,
        if (reportDataStartTimeMs != null)
          'reportDataStartTimeMs': reportDataStartTimeMs!,
        if (timezoneCode != null) 'timezoneCode': timezoneCode!,
      };
}

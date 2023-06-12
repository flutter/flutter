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

/// Real-time Bidding API - v1
///
/// Allows external bidders to manage their RTB integration with Google. This
/// includes managing bidder endpoints, QPS quotas, configuring what ad
/// inventory to receive via pretargeting, submitting creatives for
/// verification, and accessing creative metadata such as approval status.
///
/// For more information, see
/// <https://developers.google.com/authorized-buyers/apis/realtimebidding/reference/rest/>
///
/// Create an instance of [RealTimeBiddingApi] to access these resources:
///
/// - [BiddersResource]
///   - [BiddersCreativesResource]
///   - [BiddersEndpointsResource]
///   - [BiddersPretargetingConfigsResource]
/// - [BuyersResource]
///   - [BuyersCreativesResource]
///   - [BuyersUserListsResource]
library realtimebidding.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Allows external bidders to manage their RTB integration with Google.
///
/// This includes managing bidder endpoints, QPS quotas, configuring what ad
/// inventory to receive via pretargeting, submitting creatives for
/// verification, and accessing creative metadata such as approval status.
class RealTimeBiddingApi {
  /// See, create, edit, and delete your Authorized Buyers and Open Bidding
  /// account entities
  static const realtimeBiddingScope =
      'https://www.googleapis.com/auth/realtime-bidding';

  final commons.ApiRequester _requester;

  BiddersResource get bidders => BiddersResource(_requester);
  BuyersResource get buyers => BuyersResource(_requester);

  RealTimeBiddingApi(http.Client client,
      {core.String rootUrl = 'https://realtimebidding.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class BiddersResource {
  final commons.ApiRequester _requester;

  BiddersCreativesResource get creatives =>
      BiddersCreativesResource(_requester);
  BiddersEndpointsResource get endpoints =>
      BiddersEndpointsResource(_requester);
  BiddersPretargetingConfigsResource get pretargetingConfigs =>
      BiddersPretargetingConfigsResource(_requester);

  BiddersResource(commons.ApiRequester client) : _requester = client;

  /// Gets a bidder account by its name.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the bidder to get. Format:
  /// `bidders/{bidderAccountId}`
  /// Value must have pattern `^bidders/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Bidder].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Bidder> get(
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
    return Bidder.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the bidder accounts that belong to the caller.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - The maximum number of bidders to return. If unspecified, at
  /// most 100 bidders will be returned. The maximum value is 500; values above
  /// 500 will be coerced to 500.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. This value is received from a previous `ListBidders` call in
  /// ListBiddersResponse.nextPageToken.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListBiddersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListBiddersResponse> list({
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/bidders';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListBiddersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class BiddersCreativesResource {
  final commons.ApiRequester _requester;

  BiddersCreativesResource(commons.ApiRequester client) : _requester = client;

  /// Lists creatives.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the parent buyer that owns the creatives. The
  /// pattern for this resource is either `buyers/{buyerAccountId}` or
  /// `bidders/{bidderAccountId}`. For `buyers/{buyerAccountId}`, the
  /// `buyerAccountId` can be one of the following: 1. The ID of the buyer that
  /// is accessing their own creatives. 2. The ID of the child seat buyer under
  /// a bidder account. So for listing creatives pertaining to the child seat
  /// buyer (`456`) under bidder account (`123`), you would use the pattern:
  /// `buyers/456`. 3. The ID of the bidder itself. So for listing creatives
  /// pertaining to bidder (`123`), you would use `buyers/123`. If you want to
  /// access all creatives pertaining to both the bidder and all of its child
  /// seat accounts, you would use `bidders/{bidderAccountId}`, e.g., for all
  /// creatives pertaining to bidder (`123`), use `bidders/123`.
  /// Value must have pattern `^bidders/\[^/\]+$`.
  ///
  /// [filter] - Query string to filter creatives. If no filter is specified,
  /// all active creatives will be returned. Example: 'accountId=12345 AND
  /// (dealsStatus:DISAPPROVED AND disapprovalReason:UNACCEPTABLE_CONTENT) OR
  /// declaredAttributes:IS_COOKIE_TARGETED'
  ///
  /// [pageSize] - Requested page size. The server may return fewer creatives
  /// than requested (due to timeout constraint) even if more are available via
  /// another call. If unspecified, server will pick an appropriate default.
  /// Acceptable values are 1 to 1000, inclusive.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of
  /// ListCreativesResponse.nextPageToken returned from the previous call to the
  /// 'ListCreatives' method.
  ///
  /// [view] - Controls the amount of information included in the response. By
  /// default only creativeServingDecision is included. To retrieve the entire
  /// creative resource (including the declared fields and the creative content)
  /// specify the view as "FULL".
  /// Possible string values are:
  /// - "CREATIVE_VIEW_UNSPECIFIED" : Not specified, equivalent to
  /// SERVING_DECISION_ONLY.
  /// - "SERVING_DECISION_ONLY" : Only creativeServingDecision is included in
  /// the response.
  /// - "FULL" : The entire creative resource (including the declared fields and
  /// the creative content) is included in the response.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListCreativesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListCreativesResponse> list(
    core.String parent, {
    core.String? filter,
    core.int? pageSize,
    core.String? pageToken,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/creatives';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListCreativesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Watches all creatives pertaining to a bidder.
  ///
  /// It is sufficient to invoke this endpoint once per bidder. A Pub/Sub topic
  /// will be created and notifications will be pushed to the topic when any of
  /// the bidder's creatives change status. All of the bidder's service accounts
  /// will have access to read from the topic. Subsequent invocations of this
  /// method will return the existing Pub/Sub configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. To watch all creatives pertaining to the bidder and
  /// all its child seat accounts, the bidder must follow the pattern
  /// `bidders/{bidderAccountId}`.
  /// Value must have pattern `^bidders/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [WatchCreativesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<WatchCreativesResponse> watch(
    WatchCreativesRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/creatives:watch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return WatchCreativesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class BiddersEndpointsResource {
  final commons.ApiRequester _requester;

  BiddersEndpointsResource(commons.ApiRequester client) : _requester = client;

  /// Gets a bidder endpoint by its name.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the bidder endpoint to get. Format:
  /// `bidders/{bidderAccountId}/endpoints/{endpointId}`
  /// Value must have pattern `^bidders/\[^/\]+/endpoints/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Endpoint].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Endpoint> get(
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
    return Endpoint.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the bidder's endpoints.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the bidder whose endpoints will be listed.
  /// Format: `bidders/{bidderAccountId}`
  /// Value must have pattern `^bidders/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of endpoints to return. If unspecified, at
  /// most 100 endpoints will be returned. The maximum value is 500; values
  /// above 500 will be coerced to 500.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. This value is received from a previous `ListEndpoints` call in
  /// ListEndpointsResponse.nextPageToken.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListEndpointsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListEndpointsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/endpoints';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListEndpointsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class BiddersPretargetingConfigsResource {
  final commons.ApiRequester _requester;

  BiddersPretargetingConfigsResource(commons.ApiRequester client)
      : _requester = client;

  /// Activates a pretargeting configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the pretargeting configuration. Format:
  /// bidders/{bidderAccountId}/pretargetingConfig/{configId}
  /// Value must have pattern `^bidders/\[^/\]+/pretargetingConfigs/\[^/\]+$`.
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
  async.Future<PretargetingConfig> activate(
    ActivatePretargetingConfigRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':activate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Adds targeted apps to the pretargeting configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [pretargetingConfig] - Required. The name of the pretargeting
  /// configuration. Format:
  /// bidders/{bidderAccountId}/pretargetingConfig/{configId}
  /// Value must have pattern `^bidders/\[^/\]+/pretargetingConfigs/\[^/\]+$`.
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
  async.Future<PretargetingConfig> addTargetedApps(
    AddTargetedAppsRequest request,
    core.String pretargetingConfig, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$pretargetingConfig') + ':addTargetedApps';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Adds targeted publishers to the pretargeting config.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [pretargetingConfig] - Required. The name of the pretargeting
  /// configuration. Format:
  /// bidders/{bidderAccountId}/pretargetingConfig/{configId}
  /// Value must have pattern `^bidders/\[^/\]+/pretargetingConfigs/\[^/\]+$`.
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
  async.Future<PretargetingConfig> addTargetedPublishers(
    AddTargetedPublishersRequest request,
    core.String pretargetingConfig, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$pretargetingConfig') +
        ':addTargetedPublishers';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Adds targeted sites to the pretargeting configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [pretargetingConfig] - Required. The name of the pretargeting
  /// configuration. Format:
  /// bidders/{bidderAccountId}/pretargetingConfig/{configId}
  /// Value must have pattern `^bidders/\[^/\]+/pretargetingConfigs/\[^/\]+$`.
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
  async.Future<PretargetingConfig> addTargetedSites(
    AddTargetedSitesRequest request,
    core.String pretargetingConfig, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$pretargetingConfig') +
        ':addTargetedSites';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a pretargeting configuration.
  ///
  /// A pretargeting configuration's state (PretargetingConfig.state) is active
  /// upon creation, and it will start to affect traffic shortly after. A bidder
  /// may create a maximum of 10 pretargeting configurations. Attempts to exceed
  /// this maximum results in a 400 bad request error.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the bidder to create the pretargeting
  /// configuration for. Format: bidders/{bidderAccountId}
  /// Value must have pattern `^bidders/\[^/\]+$`.
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
  async.Future<PretargetingConfig> create(
    PretargetingConfig request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/pretargetingConfigs';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a pretargeting configuration.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the pretargeting configuration to delete.
  /// Format: bidders/{bidderAccountId}/pretargetingConfig/{configId}
  /// Value must have pattern `^bidders/\[^/\]+/pretargetingConfigs/\[^/\]+$`.
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

  /// Gets a pretargeting configuration.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the pretargeting configuration to get. Format:
  /// bidders/{bidderAccountId}/pretargetingConfig/{configId}
  /// Value must have pattern `^bidders/\[^/\]+/pretargetingConfigs/\[^/\]+$`.
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
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all pretargeting configurations for a single bidder.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the bidder whose pretargeting configurations
  /// will be listed. Format: bidders/{bidderAccountId}
  /// Value must have pattern `^bidders/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of pretargeting configurations to return.
  /// If unspecified, at most 10 pretargeting configurations will be returned.
  /// The maximum value is 100; values above 100 will be coerced to 100.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. This value is received from a previous `ListPretargetingConfigs`
  /// call in ListPretargetingConfigsResponse.nextPageToken.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListPretargetingConfigsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListPretargetingConfigsResponse> list(
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

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/pretargetingConfigs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListPretargetingConfigsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a pretargeting configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only. Name of the pretargeting configuration that must
  /// follow the pattern
  /// `bidders/{bidder_account_id}/pretargetingConfigs/{config_id}`
  /// Value must have pattern `^bidders/\[^/\]+/pretargetingConfigs/\[^/\]+$`.
  ///
  /// [updateMask] - Field mask to use for partial in-place updates.
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
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Removes targeted apps from the pretargeting configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [pretargetingConfig] - Required. The name of the pretargeting
  /// configuration. Format:
  /// bidders/{bidderAccountId}/pretargetingConfig/{configId}
  /// Value must have pattern `^bidders/\[^/\]+/pretargetingConfigs/\[^/\]+$`.
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
  async.Future<PretargetingConfig> removeTargetedApps(
    RemoveTargetedAppsRequest request,
    core.String pretargetingConfig, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$pretargetingConfig') +
        ':removeTargetedApps';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Removes targeted publishers from the pretargeting config.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [pretargetingConfig] - Required. The name of the pretargeting
  /// configuration. Format:
  /// bidders/{bidderAccountId}/pretargetingConfig/{configId}
  /// Value must have pattern `^bidders/\[^/\]+/pretargetingConfigs/\[^/\]+$`.
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
  async.Future<PretargetingConfig> removeTargetedPublishers(
    RemoveTargetedPublishersRequest request,
    core.String pretargetingConfig, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$pretargetingConfig') +
        ':removeTargetedPublishers';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Removes targeted sites from the pretargeting configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [pretargetingConfig] - Required. The name of the pretargeting
  /// configuration. Format:
  /// bidders/{bidderAccountId}/pretargetingConfig/{configId}
  /// Value must have pattern `^bidders/\[^/\]+/pretargetingConfigs/\[^/\]+$`.
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
  async.Future<PretargetingConfig> removeTargetedSites(
    RemoveTargetedSitesRequest request,
    core.String pretargetingConfig, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$pretargetingConfig') +
        ':removeTargetedSites';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Suspends a pretargeting configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the pretargeting configuration. Format:
  /// bidders/{bidderAccountId}/pretargetingConfig/{configId}
  /// Value must have pattern `^bidders/\[^/\]+/pretargetingConfigs/\[^/\]+$`.
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
  async.Future<PretargetingConfig> suspend(
    SuspendPretargetingConfigRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':suspend';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PretargetingConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class BuyersResource {
  final commons.ApiRequester _requester;

  BuyersCreativesResource get creatives => BuyersCreativesResource(_requester);
  BuyersUserListsResource get userLists => BuyersUserListsResource(_requester);

  BuyersResource(commons.ApiRequester client) : _requester = client;

  /// Gets a buyer account by its name.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the buyer to get. Format: `buyers/{buyerId}`
  /// Value must have pattern `^buyers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Buyer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Buyer> get(
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
    return Buyer.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets remarketing tag for a buyer.
  ///
  /// A remarketing tag is a piece of JavaScript code that can be placed on a
  /// web page. When a user visits a page containing a remarketing tag, Google
  /// adds the user to a user list.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. To fetch remarketing tag for an account, name must
  /// follow the pattern `buyers/{accountId}` where `{accountId}` represents ID
  /// of a buyer that owns the remarketing tag. For a bidder accessing
  /// remarketing tag on behalf of a child seat buyer, `{accountId}` should
  /// represent the ID of the child seat buyer. To fetch remarketing tag for a
  /// specific user list, name must follow the pattern
  /// `buyers/{accountId}/userLists/{userListId}`. See UserList.name.
  /// Value must have pattern `^buyers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetRemarketingTagResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetRemarketingTagResponse> getRemarketingTag(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':getRemarketingTag';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetRemarketingTagResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all buyer account information the calling buyer user or service
  /// account is permissioned to manage.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - The maximum number of buyers to return. If unspecified, at
  /// most 100 buyers will be returned. The maximum value is 500; values above
  /// 500 will be coerced to 500.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. This value is received from a previous `ListBuyers` call in
  /// ListBuyersResponse.nextPageToken.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListBuyersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListBuyersResponse> list({
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/buyers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListBuyersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class BuyersCreativesResource {
  final commons.ApiRequester _requester;

  BuyersCreativesResource(commons.ApiRequester client) : _requester = client;

  /// Creates a creative.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the parent buyer that the new creative
  /// belongs to that must follow the pattern `buyers/{buyerAccountId}`, where
  /// `{buyerAccountId}` represents the account ID of the buyer who owns a
  /// creative. For a bidder accessing creatives on behalf of a child seat
  /// buyer, `{buyerAccountId}` should represent the account ID of the child
  /// seat buyer.
  /// Value must have pattern `^buyers/\[^/\]+$`.
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
  async.Future<Creative> create(
    Creative request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/creatives';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Creative.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a creative.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the creative to retrieve. See creative.name.
  /// Value must have pattern `^buyers/\[^/\]+/creatives/\[^/\]+$`.
  ///
  /// [view] - Controls the amount of information included in the response. By
  /// default only creativeServingDecision is included. To retrieve the entire
  /// creative resource (including the declared fields and the creative content)
  /// specify the view as "FULL".
  /// Possible string values are:
  /// - "CREATIVE_VIEW_UNSPECIFIED" : Not specified, equivalent to
  /// SERVING_DECISION_ONLY.
  /// - "SERVING_DECISION_ONLY" : Only creativeServingDecision is included in
  /// the response.
  /// - "FULL" : The entire creative resource (including the declared fields and
  /// the creative content) is included in the response.
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
    core.String name, {
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Creative.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists creatives.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the parent buyer that owns the creatives. The
  /// pattern for this resource is either `buyers/{buyerAccountId}` or
  /// `bidders/{bidderAccountId}`. For `buyers/{buyerAccountId}`, the
  /// `buyerAccountId` can be one of the following: 1. The ID of the buyer that
  /// is accessing their own creatives. 2. The ID of the child seat buyer under
  /// a bidder account. So for listing creatives pertaining to the child seat
  /// buyer (`456`) under bidder account (`123`), you would use the pattern:
  /// `buyers/456`. 3. The ID of the bidder itself. So for listing creatives
  /// pertaining to bidder (`123`), you would use `buyers/123`. If you want to
  /// access all creatives pertaining to both the bidder and all of its child
  /// seat accounts, you would use `bidders/{bidderAccountId}`, e.g., for all
  /// creatives pertaining to bidder (`123`), use `bidders/123`.
  /// Value must have pattern `^buyers/\[^/\]+$`.
  ///
  /// [filter] - Query string to filter creatives. If no filter is specified,
  /// all active creatives will be returned. Example: 'accountId=12345 AND
  /// (dealsStatus:DISAPPROVED AND disapprovalReason:UNACCEPTABLE_CONTENT) OR
  /// declaredAttributes:IS_COOKIE_TARGETED'
  ///
  /// [pageSize] - Requested page size. The server may return fewer creatives
  /// than requested (due to timeout constraint) even if more are available via
  /// another call. If unspecified, server will pick an appropriate default.
  /// Acceptable values are 1 to 1000, inclusive.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of
  /// ListCreativesResponse.nextPageToken returned from the previous call to the
  /// 'ListCreatives' method.
  ///
  /// [view] - Controls the amount of information included in the response. By
  /// default only creativeServingDecision is included. To retrieve the entire
  /// creative resource (including the declared fields and the creative content)
  /// specify the view as "FULL".
  /// Possible string values are:
  /// - "CREATIVE_VIEW_UNSPECIFIED" : Not specified, equivalent to
  /// SERVING_DECISION_ONLY.
  /// - "SERVING_DECISION_ONLY" : Only creativeServingDecision is included in
  /// the response.
  /// - "FULL" : The entire creative resource (including the declared fields and
  /// the creative content) is included in the response.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListCreativesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListCreativesResponse> list(
    core.String parent, {
    core.String? filter,
    core.int? pageSize,
    core.String? pageToken,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/creatives';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListCreativesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a creative.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only. Name of the creative. Follows the pattern
  /// `buyers/{buyer}/creatives/{creative}`, where `{buyer}` represents the
  /// account ID of the buyer who owns the creative, and `{creative}` is the
  /// buyer-specific creative ID that references this creative in the bid
  /// response.
  /// Value must have pattern `^buyers/\[^/\]+/creatives/\[^/\]+$`.
  ///
  /// [updateMask] - Field mask to use for partial in-place updates.
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
  async.Future<Creative> patch(
    Creative request,
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
    return Creative.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class BuyersUserListsResource {
  final commons.ApiRequester _requester;

  BuyersUserListsResource(commons.ApiRequester client) : _requester = client;

  /// Change the status of a user list to CLOSED.
  ///
  /// This prevents new users from being added to the user list.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the user list to close. See UserList.name
  /// Value must have pattern `^buyers/\[^/\]+/userLists/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserList> close(
    CloseUserListRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':close';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return UserList.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Create a new user list.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the parent buyer of the user list to be
  /// retrieved that must follow the pattern `buyers/{buyerAccountId}`, where
  /// `{buyerAccountId}` represents the account ID of the buyer who owns user
  /// lists. For a bidder accessing user lists on behalf of a child seat buyer ,
  /// `{buyerAccountId}` should represent the account ID of the child seat
  /// buyer.
  /// Value must have pattern `^buyers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserList> create(
    UserList request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/userLists';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return UserList.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a user list by its name.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the user list to be retrieved. See
  /// UserList.name.
  /// Value must have pattern `^buyers/\[^/\]+/userLists/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserList> get(
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
    return UserList.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets remarketing tag for a buyer.
  ///
  /// A remarketing tag is a piece of JavaScript code that can be placed on a
  /// web page. When a user visits a page containing a remarketing tag, Google
  /// adds the user to a user list.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. To fetch remarketing tag for an account, name must
  /// follow the pattern `buyers/{accountId}` where `{accountId}` represents ID
  /// of a buyer that owns the remarketing tag. For a bidder accessing
  /// remarketing tag on behalf of a child seat buyer, `{accountId}` should
  /// represent the ID of the child seat buyer. To fetch remarketing tag for a
  /// specific user list, name must follow the pattern
  /// `buyers/{accountId}/userLists/{userListId}`. See UserList.name.
  /// Value must have pattern `^buyers/\[^/\]+/userLists/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetRemarketingTagResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetRemarketingTagResponse> getRemarketingTag(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':getRemarketingTag';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetRemarketingTagResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the user lists visible to the current user.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the parent buyer for the user lists to be
  /// returned that must follow the pattern `buyers/{buyerAccountId}`, where
  /// `{buyerAccountId}` represents the account ID of the buyer who owns user
  /// lists. For a bidder accessing user lists on behalf of a child seat buyer ,
  /// `{buyerAccountId}` should represent the account ID of the child seat
  /// buyer.
  /// Value must have pattern `^buyers/\[^/\]+$`.
  ///
  /// [pageSize] - The number of results to return per page.
  ///
  /// [pageToken] - Continuation page token (as received from a previous
  /// response).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListUserListsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListUserListsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/userLists';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListUserListsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Change the status of a user list to OPEN.
  ///
  /// This allows new users to be added to the user list.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the user list to open. See UserList.name
  /// Value must have pattern `^buyers/\[^/\]+/userLists/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserList> open(
    OpenUserListRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':open';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return UserList.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Update the given user list.
  ///
  /// Only user lists with URLRestrictions can be updated.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only. Name of the user list that must follow the pattern
  /// `buyers/{buyer}/userLists/{user_list}`, where `{buyer}` represents the
  /// account ID of the buyer who owns the user list. For a bidder accessing
  /// user lists on behalf of a child seat buyer, `{buyer}` represents the
  /// account ID of the child seat buyer. `{user_list}` is an int64 identifier
  /// assigned by Google to uniquely identify a user list.
  /// Value must have pattern `^buyers/\[^/\]+/userLists/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UserList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UserList> update(
    UserList request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return UserList.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// A request to activate a pretargeting configuration.
///
/// Sets the configuration's state to ACTIVE.
class ActivatePretargetingConfigRequest {
  ActivatePretargetingConfigRequest();

  ActivatePretargetingConfigRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The list of detected Ad Technology Providers for this creative.
///
/// Bids placed for inventory that will serve to EEA or UK users are expected to
/// comply with GDPR requirements. You must ensure that the creatives used in
/// such bids should contain only user consented ad technology providers as
/// indicated in the bid request. Google reserves the right to filter
/// non-compliant bids. User consented ad technology providers can be found in
/// the
/// [Google Protocol](https://developers.google.com/authorized-buyers/rtb/downloads/realtime-bidding-proto)
/// with the `BidRequest.adslot.consented_providers_settings` field, and can be
/// found as an
/// [OpenRTB extension](https://developers.google.com/authorized-buyers/rtb/downloads/openrtb-adx-proto)
/// with the `BidRequest.user.ext.consented_providers_settings` and
/// `BidRequest.user.ext.consent` fields. See
/// https://support.google.com/authorizedbuyers/answer/9789378 for additional
/// information about the Google TCF v2 integration.
class AdTechnologyProviders {
  /// The detected IAB Global Vendor List (GVL) IDs for this creative.
  ///
  /// See the IAB Global Vendor List at
  /// https://vendorlist.consensu.org/v2/vendor-list.json for details about the
  /// vendors.
  core.List<core.String>? detectedGvlIds;

  /// The detected \[Google Ad Tech Providers
  /// (ATP)\](https://support.google.com/admanager/answer/9012903) for this
  /// creative.
  ///
  /// See https://storage.googleapis.com/adx-rtb-dictionaries/providers.csv for
  /// mapping of provider ID to provided name, a privacy policy URL, and a list
  /// of domains which can be attributed to the provider.
  core.List<core.String>? detectedProviderIds;

  /// Domains of detected unidentified ad technology providers (if any).
  ///
  /// You must ensure that the creatives used in bids placed for inventory that
  /// will serve to EEA or UK users does not contain unidentified ad technology
  /// providers. Google reserves the right to filter non-compliant bids.
  core.List<core.String>? unidentifiedProviderDomains;

  AdTechnologyProviders();

  AdTechnologyProviders.fromJson(core.Map _json) {
    if (_json.containsKey('detectedGvlIds')) {
      detectedGvlIds = (_json['detectedGvlIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('detectedProviderIds')) {
      detectedProviderIds = (_json['detectedProviderIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('unidentifiedProviderDomains')) {
      unidentifiedProviderDomains =
          (_json['unidentifiedProviderDomains'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (detectedGvlIds != null) 'detectedGvlIds': detectedGvlIds!,
        if (detectedProviderIds != null)
          'detectedProviderIds': detectedProviderIds!,
        if (unidentifiedProviderDomains != null)
          'unidentifiedProviderDomains': unidentifiedProviderDomains!,
      };
}

/// A request to start targeting the provided app IDs in a specific pretargeting
/// configuration.
///
/// The pretargeting configuration itself specifies how these apps are targeted.
/// in PretargetingConfig.appTargeting.mobileAppTargeting.
class AddTargetedAppsRequest {
  /// A list of app IDs to target in the pretargeting configuration.
  ///
  /// These values will be added to the list of targeted app IDs in
  /// PretargetingConfig.appTargeting.mobileAppTargeting.values.
  core.List<core.String>? appIds;

  /// The targeting mode that should be applied to the list of app IDs.
  ///
  /// If there are existing targeted app IDs, must be equal to the existing
  /// PretargetingConfig.appTargeting.mobileAppTargeting.targetingMode or a 400
  /// bad request error will be returned.
  ///
  /// Required.
  /// Possible string values are:
  /// - "TARGETING_MODE_UNSPECIFIED" : Placeholder for undefined targeting mode.
  /// - "INCLUSIVE" : The inclusive list type. Inventory must match an item in
  /// this list to be targeted.
  /// - "EXCLUSIVE" : The exclusive list type. Inventory must not match any item
  /// in this list to be targeted.
  core.String? targetingMode;

  AddTargetedAppsRequest();

  AddTargetedAppsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('appIds')) {
      appIds = (_json['appIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('targetingMode')) {
      targetingMode = _json['targetingMode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appIds != null) 'appIds': appIds!,
        if (targetingMode != null) 'targetingMode': targetingMode!,
      };
}

/// A request to start targeting the provided publishers in a specific
/// pretargeting configuration.
///
/// The pretargeting configuration itself specifies how these publishers are
/// targeted in PretargetingConfig.publisherTargeting.
class AddTargetedPublishersRequest {
  /// A list of publisher IDs to target in the pretargeting configuration.
  ///
  /// These values will be added to the list of targeted publisher IDs in
  /// PretargetingConfig.publisherTargeting.values. Publishers are identified by
  /// their publisher ID from ads.txt / app-ads.txt. See
  /// https://iabtechlab.com/ads-txt/ and https://iabtechlab.com/app-ads-txt/
  /// for more details.
  core.List<core.String>? publisherIds;

  /// The targeting mode that should be applied to the list of publisher IDs.
  ///
  /// If are existing publisher IDs, must be equal to the existing
  /// PretargetingConfig.publisherTargeting.targetingMode or a 400 bad request
  /// error will be returned.
  ///
  /// Required.
  /// Possible string values are:
  /// - "TARGETING_MODE_UNSPECIFIED" : Placeholder for undefined targeting mode.
  /// - "INCLUSIVE" : The inclusive list type. Inventory must match an item in
  /// this list to be targeted.
  /// - "EXCLUSIVE" : The exclusive list type. Inventory must not match any item
  /// in this list to be targeted.
  core.String? targetingMode;

  AddTargetedPublishersRequest();

  AddTargetedPublishersRequest.fromJson(core.Map _json) {
    if (_json.containsKey('publisherIds')) {
      publisherIds = (_json['publisherIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('targetingMode')) {
      targetingMode = _json['targetingMode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (publisherIds != null) 'publisherIds': publisherIds!,
        if (targetingMode != null) 'targetingMode': targetingMode!,
      };
}

/// A request to start targeting the provided sites in a specific pretargeting
/// configuration.
///
/// The pretargeting configuration itself specifies how these sites are targeted
/// in PretargetingConfig.webTargeting.
class AddTargetedSitesRequest {
  /// A list of site URLs to target in the pretargeting configuration.
  ///
  /// These values will be added to the list of targeted URLs in
  /// PretargetingConfig.webTargeting.values.
  core.List<core.String>? sites;

  /// The targeting mode that should be applied to the list of site URLs.
  ///
  /// If there are existing targeted sites, must be equal to the existing
  /// PretargetingConfig.webTargeting.targetingMode or a 400 bad request error
  /// will be returned.
  ///
  /// Required.
  /// Possible string values are:
  /// - "TARGETING_MODE_UNSPECIFIED" : Placeholder for undefined targeting mode.
  /// - "INCLUSIVE" : The inclusive list type. Inventory must match an item in
  /// this list to be targeted.
  /// - "EXCLUSIVE" : The exclusive list type. Inventory must not match any item
  /// in this list to be targeted.
  core.String? targetingMode;

  AddTargetedSitesRequest();

  AddTargetedSitesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('sites')) {
      sites = (_json['sites'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('targetingMode')) {
      targetingMode = _json['targetingMode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sites != null) 'sites': sites!,
        if (targetingMode != null) 'targetingMode': targetingMode!,
      };
}

/// Detected advertiser and brand information.
class AdvertiserAndBrand {
  /// See https://storage.googleapis.com/adx-rtb-dictionaries/advertisers.txt
  /// for the list of possible values.
  ///
  /// Can be used to filter the response of the creatives.list method.
  core.String? advertiserId;

  /// Advertiser name.
  ///
  /// Can be used to filter the response of the creatives.list method.
  core.String? advertiserName;

  /// Detected brand ID or zero if no brand has been detected.
  ///
  /// See https://storage.googleapis.com/adx-rtb-dictionaries/brands.txt for the
  /// list of possible values. Can be used to filter the response of the
  /// creatives.list method.
  core.String? brandId;

  /// Brand name.
  ///
  /// Can be used to filter the response of the creatives.list method.
  core.String? brandName;

  AdvertiserAndBrand();

  AdvertiserAndBrand.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserId')) {
      advertiserId = _json['advertiserId'] as core.String;
    }
    if (_json.containsKey('advertiserName')) {
      advertiserName = _json['advertiserName'] as core.String;
    }
    if (_json.containsKey('brandId')) {
      brandId = _json['brandId'] as core.String;
    }
    if (_json.containsKey('brandName')) {
      brandName = _json['brandName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserId != null) 'advertiserId': advertiserId!,
        if (advertiserName != null) 'advertiserName': advertiserName!,
        if (brandId != null) 'brandId': brandId!,
        if (brandName != null) 'brandName': brandName!,
      };
}

/// A subset of app inventory to target.
///
/// Bid requests that match criteria in at least one of the specified dimensions
/// will be sent.
class AppTargeting {
  /// Lists of included and excluded mobile app categories as defined in
  /// https://developers.google.com/adwords/api/docs/appendix/mobileappcategories.csv.
  NumericTargetingDimension? mobileAppCategoryTargeting;

  /// Targeted app IDs.
  ///
  /// App IDs can refer to those found in an app store or ones that are not
  /// published in an app store. A maximum of 30,000 app IDs can be targeted.
  StringTargetingDimension? mobileAppTargeting;

  AppTargeting();

  AppTargeting.fromJson(core.Map _json) {
    if (_json.containsKey('mobileAppCategoryTargeting')) {
      mobileAppCategoryTargeting = NumericTargetingDimension.fromJson(
          _json['mobileAppCategoryTargeting']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mobileAppTargeting')) {
      mobileAppTargeting = StringTargetingDimension.fromJson(
          _json['mobileAppTargeting'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mobileAppCategoryTargeting != null)
          'mobileAppCategoryTargeting': mobileAppCategoryTargeting!.toJson(),
        if (mobileAppTargeting != null)
          'mobileAppTargeting': mobileAppTargeting!.toJson(),
      };
}

/// Bidder settings.
class Bidder {
  /// A flag to bypass pretargeting for private auctions and preferred deals.
  ///
  /// When true, bid requests from these nonguaranteed deals will always be
  /// sent. When false, bid requests will be subject to regular pretargeting
  /// configurations. Programmatic Guaranteed deals will always be sent to the
  /// bidder, regardless of the value for this flag. Auction packages are not
  /// impacted by this value and are subject to the regular pretargeting
  /// configurations.
  ///
  /// Output only.
  core.bool? bypassNonguaranteedDealsPretargeting;

  /// The buyer's network ID used for cookie matching.
  ///
  /// This ID corresponds to the `google_nid` parameter in the URL used in
  /// cookie match requests. Refer to
  /// https://developers.google.com/authorized-buyers/rtb/cookie-guide for
  /// further information.
  ///
  /// Output only.
  core.String? cookieMatchingNetworkId;

  /// The base URL used in cookie match requests.
  ///
  /// Refer to https://developers.google.com/authorized-buyers/rtb/cookie-guide
  /// for further information.
  ///
  /// Output only.
  core.String? cookieMatchingUrl;

  /// The billing ID for the deals pretargeting config.
  ///
  /// This billing ID is sent on the bid request for guaranteed and
  /// nonguaranteed deals matched in pretargeting.
  ///
  /// Output only.
  core.String? dealsBillingId;

  /// Name of the bidder resource that must follow the pattern
  /// `bidders/{bidderAccountId}`, where `{bidderAccountId}` is the account ID
  /// of the bidder whose information is to be received.
  ///
  /// One can get their account ID on the Authorized Buyers or Open Bidding UI,
  /// or by contacting their Google account manager.
  ///
  /// Output only.
  core.String? name;

  Bidder();

  Bidder.fromJson(core.Map _json) {
    if (_json.containsKey('bypassNonguaranteedDealsPretargeting')) {
      bypassNonguaranteedDealsPretargeting =
          _json['bypassNonguaranteedDealsPretargeting'] as core.bool;
    }
    if (_json.containsKey('cookieMatchingNetworkId')) {
      cookieMatchingNetworkId = _json['cookieMatchingNetworkId'] as core.String;
    }
    if (_json.containsKey('cookieMatchingUrl')) {
      cookieMatchingUrl = _json['cookieMatchingUrl'] as core.String;
    }
    if (_json.containsKey('dealsBillingId')) {
      dealsBillingId = _json['dealsBillingId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bypassNonguaranteedDealsPretargeting != null)
          'bypassNonguaranteedDealsPretargeting':
              bypassNonguaranteedDealsPretargeting!,
        if (cookieMatchingNetworkId != null)
          'cookieMatchingNetworkId': cookieMatchingNetworkId!,
        if (cookieMatchingUrl != null) 'cookieMatchingUrl': cookieMatchingUrl!,
        if (dealsBillingId != null) 'dealsBillingId': dealsBillingId!,
        if (name != null) 'name': name!,
      };
}

/// RTB Buyer account information.
class Buyer {
  /// The number of creatives that this buyer submitted via the API or bid with
  /// in the last 30 days.
  ///
  /// This is counted against the maximum number of active creatives.
  ///
  /// Output only.
  core.String? activeCreativeCount;

  /// The name of the bidder resource that is responsible for receiving bidding
  /// traffic for this account.
  ///
  /// The bidder name must follow the pattern `bidders/{bidderAccountId}`, where
  /// `{bidderAccountId}` is the account ID of the bidder receiving traffic for
  /// this buyer.
  ///
  /// Output only.
  core.String? bidder;

  /// A list of billing IDs associated with this account.
  ///
  /// These IDs appear on: 1. A bid request, to signal which buyers are eligible
  /// to bid on a given opportunity, and which pretargeting configurations were
  /// matched for each eligible buyer. 2. The bid response, to attribute a
  /// winning impression to a specific account for billing, reporting, policy
  /// and publisher block enforcement.
  ///
  /// Output only.
  core.List<core.String>? billingIds;

  /// The diplay name associated with this buyer account, as visible to sellers.
  ///
  /// Output only.
  core.String? displayName;

  /// The maximum number of active creatives that this buyer can have.
  ///
  /// Output only.
  core.String? maximumActiveCreativeCount;

  /// Name of the buyer resource that must follow the pattern
  /// `buyers/{buyerAccountId}`, where `{buyerAccountId}` is the account ID of
  /// the buyer account whose information is to be received.
  ///
  /// One can get their account ID on the Authorized Buyers or Open Bidding UI,
  /// or by contacting their Google account manager.
  ///
  /// Output only.
  core.String? name;

  Buyer();

  Buyer.fromJson(core.Map _json) {
    if (_json.containsKey('activeCreativeCount')) {
      activeCreativeCount = _json['activeCreativeCount'] as core.String;
    }
    if (_json.containsKey('bidder')) {
      bidder = _json['bidder'] as core.String;
    }
    if (_json.containsKey('billingIds')) {
      billingIds = (_json['billingIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('maximumActiveCreativeCount')) {
      maximumActiveCreativeCount =
          _json['maximumActiveCreativeCount'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activeCreativeCount != null)
          'activeCreativeCount': activeCreativeCount!,
        if (bidder != null) 'bidder': bidder!,
        if (billingIds != null) 'billingIds': billingIds!,
        if (displayName != null) 'displayName': displayName!,
        if (maximumActiveCreativeCount != null)
          'maximumActiveCreativeCount': maximumActiveCreativeCount!,
        if (name != null) 'name': name!,
      };
}

/// A request to close a specified user list.
class CloseUserListRequest {
  CloseUserListRequest();

  CloseUserListRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A creative and its classification data.
class Creative {
  /// ID of the buyer account that this creative is owned by.
  ///
  /// Can be used to filter the response of the creatives.list method with
  /// equality and inequality check.
  ///
  /// Output only.
  core.String? accountId;

  /// The link to AdChoices destination page.
  ///
  /// This is only supported for native ads.
  core.String? adChoicesDestinationUrl;

  /// The name of the company being advertised in the creative.
  ///
  /// Can be used to filter the response of the creatives.list method.
  core.String? advertiserName;

  /// The agency ID for this creative.
  core.String? agencyId;

  /// The last update timestamp of the creative via API.
  ///
  /// Output only.
  core.String? apiUpdateTime;

  /// The format of this creative.
  ///
  /// Can be used to filter the response of the creatives.list method.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "CREATIVE_FORMAT_UNSPECIFIED" : The format is unknown.
  /// - "HTML" : HTML creative.
  /// - "VIDEO" : Video creative.
  /// - "NATIVE" : Native creative.
  core.String? creativeFormat;

  /// Buyer-specific creative ID that references this creative in bid responses.
  ///
  /// This field is Ignored in update operations. Can be used to filter the
  /// response of the creatives.list method. The maximum length of the creative
  /// ID is 128 bytes.
  core.String? creativeId;

  /// Top level status and detected attributes of a creative (for example
  /// domain, language, advertiser, product category, etc.) that affect whether
  /// (status) and where (context) a creative will be allowed to serve.
  ///
  /// Output only.
  CreativeServingDecision? creativeServingDecision;

  /// IDs of all of the deals with which this creative has been used in bidding.
  ///
  /// Can be used to filter the response of the creatives.list method.
  ///
  /// Output only.
  core.List<core.String>? dealIds;

  /// All declared attributes for the ads that may be shown from this creative.
  ///
  /// Can be used to filter the response of the creatives.list method. If the
  /// `excluded_attribute` field of a
  /// [bid request](https://developers.google.com/authorized-buyers/rtb/downloads/realtime-bidding-proto")
  /// contains one of the attributes that were declared or detected for a given
  /// creative, and a bid is submitted with that creative, the bid will be
  /// filtered before the auction.
  core.List<core.String>? declaredAttributes;

  /// The set of declared destination URLs for the creative.
  ///
  /// Can be used to filter the response of the creatives.list method.
  core.List<core.String>? declaredClickThroughUrls;

  /// All declared restricted categories for the ads that may be shown from this
  /// creative.
  ///
  /// Can be used to filter the response of the creatives.list method.
  core.List<core.String>? declaredRestrictedCategories;

  /// IDs for the declared ad technology vendors that may be used by this
  /// creative.
  ///
  /// See https://storage.googleapis.com/adx-rtb-dictionaries/vendors.txt for
  /// possible values. Can be used to filter the response of the creatives.list
  /// method.
  core.List<core.int>? declaredVendorIds;

  /// An HTML creative.
  HtmlContent? html;

  /// The set of URLs to be called to record an impression.
  core.List<core.String>? impressionTrackingUrls;

  /// Name of the creative.
  ///
  /// Follows the pattern `buyers/{buyer}/creatives/{creative}`, where `{buyer}`
  /// represents the account ID of the buyer who owns the creative, and
  /// `{creative}` is the buyer-specific creative ID that references this
  /// creative in the bid response.
  ///
  /// Output only.
  core.String? name;

  /// A native creative.
  NativeContent? native;

  /// All restricted categories for the ads that may be shown from this
  /// creative.
  core.List<core.String>? restrictedCategories;

  /// The version of this creative.
  ///
  /// Version for a new creative is 1 and it increments during subsequent
  /// creative updates.
  ///
  /// Output only.
  core.int? version;

  /// A video creative.
  VideoContent? video;

  Creative();

  Creative.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('adChoicesDestinationUrl')) {
      adChoicesDestinationUrl = _json['adChoicesDestinationUrl'] as core.String;
    }
    if (_json.containsKey('advertiserName')) {
      advertiserName = _json['advertiserName'] as core.String;
    }
    if (_json.containsKey('agencyId')) {
      agencyId = _json['agencyId'] as core.String;
    }
    if (_json.containsKey('apiUpdateTime')) {
      apiUpdateTime = _json['apiUpdateTime'] as core.String;
    }
    if (_json.containsKey('creativeFormat')) {
      creativeFormat = _json['creativeFormat'] as core.String;
    }
    if (_json.containsKey('creativeId')) {
      creativeId = _json['creativeId'] as core.String;
    }
    if (_json.containsKey('creativeServingDecision')) {
      creativeServingDecision = CreativeServingDecision.fromJson(
          _json['creativeServingDecision']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dealIds')) {
      dealIds = (_json['dealIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('declaredAttributes')) {
      declaredAttributes = (_json['declaredAttributes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('declaredClickThroughUrls')) {
      declaredClickThroughUrls =
          (_json['declaredClickThroughUrls'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('declaredRestrictedCategories')) {
      declaredRestrictedCategories =
          (_json['declaredRestrictedCategories'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('declaredVendorIds')) {
      declaredVendorIds = (_json['declaredVendorIds'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('html')) {
      html = HtmlContent.fromJson(
          _json['html'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('impressionTrackingUrls')) {
      impressionTrackingUrls = (_json['impressionTrackingUrls'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('native')) {
      native = NativeContent.fromJson(
          _json['native'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('restrictedCategories')) {
      restrictedCategories = (_json['restrictedCategories'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.int;
    }
    if (_json.containsKey('video')) {
      video = VideoContent.fromJson(
          _json['video'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (adChoicesDestinationUrl != null)
          'adChoicesDestinationUrl': adChoicesDestinationUrl!,
        if (advertiserName != null) 'advertiserName': advertiserName!,
        if (agencyId != null) 'agencyId': agencyId!,
        if (apiUpdateTime != null) 'apiUpdateTime': apiUpdateTime!,
        if (creativeFormat != null) 'creativeFormat': creativeFormat!,
        if (creativeId != null) 'creativeId': creativeId!,
        if (creativeServingDecision != null)
          'creativeServingDecision': creativeServingDecision!.toJson(),
        if (dealIds != null) 'dealIds': dealIds!,
        if (declaredAttributes != null)
          'declaredAttributes': declaredAttributes!,
        if (declaredClickThroughUrls != null)
          'declaredClickThroughUrls': declaredClickThroughUrls!,
        if (declaredRestrictedCategories != null)
          'declaredRestrictedCategories': declaredRestrictedCategories!,
        if (declaredVendorIds != null) 'declaredVendorIds': declaredVendorIds!,
        if (html != null) 'html': html!.toJson(),
        if (impressionTrackingUrls != null)
          'impressionTrackingUrls': impressionTrackingUrls!,
        if (name != null) 'name': name!,
        if (native != null) 'native': native!.toJson(),
        if (restrictedCategories != null)
          'restrictedCategories': restrictedCategories!,
        if (version != null) 'version': version!,
        if (video != null) 'video': video!.toJson(),
      };
}

/// The dimensions of a creative.
///
/// This applies to only HTML and Native creatives.
class CreativeDimensions {
  /// The height of the creative in pixels.
  core.String? height;

  /// The width of the creative in pixels.
  core.String? width;

  CreativeDimensions();

  CreativeDimensions.fromJson(core.Map _json) {
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

/// Top level status and detected attributes of a creative.
class CreativeServingDecision {
  /// The detected ad technology providers.
  AdTechnologyProviders? adTechnologyProviders;

  /// The policy compliance of this creative in China.
  ///
  /// When approved or disapproved, this applies to both deals and open auction
  /// in China. When pending review, this creative is allowed to serve for deals
  /// but not for open auction.
  PolicyCompliance? chinaPolicyCompliance;

  /// Policy compliance of this creative when bidding on Programmatic Guaranteed
  /// and Preferred Deals (outside of Russia and China).
  PolicyCompliance? dealsPolicyCompliance;

  /// Detected advertisers and brands.
  core.List<AdvertiserAndBrand>? detectedAdvertisers;

  /// Publisher-excludable attributes that were detected for this creative.
  ///
  /// Can be used to filter the response of the creatives.list method. If the
  /// `excluded_attribute` field of a
  /// [bid request](https://developers.google.com/authorized-buyers/rtb/downloads/realtime-bidding-proto)
  /// contains one of the attributes that were declared or detected for a given
  /// creative, and a bid is submitted with that creative, the bid will be
  /// filtered before the auction.
  core.List<core.String>? detectedAttributes;

  /// The set of detected destination URLs for the creative.
  ///
  /// Can be used to filter the response of the creatives.list method.
  core.List<core.String>? detectedClickThroughUrls;

  /// The detected domains for this creative.
  core.List<core.String>? detectedDomains;

  /// The detected languages for this creative.
  ///
  /// The order is arbitrary. The codes are 2 or 5 characters and are documented
  /// at https://developers.google.com/adwords/api/docs/appendix/languagecodes.
  /// Can be used to filter the response of the creatives.list method.
  core.List<core.String>? detectedLanguages;

  /// Detected product categories, if any.
  ///
  /// See the ad-product-categories.txt file in the technical documentation for
  /// a list of IDs. Can be used to filter the response of the creatives.list
  /// method.
  core.List<core.int>? detectedProductCategories;

  /// Detected sensitive categories, if any.
  ///
  /// Can be used to filter the response of the creatives.list method. See the
  /// ad-sensitive-categories.txt file in the technical documentation for a list
  /// of IDs. You should use these IDs along with the
  /// excluded-sensitive-category field in the bid request to filter your bids.
  core.List<core.int>? detectedSensitiveCategories;

  /// IDs of the ad technology vendors that were detected to be used by this
  /// creative.
  ///
  /// See https://storage.googleapis.com/adx-rtb-dictionaries/vendors.txt for
  /// possible values. Can be used to filter the response of the creatives.list
  /// method. If the `allowed_vendor_type` field of a
  /// [bid request](https://developers.google.com/authorized-buyers/rtb/downloads/realtime-bidding-proto)
  /// does not contain one of the vendor type IDs that were declared or detected
  /// for a given creative, and a bid is submitted with that creative, the bid
  /// will be filtered before the auction.
  core.List<core.int>? detectedVendorIds;

  /// The last time the creative status was updated.
  ///
  /// Can be used to filter the response of the creatives.list method.
  core.String? lastStatusUpdate;

  /// Policy compliance of this creative when bidding in open auction, private
  /// auction, or auction packages (outside of Russia and China).
  PolicyCompliance? networkPolicyCompliance;

  /// Policy compliance of this creative when bidding in Open Bidding (outside
  /// of Russia and China).
  ///
  /// For the list of platform policies, see:
  /// https://support.google.com/platformspolicy/answer/3013851.
  PolicyCompliance? platformPolicyCompliance;

  /// The policy compliance of this creative in Russia.
  ///
  /// When approved or disapproved, this applies to both deals and open auction
  /// in Russia. When pending review, this creative is allowed to serve for
  /// deals but not for open auction.
  PolicyCompliance? russiaPolicyCompliance;

  CreativeServingDecision();

  CreativeServingDecision.fromJson(core.Map _json) {
    if (_json.containsKey('adTechnologyProviders')) {
      adTechnologyProviders = AdTechnologyProviders.fromJson(
          _json['adTechnologyProviders']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('chinaPolicyCompliance')) {
      chinaPolicyCompliance = PolicyCompliance.fromJson(
          _json['chinaPolicyCompliance']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dealsPolicyCompliance')) {
      dealsPolicyCompliance = PolicyCompliance.fromJson(
          _json['dealsPolicyCompliance']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('detectedAdvertisers')) {
      detectedAdvertisers = (_json['detectedAdvertisers'] as core.List)
          .map<AdvertiserAndBrand>((value) => AdvertiserAndBrand.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('detectedAttributes')) {
      detectedAttributes = (_json['detectedAttributes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('detectedClickThroughUrls')) {
      detectedClickThroughUrls =
          (_json['detectedClickThroughUrls'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('detectedDomains')) {
      detectedDomains = (_json['detectedDomains'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('detectedLanguages')) {
      detectedLanguages = (_json['detectedLanguages'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('detectedProductCategories')) {
      detectedProductCategories =
          (_json['detectedProductCategories'] as core.List)
              .map<core.int>((value) => value as core.int)
              .toList();
    }
    if (_json.containsKey('detectedSensitiveCategories')) {
      detectedSensitiveCategories =
          (_json['detectedSensitiveCategories'] as core.List)
              .map<core.int>((value) => value as core.int)
              .toList();
    }
    if (_json.containsKey('detectedVendorIds')) {
      detectedVendorIds = (_json['detectedVendorIds'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('lastStatusUpdate')) {
      lastStatusUpdate = _json['lastStatusUpdate'] as core.String;
    }
    if (_json.containsKey('networkPolicyCompliance')) {
      networkPolicyCompliance = PolicyCompliance.fromJson(
          _json['networkPolicyCompliance']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('platformPolicyCompliance')) {
      platformPolicyCompliance = PolicyCompliance.fromJson(
          _json['platformPolicyCompliance']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('russiaPolicyCompliance')) {
      russiaPolicyCompliance = PolicyCompliance.fromJson(
          _json['russiaPolicyCompliance']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adTechnologyProviders != null)
          'adTechnologyProviders': adTechnologyProviders!.toJson(),
        if (chinaPolicyCompliance != null)
          'chinaPolicyCompliance': chinaPolicyCompliance!.toJson(),
        if (dealsPolicyCompliance != null)
          'dealsPolicyCompliance': dealsPolicyCompliance!.toJson(),
        if (detectedAdvertisers != null)
          'detectedAdvertisers':
              detectedAdvertisers!.map((value) => value.toJson()).toList(),
        if (detectedAttributes != null)
          'detectedAttributes': detectedAttributes!,
        if (detectedClickThroughUrls != null)
          'detectedClickThroughUrls': detectedClickThroughUrls!,
        if (detectedDomains != null) 'detectedDomains': detectedDomains!,
        if (detectedLanguages != null) 'detectedLanguages': detectedLanguages!,
        if (detectedProductCategories != null)
          'detectedProductCategories': detectedProductCategories!,
        if (detectedSensitiveCategories != null)
          'detectedSensitiveCategories': detectedSensitiveCategories!,
        if (detectedVendorIds != null) 'detectedVendorIds': detectedVendorIds!,
        if (lastStatusUpdate != null) 'lastStatusUpdate': lastStatusUpdate!,
        if (networkPolicyCompliance != null)
          'networkPolicyCompliance': networkPolicyCompliance!.toJson(),
        if (platformPolicyCompliance != null)
          'platformPolicyCompliance': platformPolicyCompliance!.toJson(),
        if (russiaPolicyCompliance != null)
          'russiaPolicyCompliance': russiaPolicyCompliance!.toJson(),
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

/// Evidence that the creative's destination URL was not crawlable by Google.
class DestinationNotCrawlableEvidence {
  /// Approximate time of the crawl.
  core.String? crawlTime;

  /// Destination URL that was attempted to be crawled.
  core.String? crawledUrl;

  /// Reason of destination not crawlable.
  /// Possible string values are:
  /// - "REASON_UNSPECIFIED" : Default value that should never be used.
  /// - "UNREACHABLE_ROBOTS" : Site's robots exclusion file (e.g., robots.txt)
  /// was unreachable.
  /// - "TIMEOUT_ROBOTS" : Timed out reading site's robots exclusion file (e.g.,
  /// robots.txt).
  /// - "ROBOTED_DENIED" : Crawler was disallowed by the site's robots exclusion
  /// file (e.g., robots.txt).
  /// - "UNKNOWN" : Unknown reason.
  core.String? reason;

  DestinationNotCrawlableEvidence();

  DestinationNotCrawlableEvidence.fromJson(core.Map _json) {
    if (_json.containsKey('crawlTime')) {
      crawlTime = _json['crawlTime'] as core.String;
    }
    if (_json.containsKey('crawledUrl')) {
      crawledUrl = _json['crawledUrl'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (crawlTime != null) 'crawlTime': crawlTime!,
        if (crawledUrl != null) 'crawledUrl': crawledUrl!,
        if (reason != null) 'reason': reason!,
      };
}

/// Evidence of the creative's destination URL not functioning properly or
/// having been incorrectly set up.
class DestinationNotWorkingEvidence {
  /// DNS lookup errors.
  /// Possible string values are:
  /// - "DNS_ERROR_UNSPECIFIED" : Default value that should never be used.
  /// - "ERROR_DNS" : DNS name was not found.
  /// - "GOOGLE_CRAWLER_DNS_ISSUE" : An internal issue occurred when Google's
  /// crawler tried to resolve the DNS entry. This is a Google-internal issue
  /// and may not be the result of an issue with the landing page.
  core.String? dnsError;

  /// The full non-working URL.
  core.String? expandedUrl;

  /// HTTP error code (e.g. 404 or 5xx)
  core.int? httpError;

  /// Page was crawled successfully, but was detected as either a page with no
  /// content or an error page.
  /// Possible string values are:
  /// - "INVALID_PAGE_UNSPECIFIED" : Default value that should never be used.
  /// - "EMPTY_OR_ERROR_PAGE" : Page was empty or had an error.
  core.String? invalidPage;

  /// Approximate time when the ad destination was last checked.
  core.String? lastCheckTime;

  /// Platform of the non-working URL.
  /// Possible string values are:
  /// - "PLATFORM_UNSPECIFIED" : Default value that should never be used.
  /// - "PERSONAL_COMPUTER" : The personal computer platform.
  /// - "ANDROID" : The Android platform.
  /// - "IOS" : The iOS platform.
  core.String? platform;

  /// HTTP redirect chain error.
  /// Possible string values are:
  /// - "REDIRECTION_ERROR_UNSPECIFIED" : Default value that should never be
  /// used.
  /// - "TOO_MANY_REDIRECTS" : Too many redirect hops.
  /// - "INVALID_REDIRECT" : Got a redirect but it was invalid.
  /// - "EMPTY_REDIRECT" : Got a redirect but it was empty.
  /// - "REDIRECT_ERROR_UNKNOWN" : Unknown redirect error.
  core.String? redirectionError;

  /// Rejected because of malformed URLs or invalid requests.
  /// Possible string values are:
  /// - "URL_REJECTED_UNSPECIFIED" : Default value that should never be used.
  /// - "BAD_REQUEST" : URL rejected because of a malformed request.
  /// - "MALFORMED_URL" : URL rejected because of a malformed URL.
  /// - "URL_REJECTED_UNKNOWN" : URL rejected because of unknown reason.
  core.String? urlRejected;

  DestinationNotWorkingEvidence();

  DestinationNotWorkingEvidence.fromJson(core.Map _json) {
    if (_json.containsKey('dnsError')) {
      dnsError = _json['dnsError'] as core.String;
    }
    if (_json.containsKey('expandedUrl')) {
      expandedUrl = _json['expandedUrl'] as core.String;
    }
    if (_json.containsKey('httpError')) {
      httpError = _json['httpError'] as core.int;
    }
    if (_json.containsKey('invalidPage')) {
      invalidPage = _json['invalidPage'] as core.String;
    }
    if (_json.containsKey('lastCheckTime')) {
      lastCheckTime = _json['lastCheckTime'] as core.String;
    }
    if (_json.containsKey('platform')) {
      platform = _json['platform'] as core.String;
    }
    if (_json.containsKey('redirectionError')) {
      redirectionError = _json['redirectionError'] as core.String;
    }
    if (_json.containsKey('urlRejected')) {
      urlRejected = _json['urlRejected'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dnsError != null) 'dnsError': dnsError!,
        if (expandedUrl != null) 'expandedUrl': expandedUrl!,
        if (httpError != null) 'httpError': httpError!,
        if (invalidPage != null) 'invalidPage': invalidPage!,
        if (lastCheckTime != null) 'lastCheckTime': lastCheckTime!,
        if (platform != null) 'platform': platform!,
        if (redirectionError != null) 'redirectionError': redirectionError!,
        if (urlRejected != null) 'urlRejected': urlRejected!,
      };
}

/// The full landing page URL of the destination.
class DestinationUrlEvidence {
  /// The full landing page URL of the destination.
  core.String? destinationUrl;

  DestinationUrlEvidence();

  DestinationUrlEvidence.fromJson(core.Map _json) {
    if (_json.containsKey('destinationUrl')) {
      destinationUrl = _json['destinationUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationUrl != null) 'destinationUrl': destinationUrl!,
      };
}

/// Number of HTTP calls made by a creative, broken down by domain.
class DomainCallEvidence {
  /// Breakdown of the most frequent domains called via HTTP by the creative.
  core.List<DomainCalls>? topHttpCallDomains;

  /// The total number of HTTP calls made by the creative, including but not
  /// limited to the number of calls in the top_http_call_domains.
  core.int? totalHttpCallCount;

  DomainCallEvidence();

  DomainCallEvidence.fromJson(core.Map _json) {
    if (_json.containsKey('topHttpCallDomains')) {
      topHttpCallDomains = (_json['topHttpCallDomains'] as core.List)
          .map<DomainCalls>((value) => DomainCalls.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('totalHttpCallCount')) {
      totalHttpCallCount = _json['totalHttpCallCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (topHttpCallDomains != null)
          'topHttpCallDomains':
              topHttpCallDomains!.map((value) => value.toJson()).toList(),
        if (totalHttpCallCount != null)
          'totalHttpCallCount': totalHttpCallCount!,
      };
}

/// The number of HTTP calls made to the given domain.
class DomainCalls {
  /// The domain name.
  core.String? domain;

  /// Number of HTTP calls made to the domain.
  core.int? httpCallCount;

  DomainCalls();

  DomainCalls.fromJson(core.Map _json) {
    if (_json.containsKey('domain')) {
      domain = _json['domain'] as core.String;
    }
    if (_json.containsKey('httpCallCount')) {
      httpCallCount = _json['httpCallCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (domain != null) 'domain': domain!,
        if (httpCallCount != null) 'httpCallCount': httpCallCount!,
      };
}

/// Total download size and URL-level download size breakdown for resources in a
/// creative.
class DownloadSizeEvidence {
  /// Download size broken down by URLs with the top download size.
  core.List<UrlDownloadSize>? topUrlDownloadSizeBreakdowns;

  /// Total download size (in kilobytes) for all the resources in the creative.
  core.int? totalDownloadSizeKb;

  DownloadSizeEvidence();

  DownloadSizeEvidence.fromJson(core.Map _json) {
    if (_json.containsKey('topUrlDownloadSizeBreakdowns')) {
      topUrlDownloadSizeBreakdowns =
          (_json['topUrlDownloadSizeBreakdowns'] as core.List)
              .map<UrlDownloadSize>((value) => UrlDownloadSize.fromJson(
                  value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('totalDownloadSizeKb')) {
      totalDownloadSizeKb = _json['totalDownloadSizeKb'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (topUrlDownloadSizeBreakdowns != null)
          'topUrlDownloadSizeBreakdowns': topUrlDownloadSizeBreakdowns!
              .map((value) => value.toJson())
              .toList(),
        if (totalDownloadSizeKb != null)
          'totalDownloadSizeKb': totalDownloadSizeKb!,
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

/// Bidder endpoint that receives bid requests.
class Endpoint {
  /// The protocol that the bidder endpoint is using.
  /// Possible string values are:
  /// - "BID_PROTOCOL_UNSPECIFIED" : Placeholder for undefined bid protocol.
  /// This value should not be used.
  /// - "GOOGLE_RTB" : Google RTB protocol / Protobuf encoding.
  /// - "OPENRTB_2_2" : OpenRTB / JSON encoding, specification version 2.2.
  /// - "OPENRTB_2_3" : OpenRTB / JSON encoding, specification version 2.3.
  /// - "OPENRTB_PROTOBUF_2_3" : OpenRTB / Protobuf encoding, specification
  /// version 2.3.
  /// - "OPENRTB_2_4" : OpenRTB / JSON encoding, specification version 2.4.
  /// - "OPENRTB_PROTOBUF_2_4" : OpenRTB / Protobuf encoding, specification
  /// version 2.4.
  /// - "OPENRTB_2_5" : OpenRTB / JSON encoding, specification version 2.5.
  /// - "OPENRTB_PROTOBUF_2_5" : OpenRTB / Protobuf encoding, specification
  /// version 2.5.
  core.String? bidProtocol;

  /// The maximum number of queries per second allowed to be sent to this
  /// server.
  core.String? maximumQps;

  /// Name of the endpoint resource that must follow the pattern
  /// `bidders/{bidderAccountId}/endpoints/{endpointId}`, where
  /// {bidderAccountId} is the account ID of the bidder who operates this
  /// endpoint, and {endpointId} is a unique ID assigned by the server.
  ///
  /// Output only.
  core.String? name;

  /// The trading location that bid requests should be sent from.
  ///
  /// See
  /// https://developers.google.com/authorized-buyers/rtb/peer-guide#trading-locations
  /// for further information.
  /// Possible string values are:
  /// - "TRADING_LOCATION_UNSPECIFIED" : A placeholder for an undefined trading
  /// region. This value should not be used.
  /// - "US_WEST" : The Western US trading location.
  /// - "US_EAST" : The Eastern US trading location.
  /// - "EUROPE" : The European trading location.
  /// - "ASIA" : The Asia trading location.
  core.String? tradingLocation;

  /// The URL that bid requests should be sent to.
  ///
  /// Output only.
  core.String? url;

  Endpoint();

  Endpoint.fromJson(core.Map _json) {
    if (_json.containsKey('bidProtocol')) {
      bidProtocol = _json['bidProtocol'] as core.String;
    }
    if (_json.containsKey('maximumQps')) {
      maximumQps = _json['maximumQps'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('tradingLocation')) {
      tradingLocation = _json['tradingLocation'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bidProtocol != null) 'bidProtocol': bidProtocol!,
        if (maximumQps != null) 'maximumQps': maximumQps!,
        if (name != null) 'name': name!,
        if (tradingLocation != null) 'tradingLocation': tradingLocation!,
        if (url != null) 'url': url!,
      };
}

/// Response for a request to get remarketing tag.
class GetRemarketingTagResponse {
  /// A HTML tag that can be placed on the advertiser's page to add users to a
  /// user list.
  ///
  /// For more information and code samples on using snippet on your website
  /// refer to \[Tag your site for remarketing\](
  /// https://support.google.com/google-ads/answer/2476688).
  core.String? snippet;

  GetRemarketingTagResponse();

  GetRemarketingTagResponse.fromJson(core.Map _json) {
    if (_json.containsKey('snippet')) {
      snippet = _json['snippet'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (snippet != null) 'snippet': snippet!,
      };
}

/// HTML content for a creative.
class HtmlContent {
  /// The height of the HTML snippet in pixels.
  ///
  /// Can be used to filter the response of the creatives.list method.
  core.int? height;

  /// The HTML snippet that displays the ad when inserted in the web page.
  core.String? snippet;

  /// The width of the HTML snippet in pixels.
  ///
  /// Can be used to filter the response of the creatives.list method.
  core.int? width;

  HtmlContent();

  HtmlContent.fromJson(core.Map _json) {
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('snippet')) {
      snippet = _json['snippet'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (height != null) 'height': height!,
        if (snippet != null) 'snippet': snippet!,
        if (width != null) 'width': width!,
      };
}

/// HTTP calls made by a creative that resulted in policy violations.
class HttpCallEvidence {
  /// URLs of HTTP calls made by the creative.
  core.List<core.String>? urls;

  HttpCallEvidence();

  HttpCallEvidence.fromJson(core.Map _json) {
    if (_json.containsKey('urls')) {
      urls = (_json['urls'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (urls != null) 'urls': urls!,
      };
}

/// Evidence for HTTP cookie-related policy violations.
class HttpCookieEvidence {
  /// Names of cookies that violate Google policies.
  ///
  /// For TOO_MANY_COOKIES policy, this will be the cookie names of top domains
  /// with the largest number of cookies. For other policies, this will be all
  /// the cookie names that violate the policy.
  core.List<core.String>? cookieNames;

  /// The largest number of cookies set by a creative.
  ///
  /// If this field is set, cookie_names above will be set to the cookie names
  /// of top domains with the largest number of cookies. This field will only be
  /// set for TOO_MANY_COOKIES policy.
  core.int? maxCookieCount;

  HttpCookieEvidence();

  HttpCookieEvidence.fromJson(core.Map _json) {
    if (_json.containsKey('cookieNames')) {
      cookieNames = (_json['cookieNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('maxCookieCount')) {
      maxCookieCount = _json['maxCookieCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cookieNames != null) 'cookieNames': cookieNames!,
        if (maxCookieCount != null) 'maxCookieCount': maxCookieCount!,
      };
}

/// An image resource.
///
/// You may provide a larger image than was requested, so long as the aspect
/// ratio is preserved.
class Image {
  /// Image height in pixels.
  core.int? height;

  /// The URL of the image.
  core.String? url;

  /// Image width in pixels.
  core.int? width;

  Image();

  Image.fromJson(core.Map _json) {
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

/// A response containing bidders.
class ListBiddersResponse {
  /// List of bidders.
  core.List<Bidder>? bidders;

  /// A token which can be passed to a subsequent call to the `ListBidders`
  /// method to retrieve the next page of results in
  /// ListBiddersRequest.pageToken.
  core.String? nextPageToken;

  ListBiddersResponse();

  ListBiddersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('bidders')) {
      bidders = (_json['bidders'] as core.List)
          .map<Bidder>((value) =>
              Bidder.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bidders != null)
          'bidders': bidders!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A response containing buyer account information.
class ListBuyersResponse {
  /// List of buyers.
  core.List<Buyer>? buyers;

  /// A token which can be passed to a subsequent call to the `ListBuyers`
  /// method to retrieve the next page of results in
  /// ListBuyersRequest.pageToken.
  core.String? nextPageToken;

  ListBuyersResponse();

  ListBuyersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('buyers')) {
      buyers = (_json['buyers'] as core.List)
          .map<Buyer>((value) =>
              Buyer.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buyers != null)
          'buyers': buyers!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A response for listing creatives.
class ListCreativesResponse {
  /// The list of creatives.
  core.List<Creative>? creatives;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the ListCreativesRequest.pageToken field in the
  /// subsequent call to the `ListCreatives` method to retrieve the next page of
  /// results.
  core.String? nextPageToken;

  ListCreativesResponse();

  ListCreativesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('creatives')) {
      creatives = (_json['creatives'] as core.List)
          .map<Creative>((value) =>
              Creative.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creatives != null)
          'creatives': creatives!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A response containing bidder endpoints.
class ListEndpointsResponse {
  /// List of bidder endpoints.
  core.List<Endpoint>? endpoints;

  /// A token which can be passed to a subsequent call to the `ListEndpoints`
  /// method to retrieve the next page of results in
  /// ListEndpointsRequest.pageToken.
  core.String? nextPageToken;

  ListEndpointsResponse();

  ListEndpointsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('endpoints')) {
      endpoints = (_json['endpoints'] as core.List)
          .map<Endpoint>((value) =>
              Endpoint.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endpoints != null)
          'endpoints': endpoints!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A response containing pretargeting configurations.
class ListPretargetingConfigsResponse {
  /// A token which can be passed to a subsequent call to the
  /// `ListPretargetingConfigs` method to retrieve the next page of results in
  /// ListPretargetingConfigsRequest.pageToken.
  core.String? nextPageToken;

  /// List of pretargeting configurations.
  core.List<PretargetingConfig>? pretargetingConfigs;

  ListPretargetingConfigsResponse();

  ListPretargetingConfigsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('pretargetingConfigs')) {
      pretargetingConfigs = (_json['pretargetingConfigs'] as core.List)
          .map<PretargetingConfig>((value) => PretargetingConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (pretargetingConfigs != null)
          'pretargetingConfigs':
              pretargetingConfigs!.map((value) => value.toJson()).toList(),
      };
}

/// The list user list response.
class ListUserListsResponse {
  /// The continuation page token to send back to the server in a subsequent
  /// request.
  ///
  /// Due to a currently known issue, it is recommended that the caller keep
  /// invoking the list method till the time a next page token is not returned
  /// (even if the result set is empty).
  core.String? nextPageToken;

  /// List of user lists from the search.
  core.List<UserList>? userLists;

  ListUserListsResponse();

  ListUserListsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('userLists')) {
      userLists = (_json['userLists'] as core.List)
          .map<UserList>((value) =>
              UserList.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (userLists != null)
          'userLists': userLists!.map((value) => value.toJson()).toList(),
      };
}

/// Information about each media file in the VAST.
class MediaFile {
  /// Bitrate of the video file, in Kbps.
  ///
  /// Can be used to filter the response of the creatives.list method.
  core.String? bitrate;

  /// The MIME type of this media file.
  ///
  /// Can be used to filter the response of the creatives.list method.
  /// Possible string values are:
  /// - "VIDEO_MIME_TYPE_UNSPECIFIED" : Default value that should never be used.
  /// - "MIME_VIDEO_XFLV" : Flash container.
  /// - "MIME_VIDEO_WEBM" : WebM container assuming VP9 codec.
  /// - "MIME_VIDEO_MP4" : MPEG-4 container typically with H.264 codec.
  /// - "MIME_VIDEO_OGG" : Ogg container assuming Theora codec.
  /// - "MIME_VIDEO_YT_HOSTED" : Video files hosted on YouTube.
  /// - "MIME_VIDEO_X_MS_WMV" : Windows Media Video Codec.
  /// - "MIME_VIDEO_3GPP" : 3GPP container format used on 3G phones.
  /// - "MIME_VIDEO_MOV" : Quicktime container format.
  /// - "MIME_APPLICATION_SWF" : Shockwave Flash (used for VPAID ads).
  /// - "MIME_APPLICATION_SURVEY" : Properties of VAST served by consumer
  /// survey.
  /// - "MIME_APPLICATION_JAVASCRIPT" : JavaScript (used for VPAID ads).
  /// - "MIME_APPLICATION_SILVERLIGHT" : Silverlight (used for VPAID ads).
  /// - "MIME_APPLICATION_MPEGURL" : HLS/M3U8.
  /// - "MIME_APPLICATION_MPEGDASH" : DASH.
  /// - "MIME_AUDIO_MP4A" : MPEG-4 audio format.
  /// - "MIME_AUDIO_MP3" : MPEG-3 audio format.
  /// - "MIME_AUDIO_OGG" : Ogg audio format
  core.String? mimeType;

  MediaFile();

  MediaFile.fromJson(core.Map _json) {
    if (_json.containsKey('bitrate')) {
      bitrate = _json['bitrate'] as core.String;
    }
    if (_json.containsKey('mimeType')) {
      mimeType = _json['mimeType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bitrate != null) 'bitrate': bitrate!,
        if (mimeType != null) 'mimeType': mimeType!,
      };
}

/// Native content for a creative.
class NativeContent {
  /// The name of the advertiser or sponsor, to be displayed in the ad creative.
  core.String? advertiserName;

  /// The app icon, for app download ads.
  Image? appIcon;

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
  Image? image;

  /// A smaller image, for the advertiser's logo.
  Image? logo;

  /// The price of the promoted app including currency info.
  core.String? priceDisplayText;

  /// The app rating in the app store.
  ///
  /// Must be in the range \[0-5\].
  core.double? starRating;

  /// The URL to fetch a native video ad.
  core.String? videoUrl;

  NativeContent();

  NativeContent.fromJson(core.Map _json) {
    if (_json.containsKey('advertiserName')) {
      advertiserName = _json['advertiserName'] as core.String;
    }
    if (_json.containsKey('appIcon')) {
      appIcon = Image.fromJson(
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
      image =
          Image.fromJson(_json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('logo')) {
      logo =
          Image.fromJson(_json['logo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('priceDisplayText')) {
      priceDisplayText = _json['priceDisplayText'] as core.String;
    }
    if (_json.containsKey('starRating')) {
      starRating = (_json['starRating'] as core.num).toDouble();
    }
    if (_json.containsKey('videoUrl')) {
      videoUrl = _json['videoUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advertiserName != null) 'advertiserName': advertiserName!,
        if (appIcon != null) 'appIcon': appIcon!.toJson(),
        if (body != null) 'body': body!,
        if (callToAction != null) 'callToAction': callToAction!,
        if (clickLinkUrl != null) 'clickLinkUrl': clickLinkUrl!,
        if (clickTrackingUrl != null) 'clickTrackingUrl': clickTrackingUrl!,
        if (headline != null) 'headline': headline!,
        if (image != null) 'image': image!.toJson(),
        if (logo != null) 'logo': logo!.toJson(),
        if (priceDisplayText != null) 'priceDisplayText': priceDisplayText!,
        if (starRating != null) 'starRating': starRating!,
        if (videoUrl != null) 'videoUrl': videoUrl!,
      };
}

/// Generic targeting used for targeting dimensions that contain a list of
/// included and excluded numeric IDs used in app, user list, geo, and vertical
/// id targeting.
class NumericTargetingDimension {
  /// The IDs excluded in a configuration.
  core.List<core.String>? excludedIds;

  /// The IDs included in a configuration.
  core.List<core.String>? includedIds;

  NumericTargetingDimension();

  NumericTargetingDimension.fromJson(core.Map _json) {
    if (_json.containsKey('excludedIds')) {
      excludedIds = (_json['excludedIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('includedIds')) {
      includedIds = (_json['includedIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (excludedIds != null) 'excludedIds': excludedIds!,
        if (includedIds != null) 'includedIds': includedIds!,
      };
}

/// A request to open a specified user list.
class OpenUserListRequest {
  OpenUserListRequest();

  OpenUserListRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Policy compliance of the creative for a transaction type or a region.
class PolicyCompliance {
  /// Serving status for the given transaction type (e.g., open auction, deals)
  /// or region (e.g., China, Russia).
  ///
  /// Can be used to filter the response of the creatives.list method.
  /// Possible string values are:
  /// - "STATUS_UNSPECIFIED" : Default value that should never be used.
  /// - "PENDING_REVIEW" : Creative is pending review.
  /// - "DISAPPROVED" : Creative cannot serve.
  /// - "APPROVED" : Creative is approved.
  core.String? status;

  /// Topics related to the policy compliance for this transaction type (e.g.,
  /// open auction, deals) or region (e.g., China, Russia).
  ///
  /// Topics may be present only if status is DISAPPROVED.
  core.List<PolicyTopicEntry>? topics;

  PolicyCompliance();

  PolicyCompliance.fromJson(core.Map _json) {
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('topics')) {
      topics = (_json['topics'] as core.List)
          .map<PolicyTopicEntry>((value) => PolicyTopicEntry.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (status != null) 'status': status!,
        if (topics != null)
          'topics': topics!.map((value) => value.toJson()).toList(),
      };
}

/// Each policy topic entry will represent a violation of a policy topic for a
/// creative, with the policy topic information and optional evidence for the
/// policy violation.
class PolicyTopicEntry {
  /// Pieces of evidence associated with this policy topic entry.
  core.List<PolicyTopicEvidence>? evidences;

  /// URL of the help center article describing this policy topic.
  core.String? helpCenterUrl;

  /// Policy topic this entry refers to.
  ///
  /// For example, "ALCOHOL", "TRADEMARKS_IN_AD_TEXT", or
  /// "DESTINATION_NOT_WORKING". The set of possible policy topics is not fixed
  /// for a particular API version and may change at any time. Can be used to
  /// filter the response of the creatives.list method
  core.String? policyTopic;

  PolicyTopicEntry();

  PolicyTopicEntry.fromJson(core.Map _json) {
    if (_json.containsKey('evidences')) {
      evidences = (_json['evidences'] as core.List)
          .map<PolicyTopicEvidence>((value) => PolicyTopicEvidence.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('helpCenterUrl')) {
      helpCenterUrl = _json['helpCenterUrl'] as core.String;
    }
    if (_json.containsKey('policyTopic')) {
      policyTopic = _json['policyTopic'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (evidences != null)
          'evidences': evidences!.map((value) => value.toJson()).toList(),
        if (helpCenterUrl != null) 'helpCenterUrl': helpCenterUrl!,
        if (policyTopic != null) 'policyTopic': policyTopic!,
      };
}

/// Evidence associated with a policy topic entry.
class PolicyTopicEvidence {
  /// The creative's destination URL was not crawlable by Google.
  DestinationNotCrawlableEvidence? destinationNotCrawlable;

  /// The creative's destination URL did not function properly or was
  /// incorrectly set up.
  DestinationNotWorkingEvidence? destinationNotWorking;

  /// URL of the actual landing page.
  DestinationUrlEvidence? destinationUrl;

  /// Number of HTTP calls made by the creative, broken down by domain.
  DomainCallEvidence? domainCall;

  /// Total download size and URL-level download size breakdown for resources in
  /// a creative.
  DownloadSizeEvidence? downloadSize;

  /// HTTP calls made by the creative that resulted in policy violations.
  HttpCallEvidence? httpCall;

  /// Evidence for HTTP cookie-related policy violations.
  HttpCookieEvidence? httpCookie;

  PolicyTopicEvidence();

  PolicyTopicEvidence.fromJson(core.Map _json) {
    if (_json.containsKey('destinationNotCrawlable')) {
      destinationNotCrawlable = DestinationNotCrawlableEvidence.fromJson(
          _json['destinationNotCrawlable']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('destinationNotWorking')) {
      destinationNotWorking = DestinationNotWorkingEvidence.fromJson(
          _json['destinationNotWorking']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('destinationUrl')) {
      destinationUrl = DestinationUrlEvidence.fromJson(
          _json['destinationUrl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('domainCall')) {
      domainCall = DomainCallEvidence.fromJson(
          _json['domainCall'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('downloadSize')) {
      downloadSize = DownloadSizeEvidence.fromJson(
          _json['downloadSize'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('httpCall')) {
      httpCall = HttpCallEvidence.fromJson(
          _json['httpCall'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('httpCookie')) {
      httpCookie = HttpCookieEvidence.fromJson(
          _json['httpCookie'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationNotCrawlable != null)
          'destinationNotCrawlable': destinationNotCrawlable!.toJson(),
        if (destinationNotWorking != null)
          'destinationNotWorking': destinationNotWorking!.toJson(),
        if (destinationUrl != null) 'destinationUrl': destinationUrl!.toJson(),
        if (domainCall != null) 'domainCall': domainCall!.toJson(),
        if (downloadSize != null) 'downloadSize': downloadSize!.toJson(),
        if (httpCall != null) 'httpCall': httpCall!.toJson(),
        if (httpCookie != null) 'httpCookie': httpCookie!.toJson(),
      };
}

/// Pretargeting configuration: a set of targeting dimensions applied at the
/// pretargeting stage of the RTB funnel.
///
/// These control which inventory a bidder will receive bid requests for.
class PretargetingConfig {
  /// Targeting modes included by this configuration.
  ///
  /// A bid request must allow all the specified targeting modes. An unset value
  /// allows all bid requests to be sent, regardless of which targeting modes
  /// they allow.
  core.List<core.String>? allowedUserTargetingModes;

  /// Targeting on a subset of app inventory.
  ///
  /// If APP is listed in targeted_environments, the specified targeting is
  /// applied. A maximum of 30,000 app IDs can be targeted. An unset value for
  /// targeting allows all app-based bid requests to be sent. Apps can either be
  /// targeting positively (bid requests will be sent only if the destination
  /// app is listed in the targeting dimension) or negatively (bid requests will
  /// be sent only if the destination app is not listed in the targeting
  /// dimension).
  AppTargeting? appTargeting;

  /// The identifier that corresponds to this pretargeting configuration that
  /// helps buyers track and attribute their spend across their own arbitrary
  /// divisions.
  ///
  /// If a bid request matches more than one configuration, the buyer chooses
  /// which billing_id to attribute each of their bids.
  ///
  /// Output only.
  core.String? billingId;

  /// The diplay name associated with this configuration.
  ///
  /// This name must be unique among all the pretargeting configurations a
  /// bidder has.
  core.String? displayName;

  /// The sensitive content category label IDs excluded in this configuration.
  ///
  /// Bid requests for inventory with any of the specified content label IDs
  /// will not be sent. Refer to this file
  /// https://storage.googleapis.com/adx-rtb-dictionaries/content-labels.txt for
  /// category IDs.
  core.List<core.String>? excludedContentLabelIds;

  /// The geos included or excluded in this configuration defined in
  /// https://storage.googleapis.com/adx-rtb-dictionaries/geo-table.csv
  NumericTargetingDimension? geoTargeting;

  /// Creative dimensions included by this configuration.
  ///
  /// Only bid requests eligible for at least one of the specified creative
  /// dimensions will be sent. An unset value allows all bid requests to be
  /// sent, regardless of creative dimension.
  core.List<CreativeDimensions>? includedCreativeDimensions;

  /// Environments that are being included.
  ///
  /// Bid requests will not be sent for a given environment if it is not
  /// included. Further restrictions can be applied to included environments to
  /// target only a subset of its inventory. An unset value includes all
  /// environments.
  core.List<core.String>? includedEnvironments;

  /// Creative formats included by this configuration.
  ///
  /// Only bid requests eligible for at least one of the specified creative
  /// formats will be sent. An unset value will allow all bid requests to be
  /// sent, regardless of format.
  core.List<core.String>? includedFormats;

  /// The languages included in this configuration, represented by their
  /// language code.
  ///
  /// See https://developers.google.com/adwords/api/docs/appendix/languagecodes.
  core.List<core.String>? includedLanguages;

  /// The mobile operating systems included in this configuration as defined in
  /// https://storage.googleapis.com/adx-rtb-dictionaries/mobile-os.csv
  core.List<core.String>? includedMobileOperatingSystemIds;

  /// The platforms included by this configration.
  ///
  /// Bid requests for devices with the specified platform types will be sent.
  /// An unset value allows all bid requests to be sent, regardless of platform.
  core.List<core.String>? includedPlatforms;

  /// User identifier types included in this configuration.
  ///
  /// At least one of the user identifier types specified in this list must be
  /// available for the bid request to be sent.
  core.List<core.String>? includedUserIdTypes;

  /// The interstitial targeting specified for this configuration.
  ///
  /// The unset value will allow bid requests to be sent regardless of whether
  /// they are for interstitials or not.
  /// Possible string values are:
  /// - "INTERSTITIAL_TARGETING_UNSPECIFIED" : Unspecified interstitial
  /// targeting. Represents an interstitial-agnostic selection.
  /// - "ONLY_INTERSTITIAL_REQUESTS" : Only bid requests for interstitial
  /// inventory should be sent.
  /// - "ONLY_NON_INTERSTITIAL_REQUESTS" : Only bid requests for
  /// non-interstitial inventory should be sent.
  core.String? interstitialTargeting;

  /// Existing included or excluded geos that are invalid.
  ///
  /// Previously targeted geos may become invalid due to privacy restrictions.
  ///
  /// Output only.
  core.List<core.String>? invalidGeoIds;

  /// The maximum QPS threshold for this configuration.
  ///
  /// The bidder should receive no more than this number of bid requests
  /// matching this configuration per second across all their bidding endpoints
  /// among all trading locations. Further information available at
  /// https://developers.google.com/authorized-buyers/rtb/peer-guide
  core.String? maximumQps;

  /// The targeted minimum viewability decile, ranging in values \[0, 10\].
  ///
  /// A value of 5 means that the configuration will only match adslots for
  /// which we predict at least 50% viewability. Values > 10 will be rounded
  /// down to 10. An unset value or a value of 0 indicates that bid requests
  /// will be sent regardless of viewability.
  core.int? minimumViewabilityDecile;

  /// Name of the pretargeting configuration that must follow the pattern
  /// `bidders/{bidder_account_id}/pretargetingConfigs/{config_id}`
  ///
  /// Output only.
  core.String? name;

  /// Targeting on a subset of publisher inventory.
  ///
  /// Publishers can either be targeted positively (bid requests will be sent
  /// only if the publisher is listed in the targeting dimension) or negatively
  /// (bid requests will be sent only if the publisher is not listed in the
  /// targeting dimension). A maximum of 10,000 publisher IDs can be targeted.
  /// Publisher IDs are found in [ads.txt](https://iabtechlab.com/ads-txt/) /
  /// \[app-ads.txt\](https://iabtechlab.com/app-ads-txt/) and in bid requests
  /// in the `BidRequest.publisher_id` field on the
  /// [Google RTB protocol](https://developers.google.com/authorized-buyers/rtb/downloads/realtime-bidding-proto)
  /// or the `BidRequest.site.publisher.id` / `BidRequest.app.publisher.id`
  /// field on the
  /// [OpenRTB protocol](https://developers.google.com/authorized-buyers/rtb/downloads/openrtb-adx-proto).
  StringTargetingDimension? publisherTargeting;

  /// The state of this pretargeting configuration.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Placeholder for undefined state.
  /// - "ACTIVE" : This pretargeting configuration is actively being used to
  /// filter bid requests.
  /// - "SUSPENDED" : This pretargeting configuration is suspended and not used
  /// in serving.
  core.String? state;

  /// The remarketing lists included or excluded in this configuration as
  /// defined in UserList.
  NumericTargetingDimension? userListTargeting;

  /// The verticals included or excluded in this configuration as defined in
  /// https://developers.google.com/authorized-buyers/rtb/downloads/publisher-verticals
  NumericTargetingDimension? verticalTargeting;

  /// Targeting on a subset of site inventory.
  ///
  /// If WEB is listed in included_environments, the specified targeting is
  /// applied. A maximum of 50,000 site URLs can be targeted. An unset value for
  /// targeting allows all web-based bid requests to be sent. Sites can either
  /// be targeting positively (bid requests will be sent only if the destination
  /// site is listed in the targeting dimension) or negatively (bid requests
  /// will be sent only if the destination site is not listed in the
  /// pretargeting configuration).
  StringTargetingDimension? webTargeting;

  PretargetingConfig();

  PretargetingConfig.fromJson(core.Map _json) {
    if (_json.containsKey('allowedUserTargetingModes')) {
      allowedUserTargetingModes =
          (_json['allowedUserTargetingModes'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('appTargeting')) {
      appTargeting = AppTargeting.fromJson(
          _json['appTargeting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('billingId')) {
      billingId = _json['billingId'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('excludedContentLabelIds')) {
      excludedContentLabelIds = (_json['excludedContentLabelIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('geoTargeting')) {
      geoTargeting = NumericTargetingDimension.fromJson(
          _json['geoTargeting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('includedCreativeDimensions')) {
      includedCreativeDimensions =
          (_json['includedCreativeDimensions'] as core.List)
              .map<CreativeDimensions>((value) => CreativeDimensions.fromJson(
                  value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('includedEnvironments')) {
      includedEnvironments = (_json['includedEnvironments'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('includedFormats')) {
      includedFormats = (_json['includedFormats'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('includedLanguages')) {
      includedLanguages = (_json['includedLanguages'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('includedMobileOperatingSystemIds')) {
      includedMobileOperatingSystemIds =
          (_json['includedMobileOperatingSystemIds'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('includedPlatforms')) {
      includedPlatforms = (_json['includedPlatforms'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('includedUserIdTypes')) {
      includedUserIdTypes = (_json['includedUserIdTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('interstitialTargeting')) {
      interstitialTargeting = _json['interstitialTargeting'] as core.String;
    }
    if (_json.containsKey('invalidGeoIds')) {
      invalidGeoIds = (_json['invalidGeoIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('maximumQps')) {
      maximumQps = _json['maximumQps'] as core.String;
    }
    if (_json.containsKey('minimumViewabilityDecile')) {
      minimumViewabilityDecile = _json['minimumViewabilityDecile'] as core.int;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('publisherTargeting')) {
      publisherTargeting = StringTargetingDimension.fromJson(
          _json['publisherTargeting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('userListTargeting')) {
      userListTargeting = NumericTargetingDimension.fromJson(
          _json['userListTargeting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('verticalTargeting')) {
      verticalTargeting = NumericTargetingDimension.fromJson(
          _json['verticalTargeting'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('webTargeting')) {
      webTargeting = StringTargetingDimension.fromJson(
          _json['webTargeting'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedUserTargetingModes != null)
          'allowedUserTargetingModes': allowedUserTargetingModes!,
        if (appTargeting != null) 'appTargeting': appTargeting!.toJson(),
        if (billingId != null) 'billingId': billingId!,
        if (displayName != null) 'displayName': displayName!,
        if (excludedContentLabelIds != null)
          'excludedContentLabelIds': excludedContentLabelIds!,
        if (geoTargeting != null) 'geoTargeting': geoTargeting!.toJson(),
        if (includedCreativeDimensions != null)
          'includedCreativeDimensions': includedCreativeDimensions!
              .map((value) => value.toJson())
              .toList(),
        if (includedEnvironments != null)
          'includedEnvironments': includedEnvironments!,
        if (includedFormats != null) 'includedFormats': includedFormats!,
        if (includedLanguages != null) 'includedLanguages': includedLanguages!,
        if (includedMobileOperatingSystemIds != null)
          'includedMobileOperatingSystemIds': includedMobileOperatingSystemIds!,
        if (includedPlatforms != null) 'includedPlatforms': includedPlatforms!,
        if (includedUserIdTypes != null)
          'includedUserIdTypes': includedUserIdTypes!,
        if (interstitialTargeting != null)
          'interstitialTargeting': interstitialTargeting!,
        if (invalidGeoIds != null) 'invalidGeoIds': invalidGeoIds!,
        if (maximumQps != null) 'maximumQps': maximumQps!,
        if (minimumViewabilityDecile != null)
          'minimumViewabilityDecile': minimumViewabilityDecile!,
        if (name != null) 'name': name!,
        if (publisherTargeting != null)
          'publisherTargeting': publisherTargeting!.toJson(),
        if (state != null) 'state': state!,
        if (userListTargeting != null)
          'userListTargeting': userListTargeting!.toJson(),
        if (verticalTargeting != null)
          'verticalTargeting': verticalTargeting!.toJson(),
        if (webTargeting != null) 'webTargeting': webTargeting!.toJson(),
      };
}

/// A request to stop targeting the provided apps in a specific pretargeting
/// configuration.
///
/// The pretargeting configuration itself specifies how these apps are targeted.
/// in PretargetingConfig.appTargeting.mobileAppTargeting.
class RemoveTargetedAppsRequest {
  /// A list of app IDs to stop targeting in the pretargeting configuration.
  ///
  /// These values will be removed from the list of targeted app IDs in
  /// PretargetingConfig.appTargeting.mobileAppTargeting.values.
  core.List<core.String>? appIds;

  RemoveTargetedAppsRequest();

  RemoveTargetedAppsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('appIds')) {
      appIds = (_json['appIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appIds != null) 'appIds': appIds!,
      };
}

/// A request to stop targeting publishers in a specific configuration.
///
/// The pretargeting configuration itself specifies how these publishers are
/// targeted in PretargetingConfig.publisherTargeting.
class RemoveTargetedPublishersRequest {
  /// A list of publisher IDs to stop targeting in the pretargeting
  /// configuration.
  ///
  /// These values will be removed from the list of targeted publisher IDs in
  /// PretargetingConfig.publisherTargeting.values. Publishers are identified by
  /// their publisher ID from ads.txt / app-ads.txt. See
  /// https://iabtechlab.com/ads-txt/ and https://iabtechlab.com/app-ads-txt/
  /// for more details.
  core.List<core.String>? publisherIds;

  RemoveTargetedPublishersRequest();

  RemoveTargetedPublishersRequest.fromJson(core.Map _json) {
    if (_json.containsKey('publisherIds')) {
      publisherIds = (_json['publisherIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (publisherIds != null) 'publisherIds': publisherIds!,
      };
}

/// A request to stop targeting sites in a specific pretargeting configuration.
///
/// The pretargeting configuration itself specifies how these sites are targeted
/// in PretargetingConfig.webTargeting.
class RemoveTargetedSitesRequest {
  /// A list of site URLs to stop targeting in the pretargeting configuration.
  ///
  /// These values will be removed from the list of targeted URLs in
  /// PretargetingConfig.webTargeting.values.
  core.List<core.String>? sites;

  RemoveTargetedSitesRequest();

  RemoveTargetedSitesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('sites')) {
      sites = (_json['sites'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sites != null) 'sites': sites!,
      };
}

/// Generic targeting with string values used in app, website and publisher
/// targeting.
class StringTargetingDimension {
  /// How the items in this list should be targeted.
  /// Possible string values are:
  /// - "TARGETING_MODE_UNSPECIFIED" : Placeholder for undefined targeting mode.
  /// - "INCLUSIVE" : The inclusive list type. Inventory must match an item in
  /// this list to be targeted.
  /// - "EXCLUSIVE" : The exclusive list type. Inventory must not match any item
  /// in this list to be targeted.
  core.String? targetingMode;

  /// The values specified.
  core.List<core.String>? values;

  StringTargetingDimension();

  StringTargetingDimension.fromJson(core.Map _json) {
    if (_json.containsKey('targetingMode')) {
      targetingMode = _json['targetingMode'] as core.String;
    }
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (targetingMode != null) 'targetingMode': targetingMode!,
        if (values != null) 'values': values!,
      };
}

/// A request to suspend a pretargeting configuration.
///
/// Sets the configuration's state to SUSPENDED.
class SuspendPretargetingConfigRequest {
  SuspendPretargetingConfigRequest();

  SuspendPretargetingConfigRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The URL-level breakdown for the download size.
class UrlDownloadSize {
  /// Download size of the URL in kilobytes.
  core.int? downloadSizeKb;

  /// The normalized URL with query parameters and fragment removed.
  core.String? normalizedUrl;

  UrlDownloadSize();

  UrlDownloadSize.fromJson(core.Map _json) {
    if (_json.containsKey('downloadSizeKb')) {
      downloadSizeKb = _json['downloadSizeKb'] as core.int;
    }
    if (_json.containsKey('normalizedUrl')) {
      normalizedUrl = _json['normalizedUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (downloadSizeKb != null) 'downloadSizeKb': downloadSizeKb!,
        if (normalizedUrl != null) 'normalizedUrl': normalizedUrl!,
      };
}

/// Represents the URL restriction (for the URL captured by the pixel callback)
/// for a user list.
class UrlRestriction {
  /// End date (if specified) of the URL restriction.
  ///
  /// End date should be later than the start date for the date range to be
  /// valid.
  Date? endDate;

  /// The restriction type for the specified URL.
  /// Possible string values are:
  /// - "RESTRICTION_TYPE_UNSPECIFIED" : Default value that should never be
  /// used.
  /// - "CONTAINS" : The tag URL (as recorded by the pixel callback) contains
  /// the specified URL.
  /// - "EQUALS" : The tag URL (as recorded by the pixel callback) exactly
  /// matches the specified URL.
  /// - "STARTS_WITH" : The tag URL (as recorded by the pixel callback) starts
  /// with the specified URL.
  /// - "ENDS_WITH" : The tag URL (as recorded by the pixel callback) ends with
  /// the specified URL.
  /// - "DOES_NOT_EQUAL" : The tag URL (as recorded by the pixel callback) does
  /// not equal the specified URL.
  /// - "DOES_NOT_CONTAIN" : The tag URL (as recorded by the pixel callback)
  /// does not contain the specified URL.
  /// - "DOES_NOT_START_WITH" : The tag URL (as recorded by the pixel callback)
  /// does not start with the specified URL.
  /// - "DOES_NOT_END_WITH" : The tag URL (as recorded by the pixel callback)
  /// does not end with the specified URL.
  core.String? restrictionType;

  /// Start date (if specified) of the URL restriction.
  Date? startDate;

  /// The URL to use for applying the restriction on the user list.
  ///
  /// Required.
  core.String? url;

  UrlRestriction();

  UrlRestriction.fromJson(core.Map _json) {
    if (_json.containsKey('endDate')) {
      endDate = Date.fromJson(
          _json['endDate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('restrictionType')) {
      restrictionType = _json['restrictionType'] as core.String;
    }
    if (_json.containsKey('startDate')) {
      startDate = Date.fromJson(
          _json['startDate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endDate != null) 'endDate': endDate!.toJson(),
        if (restrictionType != null) 'restrictionType': restrictionType!,
        if (startDate != null) 'startDate': startDate!.toJson(),
        if (url != null) 'url': url!,
      };
}

/// Represents an Authorized Buyers user list.
///
/// Authorized Buyers can create/update/list user lists. Once a user list is
/// created in the system, Authorized Buyers can add users to the user list
/// using the bulk uploader API. Alternatively, users can be added by hosting a
/// tag on the advertiser's page.
class UserList {
  /// The description for the user list.
  core.String? description;

  /// Display name of the user list.
  ///
  /// This must be unique across all user lists for a given account.
  ///
  /// Required.
  core.String? displayName;

  /// The number of days a user's cookie stays on the user list.
  ///
  /// The field must be between 0 and 540 inclusive.
  ///
  /// Required.
  core.String? membershipDurationDays;

  /// Name of the user list that must follow the pattern
  /// `buyers/{buyer}/userLists/{user_list}`, where `{buyer}` represents the
  /// account ID of the buyer who owns the user list.
  ///
  /// For a bidder accessing user lists on behalf of a child seat buyer,
  /// `{buyer}` represents the account ID of the child seat buyer. `{user_list}`
  /// is an int64 identifier assigned by Google to uniquely identify a user
  /// list.
  ///
  /// Output only.
  core.String? name;

  /// The status of the user list.
  ///
  /// A new user list starts out as open.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATUS_UNSPECIFIED" : Default value that should never be used.
  /// - "OPEN" : New users can be added to the user list.
  /// - "CLOSED" : New users cannot be added to the user list.
  core.String? status;

  /// The URL restriction for the user list.
  ///
  /// Required.
  UrlRestriction? urlRestriction;

  UserList();

  UserList.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('membershipDurationDays')) {
      membershipDurationDays = _json['membershipDurationDays'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('urlRestriction')) {
      urlRestriction = UrlRestriction.fromJson(
          _json['urlRestriction'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (membershipDurationDays != null)
          'membershipDurationDays': membershipDurationDays!,
        if (name != null) 'name': name!,
        if (status != null) 'status': status!,
        if (urlRestriction != null) 'urlRestriction': urlRestriction!.toJson(),
      };
}

/// Video content for a creative.
class VideoContent {
  /// Video metadata.
  ///
  /// Output only.
  VideoMetadata? videoMetadata;

  /// The URL to fetch a video ad.
  core.String? videoUrl;

  /// The contents of a VAST document for a video ad.
  ///
  /// This document should conform to the VAST 2.0 or 3.0 standard.
  core.String? videoVastXml;

  VideoContent();

  VideoContent.fromJson(core.Map _json) {
    if (_json.containsKey('videoMetadata')) {
      videoMetadata = VideoMetadata.fromJson(
          _json['videoMetadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('videoUrl')) {
      videoUrl = _json['videoUrl'] as core.String;
    }
    if (_json.containsKey('videoVastXml')) {
      videoVastXml = _json['videoVastXml'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (videoMetadata != null) 'videoMetadata': videoMetadata!.toJson(),
        if (videoUrl != null) 'videoUrl': videoUrl!,
        if (videoVastXml != null) 'videoVastXml': videoVastXml!,
      };
}

/// Video metadata for a creative.
class VideoMetadata {
  /// The duration of the ad.
  ///
  /// Can be used to filter the response of the creatives.list method.
  core.String? duration;

  /// Is this a valid VAST ad? Can be used to filter the response of the
  /// creatives.list method.
  core.bool? isValidVast;

  /// Is this a VPAID ad? Can be used to filter the response of the
  /// creatives.list method.
  core.bool? isVpaid;

  /// The list of all media files declared in the VAST.
  ///
  /// If there are multiple VASTs in a wrapper chain, this includes the media
  /// files from the deepest one in the chain.
  core.List<MediaFile>? mediaFiles;

  /// The minimum duration that the user has to watch before being able to skip
  /// this ad.
  ///
  /// If the field is not set, the ad is not skippable. If the field is set, the
  /// ad is skippable. Can be used to filter the response of the creatives.list
  /// method.
  core.String? skipOffset;

  /// The maximum VAST version across all wrapped VAST documents.
  ///
  /// Can be used to filter the response of the creatives.list method.
  /// Possible string values are:
  /// - "VAST_VERSION_UNSPECIFIED" : Default value that should never be used.
  /// - "VAST_VERSION_1_0" : VAST 1.0
  /// - "VAST_VERSION_2_0" : VAST 2.0
  /// - "VAST_VERSION_3_0" : VAST 3.0
  /// - "VAST_VERSION_4_0" : VAST 4.0
  core.String? vastVersion;

  VideoMetadata();

  VideoMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('duration')) {
      duration = _json['duration'] as core.String;
    }
    if (_json.containsKey('isValidVast')) {
      isValidVast = _json['isValidVast'] as core.bool;
    }
    if (_json.containsKey('isVpaid')) {
      isVpaid = _json['isVpaid'] as core.bool;
    }
    if (_json.containsKey('mediaFiles')) {
      mediaFiles = (_json['mediaFiles'] as core.List)
          .map<MediaFile>((value) =>
              MediaFile.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('skipOffset')) {
      skipOffset = _json['skipOffset'] as core.String;
    }
    if (_json.containsKey('vastVersion')) {
      vastVersion = _json['vastVersion'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (duration != null) 'duration': duration!,
        if (isValidVast != null) 'isValidVast': isValidVast!,
        if (isVpaid != null) 'isVpaid': isVpaid!,
        if (mediaFiles != null)
          'mediaFiles': mediaFiles!.map((value) => value.toJson()).toList(),
        if (skipOffset != null) 'skipOffset': skipOffset!,
        if (vastVersion != null) 'vastVersion': vastVersion!,
      };
}

/// A request to receive push notifications when any of the creatives belonging
/// to the bidder changes status.
class WatchCreativesRequest {
  WatchCreativesRequest();

  WatchCreativesRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A response for the request to receive push notification when a bidder's
/// creatives change status.
class WatchCreativesResponse {
  /// The Pub/Sub subscription that can be used to pull creative status
  /// notifications.
  ///
  /// This would be of the format
  /// `projects/{project_id}/subscriptions/{subscription_id}`. Subscription is
  /// created with pull delivery. All service accounts belonging to the bidder
  /// will have read access to this subscription. Subscriptions that are
  /// inactive for more than 90 days will be disabled. Please use watchCreatives
  /// to re-enable the subscription.
  core.String? subscription;

  /// The Pub/Sub topic that will be used to publish creative serving status
  /// notifications.
  ///
  /// This would be of the format `projects/{project_id}/topics/{topic_id}`.
  core.String? topic;

  WatchCreativesResponse();

  WatchCreativesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('subscription')) {
      subscription = _json['subscription'] as core.String;
    }
    if (_json.containsKey('topic')) {
      topic = _json['topic'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (subscription != null) 'subscription': subscription!,
        if (topic != null) 'topic': topic!,
      };
}

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

/// Cloud Channel API - v1
///
/// For more information, see <https://cloud.google.com/channel>
///
/// Create an instance of [CloudchannelApi] to access these resources:
///
/// - [AccountsResource]
///   - [AccountsChannelPartnerLinksResource]
///     - [AccountsChannelPartnerLinksCustomersResource]
///   - [AccountsCustomersResource]
///     - [AccountsCustomersEntitlementsResource]
///   - [AccountsOffersResource]
/// - [OperationsResource]
/// - [ProductsResource]
///   - [ProductsSkusResource]
library cloudchannel.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

class CloudchannelApi {
  /// Manage users on your domain
  static const appsOrderScope = 'https://www.googleapis.com/auth/apps.order';

  final commons.ApiRequester _requester;

  AccountsResource get accounts => AccountsResource(_requester);
  OperationsResource get operations => OperationsResource(_requester);
  ProductsResource get products => ProductsResource(_requester);

  CloudchannelApi(http.Client client,
      {core.String rootUrl = 'https://cloudchannel.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AccountsResource {
  final commons.ApiRequester _requester;

  AccountsChannelPartnerLinksResource get channelPartnerLinks =>
      AccountsChannelPartnerLinksResource(_requester);
  AccountsCustomersResource get customers =>
      AccountsCustomersResource(_requester);
  AccountsOffersResource get offers => AccountsOffersResource(_requester);

  AccountsResource(commons.ApiRequester client) : _requester = client;

  /// Confirms the existence of Cloud Identity accounts based on the domain and
  /// if the Cloud Identity accounts are owned by the reseller.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The reseller account making the
  /// request is different from the reseller account in the API request. *
  /// INVALID_ARGUMENT: Required request parameters are missing or invalid. *
  /// INVALID_VALUE: Invalid domain value in the request. Return value: A list
  /// of CloudIdentityCustomerAccount resources for the domain (may be empty)
  /// Note: in the v1alpha1 version of the API, a NOT_FOUND error returns if no
  /// CloudIdentityCustomerAccount resources match the domain.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The reseller account's resource name. Parent uses the
  /// format: accounts/{account_id}
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleCloudChannelV1CheckCloudIdentityAccountsExistResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1CheckCloudIdentityAccountsExistResponse>
      checkCloudIdentityAccountsExist(
    GoogleCloudChannelV1CheckCloudIdentityAccountsExistRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$parent') +
        ':checkCloudIdentityAccountsExist';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1CheckCloudIdentityAccountsExistResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists service accounts with subscriber privileges on the Cloud Pub/Sub
  /// topic created for this Channel Services account.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The reseller account making the
  /// request and the provided reseller account are different, or the
  /// impersonated user is not a super admin. * INVALID_ARGUMENT: Required
  /// request parameters are missing or invalid. * NOT_FOUND: The topic resource
  /// doesn't exist. * INTERNAL: Any non-user error related to a technical issue
  /// in the backend. Contact Cloud Channel support. * UNKNOWN: Any non-user
  /// error related to a technical issue in the backend. Contact Cloud Channel
  /// support. Return value: A list of service email addresses.
  ///
  /// Request parameters:
  ///
  /// [account] - Required. Resource name of the account.
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of service accounts to return.
  /// The service may return fewer than this value. If unspecified, returns at
  /// most 100 service accounts. The maximum value is 1000; the server will
  /// coerce values above 1000.
  ///
  /// [pageToken] - Optional. A page token, received from a previous
  /// `ListSubscribers` call. Provide this to retrieve the subsequent page. When
  /// paginating, all other parameters provided to `ListSubscribers` must match
  /// the call that provided the page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ListSubscribersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ListSubscribersResponse> listSubscribers(
    core.String account, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$account') + ':listSubscribers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1ListSubscribersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List TransferableOffers of a customer based on Cloud Identity ID or
  /// Customer Name in the request.
  ///
  /// Use this method when a reseller gets the entitlement information of an
  /// unowned customer. The reseller should provide the customer's Cloud
  /// Identity ID or Customer Name. Possible error codes: * PERMISSION_DENIED: *
  /// The customer doesn't belong to the reseller and has no auth token. * The
  /// supplied auth token is invalid. * The reseller account making the request
  /// is different from the reseller account in the query. * INVALID_ARGUMENT:
  /// Required request parameters are missing or invalid. Return value: List of
  /// TransferableOffer for the given customer and SKU.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the reseller's account.
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ListTransferableOffersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ListTransferableOffersResponse>
      listTransferableOffers(
    GoogleCloudChannelV1ListTransferableOffersRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + ':listTransferableOffers';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1ListTransferableOffersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List TransferableSkus of a customer based on the Cloud Identity ID or
  /// Customer Name in the request.
  ///
  /// Use this method to list the entitlements information of an unowned
  /// customer. You should provide the customer's Cloud Identity ID or Customer
  /// Name. Possible error codes: * PERMISSION_DENIED: * The customer doesn't
  /// belong to the reseller and has no auth token. * The supplied auth token is
  /// invalid. * The reseller account making the request is different from the
  /// reseller account in the query. * INVALID_ARGUMENT: Required request
  /// parameters are missing or invalid. Return value: A list of the customer's
  /// TransferableSku.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The reseller account's resource name. Parent uses the
  /// format: accounts/{account_id}
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ListTransferableSkusResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ListTransferableSkusResponse>
      listTransferableSkus(
    GoogleCloudChannelV1ListTransferableSkusRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + ':listTransferableSkus';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1ListTransferableSkusResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Registers a service account with subscriber privileges on the Cloud
  /// Pub/Sub topic for this Channel Services account.
  ///
  /// After you create a subscriber, you get the events through SubscriberEvent
  /// Possible error codes: * PERMISSION_DENIED: The reseller account making the
  /// request and the provided reseller account are different, or the
  /// impersonated user is not a super admin. * INVALID_ARGUMENT: Required
  /// request parameters are missing or invalid. * INTERNAL: Any non-user error
  /// related to a technical issue in the backend. Contact Cloud Channel
  /// support. * UNKNOWN: Any non-user error related to a technical issue in the
  /// backend. Contact Cloud Channel support. Return value: The topic name with
  /// the registered service email address.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [account] - Required. Resource name of the account.
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1RegisterSubscriberResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1RegisterSubscriberResponse> register(
    GoogleCloudChannelV1RegisterSubscriberRequest request,
    core.String account, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$account') + ':register';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1RegisterSubscriberResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Unregisters a service account with subscriber privileges on the Cloud
  /// Pub/Sub topic created for this Channel Services account.
  ///
  /// If there are no service accounts left with subscriber privileges, this
  /// deletes the topic. You can call ListSubscribers to check for these
  /// accounts. Possible error codes: * PERMISSION_DENIED: The reseller account
  /// making the request and the provided reseller account are different, or the
  /// impersonated user is not a super admin. * INVALID_ARGUMENT: Required
  /// request parameters are missing or invalid. * NOT_FOUND: The topic resource
  /// doesn't exist. * INTERNAL: Any non-user error related to a technical issue
  /// in the backend. Contact Cloud Channel support. * UNKNOWN: Any non-user
  /// error related to a technical issue in the backend. Contact Cloud Channel
  /// support. Return value: The topic name that unregistered the service email
  /// address. Returns a success response if the service email address wasn't
  /// registered with the topic.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [account] - Required. Resource name of the account.
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1UnregisterSubscriberResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1UnregisterSubscriberResponse> unregister(
    GoogleCloudChannelV1UnregisterSubscriberRequest request,
    core.String account, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$account') + ':unregister';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1UnregisterSubscriberResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccountsChannelPartnerLinksResource {
  final commons.ApiRequester _requester;

  AccountsChannelPartnerLinksCustomersResource get customers =>
      AccountsChannelPartnerLinksCustomersResource(_requester);

  AccountsChannelPartnerLinksResource(commons.ApiRequester client)
      : _requester = client;

  /// Initiates a channel partner link between a distributor and a reseller, or
  /// between resellers in an n-tier reseller channel.
  ///
  /// Invited partners need to follow the invite_link_uri provided in the
  /// response to accept. After accepting the invitation, a link is set up
  /// between the two parties. You must be a distributor to call this method.
  /// Possible error codes: * PERMISSION_DENIED: The reseller account making the
  /// request is different from the reseller account in the API request. *
  /// INVALID_ARGUMENT: Required request parameters are missing or invalid. *
  /// ALREADY_EXISTS: The ChannelPartnerLink sent in the request already exists.
  /// * NOT_FOUND: No Cloud Identity customer exists for provided domain. *
  /// INTERNAL: Any non-user error related to a technical issue in the backend.
  /// Contact Cloud Channel support. * UNKNOWN: Any non-user error related to a
  /// technical issue in the backend. Contact Cloud Channel support. Return
  /// value: The new ChannelPartnerLink resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Create a channel partner link for the provided
  /// reseller account's resource name. Parent uses the format:
  /// accounts/{account_id}
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ChannelPartnerLink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ChannelPartnerLink> create(
    GoogleCloudChannelV1ChannelPartnerLink request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/channelPartnerLinks';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1ChannelPartnerLink.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the requested ChannelPartnerLink resource.
  ///
  /// You must be a distributor to call this method. Possible error codes: *
  /// PERMISSION_DENIED: The reseller account making the request is different
  /// from the reseller account in the API request. * INVALID_ARGUMENT: Required
  /// request parameters are missing or invalid. * NOT_FOUND: ChannelPartnerLink
  /// resource not found because of an invalid channel partner link name. Return
  /// value: The ChannelPartnerLink resource.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the channel partner link to
  /// retrieve. Name uses the format:
  /// accounts/{account_id}/channelPartnerLinks/{id} where {id} is the Cloud
  /// Identity ID of the partner.
  /// Value must have pattern `^accounts/\[^/\]+/channelPartnerLinks/\[^/\]+$`.
  ///
  /// [view] - Optional. The level of granularity the ChannelPartnerLink will
  /// display.
  /// Possible string values are:
  /// - "UNSPECIFIED" : The default / unset value. The API will default to the
  /// BASIC view.
  /// - "BASIC" : Includes all fields except the
  /// ChannelPartnerLink.channel_partner_cloud_identity_info.
  /// - "FULL" : Includes all fields.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ChannelPartnerLink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ChannelPartnerLink> get(
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
    return GoogleCloudChannelV1ChannelPartnerLink.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List ChannelPartnerLinks belonging to a distributor.
  ///
  /// You must be a distributor to call this method. Possible error codes: *
  /// PERMISSION_DENIED: The reseller account making the request is different
  /// from the reseller account in the API request. * INVALID_ARGUMENT: Required
  /// request parameters are missing or invalid. Return value: The list of the
  /// distributor account's ChannelPartnerLink resources.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the reseller account for listing
  /// channel partner links. Parent uses the format: accounts/{account_id}
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. Requested page size. Server might return fewer
  /// results than requested. If unspecified, server will pick a default size
  /// (25). The maximum value is 200; the server will coerce values above 200.
  ///
  /// [pageToken] - Optional. A token for a page of results other than the first
  /// page. Obtained using ListChannelPartnerLinksResponse.next_page_token of
  /// the previous CloudChannelService.ListChannelPartnerLinks call.
  ///
  /// [view] - Optional. The level of granularity the ChannelPartnerLink will
  /// display.
  /// Possible string values are:
  /// - "UNSPECIFIED" : The default / unset value. The API will default to the
  /// BASIC view.
  /// - "BASIC" : Includes all fields except the
  /// ChannelPartnerLink.channel_partner_cloud_identity_info.
  /// - "FULL" : Includes all fields.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ListChannelPartnerLinksResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ListChannelPartnerLinksResponse> list(
    core.String parent, {
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

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/channelPartnerLinks';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1ListChannelPartnerLinksResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a channel partner link.
  ///
  /// Distributors call this method to change a link's status. For example, to
  /// suspend a partner link. You must be a distributor to call this method.
  /// Possible error codes: * PERMISSION_DENIED: The reseller account making the
  /// request is different from the reseller account in the API request. *
  /// INVALID_ARGUMENT: * Required request parameters are missing or invalid. *
  /// Link state cannot change from invited to active or suspended. * Cannot
  /// send reseller_cloud_identity_id, invite_url, or name in update mask. *
  /// NOT_FOUND: ChannelPartnerLink resource not found. * INTERNAL: Any non-user
  /// error related to a technical issue in the backend. Contact Cloud Channel
  /// support. * UNKNOWN: Any non-user error related to a technical issue in the
  /// backend. Contact Cloud Channel support. Return value: The updated
  /// ChannelPartnerLink resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the channel partner link to
  /// cancel. Name uses the format:
  /// accounts/{account_id}/channelPartnerLinks/{id} where {id} is the Cloud
  /// Identity ID of the partner.
  /// Value must have pattern `^accounts/\[^/\]+/channelPartnerLinks/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ChannelPartnerLink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ChannelPartnerLink> patch(
    GoogleCloudChannelV1UpdateChannelPartnerLinkRequest request,
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
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1ChannelPartnerLink.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccountsChannelPartnerLinksCustomersResource {
  final commons.ApiRequester _requester;

  AccountsChannelPartnerLinksCustomersResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new Customer resource under the reseller or distributor account.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The reseller account making the
  /// request is different from the reseller account in the API request. *
  /// INVALID_ARGUMENT: * Required request parameters are missing or invalid. *
  /// Domain field value doesn't match the primary email domain. Return value:
  /// The newly created Customer resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of reseller account in which to
  /// create the customer. Parent uses the format: accounts/{account_id}
  /// Value must have pattern `^accounts/\[^/\]+/channelPartnerLinks/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1Customer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1Customer> create(
    GoogleCloudChannelV1Customer request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/customers';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1Customer.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the given Customer permanently.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The account making the request
  /// does not own this customer. * INVALID_ARGUMENT: Required request
  /// parameters are missing or invalid. * FAILED_PRECONDITION: The customer has
  /// existing entitlements. * NOT_FOUND: No Customer resource found for the
  /// name in the request.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the customer to delete.
  /// Value must have pattern
  /// `^accounts/\[^/\]+/channelPartnerLinks/\[^/\]+/customers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
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
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the requested Customer resource.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The reseller account making the
  /// request is different from the reseller account in the API request. *
  /// INVALID_ARGUMENT: Required request parameters are missing or invalid. *
  /// NOT_FOUND: The customer resource doesn't exist. Usually the result of an
  /// invalid name parameter. Return value: The Customer resource.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the customer to retrieve. Name
  /// uses the format: accounts/{account_id}/customers/{customer_id}
  /// Value must have pattern
  /// `^accounts/\[^/\]+/channelPartnerLinks/\[^/\]+/customers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1Customer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1Customer> get(
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
    return GoogleCloudChannelV1Customer.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List Customers.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The reseller account making the
  /// request is different from the reseller account in the API request. *
  /// INVALID_ARGUMENT: Required request parameters are missing or invalid.
  /// Return value: List of Customers, or an empty list if there are no
  /// customers.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the reseller account to list
  /// customers from. Parent uses the format: accounts/{account_id}.
  /// Value must have pattern `^accounts/\[^/\]+/channelPartnerLinks/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of customers to return. The
  /// service may return fewer than this value. If unspecified, returns at most
  /// 10 customers. The maximum value is 50.
  ///
  /// [pageToken] - Optional. A token identifying a page of results other than
  /// the first page. Obtained through ListCustomersResponse.next_page_token of
  /// the previous CloudChannelService.ListCustomers call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ListCustomersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ListCustomersResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/customers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1ListCustomersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing Customer resource for the reseller or distributor.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The reseller account making the
  /// request is different from the reseller account in the API request. *
  /// INVALID_ARGUMENT: Required request parameters are missing or invalid. *
  /// NOT_FOUND: No Customer resource found for the name in the request. Return
  /// value: The updated Customer resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only. Resource name of the customer. Format:
  /// accounts/{account_id}/customers/{customer_id}
  /// Value must have pattern
  /// `^accounts/\[^/\]+/channelPartnerLinks/\[^/\]+/customers/\[^/\]+$`.
  ///
  /// [updateMask] - The update mask that applies to the resource. Optional.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1Customer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1Customer> patch(
    GoogleCloudChannelV1Customer request,
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
    return GoogleCloudChannelV1Customer.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccountsCustomersResource {
  final commons.ApiRequester _requester;

  AccountsCustomersEntitlementsResource get entitlements =>
      AccountsCustomersEntitlementsResource(_requester);

  AccountsCustomersResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new Customer resource under the reseller or distributor account.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The reseller account making the
  /// request is different from the reseller account in the API request. *
  /// INVALID_ARGUMENT: * Required request parameters are missing or invalid. *
  /// Domain field value doesn't match the primary email domain. Return value:
  /// The newly created Customer resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of reseller account in which to
  /// create the customer. Parent uses the format: accounts/{account_id}
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1Customer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1Customer> create(
    GoogleCloudChannelV1Customer request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/customers';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1Customer.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the given Customer permanently.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The account making the request
  /// does not own this customer. * INVALID_ARGUMENT: Required request
  /// parameters are missing or invalid. * FAILED_PRECONDITION: The customer has
  /// existing entitlements. * NOT_FOUND: No Customer resource found for the
  /// name in the request.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the customer to delete.
  /// Value must have pattern `^accounts/\[^/\]+/customers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
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
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the requested Customer resource.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The reseller account making the
  /// request is different from the reseller account in the API request. *
  /// INVALID_ARGUMENT: Required request parameters are missing or invalid. *
  /// NOT_FOUND: The customer resource doesn't exist. Usually the result of an
  /// invalid name parameter. Return value: The Customer resource.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the customer to retrieve. Name
  /// uses the format: accounts/{account_id}/customers/{customer_id}
  /// Value must have pattern `^accounts/\[^/\]+/customers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1Customer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1Customer> get(
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
    return GoogleCloudChannelV1Customer.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List Customers.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The reseller account making the
  /// request is different from the reseller account in the API request. *
  /// INVALID_ARGUMENT: Required request parameters are missing or invalid.
  /// Return value: List of Customers, or an empty list if there are no
  /// customers.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the reseller account to list
  /// customers from. Parent uses the format: accounts/{account_id}.
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of customers to return. The
  /// service may return fewer than this value. If unspecified, returns at most
  /// 10 customers. The maximum value is 50.
  ///
  /// [pageToken] - Optional. A token identifying a page of results other than
  /// the first page. Obtained through ListCustomersResponse.next_page_token of
  /// the previous CloudChannelService.ListCustomers call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ListCustomersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ListCustomersResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/customers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1ListCustomersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the following: * Offers that you can purchase for a customer.
  ///
  /// * Offers that you can change for an entitlement. Possible error codes: *
  /// PERMISSION_DENIED: The customer doesn't belong to the reseller *
  /// INVALID_ARGUMENT: Required request parameters are missing or invalid.
  ///
  /// Request parameters:
  ///
  /// [customer] - Required. The resource name of the customer to list Offers
  /// for. Format: accounts/{account_id}/customers/{customer_id}.
  /// Value must have pattern `^accounts/\[^/\]+/customers/\[^/\]+$`.
  ///
  /// [changeOfferPurchase_entitlement] - Required. Resource name of the
  /// entitlement. Format:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}
  ///
  /// [changeOfferPurchase_newSku] - Optional. Resource name of the new target
  /// SKU. Provide this SKU when upgrading or downgrading an entitlement.
  /// Format: products/{product_id}/skus/{sku_id}
  ///
  /// [createEntitlementPurchase_sku] - Required. SKU that the result should be
  /// restricted to. Format: products/{product_id}/skus/{sku_id}.
  ///
  /// [languageCode] - Optional. The BCP-47 language code. For example, "en-US".
  /// The response will localize in the corresponding language code, if
  /// specified. The default value is "en-US".
  ///
  /// [pageSize] - Optional. Requested page size. Server might return fewer
  /// results than requested. If unspecified, returns at most 100 Offers. The
  /// maximum value is 1000; the server will coerce values above 1000.
  ///
  /// [pageToken] - Optional. A token for a page of results other than the first
  /// page.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ListPurchasableOffersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ListPurchasableOffersResponse>
      listPurchasableOffers(
    core.String customer, {
    core.String? changeOfferPurchase_entitlement,
    core.String? changeOfferPurchase_newSku,
    core.String? createEntitlementPurchase_sku,
    core.String? languageCode,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (changeOfferPurchase_entitlement != null)
        'changeOfferPurchase.entitlement': [changeOfferPurchase_entitlement],
      if (changeOfferPurchase_newSku != null)
        'changeOfferPurchase.newSku': [changeOfferPurchase_newSku],
      if (createEntitlementPurchase_sku != null)
        'createEntitlementPurchase.sku': [createEntitlementPurchase_sku],
      if (languageCode != null) 'languageCode': [languageCode],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$customer') + ':listPurchasableOffers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1ListPurchasableOffersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the following: * SKUs that you can purchase for a customer * SKUs
  /// that you can upgrade or downgrade for an entitlement.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The customer doesn't belong to
  /// the reseller. * INVALID_ARGUMENT: Required request parameters are missing
  /// or invalid.
  ///
  /// Request parameters:
  ///
  /// [customer] - Required. The resource name of the customer to list SKUs for.
  /// Format: accounts/{account_id}/customers/{customer_id}.
  /// Value must have pattern `^accounts/\[^/\]+/customers/\[^/\]+$`.
  ///
  /// [changeOfferPurchase_changeType] - Required. Change Type for the
  /// entitlement.
  /// Possible string values are:
  /// - "CHANGE_TYPE_UNSPECIFIED" : Not used.
  /// - "UPGRADE" : SKU is an upgrade on the current entitlement.
  /// - "DOWNGRADE" : SKU is a downgrade on the current entitlement.
  ///
  /// [changeOfferPurchase_entitlement] - Required. Resource name of the
  /// entitlement. Format:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}
  ///
  /// [createEntitlementPurchase_product] - Required. List SKUs belonging to
  /// this Product. Format: products/{product_id}. Supports products/- to
  /// retrieve SKUs for all products.
  ///
  /// [languageCode] - Optional. The BCP-47 language code. For example, "en-US".
  /// The response will localize in the corresponding language code, if
  /// specified. The default value is "en-US".
  ///
  /// [pageSize] - Optional. Requested page size. Server might return fewer
  /// results than requested. If unspecified, returns at most 100 SKUs. The
  /// maximum value is 1000; the server will coerce values above 1000.
  ///
  /// [pageToken] - Optional. A token for a page of results other than the first
  /// page.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ListPurchasableSkusResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ListPurchasableSkusResponse>
      listPurchasableSkus(
    core.String customer, {
    core.String? changeOfferPurchase_changeType,
    core.String? changeOfferPurchase_entitlement,
    core.String? createEntitlementPurchase_product,
    core.String? languageCode,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (changeOfferPurchase_changeType != null)
        'changeOfferPurchase.changeType': [changeOfferPurchase_changeType],
      if (changeOfferPurchase_entitlement != null)
        'changeOfferPurchase.entitlement': [changeOfferPurchase_entitlement],
      if (createEntitlementPurchase_product != null)
        'createEntitlementPurchase.product': [
          createEntitlementPurchase_product
        ],
      if (languageCode != null) 'languageCode': [languageCode],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$customer') + ':listPurchasableSkus';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1ListPurchasableSkusResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing Customer resource for the reseller or distributor.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The reseller account making the
  /// request is different from the reseller account in the API request. *
  /// INVALID_ARGUMENT: Required request parameters are missing or invalid. *
  /// NOT_FOUND: No Customer resource found for the name in the request. Return
  /// value: The updated Customer resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only. Resource name of the customer. Format:
  /// accounts/{account_id}/customers/{customer_id}
  /// Value must have pattern `^accounts/\[^/\]+/customers/\[^/\]+$`.
  ///
  /// [updateMask] - The update mask that applies to the resource. Optional.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1Customer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1Customer> patch(
    GoogleCloudChannelV1Customer request,
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
    return GoogleCloudChannelV1Customer.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a Cloud Identity for the given customer using the customer's
  /// information, or the information provided here.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The customer doesn't belong to
  /// the reseller. * INVALID_ARGUMENT: Required request parameters are missing
  /// or invalid. * NOT_FOUND: The customer was not found. * ALREADY_EXISTS: The
  /// customer's primary email already exists. Retry after changing the
  /// customer's primary contact email. * INTERNAL: Any non-user error related
  /// to a technical issue in the backend. Contact Cloud Channel support. *
  /// UNKNOWN: Any non-user error related to a technical issue in the backend.
  /// Contact Cloud Channel support. Return value: The ID of a long-running
  /// operation. To get the results of the operation, call the GetOperation
  /// method of CloudChannelOperationsService. The Operation metadata contains
  /// an instance of OperationMetadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - Required. Resource name of the customer. Format:
  /// accounts/{account_id}/customers/{customer_id}
  /// Value must have pattern `^accounts/\[^/\]+/customers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> provisionCloudIdentity(
    GoogleCloudChannelV1ProvisionCloudIdentityRequest request,
    core.String customer, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$customer') + ':provisionCloudIdentity';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Transfers customer entitlements to new reseller.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The customer doesn't belong to
  /// the reseller. * INVALID_ARGUMENT: Required request parameters are missing
  /// or invalid. * NOT_FOUND: The customer or offer resource was not found. *
  /// ALREADY_EXISTS: The SKU was already transferred for the customer. *
  /// CONDITION_NOT_MET or FAILED_PRECONDITION: * The SKU requires domain
  /// verification to transfer, but the domain is not verified. * An Add-On SKU
  /// (example, Vault or Drive) is missing the pre-requisite SKU (example, G
  /// Suite Basic). * (Developer accounts only) Reseller and resold domain must
  /// meet the following naming requirements: * Domain names must start with
  /// goog-test. * Domain names must include the reseller domain. * Specify all
  /// transferring entitlements. * INTERNAL: Any non-user error related to a
  /// technical issue in the backend. Contact Cloud Channel support. * UNKNOWN:
  /// Any non-user error related to a technical issue in the backend. Contact
  /// Cloud Channel support. Return value: The ID of a long-running operation.
  /// To get the results of the operation, call the GetOperation method of
  /// CloudChannelOperationsService. The Operation metadata will contain an
  /// instance of OperationMetadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the reseller's customer account
  /// that will receive transferred entitlements. Parent uses the format:
  /// accounts/{account_id}/customers/{customer_id}
  /// Value must have pattern `^accounts/\[^/\]+/customers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> transferEntitlements(
    GoogleCloudChannelV1TransferEntitlementsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + ':transferEntitlements';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Transfers customer entitlements from their current reseller to Google.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The customer doesn't belong to
  /// the reseller. * INVALID_ARGUMENT: Required request parameters are missing
  /// or invalid. * NOT_FOUND: The customer or offer resource was not found. *
  /// ALREADY_EXISTS: The SKU was already transferred for the customer. *
  /// CONDITION_NOT_MET or FAILED_PRECONDITION: * The SKU requires domain
  /// verification to transfer, but the domain is not verified. * An Add-On SKU
  /// (example, Vault or Drive) is missing the pre-requisite SKU (example, G
  /// Suite Basic). * (Developer accounts only) Reseller and resold domain must
  /// meet the following naming requirements: * Domain names must start with
  /// goog-test. * Domain names must include the reseller domain. * INTERNAL:
  /// Any non-user error related to a technical issue in the backend. Contact
  /// Cloud Channel support. * UNKNOWN: Any non-user error related to a
  /// technical issue in the backend. Contact Cloud Channel support. Return
  /// value: The ID of a long-running operation. To get the results of the
  /// operation, call the GetOperation method of CloudChannelOperationsService.
  /// The response will contain google.protobuf.Empty on success. The Operation
  /// metadata will contain an instance of OperationMetadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the reseller's customer account
  /// where the entitlements transfer from. Parent uses the format:
  /// accounts/{account_id}/customers/{customer_id}
  /// Value must have pattern `^accounts/\[^/\]+/customers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> transferEntitlementsToGoogle(
    GoogleCloudChannelV1TransferEntitlementsToGoogleRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$parent') +
        ':transferEntitlementsToGoogle';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccountsCustomersEntitlementsResource {
  final commons.ApiRequester _requester;

  AccountsCustomersEntitlementsResource(commons.ApiRequester client)
      : _requester = client;

  /// Activates a previously suspended entitlement.
  ///
  /// Entitlements suspended for pending ToS acceptance can't be activated using
  /// this method. An entitlement activation is a long-running operation and it
  /// updates the state of the customer entitlement. Possible error codes: *
  /// PERMISSION_DENIED: The reseller account making the request is different
  /// from the reseller account in the API request. * INVALID_ARGUMENT: Required
  /// request parameters are missing or invalid. * NOT_FOUND: Entitlement
  /// resource not found. * SUSPENSION_NOT_RESELLER_INITIATED: Can only activate
  /// reseller-initiated suspensions and entitlements that have accepted the
  /// TOS. * NOT_SUSPENDED: Can only activate suspended entitlements not in an
  /// ACTIVE state. * INTERNAL: Any non-user error related to a technical issue
  /// in the backend. Contact Cloud Channel support. * UNKNOWN: Any non-user
  /// error related to a technical issue in the backend. Contact Cloud Channel
  /// support. Return value: The ID of a long-running operation. To get the
  /// results of the operation, call the GetOperation method of
  /// CloudChannelOperationsService. The Operation metadata will contain an
  /// instance of OperationMetadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the entitlement to activate. Name
  /// uses the format:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}
  /// Value must have pattern
  /// `^accounts/\[^/\]+/customers/\[^/\]+/entitlements/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> activate(
    GoogleCloudChannelV1ActivateEntitlementRequest request,
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
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Cancels a previously fulfilled entitlement.
  ///
  /// An entitlement cancellation is a long-running operation. Possible error
  /// codes: * PERMISSION_DENIED: The reseller account making the request is
  /// different from the reseller account in the API request. *
  /// FAILED_PRECONDITION: There are Google Cloud projects linked to the Google
  /// Cloud entitlement's Cloud Billing subaccount. * INVALID_ARGUMENT: Required
  /// request parameters are missing or invalid. * NOT_FOUND: Entitlement
  /// resource not found. * DELETION_TYPE_NOT_ALLOWED: Cancel is only allowed
  /// for Google Workspace add-ons, or entitlements for Google Cloud's
  /// development platform. * INTERNAL: Any non-user error related to a
  /// technical issue in the backend. Contact Cloud Channel support. * UNKNOWN:
  /// Any non-user error related to a technical issue in the backend. Contact
  /// Cloud Channel support. Return value: The ID of a long-running operation.
  /// To get the results of the operation, call the GetOperation method of
  /// CloudChannelOperationsService. The response will contain
  /// google.protobuf.Empty on success. The Operation metadata will contain an
  /// instance of OperationMetadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the entitlement to cancel. Name
  /// uses the format:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}
  /// Value must have pattern
  /// `^accounts/\[^/\]+/customers/\[^/\]+/entitlements/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> cancel(
    GoogleCloudChannelV1CancelEntitlementRequest request,
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
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the Offer for an existing customer entitlement.
  ///
  /// An entitlement update is a long-running operation and it updates the
  /// entitlement as a result of fulfillment. Possible error codes: *
  /// PERMISSION_DENIED: The customer doesn't belong to the reseller. *
  /// INVALID_ARGUMENT: Required request parameters are missing or invalid. *
  /// NOT_FOUND: Offer or Entitlement resource not found. * INTERNAL: Any
  /// non-user error related to a technical issue in the backend. Contact Cloud
  /// Channel support. * UNKNOWN: Any non-user error related to a technical
  /// issue in the backend. Contact Cloud Channel support. Return value: The ID
  /// of a long-running operation. To get the results of the operation, call the
  /// GetOperation method of CloudChannelOperationsService. The Operation
  /// metadata will contain an instance of OperationMetadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the entitlement to update. Name
  /// uses the format:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}
  /// Value must have pattern
  /// `^accounts/\[^/\]+/customers/\[^/\]+/entitlements/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> changeOffer(
    GoogleCloudChannelV1ChangeOfferRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':changeOffer';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Change parameters of the entitlement.
  ///
  /// An entitlement update is a long-running operation and it updates the
  /// entitlement as a result of fulfillment. Possible error codes: *
  /// PERMISSION_DENIED: The customer doesn't belong to the reseller. *
  /// INVALID_ARGUMENT: Required request parameters are missing or invalid. For
  /// example, the number of seats being changed is greater than the allowed
  /// number of max seats, or decreasing seats for a commitment based plan. *
  /// NOT_FOUND: Entitlement resource not found. * INTERNAL: Any non-user error
  /// related to a technical issue in the backend. Contact Cloud Channel
  /// support. * UNKNOWN: Any non-user error related to a technical issue in the
  /// backend. Contact Cloud Channel support. Return value: The ID of a
  /// long-running operation. To get the results of the operation, call the
  /// GetOperation method of CloudChannelOperationsService. The Operation
  /// metadata will contain an instance of OperationMetadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the entitlement to update. Name uses the
  /// format:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}
  /// Value must have pattern
  /// `^accounts/\[^/\]+/customers/\[^/\]+/entitlements/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> changeParameters(
    GoogleCloudChannelV1ChangeParametersRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':changeParameters';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the renewal settings for an existing customer entitlement.
  ///
  /// An entitlement update is a long-running operation and it updates the
  /// entitlement as a result of fulfillment. Possible error codes: *
  /// PERMISSION_DENIED: The customer doesn't belong to the reseller. *
  /// INVALID_ARGUMENT: Required request parameters are missing or invalid. *
  /// NOT_FOUND: Entitlement resource not found. * NOT_COMMITMENT_PLAN: Renewal
  /// Settings are only applicable for a commitment plan. Can't enable or
  /// disable renewals for non-commitment plans. * INTERNAL: Any non-user error
  /// related to a technical issue in the backend. Contact Cloud Channel
  /// support. * UNKNOWN: Any non-user error related to a technical issue in the
  /// backend. Contact Cloud Channel support. Return value: The ID of a
  /// long-running operation. To get the results of the operation, call the
  /// GetOperation method of CloudChannelOperationsService. The Operation
  /// metadata will contain an instance of OperationMetadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the entitlement to update. Name uses the
  /// format:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}
  /// Value must have pattern
  /// `^accounts/\[^/\]+/customers/\[^/\]+/entitlements/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> changeRenewalSettings(
    GoogleCloudChannelV1ChangeRenewalSettingsRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$name') + ':changeRenewalSettings';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates an entitlement for a customer.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The customer doesn't belong to
  /// the reseller. * INVALID_ARGUMENT: * Required request parameters are
  /// missing or invalid. * There is already a customer entitlement for a SKU
  /// from the same product family. * INVALID_VALUE: Make sure the OfferId is
  /// valid. If it is, contact Google Channel support for further
  /// troubleshooting. * NOT_FOUND: The customer or offer resource was not
  /// found. * ALREADY_EXISTS: * The SKU was already purchased for the customer.
  /// * The customer's primary email already exists. Retry after changing the
  /// customer's primary contact email. * CONDITION_NOT_MET or
  /// FAILED_PRECONDITION: * The domain required for purchasing a SKU has not
  /// been verified. * A pre-requisite SKU required to purchase an Add-On SKU is
  /// missing. For example, Google Workspace Business Starter is required to
  /// purchase Vault or Drive. * (Developer accounts only) Reseller and resold
  /// domain must meet the following naming requirements: * Domain names must
  /// start with goog-test. * Domain names must include the reseller domain. *
  /// INTERNAL: Any non-user error related to a technical issue in the backend.
  /// Contact Cloud Channel support. * UNKNOWN: Any non-user error related to a
  /// technical issue in the backend. Contact Cloud Channel support. Return
  /// value: The ID of a long-running operation. To get the results of the
  /// operation, call the GetOperation method of CloudChannelOperationsService.
  /// The Operation metadata will contain an instance of OperationMetadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the reseller's customer account
  /// in which to create the entitlement. Parent uses the format:
  /// accounts/{account_id}/customers/{customer_id}
  /// Value must have pattern `^accounts/\[^/\]+/customers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> create(
    GoogleCloudChannelV1CreateEntitlementRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/entitlements';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the requested Entitlement resource.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The customer doesn't belong to
  /// the reseller. * INVALID_ARGUMENT: Required request parameters are missing
  /// or invalid. * NOT_FOUND: The customer entitlement was not found. Return
  /// value: The requested Entitlement resource.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the entitlement to retrieve. Name
  /// uses the format:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}
  /// Value must have pattern
  /// `^accounts/\[^/\]+/customers/\[^/\]+/entitlements/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1Entitlement].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1Entitlement> get(
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
    return GoogleCloudChannelV1Entitlement.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists Entitlements belonging to a customer.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The customer doesn't belong to
  /// the reseller. * INVALID_ARGUMENT: Required request parameters are missing
  /// or invalid. Return value: A list of the customer's Entitlements.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the reseller's customer account
  /// to list entitlements for. Parent uses the format:
  /// accounts/{account_id}/customers/{customer_id}
  /// Value must have pattern `^accounts/\[^/\]+/customers/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. Requested page size. Server might return fewer
  /// results than requested. If unspecified, return at most 50 entitlements.
  /// The maximum value is 100; the server will coerce values above 100.
  ///
  /// [pageToken] - Optional. A token for a page of results other than the first
  /// page. Obtained using ListEntitlementsResponse.next_page_token of the
  /// previous CloudChannelService.ListEntitlements call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ListEntitlementsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ListEntitlementsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/entitlements';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1ListEntitlementsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the requested Offer resource.
  ///
  /// Possible error codes: * PERMISSION_DENIED: The entitlement doesn't belong
  /// to the reseller. * INVALID_ARGUMENT: Required request parameters are
  /// missing or invalid. * NOT_FOUND: Entitlement or offer was not found.
  /// Return value: The Offer resource.
  ///
  /// Request parameters:
  ///
  /// [entitlement] - Required. The resource name of the entitlement to retrieve
  /// the Offer. Entitlement uses the format:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}
  /// Value must have pattern
  /// `^accounts/\[^/\]+/customers/\[^/\]+/entitlements/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1Offer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1Offer> lookupOffer(
    core.String entitlement, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$entitlement') + ':lookupOffer';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1Offer.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Starts paid service for a trial entitlement.
  ///
  /// Starts paid service for a trial entitlement immediately. This method is
  /// only applicable if a plan is set up for a trial entitlement but has some
  /// trial days remaining. Possible error codes: * PERMISSION_DENIED: The
  /// customer doesn't belong to the reseller. * INVALID_ARGUMENT: Required
  /// request parameters are missing or invalid. * NOT_FOUND: Entitlement
  /// resource not found. * FAILED_PRECONDITION/NOT_IN_TRIAL: This method only
  /// works for entitlement on trial plans. * INTERNAL: Any non-user error
  /// related to a technical issue in the backend. Contact Cloud Channel
  /// support. * UNKNOWN: Any non-user error related to a technical issue in the
  /// backend. Contact Cloud Channel support. Return value: The ID of a
  /// long-running operation. To get the results of the operation, call the
  /// GetOperation method of CloudChannelOperationsService. The Operation
  /// metadata will contain an instance of OperationMetadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the entitlement to start a paid service
  /// for. Name uses the format:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}
  /// Value must have pattern
  /// `^accounts/\[^/\]+/customers/\[^/\]+/entitlements/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> startPaidService(
    GoogleCloudChannelV1StartPaidServiceRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':startPaidService';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Suspends a previously fulfilled entitlement.
  ///
  /// An entitlement suspension is a long-running operation. Possible error
  /// codes: * PERMISSION_DENIED: The customer doesn't belong to the reseller. *
  /// INVALID_ARGUMENT: Required request parameters are missing or invalid. *
  /// NOT_FOUND: Entitlement resource not found. * NOT_ACTIVE: Entitlement is
  /// not active. * INTERNAL: Any non-user error related to a technical issue in
  /// the backend. Contact Cloud Channel support. * UNKNOWN: Any non-user error
  /// related to a technical issue in the backend. Contact Cloud Channel
  /// support. Return value: The ID of a long-running operation. To get the
  /// results of the operation, call the GetOperation method of
  /// CloudChannelOperationsService. The Operation metadata will contain an
  /// instance of OperationMetadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the entitlement to suspend. Name
  /// uses the format:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}
  /// Value must have pattern
  /// `^accounts/\[^/\]+/customers/\[^/\]+/entitlements/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> suspend(
    GoogleCloudChannelV1SuspendEntitlementRequest request,
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
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AccountsOffersResource {
  final commons.ApiRequester _requester;

  AccountsOffersResource(commons.ApiRequester client) : _requester = client;

  /// Lists the Offers the reseller can sell.
  ///
  /// Possible error codes: * INVALID_ARGUMENT: Required request parameters are
  /// missing or invalid.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the reseller account from which
  /// to list Offers. Parent uses the format: accounts/{account_id}.
  /// Value must have pattern `^accounts/\[^/\]+$`.
  ///
  /// [filter] - Optional. The expression to filter results by name (name of the
  /// Offer), sku.name (name of the SKU), or sku.product.name (name of the
  /// Product). Example 1: sku.product.name=products/p1 AND
  /// sku.name!=products/p1/skus/s1 Example 2: name=accounts/a1/offers/o1
  ///
  /// [languageCode] - Optional. The BCP-47 language code. For example, "en-US".
  /// The response will localize in the corresponding language code, if
  /// specified. The default value is "en-US".
  ///
  /// [pageSize] - Optional. Requested page size. Server might return fewer
  /// results than requested. If unspecified, returns at most 500 Offers. The
  /// maximum value is 1000; the server will coerce values above 1000.
  ///
  /// [pageToken] - Optional. A token for a page of results other than the first
  /// page.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ListOffersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ListOffersResponse> list(
    core.String parent, {
    core.String? filter,
    core.String? languageCode,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (languageCode != null) 'languageCode': [languageCode],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/offers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1ListOffersResponse.fromJson(
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
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> cancel(
    GoogleLongrunningCancelOperationRequest request,
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
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
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
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
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
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
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
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> get(
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
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
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
  /// Completes with a [GoogleLongrunningListOperationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningListOperationsResponse> list(
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
    return GoogleLongrunningListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProductsResource {
  final commons.ApiRequester _requester;

  ProductsSkusResource get skus => ProductsSkusResource(_requester);

  ProductsResource(commons.ApiRequester client) : _requester = client;

  /// Lists the Products the reseller is authorized to sell.
  ///
  /// Possible error codes: * INVALID_ARGUMENT: Required request parameters are
  /// missing or invalid.
  ///
  /// Request parameters:
  ///
  /// [account] - Required. The resource name of the reseller account. Format:
  /// accounts/{account_id}.
  ///
  /// [languageCode] - Optional. The BCP-47 language code. For example, "en-US".
  /// The response will localize in the corresponding language code, if
  /// specified. The default value is "en-US".
  ///
  /// [pageSize] - Optional. Requested page size. Server might return fewer
  /// results than requested. If unspecified, returns at most 100 Products. The
  /// maximum value is 1000; the server will coerce values above 1000.
  ///
  /// [pageToken] - Optional. A token for a page of results other than the first
  /// page.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ListProductsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ListProductsResponse> list({
    core.String? account,
    core.String? languageCode,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (account != null) 'account': [account],
      if (languageCode != null) 'languageCode': [languageCode],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/products';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1ListProductsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProductsSkusResource {
  final commons.ApiRequester _requester;

  ProductsSkusResource(commons.ApiRequester client) : _requester = client;

  /// Lists the SKUs for a product the reseller is authorized to sell.
  ///
  /// Possible error codes: * INVALID_ARGUMENT: Required request parameters are
  /// missing or invalid.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the Product to list SKUs for.
  /// Parent uses the format: products/{product_id}. Supports products/- to
  /// retrieve SKUs for all products.
  /// Value must have pattern `^products/\[^/\]+$`.
  ///
  /// [account] - Required. Resource name of the reseller. Format:
  /// accounts/{account_id}.
  ///
  /// [languageCode] - Optional. The BCP-47 language code. For example, "en-US".
  /// The response will localize in the corresponding language code, if
  /// specified. The default value is "en-US".
  ///
  /// [pageSize] - Optional. Requested page size. Server might return fewer
  /// results than requested. If unspecified, returns at most 100 SKUs. The
  /// maximum value is 1000; the server will coerce values above 1000.
  ///
  /// [pageToken] - Optional. A token for a page of results other than the first
  /// page. Optional.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudChannelV1ListSkusResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudChannelV1ListSkusResponse> list(
    core.String parent, {
    core.String? account,
    core.String? languageCode,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (account != null) 'account': [account],
      if (languageCode != null) 'languageCode': [languageCode],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/skus';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudChannelV1ListSkusResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Request message for CloudChannelService.ActivateEntitlement.
class GoogleCloudChannelV1ActivateEntitlementRequest {
  /// You can specify an optional unique request ID, and if you need to retry
  /// your request, the server will know to ignore the request if it's complete.
  ///
  /// For example, you make an initial request and the request times out. If you
  /// make the request again with the same request ID, the server can check if
  /// it received the original operation with the same request ID. If it did, it
  /// will ignore the second request. The request ID must be a valid
  /// [UUID](https://tools.ietf.org/html/rfc4122) with the exception that zero
  /// UUID is not supported (`00000000-0000-0000-0000-000000000000`).
  ///
  /// Optional.
  core.String? requestId;

  GoogleCloudChannelV1ActivateEntitlementRequest();

  GoogleCloudChannelV1ActivateEntitlementRequest.fromJson(core.Map _json) {
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (requestId != null) 'requestId': requestId!,
      };
}

/// Information needed to create an Admin User for Google Workspace.
class GoogleCloudChannelV1AdminUser {
  /// Primary email of the admin user.
  core.String? email;

  /// Family name of the admin user.
  core.String? familyName;

  /// Given name of the admin user.
  core.String? givenName;

  GoogleCloudChannelV1AdminUser();

  GoogleCloudChannelV1AdminUser.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('familyName')) {
      familyName = _json['familyName'] as core.String;
    }
    if (_json.containsKey('givenName')) {
      givenName = _json['givenName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
        if (familyName != null) 'familyName': familyName!,
        if (givenName != null) 'givenName': givenName!,
      };
}

/// Association links that an entitlement has to other entitlements.
class GoogleCloudChannelV1AssociationInfo {
  /// The name of the base entitlement, for which this entitlement is an add-on.
  core.String? baseEntitlement;

  GoogleCloudChannelV1AssociationInfo();

  GoogleCloudChannelV1AssociationInfo.fromJson(core.Map _json) {
    if (_json.containsKey('baseEntitlement')) {
      baseEntitlement = _json['baseEntitlement'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (baseEntitlement != null) 'baseEntitlement': baseEntitlement!,
      };
}

/// Request message for CloudChannelService.CancelEntitlement.
class GoogleCloudChannelV1CancelEntitlementRequest {
  /// You can specify an optional unique request ID, and if you need to retry
  /// your request, the server will know to ignore the request if it's complete.
  ///
  /// For example, you make an initial request and the request times out. If you
  /// make the request again with the same request ID, the server can check if
  /// it received the original operation with the same request ID. If it did, it
  /// will ignore the second request. The request ID must be a valid
  /// [UUID](https://tools.ietf.org/html/rfc4122) with the exception that zero
  /// UUID is not supported (`00000000-0000-0000-0000-000000000000`).
  ///
  /// Optional.
  core.String? requestId;

  GoogleCloudChannelV1CancelEntitlementRequest();

  GoogleCloudChannelV1CancelEntitlementRequest.fromJson(core.Map _json) {
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (requestId != null) 'requestId': requestId!,
      };
}

/// Request message for CloudChannelService.ChangeOffer.
class GoogleCloudChannelV1ChangeOfferRequest {
  /// New Offer.
  ///
  /// Format: accounts/{account_id}/offers/{offer_id}.
  ///
  /// Required.
  core.String? offer;

  /// Parameters needed to purchase the Offer.
  ///
  /// Optional.
  core.List<GoogleCloudChannelV1Parameter>? parameters;

  /// Purchase order id provided by the reseller.
  ///
  /// Optional.
  core.String? purchaseOrderId;

  /// You can specify an optional unique request ID, and if you need to retry
  /// your request, the server will know to ignore the request if it's complete.
  ///
  /// For example, you make an initial request and the request times out. If you
  /// make the request again with the same request ID, the server can check if
  /// it received the original operation with the same request ID. If it did, it
  /// will ignore the second request. The request ID must be a valid
  /// [UUID](https://tools.ietf.org/html/rfc4122) with the exception that zero
  /// UUID is not supported (`00000000-0000-0000-0000-000000000000`).
  ///
  /// Optional.
  core.String? requestId;

  GoogleCloudChannelV1ChangeOfferRequest();

  GoogleCloudChannelV1ChangeOfferRequest.fromJson(core.Map _json) {
    if (_json.containsKey('offer')) {
      offer = _json['offer'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<GoogleCloudChannelV1Parameter>((value) =>
              GoogleCloudChannelV1Parameter.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('purchaseOrderId')) {
      purchaseOrderId = _json['purchaseOrderId'] as core.String;
    }
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (offer != null) 'offer': offer!,
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
        if (purchaseOrderId != null) 'purchaseOrderId': purchaseOrderId!,
        if (requestId != null) 'requestId': requestId!,
      };
}

/// Request message for CloudChannelService.ChangeParametersRequest.
class GoogleCloudChannelV1ChangeParametersRequest {
  /// Entitlement parameters to update.
  ///
  /// You can only change editable parameters.
  ///
  /// Required.
  core.List<GoogleCloudChannelV1Parameter>? parameters;

  /// Purchase order ID provided by the reseller.
  ///
  /// Optional.
  core.String? purchaseOrderId;

  /// You can specify an optional unique request ID, and if you need to retry
  /// your request, the server will know to ignore the request if it's complete.
  ///
  /// For example, you make an initial request and the request times out. If you
  /// make the request again with the same request ID, the server can check if
  /// it received the original operation with the same request ID. If it did, it
  /// will ignore the second request. The request ID must be a valid
  /// [UUID](https://tools.ietf.org/html/rfc4122) with the exception that zero
  /// UUID is not supported (`00000000-0000-0000-0000-000000000000`).
  ///
  /// Optional.
  core.String? requestId;

  GoogleCloudChannelV1ChangeParametersRequest();

  GoogleCloudChannelV1ChangeParametersRequest.fromJson(core.Map _json) {
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<GoogleCloudChannelV1Parameter>((value) =>
              GoogleCloudChannelV1Parameter.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('purchaseOrderId')) {
      purchaseOrderId = _json['purchaseOrderId'] as core.String;
    }
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
        if (purchaseOrderId != null) 'purchaseOrderId': purchaseOrderId!,
        if (requestId != null) 'requestId': requestId!,
      };
}

/// Request message for CloudChannelService.ChangeRenewalSettings.
class GoogleCloudChannelV1ChangeRenewalSettingsRequest {
  /// New renewal settings.
  ///
  /// Required.
  GoogleCloudChannelV1RenewalSettings? renewalSettings;

  /// You can specify an optional unique request ID, and if you need to retry
  /// your request, the server will know to ignore the request if it's complete.
  ///
  /// For example, you make an initial request and the request times out. If you
  /// make the request again with the same request ID, the server can check if
  /// it received the original operation with the same request ID. If it did, it
  /// will ignore the second request. The request ID must be a valid
  /// [UUID](https://tools.ietf.org/html/rfc4122) with the exception that zero
  /// UUID is not supported (`00000000-0000-0000-0000-000000000000`).
  ///
  /// Optional.
  core.String? requestId;

  GoogleCloudChannelV1ChangeRenewalSettingsRequest();

  GoogleCloudChannelV1ChangeRenewalSettingsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('renewalSettings')) {
      renewalSettings = GoogleCloudChannelV1RenewalSettings.fromJson(
          _json['renewalSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (renewalSettings != null)
          'renewalSettings': renewalSettings!.toJson(),
        if (requestId != null) 'requestId': requestId!,
      };
}

/// Entity representing a link between distributors and their indirect resellers
/// in an n-tier resale channel.
class GoogleCloudChannelV1ChannelPartnerLink {
  /// Cloud Identity info of the channel partner (IR).
  ///
  /// Output only.
  GoogleCloudChannelV1CloudIdentityInfo? channelPartnerCloudIdentityInfo;

  /// Timestamp of when the channel partner link is created.
  ///
  /// Output only.
  core.String? createTime;

  /// URI of the web page where partner accepts the link invitation.
  ///
  /// Output only.
  core.String? inviteLinkUri;

  /// State of the channel partner link.
  ///
  /// Required.
  /// Possible string values are:
  /// - "CHANNEL_PARTNER_LINK_STATE_UNSPECIFIED" : The state is not specified.
  /// - "INVITED" : An invitation has been sent to the reseller to create a
  /// channel partner link.
  /// - "ACTIVE" : Status when the reseller is active.
  /// - "REVOKED" : Status when the reseller has been revoked by the
  /// distributor.
  /// - "SUSPENDED" : Status when the reseller is suspended by Google or
  /// distributor.
  core.String? linkState;

  /// Resource name for the channel partner link, in the format
  /// accounts/{account_id}/channelPartnerLinks/{id}.
  ///
  /// Output only.
  core.String? name;

  /// Public identifier that a customer must use to generate a transfer token to
  /// move to this distributor-reseller combination.
  ///
  /// Output only.
  core.String? publicId;

  /// Cloud Identity ID of the linked reseller.
  ///
  /// Required.
  core.String? resellerCloudIdentityId;

  /// Timestamp of when the channel partner link is updated.
  ///
  /// Output only.
  core.String? updateTime;

  GoogleCloudChannelV1ChannelPartnerLink();

  GoogleCloudChannelV1ChannelPartnerLink.fromJson(core.Map _json) {
    if (_json.containsKey('channelPartnerCloudIdentityInfo')) {
      channelPartnerCloudIdentityInfo =
          GoogleCloudChannelV1CloudIdentityInfo.fromJson(
              _json['channelPartnerCloudIdentityInfo']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('inviteLinkUri')) {
      inviteLinkUri = _json['inviteLinkUri'] as core.String;
    }
    if (_json.containsKey('linkState')) {
      linkState = _json['linkState'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('publicId')) {
      publicId = _json['publicId'] as core.String;
    }
    if (_json.containsKey('resellerCloudIdentityId')) {
      resellerCloudIdentityId = _json['resellerCloudIdentityId'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (channelPartnerCloudIdentityInfo != null)
          'channelPartnerCloudIdentityInfo':
              channelPartnerCloudIdentityInfo!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (inviteLinkUri != null) 'inviteLinkUri': inviteLinkUri!,
        if (linkState != null) 'linkState': linkState!,
        if (name != null) 'name': name!,
        if (publicId != null) 'publicId': publicId!,
        if (resellerCloudIdentityId != null)
          'resellerCloudIdentityId': resellerCloudIdentityId!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Request message for CloudChannelService.CheckCloudIdentityAccountsExist.
class GoogleCloudChannelV1CheckCloudIdentityAccountsExistRequest {
  /// Domain to fetch for Cloud Identity account customer.
  ///
  /// Required.
  core.String? domain;

  GoogleCloudChannelV1CheckCloudIdentityAccountsExistRequest();

  GoogleCloudChannelV1CheckCloudIdentityAccountsExistRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('domain')) {
      domain = _json['domain'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (domain != null) 'domain': domain!,
      };
}

/// Response message for CloudChannelService.CheckCloudIdentityAccountsExist.
class GoogleCloudChannelV1CheckCloudIdentityAccountsExistResponse {
  /// The Cloud Identity accounts associated with the domain.
  core.List<GoogleCloudChannelV1CloudIdentityCustomerAccount>?
      cloudIdentityAccounts;

  GoogleCloudChannelV1CheckCloudIdentityAccountsExistResponse();

  GoogleCloudChannelV1CheckCloudIdentityAccountsExistResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('cloudIdentityAccounts')) {
      cloudIdentityAccounts = (_json['cloudIdentityAccounts'] as core.List)
          .map<GoogleCloudChannelV1CloudIdentityCustomerAccount>((value) =>
              GoogleCloudChannelV1CloudIdentityCustomerAccount.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudIdentityAccounts != null)
          'cloudIdentityAccounts':
              cloudIdentityAccounts!.map((value) => value.toJson()).toList(),
      };
}

/// Entity representing a Cloud Identity account that may be associated with a
/// Channel Services API partner.
class GoogleCloudChannelV1CloudIdentityCustomerAccount {
  /// If existing = true, the Cloud Identity ID of the customer.
  core.String? customerCloudIdentityId;

  /// If owned = true, the name of the customer that owns the Cloud Identity
  /// account.
  ///
  /// Customer_name uses the format:
  /// accounts/{account_id}/customers/{customer_id}
  core.String? customerName;

  /// Returns true if a Cloud Identity account exists for a specific domain.
  core.bool? existing;

  /// Returns true if the Cloud Identity account is associated with a customer
  /// of the Channel Services partner.
  core.bool? owned;

  GoogleCloudChannelV1CloudIdentityCustomerAccount();

  GoogleCloudChannelV1CloudIdentityCustomerAccount.fromJson(core.Map _json) {
    if (_json.containsKey('customerCloudIdentityId')) {
      customerCloudIdentityId = _json['customerCloudIdentityId'] as core.String;
    }
    if (_json.containsKey('customerName')) {
      customerName = _json['customerName'] as core.String;
    }
    if (_json.containsKey('existing')) {
      existing = _json['existing'] as core.bool;
    }
    if (_json.containsKey('owned')) {
      owned = _json['owned'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customerCloudIdentityId != null)
          'customerCloudIdentityId': customerCloudIdentityId!,
        if (customerName != null) 'customerName': customerName!,
        if (existing != null) 'existing': existing!,
        if (owned != null) 'owned': owned!,
      };
}

/// Cloud Identity information for the Cloud Channel Customer.
class GoogleCloudChannelV1CloudIdentityInfo {
  /// URI of Customer's Admin console dashboard.
  ///
  /// Output only.
  core.String? adminConsoleUri;

  /// The alternate email.
  core.String? alternateEmail;

  /// CustomerType indicates verification type needed for using services.
  /// Possible string values are:
  /// - "CUSTOMER_TYPE_UNSPECIFIED" : Default value. This state doesn't show
  /// unless an error occurs.
  /// - "DOMAIN" : Domain-owning customer which needs domain verification to use
  /// services.
  /// - "TEAM" : Team customer which needs email verification to use services.
  core.String? customerType;

  /// Edu information about the customer.
  GoogleCloudChannelV1EduData? eduData;

  /// Whether the domain is verified.
  ///
  /// This field is not returned for a Customer's cloud_identity_info resource.
  /// Partners can use the domains.get() method of the Workspace SDK's Directory
  /// API, or listen to the PRIMARY_DOMAIN_VERIFIED Pub/Sub event in to track
  /// domain verification of their resolve Workspace customers.
  ///
  /// Output only.
  core.bool? isDomainVerified;

  /// Language code.
  core.String? languageCode;

  /// Phone number associated with the Cloud Identity.
  core.String? phoneNumber;

  /// The primary domain name.
  ///
  /// Output only.
  core.String? primaryDomain;

  GoogleCloudChannelV1CloudIdentityInfo();

  GoogleCloudChannelV1CloudIdentityInfo.fromJson(core.Map _json) {
    if (_json.containsKey('adminConsoleUri')) {
      adminConsoleUri = _json['adminConsoleUri'] as core.String;
    }
    if (_json.containsKey('alternateEmail')) {
      alternateEmail = _json['alternateEmail'] as core.String;
    }
    if (_json.containsKey('customerType')) {
      customerType = _json['customerType'] as core.String;
    }
    if (_json.containsKey('eduData')) {
      eduData = GoogleCloudChannelV1EduData.fromJson(
          _json['eduData'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('isDomainVerified')) {
      isDomainVerified = _json['isDomainVerified'] as core.bool;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
    if (_json.containsKey('primaryDomain')) {
      primaryDomain = _json['primaryDomain'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adminConsoleUri != null) 'adminConsoleUri': adminConsoleUri!,
        if (alternateEmail != null) 'alternateEmail': alternateEmail!,
        if (customerType != null) 'customerType': customerType!,
        if (eduData != null) 'eduData': eduData!.toJson(),
        if (isDomainVerified != null) 'isDomainVerified': isDomainVerified!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
        if (primaryDomain != null) 'primaryDomain': primaryDomain!,
      };
}

/// Commitment settings for commitment-based offers.
class GoogleCloudChannelV1CommitmentSettings {
  /// Commitment end timestamp.
  ///
  /// Output only.
  core.String? endTime;

  /// Renewal settings applicable for a commitment-based Offer.
  ///
  /// Optional.
  GoogleCloudChannelV1RenewalSettings? renewalSettings;

  /// Commitment start timestamp.
  ///
  /// Output only.
  core.String? startTime;

  GoogleCloudChannelV1CommitmentSettings();

  GoogleCloudChannelV1CommitmentSettings.fromJson(core.Map _json) {
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('renewalSettings')) {
      renewalSettings = GoogleCloudChannelV1RenewalSettings.fromJson(
          _json['renewalSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTime != null) 'endTime': endTime!,
        if (renewalSettings != null)
          'renewalSettings': renewalSettings!.toJson(),
        if (startTime != null) 'startTime': startTime!,
      };
}

/// Represents the constraints for buying the Offer.
class GoogleCloudChannelV1Constraints {
  /// Represents constraints required to purchase the Offer for a customer.
  GoogleCloudChannelV1CustomerConstraints? customerConstraints;

  GoogleCloudChannelV1Constraints();

  GoogleCloudChannelV1Constraints.fromJson(core.Map _json) {
    if (_json.containsKey('customerConstraints')) {
      customerConstraints = GoogleCloudChannelV1CustomerConstraints.fromJson(
          _json['customerConstraints'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customerConstraints != null)
          'customerConstraints': customerConstraints!.toJson(),
      };
}

/// Contact information for a customer account.
class GoogleCloudChannelV1ContactInfo {
  /// The customer account contact's display name, formatted as a combination of
  /// the customer's first and last name.
  ///
  /// Output only.
  core.String? displayName;

  /// The customer account's contact email.
  ///
  /// Required for entitlements that create admin.google.com accounts, and
  /// serves as the customer's username for those accounts.
  core.String? email;

  /// The customer account contact's first name.
  core.String? firstName;

  /// The customer account contact's last name.
  core.String? lastName;

  /// The customer account's contact phone number.
  core.String? phone;

  /// The customer account contact's job title.
  ///
  /// Optional.
  core.String? title;

  GoogleCloudChannelV1ContactInfo();

  GoogleCloudChannelV1ContactInfo.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('firstName')) {
      firstName = _json['firstName'] as core.String;
    }
    if (_json.containsKey('lastName')) {
      lastName = _json['lastName'] as core.String;
    }
    if (_json.containsKey('phone')) {
      phone = _json['phone'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (email != null) 'email': email!,
        if (firstName != null) 'firstName': firstName!,
        if (lastName != null) 'lastName': lastName!,
        if (phone != null) 'phone': phone!,
        if (title != null) 'title': title!,
      };
}

/// Request message for CloudChannelService.CreateEntitlement
class GoogleCloudChannelV1CreateEntitlementRequest {
  /// The entitlement to create.
  ///
  /// Required.
  GoogleCloudChannelV1Entitlement? entitlement;

  /// You can specify an optional unique request ID, and if you need to retry
  /// your request, the server will know to ignore the request if it's complete.
  ///
  /// For example, you make an initial request and the request times out. If you
  /// make the request again with the same request ID, the server can check if
  /// it received the original operation with the same request ID. If it did, it
  /// will ignore the second request. The request ID must be a valid
  /// [UUID](https://tools.ietf.org/html/rfc4122) with the exception that zero
  /// UUID is not supported (`00000000-0000-0000-0000-000000000000`).
  ///
  /// Optional.
  core.String? requestId;

  GoogleCloudChannelV1CreateEntitlementRequest();

  GoogleCloudChannelV1CreateEntitlementRequest.fromJson(core.Map _json) {
    if (_json.containsKey('entitlement')) {
      entitlement = GoogleCloudChannelV1Entitlement.fromJson(
          _json['entitlement'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entitlement != null) 'entitlement': entitlement!.toJson(),
        if (requestId != null) 'requestId': requestId!,
      };
}

/// Entity representing a customer of a reseller or distributor.
class GoogleCloudChannelV1Customer {
  /// Secondary contact email.
  ///
  /// You need to provide an alternate email to create different domains if a
  /// primary contact email already exists. Users will receive a notification
  /// with credentials when you create an admin.google.com account. Secondary
  /// emails are also recovery email addresses.
  core.String? alternateEmail;

  /// Cloud Identity ID of the customer's channel partner.
  ///
  /// Populated only if a channel partner exists for this customer.
  core.String? channelPartnerId;

  /// The customer's Cloud Identity ID if the customer has a Cloud Identity
  /// resource.
  ///
  /// Output only.
  core.String? cloudIdentityId;

  /// Cloud Identity information for the customer.
  ///
  /// Populated only if a Cloud Identity account exists for this customer.
  ///
  /// Output only.
  GoogleCloudChannelV1CloudIdentityInfo? cloudIdentityInfo;

  /// Time when the customer was created.
  ///
  /// Output only.
  core.String? createTime;

  /// The customer's primary domain.
  ///
  /// Must match the primary contact email's domain.
  ///
  /// Required.
  core.String? domain;

  /// The BCP-47 language code, such as "en-US" or "sr-Latn".
  ///
  /// For more information, see
  /// https://www.unicode.org/reports/tr35/#Unicode_locale_identifier.
  ///
  /// Optional.
  core.String? languageCode;

  /// Resource name of the customer.
  ///
  /// Format: accounts/{account_id}/customers/{customer_id}
  ///
  /// Output only.
  core.String? name;

  /// Name of the organization that the customer entity represents.
  ///
  /// Required.
  core.String? orgDisplayName;

  /// The organization address for the customer.
  ///
  /// To enforce US laws and embargoes, we require a region and zip code. You
  /// must provide valid addresses for every customer. To set the customer's
  /// language, use the Customer-level language code.
  ///
  /// Required.
  GoogleTypePostalAddress? orgPostalAddress;

  /// Primary contact info.
  GoogleCloudChannelV1ContactInfo? primaryContactInfo;

  /// Time when the customer was updated.
  ///
  /// Output only.
  core.String? updateTime;

  GoogleCloudChannelV1Customer();

  GoogleCloudChannelV1Customer.fromJson(core.Map _json) {
    if (_json.containsKey('alternateEmail')) {
      alternateEmail = _json['alternateEmail'] as core.String;
    }
    if (_json.containsKey('channelPartnerId')) {
      channelPartnerId = _json['channelPartnerId'] as core.String;
    }
    if (_json.containsKey('cloudIdentityId')) {
      cloudIdentityId = _json['cloudIdentityId'] as core.String;
    }
    if (_json.containsKey('cloudIdentityInfo')) {
      cloudIdentityInfo = GoogleCloudChannelV1CloudIdentityInfo.fromJson(
          _json['cloudIdentityInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('domain')) {
      domain = _json['domain'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('orgDisplayName')) {
      orgDisplayName = _json['orgDisplayName'] as core.String;
    }
    if (_json.containsKey('orgPostalAddress')) {
      orgPostalAddress = GoogleTypePostalAddress.fromJson(
          _json['orgPostalAddress'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('primaryContactInfo')) {
      primaryContactInfo = GoogleCloudChannelV1ContactInfo.fromJson(
          _json['primaryContactInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alternateEmail != null) 'alternateEmail': alternateEmail!,
        if (channelPartnerId != null) 'channelPartnerId': channelPartnerId!,
        if (cloudIdentityId != null) 'cloudIdentityId': cloudIdentityId!,
        if (cloudIdentityInfo != null)
          'cloudIdentityInfo': cloudIdentityInfo!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (domain != null) 'domain': domain!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (name != null) 'name': name!,
        if (orgDisplayName != null) 'orgDisplayName': orgDisplayName!,
        if (orgPostalAddress != null)
          'orgPostalAddress': orgPostalAddress!.toJson(),
        if (primaryContactInfo != null)
          'primaryContactInfo': primaryContactInfo!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Represents constraints required to purchase the Offer for a customer.
class GoogleCloudChannelV1CustomerConstraints {
  /// Allowed Customer Type.
  core.List<core.String>? allowedCustomerTypes;

  /// Allowed geographical regions of the customer.
  core.List<core.String>? allowedRegions;

  /// Allowed Promotional Order Type.
  ///
  /// Present for Promotional offers.
  core.List<core.String>? promotionalOrderTypes;

  GoogleCloudChannelV1CustomerConstraints();

  GoogleCloudChannelV1CustomerConstraints.fromJson(core.Map _json) {
    if (_json.containsKey('allowedCustomerTypes')) {
      allowedCustomerTypes = (_json['allowedCustomerTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('allowedRegions')) {
      allowedRegions = (_json['allowedRegions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('promotionalOrderTypes')) {
      promotionalOrderTypes = (_json['promotionalOrderTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedCustomerTypes != null)
          'allowedCustomerTypes': allowedCustomerTypes!,
        if (allowedRegions != null) 'allowedRegions': allowedRegions!,
        if (promotionalOrderTypes != null)
          'promotionalOrderTypes': promotionalOrderTypes!,
      };
}

/// Represents Pub/Sub message content describing customer update.
class GoogleCloudChannelV1CustomerEvent {
  /// Resource name of the customer.
  ///
  /// Format: accounts/{account_id}/customers/{customer_id}
  core.String? customer;

  /// Type of event which happened on the customer.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Default value. This state doesn't show unless an
  /// error occurs.
  /// - "PRIMARY_DOMAIN_CHANGED" : Primary domain for customer was changed.
  /// - "PRIMARY_DOMAIN_VERIFIED" : Primary domain of the customer has been
  /// verified.
  core.String? eventType;

  GoogleCloudChannelV1CustomerEvent();

  GoogleCloudChannelV1CustomerEvent.fromJson(core.Map _json) {
    if (_json.containsKey('customer')) {
      customer = _json['customer'] as core.String;
    }
    if (_json.containsKey('eventType')) {
      eventType = _json['eventType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customer != null) 'customer': customer!,
        if (eventType != null) 'eventType': eventType!,
      };
}

/// Required Edu Attributes
class GoogleCloudChannelV1EduData {
  /// Size of the institute.
  /// Possible string values are:
  /// - "INSTITUTE_SIZE_UNSPECIFIED" : Default value. This state doesn't show
  /// unless an error occurs.
  /// - "SIZE_1_100" : 1 - 100
  /// - "SIZE_101_500" : 101 - 500
  /// - "SIZE_501_1000" : 501 - 1,000
  /// - "SIZE_1001_2000" : 1,001 - 2,000
  /// - "SIZE_2001_5000" : 2,001 - 5,000
  /// - "SIZE_5001_10000" : 5,001 - 10,000
  /// - "SIZE_10001_OR_MORE" : 10,001 +
  core.String? instituteSize;

  /// Designated institute type of customer.
  /// Possible string values are:
  /// - "INSTITUTE_TYPE_UNSPECIFIED" : Default value. This state doesn't show
  /// unless an error occurs.
  /// - "K12" : Elementary/Secondary Schools & Districts
  /// - "UNIVERSITY" : Higher Education Universities & Colleges
  core.String? instituteType;

  /// Web address for the edu customer's institution.
  core.String? website;

  GoogleCloudChannelV1EduData();

  GoogleCloudChannelV1EduData.fromJson(core.Map _json) {
    if (_json.containsKey('instituteSize')) {
      instituteSize = _json['instituteSize'] as core.String;
    }
    if (_json.containsKey('instituteType')) {
      instituteType = _json['instituteType'] as core.String;
    }
    if (_json.containsKey('website')) {
      website = _json['website'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (instituteSize != null) 'instituteSize': instituteSize!,
        if (instituteType != null) 'instituteType': instituteType!,
        if (website != null) 'website': website!,
      };
}

/// An entitlement is a representation of a customer's ability to use a service.
class GoogleCloudChannelV1Entitlement {
  /// Association information to other entitlements.
  GoogleCloudChannelV1AssociationInfo? associationInfo;

  /// Commitment settings for a commitment-based Offer.
  ///
  /// Required for commitment based offers.
  GoogleCloudChannelV1CommitmentSettings? commitmentSettings;

  /// The time at which the entitlement is created.
  ///
  /// Output only.
  core.String? createTime;

  /// Resource name of an entitlement in the form:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}.
  ///
  /// Output only.
  core.String? name;

  /// The offer resource name for which the entitlement is to be created.
  ///
  /// Takes the form: accounts/{account_id}/offers/{offer_id}.
  ///
  /// Required.
  core.String? offer;

  /// Extended entitlement parameters.
  ///
  /// When creating an entitlement, valid parameters' names and values are
  /// defined in the offer's parameter definitions.
  core.List<GoogleCloudChannelV1Parameter>? parameters;

  /// Service provisioning details for the entitlement.
  ///
  /// Output only.
  GoogleCloudChannelV1ProvisionedService? provisionedService;

  /// Current provisioning state of the entitlement.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "PROVISIONING_STATE_UNSPECIFIED" : Default value. This state doesn't
  /// show unless an error occurs.
  /// - "ACTIVE" : The entitlement is currently active.
  /// - "SUSPENDED" : The entitlement is currently suspended.
  core.String? provisioningState;

  /// This purchase order (PO) information is for resellers to use for their
  /// company tracking usage.
  ///
  /// If a purchaseOrderId value is given, it appears in the API responses and
  /// shows up in the invoice. The property accepts up to 80 plain text
  /// characters.
  ///
  /// Optional.
  core.String? purchaseOrderId;

  /// Enumerable of all current suspension reasons for an entitlement.
  ///
  /// Output only.
  core.List<core.String>? suspensionReasons;

  /// Settings for trial offers.
  ///
  /// Output only.
  GoogleCloudChannelV1TrialSettings? trialSettings;

  /// The time at which the entitlement is updated.
  ///
  /// Output only.
  core.String? updateTime;

  GoogleCloudChannelV1Entitlement();

  GoogleCloudChannelV1Entitlement.fromJson(core.Map _json) {
    if (_json.containsKey('associationInfo')) {
      associationInfo = GoogleCloudChannelV1AssociationInfo.fromJson(
          _json['associationInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('commitmentSettings')) {
      commitmentSettings = GoogleCloudChannelV1CommitmentSettings.fromJson(
          _json['commitmentSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('offer')) {
      offer = _json['offer'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<GoogleCloudChannelV1Parameter>((value) =>
              GoogleCloudChannelV1Parameter.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('provisionedService')) {
      provisionedService = GoogleCloudChannelV1ProvisionedService.fromJson(
          _json['provisionedService'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('provisioningState')) {
      provisioningState = _json['provisioningState'] as core.String;
    }
    if (_json.containsKey('purchaseOrderId')) {
      purchaseOrderId = _json['purchaseOrderId'] as core.String;
    }
    if (_json.containsKey('suspensionReasons')) {
      suspensionReasons = (_json['suspensionReasons'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('trialSettings')) {
      trialSettings = GoogleCloudChannelV1TrialSettings.fromJson(
          _json['trialSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (associationInfo != null)
          'associationInfo': associationInfo!.toJson(),
        if (commitmentSettings != null)
          'commitmentSettings': commitmentSettings!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (name != null) 'name': name!,
        if (offer != null) 'offer': offer!,
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
        if (provisionedService != null)
          'provisionedService': provisionedService!.toJson(),
        if (provisioningState != null) 'provisioningState': provisioningState!,
        if (purchaseOrderId != null) 'purchaseOrderId': purchaseOrderId!,
        if (suspensionReasons != null) 'suspensionReasons': suspensionReasons!,
        if (trialSettings != null) 'trialSettings': trialSettings!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Represents Pub/Sub message content describing entitlement update.
class GoogleCloudChannelV1EntitlementEvent {
  /// Resource name of an entitlement of the form:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}
  core.String? entitlement;

  /// Type of event which happened on the entitlement.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Default value. This state doesn't show unless an
  /// error occurs.
  /// - "CREATED" : A new entitlement was created.
  /// - "PRICE_PLAN_SWITCHED" : The offer type associated with an entitlement
  /// was changed. This is not triggered if an entitlement converts from a
  /// commit offer to a flexible offer as part of a renewal.
  /// - "COMMITMENT_CHANGED" : Annual commitment for a commit plan was changed.
  /// - "RENEWED" : An annual entitlement was renewed.
  /// - "SUSPENDED" : Entitlement was suspended.
  /// - "ACTIVATED" : Entitlement was unsuspended.
  /// - "CANCELLED" : Entitlement was cancelled.
  /// - "SKU_CHANGED" : Entitlement was upgraded or downgraded (e.g. from Google
  /// Workspace Business Standard to Google Workspace Business Plus).
  /// - "RENEWAL_SETTING_CHANGED" : The renewal settings of an entitlement has
  /// changed.
  /// - "PAID_SERVICE_STARTED" : Paid service has started on trial entitlement.
  /// - "LICENSE_ASSIGNMENT_CHANGED" : License was assigned to or revoked from a
  /// user.
  /// - "LICENSE_CAP_CHANGED" : License cap was changed for the entitlement.
  core.String? eventType;

  GoogleCloudChannelV1EntitlementEvent();

  GoogleCloudChannelV1EntitlementEvent.fromJson(core.Map _json) {
    if (_json.containsKey('entitlement')) {
      entitlement = _json['entitlement'] as core.String;
    }
    if (_json.containsKey('eventType')) {
      eventType = _json['eventType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entitlement != null) 'entitlement': entitlement!,
        if (eventType != null) 'eventType': eventType!,
      };
}

/// Response message for CloudChannelService.ListChannelPartnerLinks.
class GoogleCloudChannelV1ListChannelPartnerLinksResponse {
  /// The Channel partner links for a reseller.
  core.List<GoogleCloudChannelV1ChannelPartnerLink>? channelPartnerLinks;

  /// A token to retrieve the next page of results.
  ///
  /// Pass to ListChannelPartnerLinksRequest.page_token to obtain that page.
  core.String? nextPageToken;

  GoogleCloudChannelV1ListChannelPartnerLinksResponse();

  GoogleCloudChannelV1ListChannelPartnerLinksResponse.fromJson(core.Map _json) {
    if (_json.containsKey('channelPartnerLinks')) {
      channelPartnerLinks = (_json['channelPartnerLinks'] as core.List)
          .map<GoogleCloudChannelV1ChannelPartnerLink>((value) =>
              GoogleCloudChannelV1ChannelPartnerLink.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (channelPartnerLinks != null)
          'channelPartnerLinks':
              channelPartnerLinks!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for CloudChannelService.ListCustomers.
class GoogleCloudChannelV1ListCustomersResponse {
  /// The customers belonging to a reseller or distributor.
  core.List<GoogleCloudChannelV1Customer>? customers;

  /// A token to retrieve the next page of results.
  ///
  /// Pass to ListCustomersRequest.page_token to obtain that page.
  core.String? nextPageToken;

  GoogleCloudChannelV1ListCustomersResponse();

  GoogleCloudChannelV1ListCustomersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('customers')) {
      customers = (_json['customers'] as core.List)
          .map<GoogleCloudChannelV1Customer>((value) =>
              GoogleCloudChannelV1Customer.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customers != null)
          'customers': customers!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for CloudChannelService.ListEntitlements.
class GoogleCloudChannelV1ListEntitlementsResponse {
  /// The reseller customer's entitlements.
  core.List<GoogleCloudChannelV1Entitlement>? entitlements;

  /// A token to list the next page of results.
  ///
  /// Pass to ListEntitlementsRequest.page_token to obtain that page.
  core.String? nextPageToken;

  GoogleCloudChannelV1ListEntitlementsResponse();

  GoogleCloudChannelV1ListEntitlementsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entitlements')) {
      entitlements = (_json['entitlements'] as core.List)
          .map<GoogleCloudChannelV1Entitlement>((value) =>
              GoogleCloudChannelV1Entitlement.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entitlements != null)
          'entitlements': entitlements!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for ListOffers.
class GoogleCloudChannelV1ListOffersResponse {
  /// A token to retrieve the next page of results.
  core.String? nextPageToken;

  /// The list of Offers requested.
  core.List<GoogleCloudChannelV1Offer>? offers;

  GoogleCloudChannelV1ListOffersResponse();

  GoogleCloudChannelV1ListOffersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('offers')) {
      offers = (_json['offers'] as core.List)
          .map<GoogleCloudChannelV1Offer>((value) =>
              GoogleCloudChannelV1Offer.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (offers != null)
          'offers': offers!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for ListProducts.
class GoogleCloudChannelV1ListProductsResponse {
  /// A token to retrieve the next page of results.
  core.String? nextPageToken;

  /// List of Products requested.
  core.List<GoogleCloudChannelV1Product>? products;

  GoogleCloudChannelV1ListProductsResponse();

  GoogleCloudChannelV1ListProductsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('products')) {
      products = (_json['products'] as core.List)
          .map<GoogleCloudChannelV1Product>((value) =>
              GoogleCloudChannelV1Product.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (products != null)
          'products': products!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for ListPurchasableOffers.
class GoogleCloudChannelV1ListPurchasableOffersResponse {
  /// A token to retrieve the next page of results.
  core.String? nextPageToken;

  /// The list of Offers requested.
  core.List<GoogleCloudChannelV1PurchasableOffer>? purchasableOffers;

  GoogleCloudChannelV1ListPurchasableOffersResponse();

  GoogleCloudChannelV1ListPurchasableOffersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('purchasableOffers')) {
      purchasableOffers = (_json['purchasableOffers'] as core.List)
          .map<GoogleCloudChannelV1PurchasableOffer>((value) =>
              GoogleCloudChannelV1PurchasableOffer.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (purchasableOffers != null)
          'purchasableOffers':
              purchasableOffers!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for ListPurchasableSkus.
class GoogleCloudChannelV1ListPurchasableSkusResponse {
  /// A token to retrieve the next page of results.
  core.String? nextPageToken;

  /// The list of SKUs requested.
  core.List<GoogleCloudChannelV1PurchasableSku>? purchasableSkus;

  GoogleCloudChannelV1ListPurchasableSkusResponse();

  GoogleCloudChannelV1ListPurchasableSkusResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('purchasableSkus')) {
      purchasableSkus = (_json['purchasableSkus'] as core.List)
          .map<GoogleCloudChannelV1PurchasableSku>((value) =>
              GoogleCloudChannelV1PurchasableSku.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (purchasableSkus != null)
          'purchasableSkus':
              purchasableSkus!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for ListSkus.
class GoogleCloudChannelV1ListSkusResponse {
  /// A token to retrieve the next page of results.
  core.String? nextPageToken;

  /// The list of SKUs requested.
  core.List<GoogleCloudChannelV1Sku>? skus;

  GoogleCloudChannelV1ListSkusResponse();

  GoogleCloudChannelV1ListSkusResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('skus')) {
      skus = (_json['skus'] as core.List)
          .map<GoogleCloudChannelV1Sku>((value) =>
              GoogleCloudChannelV1Sku.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (skus != null) 'skus': skus!.map((value) => value.toJson()).toList(),
      };
}

/// Response Message for ListSubscribers.
class GoogleCloudChannelV1ListSubscribersResponse {
  /// A token that can be sent as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// List of service accounts which have subscriber access to the topic.
  core.List<core.String>? serviceAccounts;

  /// Name of the topic registered with the reseller.
  core.String? topic;

  GoogleCloudChannelV1ListSubscribersResponse();

  GoogleCloudChannelV1ListSubscribersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('serviceAccounts')) {
      serviceAccounts = (_json['serviceAccounts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('topic')) {
      topic = _json['topic'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (serviceAccounts != null) 'serviceAccounts': serviceAccounts!,
        if (topic != null) 'topic': topic!,
      };
}

/// Request message for CloudChannelService.ListTransferableOffers
class GoogleCloudChannelV1ListTransferableOffersRequest {
  /// Customer's Cloud Identity ID
  core.String? cloudIdentityId;

  /// A reseller should create a customer and use the resource name of that
  /// customer here.
  core.String? customerName;

  /// The BCP-47 language code.
  ///
  /// For example, "en-US". The response will localize in the corresponding
  /// language code, if specified. The default value is "en-US".
  core.String? languageCode;

  /// Requested page size.
  ///
  /// Server might return fewer results than requested. If unspecified, returns
  /// at most 100 offers. The maximum value is 1000; the server will coerce
  /// values above 1000.
  core.int? pageSize;

  /// A token for a page of results other than the first page.
  ///
  /// Obtained using ListTransferableOffersResponse.next_page_token of the
  /// previous CloudChannelService.ListTransferableOffers call.
  core.String? pageToken;

  /// The SKU to look up Offers for.
  ///
  /// Required.
  core.String? sku;

  GoogleCloudChannelV1ListTransferableOffersRequest();

  GoogleCloudChannelV1ListTransferableOffersRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cloudIdentityId')) {
      cloudIdentityId = _json['cloudIdentityId'] as core.String;
    }
    if (_json.containsKey('customerName')) {
      customerName = _json['customerName'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('pageSize')) {
      pageSize = _json['pageSize'] as core.int;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
    if (_json.containsKey('sku')) {
      sku = _json['sku'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudIdentityId != null) 'cloudIdentityId': cloudIdentityId!,
        if (customerName != null) 'customerName': customerName!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (pageSize != null) 'pageSize': pageSize!,
        if (pageToken != null) 'pageToken': pageToken!,
        if (sku != null) 'sku': sku!,
      };
}

/// Response message for CloudChannelService.ListTransferableOffers.
class GoogleCloudChannelV1ListTransferableOffersResponse {
  /// A token to retrieve the next page of results.
  ///
  /// Pass to ListTransferableOffersRequest.page_token to obtain that page.
  core.String? nextPageToken;

  /// Information about Offers for a customer that can be used for transfer.
  core.List<GoogleCloudChannelV1TransferableOffer>? transferableOffers;

  GoogleCloudChannelV1ListTransferableOffersResponse();

  GoogleCloudChannelV1ListTransferableOffersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('transferableOffers')) {
      transferableOffers = (_json['transferableOffers'] as core.List)
          .map<GoogleCloudChannelV1TransferableOffer>((value) =>
              GoogleCloudChannelV1TransferableOffer.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (transferableOffers != null)
          'transferableOffers':
              transferableOffers!.map((value) => value.toJson()).toList(),
      };
}

/// Request message for CloudChannelService.ListTransferableSkus
class GoogleCloudChannelV1ListTransferableSkusRequest {
  /// The super admin of the resold customer generates this token to authorize a
  /// reseller to access their Cloud Identity and purchase entitlements on their
  /// behalf.
  ///
  /// You can omit this token after authorization. See
  /// https://support.google.com/a/answer/7643790 for more details.
  core.String? authToken;

  /// Customer's Cloud Identity ID
  core.String? cloudIdentityId;

  /// A reseller is required to create a customer and use the resource name of
  /// the created customer here.
  ///
  /// Customer_name uses the format:
  /// accounts/{account_id}/customers/{customer_id}
  core.String? customerName;

  /// The BCP-47 language code.
  ///
  /// For example, "en-US". The response will localize in the corresponding
  /// language code, if specified. The default value is "en-US". Optional.
  core.String? languageCode;

  /// The requested page size.
  ///
  /// Server might return fewer results than requested. If unspecified, returns
  /// at most 100 SKUs. The maximum value is 1000; the server will coerce values
  /// above 1000. Optional.
  core.int? pageSize;

  /// A token for a page of results other than the first page.
  ///
  /// Obtained using ListTransferableSkusResponse.next_page_token of the
  /// previous CloudChannelService.ListTransferableSkus call. Optional.
  core.String? pageToken;

  GoogleCloudChannelV1ListTransferableSkusRequest();

  GoogleCloudChannelV1ListTransferableSkusRequest.fromJson(core.Map _json) {
    if (_json.containsKey('authToken')) {
      authToken = _json['authToken'] as core.String;
    }
    if (_json.containsKey('cloudIdentityId')) {
      cloudIdentityId = _json['cloudIdentityId'] as core.String;
    }
    if (_json.containsKey('customerName')) {
      customerName = _json['customerName'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('pageSize')) {
      pageSize = _json['pageSize'] as core.int;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (authToken != null) 'authToken': authToken!,
        if (cloudIdentityId != null) 'cloudIdentityId': cloudIdentityId!,
        if (customerName != null) 'customerName': customerName!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (pageSize != null) 'pageSize': pageSize!,
        if (pageToken != null) 'pageToken': pageToken!,
      };
}

/// Response message for CloudChannelService.ListTransferableSkus.
class GoogleCloudChannelV1ListTransferableSkusResponse {
  /// A token to retrieve the next page of results.
  ///
  /// Pass to ListTransferableSkusRequest.page_token to obtain that page.
  core.String? nextPageToken;

  /// Information about existing SKUs for a customer that needs a transfer.
  core.List<GoogleCloudChannelV1TransferableSku>? transferableSkus;

  GoogleCloudChannelV1ListTransferableSkusResponse();

  GoogleCloudChannelV1ListTransferableSkusResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('transferableSkus')) {
      transferableSkus = (_json['transferableSkus'] as core.List)
          .map<GoogleCloudChannelV1TransferableSku>((value) =>
              GoogleCloudChannelV1TransferableSku.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (transferableSkus != null)
          'transferableSkus':
              transferableSkus!.map((value) => value.toJson()).toList(),
      };
}

/// Represents the marketing information for a Product, SKU or Offer.
class GoogleCloudChannelV1MarketingInfo {
  /// Default logo.
  GoogleCloudChannelV1Media? defaultLogo;

  /// Human readable description.
  ///
  /// Description can contain HTML.
  core.String? description;

  /// Human readable name.
  core.String? displayName;

  GoogleCloudChannelV1MarketingInfo();

  GoogleCloudChannelV1MarketingInfo.fromJson(core.Map _json) {
    if (_json.containsKey('defaultLogo')) {
      defaultLogo = GoogleCloudChannelV1Media.fromJson(
          _json['defaultLogo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (defaultLogo != null) 'defaultLogo': defaultLogo!.toJson(),
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
      };
}

/// Represents media information.
class GoogleCloudChannelV1Media {
  /// URL of the media.
  core.String? content;

  /// Title of the media.
  core.String? title;

  /// Type of the media.
  /// Possible string values are:
  /// - "MEDIA_TYPE_UNSPECIFIED" : Not used.
  /// - "MEDIA_TYPE_IMAGE" : Type of image.
  core.String? type;

  GoogleCloudChannelV1Media();

  GoogleCloudChannelV1Media.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!,
        if (title != null) 'title': title!,
        if (type != null) 'type': type!,
      };
}

/// Represents an offer made to resellers for purchase.
///
/// An offer is associated with a Sku, has a plan for payment, a price, and
/// defines the constraints for buying.
class GoogleCloudChannelV1Offer {
  /// Constraints on transacting the Offer.
  GoogleCloudChannelV1Constraints? constraints;

  /// End of the Offer validity time.
  ///
  /// Output only.
  core.String? endTime;

  /// Marketing information for the Offer.
  GoogleCloudChannelV1MarketingInfo? marketingInfo;

  /// Resource Name of the Offer.
  ///
  /// Format: accounts/{account_id}/offers/{offer_id}
  core.String? name;

  /// Parameters required to use current Offer to purchase.
  core.List<GoogleCloudChannelV1ParameterDefinition>? parameterDefinitions;

  /// Describes the payment plan for the Offer.
  GoogleCloudChannelV1Plan? plan;

  /// Price for each monetizable resource type.
  core.List<GoogleCloudChannelV1PriceByResource>? priceByResources;

  /// SKU the offer is associated with.
  GoogleCloudChannelV1Sku? sku;

  /// Start of the Offer validity time.
  core.String? startTime;

  GoogleCloudChannelV1Offer();

  GoogleCloudChannelV1Offer.fromJson(core.Map _json) {
    if (_json.containsKey('constraints')) {
      constraints = GoogleCloudChannelV1Constraints.fromJson(
          _json['constraints'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('marketingInfo')) {
      marketingInfo = GoogleCloudChannelV1MarketingInfo.fromJson(
          _json['marketingInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parameterDefinitions')) {
      parameterDefinitions = (_json['parameterDefinitions'] as core.List)
          .map<GoogleCloudChannelV1ParameterDefinition>((value) =>
              GoogleCloudChannelV1ParameterDefinition.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('plan')) {
      plan = GoogleCloudChannelV1Plan.fromJson(
          _json['plan'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('priceByResources')) {
      priceByResources = (_json['priceByResources'] as core.List)
          .map<GoogleCloudChannelV1PriceByResource>((value) =>
              GoogleCloudChannelV1PriceByResource.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('sku')) {
      sku = GoogleCloudChannelV1Sku.fromJson(
          _json['sku'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (constraints != null) 'constraints': constraints!.toJson(),
        if (endTime != null) 'endTime': endTime!,
        if (marketingInfo != null) 'marketingInfo': marketingInfo!.toJson(),
        if (name != null) 'name': name!,
        if (parameterDefinitions != null)
          'parameterDefinitions':
              parameterDefinitions!.map((value) => value.toJson()).toList(),
        if (plan != null) 'plan': plan!.toJson(),
        if (priceByResources != null)
          'priceByResources':
              priceByResources!.map((value) => value.toJson()).toList(),
        if (sku != null) 'sku': sku!.toJson(),
        if (startTime != null) 'startTime': startTime!,
      };
}

/// Provides contextual information about a google.longrunning.Operation.
class GoogleCloudChannelV1OperationMetadata {
  /// The RPC that initiated this Long Running Operation.
  /// Possible string values are:
  /// - "OPERATION_TYPE_UNSPECIFIED" : Default value. This state doesn't show
  /// unless an error occurs.
  /// - "CREATE_ENTITLEMENT" : Long Running Operation was triggered by
  /// CreateEntitlement.
  /// - "CHANGE_RENEWAL_SETTINGS" : Long Running Operation was triggered by
  /// ChangeRenewalSettings.
  /// - "START_PAID_SERVICE" : Long Running Operation was triggered by
  /// StartPaidService.
  /// - "ACTIVATE_ENTITLEMENT" : Long Running Operation was triggered by
  /// ActivateEntitlement.
  /// - "SUSPEND_ENTITLEMENT" : Long Running Operation was triggered by
  /// SuspendEntitlement.
  /// - "CANCEL_ENTITLEMENT" : Long Running Operation was triggered by
  /// CancelEntitlement.
  /// - "TRANSFER_ENTITLEMENTS" : Long Running Operation was triggered by
  /// TransferEntitlements.
  /// - "TRANSFER_ENTITLEMENTS_TO_GOOGLE" : Long Running Operation was triggered
  /// by TransferEntitlementsToGoogle.
  /// - "CHANGE_OFFER" : Long Running Operation was triggered by ChangeOffer.
  /// - "CHANGE_PARAMETERS" : Long Running Operation was triggered by
  /// ChangeParameters.
  /// - "PROVISION_CLOUD_IDENTITY" : Long Running Operation was triggered by
  /// ProvisionCloudIdentity.
  core.String? operationType;

  GoogleCloudChannelV1OperationMetadata();

  GoogleCloudChannelV1OperationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('operationType')) {
      operationType = _json['operationType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operationType != null) 'operationType': operationType!,
      };
}

/// Definition for extended entitlement parameters.
class GoogleCloudChannelV1Parameter {
  /// Specifies whether this parameter is allowed to be changed.
  ///
  /// For example, for a Google Workspace Business Starter entitlement in
  /// commitment plan, num_units is editable when entitlement is active.
  ///
  /// Output only.
  core.bool? editable;

  /// Name of the parameter.
  core.String? name;

  /// Value of the parameter.
  GoogleCloudChannelV1Value? value;

  GoogleCloudChannelV1Parameter();

  GoogleCloudChannelV1Parameter.fromJson(core.Map _json) {
    if (_json.containsKey('editable')) {
      editable = _json['editable'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = GoogleCloudChannelV1Value.fromJson(
          _json['value'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (editable != null) 'editable': editable!,
        if (name != null) 'name': name!,
        if (value != null) 'value': value!.toJson(),
      };
}

/// Parameter's definition.
///
/// Specifies what parameter is required to use the current Offer to purchase.
class GoogleCloudChannelV1ParameterDefinition {
  /// If not empty, parameter values must be drawn from this list.
  ///
  /// For example, \[us-west1, us-west2, ...\] Applicable to STRING parameter
  /// type.
  core.List<GoogleCloudChannelV1Value>? allowedValues;

  /// Maximum value of the parameter, if applicable.
  ///
  /// Inclusive. For example, maximum seats when purchasing Google Workspace
  /// Business Standard. Applicable to INT64 and DOUBLE parameter types.
  GoogleCloudChannelV1Value? maxValue;

  /// Minimal value of the parameter, if applicable.
  ///
  /// Inclusive. For example, minimal commitment when purchasing Anthos is 0.01.
  /// Applicable to INT64 and DOUBLE parameter types.
  GoogleCloudChannelV1Value? minValue;

  /// Name of the parameter.
  core.String? name;

  /// If set to true, parameter is optional to purchase this Offer.
  core.bool? optional;

  /// Data type of the parameter.
  ///
  /// Minimal value, Maximum value and allowed values will use specified data
  /// type here.
  /// Possible string values are:
  /// - "PARAMETER_TYPE_UNSPECIFIED" : Not used.
  /// - "INT64" : Int64 type.
  /// - "STRING" : String type.
  /// - "DOUBLE" : Double type.
  core.String? parameterType;

  GoogleCloudChannelV1ParameterDefinition();

  GoogleCloudChannelV1ParameterDefinition.fromJson(core.Map _json) {
    if (_json.containsKey('allowedValues')) {
      allowedValues = (_json['allowedValues'] as core.List)
          .map<GoogleCloudChannelV1Value>((value) =>
              GoogleCloudChannelV1Value.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('maxValue')) {
      maxValue = GoogleCloudChannelV1Value.fromJson(
          _json['maxValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('minValue')) {
      minValue = GoogleCloudChannelV1Value.fromJson(
          _json['minValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('optional')) {
      optional = _json['optional'] as core.bool;
    }
    if (_json.containsKey('parameterType')) {
      parameterType = _json['parameterType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedValues != null)
          'allowedValues':
              allowedValues!.map((value) => value.toJson()).toList(),
        if (maxValue != null) 'maxValue': maxValue!.toJson(),
        if (minValue != null) 'minValue': minValue!.toJson(),
        if (name != null) 'name': name!,
        if (optional != null) 'optional': optional!,
        if (parameterType != null) 'parameterType': parameterType!,
      };
}

/// Represents period in days/months/years.
class GoogleCloudChannelV1Period {
  /// Total duration of Period Type defined.
  core.int? duration;

  /// Period Type.
  /// Possible string values are:
  /// - "PERIOD_TYPE_UNSPECIFIED" : Not used.
  /// - "DAY" : Day.
  /// - "MONTH" : Month.
  /// - "YEAR" : Year.
  core.String? periodType;

  GoogleCloudChannelV1Period();

  GoogleCloudChannelV1Period.fromJson(core.Map _json) {
    if (_json.containsKey('duration')) {
      duration = _json['duration'] as core.int;
    }
    if (_json.containsKey('periodType')) {
      periodType = _json['periodType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (duration != null) 'duration': duration!,
        if (periodType != null) 'periodType': periodType!,
      };
}

/// The payment plan for the Offer.
///
/// Describes how to make a payment.
class GoogleCloudChannelV1Plan {
  /// Reseller Billing account to charge after an offer transaction.
  ///
  /// Only present for Google Cloud Platform offers.
  core.String? billingAccount;

  /// Describes how frequently the reseller will be billed, such as once per
  /// month.
  GoogleCloudChannelV1Period? paymentCycle;

  /// Describes how a reseller will be billed.
  /// Possible string values are:
  /// - "PAYMENT_PLAN_UNSPECIFIED" : Not used.
  /// - "COMMITMENT" : Commitment.
  /// - "FLEXIBLE" : No commitment.
  /// - "FREE" : Free.
  /// - "TRIAL" : Trial.
  /// - "OFFLINE" : Price and ordering not available through API.
  core.String? paymentPlan;

  /// Specifies when the payment needs to happen.
  /// Possible string values are:
  /// - "PAYMENT_TYPE_UNSPECIFIED" : Not used.
  /// - "PREPAY" : Prepay. Amount has to be paid before service is rendered.
  /// - "POSTPAY" : Postpay. Reseller is charged at the end of the Payment
  /// cycle.
  core.String? paymentType;

  /// Present for Offers with a trial period.
  ///
  /// For trial-only Offers, a paid service needs to start before the trial
  /// period ends for continued service. For Regular Offers with a trial period,
  /// the regular pricing goes into effect when trial period ends, or if paid
  /// service is started before the end of the trial period.
  GoogleCloudChannelV1Period? trialPeriod;

  GoogleCloudChannelV1Plan();

  GoogleCloudChannelV1Plan.fromJson(core.Map _json) {
    if (_json.containsKey('billingAccount')) {
      billingAccount = _json['billingAccount'] as core.String;
    }
    if (_json.containsKey('paymentCycle')) {
      paymentCycle = GoogleCloudChannelV1Period.fromJson(
          _json['paymentCycle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('paymentPlan')) {
      paymentPlan = _json['paymentPlan'] as core.String;
    }
    if (_json.containsKey('paymentType')) {
      paymentType = _json['paymentType'] as core.String;
    }
    if (_json.containsKey('trialPeriod')) {
      trialPeriod = GoogleCloudChannelV1Period.fromJson(
          _json['trialPeriod'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (billingAccount != null) 'billingAccount': billingAccount!,
        if (paymentCycle != null) 'paymentCycle': paymentCycle!.toJson(),
        if (paymentPlan != null) 'paymentPlan': paymentPlan!,
        if (paymentType != null) 'paymentType': paymentType!,
        if (trialPeriod != null) 'trialPeriod': trialPeriod!.toJson(),
      };
}

/// Represents the price of the Offer.
class GoogleCloudChannelV1Price {
  /// Base price.
  GoogleTypeMoney? basePrice;

  /// Discount percentage, represented as decimal.
  ///
  /// For example, a 20% discount will be represent as 0.2.
  core.double? discount;

  /// Effective Price after applying the discounts.
  GoogleTypeMoney? effectivePrice;

  /// Link to external price list, such as link to Google Voice rate card.
  core.String? externalPriceUri;

  GoogleCloudChannelV1Price();

  GoogleCloudChannelV1Price.fromJson(core.Map _json) {
    if (_json.containsKey('basePrice')) {
      basePrice = GoogleTypeMoney.fromJson(
          _json['basePrice'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('discount')) {
      discount = (_json['discount'] as core.num).toDouble();
    }
    if (_json.containsKey('effectivePrice')) {
      effectivePrice = GoogleTypeMoney.fromJson(
          _json['effectivePrice'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('externalPriceUri')) {
      externalPriceUri = _json['externalPriceUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (basePrice != null) 'basePrice': basePrice!.toJson(),
        if (discount != null) 'discount': discount!,
        if (effectivePrice != null) 'effectivePrice': effectivePrice!.toJson(),
        if (externalPriceUri != null) 'externalPriceUri': externalPriceUri!,
      };
}

/// Represents price by resource type.
class GoogleCloudChannelV1PriceByResource {
  /// Price of the Offer.
  ///
  /// Present if there are no price phases.
  GoogleCloudChannelV1Price? price;

  /// Specifies the price by time range.
  core.List<GoogleCloudChannelV1PricePhase>? pricePhases;

  /// Resource Type.
  ///
  /// Example: SEAT
  /// Possible string values are:
  /// - "RESOURCE_TYPE_UNSPECIFIED" : Not used.
  /// - "SEAT" : Seat.
  /// - "MAU" : Monthly active user.
  /// - "GB" : GB (used for storage SKUs).
  /// - "LICENSED_USER" : Active licensed users(for Voice SKUs).
  /// - "MINUTES" : Voice usage.
  /// - "IAAS_USAGE" : For IaaS SKUs like Google Cloud Platform, monetization is
  /// based on usage accrued on your billing account irrespective of the type of
  /// monetizable resource. This enum represents an aggregated
  /// resource/container for all usage SKUs on a billing account. Currently,
  /// only applicable to Google Cloud Platform.
  /// - "SUBSCRIPTION" : For Google Cloud Platform subscriptions like Anthos or
  /// SAP.
  core.String? resourceType;

  GoogleCloudChannelV1PriceByResource();

  GoogleCloudChannelV1PriceByResource.fromJson(core.Map _json) {
    if (_json.containsKey('price')) {
      price = GoogleCloudChannelV1Price.fromJson(
          _json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pricePhases')) {
      pricePhases = (_json['pricePhases'] as core.List)
          .map<GoogleCloudChannelV1PricePhase>((value) =>
              GoogleCloudChannelV1PricePhase.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resourceType')) {
      resourceType = _json['resourceType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (price != null) 'price': price!.toJson(),
        if (pricePhases != null)
          'pricePhases': pricePhases!.map((value) => value.toJson()).toList(),
        if (resourceType != null) 'resourceType': resourceType!,
      };
}

/// Specifies the price by the duration of months.
///
/// For example, a 20% discount for the first six months, then a 10% discount
/// starting on the seventh month.
class GoogleCloudChannelV1PricePhase {
  /// Defines first period for the phase.
  core.int? firstPeriod;

  /// Defines first period for the phase.
  core.int? lastPeriod;

  /// Defines the phase period type.
  /// Possible string values are:
  /// - "PERIOD_TYPE_UNSPECIFIED" : Not used.
  /// - "DAY" : Day.
  /// - "MONTH" : Month.
  /// - "YEAR" : Year.
  core.String? periodType;

  /// Price of the phase.
  ///
  /// Present if there are no price tiers.
  GoogleCloudChannelV1Price? price;

  /// Price by the resource tiers.
  core.List<GoogleCloudChannelV1PriceTier>? priceTiers;

  GoogleCloudChannelV1PricePhase();

  GoogleCloudChannelV1PricePhase.fromJson(core.Map _json) {
    if (_json.containsKey('firstPeriod')) {
      firstPeriod = _json['firstPeriod'] as core.int;
    }
    if (_json.containsKey('lastPeriod')) {
      lastPeriod = _json['lastPeriod'] as core.int;
    }
    if (_json.containsKey('periodType')) {
      periodType = _json['periodType'] as core.String;
    }
    if (_json.containsKey('price')) {
      price = GoogleCloudChannelV1Price.fromJson(
          _json['price'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('priceTiers')) {
      priceTiers = (_json['priceTiers'] as core.List)
          .map<GoogleCloudChannelV1PriceTier>((value) =>
              GoogleCloudChannelV1PriceTier.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (firstPeriod != null) 'firstPeriod': firstPeriod!,
        if (lastPeriod != null) 'lastPeriod': lastPeriod!,
        if (periodType != null) 'periodType': periodType!,
        if (price != null) 'price': price!.toJson(),
        if (priceTiers != null)
          'priceTiers': priceTiers!.map((value) => value.toJson()).toList(),
      };
}

/// Defines price at resource tier level.
///
/// For example, an offer with following definition : * Tier 1: Provide 25%
/// discount for all seats between 1 and 25. * Tier 2: Provide 10% discount for
/// all seats between 26 and 100. * Tier 3: Provide flat 15% discount for all
/// seats above 100. Each of these tiers is represented as a PriceTier.
class GoogleCloudChannelV1PriceTier {
  /// First resource for which the tier price applies.
  core.int? firstResource;

  /// Last resource for which the tier price applies.
  core.int? lastResource;

  /// Price of the tier.
  GoogleCloudChannelV1Price? price;

  GoogleCloudChannelV1PriceTier();

  GoogleCloudChannelV1PriceTier.fromJson(core.Map _json) {
    if (_json.containsKey('firstResource')) {
      firstResource = _json['firstResource'] as core.int;
    }
    if (_json.containsKey('lastResource')) {
      lastResource = _json['lastResource'] as core.int;
    }
    if (_json.containsKey('price')) {
      price = GoogleCloudChannelV1Price.fromJson(
          _json['price'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (firstResource != null) 'firstResource': firstResource!,
        if (lastResource != null) 'lastResource': lastResource!,
        if (price != null) 'price': price!.toJson(),
      };
}

/// A Product is the entity a customer uses when placing an order.
///
/// For example, Google Workspace, Google Voice, etc.
class GoogleCloudChannelV1Product {
  /// Marketing information for the product.
  GoogleCloudChannelV1MarketingInfo? marketingInfo;

  /// Resource Name of the Product.
  ///
  /// Format: products/{product_id}
  core.String? name;

  GoogleCloudChannelV1Product();

  GoogleCloudChannelV1Product.fromJson(core.Map _json) {
    if (_json.containsKey('marketingInfo')) {
      marketingInfo = GoogleCloudChannelV1MarketingInfo.fromJson(
          _json['marketingInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (marketingInfo != null) 'marketingInfo': marketingInfo!.toJson(),
        if (name != null) 'name': name!,
      };
}

/// Request message for CloudChannelService.ProvisionCloudIdentity
class GoogleCloudChannelV1ProvisionCloudIdentityRequest {
  /// CloudIdentity-specific customer information.
  GoogleCloudChannelV1CloudIdentityInfo? cloudIdentityInfo;

  /// Admin user information.
  GoogleCloudChannelV1AdminUser? user;

  /// Validate the request and preview the review, but do not post it.
  core.bool? validateOnly;

  GoogleCloudChannelV1ProvisionCloudIdentityRequest();

  GoogleCloudChannelV1ProvisionCloudIdentityRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cloudIdentityInfo')) {
      cloudIdentityInfo = GoogleCloudChannelV1CloudIdentityInfo.fromJson(
          _json['cloudIdentityInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('user')) {
      user = GoogleCloudChannelV1AdminUser.fromJson(
          _json['user'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('validateOnly')) {
      validateOnly = _json['validateOnly'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudIdentityInfo != null)
          'cloudIdentityInfo': cloudIdentityInfo!.toJson(),
        if (user != null) 'user': user!.toJson(),
        if (validateOnly != null) 'validateOnly': validateOnly!,
      };
}

/// Service provisioned for an entitlement.
class GoogleCloudChannelV1ProvisionedService {
  /// The product pertaining to the provisioning resource as specified in the
  /// Offer.
  ///
  /// Output only.
  core.String? productId;

  /// Provisioning ID of the entitlement.
  ///
  /// For Google Workspace, this would be the underlying Subscription ID.
  ///
  /// Output only.
  core.String? provisioningId;

  /// The SKU pertaining to the provisioning resource as specified in the Offer.
  ///
  /// Output only.
  core.String? skuId;

  GoogleCloudChannelV1ProvisionedService();

  GoogleCloudChannelV1ProvisionedService.fromJson(core.Map _json) {
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('provisioningId')) {
      provisioningId = _json['provisioningId'] as core.String;
    }
    if (_json.containsKey('skuId')) {
      skuId = _json['skuId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (productId != null) 'productId': productId!,
        if (provisioningId != null) 'provisioningId': provisioningId!,
        if (skuId != null) 'skuId': skuId!,
      };
}

/// Offer that you can purchase for a customer.
///
/// This is used in the ListPurchasableOffer API response.
class GoogleCloudChannelV1PurchasableOffer {
  /// Offer.
  GoogleCloudChannelV1Offer? offer;

  GoogleCloudChannelV1PurchasableOffer();

  GoogleCloudChannelV1PurchasableOffer.fromJson(core.Map _json) {
    if (_json.containsKey('offer')) {
      offer = GoogleCloudChannelV1Offer.fromJson(
          _json['offer'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (offer != null) 'offer': offer!.toJson(),
      };
}

/// SKU that you can purchase.
///
/// This is used in ListPurchasableSku API response.
class GoogleCloudChannelV1PurchasableSku {
  /// SKU
  GoogleCloudChannelV1Sku? sku;

  GoogleCloudChannelV1PurchasableSku();

  GoogleCloudChannelV1PurchasableSku.fromJson(core.Map _json) {
    if (_json.containsKey('sku')) {
      sku = GoogleCloudChannelV1Sku.fromJson(
          _json['sku'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sku != null) 'sku': sku!.toJson(),
      };
}

/// Request Message for RegisterSubscriber.
class GoogleCloudChannelV1RegisterSubscriberRequest {
  /// Service account that provides subscriber access to the registered topic.
  ///
  /// Required.
  core.String? serviceAccount;

  GoogleCloudChannelV1RegisterSubscriberRequest();

  GoogleCloudChannelV1RegisterSubscriberRequest.fromJson(core.Map _json) {
    if (_json.containsKey('serviceAccount')) {
      serviceAccount = _json['serviceAccount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (serviceAccount != null) 'serviceAccount': serviceAccount!,
      };
}

/// Response Message for RegisterSubscriber.
class GoogleCloudChannelV1RegisterSubscriberResponse {
  /// Name of the topic the subscriber will listen to.
  core.String? topic;

  GoogleCloudChannelV1RegisterSubscriberResponse();

  GoogleCloudChannelV1RegisterSubscriberResponse.fromJson(core.Map _json) {
    if (_json.containsKey('topic')) {
      topic = _json['topic'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (topic != null) 'topic': topic!,
      };
}

/// Renewal settings for renewable Offers.
class GoogleCloudChannelV1RenewalSettings {
  /// If false, the plan will be completed at the end date.
  core.bool? enableRenewal;

  /// Describes how frequently the reseller will be billed, such as once per
  /// month.
  GoogleCloudChannelV1Period? paymentCycle;

  /// Describes how a reseller will be billed.
  /// Possible string values are:
  /// - "PAYMENT_PLAN_UNSPECIFIED" : Not used.
  /// - "COMMITMENT" : Commitment.
  /// - "FLEXIBLE" : No commitment.
  /// - "FREE" : Free.
  /// - "TRIAL" : Trial.
  /// - "OFFLINE" : Price and ordering not available through API.
  core.String? paymentPlan;

  /// If true and enable_renewal = true, the unit (for example seats or
  /// licenses) will be set to the number of active units at renewal time.
  core.bool? resizeUnitCount;

  GoogleCloudChannelV1RenewalSettings();

  GoogleCloudChannelV1RenewalSettings.fromJson(core.Map _json) {
    if (_json.containsKey('enableRenewal')) {
      enableRenewal = _json['enableRenewal'] as core.bool;
    }
    if (_json.containsKey('paymentCycle')) {
      paymentCycle = GoogleCloudChannelV1Period.fromJson(
          _json['paymentCycle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('paymentPlan')) {
      paymentPlan = _json['paymentPlan'] as core.String;
    }
    if (_json.containsKey('resizeUnitCount')) {
      resizeUnitCount = _json['resizeUnitCount'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enableRenewal != null) 'enableRenewal': enableRenewal!,
        if (paymentCycle != null) 'paymentCycle': paymentCycle!.toJson(),
        if (paymentPlan != null) 'paymentPlan': paymentPlan!,
        if (resizeUnitCount != null) 'resizeUnitCount': resizeUnitCount!,
      };
}

/// Represents a product's purchasable Stock Keeping Unit (SKU).
///
/// SKUs represent the different variations of the product. For example, Google
/// Workspace Business Standard and Google Workspace Business Plus are Google
/// Workspace product SKUs.
class GoogleCloudChannelV1Sku {
  /// Marketing information for the SKU.
  GoogleCloudChannelV1MarketingInfo? marketingInfo;

  /// Resource Name of the SKU.
  ///
  /// Format: products/{product_id}/skus/{sku_id}
  core.String? name;

  /// Product the SKU is associated with.
  GoogleCloudChannelV1Product? product;

  GoogleCloudChannelV1Sku();

  GoogleCloudChannelV1Sku.fromJson(core.Map _json) {
    if (_json.containsKey('marketingInfo')) {
      marketingInfo = GoogleCloudChannelV1MarketingInfo.fromJson(
          _json['marketingInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('product')) {
      product = GoogleCloudChannelV1Product.fromJson(
          _json['product'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (marketingInfo != null) 'marketingInfo': marketingInfo!.toJson(),
        if (name != null) 'name': name!,
        if (product != null) 'product': product!.toJson(),
      };
}

/// Request message for CloudChannelService.StartPaidService.
class GoogleCloudChannelV1StartPaidServiceRequest {
  /// You can specify an optional unique request ID, and if you need to retry
  /// your request, the server will know to ignore the request if it's complete.
  ///
  /// For example, you make an initial request and the request times out. If you
  /// make the request again with the same request ID, the server can check if
  /// it received the original operation with the same request ID. If it did, it
  /// will ignore the second request. The request ID must be a valid
  /// [UUID](https://tools.ietf.org/html/rfc4122) with the exception that zero
  /// UUID is not supported (`00000000-0000-0000-0000-000000000000`).
  ///
  /// Optional.
  core.String? requestId;

  GoogleCloudChannelV1StartPaidServiceRequest();

  GoogleCloudChannelV1StartPaidServiceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (requestId != null) 'requestId': requestId!,
      };
}

/// Represents information which resellers will get as part of notification from
/// Cloud Pub/Sub.
class GoogleCloudChannelV1SubscriberEvent {
  /// Customer event send as part of Pub/Sub event to partners.
  GoogleCloudChannelV1CustomerEvent? customerEvent;

  /// Entitlement event send as part of Pub/Sub event to partners.
  GoogleCloudChannelV1EntitlementEvent? entitlementEvent;

  GoogleCloudChannelV1SubscriberEvent();

  GoogleCloudChannelV1SubscriberEvent.fromJson(core.Map _json) {
    if (_json.containsKey('customerEvent')) {
      customerEvent = GoogleCloudChannelV1CustomerEvent.fromJson(
          _json['customerEvent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('entitlementEvent')) {
      entitlementEvent = GoogleCloudChannelV1EntitlementEvent.fromJson(
          _json['entitlementEvent'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customerEvent != null) 'customerEvent': customerEvent!.toJson(),
        if (entitlementEvent != null)
          'entitlementEvent': entitlementEvent!.toJson(),
      };
}

/// Request message for CloudChannelService.SuspendEntitlement.
class GoogleCloudChannelV1SuspendEntitlementRequest {
  /// You can specify an optional unique request ID, and if you need to retry
  /// your request, the server will know to ignore the request if it's complete.
  ///
  /// For example, you make an initial request and the request times out. If you
  /// make the request again with the same request ID, the server can check if
  /// it received the original operation with the same request ID. If it did, it
  /// will ignore the second request. The request ID must be a valid
  /// [UUID](https://tools.ietf.org/html/rfc4122) with the exception that zero
  /// UUID is not supported (`00000000-0000-0000-0000-000000000000`).
  ///
  /// Optional.
  core.String? requestId;

  GoogleCloudChannelV1SuspendEntitlementRequest();

  GoogleCloudChannelV1SuspendEntitlementRequest.fromJson(core.Map _json) {
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (requestId != null) 'requestId': requestId!,
      };
}

/// Specifies transfer eligibility of a SKU.
class GoogleCloudChannelV1TransferEligibility {
  /// Localized description if reseller is not eligible to transfer the SKU.
  core.String? description;

  /// Specified the reason for ineligibility.
  /// Possible string values are:
  /// - "REASON_UNSPECIFIED" : Reason is not available.
  /// - "PENDING_TOS_ACCEPTANCE" : Reseller needs to accept TOS before
  /// transferring the SKU.
  /// - "SKU_NOT_ELIGIBLE" : Reseller not eligible to sell the SKU.
  /// - "SKU_SUSPENDED" : SKU subscription is suspended
  core.String? ineligibilityReason;

  /// Whether reseller is eligible to transfer the SKU.
  core.bool? isEligible;

  GoogleCloudChannelV1TransferEligibility();

  GoogleCloudChannelV1TransferEligibility.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('ineligibilityReason')) {
      ineligibilityReason = _json['ineligibilityReason'] as core.String;
    }
    if (_json.containsKey('isEligible')) {
      isEligible = _json['isEligible'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (ineligibilityReason != null)
          'ineligibilityReason': ineligibilityReason!,
        if (isEligible != null) 'isEligible': isEligible!,
      };
}

/// Request message for CloudChannelService.TransferEntitlements.
class GoogleCloudChannelV1TransferEntitlementsRequest {
  /// The super admin of the resold customer generates this token to authorize a
  /// reseller to access their Cloud Identity and purchase entitlements on their
  /// behalf.
  ///
  /// You can omit this token after authorization. See
  /// https://support.google.com/a/answer/7643790 for more details.
  core.String? authToken;

  /// The new entitlements to create or transfer.
  ///
  /// Required.
  core.List<GoogleCloudChannelV1Entitlement>? entitlements;

  /// You can specify an optional unique request ID, and if you need to retry
  /// your request, the server will know to ignore the request if it's complete.
  ///
  /// For example, you make an initial request and the request times out. If you
  /// make the request again with the same request ID, the server can check if
  /// it received the original operation with the same request ID. If it did, it
  /// will ignore the second request. The request ID must be a valid
  /// [UUID](https://tools.ietf.org/html/rfc4122) with the exception that zero
  /// UUID is not supported (`00000000-0000-0000-0000-000000000000`).
  ///
  /// Optional.
  core.String? requestId;

  GoogleCloudChannelV1TransferEntitlementsRequest();

  GoogleCloudChannelV1TransferEntitlementsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('authToken')) {
      authToken = _json['authToken'] as core.String;
    }
    if (_json.containsKey('entitlements')) {
      entitlements = (_json['entitlements'] as core.List)
          .map<GoogleCloudChannelV1Entitlement>((value) =>
              GoogleCloudChannelV1Entitlement.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (authToken != null) 'authToken': authToken!,
        if (entitlements != null)
          'entitlements': entitlements!.map((value) => value.toJson()).toList(),
        if (requestId != null) 'requestId': requestId!,
      };
}

/// Response message for CloudChannelService.TransferEntitlements.
///
/// This is put in the response field of google.longrunning.Operation.
class GoogleCloudChannelV1TransferEntitlementsResponse {
  /// The transferred entitlements.
  core.List<GoogleCloudChannelV1Entitlement>? entitlements;

  GoogleCloudChannelV1TransferEntitlementsResponse();

  GoogleCloudChannelV1TransferEntitlementsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entitlements')) {
      entitlements = (_json['entitlements'] as core.List)
          .map<GoogleCloudChannelV1Entitlement>((value) =>
              GoogleCloudChannelV1Entitlement.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entitlements != null)
          'entitlements': entitlements!.map((value) => value.toJson()).toList(),
      };
}

/// Request message for CloudChannelService.TransferEntitlementsToGoogle.
class GoogleCloudChannelV1TransferEntitlementsToGoogleRequest {
  /// The entitlements to transfer to Google.
  ///
  /// Required.
  core.List<GoogleCloudChannelV1Entitlement>? entitlements;

  /// You can specify an optional unique request ID, and if you need to retry
  /// your request, the server will know to ignore the request if it's complete.
  ///
  /// For example, you make an initial request and the request times out. If you
  /// make the request again with the same request ID, the server can check if
  /// it received the original operation with the same request ID. If it did, it
  /// will ignore the second request. The request ID must be a valid
  /// [UUID](https://tools.ietf.org/html/rfc4122) with the exception that zero
  /// UUID is not supported (`00000000-0000-0000-0000-000000000000`).
  ///
  /// Optional.
  core.String? requestId;

  GoogleCloudChannelV1TransferEntitlementsToGoogleRequest();

  GoogleCloudChannelV1TransferEntitlementsToGoogleRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('entitlements')) {
      entitlements = (_json['entitlements'] as core.List)
          .map<GoogleCloudChannelV1Entitlement>((value) =>
              GoogleCloudChannelV1Entitlement.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entitlements != null)
          'entitlements': entitlements!.map((value) => value.toJson()).toList(),
        if (requestId != null) 'requestId': requestId!,
      };
}

/// TransferableOffer represents an Offer that can be used in Transfer.
///
/// Read-only.
class GoogleCloudChannelV1TransferableOffer {
  /// Offer with parameter constraints updated to allow the Transfer.
  GoogleCloudChannelV1Offer? offer;

  GoogleCloudChannelV1TransferableOffer();

  GoogleCloudChannelV1TransferableOffer.fromJson(core.Map _json) {
    if (_json.containsKey('offer')) {
      offer = GoogleCloudChannelV1Offer.fromJson(
          _json['offer'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (offer != null) 'offer': offer!.toJson(),
      };
}

/// TransferableSku represents information a reseller needs to view existing
/// provisioned services for a customer that they do not own.
///
/// Read-only.
class GoogleCloudChannelV1TransferableSku {
  /// The customer to transfer has an entitlement with the populated legacy SKU.
  ///
  /// Optional.
  GoogleCloudChannelV1Sku? legacySku;

  /// The SKU pertaining to the provisioning resource as specified in the Offer.
  GoogleCloudChannelV1Sku? sku;

  /// Describes the transfer eligibility of a SKU.
  GoogleCloudChannelV1TransferEligibility? transferEligibility;

  GoogleCloudChannelV1TransferableSku();

  GoogleCloudChannelV1TransferableSku.fromJson(core.Map _json) {
    if (_json.containsKey('legacySku')) {
      legacySku = GoogleCloudChannelV1Sku.fromJson(
          _json['legacySku'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sku')) {
      sku = GoogleCloudChannelV1Sku.fromJson(
          _json['sku'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('transferEligibility')) {
      transferEligibility = GoogleCloudChannelV1TransferEligibility.fromJson(
          _json['transferEligibility'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (legacySku != null) 'legacySku': legacySku!.toJson(),
        if (sku != null) 'sku': sku!.toJson(),
        if (transferEligibility != null)
          'transferEligibility': transferEligibility!.toJson(),
      };
}

/// Settings for trial offers.
class GoogleCloudChannelV1TrialSettings {
  /// Date when the trial ends.
  ///
  /// The value is in milliseconds using the UNIX Epoch format. See an example
  /// [Epoch converter](https://www.epochconverter.com).
  core.String? endTime;

  /// Determines if the entitlement is in a trial or not: * `true` - The
  /// entitlement is in trial.
  ///
  /// * `false` - The entitlement is not in trial.
  core.bool? trial;

  GoogleCloudChannelV1TrialSettings();

  GoogleCloudChannelV1TrialSettings.fromJson(core.Map _json) {
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('trial')) {
      trial = _json['trial'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTime != null) 'endTime': endTime!,
        if (trial != null) 'trial': trial!,
      };
}

/// Request Message for UnregisterSubscriber.
class GoogleCloudChannelV1UnregisterSubscriberRequest {
  /// Service account to unregister from subscriber access to the topic.
  ///
  /// Required.
  core.String? serviceAccount;

  GoogleCloudChannelV1UnregisterSubscriberRequest();

  GoogleCloudChannelV1UnregisterSubscriberRequest.fromJson(core.Map _json) {
    if (_json.containsKey('serviceAccount')) {
      serviceAccount = _json['serviceAccount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (serviceAccount != null) 'serviceAccount': serviceAccount!,
      };
}

/// Response Message for UnregisterSubscriber.
class GoogleCloudChannelV1UnregisterSubscriberResponse {
  /// Name of the topic the service account subscriber access was removed from.
  core.String? topic;

  GoogleCloudChannelV1UnregisterSubscriberResponse();

  GoogleCloudChannelV1UnregisterSubscriberResponse.fromJson(core.Map _json) {
    if (_json.containsKey('topic')) {
      topic = _json['topic'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (topic != null) 'topic': topic!,
      };
}

/// Request message for CloudChannelService.UpdateChannelPartnerLink
class GoogleCloudChannelV1UpdateChannelPartnerLinkRequest {
  /// The channel partner link to update.
  ///
  /// Only channel_partner_link.link_state is allowed for updates.
  ///
  /// Required.
  GoogleCloudChannelV1ChannelPartnerLink? channelPartnerLink;

  /// The update mask that applies to the resource.
  ///
  /// The only allowable value for an update mask is
  /// channel_partner_link.link_state.
  ///
  /// Required.
  core.String? updateMask;

  GoogleCloudChannelV1UpdateChannelPartnerLinkRequest();

  GoogleCloudChannelV1UpdateChannelPartnerLinkRequest.fromJson(core.Map _json) {
    if (_json.containsKey('channelPartnerLink')) {
      channelPartnerLink = GoogleCloudChannelV1ChannelPartnerLink.fromJson(
          _json['channelPartnerLink'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateMask')) {
      updateMask = _json['updateMask'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (channelPartnerLink != null)
          'channelPartnerLink': channelPartnerLink!.toJson(),
        if (updateMask != null) 'updateMask': updateMask!,
      };
}

/// Data type and value of a parameter.
class GoogleCloudChannelV1Value {
  /// Represents a boolean value.
  core.bool? boolValue;

  /// Represents a double value.
  core.double? doubleValue;

  /// Represents an int64 value.
  core.String? int64Value;

  /// Represents an 'Any' proto value.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? protoValue;

  /// Represents a string value.
  core.String? stringValue;

  GoogleCloudChannelV1Value();

  GoogleCloudChannelV1Value.fromJson(core.Map _json) {
    if (_json.containsKey('boolValue')) {
      boolValue = _json['boolValue'] as core.bool;
    }
    if (_json.containsKey('doubleValue')) {
      doubleValue = (_json['doubleValue'] as core.num).toDouble();
    }
    if (_json.containsKey('int64Value')) {
      int64Value = _json['int64Value'] as core.String;
    }
    if (_json.containsKey('protoValue')) {
      protoValue =
          (_json['protoValue'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('stringValue')) {
      stringValue = _json['stringValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (boolValue != null) 'boolValue': boolValue!,
        if (doubleValue != null) 'doubleValue': doubleValue!,
        if (int64Value != null) 'int64Value': int64Value!,
        if (protoValue != null) 'protoValue': protoValue!,
        if (stringValue != null) 'stringValue': stringValue!,
      };
}

/// Association links that an entitlement has to other entitlements.
class GoogleCloudChannelV1alpha1AssociationInfo {
  /// The name of the base entitlement, for which this entitlement is an add-on.
  core.String? baseEntitlement;

  GoogleCloudChannelV1alpha1AssociationInfo();

  GoogleCloudChannelV1alpha1AssociationInfo.fromJson(core.Map _json) {
    if (_json.containsKey('baseEntitlement')) {
      baseEntitlement = _json['baseEntitlement'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (baseEntitlement != null) 'baseEntitlement': baseEntitlement!,
      };
}

/// Commitment settings for commitment-based offers.
class GoogleCloudChannelV1alpha1CommitmentSettings {
  /// Commitment end timestamp.
  ///
  /// Output only.
  core.String? endTime;

  /// Renewal settings applicable for a commitment-based Offer.
  ///
  /// Optional.
  GoogleCloudChannelV1alpha1RenewalSettings? renewalSettings;

  /// Commitment start timestamp.
  ///
  /// Output only.
  core.String? startTime;

  GoogleCloudChannelV1alpha1CommitmentSettings();

  GoogleCloudChannelV1alpha1CommitmentSettings.fromJson(core.Map _json) {
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('renewalSettings')) {
      renewalSettings = GoogleCloudChannelV1alpha1RenewalSettings.fromJson(
          _json['renewalSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTime != null) 'endTime': endTime!,
        if (renewalSettings != null)
          'renewalSettings': renewalSettings!.toJson(),
        if (startTime != null) 'startTime': startTime!,
      };
}

/// Represents Pub/Sub message content describing customer update.
class GoogleCloudChannelV1alpha1CustomerEvent {
  /// Resource name of the customer.
  ///
  /// Format: accounts/{account_id}/customers/{customer_id}
  core.String? customer;

  /// Type of event which happened on the customer.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Default value. This state doesn't show unless an
  /// error occurs.
  /// - "PRIMARY_DOMAIN_CHANGED" : Primary domain for customer was changed.
  /// - "PRIMARY_DOMAIN_VERIFIED" : Primary domain of the customer has been
  /// verified.
  core.String? eventType;

  GoogleCloudChannelV1alpha1CustomerEvent();

  GoogleCloudChannelV1alpha1CustomerEvent.fromJson(core.Map _json) {
    if (_json.containsKey('customer')) {
      customer = _json['customer'] as core.String;
    }
    if (_json.containsKey('eventType')) {
      eventType = _json['eventType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customer != null) 'customer': customer!,
        if (eventType != null) 'eventType': eventType!,
      };
}

/// An entitlement is a representation of a customer's ability to use a service.
class GoogleCloudChannelV1alpha1Entitlement {
  /// The current number of users that are assigned a license for the product
  /// defined in provisioned_service.skuId.
  ///
  /// Read-only. Deprecated: Use `parameters` instead.
  core.int? assignedUnits;

  /// Association information to other entitlements.
  GoogleCloudChannelV1alpha1AssociationInfo? associationInfo;

  /// Cloud Identity ID of a channel partner who will be the direct reseller for
  /// the customer's order.
  ///
  /// This field is generally used in 2-tier ordering, where the order is placed
  /// by a top-level distributor on behalf of their channel partner or reseller.
  /// Required for distributors. Deprecated: `channel_partner_id` has been moved
  /// to the Customer.
  core.String? channelPartnerId;

  /// Commitment settings for a commitment-based Offer.
  ///
  /// Required for commitment based offers.
  GoogleCloudChannelV1alpha1CommitmentSettings? commitmentSettings;

  /// The time at which the entitlement is created.
  ///
  /// Output only.
  core.String? createTime;

  /// Maximum number of units for a non commitment-based Offer, such as
  /// Flexible, Trial or Free entitlements.
  ///
  /// For commitment-based entitlements, this is a read-only field, which only
  /// the internal support team can update. Deprecated: Use `parameters`
  /// instead.
  core.int? maxUnits;

  /// Resource name of an entitlement in the form:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}.
  ///
  /// Output only.
  core.String? name;

  /// Number of units for a commitment-based Offer.
  ///
  /// For example, for seat-based Offers, this would be the number of seats; for
  /// license-based Offers, this would be the number of licenses. Required for
  /// creating commitment-based Offers. Deprecated: Use `parameters` instead.
  core.int? numUnits;

  /// The offer resource name for which the entitlement is to be created.
  ///
  /// Takes the form: accounts/{account_id}/offers/{offer_id}.
  ///
  /// Required.
  core.String? offer;

  /// Extended entitlement parameters.
  ///
  /// When creating an entitlement, valid parameters' names and values are
  /// defined in the offer's parameter definitions.
  core.List<GoogleCloudChannelV1alpha1Parameter>? parameters;

  /// Service provisioning details for the entitlement.
  ///
  /// Output only.
  GoogleCloudChannelV1alpha1ProvisionedService? provisionedService;

  /// Current provisioning state of the entitlement.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "PROVISIONING_STATE_UNSPECIFIED" : Default value. This state doesn't
  /// show unless an error occurs.
  /// - "ACTIVE" : The entitlement is currently active.
  /// - "CANCELED" : The entitlement was canceled. After an entitlement is
  /// `CANCELED`, its status will not change. Deprecated: Canceled entitlements
  /// will no longer be visible.
  /// - "COMPLETE" : The entitlement reached end of term and was not renewed.
  /// After an entitlement is `COMPLETE`, its status will not change.
  /// Deprecated: This is represented as ProvisioningState=SUSPENDED and
  /// suspensionReason in (TRIAL_ENDED, RENEWAL_WITH_TYPE_CANCEL)
  /// - "PENDING" : The entitlement is pending. Deprecated: This is represented
  /// as ProvisioningState=SUSPENDED and suspensionReason=PENDING_TOS_ACCEPTANCE
  /// - "SUSPENDED" : The entitlement is currently suspended.
  core.String? provisioningState;

  /// This purchase order (PO) information is for resellers to use for their
  /// company tracking usage.
  ///
  /// If a purchaseOrderId value is given, it appears in the API responses and
  /// shows up in the invoice. The property accepts up to 80 plain text
  /// characters.
  ///
  /// Optional.
  core.String? purchaseOrderId;

  /// Enumerable of all current suspension reasons for an entitlement.
  ///
  /// Output only.
  core.List<core.String>? suspensionReasons;

  /// Settings for trial offers.
  ///
  /// Output only.
  GoogleCloudChannelV1alpha1TrialSettings? trialSettings;

  /// The time at which the entitlement is updated.
  ///
  /// Output only.
  core.String? updateTime;

  GoogleCloudChannelV1alpha1Entitlement();

  GoogleCloudChannelV1alpha1Entitlement.fromJson(core.Map _json) {
    if (_json.containsKey('assignedUnits')) {
      assignedUnits = _json['assignedUnits'] as core.int;
    }
    if (_json.containsKey('associationInfo')) {
      associationInfo = GoogleCloudChannelV1alpha1AssociationInfo.fromJson(
          _json['associationInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('channelPartnerId')) {
      channelPartnerId = _json['channelPartnerId'] as core.String;
    }
    if (_json.containsKey('commitmentSettings')) {
      commitmentSettings =
          GoogleCloudChannelV1alpha1CommitmentSettings.fromJson(
              _json['commitmentSettings']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('maxUnits')) {
      maxUnits = _json['maxUnits'] as core.int;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('numUnits')) {
      numUnits = _json['numUnits'] as core.int;
    }
    if (_json.containsKey('offer')) {
      offer = _json['offer'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<GoogleCloudChannelV1alpha1Parameter>((value) =>
              GoogleCloudChannelV1alpha1Parameter.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('provisionedService')) {
      provisionedService =
          GoogleCloudChannelV1alpha1ProvisionedService.fromJson(
              _json['provisionedService']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('provisioningState')) {
      provisioningState = _json['provisioningState'] as core.String;
    }
    if (_json.containsKey('purchaseOrderId')) {
      purchaseOrderId = _json['purchaseOrderId'] as core.String;
    }
    if (_json.containsKey('suspensionReasons')) {
      suspensionReasons = (_json['suspensionReasons'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('trialSettings')) {
      trialSettings = GoogleCloudChannelV1alpha1TrialSettings.fromJson(
          _json['trialSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignedUnits != null) 'assignedUnits': assignedUnits!,
        if (associationInfo != null)
          'associationInfo': associationInfo!.toJson(),
        if (channelPartnerId != null) 'channelPartnerId': channelPartnerId!,
        if (commitmentSettings != null)
          'commitmentSettings': commitmentSettings!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (maxUnits != null) 'maxUnits': maxUnits!,
        if (name != null) 'name': name!,
        if (numUnits != null) 'numUnits': numUnits!,
        if (offer != null) 'offer': offer!,
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
        if (provisionedService != null)
          'provisionedService': provisionedService!.toJson(),
        if (provisioningState != null) 'provisioningState': provisioningState!,
        if (purchaseOrderId != null) 'purchaseOrderId': purchaseOrderId!,
        if (suspensionReasons != null) 'suspensionReasons': suspensionReasons!,
        if (trialSettings != null) 'trialSettings': trialSettings!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Represents Pub/Sub message content describing entitlement update.
class GoogleCloudChannelV1alpha1EntitlementEvent {
  /// Resource name of an entitlement of the form:
  /// accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}
  core.String? entitlement;

  /// Type of event which happened on the entitlement.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Default value. This state doesn't show unless an
  /// error occurs.
  /// - "CREATED" : A new entitlement was created.
  /// - "PRICE_PLAN_SWITCHED" : The offer type associated with an entitlement
  /// was changed. This is not triggered if an entitlement converts from a
  /// commit offer to a flexible offer as part of a renewal.
  /// - "COMMITMENT_CHANGED" : Annual commitment for a commit plan was changed.
  /// - "RENEWED" : An annual entitlement was renewed.
  /// - "SUSPENDED" : Entitlement was suspended.
  /// - "ACTIVATED" : Entitlement was unsuspended.
  /// - "CANCELLED" : Entitlement was cancelled.
  /// - "SKU_CHANGED" : Entitlement was upgraded or downgraded (e.g. from Google
  /// Workspace Business Standard to Google Workspace Business Plus).
  /// - "RENEWAL_SETTING_CHANGED" : The renewal settings of an entitlement has
  /// changed.
  /// - "PAID_SERVICE_STARTED" : Paid service has started on trial entitlement.
  /// - "LICENSE_ASSIGNMENT_CHANGED" : License was assigned to or revoked from a
  /// user.
  /// - "LICENSE_CAP_CHANGED" : License cap was changed for the entitlement.
  core.String? eventType;

  GoogleCloudChannelV1alpha1EntitlementEvent();

  GoogleCloudChannelV1alpha1EntitlementEvent.fromJson(core.Map _json) {
    if (_json.containsKey('entitlement')) {
      entitlement = _json['entitlement'] as core.String;
    }
    if (_json.containsKey('eventType')) {
      eventType = _json['eventType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entitlement != null) 'entitlement': entitlement!,
        if (eventType != null) 'eventType': eventType!,
      };
}

/// Provides contextual information about a google.longrunning.Operation.
class GoogleCloudChannelV1alpha1OperationMetadata {
  /// The RPC that initiated this Long Running Operation.
  /// Possible string values are:
  /// - "OPERATION_TYPE_UNSPECIFIED" : Default value. This state doesn't show
  /// unless an error occurs.
  /// - "CREATE_ENTITLEMENT" : Long Running Operation was triggered by
  /// CreateEntitlement.
  /// - "CHANGE_QUANTITY" : Long Running Operation was triggered by
  /// ChangeQuantity.
  /// - "CHANGE_RENEWAL_SETTINGS" : Long Running Operation was triggered by
  /// ChangeRenewalSettings.
  /// - "CHANGE_PLAN" : Long Running Operation was triggered by ChangePlan.
  /// - "START_PAID_SERVICE" : Long Running Operation was triggered by
  /// StartPaidService.
  /// - "CHANGE_SKU" : Long Running Operation was triggered by ChangeSku.
  /// - "ACTIVATE_ENTITLEMENT" : Long Running Operation was triggered by
  /// ActivateEntitlement.
  /// - "SUSPEND_ENTITLEMENT" : Long Running Operation was triggered by
  /// SuspendEntitlement.
  /// - "CANCEL_ENTITLEMENT" : Long Running Operation was triggered by
  /// CancelEntitlement.
  /// - "TRANSFER_ENTITLEMENTS" : Long Running Operation was triggered by
  /// TransferEntitlements.
  /// - "TRANSFER_ENTITLEMENTS_TO_GOOGLE" : Long Running Operation was triggered
  /// by TransferEntitlementsToGoogle.
  /// - "CHANGE_OFFER" : Long Running Operation was triggered by ChangeOffer.
  /// - "CHANGE_PARAMETERS" : Long Running Operation was triggered by
  /// ChangeParameters.
  /// - "PROVISION_CLOUD_IDENTITY" : Long Running Operation was triggered by
  /// ProvisionCloudIdentity.
  core.String? operationType;

  GoogleCloudChannelV1alpha1OperationMetadata();

  GoogleCloudChannelV1alpha1OperationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('operationType')) {
      operationType = _json['operationType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operationType != null) 'operationType': operationType!,
      };
}

/// Definition for extended entitlement parameters.
class GoogleCloudChannelV1alpha1Parameter {
  /// Specifies whether this parameter is allowed to be changed.
  ///
  /// For example, for a Google Workspace Business Starter entitlement in
  /// commitment plan, num_units is editable when entitlement is active.
  ///
  /// Output only.
  core.bool? editable;

  /// Name of the parameter.
  core.String? name;

  /// Value of the parameter.
  GoogleCloudChannelV1alpha1Value? value;

  GoogleCloudChannelV1alpha1Parameter();

  GoogleCloudChannelV1alpha1Parameter.fromJson(core.Map _json) {
    if (_json.containsKey('editable')) {
      editable = _json['editable'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = GoogleCloudChannelV1alpha1Value.fromJson(
          _json['value'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (editable != null) 'editable': editable!,
        if (name != null) 'name': name!,
        if (value != null) 'value': value!.toJson(),
      };
}

/// Represents period in days/months/years.
class GoogleCloudChannelV1alpha1Period {
  /// Total duration of Period Type defined.
  core.int? duration;

  /// Period Type.
  /// Possible string values are:
  /// - "PERIOD_TYPE_UNSPECIFIED" : Not used.
  /// - "DAY" : Day.
  /// - "MONTH" : Month.
  /// - "YEAR" : Year.
  core.String? periodType;

  GoogleCloudChannelV1alpha1Period();

  GoogleCloudChannelV1alpha1Period.fromJson(core.Map _json) {
    if (_json.containsKey('duration')) {
      duration = _json['duration'] as core.int;
    }
    if (_json.containsKey('periodType')) {
      periodType = _json['periodType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (duration != null) 'duration': duration!,
        if (periodType != null) 'periodType': periodType!,
      };
}

/// Service provisioned for an entitlement.
class GoogleCloudChannelV1alpha1ProvisionedService {
  /// The product pertaining to the provisioning resource as specified in the
  /// Offer.
  ///
  /// Output only.
  core.String? productId;

  /// Provisioning ID of the entitlement.
  ///
  /// For Google Workspace, this would be the underlying Subscription ID.
  ///
  /// Output only.
  core.String? provisioningId;

  /// The SKU pertaining to the provisioning resource as specified in the Offer.
  ///
  /// Output only.
  core.String? skuId;

  GoogleCloudChannelV1alpha1ProvisionedService();

  GoogleCloudChannelV1alpha1ProvisionedService.fromJson(core.Map _json) {
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('provisioningId')) {
      provisioningId = _json['provisioningId'] as core.String;
    }
    if (_json.containsKey('skuId')) {
      skuId = _json['skuId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (productId != null) 'productId': productId!,
        if (provisioningId != null) 'provisioningId': provisioningId!,
        if (skuId != null) 'skuId': skuId!,
      };
}

/// Renewal settings for renewable Offers.
class GoogleCloudChannelV1alpha1RenewalSettings {
  /// If true, disables commitment-based offer on renewal and switches to
  /// flexible or pay as you go.
  ///
  /// Deprecated: Use `payment_plan` instead.
  core.bool? disableCommitment;

  /// If false, the plan will be completed at the end date.
  core.bool? enableRenewal;

  /// Describes how frequently the reseller will be billed, such as once per
  /// month.
  GoogleCloudChannelV1alpha1Period? paymentCycle;

  /// Set if enable_renewal=true.
  ///
  /// Deprecated: Use `payment_cycle` instead.
  /// Possible string values are:
  /// - "PAYMENT_OPTION_UNSPECIFIED" : Default value. This state doesn't show
  /// unless an error occurs.
  /// - "ANNUAL" : Paid in yearly installments.
  /// - "MONTHLY" : Paid in monthly installments.
  core.String? paymentOption;

  /// Describes how a reseller will be billed.
  /// Possible string values are:
  /// - "PAYMENT_PLAN_UNSPECIFIED" : Not used.
  /// - "COMMITMENT" : Commitment.
  /// - "FLEXIBLE" : No commitment.
  /// - "FREE" : Free.
  /// - "TRIAL" : Trial.
  /// - "OFFLINE" : Price and ordering not available through API.
  core.String? paymentPlan;

  /// If true and enable_renewal = true, the unit (for example seats or
  /// licenses) will be set to the number of active units at renewal time.
  core.bool? resizeUnitCount;

  GoogleCloudChannelV1alpha1RenewalSettings();

  GoogleCloudChannelV1alpha1RenewalSettings.fromJson(core.Map _json) {
    if (_json.containsKey('disableCommitment')) {
      disableCommitment = _json['disableCommitment'] as core.bool;
    }
    if (_json.containsKey('enableRenewal')) {
      enableRenewal = _json['enableRenewal'] as core.bool;
    }
    if (_json.containsKey('paymentCycle')) {
      paymentCycle = GoogleCloudChannelV1alpha1Period.fromJson(
          _json['paymentCycle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('paymentOption')) {
      paymentOption = _json['paymentOption'] as core.String;
    }
    if (_json.containsKey('paymentPlan')) {
      paymentPlan = _json['paymentPlan'] as core.String;
    }
    if (_json.containsKey('resizeUnitCount')) {
      resizeUnitCount = _json['resizeUnitCount'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disableCommitment != null) 'disableCommitment': disableCommitment!,
        if (enableRenewal != null) 'enableRenewal': enableRenewal!,
        if (paymentCycle != null) 'paymentCycle': paymentCycle!.toJson(),
        if (paymentOption != null) 'paymentOption': paymentOption!,
        if (paymentPlan != null) 'paymentPlan': paymentPlan!,
        if (resizeUnitCount != null) 'resizeUnitCount': resizeUnitCount!,
      };
}

/// Represents information which resellers will get as part of notification from
/// Cloud Pub/Sub.
class GoogleCloudChannelV1alpha1SubscriberEvent {
  /// Customer event send as part of Pub/Sub event to partners.
  GoogleCloudChannelV1alpha1CustomerEvent? customerEvent;

  /// Entitlement event send as part of Pub/Sub event to partners.
  GoogleCloudChannelV1alpha1EntitlementEvent? entitlementEvent;

  GoogleCloudChannelV1alpha1SubscriberEvent();

  GoogleCloudChannelV1alpha1SubscriberEvent.fromJson(core.Map _json) {
    if (_json.containsKey('customerEvent')) {
      customerEvent = GoogleCloudChannelV1alpha1CustomerEvent.fromJson(
          _json['customerEvent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('entitlementEvent')) {
      entitlementEvent = GoogleCloudChannelV1alpha1EntitlementEvent.fromJson(
          _json['entitlementEvent'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customerEvent != null) 'customerEvent': customerEvent!.toJson(),
        if (entitlementEvent != null)
          'entitlementEvent': entitlementEvent!.toJson(),
      };
}

/// Response message for CloudChannelService.TransferEntitlements.
///
/// This is put in the response field of google.longrunning.Operation.
class GoogleCloudChannelV1alpha1TransferEntitlementsResponse {
  /// The transferred entitlements.
  core.List<GoogleCloudChannelV1alpha1Entitlement>? entitlements;

  GoogleCloudChannelV1alpha1TransferEntitlementsResponse();

  GoogleCloudChannelV1alpha1TransferEntitlementsResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('entitlements')) {
      entitlements = (_json['entitlements'] as core.List)
          .map<GoogleCloudChannelV1alpha1Entitlement>((value) =>
              GoogleCloudChannelV1alpha1Entitlement.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entitlements != null)
          'entitlements': entitlements!.map((value) => value.toJson()).toList(),
      };
}

/// Settings for trial offers.
class GoogleCloudChannelV1alpha1TrialSettings {
  /// Date when the trial ends.
  ///
  /// The value is in milliseconds using the UNIX Epoch format. See an example
  /// [Epoch converter](https://www.epochconverter.com).
  core.String? endTime;

  /// Determines if the entitlement is in a trial or not: * `true` - The
  /// entitlement is in trial.
  ///
  /// * `false` - The entitlement is not in trial.
  core.bool? trial;

  GoogleCloudChannelV1alpha1TrialSettings();

  GoogleCloudChannelV1alpha1TrialSettings.fromJson(core.Map _json) {
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('trial')) {
      trial = _json['trial'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTime != null) 'endTime': endTime!,
        if (trial != null) 'trial': trial!,
      };
}

/// Data type and value of a parameter.
class GoogleCloudChannelV1alpha1Value {
  /// Represents a boolean value.
  core.bool? boolValue;

  /// Represents a double value.
  core.double? doubleValue;

  /// Represents an int64 value.
  core.String? int64Value;

  /// Represents an 'Any' proto value.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? protoValue;

  /// Represents a string value.
  core.String? stringValue;

  GoogleCloudChannelV1alpha1Value();

  GoogleCloudChannelV1alpha1Value.fromJson(core.Map _json) {
    if (_json.containsKey('boolValue')) {
      boolValue = _json['boolValue'] as core.bool;
    }
    if (_json.containsKey('doubleValue')) {
      doubleValue = (_json['doubleValue'] as core.num).toDouble();
    }
    if (_json.containsKey('int64Value')) {
      int64Value = _json['int64Value'] as core.String;
    }
    if (_json.containsKey('protoValue')) {
      protoValue =
          (_json['protoValue'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('stringValue')) {
      stringValue = _json['stringValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (boolValue != null) 'boolValue': boolValue!,
        if (doubleValue != null) 'doubleValue': doubleValue!,
        if (int64Value != null) 'int64Value': int64Value!,
        if (protoValue != null) 'protoValue': protoValue!,
        if (stringValue != null) 'stringValue': stringValue!,
      };
}

/// The request message for Operations.CancelOperation.
class GoogleLongrunningCancelOperationRequest {
  GoogleLongrunningCancelOperationRequest();

  GoogleLongrunningCancelOperationRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The response message for Operations.ListOperations.
class GoogleLongrunningListOperationsResponse {
  /// The standard List next-page token.
  core.String? nextPageToken;

  /// A list of operations that matches the specified filter in the request.
  core.List<GoogleLongrunningOperation>? operations;

  GoogleLongrunningListOperationsResponse();

  GoogleLongrunningListOperationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<GoogleLongrunningOperation>((value) =>
              GoogleLongrunningOperation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
      };
}

/// This resource represents a long-running operation that is the result of a
/// network API call.
class GoogleLongrunningOperation {
  /// If the value is `false`, it means the operation is still in progress.
  ///
  /// If `true`, the operation is completed, and either `error` or `response` is
  /// available.
  core.bool? done;

  /// The error result of the operation in case of failure or cancellation.
  GoogleRpcStatus? error;

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

  GoogleLongrunningOperation();

  GoogleLongrunningOperation.fromJson(core.Map _json) {
    if (_json.containsKey('done')) {
      done = _json['done'] as core.bool;
    }
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
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

/// A generic empty message that you can re-use to avoid defining duplicated
/// empty messages in your APIs.
///
/// A typical example is to use it as the request or the response type of an API
/// method. For instance: service Foo { rpc Bar(google.protobuf.Empty) returns
/// (google.protobuf.Empty); } The JSON representation for `Empty` is empty JSON
/// object `{}`.
class GoogleProtobufEmpty {
  GoogleProtobufEmpty();

  GoogleProtobufEmpty.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs.
///
/// It is used by [gRPC](https://github.com/grpc). Each `Status` message
/// contains three pieces of data: error code, error message, and error details.
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
class GoogleRpcStatus {
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

  GoogleRpcStatus();

  GoogleRpcStatus.fromJson(core.Map _json) {
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

/// Represents an amount of money with its currency type.
class GoogleTypeMoney {
  /// The three-letter currency code defined in ISO 4217.
  core.String? currencyCode;

  /// Number of nano (10^-9) units of the amount.
  ///
  /// The value must be between -999,999,999 and +999,999,999 inclusive. If
  /// `units` is positive, `nanos` must be positive or zero. If `units` is zero,
  /// `nanos` can be positive, zero, or negative. If `units` is negative,
  /// `nanos` must be negative or zero. For example $-1.75 is represented as
  /// `units`=-1 and `nanos`=-750,000,000.
  core.int? nanos;

  /// The whole units of the amount.
  ///
  /// For example if `currencyCode` is `"USD"`, then 1 unit is one US dollar.
  core.String? units;

  GoogleTypeMoney();

  GoogleTypeMoney.fromJson(core.Map _json) {
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('nanos')) {
      nanos = _json['nanos'] as core.int;
    }
    if (_json.containsKey('units')) {
      units = _json['units'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (nanos != null) 'nanos': nanos!,
        if (units != null) 'units': units!,
      };
}

/// Represents a postal address, e.g. for postal delivery or payments addresses.
///
/// Given a postal address, a postal service can deliver items to a premise,
/// P.O. Box or similar. It is not intended to model geographical locations
/// (roads, towns, mountains). In typical usage an address would be created via
/// user input or from importing existing data, depending on the type of
/// process. Advice on address input / editing: - Use an i18n-ready address
/// widget such as https://github.com/google/libaddressinput) - Users should not
/// be presented with UI elements for input or editing of fields outside
/// countries where that field is used. For more guidance on how to use this
/// schema, please see: https://support.google.com/business/answer/6397478
class GoogleTypePostalAddress {
  /// Unstructured address lines describing the lower levels of an address.
  ///
  /// Because values in address_lines do not have type information and may
  /// sometimes contain multiple values in a single field (e.g. "Austin, TX"),
  /// it is important that the line order is clear. The order of address lines
  /// should be "envelope order" for the country/region of the address. In
  /// places where this can vary (e.g. Japan), address_language is used to make
  /// it explicit (e.g. "ja" for large-to-small ordering and "ja-Latn" or "en"
  /// for small-to-large). This way, the most specific line of an address can be
  /// selected based on the language. The minimum permitted structural
  /// representation of an address consists of a region_code with all remaining
  /// information placed in the address_lines. It would be possible to format
  /// such an address very approximately without geocoding, but no semantic
  /// reasoning could be made about any of the address components until it was
  /// at least partially resolved. Creating an address only containing a
  /// region_code and address_lines, and then geocoding is the recommended way
  /// to handle completely unstructured addresses (as opposed to guessing which
  /// parts of the address should be localities or administrative areas).
  core.List<core.String>? addressLines;

  /// Highest administrative subdivision which is used for postal addresses of a
  /// country or region.
  ///
  /// For example, this can be a state, a province, an oblast, or a prefecture.
  /// Specifically, for Spain this is the province and not the autonomous
  /// community (e.g. "Barcelona" and not "Catalonia"). Many countries don't use
  /// an administrative area in postal addresses. E.g. in Switzerland this
  /// should be left unpopulated.
  ///
  /// Optional.
  core.String? administrativeArea;

  /// BCP-47 language code of the contents of this address (if known).
  ///
  /// This is often the UI language of the input form or is expected to match
  /// one of the languages used in the address' country/region, or their
  /// transliterated equivalents. This can affect formatting in certain
  /// countries, but is not critical to the correctness of the data and will
  /// never affect any validation or other non-formatting related operations. If
  /// this value is not known, it should be omitted (rather than specifying a
  /// possibly incorrect default). Examples: "zh-Hant", "ja", "ja-Latn", "en".
  ///
  /// Optional.
  core.String? languageCode;

  /// Generally refers to the city/town portion of the address.
  ///
  /// Examples: US city, IT comune, UK post town. In regions of the world where
  /// localities are not well defined or do not fit into this structure well,
  /// leave locality empty and use address_lines.
  ///
  /// Optional.
  core.String? locality;

  /// The name of the organization at the address.
  ///
  /// Optional.
  core.String? organization;

  /// Postal code of the address.
  ///
  /// Not all countries use or require postal codes to be present, but where
  /// they are used, they may trigger additional validation with other parts of
  /// the address (e.g. state/zip validation in the U.S.A.).
  ///
  /// Optional.
  core.String? postalCode;

  /// The recipient at the address.
  ///
  /// This field may, under certain circumstances, contain multiline
  /// information. For example, it might contain "care of" information.
  ///
  /// Optional.
  core.List<core.String>? recipients;

  /// CLDR region code of the country/region of the address.
  ///
  /// This is never inferred and it is up to the user to ensure the value is
  /// correct. See http://cldr.unicode.org/ and
  /// http://www.unicode.org/cldr/charts/30/supplemental/territory_information.html
  /// for details. Example: "CH" for Switzerland.
  ///
  /// Required.
  core.String? regionCode;

  /// The schema revision of the `PostalAddress`.
  ///
  /// This must be set to 0, which is the latest revision. All new revisions
  /// **must** be backward compatible with old revisions.
  core.int? revision;

  /// Additional, country-specific, sorting code.
  ///
  /// This is not used in most regions. Where it is used, the value is either a
  /// string like "CEDEX", optionally followed by a number (e.g. "CEDEX 7"), or
  /// just a number alone, representing the "sector code" (Jamaica), "delivery
  /// area indicator" (Malawi) or "post office indicator" (e.g. Côte d'Ivoire).
  ///
  /// Optional.
  core.String? sortingCode;

  /// Sublocality of the address.
  ///
  /// For example, this can be neighborhoods, boroughs, districts.
  ///
  /// Optional.
  core.String? sublocality;

  GoogleTypePostalAddress();

  GoogleTypePostalAddress.fromJson(core.Map _json) {
    if (_json.containsKey('addressLines')) {
      addressLines = (_json['addressLines'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('administrativeArea')) {
      administrativeArea = _json['administrativeArea'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('locality')) {
      locality = _json['locality'] as core.String;
    }
    if (_json.containsKey('organization')) {
      organization = _json['organization'] as core.String;
    }
    if (_json.containsKey('postalCode')) {
      postalCode = _json['postalCode'] as core.String;
    }
    if (_json.containsKey('recipients')) {
      recipients = (_json['recipients'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('regionCode')) {
      regionCode = _json['regionCode'] as core.String;
    }
    if (_json.containsKey('revision')) {
      revision = _json['revision'] as core.int;
    }
    if (_json.containsKey('sortingCode')) {
      sortingCode = _json['sortingCode'] as core.String;
    }
    if (_json.containsKey('sublocality')) {
      sublocality = _json['sublocality'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (addressLines != null) 'addressLines': addressLines!,
        if (administrativeArea != null)
          'administrativeArea': administrativeArea!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (locality != null) 'locality': locality!,
        if (organization != null) 'organization': organization!,
        if (postalCode != null) 'postalCode': postalCode!,
        if (recipients != null) 'recipients': recipients!,
        if (regionCode != null) 'regionCode': regionCode!,
        if (revision != null) 'revision': revision!,
        if (sortingCode != null) 'sortingCode': sortingCode!,
        if (sublocality != null) 'sublocality': sublocality!,
      };
}

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

/// Google Workspace Reseller API - v1
///
/// Perform common functions that are available on the Channel Services console
/// at scale, like placing orders and viewing customer information
///
/// For more information, see
/// <https://developers.google.com/google-apps/reseller/>
///
/// Create an instance of [ResellerApi] to access these resources:
///
/// - [CustomersResource]
/// - [ResellernotifyResource_1]
/// - [SubscriptionsResource]
library reseller.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Perform common functions that are available on the Channel Services console
/// at scale, like placing orders and viewing customer information
class ResellerApi {
  /// Manage users on your domain
  static const appsOrderScope = 'https://www.googleapis.com/auth/apps.order';

  /// Manage users on your domain
  static const appsOrderReadonlyScope =
      'https://www.googleapis.com/auth/apps.order.readonly';

  final commons.ApiRequester _requester;

  CustomersResource get customers => CustomersResource(_requester);
  ResellernotifyResource_1 get resellernotify =>
      ResellernotifyResource_1(_requester);
  SubscriptionsResource get subscriptions => SubscriptionsResource(_requester);

  ResellerApi(http.Client client,
      {core.String rootUrl = 'https://reseller.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class CustomersResource {
  final commons.ApiRequester _requester;

  CustomersResource(commons.ApiRequester client) : _requester = client;

  /// Get a customer account.
  ///
  /// Use this operation to see a customer account already in your reseller
  /// management, or to see the minimal account information for an existing
  /// customer that you do not manage. For more information about the API
  /// response for existing customers, see \[retrieving a customer
  /// account\](/admin-sdk/reseller/v1/how-tos/manage_customers#get_customer).
  ///
  /// Request parameters:
  ///
  /// [customerId] - Either the customer's primary domain name or the customer's
  /// unique identifier. If using the domain name, we do not recommend using a
  /// `customerId` as a key for persistent data. If the domain name for a
  /// `customerId` is changed, the Google system automatically updates.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Customer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Customer> get(
    core.String customerId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'apps/reseller/v1/customers/' + commons.escapeVariable('$customerId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Customer.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Order a new customer's account.
  ///
  /// Before ordering a new customer account, establish whether the customer
  /// account already exists using the
  /// \[`customers.get`\](/admin-sdk/reseller/v1/reference/customers/get) If the
  /// customer account exists as a direct Google account or as a resold customer
  /// account from another reseller, use the `customerAuthToken\` as described
  /// in \[order a resold account for an existing
  /// customer\](/admin-sdk/reseller/v1/how-tos/manage_customers#create_existing_customer).
  /// For more information about ordering a new customer account, see \[order a
  /// new customer
  /// account\](/admin-sdk/reseller/v1/how-tos/manage_customers#create_customer).
  /// After creating a new customer account, you must provision a user as an
  /// administrator. The customer's administrator is required to sign in to the
  /// Admin console and sign the G Suite via Reseller agreement to activate the
  /// account. Resellers are prohibited from signing the G Suite via Reseller
  /// agreement on the customer's behalf. For more information, see \[order a
  /// new customer
  /// account\](/admin-sdk/reseller/v1/how-tos/manage_customers#tos).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerAuthToken] - The `customerAuthToken` query string is required
  /// when creating a resold account that transfers a direct customer's
  /// subscription or transfers another reseller customer's subscription to your
  /// reseller management. This is a hexadecimal authentication token needed to
  /// complete the subscription transfer. For more information, see the
  /// administrator help center.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Customer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Customer> insert(
    Customer request, {
    core.String? customerAuthToken,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (customerAuthToken != null) 'customerAuthToken': [customerAuthToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'apps/reseller/v1/customers';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Customer.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Update a customer account's settings.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Either the customer's primary domain name or the customer's
  /// unique identifier. If using the domain name, we do not recommend using a
  /// `customerId` as a key for persistent data. If the domain name for a
  /// `customerId` is changed, the Google system automatically updates.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Customer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Customer> patch(
    Customer request,
    core.String customerId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'apps/reseller/v1/customers/' + commons.escapeVariable('$customerId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Customer.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Update a customer account's settings.
  ///
  /// For more information, see \[update a customer's
  /// settings\](/admin-sdk/reseller/v1/how-tos/manage_customers#update_customer).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Either the customer's primary domain name or the customer's
  /// unique identifier. If using the domain name, we do not recommend using a
  /// `customerId` as a key for persistent data. If the domain name for a
  /// `customerId` is changed, the Google system automatically updates.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Customer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Customer> update(
    Customer request,
    core.String customerId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'apps/reseller/v1/customers/' + commons.escapeVariable('$customerId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Customer.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ResellernotifyResource_1 {
  final commons.ApiRequester _requester;

  ResellernotifyResource_1(commons.ApiRequester client) : _requester = client;

  /// Returns all the details of the watch corresponding to the reseller.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ResellernotifyGetwatchdetailsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ResellernotifyGetwatchdetailsResponse> getwatchdetails({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'apps/reseller/v1/resellernotify/getwatchdetails';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ResellernotifyGetwatchdetailsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Registers a Reseller for receiving notifications.
  ///
  /// Request parameters:
  ///
  /// [serviceAccountEmailAddress] - The service account which will own the
  /// created Cloud-PubSub topic.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ResellernotifyResource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ResellernotifyResource> register({
    core.String? serviceAccountEmailAddress,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (serviceAccountEmailAddress != null)
        'serviceAccountEmailAddress': [serviceAccountEmailAddress],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'apps/reseller/v1/resellernotify/register';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return ResellernotifyResource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Unregisters a Reseller for receiving notifications.
  ///
  /// Request parameters:
  ///
  /// [serviceAccountEmailAddress] - The service account which owns the
  /// Cloud-PubSub topic.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ResellernotifyResource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ResellernotifyResource> unregister({
    core.String? serviceAccountEmailAddress,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (serviceAccountEmailAddress != null)
        'serviceAccountEmailAddress': [serviceAccountEmailAddress],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'apps/reseller/v1/resellernotify/unregister';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return ResellernotifyResource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class SubscriptionsResource {
  final commons.ApiRequester _requester;

  SubscriptionsResource(commons.ApiRequester client) : _requester = client;

  /// Activates a subscription previously suspended by the reseller.
  ///
  /// If you did not suspend the customer subscription and it is suspended for
  /// any other reason, such as for abuse or a pending ToS acceptance, this call
  /// will not reactivate the customer subscription.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Either the customer's primary domain name or the customer's
  /// unique identifier. If using the domain name, we do not recommend using a
  /// `customerId` as a key for persistent data. If the domain name for a
  /// `customerId` is changed, the Google system automatically updates.
  ///
  /// [subscriptionId] - This is a required property. The `subscriptionId` is
  /// the subscription identifier and is unique for each customer. Since a
  /// `subscriptionId` changes when a subscription is updated, we recommend to
  /// not use this ID as a key for persistent data. And the `subscriptionId` can
  /// be found using the retrieve all reseller subscriptions method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subscription].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subscription> activate(
    core.String customerId,
    core.String subscriptionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apps/reseller/v1/customers/' +
        commons.escapeVariable('$customerId') +
        '/subscriptions/' +
        commons.escapeVariable('$subscriptionId') +
        '/activate';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Subscription.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update a subscription plan.
  ///
  /// Use this method to update a plan for a 30-day trial or a flexible plan
  /// subscription to an annual commitment plan with monthly or yearly payments.
  /// How a plan is updated differs depending on the plan and the products. For
  /// more information, see the description in \[manage
  /// subscriptions\](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#update_subscription_plan).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Either the customer's primary domain name or the customer's
  /// unique identifier. If using the domain name, we do not recommend using a
  /// `customerId` as a key for persistent data. If the domain name for a
  /// `customerId` is changed, the Google system automatically updates.
  ///
  /// [subscriptionId] - This is a required property. The `subscriptionId` is
  /// the subscription identifier and is unique for each customer. Since a
  /// `subscriptionId` changes when a subscription is updated, we recommend to
  /// not use this ID as a key for persistent data. And the `subscriptionId` can
  /// be found using the retrieve all reseller subscriptions method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subscription].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subscription> changePlan(
    ChangePlanRequest request,
    core.String customerId,
    core.String subscriptionId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apps/reseller/v1/customers/' +
        commons.escapeVariable('$customerId') +
        '/subscriptions/' +
        commons.escapeVariable('$subscriptionId') +
        '/changePlan';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Subscription.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update a user license's renewal settings.
  ///
  /// This is applicable for accounts with annual commitment plans only. For
  /// more information, see the description in \[manage
  /// subscriptions\](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#update_renewal).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Either the customer's primary domain name or the customer's
  /// unique identifier. If using the domain name, we do not recommend using a
  /// `customerId` as a key for persistent data. If the domain name for a
  /// `customerId` is changed, the Google system automatically updates.
  ///
  /// [subscriptionId] - This is a required property. The `subscriptionId` is
  /// the subscription identifier and is unique for each customer. Since a
  /// `subscriptionId` changes when a subscription is updated, we recommend to
  /// not use this ID as a key for persistent data. And the `subscriptionId` can
  /// be found using the retrieve all reseller subscriptions method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subscription].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subscription> changeRenewalSettings(
    RenewalSettings request,
    core.String customerId,
    core.String subscriptionId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apps/reseller/v1/customers/' +
        commons.escapeVariable('$customerId') +
        '/subscriptions/' +
        commons.escapeVariable('$subscriptionId') +
        '/changeRenewalSettings';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Subscription.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update a subscription's user license settings.
  ///
  /// For more information about updating an annual commitment plan or a
  /// flexible plan subscription’s licenses, see \[Manage
  /// Subscriptions\](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#update_subscription_seat).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Either the customer's primary domain name or the customer's
  /// unique identifier. If using the domain name, we do not recommend using a
  /// `customerId` as a key for persistent data. If the domain name for a
  /// `customerId` is changed, the Google system automatically updates.
  ///
  /// [subscriptionId] - This is a required property. The `subscriptionId` is
  /// the subscription identifier and is unique for each customer. Since a
  /// `subscriptionId` changes when a subscription is updated, we recommend to
  /// not use this ID as a key for persistent data. And the `subscriptionId` can
  /// be found using the retrieve all reseller subscriptions method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subscription].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subscription> changeSeats(
    Seats request,
    core.String customerId,
    core.String subscriptionId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apps/reseller/v1/customers/' +
        commons.escapeVariable('$customerId') +
        '/subscriptions/' +
        commons.escapeVariable('$subscriptionId') +
        '/changeSeats';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Subscription.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Cancel, suspend, or transfer a subscription to direct.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Either the customer's primary domain name or the customer's
  /// unique identifier. If using the domain name, we do not recommend using a
  /// `customerId` as a key for persistent data. If the domain name for a
  /// `customerId` is changed, the Google system automatically updates.
  ///
  /// [subscriptionId] - This is a required property. The `subscriptionId` is
  /// the subscription identifier and is unique for each customer. Since a
  /// `subscriptionId` changes when a subscription is updated, we recommend to
  /// not use this ID as a key for persistent data. And the `subscriptionId` can
  /// be found using the retrieve all reseller subscriptions method.
  ///
  /// [deletionType] - The `deletionType` query string enables the cancellation,
  /// downgrade, or suspension of a subscription.
  /// Possible string values are:
  /// - "deletion_type_undefined"
  /// - "cancel" : Cancels the subscription immediately. This does not apply to
  /// a G Suite subscription.
  /// - "transfer_to_direct" : Transfers a subscription directly to Google. The
  /// customer is immediately transferred to a direct billing relationship with
  /// Google and is given a short amount of time with no service interruption.
  /// The customer can then choose to set up billing directly with Google by
  /// using a credit card, or they can transfer to another reseller.
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
    core.String customerId,
    core.String subscriptionId,
    core.String deletionType, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'deletionType': [deletionType],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apps/reseller/v1/customers/' +
        commons.escapeVariable('$customerId') +
        '/subscriptions/' +
        commons.escapeVariable('$subscriptionId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Get a specific subscription.
  ///
  /// The `subscriptionId` can be found using the \[Retrieve all reseller
  /// subscriptions\](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#get_all_subscriptions)
  /// method. For more information about retrieving a specific subscription, see
  /// the information descrived in \[manage
  /// subscriptions\](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#get_subscription).
  ///
  /// Request parameters:
  ///
  /// [customerId] - Either the customer's primary domain name or the customer's
  /// unique identifier. If using the domain name, we do not recommend using a
  /// `customerId` as a key for persistent data. If the domain name for a
  /// `customerId` is changed, the Google system automatically updates.
  ///
  /// [subscriptionId] - This is a required property. The `subscriptionId` is
  /// the subscription identifier and is unique for each customer. Since a
  /// `subscriptionId` changes when a subscription is updated, we recommend to
  /// not use this ID as a key for persistent data. And the `subscriptionId` can
  /// be found using the retrieve all reseller subscriptions method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subscription].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subscription> get(
    core.String customerId,
    core.String subscriptionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apps/reseller/v1/customers/' +
        commons.escapeVariable('$customerId') +
        '/subscriptions/' +
        commons.escapeVariable('$subscriptionId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Subscription.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Create or transfer a subscription.
  ///
  /// Create a subscription for a customer's account that you ordered using the
  /// \[Order a new customer
  /// account\](/admin-sdk/reseller/v1/reference/customers/insert.html) method.
  /// For more information about creating a subscription for different payment
  /// plans, see \[manage
  /// subscriptions\](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#create_subscription).\
  /// If you did not order the customer's account using the customer insert
  /// method, use the customer's `customerAuthToken` when creating a
  /// subscription for that customer. If transferring a G Suite subscription
  /// with an associated Google Drive or Google Vault subscription, use the
  /// \[batch operation\](/admin-sdk/reseller/v1/how-tos/batch.html) to transfer
  /// all of these subscriptions. For more information, see how to \[transfer
  /// subscriptions\](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#transfer_a_subscription).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Either the customer's primary domain name or the customer's
  /// unique identifier. If using the domain name, we do not recommend using a
  /// `customerId` as a key for persistent data. If the domain name for a
  /// `customerId` is changed, the Google system automatically updates.
  ///
  /// [customerAuthToken] - The `customerAuthToken` query string is required
  /// when creating a resold account that transfers a direct customer's
  /// subscription or transfers another reseller customer's subscription to your
  /// reseller management. This is a hexadecimal authentication token needed to
  /// complete the subscription transfer. For more information, see the
  /// administrator help center.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subscription].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subscription> insert(
    Subscription request,
    core.String customerId, {
    core.String? customerAuthToken,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (customerAuthToken != null) 'customerAuthToken': [customerAuthToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apps/reseller/v1/customers/' +
        commons.escapeVariable('$customerId') +
        '/subscriptions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Subscription.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List of subscriptions managed by the reseller.
  ///
  /// The list can be all subscriptions, all of a customer's subscriptions, or
  /// all of a customer's transferable subscriptions. Optionally, this method
  /// can filter the response by a `customerNamePrefix`. For more information,
  /// see \[manage
  /// subscriptions\](/admin-sdk/reseller/v1/how-tos/manage_subscriptions).
  ///
  /// Request parameters:
  ///
  /// [customerAuthToken] - The `customerAuthToken` query string is required
  /// when creating a resold account that transfers a direct customer's
  /// subscription or transfers another reseller customer's subscription to your
  /// reseller management. This is a hexadecimal authentication token needed to
  /// complete the subscription transfer. For more information, see the
  /// administrator help center.
  ///
  /// [customerId] - Either the customer's primary domain name or the customer's
  /// unique identifier. If using the domain name, we do not recommend using a
  /// `customerId` as a key for persistent data. If the domain name for a
  /// `customerId` is changed, the Google system automatically updates.
  ///
  /// [customerNamePrefix] - When retrieving all of your subscriptions and
  /// filtering for specific customers, you can enter a prefix for a customer
  /// name. Using an example customer group that includes `exam.com`,
  /// `example20.com` and `example.com`: - `exa` -- Returns all customer names
  /// that start with 'exa' which could include `exam.com`, `example20.com`, and
  /// `example.com`. A name prefix is similar to using a regular expression's
  /// asterisk, exa*. - `example` -- Returns `example20.com` and `example.com`.
  ///
  /// [maxResults] - When retrieving a large list, the `maxResults` is the
  /// maximum number of results per page. The `nextPageToken` value takes you to
  /// the next page. The default is 20.
  /// Value must be between "1" and "100".
  ///
  /// [pageToken] - Token to specify next page in the list
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subscriptions].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subscriptions> list({
    core.String? customerAuthToken,
    core.String? customerId,
    core.String? customerNamePrefix,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customerAuthToken != null) 'customerAuthToken': [customerAuthToken],
      if (customerId != null) 'customerId': [customerId],
      if (customerNamePrefix != null)
        'customerNamePrefix': [customerNamePrefix],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'apps/reseller/v1/subscriptions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Subscriptions.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Immediately move a 30-day free trial subscription to a paid service
  /// subscription.
  ///
  /// This method is only applicable if a payment plan has already been set up
  /// for the 30-day trial subscription. For more information, see \[manage
  /// subscriptions\](/admin-sdk/reseller/v1/how-tos/manage_subscriptions#paid_service).
  ///
  /// Request parameters:
  ///
  /// [customerId] - Either the customer's primary domain name or the customer's
  /// unique identifier. If using the domain name, we do not recommend using a
  /// `customerId` as a key for persistent data. If the domain name for a
  /// `customerId` is changed, the Google system automatically updates.
  ///
  /// [subscriptionId] - This is a required property. The `subscriptionId` is
  /// the subscription identifier and is unique for each customer. Since a
  /// `subscriptionId` changes when a subscription is updated, we recommend to
  /// not use this ID as a key for persistent data. And the `subscriptionId` can
  /// be found using the retrieve all reseller subscriptions method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subscription].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subscription> startPaidService(
    core.String customerId,
    core.String subscriptionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apps/reseller/v1/customers/' +
        commons.escapeVariable('$customerId') +
        '/subscriptions/' +
        commons.escapeVariable('$subscriptionId') +
        '/startPaidService';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Subscription.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Suspends an active subscription.
  ///
  /// You can use this method to suspend a paid subscription that is currently
  /// in the `ACTIVE` state. * For `FLEXIBLE` subscriptions, billing is paused.
  /// * For `ANNUAL_MONTHLY_PAY` or `ANNUAL_YEARLY_PAY` subscriptions: *
  /// Suspending the subscription does not change the renewal date that was
  /// originally committed to. * A suspended subscription does not renew. If you
  /// activate the subscription after the original renewal date, a new annual
  /// subscription will be created, starting on the day of activation. We
  /// strongly encourage you to suspend subscriptions only for short periods of
  /// time as suspensions over 60 days may result in the subscription being
  /// cancelled.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Either the customer's primary domain name or the customer's
  /// unique identifier. If using the domain name, we do not recommend using a
  /// `customerId` as a key for persistent data. If the domain name for a
  /// `customerId` is changed, the Google system automatically updates.
  ///
  /// [subscriptionId] - This is a required property. The `subscriptionId` is
  /// the subscription identifier and is unique for each customer. Since a
  /// `subscriptionId` changes when a subscription is updated, we recommend to
  /// not use this ID as a key for persistent data. And the `subscriptionId` can
  /// be found using the retrieve all reseller subscriptions method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Subscription].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Subscription> suspend(
    core.String customerId,
    core.String subscriptionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'apps/reseller/v1/customers/' +
        commons.escapeVariable('$customerId') +
        '/subscriptions/' +
        commons.escapeVariable('$subscriptionId') +
        '/suspend';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Subscription.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// JSON template for address of a customer.
class Address {
  /// A customer's physical address.
  ///
  /// An address can be composed of one to three lines. The `addressline2` and
  /// `addressLine3` are optional.
  core.String? addressLine1;

  /// Line 2 of the address.
  core.String? addressLine2;

  /// Line 3 of the address.
  core.String? addressLine3;

  /// The customer contact's name.
  ///
  /// This is required.
  core.String? contactName;

  /// For `countryCode` information, see the ISO 3166 country code elements.
  ///
  /// Verify that country is approved for resale of Google products. This
  /// property is required when creating a new customer.
  core.String? countryCode;

  /// Identifies the resource as a customer address.
  ///
  /// Value: `customers#address`
  core.String? kind;

  /// An example of a `locality` value is the city of `San Francisco`.
  core.String? locality;

  /// The company or company division name.
  ///
  /// This is required.
  core.String? organizationName;

  /// A `postalCode` example is a postal zip code such as `94043`.
  ///
  /// This property is required when creating a new customer.
  core.String? postalCode;

  /// An example of a `region` value is `CA` for the state of California.
  core.String? region;

  Address();

  Address.fromJson(core.Map _json) {
    if (_json.containsKey('addressLine1')) {
      addressLine1 = _json['addressLine1'] as core.String;
    }
    if (_json.containsKey('addressLine2')) {
      addressLine2 = _json['addressLine2'] as core.String;
    }
    if (_json.containsKey('addressLine3')) {
      addressLine3 = _json['addressLine3'] as core.String;
    }
    if (_json.containsKey('contactName')) {
      contactName = _json['contactName'] as core.String;
    }
    if (_json.containsKey('countryCode')) {
      countryCode = _json['countryCode'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('locality')) {
      locality = _json['locality'] as core.String;
    }
    if (_json.containsKey('organizationName')) {
      organizationName = _json['organizationName'] as core.String;
    }
    if (_json.containsKey('postalCode')) {
      postalCode = _json['postalCode'] as core.String;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (addressLine1 != null) 'addressLine1': addressLine1!,
        if (addressLine2 != null) 'addressLine2': addressLine2!,
        if (addressLine3 != null) 'addressLine3': addressLine3!,
        if (contactName != null) 'contactName': contactName!,
        if (countryCode != null) 'countryCode': countryCode!,
        if (kind != null) 'kind': kind!,
        if (locality != null) 'locality': locality!,
        if (organizationName != null) 'organizationName': organizationName!,
        if (postalCode != null) 'postalCode': postalCode!,
        if (region != null) 'region': region!,
      };
}

/// JSON template for the ChangePlan rpc request.
class ChangePlanRequest {
  /// Google-issued code (100 char max) for discounted pricing on subscription
  /// plans.
  ///
  /// Deal code must be included in `changePlan` request in order to receive
  /// discounted rate. This property is optional. If a deal code has already
  /// been added to a subscription, this property may be left empty and the
  /// existing discounted rate will still apply (if not empty, only provide the
  /// deal code that is already present on the subscription). If a deal code has
  /// never been added to a subscription and this property is left blank,
  /// regular pricing will apply.
  core.String? dealCode;

  /// Identifies the resource as a subscription change plan request.
  ///
  /// Value: `subscriptions#changePlanRequest`
  core.String? kind;

  /// The `planName` property is required.
  ///
  /// This is the name of the subscription's payment plan. For more information
  /// about the Google payment plans, see API concepts. Possible values are: -
  /// `ANNUAL_MONTHLY_PAY` - The annual commitment plan with monthly payments
  /// *Caution: *`ANNUAL_MONTHLY_PAY` is returned as `ANNUAL` in all API
  /// responses. - `ANNUAL_YEARLY_PAY` - The annual commitment plan with yearly
  /// payments - `FLEXIBLE` - The flexible plan - `TRIAL` - The 30-day free
  /// trial plan
  core.String? planName;

  /// This is an optional property.
  ///
  /// This purchase order (PO) information is for resellers to use for their
  /// company tracking usage. If a `purchaseOrderId` value is given it appears
  /// in the API responses and shows up in the invoice. The property accepts up
  /// to 80 plain text characters.
  core.String? purchaseOrderId;

  /// This is a required property.
  ///
  /// The seats property is the number of user seat licenses.
  Seats? seats;

  ChangePlanRequest();

  ChangePlanRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dealCode')) {
      dealCode = _json['dealCode'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('planName')) {
      planName = _json['planName'] as core.String;
    }
    if (_json.containsKey('purchaseOrderId')) {
      purchaseOrderId = _json['purchaseOrderId'] as core.String;
    }
    if (_json.containsKey('seats')) {
      seats =
          Seats.fromJson(_json['seats'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dealCode != null) 'dealCode': dealCode!,
        if (kind != null) 'kind': kind!,
        if (planName != null) 'planName': planName!,
        if (purchaseOrderId != null) 'purchaseOrderId': purchaseOrderId!,
        if (seats != null) 'seats': seats!.toJson(),
      };
}

/// When a Google customer's account is registered with a reseller, the
/// customer's subscriptions for Google services are managed by this reseller.
///
/// A customer is described by a primary domain name and a physical address.
class Customer {
  /// Like the "Customer email" in the reseller tools, this email is the
  /// secondary contact used if something happens to the customer's service such
  /// as service outage or a security issue.
  ///
  /// This property is required when creating a new customer and should not use
  /// the same domain as `customerDomain`.
  core.String? alternateEmail;

  /// The customer's primary domain name string.
  ///
  /// `customerDomain` is required when creating a new customer. Do not include
  /// the `www` prefix in the domain when adding a customer.
  core.String? customerDomain;

  /// Whether the customer's primary domain has been verified.
  core.bool? customerDomainVerified;

  /// This property will always be returned in a response as the unique
  /// identifier generated by Google.
  ///
  /// In a request, this property can be either the primary domain or the unique
  /// identifier generated by Google.
  core.String? customerId;

  /// Identifies the resource as a customer.
  ///
  /// Value: `reseller#customer`
  core.String? kind;

  /// Customer contact phone number.
  ///
  /// Must start with "+" followed by the country code. The rest of the number
  /// can be contiguous numbers or respect the phone local format conventions,
  /// but it must be a real phone number and not, for example, "123". This field
  /// is silently ignored if invalid.
  core.String? phoneNumber;

  /// A customer's address information.
  ///
  /// Each field has a limit of 255 charcters.
  Address? postalAddress;

  /// URL to customer's Admin console dashboard.
  ///
  /// The read-only URL is generated by the API service. This is used if your
  /// client application requires the customer to complete a task in the Admin
  /// console.
  core.String? resourceUiUrl;

  Customer();

  Customer.fromJson(core.Map _json) {
    if (_json.containsKey('alternateEmail')) {
      alternateEmail = _json['alternateEmail'] as core.String;
    }
    if (_json.containsKey('customerDomain')) {
      customerDomain = _json['customerDomain'] as core.String;
    }
    if (_json.containsKey('customerDomainVerified')) {
      customerDomainVerified = _json['customerDomainVerified'] as core.bool;
    }
    if (_json.containsKey('customerId')) {
      customerId = _json['customerId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
    if (_json.containsKey('postalAddress')) {
      postalAddress = Address.fromJson(
          _json['postalAddress'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resourceUiUrl')) {
      resourceUiUrl = _json['resourceUiUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alternateEmail != null) 'alternateEmail': alternateEmail!,
        if (customerDomain != null) 'customerDomain': customerDomain!,
        if (customerDomainVerified != null)
          'customerDomainVerified': customerDomainVerified!,
        if (customerId != null) 'customerId': customerId!,
        if (kind != null) 'kind': kind!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
        if (postalAddress != null) 'postalAddress': postalAddress!.toJson(),
        if (resourceUiUrl != null) 'resourceUiUrl': resourceUiUrl!,
      };
}

/// JSON template for a subscription renewal settings.
class RenewalSettings {
  /// Identifies the resource as a subscription renewal setting.
  ///
  /// Value: `subscriptions#renewalSettings`
  core.String? kind;

  /// Renewal settings for the annual commitment plan.
  ///
  /// For more detailed information, see renewal options in the administrator
  /// help center. When renewing a subscription, the `renewalType` is a required
  /// property.
  core.String? renewalType;

  RenewalSettings();

  RenewalSettings.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('renewalType')) {
      renewalType = _json['renewalType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (renewalType != null) 'renewalType': renewalType!,
      };
}

/// JSON template for resellernotify getwatchdetails response.
class ResellernotifyGetwatchdetailsResponse {
  /// List of registered service accounts.
  core.List<core.String>? serviceAccountEmailAddresses;

  /// Topic name of the PubSub
  core.String? topicName;

  ResellernotifyGetwatchdetailsResponse();

  ResellernotifyGetwatchdetailsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('serviceAccountEmailAddresses')) {
      serviceAccountEmailAddresses =
          (_json['serviceAccountEmailAddresses'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('topicName')) {
      topicName = _json['topicName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (serviceAccountEmailAddresses != null)
          'serviceAccountEmailAddresses': serviceAccountEmailAddresses!,
        if (topicName != null) 'topicName': topicName!,
      };
}

/// JSON template for resellernotify response.
class ResellernotifyResource {
  /// Topic name of the PubSub
  core.String? topicName;

  ResellernotifyResource();

  ResellernotifyResource.fromJson(core.Map _json) {
    if (_json.containsKey('topicName')) {
      topicName = _json['topicName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (topicName != null) 'topicName': topicName!,
      };
}

/// JSON template for subscription seats.
class Seats {
  /// Identifies the resource as a subscription seat setting.
  ///
  /// Value: `subscriptions#seats`
  core.String? kind;

  /// Read-only field containing the current number of users that are assigned a
  /// license for the product defined in `skuId`.
  ///
  /// This field's value is equivalent to the numerical count of users returned
  /// by the Enterprise License Manager API method:
  /// \[`listForProductAndSku`\](/admin-sdk/licensing/v1/reference/licenseAssignments/listForProductAndSku).
  core.int? licensedNumberOfSeats;

  /// This is a required property and is exclusive to subscriptions with
  /// `FLEXIBLE` or `TRIAL` plans.
  ///
  /// This property sets the maximum number of licensed users allowed on a
  /// subscription. This quantity can be increased up to the maximum limit
  /// defined in the reseller's contract. The minimum quantity is the current
  /// number of users in the customer account. *Note: *G Suite subscriptions
  /// automatically assign a license to every user.
  core.int? maximumNumberOfSeats;

  /// This is a required property and is exclusive to subscriptions with
  /// `ANNUAL_MONTHLY_PAY` and `ANNUAL_YEARLY_PAY` plans.
  ///
  /// This property sets the maximum number of licenses assignable to users on a
  /// subscription. The reseller can add more licenses, but once set, the
  /// `numberOfSeats` cannot be reduced until renewal. The reseller is invoiced
  /// based on the `numberOfSeats` value regardless of how many of these user
  /// licenses are assigned. *Note: *G Suite subscriptions automatically assign
  /// a license to every user.
  core.int? numberOfSeats;

  Seats();

  Seats.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('licensedNumberOfSeats')) {
      licensedNumberOfSeats = _json['licensedNumberOfSeats'] as core.int;
    }
    if (_json.containsKey('maximumNumberOfSeats')) {
      maximumNumberOfSeats = _json['maximumNumberOfSeats'] as core.int;
    }
    if (_json.containsKey('numberOfSeats')) {
      numberOfSeats = _json['numberOfSeats'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (licensedNumberOfSeats != null)
          'licensedNumberOfSeats': licensedNumberOfSeats!,
        if (maximumNumberOfSeats != null)
          'maximumNumberOfSeats': maximumNumberOfSeats!,
        if (numberOfSeats != null) 'numberOfSeats': numberOfSeats!,
      };
}

/// In this version of the API, annual commitment plan's interval is one year.
///
/// *Note: *When `billingMethod` value is `OFFLINE`, the subscription property
/// object `plan.commitmentInterval` is omitted in all API responses.
class SubscriptionPlanCommitmentInterval {
  /// An annual commitment plan's interval's `endTime` in milliseconds using the
  /// UNIX Epoch format.
  ///
  /// See an example Epoch converter.
  core.String? endTime;

  /// An annual commitment plan's interval's `startTime` in milliseconds using
  /// UNIX Epoch format.
  ///
  /// See an example Epoch converter.
  core.String? startTime;

  SubscriptionPlanCommitmentInterval();

  SubscriptionPlanCommitmentInterval.fromJson(core.Map _json) {
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

/// The `plan` property is required.
///
/// In this version of the API, the G Suite plans are the flexible plan, annual
/// commitment plan, and the 30-day free trial plan. For more information about
/// the API"s payment plans, see the API concepts.
class SubscriptionPlan {
  /// In this version of the API, annual commitment plan's interval is one year.
  ///
  /// *Note: *When `billingMethod` value is `OFFLINE`, the subscription property
  /// object `plan.commitmentInterval` is omitted in all API responses.
  SubscriptionPlanCommitmentInterval? commitmentInterval;

  /// The `isCommitmentPlan` property's boolean value identifies the plan as an
  /// annual commitment plan: - `true` — The subscription's plan is an annual
  /// commitment plan.
  ///
  /// - `false` — The plan is not an annual commitment plan.
  core.bool? isCommitmentPlan;

  /// The `planName` property is required.
  ///
  /// This is the name of the subscription's plan. For more information about
  /// the Google payment plans, see the API concepts. Possible values are: -
  /// `ANNUAL_MONTHLY_PAY` — The annual commitment plan with monthly payments.
  /// *Caution: *`ANNUAL_MONTHLY_PAY` is returned as `ANNUAL` in all API
  /// responses. - `ANNUAL_YEARLY_PAY` — The annual commitment plan with yearly
  /// payments - `FLEXIBLE` — The flexible plan - `TRIAL` — The 30-day free
  /// trial plan. A subscription in trial will be suspended after the 30th free
  /// day if no payment plan is assigned. Calling `changePlan` will assign a
  /// payment plan to a trial but will not activate the plan. A trial will
  /// automatically begin its assigned payment plan after its 30th free day or
  /// immediately after calling `startPaidService`. - `FREE` — The free plan is
  /// exclusive to the Cloud Identity SKU and does not incur any billing.
  core.String? planName;

  SubscriptionPlan();

  SubscriptionPlan.fromJson(core.Map _json) {
    if (_json.containsKey('commitmentInterval')) {
      commitmentInterval = SubscriptionPlanCommitmentInterval.fromJson(
          _json['commitmentInterval'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('isCommitmentPlan')) {
      isCommitmentPlan = _json['isCommitmentPlan'] as core.bool;
    }
    if (_json.containsKey('planName')) {
      planName = _json['planName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (commitmentInterval != null)
          'commitmentInterval': commitmentInterval!.toJson(),
        if (isCommitmentPlan != null) 'isCommitmentPlan': isCommitmentPlan!,
        if (planName != null) 'planName': planName!,
      };
}

/// Read-only transfer related information for the subscription.
///
/// For more information, see retrieve transferable subscriptions for a
/// customer.
class SubscriptionTransferInfo {
  /// Sku id of the current resold subscription.
  ///
  /// This is populated only when customer has subscription with legacy sku and
  /// the subscription resource is populated with recommeded sku for transfer
  /// in.
  core.String? currentLegacySkuId;

  /// When inserting a subscription, this is the minimum number of seats listed
  /// in the transfer order for this product.
  ///
  /// For example, if the customer has 20 users, the reseller cannot place a
  /// transfer order of 15 seats. The minimum is 20 seats.
  core.int? minimumTransferableSeats;

  /// The time when transfer token or intent to transfer will expire.
  ///
  /// The time is in milliseconds using UNIX Epoch format.
  core.String? transferabilityExpirationTime;

  SubscriptionTransferInfo();

  SubscriptionTransferInfo.fromJson(core.Map _json) {
    if (_json.containsKey('currentLegacySkuId')) {
      currentLegacySkuId = _json['currentLegacySkuId'] as core.String;
    }
    if (_json.containsKey('minimumTransferableSeats')) {
      minimumTransferableSeats = _json['minimumTransferableSeats'] as core.int;
    }
    if (_json.containsKey('transferabilityExpirationTime')) {
      transferabilityExpirationTime =
          _json['transferabilityExpirationTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentLegacySkuId != null)
          'currentLegacySkuId': currentLegacySkuId!,
        if (minimumTransferableSeats != null)
          'minimumTransferableSeats': minimumTransferableSeats!,
        if (transferabilityExpirationTime != null)
          'transferabilityExpirationTime': transferabilityExpirationTime!,
      };
}

/// The G Suite annual commitment and flexible payment plans can be in a 30-day
/// free trial.
///
/// For more information, see the API concepts.
class SubscriptionTrialSettings {
  /// Determines if a subscription's plan is in a 30-day free trial or not: -
  /// `true` — The plan is in trial.
  ///
  /// - `false` — The plan is not in trial.
  core.bool? isInTrial;

  /// Date when the trial ends.
  ///
  /// The value is in milliseconds using the UNIX Epoch format. See an example
  /// Epoch converter.
  core.String? trialEndTime;

  SubscriptionTrialSettings();

  SubscriptionTrialSettings.fromJson(core.Map _json) {
    if (_json.containsKey('isInTrial')) {
      isInTrial = _json['isInTrial'] as core.bool;
    }
    if (_json.containsKey('trialEndTime')) {
      trialEndTime = _json['trialEndTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (isInTrial != null) 'isInTrial': isInTrial!,
        if (trialEndTime != null) 'trialEndTime': trialEndTime!,
      };
}

/// JSON template for a subscription.
class Subscription {
  /// Read-only field that returns the current billing method for a
  /// subscription.
  core.String? billingMethod;

  /// The `creationTime` property is the date when subscription was created.
  ///
  /// It is in milliseconds using the Epoch format. See an example Epoch
  /// converter.
  core.String? creationTime;

  /// Primary domain name of the customer
  core.String? customerDomain;

  /// This property will always be returned in a response as the unique
  /// identifier generated by Google.
  ///
  /// In a request, this property can be either the primary domain or the unique
  /// identifier generated by Google.
  core.String? customerId;

  /// Google-issued code (100 char max) for discounted pricing on subscription
  /// plans.
  ///
  /// Deal code must be included in `insert` requests in order to receive
  /// discounted rate. This property is optional, regular pricing applies if
  /// left empty.
  core.String? dealCode;

  /// Identifies the resource as a Subscription.
  ///
  /// Value: `reseller#subscription`
  core.String? kind;

  /// The `plan` property is required.
  ///
  /// In this version of the API, the G Suite plans are the flexible plan,
  /// annual commitment plan, and the 30-day free trial plan. For more
  /// information about the API"s payment plans, see the API concepts.
  SubscriptionPlan? plan;

  /// This is an optional property.
  ///
  /// This purchase order (PO) information is for resellers to use for their
  /// company tracking usage. If a `purchaseOrderId` value is given it appears
  /// in the API responses and shows up in the invoice. The property accepts up
  /// to 80 plain text characters.
  core.String? purchaseOrderId;

  /// Renewal settings for the annual commitment plan.
  ///
  /// For more detailed information, see renewal options in the administrator
  /// help center.
  RenewalSettings? renewalSettings;

  /// URL to customer's Subscriptions page in the Admin console.
  ///
  /// The read-only URL is generated by the API service. This is used if your
  /// client application requires the customer to complete a task using the
  /// Subscriptions page in the Admin console.
  core.String? resourceUiUrl;

  /// This is a required property.
  ///
  /// The number and limit of user seat licenses in the plan.
  Seats? seats;

  /// A required property.
  ///
  /// The `skuId` is a unique system identifier for a product's SKU assigned to
  /// a customer in the subscription. For products and SKUs available in this
  /// version of the API, see Product and SKU IDs.
  core.String? skuId;

  /// Read-only external display name for a product's SKU assigned to a customer
  /// in the subscription.
  ///
  /// SKU names are subject to change at Google's discretion. For products and
  /// SKUs available in this version of the API, see Product and SKU IDs.
  core.String? skuName;

  /// This is an optional property.
  core.String? status;

  /// The `subscriptionId` is the subscription identifier and is unique for each
  /// customer.
  ///
  /// This is a required property. Since a `subscriptionId` changes when a
  /// subscription is updated, we recommend not using this ID as a key for
  /// persistent data. Use the `subscriptionId` as described in retrieve all
  /// reseller subscriptions.
  core.String? subscriptionId;

  /// Read-only field containing an enumerable of all the current suspension
  /// reasons for a subscription.
  ///
  /// It is possible for a subscription to have many concurrent, overlapping
  /// suspension reasons. A subscription's `STATUS` is `SUSPENDED` until all
  /// pending suspensions are removed. Possible options include: -
  /// `PENDING_TOS_ACCEPTANCE` - The customer has not logged in and accepted the
  /// G Suite Resold Terms of Services. - `RENEWAL_WITH_TYPE_CANCEL` - The
  /// customer's commitment ended and their service was cancelled at the end of
  /// their term. - `RESELLER_INITIATED` - A manual suspension invoked by a
  /// Reseller. - `TRIAL_ENDED` - The customer's trial expired without a plan
  /// selected. - `OTHER` - The customer is suspended for an internal Google
  /// reason (e.g. abuse or otherwise).
  core.List<core.String>? suspensionReasons;

  /// Read-only transfer related information for the subscription.
  ///
  /// For more information, see retrieve transferable subscriptions for a
  /// customer.
  SubscriptionTransferInfo? transferInfo;

  /// The G Suite annual commitment and flexible payment plans can be in a
  /// 30-day free trial.
  ///
  /// For more information, see the API concepts.
  SubscriptionTrialSettings? trialSettings;

  Subscription();

  Subscription.fromJson(core.Map _json) {
    if (_json.containsKey('billingMethod')) {
      billingMethod = _json['billingMethod'] as core.String;
    }
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('customerDomain')) {
      customerDomain = _json['customerDomain'] as core.String;
    }
    if (_json.containsKey('customerId')) {
      customerId = _json['customerId'] as core.String;
    }
    if (_json.containsKey('dealCode')) {
      dealCode = _json['dealCode'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('plan')) {
      plan = SubscriptionPlan.fromJson(
          _json['plan'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('purchaseOrderId')) {
      purchaseOrderId = _json['purchaseOrderId'] as core.String;
    }
    if (_json.containsKey('renewalSettings')) {
      renewalSettings = RenewalSettings.fromJson(
          _json['renewalSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resourceUiUrl')) {
      resourceUiUrl = _json['resourceUiUrl'] as core.String;
    }
    if (_json.containsKey('seats')) {
      seats =
          Seats.fromJson(_json['seats'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('skuId')) {
      skuId = _json['skuId'] as core.String;
    }
    if (_json.containsKey('skuName')) {
      skuName = _json['skuName'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('subscriptionId')) {
      subscriptionId = _json['subscriptionId'] as core.String;
    }
    if (_json.containsKey('suspensionReasons')) {
      suspensionReasons = (_json['suspensionReasons'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('transferInfo')) {
      transferInfo = SubscriptionTransferInfo.fromJson(
          _json['transferInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('trialSettings')) {
      trialSettings = SubscriptionTrialSettings.fromJson(
          _json['trialSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (billingMethod != null) 'billingMethod': billingMethod!,
        if (creationTime != null) 'creationTime': creationTime!,
        if (customerDomain != null) 'customerDomain': customerDomain!,
        if (customerId != null) 'customerId': customerId!,
        if (dealCode != null) 'dealCode': dealCode!,
        if (kind != null) 'kind': kind!,
        if (plan != null) 'plan': plan!.toJson(),
        if (purchaseOrderId != null) 'purchaseOrderId': purchaseOrderId!,
        if (renewalSettings != null)
          'renewalSettings': renewalSettings!.toJson(),
        if (resourceUiUrl != null) 'resourceUiUrl': resourceUiUrl!,
        if (seats != null) 'seats': seats!.toJson(),
        if (skuId != null) 'skuId': skuId!,
        if (skuName != null) 'skuName': skuName!,
        if (status != null) 'status': status!,
        if (subscriptionId != null) 'subscriptionId': subscriptionId!,
        if (suspensionReasons != null) 'suspensionReasons': suspensionReasons!,
        if (transferInfo != null) 'transferInfo': transferInfo!.toJson(),
        if (trialSettings != null) 'trialSettings': trialSettings!.toJson(),
      };
}

/// A subscription manages the relationship of a Google customer's payment plan
/// with a product's SKU, user licenses, 30-day free trial status, and renewal
/// options.
///
/// A primary role of a reseller is to manage the Google customer's
/// subscriptions.
class Subscriptions {
  /// Identifies the resource as a collection of subscriptions.
  ///
  /// Value: reseller#subscriptions
  core.String? kind;

  /// The continuation token, used to page through large result sets.
  ///
  /// Provide this value in a subsequent request to return the next page of
  /// results.
  core.String? nextPageToken;

  /// The subscriptions in this page of results.
  core.List<Subscription>? subscriptions;

  Subscriptions();

  Subscriptions.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('subscriptions')) {
      subscriptions = (_json['subscriptions'] as core.List)
          .map<Subscription>((value) => Subscription.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (subscriptions != null)
          'subscriptions':
              subscriptions!.map((value) => value.toJson()).toList(),
      };
}

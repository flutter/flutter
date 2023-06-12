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

/// Cloud Billing API - v1
///
/// Allows developers to manage billing for their Google Cloud Platform projects
/// programmatically.
///
/// For more information, see <https://cloud.google.com/billing/>
///
/// Create an instance of [CloudbillingApi] to access these resources:
///
/// - [BillingAccountsResource]
///   - [BillingAccountsProjectsResource]
/// - [ProjectsResource]
/// - [ServicesResource]
///   - [ServicesSkusResource]
library cloudbilling.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Allows developers to manage billing for their Google Cloud Platform projects
/// programmatically.
class CloudbillingApi {
  /// View and manage your Google Cloud Platform billing accounts
  static const cloudBillingScope =
      'https://www.googleapis.com/auth/cloud-billing';

  /// View your Google Cloud Platform billing accounts
  static const cloudBillingReadonlyScope =
      'https://www.googleapis.com/auth/cloud-billing.readonly';

  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  BillingAccountsResource get billingAccounts =>
      BillingAccountsResource(_requester);
  ProjectsResource get projects => ProjectsResource(_requester);
  ServicesResource get services => ServicesResource(_requester);

  CloudbillingApi(http.Client client,
      {core.String rootUrl = 'https://cloudbilling.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class BillingAccountsResource {
  final commons.ApiRequester _requester;

  BillingAccountsProjectsResource get projects =>
      BillingAccountsProjectsResource(_requester);

  BillingAccountsResource(commons.ApiRequester client) : _requester = client;

  /// This method creates
  /// [billing subaccounts](https://cloud.google.com/billing/docs/concepts#subaccounts).
  ///
  /// Google Cloud resellers should use the Channel Services APIs,
  /// [accounts.customers.create](https://cloud.google.com/channel/docs/reference/rest/v1/accounts.customers/create)
  /// and
  /// [accounts.customers.entitlements.create](https://cloud.google.com/channel/docs/reference/rest/v1/accounts.customers.entitlements/create).
  /// When creating a subaccount, the current authenticated user must have the
  /// `billing.accounts.update` IAM permission on the parent account, which is
  /// typically given to billing account
  /// [administrators](https://cloud.google.com/billing/docs/how-to/billing-access).
  /// This method will return an error if the parent account has not been
  /// provisioned as a reseller account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BillingAccount].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BillingAccount> create(
    BillingAccount request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/billingAccounts';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BillingAccount.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets information about a billing account.
  ///
  /// The current authenticated user must be a
  /// [viewer of the billing account](https://cloud.google.com/billing/docs/how-to/billing-access).
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the billing account to retrieve.
  /// For example, `billingAccounts/012345-567890-ABCDEF`.
  /// Value must have pattern `^billingAccounts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BillingAccount].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BillingAccount> get(
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
    return BillingAccount.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy for a billing account.
  ///
  /// The caller must have the `billing.accounts.getIamPolicy` permission on the
  /// account, which is often given to billing account
  /// [viewers](https://cloud.google.com/billing/docs/how-to/billing-access).
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^billingAccounts/\[^/\]+$`.
  ///
  /// [options_requestedPolicyVersion] - Optional. The policy format version to
  /// be returned. Valid values are 0, 1, and 3. Requests specifying an invalid
  /// value will be rejected. Requests for policies with any conditional
  /// bindings must specify version 3. Policies without any conditional bindings
  /// may specify any valid value or leave the field unset. To learn which
  /// resources support conditions in their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Policy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Policy> getIamPolicy(
    core.String resource, {
    core.int? options_requestedPolicyVersion,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (options_requestedPolicyVersion != null)
        'options.requestedPolicyVersion': ['${options_requestedPolicyVersion}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the billing accounts that the current authenticated user has
  /// permission to
  /// [view](https://cloud.google.com/billing/docs/how-to/billing-access).
  ///
  /// Request parameters:
  ///
  /// [filter] - Options for how to filter the returned billing accounts.
  /// Currently this only supports filtering for
  /// [subaccounts](https://cloud.google.com/billing/docs/concepts) under a
  /// single provided reseller billing account. (e.g.
  /// "master_billing_account=billingAccounts/012345-678901-ABCDEF"). Boolean
  /// algebra and other fields are not currently supported.
  ///
  /// [pageSize] - Requested page size. The maximum page size is 100; this is
  /// also the default.
  ///
  /// [pageToken] - A token identifying a page of results to return. This should
  /// be a `next_page_token` value returned from a previous
  /// `ListBillingAccounts` call. If unspecified, the first page of results is
  /// returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListBillingAccountsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListBillingAccountsResponse> list({
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

    const _url = 'v1/billingAccounts';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListBillingAccountsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a billing account's fields.
  ///
  /// Currently the only field that can be edited is `display_name`. The current
  /// authenticated user must have the `billing.accounts.update` IAM permission,
  /// which is typically given to the
  /// [administrator](https://cloud.google.com/billing/docs/how-to/billing-access)
  /// of the billing account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the billing account resource to be updated.
  /// Value must have pattern `^billingAccounts/\[^/\]+$`.
  ///
  /// [updateMask] - The update mask applied to the resource. Only
  /// "display_name" is currently supported.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BillingAccount].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BillingAccount> patch(
    BillingAccount request,
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
    return BillingAccount.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy for a billing account.
  ///
  /// Replaces any existing policy. The caller must have the
  /// `billing.accounts.setIamPolicy` permission on the account, which is often
  /// given to billing account
  /// [administrators](https://cloud.google.com/billing/docs/how-to/billing-access).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^billingAccounts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Policy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Policy> setIamPolicy(
    SetIamPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':setIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Tests the access control policy for a billing account.
  ///
  /// This method takes the resource and a set of permissions as input and
  /// returns the subset of the input permissions that the caller is allowed for
  /// that resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^billingAccounts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TestIamPermissionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TestIamPermissionsResponse> testIamPermissions(
    TestIamPermissionsRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$resource') + ':testIamPermissions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TestIamPermissionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class BillingAccountsProjectsResource {
  final commons.ApiRequester _requester;

  BillingAccountsProjectsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists the projects associated with a billing account.
  ///
  /// The current authenticated user must have the
  /// `billing.resourceAssociations.list` IAM permission, which is often given
  /// to billing account
  /// [viewers](https://cloud.google.com/billing/docs/how-to/billing-access).
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the billing account associated
  /// with the projects that you want to list. For example,
  /// `billingAccounts/012345-567890-ABCDEF`.
  /// Value must have pattern `^billingAccounts/\[^/\]+$`.
  ///
  /// [pageSize] - Requested page size. The maximum page size is 100; this is
  /// also the default.
  ///
  /// [pageToken] - A token identifying a page of results to be returned. This
  /// should be a `next_page_token` value returned from a previous
  /// `ListProjectBillingInfo` call. If unspecified, the first page of results
  /// is returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListProjectBillingInfoResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListProjectBillingInfoResponse> list(
    core.String name, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/projects';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListProjectBillingInfoResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsResource(commons.ApiRequester client) : _requester = client;

  /// Gets the billing information for a project.
  ///
  /// The current authenticated user must have \[permission to view the
  /// project\](https://cloud.google.com/docs/permissions-overview#h.bgs0oxofvnoo
  /// ).
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the project for which billing
  /// information is retrieved. For example, `projects/tokyo-rain-123`.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ProjectBillingInfo].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ProjectBillingInfo> getBillingInfo(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/billingInfo';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ProjectBillingInfo.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets or updates the billing account associated with a project.
  ///
  /// You specify the new billing account by setting the `billing_account_name`
  /// in the `ProjectBillingInfo` resource to the resource name of a billing
  /// account. Associating a project with an open billing account enables
  /// billing on the project and allows charges for resource usage. If the
  /// project already had a billing account, this method changes the billing
  /// account used for resource usage charges. *Note:* Incurred charges that
  /// have not yet been reported in the transaction history of the Google Cloud
  /// Console might be billed to the new billing account, even if the charge
  /// occurred before the new billing account was assigned to the project. The
  /// current authenticated user must have ownership privileges for both the
  /// \[project\](https://cloud.google.com/docs/permissions-overview#h.bgs0oxofvnoo
  /// ) and the
  /// [billing account](https://cloud.google.com/billing/docs/how-to/billing-access).
  /// You can disable billing on the project by setting the
  /// `billing_account_name` field to empty. This action disassociates the
  /// current billing account from the project. Any billable activity of your
  /// in-use services will stop, and your application could stop functioning as
  /// expected. Any unbilled charges to date will be billed to the previously
  /// associated account. The current authenticated user must be either an owner
  /// of the project or an owner of the billing account for the project. Note
  /// that associating a project with a *closed* billing account will have much
  /// the same effect as disabling billing on the project: any paid resources
  /// used by the project will be shut down. Thus, unless you wish to disable
  /// billing, you should always call this method with the name of an *open*
  /// billing account.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the project associated with the
  /// billing information that you want to update. For example,
  /// `projects/tokyo-rain-123`.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ProjectBillingInfo].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ProjectBillingInfo> updateBillingInfo(
    ProjectBillingInfo request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/billingInfo';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return ProjectBillingInfo.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ServicesResource {
  final commons.ApiRequester _requester;

  ServicesSkusResource get skus => ServicesSkusResource(_requester);

  ServicesResource(commons.ApiRequester client) : _requester = client;

  /// Lists all public cloud services.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Requested page size. Defaults to 5000.
  ///
  /// [pageToken] - A token identifying a page of results to return. This should
  /// be a `next_page_token` value returned from a previous `ListServices` call.
  /// If unspecified, the first page of results is returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListServicesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListServicesResponse> list({
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/services';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListServicesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ServicesSkusResource {
  final commons.ApiRequester _requester;

  ServicesSkusResource(commons.ApiRequester client) : _requester = client;

  /// Lists all publicly available SKUs for a given cloud service.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the service. Example:
  /// "services/DA34-426B-A397"
  /// Value must have pattern `^services/\[^/\]+$`.
  ///
  /// [currencyCode] - The ISO 4217 currency code for the pricing info in the
  /// response proto. Will use the conversion rate as of start_time. Optional.
  /// If not specified USD will be used.
  ///
  /// [endTime] - Optional exclusive end time of the time range for which the
  /// pricing versions will be returned. Timestamps in the future are not
  /// allowed. The time range has to be within a single calendar month in
  /// America/Los_Angeles timezone. Time range as a whole is optional. If not
  /// specified, the latest pricing will be returned (up to 12 hours old at
  /// most).
  ///
  /// [pageSize] - Requested page size. Defaults to 5000.
  ///
  /// [pageToken] - A token identifying a page of results to return. This should
  /// be a `next_page_token` value returned from a previous `ListSkus` call. If
  /// unspecified, the first page of results is returned.
  ///
  /// [startTime] - Optional inclusive start time of the time range for which
  /// the pricing versions will be returned. Timestamps in the future are not
  /// allowed. The time range has to be within a single calendar month in
  /// America/Los_Angeles timezone. Time range as a whole is optional. If not
  /// specified, the latest pricing will be returned (up to 12 hours old at
  /// most).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSkusResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSkusResponse> list(
    core.String parent, {
    core.String? currencyCode,
    core.String? endTime,
    core.int? pageSize,
    core.String? pageToken,
    core.String? startTime,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (currencyCode != null) 'currencyCode': [currencyCode],
      if (endTime != null) 'endTime': [endTime],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (startTime != null) 'startTime': [startTime],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/skus';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSkusResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Represents the aggregation level and interval for pricing of a single SKU.
class AggregationInfo {
  /// The number of intervals to aggregate over.
  ///
  /// Example: If aggregation_level is "DAILY" and aggregation_count is 14,
  /// aggregation will be over 14 days.
  core.int? aggregationCount;

  ///
  /// Possible string values are:
  /// - "AGGREGATION_INTERVAL_UNSPECIFIED"
  /// - "DAILY"
  /// - "MONTHLY"
  core.String? aggregationInterval;

  ///
  /// Possible string values are:
  /// - "AGGREGATION_LEVEL_UNSPECIFIED"
  /// - "ACCOUNT"
  /// - "PROJECT"
  core.String? aggregationLevel;

  AggregationInfo();

  AggregationInfo.fromJson(core.Map _json) {
    if (_json.containsKey('aggregationCount')) {
      aggregationCount = _json['aggregationCount'] as core.int;
    }
    if (_json.containsKey('aggregationInterval')) {
      aggregationInterval = _json['aggregationInterval'] as core.String;
    }
    if (_json.containsKey('aggregationLevel')) {
      aggregationLevel = _json['aggregationLevel'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aggregationCount != null) 'aggregationCount': aggregationCount!,
        if (aggregationInterval != null)
          'aggregationInterval': aggregationInterval!,
        if (aggregationLevel != null) 'aggregationLevel': aggregationLevel!,
      };
}

/// Specifies the audit configuration for a service.
///
/// The configuration determines which permission types are logged, and what
/// identities, if any, are exempted from logging. An AuditConfig must have one
/// or more AuditLogConfigs. If there are AuditConfigs for both `allServices`
/// and a specific service, the union of the two AuditConfigs is used for that
/// service: the log_types specified in each AuditConfig are enabled, and the
/// exempted_members in each AuditLogConfig are exempted. Example Policy with
/// multiple AuditConfigs: { "audit_configs": \[ { "service": "allServices",
/// "audit_log_configs": \[ { "log_type": "DATA_READ", "exempted_members": \[
/// "user:jose@example.com" \] }, { "log_type": "DATA_WRITE" }, { "log_type":
/// "ADMIN_READ" } \] }, { "service": "sampleservice.googleapis.com",
/// "audit_log_configs": \[ { "log_type": "DATA_READ" }, { "log_type":
/// "DATA_WRITE", "exempted_members": \[ "user:aliya@example.com" \] } \] } \] }
/// For sampleservice, this policy enables DATA_READ, DATA_WRITE and ADMIN_READ
/// logging. It also exempts jose@example.com from DATA_READ logging, and
/// aliya@example.com from DATA_WRITE logging.
class AuditConfig {
  /// The configuration for logging of each type of permission.
  core.List<AuditLogConfig>? auditLogConfigs;

  /// Specifies a service that will be enabled for audit logging.
  ///
  /// For example, `storage.googleapis.com`, `cloudsql.googleapis.com`.
  /// `allServices` is a special value that covers all services.
  core.String? service;

  AuditConfig();

  AuditConfig.fromJson(core.Map _json) {
    if (_json.containsKey('auditLogConfigs')) {
      auditLogConfigs = (_json['auditLogConfigs'] as core.List)
          .map<AuditLogConfig>((value) => AuditLogConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('service')) {
      service = _json['service'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auditLogConfigs != null)
          'auditLogConfigs':
              auditLogConfigs!.map((value) => value.toJson()).toList(),
        if (service != null) 'service': service!,
      };
}

/// Provides the configuration for logging a type of permissions.
///
/// Example: { "audit_log_configs": \[ { "log_type": "DATA_READ",
/// "exempted_members": \[ "user:jose@example.com" \] }, { "log_type":
/// "DATA_WRITE" } \] } This enables 'DATA_READ' and 'DATA_WRITE' logging, while
/// exempting jose@example.com from DATA_READ logging.
class AuditLogConfig {
  /// Specifies the identities that do not cause logging for this type of
  /// permission.
  ///
  /// Follows the same format of Binding.members.
  core.List<core.String>? exemptedMembers;

  /// The log type that this config enables.
  /// Possible string values are:
  /// - "LOG_TYPE_UNSPECIFIED" : Default case. Should never be this.
  /// - "ADMIN_READ" : Admin reads. Example: CloudIAM getIamPolicy
  /// - "DATA_WRITE" : Data writes. Example: CloudSQL Users create
  /// - "DATA_READ" : Data reads. Example: CloudSQL Users list
  core.String? logType;

  AuditLogConfig();

  AuditLogConfig.fromJson(core.Map _json) {
    if (_json.containsKey('exemptedMembers')) {
      exemptedMembers = (_json['exemptedMembers'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('logType')) {
      logType = _json['logType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exemptedMembers != null) 'exemptedMembers': exemptedMembers!,
        if (logType != null) 'logType': logType!,
      };
}

/// A billing account in the
/// [Google Cloud Console](https://console.cloud.google.com/).
///
/// You can assign a billing account to one or more projects.
class BillingAccount {
  /// The display name given to the billing account, such as `My Billing
  /// Account`.
  ///
  /// This name is displayed in the Google Cloud Console.
  core.String? displayName;

  /// If this account is a
  /// [subaccount](https://cloud.google.com/billing/docs/concepts), then this
  /// will be the resource name of the parent billing account that it is being
  /// resold through.
  ///
  /// Otherwise this will be empty.
  core.String? masterBillingAccount;

  /// The resource name of the billing account.
  ///
  /// The resource name has the form `billingAccounts/{billing_account_id}`. For
  /// example, `billingAccounts/012345-567890-ABCDEF` would be the resource name
  /// for billing account `012345-567890-ABCDEF`.
  ///
  /// Output only.
  core.String? name;

  /// True if the billing account is open, and will therefore be charged for any
  /// usage on associated projects.
  ///
  /// False if the billing account is closed, and therefore projects associated
  /// with it will be unable to use paid services.
  ///
  /// Output only.
  core.bool? open;

  BillingAccount();

  BillingAccount.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('masterBillingAccount')) {
      masterBillingAccount = _json['masterBillingAccount'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('open')) {
      open = _json['open'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (masterBillingAccount != null)
          'masterBillingAccount': masterBillingAccount!,
        if (name != null) 'name': name!,
        if (open != null) 'open': open!,
      };
}

/// Associates `members` with a `role`.
class Binding {
  /// The condition that is associated with this binding.
  ///
  /// If the condition evaluates to `true`, then this binding applies to the
  /// current request. If the condition evaluates to `false`, then this binding
  /// does not apply to the current request. However, a different role binding
  /// might grant the same role to one or more of the members in this binding.
  /// To learn which resources support conditions in their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  Expr? condition;

  /// Specifies the identities requesting access for a Cloud Platform resource.
  ///
  /// `members` can have the following values: * `allUsers`: A special
  /// identifier that represents anyone who is on the internet; with or without
  /// a Google account. * `allAuthenticatedUsers`: A special identifier that
  /// represents anyone who is authenticated with a Google account or a service
  /// account. * `user:{emailid}`: An email address that represents a specific
  /// Google account. For example, `alice@example.com` . *
  /// `serviceAccount:{emailid}`: An email address that represents a service
  /// account. For example, `my-other-app@appspot.gserviceaccount.com`. *
  /// `group:{emailid}`: An email address that represents a Google group. For
  /// example, `admins@example.com`. * `deleted:user:{emailid}?uid={uniqueid}`:
  /// An email address (plus unique identifier) representing a user that has
  /// been recently deleted. For example,
  /// `alice@example.com?uid=123456789012345678901`. If the user is recovered,
  /// this value reverts to `user:{emailid}` and the recovered user retains the
  /// role in the binding. * `deleted:serviceAccount:{emailid}?uid={uniqueid}`:
  /// An email address (plus unique identifier) representing a service account
  /// that has been recently deleted. For example,
  /// `my-other-app@appspot.gserviceaccount.com?uid=123456789012345678901`. If
  /// the service account is undeleted, this value reverts to
  /// `serviceAccount:{emailid}` and the undeleted service account retains the
  /// role in the binding. * `deleted:group:{emailid}?uid={uniqueid}`: An email
  /// address (plus unique identifier) representing a Google group that has been
  /// recently deleted. For example,
  /// `admins@example.com?uid=123456789012345678901`. If the group is recovered,
  /// this value reverts to `group:{emailid}` and the recovered group retains
  /// the role in the binding. * `domain:{domain}`: The G Suite domain (primary)
  /// that represents all the users of that domain. For example, `google.com` or
  /// `example.com`.
  core.List<core.String>? members;

  /// Role that is assigned to `members`.
  ///
  /// For example, `roles/viewer`, `roles/editor`, or `roles/owner`.
  core.String? role;

  Binding();

  Binding.fromJson(core.Map _json) {
    if (_json.containsKey('condition')) {
      condition = Expr.fromJson(
          _json['condition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('members')) {
      members = (_json['members'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (condition != null) 'condition': condition!.toJson(),
        if (members != null) 'members': members!,
        if (role != null) 'role': role!,
      };
}

/// Represents the category hierarchy of a SKU.
class Category {
  /// The type of product the SKU refers to.
  ///
  /// Example: "Compute", "Storage", "Network", "ApplicationServices" etc.
  core.String? resourceFamily;

  /// A group classification for related SKUs.
  ///
  /// Example: "RAM", "GPU", "Prediction", "Ops", "GoogleEgress" etc.
  core.String? resourceGroup;

  /// The display name of the service this SKU belongs to.
  core.String? serviceDisplayName;

  /// Represents how the SKU is consumed.
  ///
  /// Example: "OnDemand", "Preemptible", "Commit1Mo", "Commit1Yr" etc.
  core.String? usageType;

  Category();

  Category.fromJson(core.Map _json) {
    if (_json.containsKey('resourceFamily')) {
      resourceFamily = _json['resourceFamily'] as core.String;
    }
    if (_json.containsKey('resourceGroup')) {
      resourceGroup = _json['resourceGroup'] as core.String;
    }
    if (_json.containsKey('serviceDisplayName')) {
      serviceDisplayName = _json['serviceDisplayName'] as core.String;
    }
    if (_json.containsKey('usageType')) {
      usageType = _json['usageType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceFamily != null) 'resourceFamily': resourceFamily!,
        if (resourceGroup != null) 'resourceGroup': resourceGroup!,
        if (serviceDisplayName != null)
          'serviceDisplayName': serviceDisplayName!,
        if (usageType != null) 'usageType': usageType!,
      };
}

/// Represents a textual expression in the Common Expression Language (CEL)
/// syntax.
///
/// CEL is a C-like expression language. The syntax and semantics of CEL are
/// documented at https://github.com/google/cel-spec. Example (Comparison):
/// title: "Summary size limit" description: "Determines if a summary is less
/// than 100 chars" expression: "document.summary.size() < 100" Example
/// (Equality): title: "Requestor is owner" description: "Determines if
/// requestor is the document owner" expression: "document.owner ==
/// request.auth.claims.email" Example (Logic): title: "Public documents"
/// description: "Determine whether the document should be publicly visible"
/// expression: "document.type != 'private' && document.type != 'internal'"
/// Example (Data Manipulation): title: "Notification string" description:
/// "Create a notification string with a timestamp." expression: "'New message
/// received at ' + string(document.create_time)" The exact variables and
/// functions that may be referenced within an expression are determined by the
/// service that evaluates it. See the service documentation for additional
/// information.
class Expr {
  /// Description of the expression.
  ///
  /// This is a longer text which describes the expression, e.g. when hovered
  /// over it in a UI.
  ///
  /// Optional.
  core.String? description;

  /// Textual representation of an expression in Common Expression Language
  /// syntax.
  core.String? expression;

  /// String indicating the location of the expression for error reporting, e.g.
  /// a file name and a position in the file.
  ///
  /// Optional.
  core.String? location;

  /// Title for the expression, i.e. a short string describing its purpose.
  ///
  /// This can be used e.g. in UIs which allow to enter the expression.
  ///
  /// Optional.
  core.String? title;

  Expr();

  Expr.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('expression')) {
      expression = _json['expression'] as core.String;
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (expression != null) 'expression': expression!,
        if (location != null) 'location': location!,
        if (title != null) 'title': title!,
      };
}

/// Encapsulates the geographic taxonomy data for a sku.
class GeoTaxonomy {
  /// The list of regions associated with a sku.
  ///
  /// Empty for Global skus, which are associated with all Google Cloud regions.
  core.List<core.String>? regions;

  /// The type of Geo Taxonomy: GLOBAL, REGIONAL, or MULTI_REGIONAL.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : The type is not specified.
  /// - "GLOBAL" : The sku is global in nature, e.g. a license sku. Global skus
  /// are available in all regions, and so have an empty region list.
  /// - "REGIONAL" : The sku is available in a specific region, e.g. "us-west2".
  /// - "MULTI_REGIONAL" : The sku is associated with multiple regions, e.g.
  /// "us-west2" and "us-east1".
  core.String? type;

  GeoTaxonomy();

  GeoTaxonomy.fromJson(core.Map _json) {
    if (_json.containsKey('regions')) {
      regions = (_json['regions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (regions != null) 'regions': regions!,
        if (type != null) 'type': type!,
      };
}

/// Response message for `ListBillingAccounts`.
class ListBillingAccountsResponse {
  /// A list of billing accounts.
  core.List<BillingAccount>? billingAccounts;

  /// A token to retrieve the next page of results.
  ///
  /// To retrieve the next page, call `ListBillingAccounts` again with the
  /// `page_token` field set to this value. This field is empty if there are no
  /// more results to retrieve.
  core.String? nextPageToken;

  ListBillingAccountsResponse();

  ListBillingAccountsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('billingAccounts')) {
      billingAccounts = (_json['billingAccounts'] as core.List)
          .map<BillingAccount>((value) => BillingAccount.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (billingAccounts != null)
          'billingAccounts':
              billingAccounts!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Request message for `ListProjectBillingInfoResponse`.
class ListProjectBillingInfoResponse {
  /// A token to retrieve the next page of results.
  ///
  /// To retrieve the next page, call `ListProjectBillingInfo` again with the
  /// `page_token` field set to this value. This field is empty if there are no
  /// more results to retrieve.
  core.String? nextPageToken;

  /// A list of `ProjectBillingInfo` resources representing the projects
  /// associated with the billing account.
  core.List<ProjectBillingInfo>? projectBillingInfo;

  ListProjectBillingInfoResponse();

  ListProjectBillingInfoResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('projectBillingInfo')) {
      projectBillingInfo = (_json['projectBillingInfo'] as core.List)
          .map<ProjectBillingInfo>((value) => ProjectBillingInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (projectBillingInfo != null)
          'projectBillingInfo':
              projectBillingInfo!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for `ListServices`.
class ListServicesResponse {
  /// A token to retrieve the next page of results.
  ///
  /// To retrieve the next page, call `ListServices` again with the `page_token`
  /// field set to this value. This field is empty if there are no more results
  /// to retrieve.
  core.String? nextPageToken;

  /// A list of services.
  core.List<Service>? services;

  ListServicesResponse();

  ListServicesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('services')) {
      services = (_json['services'] as core.List)
          .map<Service>((value) =>
              Service.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (services != null)
          'services': services!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for `ListSkus`.
class ListSkusResponse {
  /// A token to retrieve the next page of results.
  ///
  /// To retrieve the next page, call `ListSkus` again with the `page_token`
  /// field set to this value. This field is empty if there are no more results
  /// to retrieve.
  core.String? nextPageToken;

  /// The list of public SKUs of the given service.
  core.List<Sku>? skus;

  ListSkusResponse();

  ListSkusResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('skus')) {
      skus = (_json['skus'] as core.List)
          .map<Sku>((value) =>
              Sku.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (skus != null) 'skus': skus!.map((value) => value.toJson()).toList(),
      };
}

/// Represents an amount of money with its currency type.
class Money {
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

  Money();

  Money.fromJson(core.Map _json) {
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

/// An Identity and Access Management (IAM) policy, which specifies access
/// controls for Google Cloud resources.
///
/// A `Policy` is a collection of `bindings`. A `binding` binds one or more
/// `members` to a single `role`. Members can be user accounts, service
/// accounts, Google groups, and domains (such as G Suite). A `role` is a named
/// list of permissions; each `role` can be an IAM predefined role or a
/// user-created custom role. For some types of Google Cloud resources, a
/// `binding` can also specify a `condition`, which is a logical expression that
/// allows access to a resource only if the expression evaluates to `true`. A
/// condition can add constraints based on attributes of the request, the
/// resource, or both. To learn which resources support conditions in their IAM
/// policies, see the
/// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
/// **JSON example:** { "bindings": \[ { "role":
/// "roles/resourcemanager.organizationAdmin", "members": \[
/// "user:mike@example.com", "group:admins@example.com", "domain:google.com",
/// "serviceAccount:my-project-id@appspot.gserviceaccount.com" \] }, { "role":
/// "roles/resourcemanager.organizationViewer", "members": \[
/// "user:eve@example.com" \], "condition": { "title": "expirable access",
/// "description": "Does not grant access after Sep 2020", "expression":
/// "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } \], "etag":
/// "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: -
/// user:mike@example.com - group:admins@example.com - domain:google.com -
/// serviceAccount:my-project-id@appspot.gserviceaccount.com role:
/// roles/resourcemanager.organizationAdmin - members: - user:eve@example.com
/// role: roles/resourcemanager.organizationViewer condition: title: expirable
/// access description: Does not grant access after Sep 2020 expression:
/// request.time < timestamp('2020-10-01T00:00:00.000Z') - etag: BwWWja0YfJA= -
/// version: 3 For a description of IAM and its features, see the
/// [IAM documentation](https://cloud.google.com/iam/docs/).
class Policy {
  /// Specifies cloud audit logging configuration for this policy.
  core.List<AuditConfig>? auditConfigs;

  /// Associates a list of `members` to a `role`.
  ///
  /// Optionally, may specify a `condition` that determines how and when the
  /// `bindings` are applied. Each of the `bindings` must contain at least one
  /// member.
  core.List<Binding>? bindings;

  /// `etag` is used for optimistic concurrency control as a way to help prevent
  /// simultaneous updates of a policy from overwriting each other.
  ///
  /// It is strongly suggested that systems make use of the `etag` in the
  /// read-modify-write cycle to perform policy updates in order to avoid race
  /// conditions: An `etag` is returned in the response to `getIamPolicy`, and
  /// systems are expected to put that etag in the request to `setIamPolicy` to
  /// ensure that their change will be applied to the same version of the
  /// policy. **Important:** If you use IAM Conditions, you must include the
  /// `etag` field whenever you call `setIamPolicy`. If you omit this field,
  /// then IAM allows you to overwrite a version `3` policy with a version `1`
  /// policy, and all of the conditions in the version `3` policy are lost.
  core.String? etag;
  core.List<core.int> get etagAsBytes => convert.base64.decode(etag!);

  set etagAsBytes(core.List<core.int> _bytes) {
    etag =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Specifies the format of the policy.
  ///
  /// Valid values are `0`, `1`, and `3`. Requests that specify an invalid value
  /// are rejected. Any operation that affects conditional role bindings must
  /// specify version `3`. This requirement applies to the following operations:
  /// * Getting a policy that includes a conditional role binding * Adding a
  /// conditional role binding to a policy * Changing a conditional role binding
  /// in a policy * Removing any role binding, with or without a condition, from
  /// a policy that includes conditions **Important:** If you use IAM
  /// Conditions, you must include the `etag` field whenever you call
  /// `setIamPolicy`. If you omit this field, then IAM allows you to overwrite a
  /// version `3` policy with a version `1` policy, and all of the conditions in
  /// the version `3` policy are lost. If a policy does not include any
  /// conditions, operations on that policy may specify any valid version or
  /// leave the field unset. To learn which resources support conditions in
  /// their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  core.int? version;

  Policy();

  Policy.fromJson(core.Map _json) {
    if (_json.containsKey('auditConfigs')) {
      auditConfigs = (_json['auditConfigs'] as core.List)
          .map<AuditConfig>((value) => AuditConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('bindings')) {
      bindings = (_json['bindings'] as core.List)
          .map<Binding>((value) =>
              Binding.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auditConfigs != null)
          'auditConfigs': auditConfigs!.map((value) => value.toJson()).toList(),
        if (bindings != null)
          'bindings': bindings!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (version != null) 'version': version!,
      };
}

/// Expresses a mathematical pricing formula.
///
/// For Example:- `usage_unit: GBy` `tiered_rates:` `[start_usage_amount: 20,
/// unit_price: $10]` `[start_usage_amount: 100, unit_price: $5]` The above
/// expresses a pricing formula where the first 20GB is free, the next 80GB is
/// priced at $10 per GB followed by $5 per GB for additional usage.
class PricingExpression {
  /// The base unit for the SKU which is the unit used in usage exports.
  ///
  /// Example: "By"
  core.String? baseUnit;

  /// Conversion factor for converting from price per usage_unit to price per
  /// base_unit, and start_usage_amount to start_usage_amount in base_unit.
  ///
  /// unit_price / base_unit_conversion_factor = price per base_unit.
  /// start_usage_amount * base_unit_conversion_factor = start_usage_amount in
  /// base_unit.
  core.double? baseUnitConversionFactor;

  /// The base unit in human readable form.
  ///
  /// Example: "byte".
  core.String? baseUnitDescription;

  /// The recommended quantity of units for displaying pricing info.
  ///
  /// When displaying pricing info it is recommended to display: (unit_price *
  /// display_quantity) per display_quantity usage_unit. This field does not
  /// affect the pricing formula and is for display purposes only. Example: If
  /// the unit_price is "0.0001 USD", the usage_unit is "GB" and the
  /// display_quantity is "1000" then the recommended way of displaying the
  /// pricing info is "0.10 USD per 1000 GB"
  core.double? displayQuantity;

  /// The list of tiered rates for this pricing.
  ///
  /// The total cost is computed by applying each of the tiered rates on usage.
  /// This repeated list is sorted by ascending order of start_usage_amount.
  core.List<TierRate>? tieredRates;

  /// The short hand for unit of usage this pricing is specified in.
  ///
  /// Example: usage_unit of "GiBy" means that usage is specified in "Gibi
  /// Byte".
  core.String? usageUnit;

  /// The unit of usage in human readable form.
  ///
  /// Example: "gibi byte".
  core.String? usageUnitDescription;

  PricingExpression();

  PricingExpression.fromJson(core.Map _json) {
    if (_json.containsKey('baseUnit')) {
      baseUnit = _json['baseUnit'] as core.String;
    }
    if (_json.containsKey('baseUnitConversionFactor')) {
      baseUnitConversionFactor =
          (_json['baseUnitConversionFactor'] as core.num).toDouble();
    }
    if (_json.containsKey('baseUnitDescription')) {
      baseUnitDescription = _json['baseUnitDescription'] as core.String;
    }
    if (_json.containsKey('displayQuantity')) {
      displayQuantity = (_json['displayQuantity'] as core.num).toDouble();
    }
    if (_json.containsKey('tieredRates')) {
      tieredRates = (_json['tieredRates'] as core.List)
          .map<TierRate>((value) =>
              TierRate.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('usageUnit')) {
      usageUnit = _json['usageUnit'] as core.String;
    }
    if (_json.containsKey('usageUnitDescription')) {
      usageUnitDescription = _json['usageUnitDescription'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (baseUnit != null) 'baseUnit': baseUnit!,
        if (baseUnitConversionFactor != null)
          'baseUnitConversionFactor': baseUnitConversionFactor!,
        if (baseUnitDescription != null)
          'baseUnitDescription': baseUnitDescription!,
        if (displayQuantity != null) 'displayQuantity': displayQuantity!,
        if (tieredRates != null)
          'tieredRates': tieredRates!.map((value) => value.toJson()).toList(),
        if (usageUnit != null) 'usageUnit': usageUnit!,
        if (usageUnitDescription != null)
          'usageUnitDescription': usageUnitDescription!,
      };
}

/// Represents the pricing information for a SKU at a single point of time.
class PricingInfo {
  /// Aggregation Info.
  ///
  /// This can be left unspecified if the pricing expression doesn't require
  /// aggregation.
  AggregationInfo? aggregationInfo;

  /// Conversion rate used for currency conversion, from USD to the currency
  /// specified in the request.
  ///
  /// This includes any surcharge collected for billing in non USD currency. If
  /// a currency is not specified in the request this defaults to 1.0. Example:
  /// USD * currency_conversion_rate = JPY
  core.double? currencyConversionRate;

  /// The timestamp from which this pricing was effective within the requested
  /// time range.
  ///
  /// This is guaranteed to be greater than or equal to the start_time field in
  /// the request and less than the end_time field in the request. If a time
  /// range was not specified in the request this field will be equivalent to a
  /// time within the last 12 hours, indicating the latest pricing info.
  core.String? effectiveTime;

  /// Expresses the pricing formula.
  ///
  /// See `PricingExpression` for an example.
  PricingExpression? pricingExpression;

  /// An optional human readable summary of the pricing information, has a
  /// maximum length of 256 characters.
  core.String? summary;

  PricingInfo();

  PricingInfo.fromJson(core.Map _json) {
    if (_json.containsKey('aggregationInfo')) {
      aggregationInfo = AggregationInfo.fromJson(
          _json['aggregationInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('currencyConversionRate')) {
      currencyConversionRate =
          (_json['currencyConversionRate'] as core.num).toDouble();
    }
    if (_json.containsKey('effectiveTime')) {
      effectiveTime = _json['effectiveTime'] as core.String;
    }
    if (_json.containsKey('pricingExpression')) {
      pricingExpression = PricingExpression.fromJson(
          _json['pricingExpression'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('summary')) {
      summary = _json['summary'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aggregationInfo != null)
          'aggregationInfo': aggregationInfo!.toJson(),
        if (currencyConversionRate != null)
          'currencyConversionRate': currencyConversionRate!,
        if (effectiveTime != null) 'effectiveTime': effectiveTime!,
        if (pricingExpression != null)
          'pricingExpression': pricingExpression!.toJson(),
        if (summary != null) 'summary': summary!,
      };
}

/// Encapsulation of billing information for a Google Cloud Console project.
///
/// A project has at most one associated billing account at a time (but a
/// billing account can be assigned to multiple projects).
class ProjectBillingInfo {
  /// The resource name of the billing account associated with the project, if
  /// any.
  ///
  /// For example, `billingAccounts/012345-567890-ABCDEF`.
  core.String? billingAccountName;

  /// True if the project is associated with an open billing account, to which
  /// usage on the project is charged.
  ///
  /// False if the project is associated with a closed billing account, or no
  /// billing account at all, and therefore cannot use paid services. This field
  /// is read-only.
  core.bool? billingEnabled;

  /// The resource name for the `ProjectBillingInfo`; has the form
  /// `projects/{project_id}/billingInfo`.
  ///
  /// For example, the resource name for the billing information for project
  /// `tokyo-rain-123` would be `projects/tokyo-rain-123/billingInfo`. This
  /// field is read-only.
  core.String? name;

  /// The ID of the project that this `ProjectBillingInfo` represents, such as
  /// `tokyo-rain-123`.
  ///
  /// This is a convenience field so that you don't need to parse the `name`
  /// field to obtain a project ID. This field is read-only.
  core.String? projectId;

  ProjectBillingInfo();

  ProjectBillingInfo.fromJson(core.Map _json) {
    if (_json.containsKey('billingAccountName')) {
      billingAccountName = _json['billingAccountName'] as core.String;
    }
    if (_json.containsKey('billingEnabled')) {
      billingEnabled = _json['billingEnabled'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (billingAccountName != null)
          'billingAccountName': billingAccountName!,
        if (billingEnabled != null) 'billingEnabled': billingEnabled!,
        if (name != null) 'name': name!,
        if (projectId != null) 'projectId': projectId!,
      };
}

/// Encapsulates a single service in Google Cloud Platform.
class Service {
  /// The business under which the service is offered.
  ///
  /// Ex. "businessEntities/GCP", "businessEntities/Maps"
  core.String? businessEntityName;

  /// A human readable display name for this service.
  core.String? displayName;

  /// The resource name for the service.
  ///
  /// Example: "services/DA34-426B-A397"
  core.String? name;

  /// The identifier for the service.
  ///
  /// Example: "DA34-426B-A397"
  core.String? serviceId;

  Service();

  Service.fromJson(core.Map _json) {
    if (_json.containsKey('businessEntityName')) {
      businessEntityName = _json['businessEntityName'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('serviceId')) {
      serviceId = _json['serviceId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (businessEntityName != null)
          'businessEntityName': businessEntityName!,
        if (displayName != null) 'displayName': displayName!,
        if (name != null) 'name': name!,
        if (serviceId != null) 'serviceId': serviceId!,
      };
}

/// Request message for `SetIamPolicy` method.
class SetIamPolicyRequest {
  /// REQUIRED: The complete policy to be applied to the `resource`.
  ///
  /// The size of the policy is limited to a few 10s of KB. An empty policy is a
  /// valid policy but certain Cloud Platform services (such as Projects) might
  /// reject them.
  Policy? policy;

  /// OPTIONAL: A FieldMask specifying which fields of the policy to modify.
  ///
  /// Only the fields in the mask will be modified. If no mask is provided, the
  /// following default mask is used: `paths: "bindings, etag"`
  core.String? updateMask;

  SetIamPolicyRequest();

  SetIamPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('policy')) {
      policy = Policy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateMask')) {
      updateMask = _json['updateMask'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (policy != null) 'policy': policy!.toJson(),
        if (updateMask != null) 'updateMask': updateMask!,
      };
}

/// Encapsulates a single SKU in Google Cloud Platform
class Sku {
  /// The category hierarchy of this SKU, purely for organizational purpose.
  Category? category;

  /// A human readable description of the SKU, has a maximum length of 256
  /// characters.
  core.String? description;

  /// The geographic taxonomy for this sku.
  GeoTaxonomy? geoTaxonomy;

  /// The resource name for the SKU.
  ///
  /// Example: "services/DA34-426B-A397/skus/AA95-CD31-42FE"
  core.String? name;

  /// A timeline of pricing info for this SKU in chronological order.
  core.List<PricingInfo>? pricingInfo;

  /// Identifies the service provider.
  ///
  /// This is 'Google' for first party services in Google Cloud Platform.
  core.String? serviceProviderName;

  /// List of service regions this SKU is offered at.
  ///
  /// Example: "asia-east1" Service regions can be found at
  /// https://cloud.google.com/about/locations/
  core.List<core.String>? serviceRegions;

  /// The identifier for the SKU.
  ///
  /// Example: "AA95-CD31-42FE"
  core.String? skuId;

  Sku();

  Sku.fromJson(core.Map _json) {
    if (_json.containsKey('category')) {
      category = Category.fromJson(
          _json['category'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('geoTaxonomy')) {
      geoTaxonomy = GeoTaxonomy.fromJson(
          _json['geoTaxonomy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('pricingInfo')) {
      pricingInfo = (_json['pricingInfo'] as core.List)
          .map<PricingInfo>((value) => PricingInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('serviceProviderName')) {
      serviceProviderName = _json['serviceProviderName'] as core.String;
    }
    if (_json.containsKey('serviceRegions')) {
      serviceRegions = (_json['serviceRegions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('skuId')) {
      skuId = _json['skuId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (category != null) 'category': category!.toJson(),
        if (description != null) 'description': description!,
        if (geoTaxonomy != null) 'geoTaxonomy': geoTaxonomy!.toJson(),
        if (name != null) 'name': name!,
        if (pricingInfo != null)
          'pricingInfo': pricingInfo!.map((value) => value.toJson()).toList(),
        if (serviceProviderName != null)
          'serviceProviderName': serviceProviderName!,
        if (serviceRegions != null) 'serviceRegions': serviceRegions!,
        if (skuId != null) 'skuId': skuId!,
      };
}

/// Request message for `TestIamPermissions` method.
class TestIamPermissionsRequest {
  /// The set of permissions to check for the `resource`.
  ///
  /// Permissions with wildcards (such as '*' or 'storage.*') are not allowed.
  /// For more information see
  /// [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
  core.List<core.String>? permissions;

  TestIamPermissionsRequest();

  TestIamPermissionsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (permissions != null) 'permissions': permissions!,
      };
}

/// Response message for `TestIamPermissions` method.
class TestIamPermissionsResponse {
  /// A subset of `TestPermissionsRequest.permissions` that the caller is
  /// allowed.
  core.List<core.String>? permissions;

  TestIamPermissionsResponse();

  TestIamPermissionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (permissions != null) 'permissions': permissions!,
      };
}

/// The price rate indicating starting usage and its corresponding price.
class TierRate {
  /// Usage is priced at this rate only after this amount.
  ///
  /// Example: start_usage_amount of 10 indicates that the usage will be priced
  /// at the unit_price after the first 10 usage_units.
  core.double? startUsageAmount;

  /// The price per unit of usage.
  ///
  /// Example: unit_price of amount $10 indicates that each unit will cost $10.
  Money? unitPrice;

  TierRate();

  TierRate.fromJson(core.Map _json) {
    if (_json.containsKey('startUsageAmount')) {
      startUsageAmount = (_json['startUsageAmount'] as core.num).toDouble();
    }
    if (_json.containsKey('unitPrice')) {
      unitPrice = Money.fromJson(
          _json['unitPrice'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (startUsageAmount != null) 'startUsageAmount': startUsageAmount!,
        if (unitPrice != null) 'unitPrice': unitPrice!.toJson(),
      };
}

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

/// Google Play EMM API - v1
///
/// Manages the deployment of apps to Android Enterprise devices.
///
/// For more information, see
/// <https://developers.google.com/android/work/play/emm-api>
///
/// Create an instance of [AndroidEnterpriseApi] to access these resources:
///
/// - [DevicesResource]
/// - [EnterprisesResource]
/// - [EntitlementsResource]
/// - [GrouplicensesResource]
/// - [GrouplicenseusersResource]
/// - [InstallsResource]
/// - [ManagedconfigurationsfordeviceResource]
/// - [ManagedconfigurationsforuserResource]
/// - [ManagedconfigurationssettingsResource]
/// - [PermissionsResource]
/// - [ProductsResource]
/// - [ServiceaccountkeysResource]
/// - [StorelayoutclustersResource]
/// - [StorelayoutpagesResource]
/// - [UsersResource]
/// - [WebappsResource]
library androidenterprise.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Manages the deployment of apps to Android Enterprise devices.
class AndroidEnterpriseApi {
  /// Manage corporate Android devices
  static const androidenterpriseScope =
      'https://www.googleapis.com/auth/androidenterprise';

  final commons.ApiRequester _requester;

  DevicesResource get devices => DevicesResource(_requester);
  EnterprisesResource get enterprises => EnterprisesResource(_requester);
  EntitlementsResource get entitlements => EntitlementsResource(_requester);
  GrouplicensesResource get grouplicenses => GrouplicensesResource(_requester);
  GrouplicenseusersResource get grouplicenseusers =>
      GrouplicenseusersResource(_requester);
  InstallsResource get installs => InstallsResource(_requester);
  ManagedconfigurationsfordeviceResource get managedconfigurationsfordevice =>
      ManagedconfigurationsfordeviceResource(_requester);
  ManagedconfigurationsforuserResource get managedconfigurationsforuser =>
      ManagedconfigurationsforuserResource(_requester);
  ManagedconfigurationssettingsResource get managedconfigurationssettings =>
      ManagedconfigurationssettingsResource(_requester);
  PermissionsResource get permissions => PermissionsResource(_requester);
  ProductsResource get products => ProductsResource(_requester);
  ServiceaccountkeysResource get serviceaccountkeys =>
      ServiceaccountkeysResource(_requester);
  StorelayoutclustersResource get storelayoutclusters =>
      StorelayoutclustersResource(_requester);
  StorelayoutpagesResource get storelayoutpages =>
      StorelayoutpagesResource(_requester);
  UsersResource get users => UsersResource(_requester);
  WebappsResource get webapps => WebappsResource(_requester);

  AndroidEnterpriseApi(http.Client client,
      {core.String rootUrl = 'https://androidenterprise.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class DevicesResource {
  final commons.ApiRequester _requester;

  DevicesResource(commons.ApiRequester client) : _requester = client;

  /// Uploads a report containing any changes in app states on the device since
  /// the last report was generated.
  ///
  /// You can call this method up to 3 times every 24 hours for a given device.
  /// If you exceed the quota, then the Google Play EMM API returns HTTP 429 Too
  /// Many Requests.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [deviceId] - The ID of the device.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> forceReportUpload(
    core.String enterpriseId,
    core.String userId,
    core.String deviceId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/devices/' +
        commons.escapeVariable('$deviceId') +
        '/forceReportUpload';

    await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves the details of a device.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [deviceId] - The ID of the device.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Device].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Device> get(
    core.String enterpriseId,
    core.String userId,
    core.String deviceId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/devices/' +
        commons.escapeVariable('$deviceId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Device.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves whether a device's access to Google services is enabled or
  /// disabled.
  ///
  /// The device state takes effect only if enforcing EMM policies on Android
  /// devices is enabled in the Google Admin Console. Otherwise, the device
  /// state is ignored and all devices are allowed access to Google services.
  /// This is only supported for Google-managed users.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [deviceId] - The ID of the device.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DeviceState].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DeviceState> getState(
    core.String enterpriseId,
    core.String userId,
    core.String deviceId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/devices/' +
        commons.escapeVariable('$deviceId') +
        '/state';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DeviceState.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the IDs of all of a user's devices.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DevicesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DevicesListResponse> list(
    core.String enterpriseId,
    core.String userId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/devices';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DevicesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets whether a device's access to Google services is enabled or disabled.
  ///
  /// The device state takes effect only if enforcing EMM policies on Android
  /// devices is enabled in the Google Admin Console. Otherwise, the device
  /// state is ignored and all devices are allowed access to Google services.
  /// This is only supported for Google-managed users.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [deviceId] - The ID of the device.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DeviceState].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DeviceState> setState(
    DeviceState request,
    core.String enterpriseId,
    core.String userId,
    core.String deviceId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/devices/' +
        commons.escapeVariable('$deviceId') +
        '/state';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return DeviceState.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the device policy.
  ///
  /// To ensure the policy is properly enforced, you need to prevent unmanaged
  /// accounts from accessing Google Play by setting the allowed_accounts in the
  /// managed configuration for the Google Play package. See restrict accounts
  /// in Google Play.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [deviceId] - The ID of the device.
  ///
  /// [updateMask] - Mask that identifies which fields to update. If not set,
  /// all modifiable fields will be modified. When set in a query parameter,
  /// this field should be specified as updateMask=<field1>,<field2>,...
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Device].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Device> update(
    Device request,
    core.String enterpriseId,
    core.String userId,
    core.String deviceId, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/devices/' +
        commons.escapeVariable('$deviceId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Device.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class EnterprisesResource {
  final commons.ApiRequester _requester;

  EnterprisesResource(commons.ApiRequester client) : _requester = client;

  /// Acknowledges notifications that were received from
  /// Enterprises.PullNotificationSet to prevent subsequent calls from returning
  /// the same notifications.
  ///
  /// Request parameters:
  ///
  /// [notificationSetId] - The notification set ID as returned by
  /// Enterprises.PullNotificationSet. This must be provided.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> acknowledgeNotificationSet({
    core.String? notificationSetId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (notificationSetId != null) 'notificationSetId': [notificationSetId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'androidenterprise/v1/enterprises/acknowledgeNotificationSet';

    await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Completes the signup flow, by specifying the Completion token and
  /// Enterprise token.
  ///
  /// This request must not be called multiple times for a given Enterprise
  /// Token.
  ///
  /// Request parameters:
  ///
  /// [completionToken] - The Completion token initially returned by
  /// GenerateSignupUrl.
  ///
  /// [enterpriseToken] - The Enterprise token appended to the Callback URL.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Enterprise].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Enterprise> completeSignup({
    core.String? completionToken,
    core.String? enterpriseToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (completionToken != null) 'completionToken': [completionToken],
      if (enterpriseToken != null) 'enterpriseToken': [enterpriseToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'androidenterprise/v1/enterprises/completeSignup';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Enterprise.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns a unique token to access an embeddable UI.
  ///
  /// To generate a web UI, pass the generated token into the managed Google
  /// Play javascript API. Each token may only be used to start one UI session.
  /// See the javascript API documentation for further information.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AdministratorWebToken].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AdministratorWebToken> createWebToken(
    AdministratorWebTokenSpec request,
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/createWebToken';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AdministratorWebToken.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Enrolls an enterprise with the calling EMM.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [token] - Required. The token provided by the enterprise to register the
  /// EMM.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Enterprise].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Enterprise> enroll(
    Enterprise request,
    core.String token, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      'token': [token],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'androidenterprise/v1/enterprises/enroll';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Enterprise.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Generates a sign-up URL.
  ///
  /// Request parameters:
  ///
  /// [callbackUrl] - The callback URL to which the Admin will be redirected
  /// after successfully creating an enterprise. Before redirecting there the
  /// system will add a single query parameter to this URL named
  /// "enterpriseToken" which will contain an opaque token to be used for the
  /// CompleteSignup request. Beware that this means that the URL will be
  /// parsed, the parameter added and then a new URL formatted, i.e. there may
  /// be some minor formatting changes and, more importantly, the URL must be
  /// well-formed so that it can be parsed.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SignupInfo].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SignupInfo> generateSignupUrl({
    core.String? callbackUrl,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (callbackUrl != null) 'callbackUrl': [callbackUrl],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'androidenterprise/v1/enterprises/signupUrl';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return SignupInfo.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the name and domain of an enterprise.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Enterprise].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Enterprise> get(
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Enterprise.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns a service account and credentials.
  ///
  /// The service account can be bound to the enterprise by calling setAccount.
  /// The service account is unique to this enterprise and EMM, and will be
  /// deleted if the enterprise is unbound. The credentials contain private key
  /// data and are not stored server-side. This method can only be called after
  /// calling Enterprises.Enroll or Enterprises.CompleteSignup, and before
  /// Enterprises.SetAccount; at other times it will return an error. Subsequent
  /// calls after the first will generate a new, unique set of credentials, and
  /// invalidate the previously generated credentials. Once the service account
  /// is bound to the enterprise, it can be managed using the serviceAccountKeys
  /// resource.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [keyType] - The type of credential to return with the service account.
  /// Required.
  /// Possible string values are:
  /// - "googleCredentials" : Google Credentials File format.
  /// - "pkcs12" : PKCS12 format. The password for the PKCS12 file is
  /// 'notasecret'. For more information, see
  /// https://tools.ietf.org/html/rfc7292. The data for keys of this type are
  /// base64 encoded according to RFC 4648 Section 4. See
  /// http://tools.ietf.org/html/rfc4648#section-4.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ServiceAccount].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ServiceAccount> getServiceAccount(
    core.String enterpriseId, {
    core.String? keyType,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (keyType != null) 'keyType': [keyType],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/serviceAccount';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ServiceAccount.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the store layout for the enterprise.
  ///
  /// If the store layout has not been set, returns "basic" as the store layout
  /// type and no homepage.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [StoreLayout].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<StoreLayout> getStoreLayout(
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/storeLayout';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return StoreLayout.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Looks up an enterprise by domain name.
  ///
  /// This is only supported for enterprises created via the Google-initiated
  /// creation flow. Lookup of the id is not needed for enterprises created via
  /// the EMM-initiated flow since the EMM learns the enterprise ID in the
  /// callback specified in the Enterprises.generateSignupUrl call.
  ///
  /// Request parameters:
  ///
  /// [domain] - Required. The exact primary domain name of the enterprise to
  /// look up.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EnterprisesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EnterprisesListResponse> list(
    core.String domain, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'domain': [domain],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'androidenterprise/v1/enterprises';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return EnterprisesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Pulls and returns a notification set for the enterprises associated with
  /// the service account authenticated for the request.
  ///
  /// The notification set may be empty if no notification are pending. A
  /// notification set returned needs to be acknowledged within 20 seconds by
  /// calling Enterprises.AcknowledgeNotificationSet, unless the notification
  /// set is empty. Notifications that are not acknowledged within the 20
  /// seconds will eventually be included again in the response to another
  /// PullNotificationSet request, and those that are never acknowledged will
  /// ultimately be deleted according to the Google Cloud Platform Pub/Sub
  /// system policy. Multiple requests might be performed concurrently to
  /// retrieve notifications, in which case the pending notifications (if any)
  /// will be split among each caller, if any are pending. If no notifications
  /// are present, an empty notification list is returned. Subsequent requests
  /// may return more notifications once they become available.
  ///
  /// Request parameters:
  ///
  /// [requestMode] - The request mode for pulling notifications. Specifying
  /// waitForNotifications will cause the request to block and wait until one or
  /// more notifications are present, or return an empty notification list if no
  /// notifications are present after some time. Speciying returnImmediately
  /// will cause the request to immediately return the pending notifications, or
  /// an empty list if no notifications are present. If omitted, defaults to
  /// waitForNotifications.
  /// Possible string values are:
  /// - "waitForNotifications" : Wait until one or more notifications are
  /// present.
  /// - "returnImmediately" : Returns immediately whether notifications are
  /// present or not.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [NotificationSet].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<NotificationSet> pullNotificationSet({
    core.String? requestMode,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (requestMode != null) 'requestMode': [requestMode],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'androidenterprise/v1/enterprises/pullNotificationSet';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return NotificationSet.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sends a test notification to validate the EMM integration with the Google
  /// Cloud Pub/Sub service for this enterprise.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EnterprisesSendTestPushNotificationResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EnterprisesSendTestPushNotificationResponse>
      sendTestPushNotification(
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/sendTestPushNotification';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return EnterprisesSendTestPushNotificationResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the account that will be used to authenticate to the API as the
  /// enterprise.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EnterpriseAccount].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EnterpriseAccount> setAccount(
    EnterpriseAccount request,
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/account';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return EnterpriseAccount.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the store layout for the enterprise.
  ///
  /// By default, storeLayoutType is set to "basic" and the basic store layout
  /// is enabled. The basic layout only contains apps approved by the admin, and
  /// that have been added to the available product set for a user (using the
  /// setAvailableProductSet call). Apps on the page are sorted in order of
  /// their product ID value. If you create a custom store layout (by setting
  /// storeLayoutType = "custom" and setting a homepage), the basic store layout
  /// is disabled.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [StoreLayout].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<StoreLayout> setStoreLayout(
    StoreLayout request,
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/storeLayout';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return StoreLayout.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Unenrolls an enterprise from the calling EMM.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> unenroll(
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/unenroll';

    await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }
}

class EntitlementsResource {
  final commons.ApiRequester _requester;

  EntitlementsResource(commons.ApiRequester client) : _requester = client;

  /// Removes an entitlement to an app for a user.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [entitlementId] - The ID of the entitlement (a product ID), e.g.
  /// "app:com.google.android.gm".
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
    core.String enterpriseId,
    core.String userId,
    core.String entitlementId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/entitlements/' +
        commons.escapeVariable('$entitlementId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves details of an entitlement.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [entitlementId] - The ID of the entitlement (a product ID), e.g.
  /// "app:com.google.android.gm".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Entitlement].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Entitlement> get(
    core.String enterpriseId,
    core.String userId,
    core.String entitlementId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/entitlements/' +
        commons.escapeVariable('$entitlementId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Entitlement.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all entitlements for the specified user.
  ///
  /// Only the ID is set.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EntitlementsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EntitlementsListResponse> list(
    core.String enterpriseId,
    core.String userId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/entitlements';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return EntitlementsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Adds or updates an entitlement to an app for a user.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [entitlementId] - The ID of the entitlement (a product ID), e.g.
  /// "app:com.google.android.gm".
  ///
  /// [install] - Set to true to also install the product on all the user's
  /// devices where possible. Failure to install on one or more devices will not
  /// prevent this operation from returning successfully, as long as the
  /// entitlement was successfully assigned to the user.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Entitlement].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Entitlement> update(
    Entitlement request,
    core.String enterpriseId,
    core.String userId,
    core.String entitlementId, {
    core.bool? install,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (install != null) 'install': ['${install}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/entitlements/' +
        commons.escapeVariable('$entitlementId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Entitlement.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class GrouplicensesResource {
  final commons.ApiRequester _requester;

  GrouplicensesResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves details of an enterprise's group license for a product.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [groupLicenseId] - The ID of the product the group license is for, e.g.
  /// "app:com.google.android.gm".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GroupLicense].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GroupLicense> get(
    core.String enterpriseId,
    core.String groupLicenseId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/groupLicenses/' +
        commons.escapeVariable('$groupLicenseId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GroupLicense.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves IDs of all products for which the enterprise has a group
  /// license.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GroupLicensesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GroupLicensesListResponse> list(
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/groupLicenses';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GroupLicensesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class GrouplicenseusersResource {
  final commons.ApiRequester _requester;

  GrouplicenseusersResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves the IDs of the users who have been granted entitlements under
  /// the license.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [groupLicenseId] - The ID of the product the group license is for, e.g.
  /// "app:com.google.android.gm".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GroupLicenseUsersListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GroupLicenseUsersListResponse> list(
    core.String enterpriseId,
    core.String groupLicenseId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/groupLicenses/' +
        commons.escapeVariable('$groupLicenseId') +
        '/users';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GroupLicenseUsersListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class InstallsResource {
  final commons.ApiRequester _requester;

  InstallsResource(commons.ApiRequester client) : _requester = client;

  /// Requests to remove an app from a device.
  ///
  /// A call to get or list will still show the app as installed on the device
  /// until it is actually removed.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [deviceId] - The Android ID of the device.
  ///
  /// [installId] - The ID of the product represented by the install, e.g.
  /// "app:com.google.android.gm".
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
    core.String enterpriseId,
    core.String userId,
    core.String deviceId,
    core.String installId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/devices/' +
        commons.escapeVariable('$deviceId') +
        '/installs/' +
        commons.escapeVariable('$installId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves details of an installation of an app on a device.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [deviceId] - The Android ID of the device.
  ///
  /// [installId] - The ID of the product represented by the install, e.g.
  /// "app:com.google.android.gm".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Install].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Install> get(
    core.String enterpriseId,
    core.String userId,
    core.String deviceId,
    core.String installId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/devices/' +
        commons.escapeVariable('$deviceId') +
        '/installs/' +
        commons.escapeVariable('$installId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Install.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the details of all apps installed on the specified device.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [deviceId] - The Android ID of the device.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [InstallsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<InstallsListResponse> list(
    core.String enterpriseId,
    core.String userId,
    core.String deviceId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/devices/' +
        commons.escapeVariable('$deviceId') +
        '/installs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return InstallsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Requests to install the latest version of an app to a device.
  ///
  /// If the app is already installed, then it is updated to the latest version
  /// if necessary.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [deviceId] - The Android ID of the device.
  ///
  /// [installId] - The ID of the product represented by the install, e.g.
  /// "app:com.google.android.gm".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Install].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Install> update(
    Install request,
    core.String enterpriseId,
    core.String userId,
    core.String deviceId,
    core.String installId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/devices/' +
        commons.escapeVariable('$deviceId') +
        '/installs/' +
        commons.escapeVariable('$installId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Install.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ManagedconfigurationsfordeviceResource {
  final commons.ApiRequester _requester;

  ManagedconfigurationsfordeviceResource(commons.ApiRequester client)
      : _requester = client;

  /// Removes a per-device managed configuration for an app for the specified
  /// device.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [deviceId] - The Android ID of the device.
  ///
  /// [managedConfigurationForDeviceId] - The ID of the managed configuration (a
  /// product ID), e.g. "app:com.google.android.gm".
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
    core.String enterpriseId,
    core.String userId,
    core.String deviceId,
    core.String managedConfigurationForDeviceId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/devices/' +
        commons.escapeVariable('$deviceId') +
        '/managedConfigurationsForDevice/' +
        commons.escapeVariable('$managedConfigurationForDeviceId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves details of a per-device managed configuration.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [deviceId] - The Android ID of the device.
  ///
  /// [managedConfigurationForDeviceId] - The ID of the managed configuration (a
  /// product ID), e.g. "app:com.google.android.gm".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ManagedConfiguration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ManagedConfiguration> get(
    core.String enterpriseId,
    core.String userId,
    core.String deviceId,
    core.String managedConfigurationForDeviceId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/devices/' +
        commons.escapeVariable('$deviceId') +
        '/managedConfigurationsForDevice/' +
        commons.escapeVariable('$managedConfigurationForDeviceId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ManagedConfiguration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the per-device managed configurations for the specified device.
  ///
  /// Only the ID is set.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [deviceId] - The Android ID of the device.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ManagedConfigurationsForDeviceListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ManagedConfigurationsForDeviceListResponse> list(
    core.String enterpriseId,
    core.String userId,
    core.String deviceId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/devices/' +
        commons.escapeVariable('$deviceId') +
        '/managedConfigurationsForDevice';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ManagedConfigurationsForDeviceListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Adds or updates a per-device managed configuration for an app for the
  /// specified device.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [deviceId] - The Android ID of the device.
  ///
  /// [managedConfigurationForDeviceId] - The ID of the managed configuration (a
  /// product ID), e.g. "app:com.google.android.gm".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ManagedConfiguration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ManagedConfiguration> update(
    ManagedConfiguration request,
    core.String enterpriseId,
    core.String userId,
    core.String deviceId,
    core.String managedConfigurationForDeviceId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/devices/' +
        commons.escapeVariable('$deviceId') +
        '/managedConfigurationsForDevice/' +
        commons.escapeVariable('$managedConfigurationForDeviceId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return ManagedConfiguration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ManagedconfigurationsforuserResource {
  final commons.ApiRequester _requester;

  ManagedconfigurationsforuserResource(commons.ApiRequester client)
      : _requester = client;

  /// Removes a per-user managed configuration for an app for the specified
  /// user.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [managedConfigurationForUserId] - The ID of the managed configuration (a
  /// product ID), e.g. "app:com.google.android.gm".
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
    core.String enterpriseId,
    core.String userId,
    core.String managedConfigurationForUserId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/managedConfigurationsForUser/' +
        commons.escapeVariable('$managedConfigurationForUserId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves details of a per-user managed configuration for an app for the
  /// specified user.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [managedConfigurationForUserId] - The ID of the managed configuration (a
  /// product ID), e.g. "app:com.google.android.gm".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ManagedConfiguration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ManagedConfiguration> get(
    core.String enterpriseId,
    core.String userId,
    core.String managedConfigurationForUserId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/managedConfigurationsForUser/' +
        commons.escapeVariable('$managedConfigurationForUserId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ManagedConfiguration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the per-user managed configurations for the specified user.
  ///
  /// Only the ID is set.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ManagedConfigurationsForUserListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ManagedConfigurationsForUserListResponse> list(
    core.String enterpriseId,
    core.String userId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/managedConfigurationsForUser';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ManagedConfigurationsForUserListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Adds or updates the managed configuration settings for an app for the
  /// specified user.
  ///
  /// If you support the Managed configurations iframe, you can apply managed
  /// configurations to a user by specifying an mcmId and its associated
  /// configuration variables (if any) in the request. Alternatively, all EMMs
  /// can apply managed configurations by passing a list of managed properties.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [managedConfigurationForUserId] - The ID of the managed configuration (a
  /// product ID), e.g. "app:com.google.android.gm".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ManagedConfiguration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ManagedConfiguration> update(
    ManagedConfiguration request,
    core.String enterpriseId,
    core.String userId,
    core.String managedConfigurationForUserId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/managedConfigurationsForUser/' +
        commons.escapeVariable('$managedConfigurationForUserId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return ManagedConfiguration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ManagedconfigurationssettingsResource {
  final commons.ApiRequester _requester;

  ManagedconfigurationssettingsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists all the managed configurations settings for the specified app.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [productId] - The ID of the product for which the managed configurations
  /// settings applies to.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ManagedConfigurationsSettingsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ManagedConfigurationsSettingsListResponse> list(
    core.String enterpriseId,
    core.String productId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/products/' +
        commons.escapeVariable('$productId') +
        '/managedConfigurationsSettings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ManagedConfigurationsSettingsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PermissionsResource {
  final commons.ApiRequester _requester;

  PermissionsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves details of an Android app permission for display to an
  /// enterprise admin.
  ///
  /// Request parameters:
  ///
  /// [permissionId] - The ID of the permission.
  ///
  /// [language] - The BCP47 tag for the user's preferred language (e.g.
  /// "en-US", "de")
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Permission].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Permission> get(
    core.String permissionId, {
    core.String? language,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/permissions/' +
        commons.escapeVariable('$permissionId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Permission.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProductsResource {
  final commons.ApiRequester _requester;

  ProductsResource(commons.ApiRequester client) : _requester = client;

  ///  Approves the specified product and the relevant app permissions, if any.
  ///
  /// The maximum number of products that you can approve per enterprise
  /// customer is 1,000. To learn how to use managed Google Play to design and
  /// create a store layout to display approved products to your users, see
  /// Store Layout Design.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [productId] - The ID of the product.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> approve(
    ProductsApproveRequest request,
    core.String enterpriseId,
    core.String productId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/products/' +
        commons.escapeVariable('$productId') +
        '/approve';

    await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Generates a URL that can be rendered in an iframe to display the
  /// permissions (if any) of a product.
  ///
  /// An enterprise admin must view these permissions and accept them on behalf
  /// of their organization in order to approve that product. Admins should
  /// accept the displayed permissions by interacting with a separate UI element
  /// in the EMM console, which in turn should trigger the use of this URL as
  /// the approvalUrlInfo.approvalUrl property in a Products.approve call to
  /// approve the product. This URL can only be used to display permissions for
  /// up to 1 day.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [productId] - The ID of the product.
  ///
  /// [languageCode] - The BCP 47 language code used for permission names and
  /// descriptions in the returned iframe, for instance "en-US".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ProductsGenerateApprovalUrlResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ProductsGenerateApprovalUrlResponse> generateApprovalUrl(
    core.String enterpriseId,
    core.String productId, {
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/products/' +
        commons.escapeVariable('$productId') +
        '/generateApprovalUrl';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return ProductsGenerateApprovalUrlResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves details of a product for display to an enterprise admin.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [productId] - The ID of the product, e.g. "app:com.google.android.gm".
  ///
  /// [language] - The BCP47 tag for the user's preferred language (e.g.
  /// "en-US", "de").
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
    core.String enterpriseId,
    core.String productId, {
    core.String? language,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/products/' +
        commons.escapeVariable('$productId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Product.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the schema that defines the configurable properties for this
  /// product.
  ///
  /// All products have a schema, but this schema may be empty if no managed
  /// configurations have been defined. This schema can be used to populate a UI
  /// that allows an admin to configure the product. To apply a managed
  /// configuration based on the schema obtained using this API, see Managed
  /// Configurations through Play.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [productId] - The ID of the product.
  ///
  /// [language] - The BCP47 tag for the user's preferred language (e.g.
  /// "en-US", "de").
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AppRestrictionsSchema].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AppRestrictionsSchema> getAppRestrictionsSchema(
    core.String enterpriseId,
    core.String productId, {
    core.String? language,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/products/' +
        commons.escapeVariable('$productId') +
        '/appRestrictionsSchema';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AppRestrictionsSchema.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the Android app permissions required by this app.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [productId] - The ID of the product.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ProductPermissions].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ProductPermissions> getPermissions(
    core.String enterpriseId,
    core.String productId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/products/' +
        commons.escapeVariable('$productId') +
        '/permissions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ProductPermissions.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Finds approved products that match a query, or all approved products if
  /// there is no query.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [approved] - Specifies whether to search among all products (false) or
  /// among only products that have been approved (true). Only "true" is
  /// supported, and should be specified.
  ///
  /// [language] - The BCP47 tag for the user's preferred language (e.g.
  /// "en-US", "de"). Results are returned in the language best matching the
  /// preferred language.
  ///
  /// [maxResults] - Defines how many results the list operation should return.
  /// The default number depends on the resource collection.
  ///
  /// [query] - The search query as typed in the Google Play store search box.
  /// If omitted, all approved apps will be returned (using the pagination
  /// parameters), including apps that are not available in the store (e.g.
  /// unpublished apps).
  ///
  /// [token] - Defines the token of the page to return, usually taken from
  /// TokenPagination. This can only be used if token paging is enabled.
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
    core.String enterpriseId, {
    core.bool? approved,
    core.String? language,
    core.int? maxResults,
    core.String? query,
    core.String? token,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (approved != null) 'approved': ['${approved}'],
      if (language != null) 'language': [language],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (query != null) 'query': [query],
      if (token != null) 'token': [token],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/products';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ProductsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Unapproves the specified product (and the relevant app permissions, if
  /// any)
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [productId] - The ID of the product.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> unapprove(
    core.String enterpriseId,
    core.String productId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/products/' +
        commons.escapeVariable('$productId') +
        '/unapprove';

    await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }
}

class ServiceaccountkeysResource {
  final commons.ApiRequester _requester;

  ServiceaccountkeysResource(commons.ApiRequester client) : _requester = client;

  /// Removes and invalidates the specified credentials for the service account
  /// associated with this enterprise.
  ///
  /// The calling service account must have been retrieved by calling
  /// Enterprises.GetServiceAccount and must have been set as the enterprise
  /// service account by calling Enterprises.SetAccount.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [keyId] - The ID of the key.
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
    core.String enterpriseId,
    core.String keyId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/serviceAccountKeys/' +
        commons.escapeVariable('$keyId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Generates new credentials for the service account associated with this
  /// enterprise.
  ///
  /// The calling service account must have been retrieved by calling
  /// Enterprises.GetServiceAccount and must have been set as the enterprise
  /// service account by calling Enterprises.SetAccount. Only the type of the
  /// key should be populated in the resource to be inserted.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ServiceAccountKey].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ServiceAccountKey> insert(
    ServiceAccountKey request,
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/serviceAccountKeys';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ServiceAccountKey.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all active credentials for the service account associated with this
  /// enterprise.
  ///
  /// Only the ID and key type are returned. The calling service account must
  /// have been retrieved by calling Enterprises.GetServiceAccount and must have
  /// been set as the enterprise service account by calling
  /// Enterprises.SetAccount.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ServiceAccountKeysListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ServiceAccountKeysListResponse> list(
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/serviceAccountKeys';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ServiceAccountKeysListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class StorelayoutclustersResource {
  final commons.ApiRequester _requester;

  StorelayoutclustersResource(commons.ApiRequester client)
      : _requester = client;

  /// Deletes a cluster.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [pageId] - The ID of the page.
  ///
  /// [clusterId] - The ID of the cluster.
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
    core.String enterpriseId,
    core.String pageId,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/storeLayout/pages/' +
        commons.escapeVariable('$pageId') +
        '/clusters/' +
        commons.escapeVariable('$clusterId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves details of a cluster.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [pageId] - The ID of the page.
  ///
  /// [clusterId] - The ID of the cluster.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [StoreCluster].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<StoreCluster> get(
    core.String enterpriseId,
    core.String pageId,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/storeLayout/pages/' +
        commons.escapeVariable('$pageId') +
        '/clusters/' +
        commons.escapeVariable('$clusterId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return StoreCluster.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new cluster in a page.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [pageId] - The ID of the page.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [StoreCluster].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<StoreCluster> insert(
    StoreCluster request,
    core.String enterpriseId,
    core.String pageId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/storeLayout/pages/' +
        commons.escapeVariable('$pageId') +
        '/clusters';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return StoreCluster.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the details of all clusters on the specified page.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [pageId] - The ID of the page.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [StoreLayoutClustersListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<StoreLayoutClustersListResponse> list(
    core.String enterpriseId,
    core.String pageId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/storeLayout/pages/' +
        commons.escapeVariable('$pageId') +
        '/clusters';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return StoreLayoutClustersListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a cluster.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [pageId] - The ID of the page.
  ///
  /// [clusterId] - The ID of the cluster.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [StoreCluster].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<StoreCluster> update(
    StoreCluster request,
    core.String enterpriseId,
    core.String pageId,
    core.String clusterId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/storeLayout/pages/' +
        commons.escapeVariable('$pageId') +
        '/clusters/' +
        commons.escapeVariable('$clusterId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return StoreCluster.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class StorelayoutpagesResource {
  final commons.ApiRequester _requester;

  StorelayoutpagesResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a store page.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [pageId] - The ID of the page.
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
    core.String enterpriseId,
    core.String pageId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/storeLayout/pages/' +
        commons.escapeVariable('$pageId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves details of a store page.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [pageId] - The ID of the page.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [StorePage].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<StorePage> get(
    core.String enterpriseId,
    core.String pageId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/storeLayout/pages/' +
        commons.escapeVariable('$pageId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return StorePage.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a new store page.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [StorePage].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<StorePage> insert(
    StorePage request,
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/storeLayout/pages';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return StorePage.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the details of all pages in the store.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [StoreLayoutPagesListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<StoreLayoutPagesListResponse> list(
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/storeLayout/pages';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return StoreLayoutPagesListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the content of a store page.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [pageId] - The ID of the page.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [StorePage].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<StorePage> update(
    StorePage request,
    core.String enterpriseId,
    core.String pageId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/storeLayout/pages/' +
        commons.escapeVariable('$pageId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return StorePage.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class UsersResource {
  final commons.ApiRequester _requester;

  UsersResource(commons.ApiRequester client) : _requester = client;

  /// Deleted an EMM-managed user.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
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
    core.String enterpriseId,
    core.String userId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Generates an authentication token which the device policy client can use
  /// to provision the given EMM-managed user account on a device.
  ///
  /// The generated token is single-use and expires after a few minutes. You can
  /// provision a maximum of 10 devices per user. This call only works with
  /// EMM-managed accounts.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AuthenticationToken].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AuthenticationToken> generateAuthenticationToken(
    core.String enterpriseId,
    core.String userId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/authenticationToken';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return AuthenticationToken.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a user's details.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [User].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<User> get(
    core.String enterpriseId,
    core.String userId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return User.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the set of products a user is entitled to access.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ProductSet].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ProductSet> getAvailableProductSet(
    core.String enterpriseId,
    core.String userId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/availableProductSet';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ProductSet.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new EMM-managed user.
  ///
  /// The Users resource passed in the body of the request should include an
  /// accountIdentifier and an accountType. If a corresponding user already
  /// exists with the same account identifier, the user will be updated with the
  /// resource. In this case only the displayName field can be changed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [User].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<User> insert(
    User request,
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return User.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Looks up a user by primary email address.
  ///
  /// This is only supported for Google-managed users. Lookup of the id is not
  /// needed for EMM-managed users because the id is already returned in the
  /// result of the Users.insert call.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [email] - Required. The exact primary email address of the user to look
  /// up.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UsersListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UsersListResponse> list(
    core.String enterpriseId,
    core.String email, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'email': [email],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return UsersListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Revokes access to all devices currently provisioned to the user.
  ///
  /// The user will no longer be able to use the managed Play store on any of
  /// their managed devices. This call only works with EMM-managed accounts.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> revokeDeviceAccess(
    core.String enterpriseId,
    core.String userId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/deviceAccess';

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Modifies the set of products that a user is entitled to access (referred
  /// to as *whitelisted* products).
  ///
  /// Only products that are approved or products that were previously approved
  /// (products with revoked approval) can be whitelisted.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ProductSet].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ProductSet> setAvailableProductSet(
    ProductSet request,
    core.String enterpriseId,
    core.String userId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId') +
        '/availableProductSet';

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return ProductSet.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the details of an EMM-managed user.
  ///
  /// Can be used with EMM-managed users only (not Google managed users). Pass
  /// the new details in the Users resource in the request body. Only the
  /// displayName field can be changed. Other fields must either be unset or
  /// have the currently active value.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [userId] - The ID of the user.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [User].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<User> update(
    User request,
    core.String enterpriseId,
    core.String userId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/users/' +
        commons.escapeVariable('$userId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return User.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class WebappsResource {
  final commons.ApiRequester _requester;

  WebappsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes an existing web app.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [webAppId] - The ID of the web app.
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
    core.String enterpriseId,
    core.String webAppId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/webApps/' +
        commons.escapeVariable('$webAppId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets an existing web app.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [webAppId] - The ID of the web app.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [WebApp].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<WebApp> get(
    core.String enterpriseId,
    core.String webAppId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/webApps/' +
        commons.escapeVariable('$webAppId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return WebApp.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new web app for the enterprise.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [WebApp].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<WebApp> insert(
    WebApp request,
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/webApps';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return WebApp.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the details of all web apps for a given enterprise.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [WebAppsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<WebAppsListResponse> list(
    core.String enterpriseId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/webApps';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return WebAppsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing web app.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [enterpriseId] - The ID of the enterprise.
  ///
  /// [webAppId] - The ID of the web app.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [WebApp].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<WebApp> update(
    WebApp request,
    core.String enterpriseId,
    core.String webAppId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'androidenterprise/v1/enterprises/' +
        commons.escapeVariable('$enterpriseId') +
        '/webApps/' +
        commons.escapeVariable('$webAppId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return WebApp.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// This represents an enterprise admin who can manage the enterprise in the
/// managed Google Play store.
class Administrator {
  /// The admin's email address.
  core.String? email;

  Administrator();

  Administrator.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
      };
}

/// A token authorizing an admin to access an iframe.
class AdministratorWebToken {
  /// An opaque token to be passed to the Play front-end to generate an iframe.
  core.String? token;

  AdministratorWebToken();

  AdministratorWebToken.fromJson(core.Map _json) {
    if (_json.containsKey('token')) {
      token = _json['token'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (token != null) 'token': token!,
      };
}

/// Specification for a token used to generate iframes.
///
/// The token specifies what data the admin is allowed to modify and the URI the
/// iframe is allowed to communiate with.
class AdministratorWebTokenSpec {
  /// Options for displaying the Managed Configuration page.
  AdministratorWebTokenSpecManagedConfigurations? managedConfigurations;

  /// The URI of the parent frame hosting the iframe.
  ///
  /// To prevent XSS, the iframe may not be hosted at other URIs. This URI must
  /// be https. Use whitespaces to separate multiple parent URIs.
  core.String? parent;

  /// Use PlaySearch.approveApps.
  ///
  /// Deprecated.
  core.List<core.String>? permission;

  /// Options for displaying the managed Play Search apps page.
  AdministratorWebTokenSpecPlaySearch? playSearch;

  /// Options for displaying the Private Apps page.
  AdministratorWebTokenSpecPrivateApps? privateApps;

  /// Options for displaying the Organize apps page.
  AdministratorWebTokenSpecStoreBuilder? storeBuilder;

  /// Options for displaying the Web Apps page.
  AdministratorWebTokenSpecWebApps? webApps;

  /// Options for displaying the Zero Touch page.
  AdministratorWebTokenSpecZeroTouch? zeroTouch;

  AdministratorWebTokenSpec();

  AdministratorWebTokenSpec.fromJson(core.Map _json) {
    if (_json.containsKey('managedConfigurations')) {
      managedConfigurations =
          AdministratorWebTokenSpecManagedConfigurations.fromJson(
              _json['managedConfigurations']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('permission')) {
      permission = (_json['permission'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('playSearch')) {
      playSearch = AdministratorWebTokenSpecPlaySearch.fromJson(
          _json['playSearch'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('privateApps')) {
      privateApps = AdministratorWebTokenSpecPrivateApps.fromJson(
          _json['privateApps'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('storeBuilder')) {
      storeBuilder = AdministratorWebTokenSpecStoreBuilder.fromJson(
          _json['storeBuilder'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('webApps')) {
      webApps = AdministratorWebTokenSpecWebApps.fromJson(
          _json['webApps'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('zeroTouch')) {
      zeroTouch = AdministratorWebTokenSpecZeroTouch.fromJson(
          _json['zeroTouch'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (managedConfigurations != null)
          'managedConfigurations': managedConfigurations!.toJson(),
        if (parent != null) 'parent': parent!,
        if (permission != null) 'permission': permission!,
        if (playSearch != null) 'playSearch': playSearch!.toJson(),
        if (privateApps != null) 'privateApps': privateApps!.toJson(),
        if (storeBuilder != null) 'storeBuilder': storeBuilder!.toJson(),
        if (webApps != null) 'webApps': webApps!.toJson(),
        if (zeroTouch != null) 'zeroTouch': zeroTouch!.toJson(),
      };
}

class AdministratorWebTokenSpecManagedConfigurations {
  /// Whether the Managed Configuration page is displayed.
  ///
  /// Default is true.
  core.bool? enabled;

  AdministratorWebTokenSpecManagedConfigurations();

  AdministratorWebTokenSpecManagedConfigurations.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

class AdministratorWebTokenSpecPlaySearch {
  /// Allow access to the iframe in approve mode.
  ///
  /// Default is false.
  core.bool? approveApps;

  /// Whether the managed Play Search apps page is displayed.
  ///
  /// Default is true.
  core.bool? enabled;

  AdministratorWebTokenSpecPlaySearch();

  AdministratorWebTokenSpecPlaySearch.fromJson(core.Map _json) {
    if (_json.containsKey('approveApps')) {
      approveApps = _json['approveApps'] as core.bool;
    }
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (approveApps != null) 'approveApps': approveApps!,
        if (enabled != null) 'enabled': enabled!,
      };
}

class AdministratorWebTokenSpecPrivateApps {
  /// Whether the Private Apps page is displayed.
  ///
  /// Default is true.
  core.bool? enabled;

  AdministratorWebTokenSpecPrivateApps();

  AdministratorWebTokenSpecPrivateApps.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

class AdministratorWebTokenSpecStoreBuilder {
  /// Whether the Organize apps page is displayed.
  ///
  /// Default is true.
  core.bool? enabled;

  AdministratorWebTokenSpecStoreBuilder();

  AdministratorWebTokenSpecStoreBuilder.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

class AdministratorWebTokenSpecWebApps {
  /// Whether the Web Apps page is displayed.
  ///
  /// Default is true.
  core.bool? enabled;

  AdministratorWebTokenSpecWebApps();

  AdministratorWebTokenSpecWebApps.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

class AdministratorWebTokenSpecZeroTouch {
  /// Whether zero-touch embedded UI is usable with this token.
  ///
  /// If enabled, the admin can link zero-touch customers to this enterprise.
  core.bool? enabled;

  AdministratorWebTokenSpecZeroTouch();

  AdministratorWebTokenSpecZeroTouch.fromJson(core.Map _json) {
    if (_json.containsKey('enabled')) {
      enabled = _json['enabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabled != null) 'enabled': enabled!,
      };
}

/// Represents the list of app restrictions available to be pre-configured for
/// the product.
class AppRestrictionsSchema {
  /// Deprecated.
  core.String? kind;

  /// The set of restrictions that make up this schema.
  core.List<AppRestrictionsSchemaRestriction>? restrictions;

  AppRestrictionsSchema();

  AppRestrictionsSchema.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('restrictions')) {
      restrictions = (_json['restrictions'] as core.List)
          .map<AppRestrictionsSchemaRestriction>((value) =>
              AppRestrictionsSchemaRestriction.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (restrictions != null)
          'restrictions': restrictions!.map((value) => value.toJson()).toList(),
      };
}

/// An event generated when a new app version is uploaded to Google Play and its
/// app restrictions schema changed.
///
/// To fetch the app restrictions schema for an app, use
/// Products.getAppRestrictionsSchema on the EMM API.
class AppRestrictionsSchemaChangeEvent {
  /// The id of the product (e.g. "app:com.google.android.gm") for which the app
  /// restriction schema changed.
  ///
  /// This field will always be present.
  core.String? productId;

  AppRestrictionsSchemaChangeEvent();

  AppRestrictionsSchemaChangeEvent.fromJson(core.Map _json) {
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (productId != null) 'productId': productId!,
      };
}

/// A restriction in the App Restriction Schema represents a piece of
/// configuration that may be pre-applied.
class AppRestrictionsSchemaRestriction {
  /// The default value of the restriction.
  ///
  /// bundle and bundleArray restrictions never have a default value.
  AppRestrictionsSchemaRestrictionRestrictionValue? defaultValue;

  /// A longer description of the restriction, giving more detail of what it
  /// affects.
  core.String? description;

  /// For choice or multiselect restrictions, the list of possible entries'
  /// human-readable names.
  core.List<core.String>? entry;

  /// For choice or multiselect restrictions, the list of possible entries'
  /// machine-readable values.
  ///
  /// These values should be used in the configuration, either as a single
  /// string value for a choice restriction or in a stringArray for a
  /// multiselect restriction.
  core.List<core.String>? entryValue;

  /// The unique key that the product uses to identify the restriction, e.g.
  /// "com.google.android.gm.fieldname".
  core.String? key;

  /// For bundle or bundleArray restrictions, the list of nested restrictions.
  ///
  /// A bundle restriction is always nested within a bundleArray restriction,
  /// and a bundleArray restriction is at most two levels deep.
  core.List<AppRestrictionsSchemaRestriction>? nestedRestriction;

  /// The type of the restriction.
  /// Possible string values are:
  /// - "bool" : A restriction of boolean type.
  /// - "string" : A restriction of string type.
  /// - "integer" : A restriction of integer type.
  /// - "choice" : A choice of one item from a set.
  /// - "multiselect" : A choice of multiple items from a set.
  /// - "hidden" : A hidden restriction of string type (the default value can be
  /// used to pass along information that cannot be modified, such as a version
  /// code).
  /// - "bundle" : \[M+ devices only\] A bundle of restrictions
  /// - "bundleArray" : \[M+ devices only\] An array of restriction bundles
  core.String? restrictionType;

  /// The name of the restriction.
  core.String? title;

  AppRestrictionsSchemaRestriction();

  AppRestrictionsSchemaRestriction.fromJson(core.Map _json) {
    if (_json.containsKey('defaultValue')) {
      defaultValue = AppRestrictionsSchemaRestrictionRestrictionValue.fromJson(
          _json['defaultValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('entry')) {
      entry = (_json['entry'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('entryValue')) {
      entryValue = (_json['entryValue'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('nestedRestriction')) {
      nestedRestriction = (_json['nestedRestriction'] as core.List)
          .map<AppRestrictionsSchemaRestriction>((value) =>
              AppRestrictionsSchemaRestriction.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('restrictionType')) {
      restrictionType = _json['restrictionType'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (defaultValue != null) 'defaultValue': defaultValue!.toJson(),
        if (description != null) 'description': description!,
        if (entry != null) 'entry': entry!,
        if (entryValue != null) 'entryValue': entryValue!,
        if (key != null) 'key': key!,
        if (nestedRestriction != null)
          'nestedRestriction':
              nestedRestriction!.map((value) => value.toJson()).toList(),
        if (restrictionType != null) 'restrictionType': restrictionType!,
        if (title != null) 'title': title!,
      };
}

/// A typed value for the restriction.
class AppRestrictionsSchemaRestrictionRestrictionValue {
  /// The type of the value being provided.
  /// Possible string values are:
  /// - "bool" : A restriction of boolean type.
  /// - "string" : A restriction of string type.
  /// - "integer" : A restriction of integer type.
  /// - "choice" : A choice of one item from a set.
  /// - "multiselect" : A choice of multiple items from a set.
  /// - "hidden" : A hidden restriction of string type (the default value can be
  /// used to pass along information that cannot be modified, such as a version
  /// code).
  /// - "bundle" : \[M+ devices only\] A bundle of restrictions
  /// - "bundleArray" : \[M+ devices only\] An array of restriction bundles
  core.String? type;

  /// The boolean value - this will only be present if type is bool.
  core.bool? valueBool;

  /// The integer value - this will only be present if type is integer.
  core.int? valueInteger;

  /// The list of string values - this will only be present if type is
  /// multiselect.
  core.List<core.String>? valueMultiselect;

  /// The string value - this will be present for types string, choice and
  /// hidden.
  core.String? valueString;

  AppRestrictionsSchemaRestrictionRestrictionValue();

  AppRestrictionsSchemaRestrictionRestrictionValue.fromJson(core.Map _json) {
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('valueBool')) {
      valueBool = _json['valueBool'] as core.bool;
    }
    if (_json.containsKey('valueInteger')) {
      valueInteger = _json['valueInteger'] as core.int;
    }
    if (_json.containsKey('valueMultiselect')) {
      valueMultiselect = (_json['valueMultiselect'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('valueString')) {
      valueString = _json['valueString'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (type != null) 'type': type!,
        if (valueBool != null) 'valueBool': valueBool!,
        if (valueInteger != null) 'valueInteger': valueInteger!,
        if (valueMultiselect != null) 'valueMultiselect': valueMultiselect!,
        if (valueString != null) 'valueString': valueString!,
      };
}

/// List of states set by the app.
class AppState {
  /// List of keyed app states.
  ///
  /// This field will always be present.
  core.List<KeyedAppState>? keyedAppState;

  /// The package name of the app.
  ///
  /// This field will always be present.
  core.String? packageName;

  AppState();

  AppState.fromJson(core.Map _json) {
    if (_json.containsKey('keyedAppState')) {
      keyedAppState = (_json['keyedAppState'] as core.List)
          .map<KeyedAppState>((value) => KeyedAppState.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (keyedAppState != null)
          'keyedAppState':
              keyedAppState!.map((value) => value.toJson()).toList(),
        if (packageName != null) 'packageName': packageName!,
      };
}

/// An event generated when a new version of an app is uploaded to Google Play.
///
/// Notifications are sent for new public versions only: alpha, beta, or canary
/// versions do not generate this event. To fetch up-to-date version history for
/// an app, use Products.Get on the EMM API.
class AppUpdateEvent {
  /// The id of the product (e.g. "app:com.google.android.gm") that was updated.
  ///
  /// This field will always be present.
  core.String? productId;

  AppUpdateEvent();

  AppUpdateEvent.fromJson(core.Map _json) {
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (productId != null) 'productId': productId!,
      };
}

/// This represents a single version of the app.
class AppVersion {
  /// True if this version is a production APK.
  core.bool? isProduction;

  /// Deprecated, use trackId instead.
  /// Possible string values are:
  /// - "appTrackUnspecified"
  /// - "production"
  /// - "beta"
  /// - "alpha"
  core.String? track;

  /// Track ids that the app version is published in.
  ///
  /// Replaces the track field (deprecated), but doesn't include the production
  /// track (see isProduction instead).
  core.List<core.String>? trackId;

  /// Unique increasing identifier for the app version.
  core.int? versionCode;

  /// The string used in the Play store by the app developer to identify the
  /// version.
  ///
  /// The string is not necessarily unique or localized (for example, the string
  /// could be "1.4").
  core.String? versionString;

  AppVersion();

  AppVersion.fromJson(core.Map _json) {
    if (_json.containsKey('isProduction')) {
      isProduction = _json['isProduction'] as core.bool;
    }
    if (_json.containsKey('track')) {
      track = _json['track'] as core.String;
    }
    if (_json.containsKey('trackId')) {
      trackId = (_json['trackId'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('versionCode')) {
      versionCode = _json['versionCode'] as core.int;
    }
    if (_json.containsKey('versionString')) {
      versionString = _json['versionString'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (isProduction != null) 'isProduction': isProduction!,
        if (track != null) 'track': track!,
        if (trackId != null) 'trackId': trackId!,
        if (versionCode != null) 'versionCode': versionCode!,
        if (versionString != null) 'versionString': versionString!,
      };
}

/// Information on an approval URL.
class ApprovalUrlInfo {
  /// A URL that displays a product's permissions and that can also be used to
  /// approve the product with the Products.approve call.
  core.String? approvalUrl;

  ApprovalUrlInfo();

  ApprovalUrlInfo.fromJson(core.Map _json) {
    if (_json.containsKey('approvalUrl')) {
      approvalUrl = _json['approvalUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (approvalUrl != null) 'approvalUrl': approvalUrl!,
      };
}

/// An AuthenticationToken is used by the EMM's device policy client on a device
/// to provision the given EMM-managed user on that device.
class AuthenticationToken {
  /// The authentication token to be passed to the device policy client on the
  /// device where it can be used to provision the account for which this token
  /// was generated.
  core.String? token;

  AuthenticationToken();

  AuthenticationToken.fromJson(core.Map _json) {
    if (_json.containsKey('token')) {
      token = _json['token'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (token != null) 'token': token!,
      };
}

/// The auto-install constraint.
///
/// Defines a set of restrictions for installation. At least one of the fields
/// must be set.
class AutoInstallConstraint {
  /// Charging state constraint.
  /// Possible string values are:
  /// - "chargingStateConstraintUnspecified"
  /// - "chargingNotRequired" : Device doesn't have to be charging.
  /// - "chargingRequired" : Device has to be charging.
  core.String? chargingStateConstraint;

  /// Device idle state constraint.
  /// Possible string values are:
  /// - "deviceIdleStateConstraintUnspecified"
  /// - "deviceIdleNotRequired" : Device doesn't have to be idle, app can be
  /// installed while the user is interacting with the device.
  /// - "deviceIdleRequired" : Device has to be idle.
  core.String? deviceIdleStateConstraint;

  /// Network type constraint.
  /// Possible string values are:
  /// - "networkTypeConstraintUnspecified"
  /// - "anyNetwork" : Any active networks (Wi-Fi, cellular, etc.).
  /// - "unmeteredNetwork" : Any unmetered network (e.g. Wi-FI).
  core.String? networkTypeConstraint;

  AutoInstallConstraint();

  AutoInstallConstraint.fromJson(core.Map _json) {
    if (_json.containsKey('chargingStateConstraint')) {
      chargingStateConstraint = _json['chargingStateConstraint'] as core.String;
    }
    if (_json.containsKey('deviceIdleStateConstraint')) {
      deviceIdleStateConstraint =
          _json['deviceIdleStateConstraint'] as core.String;
    }
    if (_json.containsKey('networkTypeConstraint')) {
      networkTypeConstraint = _json['networkTypeConstraint'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (chargingStateConstraint != null)
          'chargingStateConstraint': chargingStateConstraint!,
        if (deviceIdleStateConstraint != null)
          'deviceIdleStateConstraint': deviceIdleStateConstraint!,
        if (networkTypeConstraint != null)
          'networkTypeConstraint': networkTypeConstraint!,
      };
}

class AutoInstallPolicy {
  /// The constraints for auto-installing the app.
  ///
  /// You can specify a maximum of one constraint.
  core.List<AutoInstallConstraint>? autoInstallConstraint;

  /// The auto-install mode.
  ///
  /// If unset defaults to "doNotAutoInstall".
  /// Possible string values are:
  /// - "autoInstallModeUnspecified"
  /// - "doNotAutoInstall" : The product is not installed automatically, the
  /// user needs to install it from the Play Store.
  /// - "autoInstallOnce" : The product is automatically installed once, if the
  /// user uninstalls the product it will not be installed again.
  /// - "forceAutoInstall" : The product is automatically installed, if the user
  /// uninstalls the product it will be installed again. On managed devices the
  /// DPC should block uninstall.
  core.String? autoInstallMode;

  /// The priority of the install, as an unsigned integer.
  ///
  /// A lower number means higher priority.
  core.int? autoInstallPriority;

  /// The minimum version of the app.
  ///
  /// If a lower version of the app is installed, then the app will be
  /// auto-updated according to the auto-install constraints, instead of waiting
  /// for the regular auto-update. You can set a minimum version code for at
  /// most 20 apps per device.
  core.int? minimumVersionCode;

  AutoInstallPolicy();

  AutoInstallPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('autoInstallConstraint')) {
      autoInstallConstraint = (_json['autoInstallConstraint'] as core.List)
          .map<AutoInstallConstraint>((value) => AutoInstallConstraint.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('autoInstallMode')) {
      autoInstallMode = _json['autoInstallMode'] as core.String;
    }
    if (_json.containsKey('autoInstallPriority')) {
      autoInstallPriority = _json['autoInstallPriority'] as core.int;
    }
    if (_json.containsKey('minimumVersionCode')) {
      minimumVersionCode = _json['minimumVersionCode'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoInstallConstraint != null)
          'autoInstallConstraint':
              autoInstallConstraint!.map((value) => value.toJson()).toList(),
        if (autoInstallMode != null) 'autoInstallMode': autoInstallMode!,
        if (autoInstallPriority != null)
          'autoInstallPriority': autoInstallPriority!,
        if (minimumVersionCode != null)
          'minimumVersionCode': minimumVersionCode!,
      };
}

/// A configuration variables resource contains the managed configuration
/// settings ID to be applied to a single user, as well as the variable set that
/// is attributed to the user.
///
/// The variable set will be used to replace placeholders in the managed
/// configuration settings.
class ConfigurationVariables {
  /// The ID of the managed configurations settings.
  core.String? mcmId;

  /// The variable set that is attributed to the user.
  core.List<VariableSet>? variableSet;

  ConfigurationVariables();

  ConfigurationVariables.fromJson(core.Map _json) {
    if (_json.containsKey('mcmId')) {
      mcmId = _json['mcmId'] as core.String;
    }
    if (_json.containsKey('variableSet')) {
      variableSet = (_json['variableSet'] as core.List)
          .map<VariableSet>((value) => VariableSet.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mcmId != null) 'mcmId': mcmId!,
        if (variableSet != null)
          'variableSet': variableSet!.map((value) => value.toJson()).toList(),
      };
}

/// A Devices resource represents a mobile device managed by the EMM and
/// belonging to a specific enterprise user.
class Device {
  /// The Google Play Services Android ID for the device encoded as a lowercase
  /// hex string.
  ///
  /// For example, "123456789abcdef0".
  core.String? androidId;

  /// Identifies the extent to which the device is controlled by a managed
  /// Google Play EMM in various deployment configurations.
  ///
  /// Possible values include: - "managedDevice", a device that has the EMM's
  /// device policy controller (DPC) as the device owner. - "managedProfile", a
  /// device that has a profile managed by the DPC (DPC is profile owner) in
  /// addition to a separate, personal profile that is unavailable to the DPC. -
  /// "containerApp", no longer used (deprecated). - "unmanagedProfile", a
  /// device that has been allowed (by the domain's admin, using the Admin
  /// Console to enable the privilege) to use managed Google Play, but the
  /// profile is itself not owned by a DPC.
  /// Possible string values are:
  /// - "managedDevice"
  /// - "managedProfile"
  /// - "containerApp"
  /// - "unmanagedProfile"
  core.String? managementType;

  /// The policy enforced on the device.
  Policy? policy;

  /// The device report updated with the latest app states.
  DeviceReport? report;

  Device();

  Device.fromJson(core.Map _json) {
    if (_json.containsKey('androidId')) {
      androidId = _json['androidId'] as core.String;
    }
    if (_json.containsKey('managementType')) {
      managementType = _json['managementType'] as core.String;
    }
    if (_json.containsKey('policy')) {
      policy = Policy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('report')) {
      report = DeviceReport.fromJson(
          _json['report'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (androidId != null) 'androidId': androidId!,
        if (managementType != null) 'managementType': managementType!,
        if (policy != null) 'policy': policy!.toJson(),
        if (report != null) 'report': report!.toJson(),
      };
}

/// Device report updated with the latest app states for managed apps on the
/// device.
class DeviceReport {
  /// List of app states set by managed apps on the device.
  ///
  /// App states are defined by the app's developers. This field will always be
  /// present.
  core.List<AppState>? appState;

  /// The timestamp of the last report update in milliseconds since epoch.
  ///
  /// This field will always be present.
  core.String? lastUpdatedTimestampMillis;

  DeviceReport();

  DeviceReport.fromJson(core.Map _json) {
    if (_json.containsKey('appState')) {
      appState = (_json['appState'] as core.List)
          .map<AppState>((value) =>
              AppState.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('lastUpdatedTimestampMillis')) {
      lastUpdatedTimestampMillis =
          _json['lastUpdatedTimestampMillis'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appState != null)
          'appState': appState!.map((value) => value.toJson()).toList(),
        if (lastUpdatedTimestampMillis != null)
          'lastUpdatedTimestampMillis': lastUpdatedTimestampMillis!,
      };
}

/// An event generated when an updated device report is available.
class DeviceReportUpdateEvent {
  /// The Android ID of the device.
  ///
  /// This field will always be present.
  core.String? deviceId;

  /// The device report updated with the latest app states.
  ///
  /// This field will always be present.
  DeviceReport? report;

  /// The ID of the user.
  ///
  /// This field will always be present.
  core.String? userId;

  DeviceReportUpdateEvent();

  DeviceReportUpdateEvent.fromJson(core.Map _json) {
    if (_json.containsKey('deviceId')) {
      deviceId = _json['deviceId'] as core.String;
    }
    if (_json.containsKey('report')) {
      report = DeviceReport.fromJson(
          _json['report'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('userId')) {
      userId = _json['userId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceId != null) 'deviceId': deviceId!,
        if (report != null) 'report': report!.toJson(),
        if (userId != null) 'userId': userId!,
      };
}

/// The state of a user's device, as accessed by the getState and setState
/// methods on device resources.
class DeviceState {
  /// The state of the Google account on the device.
  ///
  /// "enabled" indicates that the Google account on the device can be used to
  /// access Google services (including Google Play), while "disabled" means
  /// that it cannot. A new device is initially in the "disabled" state.
  /// Possible string values are:
  /// - "enabled"
  /// - "disabled"
  core.String? accountState;

  DeviceState();

  DeviceState.fromJson(core.Map _json) {
    if (_json.containsKey('accountState')) {
      accountState = _json['accountState'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountState != null) 'accountState': accountState!,
      };
}

class DevicesListResponse {
  /// A managed device.
  core.List<Device>? device;

  DevicesListResponse();

  DevicesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('device')) {
      device = (_json['device'] as core.List)
          .map<Device>((value) =>
              Device.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (device != null)
          'device': device!.map((value) => value.toJson()).toList(),
      };
}

/// An Enterprises resource represents the binding between an EMM and a specific
/// organization.
///
/// That binding can be instantiated in one of two different ways using this API
/// as follows: - For Google managed domain customers, the process involves
/// using Enterprises.enroll and Enterprises.setAccount (in conjunction with
/// artifacts obtained from the Admin console and the Google API Console) and
/// submitted to the EMM through a more-or-less manual process. - For managed
/// Google Play Accounts customers, the process involves using
/// Enterprises.generateSignupUrl and Enterprises.completeSignup in conjunction
/// with the managed Google Play sign-up UI (Google-provided mechanism) to
/// create the binding without manual steps. As an EMM, you can support either
/// or both approaches in your EMM console. See Create an Enterprise for
/// details.
class Enterprise {
  /// Admins of the enterprise.
  ///
  /// This is only supported for enterprises created via the EMM-initiated flow.
  core.List<Administrator>? administrator;

  /// The unique ID for the enterprise.
  core.String? id;

  /// The name of the enterprise, for example, "Example, Inc".
  core.String? name;

  /// The enterprise's primary domain, such as "example.com".
  core.String? primaryDomain;

  Enterprise();

  Enterprise.fromJson(core.Map _json) {
    if (_json.containsKey('administrator')) {
      administrator = (_json['administrator'] as core.List)
          .map<Administrator>((value) => Administrator.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('primaryDomain')) {
      primaryDomain = _json['primaryDomain'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (administrator != null)
          'administrator':
              administrator!.map((value) => value.toJson()).toList(),
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
        if (primaryDomain != null) 'primaryDomain': primaryDomain!,
      };
}

/// A service account that can be used to authenticate as the enterprise to API
/// calls that require such authentication.
class EnterpriseAccount {
  /// The email address of the service account.
  core.String? accountEmail;

  EnterpriseAccount();

  EnterpriseAccount.fromJson(core.Map _json) {
    if (_json.containsKey('accountEmail')) {
      accountEmail = _json['accountEmail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountEmail != null) 'accountEmail': accountEmail!,
      };
}

class EnterprisesListResponse {
  /// An enterprise.
  core.List<Enterprise>? enterprise;

  EnterprisesListResponse();

  EnterprisesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('enterprise')) {
      enterprise = (_json['enterprise'] as core.List)
          .map<Enterprise>((value) =>
              Enterprise.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enterprise != null)
          'enterprise': enterprise!.map((value) => value.toJson()).toList(),
      };
}

class EnterprisesSendTestPushNotificationResponse {
  /// The message ID of the test push notification that was sent.
  core.String? messageId;

  /// The name of the Cloud Pub/Sub topic to which notifications for this
  /// enterprise's enrolled account will be sent.
  core.String? topicName;

  EnterprisesSendTestPushNotificationResponse();

  EnterprisesSendTestPushNotificationResponse.fromJson(core.Map _json) {
    if (_json.containsKey('messageId')) {
      messageId = _json['messageId'] as core.String;
    }
    if (_json.containsKey('topicName')) {
      topicName = _json['topicName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (messageId != null) 'messageId': messageId!,
        if (topicName != null) 'topicName': topicName!,
      };
}

/// The presence of an Entitlements resource indicates that a user has the right
/// to use a particular app.
///
/// Entitlements are user specific, not device specific. This allows a user with
/// an entitlement to an app to install the app on all their devices. It's also
/// possible for a user to hold an entitlement to an app without installing the
/// app on any device. The API can be used to create an entitlement. As an
/// option, you can also use the API to trigger the installation of an app on
/// all a user's managed devices at the same time the entitlement is created. If
/// the app is free, creating the entitlement also creates a group license for
/// that app. For paid apps, creating the entitlement consumes one license, and
/// that license remains consumed until the entitlement is removed. If the
/// enterprise hasn't purchased enough licenses, then no entitlement is created
/// and the installation fails. An entitlement is also not created for an app if
/// the app requires permissions that the enterprise hasn't accepted. If an
/// entitlement is deleted, the app may be uninstalled from a user's device. As
/// a best practice, uninstall the app by calling Installs.delete() before
/// deleting the entitlement. Entitlements for apps that a user pays for on an
/// unmanaged profile have "userPurchase" as the entitlement reason. These
/// entitlements cannot be removed via the API.
class Entitlement {
  /// The ID of the product that the entitlement is for.
  ///
  /// For example, "app:com.google.android.gm".
  core.String? productId;

  /// The reason for the entitlement.
  ///
  /// For example, "free" for free apps. This property is temporary: it will be
  /// replaced by the acquisition kind field of group licenses.
  /// Possible string values are:
  /// - "free"
  /// - "groupLicense"
  /// - "userPurchase"
  core.String? reason;

  Entitlement();

  Entitlement.fromJson(core.Map _json) {
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (productId != null) 'productId': productId!,
        if (reason != null) 'reason': reason!,
      };
}

class EntitlementsListResponse {
  /// An entitlement of a user to a product (e.g. an app).
  ///
  /// For example, a free app that they have installed, or a paid app that they
  /// have been allocated a license to.
  core.List<Entitlement>? entitlement;

  EntitlementsListResponse();

  EntitlementsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entitlement')) {
      entitlement = (_json['entitlement'] as core.List)
          .map<Entitlement>((value) => Entitlement.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entitlement != null)
          'entitlement': entitlement!.map((value) => value.toJson()).toList(),
      };
}

/// Group license objects allow you to keep track of licenses (called
/// entitlements) for both free and paid apps.
///
/// For a free app, a group license is created when an enterprise admin first
/// approves the product in Google Play or when the first entitlement for the
/// product is created for a user via the API. For a paid app, a group license
/// object is only created when an enterprise admin purchases the product in
/// Google Play for the first time. Use the API to query group licenses. A
/// Grouplicenses resource includes the total number of licenses purchased (paid
/// apps only) and the total number of licenses currently in use. In other
/// words, the total number of Entitlements that exist for the product. Only one
/// group license object is created per product and group license objects are
/// never deleted. If a product is unapproved, its group license remains. This
/// allows enterprise admins to keep track of any remaining entitlements for the
/// product.
class GroupLicense {
  /// How this group license was acquired.
  ///
  /// "bulkPurchase" means that this Grouplicenses resource was created because
  /// the enterprise purchased licenses for this product; otherwise, the value
  /// is "free" (for free products).
  /// Possible string values are:
  /// - "free"
  /// - "bulkPurchase"
  core.String? acquisitionKind;

  /// Whether the product to which this group license relates is currently
  /// approved by the enterprise.
  ///
  /// Products are approved when a group license is first created, but this
  /// approval may be revoked by an enterprise admin via Google Play. Unapproved
  /// products will not be visible to end users in collections, and new
  /// entitlements to them should not normally be created.
  /// Possible string values are:
  /// - "approved"
  /// - "unapproved"
  core.String? approval;

  /// The total number of provisioned licenses for this product.
  ///
  /// Returned by read operations, but ignored in write operations.
  core.int? numProvisioned;

  /// The number of purchased licenses (possibly in multiple purchases).
  ///
  /// If this field is omitted, then there is no limit on the number of licenses
  /// that can be provisioned (for example, if the acquisition kind is "free").
  core.int? numPurchased;

  /// The permission approval status of the product.
  ///
  /// This field is only set if the product is approved. Possible states are: -
  /// "currentApproved", the current set of permissions is approved, but
  /// additional permissions will require the administrator to reapprove the
  /// product (If the product was approved without specifying the approved
  /// permissions setting, then this is the default behavior.), -
  /// "needsReapproval", the product has unapproved permissions. No additional
  /// product licenses can be assigned until the product is reapproved, -
  /// "allCurrentAndFutureApproved", the current permissions are approved and
  /// any future permission updates will be automatically approved without
  /// administrator review.
  /// Possible string values are:
  /// - "currentApproved"
  /// - "needsReapproval"
  /// - "allCurrentAndFutureApproved"
  core.String? permissions;

  /// The ID of the product that the license is for.
  ///
  /// For example, "app:com.google.android.gm".
  core.String? productId;

  GroupLicense();

  GroupLicense.fromJson(core.Map _json) {
    if (_json.containsKey('acquisitionKind')) {
      acquisitionKind = _json['acquisitionKind'] as core.String;
    }
    if (_json.containsKey('approval')) {
      approval = _json['approval'] as core.String;
    }
    if (_json.containsKey('numProvisioned')) {
      numProvisioned = _json['numProvisioned'] as core.int;
    }
    if (_json.containsKey('numPurchased')) {
      numPurchased = _json['numPurchased'] as core.int;
    }
    if (_json.containsKey('permissions')) {
      permissions = _json['permissions'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (acquisitionKind != null) 'acquisitionKind': acquisitionKind!,
        if (approval != null) 'approval': approval!,
        if (numProvisioned != null) 'numProvisioned': numProvisioned!,
        if (numPurchased != null) 'numPurchased': numPurchased!,
        if (permissions != null) 'permissions': permissions!,
        if (productId != null) 'productId': productId!,
      };
}

class GroupLicenseUsersListResponse {
  /// A user of an enterprise.
  core.List<User>? user;

  GroupLicenseUsersListResponse();

  GroupLicenseUsersListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('user')) {
      user = (_json['user'] as core.List)
          .map<User>((value) =>
              User.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (user != null) 'user': user!.map((value) => value.toJson()).toList(),
      };
}

class GroupLicensesListResponse {
  /// A group license for a product approved for use in the enterprise.
  core.List<GroupLicense>? groupLicense;

  GroupLicensesListResponse();

  GroupLicensesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('groupLicense')) {
      groupLicense = (_json['groupLicense'] as core.List)
          .map<GroupLicense>((value) => GroupLicense.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (groupLicense != null)
          'groupLicense': groupLicense!.map((value) => value.toJson()).toList(),
      };
}

/// The existence of an Installs resource indicates that an app is installed on
/// a particular device (or that an install is pending).
///
/// The API can be used to create an install resource using the update method.
/// This triggers the actual install of the app on the device. If the user does
/// not already have an entitlement for the app, then an attempt is made to
/// create one. If this fails (for example, because the app is not free and
/// there is no available license), then the creation of the install fails. The
/// API can also be used to update an installed app. If the update method is
/// used on an existing install, then the app will be updated to the latest
/// available version. Note that it is not possible to force the installation of
/// a specific version of an app: the version code is read-only. If a user
/// installs an app themselves (as permitted by the enterprise), then again an
/// install resource and possibly an entitlement resource are automatically
/// created. The API can also be used to delete an install resource, which
/// triggers the removal of the app from the device. Note that deleting an
/// install does not automatically remove the corresponding entitlement, even if
/// there are no remaining installs. The install resource will also be deleted
/// if the user uninstalls the app themselves.
class Install {
  /// Install state.
  ///
  /// The state "installPending" means that an install request has recently been
  /// made and download to the device is in progress. The state "installed"
  /// means that the app has been installed. This field is read-only.
  /// Possible string values are:
  /// - "installed"
  /// - "installPending"
  core.String? installState;

  /// The ID of the product that the install is for.
  ///
  /// For example, "app:com.google.android.gm".
  core.String? productId;

  /// The version of the installed product.
  ///
  /// Guaranteed to be set only if the install state is "installed".
  core.int? versionCode;

  Install();

  Install.fromJson(core.Map _json) {
    if (_json.containsKey('installState')) {
      installState = _json['installState'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('versionCode')) {
      versionCode = _json['versionCode'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (installState != null) 'installState': installState!,
        if (productId != null) 'productId': productId!,
        if (versionCode != null) 'versionCode': versionCode!,
      };
}

/// An event generated when an app installation failed on a device
class InstallFailureEvent {
  /// The Android ID of the device.
  ///
  /// This field will always be present.
  core.String? deviceId;

  /// Additional details on the failure if applicable.
  core.String? failureDetails;

  /// The reason for the installation failure.
  ///
  /// This field will always be present.
  /// Possible string values are:
  /// - "unknown" : Used whenever no better reason for failure can be provided.
  /// - "timeout" : Used when the installation timed out. This can cover a
  /// number of situations, for example when the device did not have
  /// connectivity at any point during the retry period, or if the device is
  /// OOM.
  core.String? failureReason;

  /// The id of the product (e.g. "app:com.google.android.gm") for which the
  /// install failure event occured.
  ///
  /// This field will always be present.
  core.String? productId;

  /// The ID of the user.
  ///
  /// This field will always be present.
  core.String? userId;

  InstallFailureEvent();

  InstallFailureEvent.fromJson(core.Map _json) {
    if (_json.containsKey('deviceId')) {
      deviceId = _json['deviceId'] as core.String;
    }
    if (_json.containsKey('failureDetails')) {
      failureDetails = _json['failureDetails'] as core.String;
    }
    if (_json.containsKey('failureReason')) {
      failureReason = _json['failureReason'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('userId')) {
      userId = _json['userId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceId != null) 'deviceId': deviceId!,
        if (failureDetails != null) 'failureDetails': failureDetails!,
        if (failureReason != null) 'failureReason': failureReason!,
        if (productId != null) 'productId': productId!,
        if (userId != null) 'userId': userId!,
      };
}

class InstallsListResponse {
  /// An installation of an app for a user on a specific device.
  ///
  /// The existence of an install implies that the user must have an entitlement
  /// to the app.
  core.List<Install>? install;

  InstallsListResponse();

  InstallsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('install')) {
      install = (_json['install'] as core.List)
          .map<Install>((value) =>
              Install.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (install != null)
          'install': install!.map((value) => value.toJson()).toList(),
      };
}

/// Represents a keyed app state containing a key, timestamp, severity level,
/// optional description, and optional data.
class KeyedAppState {
  /// Additional field intended for machine-readable data.
  ///
  /// For example, a number or JSON object. To prevent XSS, we recommend
  /// removing any HTML from the data before displaying it.
  core.String? data;

  /// Key indicating what the app is providing a state for.
  ///
  /// The content of the key is set by the app's developer. To prevent XSS, we
  /// recommend removing any HTML from the key before displaying it. This field
  /// will always be present.
  core.String? key;

  /// Free-form, human-readable message describing the app state.
  ///
  /// For example, an error message. To prevent XSS, we recommend removing any
  /// HTML from the message before displaying it.
  core.String? message;

  /// Severity of the app state.
  ///
  /// This field will always be present.
  /// Possible string values are:
  /// - "severityUnknown"
  /// - "severityInfo"
  /// - "severityError"
  core.String? severity;

  /// Timestamp of when the app set the state in milliseconds since epoch.
  ///
  /// This field will always be present.
  core.String? stateTimestampMillis;

  KeyedAppState();

  KeyedAppState.fromJson(core.Map _json) {
    if (_json.containsKey('data')) {
      data = _json['data'] as core.String;
    }
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
    if (_json.containsKey('stateTimestampMillis')) {
      stateTimestampMillis = _json['stateTimestampMillis'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (data != null) 'data': data!,
        if (key != null) 'key': key!,
        if (message != null) 'message': message!,
        if (severity != null) 'severity': severity!,
        if (stateTimestampMillis != null)
          'stateTimestampMillis': stateTimestampMillis!,
      };
}

/// A localized string with its locale.
class LocalizedText {
  /// The BCP47 tag for a locale.
  ///
  /// (e.g. "en-US", "de").
  core.String? locale;

  /// The text localized in the associated locale.
  core.String? text;

  LocalizedText();

  LocalizedText.fromJson(core.Map _json) {
    if (_json.containsKey('locale')) {
      locale = _json['locale'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (locale != null) 'locale': locale!,
        if (text != null) 'text': text!,
      };
}

/// Maintenance window for managed Google Play Accounts.
///
/// This allows Play store to update the apps on the foreground in the
/// designated window.
class MaintenanceWindow {
  /// Duration of the maintenance window, in milliseconds.
  ///
  /// The duration must be between 30 minutes and 24 hours (inclusive).
  core.String? durationMs;

  /// Start time of the maintenance window, in milliseconds after midnight on
  /// the device.
  ///
  /// Windows can span midnight.
  core.String? startTimeAfterMidnightMs;

  MaintenanceWindow();

  MaintenanceWindow.fromJson(core.Map _json) {
    if (_json.containsKey('durationMs')) {
      durationMs = _json['durationMs'] as core.String;
    }
    if (_json.containsKey('startTimeAfterMidnightMs')) {
      startTimeAfterMidnightMs =
          _json['startTimeAfterMidnightMs'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (durationMs != null) 'durationMs': durationMs!,
        if (startTimeAfterMidnightMs != null)
          'startTimeAfterMidnightMs': startTimeAfterMidnightMs!,
      };
}

/// A managed configuration resource contains the set of managed properties
/// defined by the app developer in the app's managed configurations schema, as
/// well as any configuration variables defined for the user.
class ManagedConfiguration {
  /// Contains the ID of the managed configuration profile and the set of
  /// configuration variables (if any) defined for the user.
  ConfigurationVariables? configurationVariables;

  /// Deprecated.
  core.String? kind;

  /// The set of managed properties for this configuration.
  core.List<ManagedProperty>? managedProperty;

  /// The ID of the product that the managed configuration is for, e.g.
  /// "app:com.google.android.gm".
  core.String? productId;

  ManagedConfiguration();

  ManagedConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('configurationVariables')) {
      configurationVariables = ConfigurationVariables.fromJson(
          _json['configurationVariables']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('managedProperty')) {
      managedProperty = (_json['managedProperty'] as core.List)
          .map<ManagedProperty>((value) => ManagedProperty.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (configurationVariables != null)
          'configurationVariables': configurationVariables!.toJson(),
        if (kind != null) 'kind': kind!,
        if (managedProperty != null)
          'managedProperty':
              managedProperty!.map((value) => value.toJson()).toList(),
        if (productId != null) 'productId': productId!,
      };
}

class ManagedConfigurationsForDeviceListResponse {
  /// A managed configuration for an app on a specific device.
  core.List<ManagedConfiguration>? managedConfigurationForDevice;

  ManagedConfigurationsForDeviceListResponse();

  ManagedConfigurationsForDeviceListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('managedConfigurationForDevice')) {
      managedConfigurationForDevice = (_json['managedConfigurationForDevice']
              as core.List)
          .map<ManagedConfiguration>((value) => ManagedConfiguration.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (managedConfigurationForDevice != null)
          'managedConfigurationForDevice': managedConfigurationForDevice!
              .map((value) => value.toJson())
              .toList(),
      };
}

class ManagedConfigurationsForUserListResponse {
  /// A managed configuration for an app for a specific user.
  core.List<ManagedConfiguration>? managedConfigurationForUser;

  ManagedConfigurationsForUserListResponse();

  ManagedConfigurationsForUserListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('managedConfigurationForUser')) {
      managedConfigurationForUser = (_json['managedConfigurationForUser']
              as core.List)
          .map<ManagedConfiguration>((value) => ManagedConfiguration.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (managedConfigurationForUser != null)
          'managedConfigurationForUser': managedConfigurationForUser!
              .map((value) => value.toJson())
              .toList(),
      };
}

/// A managed configurations settings resource contains the set of managed
/// properties that have been configured for an Android app to be applied to a
/// set of users.
///
/// The app's developer would have defined configurable properties in the
/// managed configurations schema.
class ManagedConfigurationsSettings {
  /// The last updated time of the managed configuration settings in
  /// milliseconds since 1970-01-01T00:00:00Z.
  core.String? lastUpdatedTimestampMillis;

  /// The ID of the managed configurations settings.
  core.String? mcmId;

  /// The name of the managed configurations settings.
  core.String? name;

  ManagedConfigurationsSettings();

  ManagedConfigurationsSettings.fromJson(core.Map _json) {
    if (_json.containsKey('lastUpdatedTimestampMillis')) {
      lastUpdatedTimestampMillis =
          _json['lastUpdatedTimestampMillis'] as core.String;
    }
    if (_json.containsKey('mcmId')) {
      mcmId = _json['mcmId'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lastUpdatedTimestampMillis != null)
          'lastUpdatedTimestampMillis': lastUpdatedTimestampMillis!,
        if (mcmId != null) 'mcmId': mcmId!,
        if (name != null) 'name': name!,
      };
}

class ManagedConfigurationsSettingsListResponse {
  /// A managed configurations settings for an app that may be assigned to a
  /// group of users in an enterprise.
  core.List<ManagedConfigurationsSettings>? managedConfigurationsSettings;

  ManagedConfigurationsSettingsListResponse();

  ManagedConfigurationsSettingsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('managedConfigurationsSettings')) {
      managedConfigurationsSettings =
          (_json['managedConfigurationsSettings'] as core.List)
              .map<ManagedConfigurationsSettings>((value) =>
                  ManagedConfigurationsSettings.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (managedConfigurationsSettings != null)
          'managedConfigurationsSettings': managedConfigurationsSettings!
              .map((value) => value.toJson())
              .toList(),
      };
}

/// A managed property of a managed configuration.
///
/// The property must match one of the properties in the app restrictions schema
/// of the product. Exactly one of the value fields must be populated, and it
/// must match the property's type in the app restrictions schema.
class ManagedProperty {
  /// The unique key that identifies the property.
  core.String? key;

  /// The boolean value - this will only be present if type of the property is
  /// bool.
  core.bool? valueBool;

  /// The bundle of managed properties - this will only be present if type of
  /// the property is bundle.
  ManagedPropertyBundle? valueBundle;

  /// The list of bundles of properties - this will only be present if type of
  /// the property is bundle_array.
  core.List<ManagedPropertyBundle>? valueBundleArray;

  /// The integer value - this will only be present if type of the property is
  /// integer.
  core.int? valueInteger;

  /// The string value - this will only be present if type of the property is
  /// string, choice or hidden.
  core.String? valueString;

  /// The list of string values - this will only be present if type of the
  /// property is multiselect.
  core.List<core.String>? valueStringArray;

  ManagedProperty();

  ManagedProperty.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('valueBool')) {
      valueBool = _json['valueBool'] as core.bool;
    }
    if (_json.containsKey('valueBundle')) {
      valueBundle = ManagedPropertyBundle.fromJson(
          _json['valueBundle'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('valueBundleArray')) {
      valueBundleArray = (_json['valueBundleArray'] as core.List)
          .map<ManagedPropertyBundle>((value) => ManagedPropertyBundle.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('valueInteger')) {
      valueInteger = _json['valueInteger'] as core.int;
    }
    if (_json.containsKey('valueString')) {
      valueString = _json['valueString'] as core.String;
    }
    if (_json.containsKey('valueStringArray')) {
      valueStringArray = (_json['valueStringArray'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (valueBool != null) 'valueBool': valueBool!,
        if (valueBundle != null) 'valueBundle': valueBundle!.toJson(),
        if (valueBundleArray != null)
          'valueBundleArray':
              valueBundleArray!.map((value) => value.toJson()).toList(),
        if (valueInteger != null) 'valueInteger': valueInteger!,
        if (valueString != null) 'valueString': valueString!,
        if (valueStringArray != null) 'valueStringArray': valueStringArray!,
      };
}

/// A bundle of managed properties.
class ManagedPropertyBundle {
  /// The list of managed properties.
  core.List<ManagedProperty>? managedProperty;

  ManagedPropertyBundle();

  ManagedPropertyBundle.fromJson(core.Map _json) {
    if (_json.containsKey('managedProperty')) {
      managedProperty = (_json['managedProperty'] as core.List)
          .map<ManagedProperty>((value) => ManagedProperty.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (managedProperty != null)
          'managedProperty':
              managedProperty!.map((value) => value.toJson()).toList(),
      };
}

/// An event generated when a new device is ready to be managed.
class NewDeviceEvent {
  /// The Android ID of the device.
  ///
  /// This field will always be present.
  core.String? deviceId;

  /// Policy app on the device.
  core.String? dpcPackageName;

  /// Identifies the extent to which the device is controlled by an Android EMM
  /// in various deployment configurations.
  ///
  /// Possible values include: - "managedDevice", a device where the DPC is set
  /// as device owner, - "managedProfile", a device where the DPC is set as
  /// profile owner.
  /// Possible string values are:
  /// - "managedDevice"
  /// - "managedProfile"
  core.String? managementType;

  /// The ID of the user.
  ///
  /// This field will always be present.
  core.String? userId;

  NewDeviceEvent();

  NewDeviceEvent.fromJson(core.Map _json) {
    if (_json.containsKey('deviceId')) {
      deviceId = _json['deviceId'] as core.String;
    }
    if (_json.containsKey('dpcPackageName')) {
      dpcPackageName = _json['dpcPackageName'] as core.String;
    }
    if (_json.containsKey('managementType')) {
      managementType = _json['managementType'] as core.String;
    }
    if (_json.containsKey('userId')) {
      userId = _json['userId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceId != null) 'deviceId': deviceId!,
        if (dpcPackageName != null) 'dpcPackageName': dpcPackageName!,
        if (managementType != null) 'managementType': managementType!,
        if (userId != null) 'userId': userId!,
      };
}

/// An event generated when new permissions are added to an app.
class NewPermissionsEvent {
  /// The set of permissions that the enterprise admin has already approved for
  /// this application.
  ///
  /// Use Permissions.Get on the EMM API to retrieve details about these
  /// permissions.
  core.List<core.String>? approvedPermissions;

  /// The id of the product (e.g. "app:com.google.android.gm") for which new
  /// permissions were added.
  ///
  /// This field will always be present.
  core.String? productId;

  /// The set of permissions that the app is currently requesting.
  ///
  /// Use Permissions.Get on the EMM API to retrieve details about these
  /// permissions.
  core.List<core.String>? requestedPermissions;

  NewPermissionsEvent();

  NewPermissionsEvent.fromJson(core.Map _json) {
    if (_json.containsKey('approvedPermissions')) {
      approvedPermissions = (_json['approvedPermissions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('requestedPermissions')) {
      requestedPermissions = (_json['requestedPermissions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (approvedPermissions != null)
          'approvedPermissions': approvedPermissions!,
        if (productId != null) 'productId': productId!,
        if (requestedPermissions != null)
          'requestedPermissions': requestedPermissions!,
      };
}

/// A notification of one event relating to an enterprise.
class Notification {
  /// Notifications about new app restrictions schema changes.
  AppRestrictionsSchemaChangeEvent? appRestrictionsSchemaChangeEvent;

  /// Notifications about app updates.
  AppUpdateEvent? appUpdateEvent;

  /// Notifications about device report updates.
  DeviceReportUpdateEvent? deviceReportUpdateEvent;

  /// The ID of the enterprise for which the notification is sent.
  ///
  /// This will always be present.
  core.String? enterpriseId;

  /// Notifications about an app installation failure.
  InstallFailureEvent? installFailureEvent;

  /// Notifications about new devices.
  NewDeviceEvent? newDeviceEvent;

  /// Notifications about new app permissions.
  NewPermissionsEvent? newPermissionsEvent;

  /// Type of the notification.
  /// Possible string values are:
  /// - "unknown"
  /// - "testNotification" : A test push notification.
  /// - "productApproval" : Notification about change to a product's approval
  /// status.
  /// - "installFailure" : Notification about an app installation failure.
  /// - "appUpdate" : Notification about app update.
  /// - "newPermissions" : Notification about new app permissions.
  /// - "appRestricionsSchemaChange" : Notification about new app restrictions
  /// schema change.
  /// - "productAvailabilityChange" : Notification about product availability
  /// change.
  /// - "newDevice" : Notification about a new device.
  /// - "deviceReportUpdate" : Notification about an updated device report.
  core.String? notificationType;

  /// Notifications about changes to a product's approval status.
  ProductApprovalEvent? productApprovalEvent;

  /// Notifications about product availability changes.
  ProductAvailabilityChangeEvent? productAvailabilityChangeEvent;

  /// The time when the notification was published in milliseconds since
  /// 1970-01-01T00:00:00Z.
  ///
  /// This will always be present.
  core.String? timestampMillis;

  Notification();

  Notification.fromJson(core.Map _json) {
    if (_json.containsKey('appRestrictionsSchemaChangeEvent')) {
      appRestrictionsSchemaChangeEvent =
          AppRestrictionsSchemaChangeEvent.fromJson(
              _json['appRestrictionsSchemaChangeEvent']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('appUpdateEvent')) {
      appUpdateEvent = AppUpdateEvent.fromJson(
          _json['appUpdateEvent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deviceReportUpdateEvent')) {
      deviceReportUpdateEvent = DeviceReportUpdateEvent.fromJson(
          _json['deviceReportUpdateEvent']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('enterpriseId')) {
      enterpriseId = _json['enterpriseId'] as core.String;
    }
    if (_json.containsKey('installFailureEvent')) {
      installFailureEvent = InstallFailureEvent.fromJson(
          _json['installFailureEvent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('newDeviceEvent')) {
      newDeviceEvent = NewDeviceEvent.fromJson(
          _json['newDeviceEvent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('newPermissionsEvent')) {
      newPermissionsEvent = NewPermissionsEvent.fromJson(
          _json['newPermissionsEvent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('notificationType')) {
      notificationType = _json['notificationType'] as core.String;
    }
    if (_json.containsKey('productApprovalEvent')) {
      productApprovalEvent = ProductApprovalEvent.fromJson(
          _json['productApprovalEvent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('productAvailabilityChangeEvent')) {
      productAvailabilityChangeEvent = ProductAvailabilityChangeEvent.fromJson(
          _json['productAvailabilityChangeEvent']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timestampMillis')) {
      timestampMillis = _json['timestampMillis'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appRestrictionsSchemaChangeEvent != null)
          'appRestrictionsSchemaChangeEvent':
              appRestrictionsSchemaChangeEvent!.toJson(),
        if (appUpdateEvent != null) 'appUpdateEvent': appUpdateEvent!.toJson(),
        if (deviceReportUpdateEvent != null)
          'deviceReportUpdateEvent': deviceReportUpdateEvent!.toJson(),
        if (enterpriseId != null) 'enterpriseId': enterpriseId!,
        if (installFailureEvent != null)
          'installFailureEvent': installFailureEvent!.toJson(),
        if (newDeviceEvent != null) 'newDeviceEvent': newDeviceEvent!.toJson(),
        if (newPermissionsEvent != null)
          'newPermissionsEvent': newPermissionsEvent!.toJson(),
        if (notificationType != null) 'notificationType': notificationType!,
        if (productApprovalEvent != null)
          'productApprovalEvent': productApprovalEvent!.toJson(),
        if (productAvailabilityChangeEvent != null)
          'productAvailabilityChangeEvent':
              productAvailabilityChangeEvent!.toJson(),
        if (timestampMillis != null) 'timestampMillis': timestampMillis!,
      };
}

/// A resource returned by the PullNotificationSet API, which contains a
/// collection of notifications for enterprises associated with the service
/// account authenticated for the request.
class NotificationSet {
  /// The notifications received, or empty if no notifications are present.
  core.List<Notification>? notification;

  /// The notification set ID, required to mark the notification as received
  /// with the Enterprises.AcknowledgeNotification API.
  ///
  /// This will be omitted if no notifications are present.
  core.String? notificationSetId;

  NotificationSet();

  NotificationSet.fromJson(core.Map _json) {
    if (_json.containsKey('notification')) {
      notification = (_json['notification'] as core.List)
          .map<Notification>((value) => Notification.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('notificationSetId')) {
      notificationSetId = _json['notificationSetId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (notification != null)
          'notification': notification!.map((value) => value.toJson()).toList(),
        if (notificationSetId != null) 'notificationSetId': notificationSetId!,
      };
}

/// Information about the current page.
///
/// List operations that supports paging return only one "page" of results. This
/// protocol buffer message describes the page that has been returned.
class PageInfo {
  /// Maximum number of results returned in one page.
  ///
  /// ! The number of results included in the API response.
  core.int? resultPerPage;

  /// Index of the first result returned in the current page.
  core.int? startIndex;

  /// Total number of results available on the backend ! The total number of
  /// results in the result set.
  core.int? totalResults;

  PageInfo();

  PageInfo.fromJson(core.Map _json) {
    if (_json.containsKey('resultPerPage')) {
      resultPerPage = _json['resultPerPage'] as core.int;
    }
    if (_json.containsKey('startIndex')) {
      startIndex = _json['startIndex'] as core.int;
    }
    if (_json.containsKey('totalResults')) {
      totalResults = _json['totalResults'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resultPerPage != null) 'resultPerPage': resultPerPage!,
        if (startIndex != null) 'startIndex': startIndex!,
        if (totalResults != null) 'totalResults': totalResults!,
      };
}

/// A Permissions resource represents some extra capability, to be granted to an
/// Android app, which requires explicit consent.
///
/// An enterprise admin must consent to these permissions on behalf of their
/// users before an entitlement for the app can be created. The permissions
/// collection is read-only. The information provided for each permission
/// (localized name and description) is intended to be used in the MDM user
/// interface when obtaining consent from the enterprise.
class Permission {
  /// A longer description of the Permissions resource, giving more details of
  /// what it affects.
  core.String? description;

  /// The name of the permission.
  core.String? name;

  /// An opaque string uniquely identifying the permission.
  core.String? permissionId;

  Permission();

  Permission.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('permissionId')) {
      permissionId = _json['permissionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (name != null) 'name': name!,
        if (permissionId != null) 'permissionId': permissionId!,
      };
}

/// The device policy for a given managed device.
class Policy {
  /// The auto-update policy for apps installed on the device.
  ///
  /// "choiceToTheUser" allows the device's user to configure the app update
  /// policy. "always" enables auto updates. "never" disables auto updates.
  /// "wifiOnly" enables auto updates only when the device is connected to wifi.
  /// Possible string values are:
  /// - "autoUpdatePolicyUnspecified" : The auto update policy is not set.
  /// - "choiceToTheUser" : The user can control auto-updates.
  /// - "never" : Apps are never auto-updated.
  /// - "wifiOnly" : Apps are auto-updated over WiFi only.
  /// - "always" : Apps are auto-updated at any time. Data charges may apply.
  core.String? autoUpdatePolicy;

  /// Whether the device reports app states to the EMM.
  ///
  /// The default value is "deviceReportDisabled".
  /// Possible string values are:
  /// - "deviceReportPolicyUnspecified" : The device report policy is not set.
  /// - "deviceReportDisabled" : Device reports are disabled.
  /// - "deviceReportEnabled" : Device reports are enabled.
  core.String? deviceReportPolicy;

  /// The maintenance window defining when apps running in the foreground should
  /// be updated.
  MaintenanceWindow? maintenanceWindow;

  /// The availability granted to the device for the specified products.
  ///
  /// "all" gives the device access to all products, regardless of approval
  /// status. "all" does not enable automatic visibility of "alpha" or "beta"
  /// tracks. "whitelist" grants the device access the products specified in
  /// productPolicy\[\]. Only products that are approved or products that were
  /// previously approved (products with revoked approval) by the enterprise can
  /// be whitelisted. If no value is provided, the availability set at the user
  /// level is applied by default.
  /// Possible string values are:
  /// - "productAvailabilityPolicyUnspecified" : Unspecified, applies the user
  /// available product set by default.
  /// - "whitelist" : The approved products with product availability set to
  /// AVAILABLE in the product policy are available.
  /// - "all" : All products are available except those explicitly marked as
  /// unavailable in the product availability policy.
  core.String? productAvailabilityPolicy;

  /// The list of product policies.
  ///
  /// The productAvailabilityPolicy needs to be set to WHITELIST or ALL for the
  /// product policies to be applied.
  core.List<ProductPolicy>? productPolicy;

  Policy();

  Policy.fromJson(core.Map _json) {
    if (_json.containsKey('autoUpdatePolicy')) {
      autoUpdatePolicy = _json['autoUpdatePolicy'] as core.String;
    }
    if (_json.containsKey('deviceReportPolicy')) {
      deviceReportPolicy = _json['deviceReportPolicy'] as core.String;
    }
    if (_json.containsKey('maintenanceWindow')) {
      maintenanceWindow = MaintenanceWindow.fromJson(
          _json['maintenanceWindow'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('productAvailabilityPolicy')) {
      productAvailabilityPolicy =
          _json['productAvailabilityPolicy'] as core.String;
    }
    if (_json.containsKey('productPolicy')) {
      productPolicy = (_json['productPolicy'] as core.List)
          .map<ProductPolicy>((value) => ProductPolicy.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoUpdatePolicy != null) 'autoUpdatePolicy': autoUpdatePolicy!,
        if (deviceReportPolicy != null)
          'deviceReportPolicy': deviceReportPolicy!,
        if (maintenanceWindow != null)
          'maintenanceWindow': maintenanceWindow!.toJson(),
        if (productAvailabilityPolicy != null)
          'productAvailabilityPolicy': productAvailabilityPolicy!,
        if (productPolicy != null)
          'productPolicy':
              productPolicy!.map((value) => value.toJson()).toList(),
      };
}

/// A Products resource represents an app in the Google Play store that is
/// available to at least some users in the enterprise.
///
/// (Some apps are restricted to a single enterprise, and no information about
/// them is made available outside that enterprise.) The information provided
/// for each product (localized name, icon, link to the full Google Play details
/// page) is intended to allow a basic representation of the product within an
/// EMM user interface.
class Product {
  /// The tracks visible to the enterprise.
  core.List<TrackInfo>? appTracks;

  /// App versions currently available for this product.
  core.List<AppVersion>? appVersion;

  /// The name of the author of the product (for example, the app developer).
  core.String? authorName;

  /// The countries which this app is available in.
  core.List<core.String>? availableCountries;

  /// Deprecated, use appTracks instead.
  core.List<core.String>? availableTracks;

  /// The app category (e.g. RACING, SOCIAL, etc.)
  core.String? category;

  /// The content rating for this app.
  /// Possible string values are:
  /// - "ratingUnknown"
  /// - "all"
  /// - "preTeen"
  /// - "teen"
  /// - "mature"
  core.String? contentRating;

  /// The localized promotional description, if available.
  core.String? description;

  /// A link to the (consumer) Google Play details page for the product.
  core.String? detailsUrl;

  /// How and to whom the package is made available.
  ///
  /// The value publicGoogleHosted means that the package is available through
  /// the Play store and not restricted to a specific enterprise. The value
  /// privateGoogleHosted means that the package is a private app (restricted to
  /// an enterprise) but hosted by Google. The value privateSelfHosted means
  /// that the package is a private app (restricted to an enterprise) and is
  /// privately hosted.
  /// Possible string values are:
  /// - "publicGoogleHosted"
  /// - "privateGoogleHosted"
  /// - "privateSelfHosted"
  core.String? distributionChannel;

  /// Noteworthy features (if any) of this product.
  core.List<core.String>? features;

  /// A link to an image that can be used as an icon for the product.
  ///
  /// This image is suitable for use at up to 512px x 512px.
  core.String? iconUrl;

  /// The approximate time (within 7 days) the app was last published, expressed
  /// in milliseconds since epoch.
  core.String? lastUpdatedTimestampMillis;

  /// The minimum Android SDK necessary to run the app.
  core.int? minAndroidSdkVersion;

  /// A list of permissions required by the app.
  core.List<ProductPermission>? permissions;

  /// A string of the form *app:<package name>*.
  ///
  /// For example, app:com.google.android.gm represents the Gmail app.
  core.String? productId;

  /// Whether this product is free, free with in-app purchases, or paid.
  ///
  /// If the pricing is unknown, this means the product is not generally
  /// available anymore (even though it might still be available to people who
  /// own it).
  /// Possible string values are:
  /// - "unknown" : Unknown pricing, used to denote an approved product that is
  /// not generally available.
  /// - "free" : The product is free.
  /// - "freeWithInAppPurchase" : The product is free, but offers in-app
  /// purchases.
  /// - "paid" : The product is paid.
  core.String? productPricing;

  /// A description of the recent changes made to the app.
  core.String? recentChanges;

  /// Deprecated.
  core.bool? requiresContainerApp;

  /// A list of screenshot links representing the app.
  core.List<core.String>? screenshotUrls;

  /// The certificate used to sign this product.
  ProductSigningCertificate? signingCertificate;

  /// A link to a smaller image that can be used as an icon for the product.
  ///
  /// This image is suitable for use at up to 128px x 128px.
  core.String? smallIconUrl;

  /// The name of the product.
  core.String? title;

  /// A link to the managed Google Play details page for the product, for use by
  /// an Enterprise admin.
  core.String? workDetailsUrl;

  Product();

  Product.fromJson(core.Map _json) {
    if (_json.containsKey('appTracks')) {
      appTracks = (_json['appTracks'] as core.List)
          .map<TrackInfo>((value) =>
              TrackInfo.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('appVersion')) {
      appVersion = (_json['appVersion'] as core.List)
          .map<AppVersion>((value) =>
              AppVersion.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('authorName')) {
      authorName = _json['authorName'] as core.String;
    }
    if (_json.containsKey('availableCountries')) {
      availableCountries = (_json['availableCountries'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('availableTracks')) {
      availableTracks = (_json['availableTracks'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('category')) {
      category = _json['category'] as core.String;
    }
    if (_json.containsKey('contentRating')) {
      contentRating = _json['contentRating'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('detailsUrl')) {
      detailsUrl = _json['detailsUrl'] as core.String;
    }
    if (_json.containsKey('distributionChannel')) {
      distributionChannel = _json['distributionChannel'] as core.String;
    }
    if (_json.containsKey('features')) {
      features = (_json['features'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('iconUrl')) {
      iconUrl = _json['iconUrl'] as core.String;
    }
    if (_json.containsKey('lastUpdatedTimestampMillis')) {
      lastUpdatedTimestampMillis =
          _json['lastUpdatedTimestampMillis'] as core.String;
    }
    if (_json.containsKey('minAndroidSdkVersion')) {
      minAndroidSdkVersion = _json['minAndroidSdkVersion'] as core.int;
    }
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<ProductPermission>((value) => ProductPermission.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('productPricing')) {
      productPricing = _json['productPricing'] as core.String;
    }
    if (_json.containsKey('recentChanges')) {
      recentChanges = _json['recentChanges'] as core.String;
    }
    if (_json.containsKey('requiresContainerApp')) {
      requiresContainerApp = _json['requiresContainerApp'] as core.bool;
    }
    if (_json.containsKey('screenshotUrls')) {
      screenshotUrls = (_json['screenshotUrls'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('signingCertificate')) {
      signingCertificate = ProductSigningCertificate.fromJson(
          _json['signingCertificate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('smallIconUrl')) {
      smallIconUrl = _json['smallIconUrl'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('workDetailsUrl')) {
      workDetailsUrl = _json['workDetailsUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appTracks != null)
          'appTracks': appTracks!.map((value) => value.toJson()).toList(),
        if (appVersion != null)
          'appVersion': appVersion!.map((value) => value.toJson()).toList(),
        if (authorName != null) 'authorName': authorName!,
        if (availableCountries != null)
          'availableCountries': availableCountries!,
        if (availableTracks != null) 'availableTracks': availableTracks!,
        if (category != null) 'category': category!,
        if (contentRating != null) 'contentRating': contentRating!,
        if (description != null) 'description': description!,
        if (detailsUrl != null) 'detailsUrl': detailsUrl!,
        if (distributionChannel != null)
          'distributionChannel': distributionChannel!,
        if (features != null) 'features': features!,
        if (iconUrl != null) 'iconUrl': iconUrl!,
        if (lastUpdatedTimestampMillis != null)
          'lastUpdatedTimestampMillis': lastUpdatedTimestampMillis!,
        if (minAndroidSdkVersion != null)
          'minAndroidSdkVersion': minAndroidSdkVersion!,
        if (permissions != null)
          'permissions': permissions!.map((value) => value.toJson()).toList(),
        if (productId != null) 'productId': productId!,
        if (productPricing != null) 'productPricing': productPricing!,
        if (recentChanges != null) 'recentChanges': recentChanges!,
        if (requiresContainerApp != null)
          'requiresContainerApp': requiresContainerApp!,
        if (screenshotUrls != null) 'screenshotUrls': screenshotUrls!,
        if (signingCertificate != null)
          'signingCertificate': signingCertificate!.toJson(),
        if (smallIconUrl != null) 'smallIconUrl': smallIconUrl!,
        if (title != null) 'title': title!,
        if (workDetailsUrl != null) 'workDetailsUrl': workDetailsUrl!,
      };
}

/// An event generated when a product's approval status is changed.
class ProductApprovalEvent {
  /// Whether the product was approved or unapproved.
  ///
  /// This field will always be present.
  /// Possible string values are:
  /// - "unknown" : Conveys no information.
  /// - "approved" : The product was approved.
  /// - "unapproved" : The product was unapproved.
  core.String? approved;

  /// The id of the product (e.g. "app:com.google.android.gm") for which the
  /// approval status has changed.
  ///
  /// This field will always be present.
  core.String? productId;

  ProductApprovalEvent();

  ProductApprovalEvent.fromJson(core.Map _json) {
    if (_json.containsKey('approved')) {
      approved = _json['approved'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (approved != null) 'approved': approved!,
        if (productId != null) 'productId': productId!,
      };
}

/// An event generated whenever a product's availability changes.
class ProductAvailabilityChangeEvent {
  /// The new state of the product.
  ///
  /// This field will always be present.
  /// Possible string values are:
  /// - "unknown" : Conveys no information.
  /// - "available" : The previously unavailable product is again available on
  /// Google Play.
  /// - "removed" : The product was removed from Google Play.
  /// - "unpublished" : The product was unpublished by the developer.
  core.String? availabilityStatus;

  /// The id of the product (e.g. "app:com.google.android.gm") for which the
  /// product availability changed.
  ///
  /// This field will always be present.
  core.String? productId;

  ProductAvailabilityChangeEvent();

  ProductAvailabilityChangeEvent.fromJson(core.Map _json) {
    if (_json.containsKey('availabilityStatus')) {
      availabilityStatus = _json['availabilityStatus'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (availabilityStatus != null)
          'availabilityStatus': availabilityStatus!,
        if (productId != null) 'productId': productId!,
      };
}

/// A product permissions resource represents the set of permissions required by
/// a specific app and whether or not they have been accepted by an enterprise
/// admin.
///
/// The API can be used to read the set of permissions, and also to update the
/// set to indicate that permissions have been accepted.
class ProductPermission {
  /// An opaque string uniquely identifying the permission.
  core.String? permissionId;

  /// Whether the permission has been accepted or not.
  /// Possible string values are:
  /// - "required" : The permission is required by the app but has not yet been
  /// accepted by the enterprise.
  /// - "accepted" : The permission has been accepted by the enterprise.
  core.String? state;

  ProductPermission();

  ProductPermission.fromJson(core.Map _json) {
    if (_json.containsKey('permissionId')) {
      permissionId = _json['permissionId'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (permissionId != null) 'permissionId': permissionId!,
        if (state != null) 'state': state!,
      };
}

/// Information about the permissions required by a specific app and whether
/// they have been accepted by the enterprise.
class ProductPermissions {
  /// The permissions required by the app.
  core.List<ProductPermission>? permission;

  /// The ID of the app that the permissions relate to, e.g.
  /// "app:com.google.android.gm".
  core.String? productId;

  ProductPermissions();

  ProductPermissions.fromJson(core.Map _json) {
    if (_json.containsKey('permission')) {
      permission = (_json['permission'] as core.List)
          .map<ProductPermission>((value) => ProductPermission.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (permission != null)
          'permission': permission!.map((value) => value.toJson()).toList(),
        if (productId != null) 'productId': productId!,
      };
}

/// The policy for a product.
class ProductPolicy {
  /// The auto-install policy for the product.
  AutoInstallPolicy? autoInstallPolicy;

  /// The auto-update mode for the product.
  /// Possible string values are:
  /// - "autoUpdateModeUnspecified" : Unspecified. Defaults to
  /// AUTO_UPDATE_DEFAULT.
  /// - "autoUpdateDefault" : The app is automatically updated with low priority
  /// to minimize the impact on the user. The app is updated when the following
  /// constraints are met: * The device is not actively used * The device is
  /// connected to a Wi-Fi network. * The device is charging * If the system
  /// update policy is set to `WINDOWED`: the local time of the device is within
  /// the daily maintenance window The device is notified about a new update
  /// within 24 hours after it is published by the developer, after which the
  /// app is updated the next time the constraints above are met.
  /// - "autoUpdatePostponed" : The app is not automatically updated for a
  /// maximum of 90 days after the app becomes out of date. 90 days after the
  /// app becomes out of date, the latest available version is installed
  /// automatically with low priority (see AUTO_UPDATE_DEFAULT). After the app
  /// is updated it is not automatically updated again until 90 days after it
  /// becomes out of date again. The user can still manually update the app from
  /// the Play Store at any time.
  /// - "autoUpdateHighPriority" : The app is updated as soon as possible. No
  /// constraints are applied. The device is notified immediately about a new
  /// app update after it is published by the developer.
  core.String? autoUpdateMode;

  /// The managed configuration for the product.
  ManagedConfiguration? managedConfiguration;

  /// The ID of the product.
  ///
  /// For example, "app:com.google.android.gm".
  core.String? productId;

  /// Grants the device visibility to the specified product release track(s),
  /// identified by trackIds.
  ///
  /// The list of release tracks of a product can be obtained by calling
  /// Products.Get.
  core.List<core.String>? trackIds;

  /// Use trackIds instead.
  ///
  /// Deprecated.
  core.List<core.String>? tracks;

  ProductPolicy();

  ProductPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('autoInstallPolicy')) {
      autoInstallPolicy = AutoInstallPolicy.fromJson(
          _json['autoInstallPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('autoUpdateMode')) {
      autoUpdateMode = _json['autoUpdateMode'] as core.String;
    }
    if (_json.containsKey('managedConfiguration')) {
      managedConfiguration = ManagedConfiguration.fromJson(
          _json['managedConfiguration'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('trackIds')) {
      trackIds = (_json['trackIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoInstallPolicy != null)
          'autoInstallPolicy': autoInstallPolicy!.toJson(),
        if (autoUpdateMode != null) 'autoUpdateMode': autoUpdateMode!,
        if (managedConfiguration != null)
          'managedConfiguration': managedConfiguration!.toJson(),
        if (productId != null) 'productId': productId!,
        if (trackIds != null) 'trackIds': trackIds!,
        if (tracks != null) 'tracks': tracks!,
      };
}

/// A set of products.
class ProductSet {
  /// The list of product IDs making up the set of products.
  core.List<core.String>? productId;

  /// The interpretation of this product set.
  ///
  /// "unknown" should never be sent and is ignored if received. "whitelist"
  /// means that the user is entitled to access the product set. "includeAll"
  /// means that all products are accessible, including products that are
  /// approved, products with revoked approval, and products that have never
  /// been approved. "allApproved" means that the user is entitled to access all
  /// products that are approved for the enterprise. If the value is
  /// "allApproved" or "includeAll", the productId field is ignored. If no value
  /// is provided, it is interpreted as "whitelist" for backwards compatibility.
  /// Further "allApproved" or "includeAll" does not enable automatic visibility
  /// of "alpha" or "beta" tracks for Android app. Use ProductVisibility to
  /// enable "alpha" or "beta" tracks per user.
  /// Possible string values are:
  /// - "unknown" : This value should never be sent and ignored if received.
  /// - "whitelist" : This product set constitutes a whitelist.
  /// - "includeAll" : This product set represents all products. For Android app
  /// it represents only "production" track. (The value of the productId field
  /// is therefore ignored).
  /// - "allApproved" : This product set represents all approved products. For
  /// Android app it represents only "production" track. (The value of the
  /// product_id field is therefore ignored).
  core.String? productSetBehavior;

  /// Additional list of product IDs making up the product set.
  ///
  /// Unlike the productID array, in this list It's possible to specify which
  /// tracks (alpha, beta, production) of a product are visible to the user. See
  /// ProductVisibility and its fields for more information. Specifying the same
  /// product ID both here and in the productId array is not allowed and it will
  /// result in an error.
  core.List<ProductVisibility>? productVisibility;

  ProductSet();

  ProductSet.fromJson(core.Map _json) {
    if (_json.containsKey('productId')) {
      productId = (_json['productId'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('productSetBehavior')) {
      productSetBehavior = _json['productSetBehavior'] as core.String;
    }
    if (_json.containsKey('productVisibility')) {
      productVisibility = (_json['productVisibility'] as core.List)
          .map<ProductVisibility>((value) => ProductVisibility.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (productId != null) 'productId': productId!,
        if (productSetBehavior != null)
          'productSetBehavior': productSetBehavior!,
        if (productVisibility != null)
          'productVisibility':
              productVisibility!.map((value) => value.toJson()).toList(),
      };
}

class ProductSigningCertificate {
  /// The base64 urlsafe encoded SHA1 hash of the certificate.
  ///
  /// (This field is deprecated in favor of SHA2-256. It should not be used and
  /// may be removed at any time.)
  core.String? certificateHashSha1;

  /// The base64 urlsafe encoded SHA2-256 hash of the certificate.
  core.String? certificateHashSha256;

  ProductSigningCertificate();

  ProductSigningCertificate.fromJson(core.Map _json) {
    if (_json.containsKey('certificateHashSha1')) {
      certificateHashSha1 = _json['certificateHashSha1'] as core.String;
    }
    if (_json.containsKey('certificateHashSha256')) {
      certificateHashSha256 = _json['certificateHashSha256'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (certificateHashSha1 != null)
          'certificateHashSha1': certificateHashSha1!,
        if (certificateHashSha256 != null)
          'certificateHashSha256': certificateHashSha256!,
      };
}

/// A product to be made visible to a user.
class ProductVisibility {
  /// The product ID to make visible to the user.
  ///
  /// Required for each item in the productVisibility list.
  core.String? productId;

  /// Grants the user visibility to the specified product track(s), identified
  /// by trackIds.
  core.List<core.String>? trackIds;

  /// Use trackIds instead.
  ///
  /// Deprecated.
  core.List<core.String>? tracks;

  ProductVisibility();

  ProductVisibility.fromJson(core.Map _json) {
    if (_json.containsKey('productId')) {
      productId = _json['productId'] as core.String;
    }
    if (_json.containsKey('trackIds')) {
      trackIds = (_json['trackIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (productId != null) 'productId': productId!,
        if (trackIds != null) 'trackIds': trackIds!,
        if (tracks != null) 'tracks': tracks!,
      };
}

class ProductsApproveRequest {
  /// The approval URL that was shown to the user.
  ///
  /// Only the permissions shown to the user with that URL will be accepted,
  /// which may not be the product's entire set of permissions. For example, the
  /// URL may only display new permissions from an update after the product was
  /// approved, or not include new permissions if the product was updated since
  /// the URL was generated.
  ApprovalUrlInfo? approvalUrlInfo;

  /// Sets how new permission requests for the product are handled.
  ///
  /// "allPermissions" automatically approves all current and future permissions
  /// for the product. "currentPermissionsOnly" approves the current set of
  /// permissions for the product, but any future permissions added through
  /// updates will require manual reapproval. If not specified, only the current
  /// set of permissions will be approved.
  /// Possible string values are:
  /// - "currentPermissionsOnly" : Approve only the permissions the product
  /// requires at approval time. If an update requires additional permissions,
  /// the app will not be updated on devices associated with enterprise users
  /// until the additional permissions are approved.
  /// - "allPermissions" : All current and future permissions the app requires
  /// are automatically approved.
  core.String? approvedPermissions;

  ProductsApproveRequest();

  ProductsApproveRequest.fromJson(core.Map _json) {
    if (_json.containsKey('approvalUrlInfo')) {
      approvalUrlInfo = ApprovalUrlInfo.fromJson(
          _json['approvalUrlInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('approvedPermissions')) {
      approvedPermissions = _json['approvedPermissions'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (approvalUrlInfo != null)
          'approvalUrlInfo': approvalUrlInfo!.toJson(),
        if (approvedPermissions != null)
          'approvedPermissions': approvedPermissions!,
      };
}

class ProductsGenerateApprovalUrlResponse {
  /// A URL that can be rendered in an iframe to display the permissions (if
  /// any) of a product.
  ///
  /// This URL can be used to approve the product only once and only within 24
  /// hours of being generated, using the Products.approve call. If the product
  /// is currently unapproved and has no permissions, this URL will point to an
  /// empty page. If the product is currently approved, a URL will only be
  /// generated if that product has added permissions since it was last
  /// approved, and the URL will only display those new permissions that have
  /// not yet been accepted.
  core.String? url;

  ProductsGenerateApprovalUrlResponse();

  ProductsGenerateApprovalUrlResponse.fromJson(core.Map _json) {
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (url != null) 'url': url!,
      };
}

class ProductsListResponse {
  /// General pagination information.
  PageInfo? pageInfo;

  /// Information about a product (e.g. an app) in the Google Play store, for
  /// display to an enterprise admin.
  core.List<Product>? product;

  /// Pagination information for token pagination.
  TokenPagination? tokenPagination;

  ProductsListResponse();

  ProductsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('pageInfo')) {
      pageInfo = PageInfo.fromJson(
          _json['pageInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('product')) {
      product = (_json['product'] as core.List)
          .map<Product>((value) =>
              Product.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('tokenPagination')) {
      tokenPagination = TokenPagination.fromJson(
          _json['tokenPagination'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pageInfo != null) 'pageInfo': pageInfo!.toJson(),
        if (product != null)
          'product': product!.map((value) => value.toJson()).toList(),
        if (tokenPagination != null)
          'tokenPagination': tokenPagination!.toJson(),
      };
}

/// A service account identity, including the name and credentials that can be
/// used to authenticate as the service account.
class ServiceAccount {
  /// Credentials that can be used to authenticate as this ServiceAccount.
  ServiceAccountKey? key;

  /// The account name of the service account, in the form of an email address.
  ///
  /// Assigned by the server.
  core.String? name;

  ServiceAccount();

  ServiceAccount.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = ServiceAccountKey.fromJson(
          _json['key'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!.toJson(),
        if (name != null) 'name': name!,
      };
}

/// Credentials that can be used to authenticate as a service account.
class ServiceAccountKey {
  /// The body of the private key credentials file, in string format.
  ///
  /// This is only populated when the ServiceAccountKey is created, and is not
  /// stored by Google.
  core.String? data;

  /// An opaque, unique identifier for this ServiceAccountKey.
  ///
  /// Assigned by the server.
  core.String? id;

  /// Public key data for the credentials file.
  ///
  /// This is an X.509 cert. If you are using the googleCredentials key type,
  /// this is identical to the cert that can be retrieved by using the X.509
  /// cert url inside of the credentials file.
  core.String? publicData;

  /// The file format of the generated key data.
  /// Possible string values are:
  /// - "googleCredentials" : Google Credentials File format.
  /// - "pkcs12" : PKCS12 format. The password for the PKCS12 file is
  /// 'notasecret'. For more information, see
  /// https://tools.ietf.org/html/rfc7292. The data for keys of this type are
  /// base64 encoded according to RFC 4648 Section 4. See
  /// http://tools.ietf.org/html/rfc4648#section-4.
  core.String? type;

  ServiceAccountKey();

  ServiceAccountKey.fromJson(core.Map _json) {
    if (_json.containsKey('data')) {
      data = _json['data'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('publicData')) {
      publicData = _json['publicData'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (data != null) 'data': data!,
        if (id != null) 'id': id!,
        if (publicData != null) 'publicData': publicData!,
        if (type != null) 'type': type!,
      };
}

class ServiceAccountKeysListResponse {
  /// The service account credentials.
  core.List<ServiceAccountKey>? serviceAccountKey;

  ServiceAccountKeysListResponse();

  ServiceAccountKeysListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('serviceAccountKey')) {
      serviceAccountKey = (_json['serviceAccountKey'] as core.List)
          .map<ServiceAccountKey>((value) => ServiceAccountKey.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (serviceAccountKey != null)
          'serviceAccountKey':
              serviceAccountKey!.map((value) => value.toJson()).toList(),
      };
}

/// A resource returned by the GenerateSignupUrl API, which contains the Signup
/// URL and Completion Token.
class SignupInfo {
  /// An opaque token that will be required, along with the Enterprise Token,
  /// for obtaining the enterprise resource from CompleteSignup.
  core.String? completionToken;

  /// Deprecated.
  core.String? kind;

  /// A URL under which the Admin can sign up for an enterprise.
  ///
  /// The page pointed to cannot be rendered in an iframe.
  core.String? url;

  SignupInfo();

  SignupInfo.fromJson(core.Map _json) {
    if (_json.containsKey('completionToken')) {
      completionToken = _json['completionToken'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (completionToken != null) 'completionToken': completionToken!,
        if (kind != null) 'kind': kind!,
        if (url != null) 'url': url!,
      };
}

/// Definition of a managed Google Play store cluster, a list of products
/// displayed as part of a store page.
class StoreCluster {
  /// Unique ID of this cluster.
  ///
  /// Assigned by the server. Immutable once assigned.
  core.String? id;

  /// Ordered list of localized strings giving the name of this page.
  ///
  /// The text displayed is the one that best matches the user locale, or the
  /// first entry if there is no good match. There needs to be at least one
  /// entry.
  core.List<LocalizedText>? name;

  /// String (US-ASCII only) used to determine order of this cluster within the
  /// parent page's elements.
  ///
  /// Page elements are sorted in lexicographic order of this field. Duplicated
  /// values are allowed, but ordering between elements with duplicate order is
  /// undefined. The value of this field is never visible to a user, it is used
  /// solely for the purpose of defining an ordering. Maximum length is 256
  /// characters.
  core.String? orderInPage;

  /// List of products in the order they are displayed in the cluster.
  ///
  /// There should not be duplicates within a cluster.
  core.List<core.String>? productId;

  StoreCluster();

  StoreCluster.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = (_json['name'] as core.List)
          .map<LocalizedText>((value) => LocalizedText.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('orderInPage')) {
      orderInPage = _json['orderInPage'] as core.String;
    }
    if (_json.containsKey('productId')) {
      productId = (_json['productId'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (name != null) 'name': name!.map((value) => value.toJson()).toList(),
        if (orderInPage != null) 'orderInPage': orderInPage!,
        if (productId != null) 'productId': productId!,
      };
}

/// General setting for the managed Google Play store layout, currently only
/// specifying the page to display the first time the store is opened.
class StoreLayout {
  /// The ID of the store page to be used as the homepage.
  ///
  /// The homepage is the first page shown in the managed Google Play Store. Not
  /// specifying a homepage is equivalent to setting the store layout type to
  /// "basic".
  core.String? homepageId;

  /// The store layout type.
  ///
  /// By default, this value is set to "basic" if the homepageId field is not
  /// set, and to "custom" otherwise. If set to "basic", the layout will consist
  /// of all approved apps that have been whitelisted for the user.
  /// Possible string values are:
  /// - "unknown"
  /// - "basic"
  /// - "custom"
  core.String? storeLayoutType;

  StoreLayout();

  StoreLayout.fromJson(core.Map _json) {
    if (_json.containsKey('homepageId')) {
      homepageId = _json['homepageId'] as core.String;
    }
    if (_json.containsKey('storeLayoutType')) {
      storeLayoutType = _json['storeLayoutType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (homepageId != null) 'homepageId': homepageId!,
        if (storeLayoutType != null) 'storeLayoutType': storeLayoutType!,
      };
}

class StoreLayoutClustersListResponse {
  /// A store cluster of an enterprise.
  core.List<StoreCluster>? cluster;

  StoreLayoutClustersListResponse();

  StoreLayoutClustersListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('cluster')) {
      cluster = (_json['cluster'] as core.List)
          .map<StoreCluster>((value) => StoreCluster.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cluster != null)
          'cluster': cluster!.map((value) => value.toJson()).toList(),
      };
}

class StoreLayoutPagesListResponse {
  /// A store page of an enterprise.
  core.List<StorePage>? page;

  StoreLayoutPagesListResponse();

  StoreLayoutPagesListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('page')) {
      page = (_json['page'] as core.List)
          .map<StorePage>((value) =>
              StorePage.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (page != null) 'page': page!.map((value) => value.toJson()).toList(),
      };
}

/// Definition of a managed Google Play store page, made of a localized name and
/// links to other pages.
///
/// A page also contains clusters defined as a subcollection.
class StorePage {
  /// Unique ID of this page.
  ///
  /// Assigned by the server. Immutable once assigned.
  core.String? id;

  /// Ordered list of pages a user should be able to reach from this page.
  ///
  /// The list can't include this page. It is recommended that the basic pages
  /// are created first, before adding the links between pages. The API doesn't
  /// verify that the pages exist or the pages are reachable.
  core.List<core.String>? link;

  /// Ordered list of localized strings giving the name of this page.
  ///
  /// The text displayed is the one that best matches the user locale, or the
  /// first entry if there is no good match. There needs to be at least one
  /// entry.
  core.List<LocalizedText>? name;

  StorePage();

  StorePage.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('link')) {
      link = (_json['link'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('name')) {
      name = (_json['name'] as core.List)
          .map<LocalizedText>((value) => LocalizedText.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (link != null) 'link': link!,
        if (name != null) 'name': name!.map((value) => value.toJson()).toList(),
      };
}

/// Pagination information returned by a List operation when token pagination is
/// enabled.
///
/// List operations that supports paging return only one "page" of results. This
/// protocol buffer message describes the page that has been returned. When
/// using token pagination, clients should use the next/previous token to get
/// another page of the result. The presence or absence of next/previous token
/// indicates whether a next/previous page is available and provides a mean of
/// accessing this page. ListRequest.page_token should be set to either
/// next_page_token or previous_page_token to access another page.
class TokenPagination {
  /// Tokens to pass to the standard list field 'page_token'.
  ///
  /// Whenever available, tokens are preferred over manipulating start_index.
  core.String? nextPageToken;
  core.String? previousPageToken;

  TokenPagination();

  TokenPagination.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('previousPageToken')) {
      previousPageToken = _json['previousPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (previousPageToken != null) 'previousPageToken': previousPageToken!,
      };
}

/// Id to name association of a track.
class TrackInfo {
  /// A modifiable name for a track.
  ///
  /// This is the visible name in the play developer console.
  core.String? trackAlias;

  /// Unmodifiable, unique track identifier.
  ///
  /// This identifier is the releaseTrackId in the url of the play developer
  /// console page that displays the track information.
  core.String? trackId;

  TrackInfo();

  TrackInfo.fromJson(core.Map _json) {
    if (_json.containsKey('trackAlias')) {
      trackAlias = _json['trackAlias'] as core.String;
    }
    if (_json.containsKey('trackId')) {
      trackId = _json['trackId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (trackAlias != null) 'trackAlias': trackAlias!,
        if (trackId != null) 'trackId': trackId!,
      };
}

/// A Users resource represents an account associated with an enterprise.
///
/// The account may be specific to a device or to an individual user (who can
/// then use the account across multiple devices). The account may provide
/// access to managed Google Play only, or to other Google services, depending
/// on the identity model: - The Google managed domain identity model requires
/// synchronization to Google account sources (via primaryEmail). - The managed
/// Google Play Accounts identity model provides a dynamic means for enterprises
/// to create user or device accounts as needed. These accounts provide access
/// to managed Google Play.
class User {
  /// A unique identifier you create for this user, such as "user342" or
  /// "asset#44418".
  ///
  /// Do not use personally identifiable information (PII) for this property.
  /// Must always be set for EMM-managed users. Not set for Google-managed
  /// users.
  core.String? accountIdentifier;

  /// The type of account that this user represents.
  ///
  /// A userAccount can be installed on multiple devices, but a deviceAccount is
  /// specific to a single device. An EMM-managed user (emmManaged) can be
  /// either type (userAccount, deviceAccount), but a Google-managed user
  /// (googleManaged) is always a userAccount.
  /// Possible string values are:
  /// - "deviceAccount"
  /// - "userAccount"
  core.String? accountType;

  /// The name that will appear in user interfaces.
  ///
  /// Setting this property is optional when creating EMM-managed users. If you
  /// do set this property, use something generic about the organization (such
  /// as "Example, Inc.") or your name (as EMM). Not used for Google-managed
  /// user accounts. @mutable androidenterprise.users.update
  core.String? displayName;

  /// The unique ID for the user.
  core.String? id;

  /// The entity that manages the user.
  ///
  /// With googleManaged users, the source of truth is Google so EMMs have to
  /// make sure a Google Account exists for the user. With emmManaged users, the
  /// EMM is in charge.
  /// Possible string values are:
  /// - "googleManaged"
  /// - "emmManaged"
  core.String? managementType;

  /// The user's primary email address, for example, "jsmith@example.com".
  ///
  /// Will always be set for Google managed users and not set for EMM managed
  /// users.
  core.String? primaryEmail;

  User();

  User.fromJson(core.Map _json) {
    if (_json.containsKey('accountIdentifier')) {
      accountIdentifier = _json['accountIdentifier'] as core.String;
    }
    if (_json.containsKey('accountType')) {
      accountType = _json['accountType'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('managementType')) {
      managementType = _json['managementType'] as core.String;
    }
    if (_json.containsKey('primaryEmail')) {
      primaryEmail = _json['primaryEmail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountIdentifier != null) 'accountIdentifier': accountIdentifier!,
        if (accountType != null) 'accountType': accountType!,
        if (displayName != null) 'displayName': displayName!,
        if (id != null) 'id': id!,
        if (managementType != null) 'managementType': managementType!,
        if (primaryEmail != null) 'primaryEmail': primaryEmail!,
      };
}

class UsersListResponse {
  /// A user of an enterprise.
  core.List<User>? user;

  UsersListResponse();

  UsersListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('user')) {
      user = (_json['user'] as core.List)
          .map<User>((value) =>
              User.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (user != null) 'user': user!.map((value) => value.toJson()).toList(),
      };
}

/// A variable set is a key-value pair of EMM-provided placeholders and its
/// corresponding value, which is attributed to a user.
///
/// For example, $FIRSTNAME could be a placeholder, and its value could be
/// Alice. Placeholders should start with a '$' sign and should be alphanumeric
/// only.
class VariableSet {
  /// The placeholder string; defined by EMM.
  core.String? placeholder;

  /// The value of the placeholder, specific to the user.
  core.String? userValue;

  VariableSet();

  VariableSet.fromJson(core.Map _json) {
    if (_json.containsKey('placeholder')) {
      placeholder = _json['placeholder'] as core.String;
    }
    if (_json.containsKey('userValue')) {
      userValue = _json['userValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (placeholder != null) 'placeholder': placeholder!,
        if (userValue != null) 'userValue': userValue!,
      };
}

/// A WebApps resource represents a web app created for an enterprise.
///
/// Web apps are published to managed Google Play and can be distributed like
/// other Android apps. On a user's device, a web app opens its specified URL.
class WebApp {
  /// The display mode of the web app.
  ///
  /// Possible values include: - "minimalUi", the device's status bar,
  /// navigation bar, the app's URL, and a refresh button are visible when the
  /// app is open. For HTTP URLs, you can only select this option. -
  /// "standalone", the device's status bar and navigation bar are visible when
  /// the app is open. - "fullScreen", the app opens in full screen mode, hiding
  /// the device's status and navigation bars. All browser UI elements, page
  /// URL, system status bar and back button are not visible, and the web app
  /// takes up the entirety of the available display area.
  /// Possible string values are:
  /// - "displayModeUnspecified"
  /// - "minimalUi" : Opens the web app with a minimal set of browser UI
  /// elements for controlling navigation and viewing the page URL.
  /// - "standalone" : Opens the web app to look and feel like a standalone
  /// native application. The browser UI elements and page URL are not visible,
  /// however the system status bar and back button are visible.
  /// - "fullScreen" : Opens the web app in full screen without any visible
  /// controls. The browser UI elements, page URL, system status bar and back
  /// button are not visible, and the web app takes up the entirety of the
  /// available display area.
  core.String? displayMode;

  /// A list of icons representing this website.
  ///
  /// If absent, a default icon (for create) or the current icon (for update)
  /// will be used.
  core.List<WebAppIcon>? icons;

  /// A flag whether the app has been published to the Play store yet.
  core.bool? isPublished;

  /// The start URL, i.e. the URL that should load when the user opens the
  /// application.
  core.String? startUrl;

  /// The title of the web app as displayed to the user (e.g., amongst a list of
  /// other applications, or as a label for an icon).
  core.String? title;

  /// The current version of the app.
  ///
  /// Note that the version can automatically increase during the lifetime of
  /// the web app, while Google does internal housekeeping to keep the web app
  /// up-to-date.
  core.String? versionCode;

  /// The ID of the application.
  ///
  /// A string of the form "app:<package name>" where the package name always
  /// starts with the prefix "com.google.enterprise.webapp." followed by a
  /// random id.
  core.String? webAppId;

  WebApp();

  WebApp.fromJson(core.Map _json) {
    if (_json.containsKey('displayMode')) {
      displayMode = _json['displayMode'] as core.String;
    }
    if (_json.containsKey('icons')) {
      icons = (_json['icons'] as core.List)
          .map<WebAppIcon>((value) =>
              WebAppIcon.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('isPublished')) {
      isPublished = _json['isPublished'] as core.bool;
    }
    if (_json.containsKey('startUrl')) {
      startUrl = _json['startUrl'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('versionCode')) {
      versionCode = _json['versionCode'] as core.String;
    }
    if (_json.containsKey('webAppId')) {
      webAppId = _json['webAppId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayMode != null) 'displayMode': displayMode!,
        if (icons != null)
          'icons': icons!.map((value) => value.toJson()).toList(),
        if (isPublished != null) 'isPublished': isPublished!,
        if (startUrl != null) 'startUrl': startUrl!,
        if (title != null) 'title': title!,
        if (versionCode != null) 'versionCode': versionCode!,
        if (webAppId != null) 'webAppId': webAppId!,
      };
}

/// Icon for a web app.
class WebAppIcon {
  /// The actual bytes of the image in a base64url encoded string (c.f. RFC4648,
  /// section 5 "Base 64 Encoding with URL and Filename Safe Alphabet").
  ///
  /// - The image type can be png or jpg. - The image should ideally be square.
  /// - The image should ideally have a size of 512x512.
  core.String? imageData;

  WebAppIcon();

  WebAppIcon.fromJson(core.Map _json) {
    if (_json.containsKey('imageData')) {
      imageData = _json['imageData'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (imageData != null) 'imageData': imageData!,
      };
}

class WebAppsListResponse {
  /// The manifest describing a web app.
  core.List<WebApp>? webApp;

  WebAppsListResponse();

  WebAppsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('webApp')) {
      webApp = (_json['webApp'] as core.List)
          .map<WebApp>((value) =>
              WebApp.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (webApp != null)
          'webApp': webApp!.map((value) => value.toJson()).toList(),
      };
}

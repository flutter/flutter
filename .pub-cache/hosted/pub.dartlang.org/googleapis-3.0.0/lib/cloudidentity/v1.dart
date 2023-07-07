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

/// Cloud Identity API - v1
///
/// API for provisioning and managing identity resources.
///
/// For more information, see <https://cloud.google.com/identity/>
///
/// Create an instance of [CloudIdentityApi] to access these resources:
///
/// - [DevicesResource]
///   - [DevicesDeviceUsersResource]
///     - [DevicesDeviceUsersClientStatesResource]
/// - [GroupsResource]
///   - [GroupsMembershipsResource]
library cloudidentity.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// API for provisioning and managing identity resources.
class CloudIdentityApi {
  /// See your device details
  static const cloudIdentityDevicesLookupScope =
      'https://www.googleapis.com/auth/cloud-identity.devices.lookup';

  /// See, change, create, and delete any of the Cloud Identity Groups that you
  /// can access, including the members of each group
  static const cloudIdentityGroupsScope =
      'https://www.googleapis.com/auth/cloud-identity.groups';

  /// See any Cloud Identity Groups that you can access, including group members
  /// and their emails
  static const cloudIdentityGroupsReadonlyScope =
      'https://www.googleapis.com/auth/cloud-identity.groups.readonly';

  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  DevicesResource get devices => DevicesResource(_requester);
  GroupsResource get groups => GroupsResource(_requester);

  CloudIdentityApi(http.Client client,
      {core.String rootUrl = 'https://cloudidentity.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class DevicesResource {
  final commons.ApiRequester _requester;

  DevicesDeviceUsersResource get deviceUsers =>
      DevicesDeviceUsersResource(_requester);

  DevicesResource(commons.ApiRequester client) : _requester = client;

  /// Cancels an unfinished device wipe.
  ///
  /// This operation can be used to cancel device wipe in the gap between the
  /// wipe operation returning success and the device being wiped. This
  /// operation is possible when the device is in a "pending wipe" state. The
  /// device enters the "pending wipe" state when a wipe device command is
  /// issued, but has not yet been sent to the device. The cancel wipe will fail
  /// if the wipe command has already been issued to the device.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the Device in format: `devices/{device_id}`, where device_id is the unique
  /// ID assigned to the Device.
  /// Value must have pattern `^devices/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> cancelWipe(
    GoogleAppsCloudidentityDevicesV1CancelWipeDeviceRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':cancelWipe';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a device.
  ///
  /// Only company-owned device may be created. **Note**: This method is
  /// available only to customers who have one of the following SKUs: Enterprise
  /// Standard, Enterprise Plus, Enterprise for Education, and Cloud Identity
  /// Premium
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [customer] - Optional.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer. If you're using this API for your own organization, use
  /// `customers/my_customer` If you're using this API to manage another
  /// organization, use `customers/{customer_id}`, where customer_id is the
  /// customer to whom the device belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> create(
    GoogleAppsCloudidentityDevicesV1Device request, {
    core.String? customer,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (customer != null) 'customer': [customer],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/devices';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified device.
  ///
  /// Request parameters:
  ///
  /// [name] - Required.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the Device in format: `devices/{device_id}`, where device_id is the unique
  /// ID assigned to the Device.
  /// Value must have pattern `^devices/\[^/\]+$`.
  ///
  /// [customer] - Optional.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer. If you're using this API for your own organization, use
  /// `customers/my_customer` If you're using this API to manage another
  /// organization, use `customers/{customer_id}`, where customer_id is the
  /// customer to whom the device belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> delete(
    core.String name, {
    core.String? customer,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customer != null) 'customer': [customer],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified device.
  ///
  /// Request parameters:
  ///
  /// [name] - Required.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the Device in the format: `devices/{device_id}`, where device_id is the
  /// unique ID assigned to the Device.
  /// Value must have pattern `^devices/\[^/\]+$`.
  ///
  /// [customer] - Optional.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the Customer in the format: `customers/{customer_id}`, where customer_id
  /// is the customer to whom the device belongs. If you're using this API for
  /// your own organization, use `customers/my_customer`. If you're using this
  /// API to manage another organization, use `customers/{customer_id}`, where
  /// customer_id is the customer to whom the device belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleAppsCloudidentityDevicesV1Device].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleAppsCloudidentityDevicesV1Device> get(
    core.String name, {
    core.String? customer,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customer != null) 'customer': [customer],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleAppsCloudidentityDevicesV1Device.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists/Searches devices.
  ///
  /// Request parameters:
  ///
  /// [customer] - Optional.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer in the format: `customers/{customer_id}`, where customer_id
  /// is the customer to whom the device belongs. If you're using this API for
  /// your own organization, use `customers/my_customer`. If you're using this
  /// API to manage another organization, use `customers/{customer_id}`, where
  /// customer_id is the customer to whom the device belongs.
  ///
  /// [filter] - Optional. Additional restrictions when fetching list of
  /// devices. For a list of search fields, refer to
  /// [Mobile device search fields](https://developers.google.com/admin-sdk/directory/v1/search-operators).
  /// Multiple search fields are separated by the space character.
  ///
  /// [orderBy] - Optional. Order specification for devices in the response.
  /// Only one of the following field names may be used to specify the order:
  /// `create_time`, `last_sync_time`, `model`, `os_version`, `device_type` and
  /// `serial_number`. `desc` may be specified optionally at the end to specify
  /// results to be sorted in descending order. Default order is ascending.
  ///
  /// [pageSize] - Optional. The maximum number of Devices to return. If
  /// unspecified, at most 20 Devices will be returned. The maximum value is
  /// 100; values above 100 will be coerced to 100.
  ///
  /// [pageToken] - Optional. A page token, received from a previous
  /// `ListDevices` call. Provide this to retrieve the subsequent page. When
  /// paginating, all other parameters provided to `ListDevices` must match the
  /// call that provided the page token.
  ///
  /// [view] - Optional. The view to use for the List request.
  /// Possible string values are:
  /// - "VIEW_UNSPECIFIED" : Default value. The value is unused.
  /// - "COMPANY_INVENTORY" : This view contains all devices imported by the
  /// company admin. Each device in the response contains all information
  /// specified by the company admin when importing the device (i.e. asset
  /// tags). This includes devices that may be unaassigned or assigned to users.
  /// - "USER_ASSIGNED_DEVICES" : This view contains all devices with at least
  /// one user registered on the device. Each device in the response contains
  /// all device information, except for asset tags.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleAppsCloudidentityDevicesV1ListDevicesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleAppsCloudidentityDevicesV1ListDevicesResponse> list({
    core.String? customer,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customer != null) 'customer': [customer],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/devices';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleAppsCloudidentityDevicesV1ListDevicesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Wipes all data on the specified device.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the Device in format: `devices/{device_id}/deviceUsers/{device_user_id}`,
  /// where device_id is the unique ID assigned to the Device, and
  /// device_user_id is the unique ID assigned to the User.
  /// Value must have pattern `^devices/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> wipe(
    GoogleAppsCloudidentityDevicesV1WipeDeviceRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':wipe';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class DevicesDeviceUsersResource {
  final commons.ApiRequester _requester;

  DevicesDeviceUsersClientStatesResource get clientStates =>
      DevicesDeviceUsersClientStatesResource(_requester);

  DevicesDeviceUsersResource(commons.ApiRequester client) : _requester = client;

  /// Approves device to access user data.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the Device in format: `devices/{device_id}/deviceUsers/{device_user_id}`,
  /// where device_id is the unique ID assigned to the Device, and
  /// device_user_id is the unique ID assigned to the User.
  /// Value must have pattern `^devices/\[^/\]+/deviceUsers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> approve(
    GoogleAppsCloudidentityDevicesV1ApproveDeviceUserRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':approve';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Blocks device from accessing user data
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the Device in format: `devices/{device_id}/deviceUsers/{device_user_id}`,
  /// where device_id is the unique ID assigned to the Device, and
  /// device_user_id is the unique ID assigned to the User.
  /// Value must have pattern `^devices/\[^/\]+/deviceUsers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> block(
    GoogleAppsCloudidentityDevicesV1BlockDeviceUserRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':block';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Cancels an unfinished user account wipe.
  ///
  /// This operation can be used to cancel device wipe in the gap between the
  /// wipe operation returning success and the device being wiped.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the Device in format: `devices/{device_id}/deviceUsers/{device_user_id}`,
  /// where device_id is the unique ID assigned to the Device, and
  /// device_user_id is the unique ID assigned to the User.
  /// Value must have pattern `^devices/\[^/\]+/deviceUsers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> cancelWipe(
    GoogleAppsCloudidentityDevicesV1CancelWipeDeviceUserRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':cancelWipe';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified DeviceUser.
  ///
  /// This also revokes the user's access to device data.
  ///
  /// Request parameters:
  ///
  /// [name] - Required.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the Device in format: `devices/{device_id}/deviceUsers/{device_user_id}`,
  /// where device_id is the unique ID assigned to the Device, and
  /// device_user_id is the unique ID assigned to the User.
  /// Value must have pattern `^devices/\[^/\]+/deviceUsers/\[^/\]+$`.
  ///
  /// [customer] - Optional.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer. If you're using this API for your own organization, use
  /// `customers/my_customer` If you're using this API to manage another
  /// organization, use `customers/{customer_id}`, where customer_id is the
  /// customer to whom the device belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> delete(
    core.String name, {
    core.String? customer,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customer != null) 'customer': [customer],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified DeviceUser
  ///
  /// Request parameters:
  ///
  /// [name] - Required.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the Device in format: `devices/{device_id}/deviceUsers/{device_user_id}`,
  /// where device_id is the unique ID assigned to the Device, and
  /// device_user_id is the unique ID assigned to the User.
  /// Value must have pattern `^devices/\[^/\]+/deviceUsers/\[^/\]+$`.
  ///
  /// [customer] - Optional.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer. If you're using this API for your own organization, use
  /// `customers/my_customer` If you're using this API to manage another
  /// organization, use `customers/{customer_id}`, where customer_id is the
  /// customer to whom the device belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleAppsCloudidentityDevicesV1DeviceUser].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleAppsCloudidentityDevicesV1DeviceUser> get(
    core.String name, {
    core.String? customer,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customer != null) 'customer': [customer],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleAppsCloudidentityDevicesV1DeviceUser.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists/Searches DeviceUsers.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. To list all DeviceUsers, set this to "devices/-". To
  /// list all DeviceUsers owned by a device, set this to the resource name of
  /// the device. Format: devices/{device}
  /// Value must have pattern `^devices/\[^/\]+$`.
  ///
  /// [customer] - Optional.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer. If you're using this API for your own organization, use
  /// `customers/my_customer` If you're using this API to manage another
  /// organization, use `customers/{customer_id}`, where customer_id is the
  /// customer to whom the device belongs.
  ///
  /// [filter] - Optional. Additional restrictions when fetching list of
  /// devices. For a list of search fields, refer to
  /// [Mobile device search fields](https://developers.google.com/admin-sdk/directory/v1/search-operators).
  /// Multiple search fields are separated by the space character.
  ///
  /// [orderBy] - Optional. Order specification for devices in the response.
  ///
  /// [pageSize] - Optional. The maximum number of DeviceUsers to return. If
  /// unspecified, at most 5 DeviceUsers will be returned. The maximum value is
  /// 20; values above 20 will be coerced to 20.
  ///
  /// [pageToken] - Optional. A page token, received from a previous
  /// `ListDeviceUsers` call. Provide this to retrieve the subsequent page. When
  /// paginating, all other parameters provided to `ListBooks` must match the
  /// call that provided the page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleAppsCloudidentityDevicesV1ListDeviceUsersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleAppsCloudidentityDevicesV1ListDeviceUsersResponse> list(
    core.String parent, {
    core.String? customer,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customer != null) 'customer': [customer],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/deviceUsers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleAppsCloudidentityDevicesV1ListDeviceUsersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Looks up resource names of the DeviceUsers associated with the caller's
  /// credentials, as well as the properties provided in the request.
  ///
  /// This method must be called with end-user credentials with the scope:
  /// https://www.googleapis.com/auth/cloud-identity.devices.lookup If multiple
  /// properties are provided, only DeviceUsers having all of these properties
  /// are considered as matches - i.e. the query behaves like an AND. Different
  /// platforms require different amounts of information from the caller to
  /// ensure that the DeviceUser is uniquely identified. - iOS: No properties
  /// need to be passed, the caller's credentials are sufficient to identify the
  /// corresponding DeviceUser. - Android: Specifying the 'android_id' field is
  /// required. - Desktop: Specifying the 'raw_resource_id' field is required.
  ///
  /// Request parameters:
  ///
  /// [parent] - Must be set to "devices/-/deviceUsers" to search across all
  /// DeviceUser belonging to the user.
  /// Value must have pattern `^devices/\[^/\]+/deviceUsers$`.
  ///
  /// [androidId] - Android Id returned by
  /// \[Settings.Secure#ANDROID_ID\](https://developer.android.com/reference/android/provider/Settings.Secure.html#ANDROID_ID).
  ///
  /// [pageSize] - The maximum number of DeviceUsers to return. If unspecified,
  /// at most 20 DeviceUsers will be returned. The maximum value is 20; values
  /// above 20 will be coerced to 20.
  ///
  /// [pageToken] - A page token, received from a previous `LookupDeviceUsers`
  /// call. Provide this to retrieve the subsequent page. When paginating, all
  /// other parameters provided to `LookupDeviceUsers` must match the call that
  /// provided the page token.
  ///
  /// [rawResourceId] - Raw Resource Id used by Google Endpoint Verification. If
  /// the user is enrolled into Google Endpoint Verification, this id will be
  /// saved as the 'device_resource_id' field in the following platform
  /// dependent files. Mac: ~/.secureConnect/context_aware_config.json Windows:
  /// C:\Users\%USERPROFILE%\.secureConnect\context_aware_config.json Linux:
  /// ~/.secureConnect/context_aware_config.json
  ///
  /// [userId] - The user whose DeviceUser's resource name will be fetched. Must
  /// be set to 'me' to fetch the DeviceUser's resource name for the calling
  /// user.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleAppsCloudidentityDevicesV1LookupSelfDeviceUsersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleAppsCloudidentityDevicesV1LookupSelfDeviceUsersResponse>
      lookup(
    core.String parent, {
    core.String? androidId,
    core.int? pageSize,
    core.String? pageToken,
    core.String? rawResourceId,
    core.String? userId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (androidId != null) 'androidId': [androidId],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (rawResourceId != null) 'rawResourceId': [rawResourceId],
      if (userId != null) 'userId': [userId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + ':lookup';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleAppsCloudidentityDevicesV1LookupSelfDeviceUsersResponse
        .fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Wipes the user's account on a device.
  ///
  /// Other data on the device that is not associated with the user's work
  /// account is not affected. For example, if a Gmail app is installed on a
  /// device that is used for personal and work purposes, and the user is logged
  /// in to the Gmail app with their personal account as well as their work
  /// account, wiping the "deviceUser" by their work administrator will not
  /// affect their personal account within Gmail or other apps such as Photos.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the Device in format: `devices/{device_id}/deviceUsers/{device_user_id}`,
  /// where device_id is the unique ID assigned to the Device, and
  /// device_user_id is the unique ID assigned to the User.
  /// Value must have pattern `^devices/\[^/\]+/deviceUsers/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> wipe(
    GoogleAppsCloudidentityDevicesV1WipeDeviceUserRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':wipe';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class DevicesDeviceUsersClientStatesResource {
  final commons.ApiRequester _requester;

  DevicesDeviceUsersClientStatesResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets the client state for the device user
  ///
  /// Request parameters:
  ///
  /// [name] - Required.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the ClientState in format:
  /// `devices/{device_id}/deviceUsers/{device_user_id}/clientStates/{partner_id}`,
  /// where `device_id` is the unique ID assigned to the Device,
  /// `device_user_id` is the unique ID assigned to the User and `partner_id`
  /// identifies the partner storing the data. To get the client state for
  /// devices belonging to your own organization, the `partnerId` is in the
  /// format: `customerId-*anystring*`. Where the `customerId` is your
  /// organization's customer ID and `anystring` is any suffix. This suffix is
  /// used in setting up Custom Access Levels in Context-Aware Access. You may
  /// use `my_customer` instead of the customer ID for devices managed by your
  /// own organization. You may specify `-` in place of the `{device_id}`, so
  /// the ClientState resource name can be:
  /// `devices/-/deviceUsers/{device_user_resource_id}/clientStates/{partner_id}`.
  /// Value must have pattern
  /// `^devices/\[^/\]+/deviceUsers/\[^/\]+/clientStates/\[^/\]+$`.
  ///
  /// [customer] - Optional.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer. If you're using this API for your own organization, use
  /// `customers/my_customer` If you're using this API to manage another
  /// organization, use `customers/{customer_id}`, where customer_id is the
  /// customer to whom the device belongs.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleAppsCloudidentityDevicesV1ClientState].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleAppsCloudidentityDevicesV1ClientState> get(
    core.String name, {
    core.String? customer,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customer != null) 'customer': [customer],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleAppsCloudidentityDevicesV1ClientState.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the client states for the given search query.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. To list all ClientStates, set this to
  /// "devices/-/deviceUsers/-". To list all ClientStates owned by a DeviceUser,
  /// set this to the resource name of the DeviceUser. Format:
  /// devices/{device}/deviceUsers/{deviceUser}
  /// Value must have pattern `^devices/\[^/\]+/deviceUsers/\[^/\]+$`.
  ///
  /// [customer] - Optional.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer. If you're using this API for your own organization, use
  /// `customers/my_customer` If you're using this API to manage another
  /// organization, use `customers/{customer_id}`, where customer_id is the
  /// customer to whom the device belongs.
  ///
  /// [filter] - Optional. Additional restrictions when fetching list of client
  /// states.
  ///
  /// [orderBy] - Optional. Order specification for client states in the
  /// response.
  ///
  /// [pageToken] - Optional. A page token, received from a previous
  /// `ListClientStates` call. Provide this to retrieve the subsequent page.
  /// When paginating, all other parameters provided to `ListClientStates` must
  /// match the call that provided the page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleAppsCloudidentityDevicesV1ListClientStatesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleAppsCloudidentityDevicesV1ListClientStatesResponse> list(
    core.String parent, {
    core.String? customer,
    core.String? filter,
    core.String? orderBy,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customer != null) 'customer': [customer],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/clientStates';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleAppsCloudidentityDevicesV1ListClientStatesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the client state for the device user **Note**: This method is
  /// available only to customers who have one of the following SKUs: Enterprise
  /// Standard, Enterprise Plus, Enterprise for Education, and Cloud Identity
  /// Premium
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the ClientState in format:
  /// `devices/{device_id}/deviceUsers/{device_user_id}/clientState/{partner_id}`,
  /// where partner_id corresponds to the partner storing the data. For partners
  /// belonging to the "BeyondCorp Alliance", this is the partner ID specified
  /// to you by Google. For all other callers, this is a string of the form:
  /// `{customer_id}-suffix`, where `customer_id` is your customer ID. The
  /// *suffix* is any string the caller specifies. This string will be displayed
  /// verbatim in the administration console. This suffix is used in setting up
  /// Custom Access Levels in Context-Aware Access. Your organization's customer
  /// ID can be obtained from the URL: `GET
  /// https://www.googleapis.com/admin/directory/v1/customers/my_customer` The
  /// `id` field in the response contains the customer ID starting with the
  /// letter 'C'. The customer ID to be used in this API is the string after the
  /// letter 'C' (not including 'C')
  /// Value must have pattern
  /// `^devices/\[^/\]+/deviceUsers/\[^/\]+/clientStates/\[^/\]+$`.
  ///
  /// [customer] - Optional.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer. If you're using this API for your own organization, use
  /// `customers/my_customer` If you're using this API to manage another
  /// organization, use `customers/{customer_id}`, where customer_id is the
  /// customer to whom the device belongs.
  ///
  /// [updateMask] - Optional. Comma-separated list of fully qualified names of
  /// fields to be updated. If not specified, all updatable fields in
  /// ClientState are updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> patch(
    GoogleAppsCloudidentityDevicesV1ClientState request,
    core.String name, {
    core.String? customer,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (customer != null) 'customer': [customer],
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
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class GroupsResource {
  final commons.ApiRequester _requester;

  GroupsMembershipsResource get memberships =>
      GroupsMembershipsResource(_requester);

  GroupsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a Group.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [initialGroupConfig] - Optional. The initial configuration option for the
  /// `Group`.
  /// Possible string values are:
  /// - "INITIAL_GROUP_CONFIG_UNSPECIFIED" : Default. Should not be used.
  /// - "WITH_INITIAL_OWNER" : The end user making the request will be added as
  /// the initial owner of the `Group`.
  /// - "EMPTY" : An empty group is created without any initial owners. This can
  /// only be used by admins of the domain.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> create(
    Group request, {
    core.String? initialGroupConfig,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (initialGroupConfig != null)
        'initialGroupConfig': [initialGroupConfig],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/groups';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a `Group`.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The
  /// [resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the `Group` to retrieve. Must be of the form `groups/{group_id}`.
  /// Value must have pattern `^groups/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> delete(
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
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a `Group`.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The
  /// [resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the `Group` to retrieve. Must be of the form `groups/{group_id}`.
  /// Value must have pattern `^groups/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Group].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Group> get(
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
    return Group.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the `Group` resources under a customer or namespace.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - The maximum number of results to return. Note that the number
  /// of results returned may be less than this value even if there are more
  /// available results. To fetch all results, clients must continue calling
  /// this method repeatedly until the response no longer contains a
  /// `next_page_token`. If unspecified, defaults to 200 for `View.BASIC` and to
  /// 50 for `View.FULL`. Must not be greater than 1000 for `View.BASIC` or 500
  /// for `View.FULL`.
  ///
  /// [pageToken] - The `next_page_token` value returned from a previous list
  /// request, if any.
  ///
  /// [parent] - Required. The parent resource under which to list all `Group`
  /// resources. Must be of the form `identitysources/{identity_source_id}` for
  /// external- identity-mapped groups or `customers/{customer_id}` for Google
  /// Groups. The `customer_id` must begin with "C" (for example, 'C046psxkn').
  ///
  /// [view] - The level of detail to be returned. If unspecified, defaults to
  /// `View.BASIC`.
  /// Possible string values are:
  /// - "VIEW_UNSPECIFIED" : Default. Should not be used.
  /// - "BASIC" : Only basic resource information is returned.
  /// - "FULL" : All resource information is returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListGroupsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListGroupsResponse> list({
    core.int? pageSize,
    core.String? pageToken,
    core.String? parent,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (parent != null) 'parent': [parent],
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/groups';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListGroupsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Looks up the
  /// [resource name](https://cloud.google.com/apis/design/resource_names) of a
  /// `Group` by its `EntityKey`.
  ///
  /// Request parameters:
  ///
  /// [groupKey_id] - The ID of the entity. For Google-managed entities, the
  /// `id` should be the email address of an existing group or user. For
  /// external-identity-mapped entities, the `id` must be a string conforming to
  /// the Identity Source's requirements. Must be unique within a `namespace`.
  ///
  /// [groupKey_namespace] - The namespace in which the entity exists. If not
  /// specified, the \`EntityKey\` represents a Google-managed entity such as a
  /// Google user or a Google Group. If specified, the \`EntityKey\` represents
  /// an external-identity-mapped group. The namespace must correspond to an
  /// identity source created in Admin Console and must be in the form of
  /// \`identitysources/{identity_source_id}.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LookupGroupNameResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LookupGroupNameResponse> lookup({
    core.String? groupKey_id,
    core.String? groupKey_namespace,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (groupKey_id != null) 'groupKey.id': [groupKey_id],
      if (groupKey_namespace != null)
        'groupKey.namespace': [groupKey_namespace],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/groups:lookup';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LookupGroupNameResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a `Group`.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only. The
  /// [resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the `Group`. Shall be of the form `groups/{group_id}`.
  /// Value must have pattern `^groups/\[^/\]+$`.
  ///
  /// [updateMask] - Required. The fully-qualified names of fields to update.
  /// May only contain the following fields: `display_name`, `description`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> patch(
    Group request,
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
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Searches for `Group` resources matching a specified query.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - The maximum number of results to return. Note that the number
  /// of results returned may be less than this value even if there are more
  /// available results. To fetch all results, clients must continue calling
  /// this method repeatedly until the response no longer contains a
  /// `next_page_token`. If unspecified, defaults to 200 for `GroupView.BASIC`
  /// and 50 for `GroupView.FULL`. Must not be greater than 1000 for
  /// `GroupView.BASIC` or 500 for `GroupView.FULL`.
  ///
  /// [pageToken] - The `next_page_token` value returned from a previous search
  /// request, if any.
  ///
  /// [query] - Required. The search query. Must be specified in
  /// [Common Expression Language](https://opensource.google/projects/cel). May
  /// only contain equality operators on the parent and inclusion operators on
  /// labels (e.g., `parent == 'customers/{customer_id}' &&
  /// 'cloudidentity.googleapis.com/groups.discussion_forum' in labels`). The
  /// `customer_id` must begin with "C" (for example, 'C046psxkn').
  ///
  /// [view] - The level of detail to be returned. If unspecified, defaults to
  /// `View.BASIC`.
  /// Possible string values are:
  /// - "VIEW_UNSPECIFIED" : Default. Should not be used.
  /// - "BASIC" : Only basic resource information is returned.
  /// - "FULL" : All resource information is returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchGroupsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchGroupsResponse> search({
    core.int? pageSize,
    core.String? pageToken,
    core.String? query,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (query != null) 'query': [query],
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/groups:search';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SearchGroupsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class GroupsMembershipsResource {
  final commons.ApiRequester _requester;

  GroupsMembershipsResource(commons.ApiRequester client) : _requester = client;

  /// Check a potential member for membership in a group.
  ///
  /// **Note:** This feature is only available to Google Workspace Enterprise
  /// Standard, Enterprise Plus, and Enterprise for Education; and Cloud
  /// Identity Premium accounts. If the account of the member is not one of
  /// these, a 403 (PERMISSION_DENIED) HTTP status code will be returned. A
  /// member has membership to a group as long as there is a single viewable
  /// transitive membership between the group and the member. The actor must
  /// have view permissions to at least one transitive membership between the
  /// member and group.
  ///
  /// Request parameters:
  ///
  /// [parent] -
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the group to check the transitive membership in. Format:
  /// `groups/{group_id}`, where `group_id` is the unique id assigned to the
  /// Group to which the Membership belongs to.
  /// Value must have pattern `^groups/\[^/\]+$`.
  ///
  /// [query] - Required. A CEL expression that MUST include member
  /// specification. This is a `required` field. Certain groups are uniquely
  /// identified by both a 'member_key_id' and a 'member_key_namespace', which
  /// requires an additional query input: 'member_key_namespace'. Example query:
  /// `member_key_id == 'member_key_id_value'`
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CheckTransitiveMembershipResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CheckTransitiveMembershipResponse> checkTransitiveMembership(
    core.String parent, {
    core.String? query,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (query != null) 'query': [query],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$parent') +
        '/memberships:checkTransitiveMembership';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CheckTransitiveMembershipResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a `Membership`.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent `Group` resource under which to create the
  /// `Membership`. Must be of the form `groups/{group_id}`.
  /// Value must have pattern `^groups/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> create(
    Membership request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/memberships';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a `Membership`.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The
  /// [resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the `Membership` to delete. Must be of the form
  /// `groups/{group_id}/memberships/{membership_id}`
  /// Value must have pattern `^groups/\[^/\]+/memberships/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> delete(
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
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a `Membership`.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The
  /// [resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the `Membership` to retrieve. Must be of the form
  /// `groups/{group_id}/memberships/{membership_id}`.
  /// Value must have pattern `^groups/\[^/\]+/memberships/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Membership].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Membership> get(
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
    return Membership.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Get a membership graph of just a member or both a member and a group.
  ///
  /// **Note:** This feature is only available to Google Workspace Enterprise
  /// Standard, Enterprise Plus, and Enterprise for Education; and Cloud
  /// Identity Premium accounts. If the account of the member is not one of
  /// these, a 403 (PERMISSION_DENIED) HTTP status code will be returned. Given
  /// a member, the response will contain all membership paths from the member.
  /// Given both a group and a member, the response will contain all membership
  /// paths between the group and the member.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required.
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the group to search transitive memberships in. Format:
  /// `groups/{group_id}`, where `group_id` is the unique ID assigned to the
  /// Group to which the Membership belongs to. group_id can be a wildcard
  /// collection id "-". When a group_id is specified, the membership graph will
  /// be constrained to paths between the member (defined in the query) and the
  /// parent. If a wildcard collection is provided, all membership paths
  /// connected to the member will be returned.
  /// Value must have pattern `^groups/\[^/\]+$`.
  ///
  /// [query] - Required. A CEL expression that MUST include member
  /// specification AND label(s). Certain groups are uniquely identified by both
  /// a 'member_key_id' and a 'member_key_namespace', which requires an
  /// additional query input: 'member_key_namespace'. Example query:
  /// `member_key_id == 'member_key_id_value' && in labels`
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> getMembershipGraph(
    core.String parent, {
    core.String? query,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (query != null) 'query': [query],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$parent') +
        '/memberships:getMembershipGraph';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the `Membership`s within a `Group`.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent `Group` resource under which to lookup the
  /// `Membership` name. Must be of the form `groups/{group_id}`.
  /// Value must have pattern `^groups/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of results to return. Note that the number
  /// of results returned may be less than this value even if there are more
  /// available results. To fetch all results, clients must continue calling
  /// this method repeatedly until the response no longer contains a
  /// `next_page_token`. If unspecified, defaults to 200 for `GroupView.BASIC`
  /// and to 50 for `GroupView.FULL`. Must not be greater than 1000 for
  /// `GroupView.BASIC` or 500 for `GroupView.FULL`.
  ///
  /// [pageToken] - The `next_page_token` value returned from a previous search
  /// request, if any.
  ///
  /// [view] - The level of detail to be returned. If unspecified, defaults to
  /// `View.BASIC`.
  /// Possible string values are:
  /// - "VIEW_UNSPECIFIED" : Default. Should not be used.
  /// - "BASIC" : Only basic resource information is returned.
  /// - "FULL" : All resource information is returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListMembershipsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListMembershipsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/memberships';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListMembershipsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Looks up the
  /// [resource name](https://cloud.google.com/apis/design/resource_names) of a
  /// `Membership` by its `EntityKey`.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent `Group` resource under which to lookup the
  /// `Membership` name. Must be of the form `groups/{group_id}`.
  /// Value must have pattern `^groups/\[^/\]+$`.
  ///
  /// [memberKey_id] - The ID of the entity. For Google-managed entities, the
  /// `id` should be the email address of an existing group or user. For
  /// external-identity-mapped entities, the `id` must be a string conforming to
  /// the Identity Source's requirements. Must be unique within a `namespace`.
  ///
  /// [memberKey_namespace] - The namespace in which the entity exists. If not
  /// specified, the \`EntityKey\` represents a Google-managed entity such as a
  /// Google user or a Google Group. If specified, the \`EntityKey\` represents
  /// an external-identity-mapped group. The namespace must correspond to an
  /// identity source created in Admin Console and must be in the form of
  /// \`identitysources/{identity_source_id}.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LookupMembershipNameResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LookupMembershipNameResponse> lookup(
    core.String parent, {
    core.String? memberKey_id,
    core.String? memberKey_namespace,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (memberKey_id != null) 'memberKey.id': [memberKey_id],
      if (memberKey_namespace != null)
        'memberKey.namespace': [memberKey_namespace],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/memberships:lookup';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LookupMembershipNameResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Modifies the `MembershipRole`s of a `Membership`.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The
  /// [resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the `Membership` whose roles are to be modified. Must be of the form
  /// `groups/{group_id}/memberships/{membership_id}`.
  /// Value must have pattern `^groups/\[^/\]+/memberships/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ModifyMembershipRolesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ModifyMembershipRolesResponse> modifyMembershipRoles(
    ModifyMembershipRolesRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$name') + ':modifyMembershipRoles';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ModifyMembershipRolesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Search transitive groups of a member.
  ///
  /// **Note:** This feature is only available to Google Workspace Enterprise
  /// Standard, Enterprise Plus, and Enterprise for Education; and Cloud
  /// Identity Premium accounts. If the account of the member is not one of
  /// these, a 403 (PERMISSION_DENIED) HTTP status code will be returned. A
  /// transitive group is any group that has a direct or indirect membership to
  /// the member. Actor must have view permissions all transitive groups.
  ///
  /// Request parameters:
  ///
  /// [parent] -
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the group to search transitive memberships in. Format:
  /// `groups/{group_id}`, where `group_id` is always '-' as this API will
  /// search across all groups for a given member.
  /// Value must have pattern `^groups/\[^/\]+$`.
  ///
  /// [pageSize] - The default page size is 200 (max 1000).
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request, if any.
  ///
  /// [query] - Required. A CEL expression that MUST include member
  /// specification AND label(s). This is a `required` field. Users can search
  /// on label attributes of groups. CONTAINS match ('in') is supported on
  /// labels. Identity-mapped groups are uniquely identified by both a
  /// `member_key_id` and a `member_key_namespace`, which requires an additional
  /// query input: `member_key_namespace`. Example query: `member_key_id ==
  /// 'member_key_id_value' && in labels`
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchTransitiveGroupsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchTransitiveGroupsResponse> searchTransitiveGroups(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? query,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (query != null) 'query': [query],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$parent') +
        '/memberships:searchTransitiveGroups';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SearchTransitiveGroupsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Search transitive memberships of a group.
  ///
  /// **Note:** This feature is only available to Google Workspace Enterprise
  /// Standard, Enterprise Plus, and Enterprise for Education; and Cloud
  /// Identity Premium accounts. If the account of the group is not one of
  /// these, a 403 (PERMISSION_DENIED) HTTP status code will be returned. A
  /// transitive membership is any direct or indirect membership of a group.
  /// Actor must have view permissions to all transitive memberships.
  ///
  /// Request parameters:
  ///
  /// [parent] -
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the group to search transitive memberships in. Format:
  /// `groups/{group_id}`, where `group_id` is the unique ID assigned to the
  /// Group.
  /// Value must have pattern `^groups/\[^/\]+$`.
  ///
  /// [pageSize] - The default page size is 200 (max 1000).
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchTransitiveMembershipsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchTransitiveMembershipsResponse> searchTransitiveMemberships(
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

    final _url = 'v1/' +
        core.Uri.encodeFull('$parent') +
        '/memberships:searchTransitiveMemberships';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SearchTransitiveMembershipsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// The response message for MembershipsService.CheckTransitiveMembership.
class CheckTransitiveMembershipResponse {
  /// Response does not include the possible roles of a member since the
  /// behavior of this rpc is not all-or-nothing unlike the other rpcs.
  ///
  /// So, it may not be possible to list all the roles definitively, due to
  /// possible lack of authorization in some of the paths.
  core.bool? hasMembership;

  CheckTransitiveMembershipResponse();

  CheckTransitiveMembershipResponse.fromJson(core.Map _json) {
    if (_json.containsKey('hasMembership')) {
      hasMembership = _json['hasMembership'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (hasMembership != null) 'hasMembership': hasMembership!,
      };
}

/// Dynamic group metadata like queries and status.
class DynamicGroupMetadata {
  /// Memberships will be the union of all queries.
  ///
  /// Only one entry with USER resource is currently supported. Customers can
  /// create up to 100 dynamic groups.
  core.List<DynamicGroupQuery>? queries;

  /// Status of the dynamic group.
  ///
  /// Output only.
  DynamicGroupStatus? status;

  DynamicGroupMetadata();

  DynamicGroupMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('queries')) {
      queries = (_json['queries'] as core.List)
          .map<DynamicGroupQuery>((value) => DynamicGroupQuery.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('status')) {
      status = DynamicGroupStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (queries != null)
          'queries': queries!.map((value) => value.toJson()).toList(),
        if (status != null) 'status': status!.toJson(),
      };
}

/// Defines a query on a resource.
class DynamicGroupQuery {
  /// Query that determines the memberships of the dynamic group.
  ///
  /// Examples: All users with at least one `organizations.department` of
  /// engineering. `user.organizations.exists(org,
  /// org.department=='engineering')` All users with at least one location that
  /// has `area` of `foo` and `building_id` of `bar`.
  /// `user.locations.exists(loc, loc.area=='foo' && loc.building_id=='bar')`
  core.String? query;

  /// Resource type for the Dynamic Group Query
  /// Possible string values are:
  /// - "RESOURCE_TYPE_UNSPECIFIED" : Default value (not valid)
  /// - "USER" : For queries on User
  core.String? resourceType;

  DynamicGroupQuery();

  DynamicGroupQuery.fromJson(core.Map _json) {
    if (_json.containsKey('query')) {
      query = _json['query'] as core.String;
    }
    if (_json.containsKey('resourceType')) {
      resourceType = _json['resourceType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (query != null) 'query': query!,
        if (resourceType != null) 'resourceType': resourceType!,
      };
}

/// The current status of a dynamic group along with timestamp.
class DynamicGroupStatus {
  /// Status of the dynamic group.
  /// Possible string values are:
  /// - "STATUS_UNSPECIFIED" : Default.
  /// - "UP_TO_DATE" : The dynamic group is up-to-date.
  /// - "UPDATING_MEMBERSHIPS" : The dynamic group has just been created and
  /// memberships are being updated.
  core.String? status;

  /// The latest time at which the dynamic group is guaranteed to be in the
  /// given status.
  ///
  /// If status is `UP_TO_DATE`, the latest time at which the dynamic group was
  /// confirmed to be up-to-date. If status is `UPDATING_MEMBERSHIPS`, the time
  /// at which dynamic group was created.
  core.String? statusTime;

  DynamicGroupStatus();

  DynamicGroupStatus.fromJson(core.Map _json) {
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('statusTime')) {
      statusTime = _json['statusTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (status != null) 'status': status!,
        if (statusTime != null) 'statusTime': statusTime!,
      };
}

/// A unique identifier for an entity in the Cloud Identity Groups API.
///
/// An entity can represent either a group with an optional `namespace` or a
/// user without a `namespace`. The combination of `id` and `namespace` must be
/// unique; however, the same `id` can be used with different `namespace`s.
class EntityKey {
  /// The ID of the entity.
  ///
  /// For Google-managed entities, the `id` should be the email address of an
  /// existing group or user. For external-identity-mapped entities, the `id`
  /// must be a string conforming to the Identity Source's requirements. Must be
  /// unique within a `namespace`.
  core.String? id;

  /// The namespace in which the entity exists.
  ///
  /// If not specified, the \`EntityKey\` represents a Google-managed entity
  /// such as a Google user or a Google Group. If specified, the \`EntityKey\`
  /// represents an external-identity-mapped group. The namespace must
  /// correspond to an identity source created in Admin Console and must be in
  /// the form of \`identitysources/{identity_source_id}.
  core.String? namespace;

  EntityKey();

  EntityKey.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('namespace')) {
      namespace = _json['namespace'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (namespace != null) 'namespace': namespace!,
      };
}

/// The `MembershipRole` expiry details.
class ExpiryDetail {
  /// The time at which the `MembershipRole` will expire.
  core.String? expireTime;

  ExpiryDetail();

  ExpiryDetail.fromJson(core.Map _json) {
    if (_json.containsKey('expireTime')) {
      expireTime = _json['expireTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expireTime != null) 'expireTime': expireTime!,
      };
}

/// The response message for MembershipsService.GetMembershipGraph.
class GetMembershipGraphResponse {
  /// The membership graph's path information represented as an adjacency list.
  core.List<MembershipAdjacencyList>? adjacencyList;

  /// The resources representing each group in the adjacency list.
  ///
  /// Each group in this list can be correlated to a 'group' of the
  /// MembershipAdjacencyList using the 'name' of the Group resource.
  core.List<Group>? groups;

  GetMembershipGraphResponse();

  GetMembershipGraphResponse.fromJson(core.Map _json) {
    if (_json.containsKey('adjacencyList')) {
      adjacencyList = (_json['adjacencyList'] as core.List)
          .map<MembershipAdjacencyList>((value) =>
              MembershipAdjacencyList.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('groups')) {
      groups = (_json['groups'] as core.List)
          .map<Group>((value) =>
              Group.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adjacencyList != null)
          'adjacencyList':
              adjacencyList!.map((value) => value.toJson()).toList(),
        if (groups != null)
          'groups': groups!.map((value) => value.toJson()).toList(),
      };
}

/// Resource representing the Android specific attributes of a Device.
class GoogleAppsCloudidentityDevicesV1AndroidAttributes {
  /// Whether applications from unknown sources can be installed on device.
  core.bool? enabledUnknownSources;

  /// Whether this account is on an owner/primary profile.
  ///
  /// For phones, only true for owner profiles. Android 4+ devices can have
  /// secondary or restricted user profiles.
  core.bool? ownerProfileAccount;

  /// Ownership privileges on device.
  /// Possible string values are:
  /// - "OWNERSHIP_PRIVILEGE_UNSPECIFIED" : Ownership privilege is not set.
  /// - "DEVICE_ADMINISTRATOR" : Active device administrator privileges on the
  /// device.
  /// - "PROFILE_OWNER" : Profile Owner privileges. The account is in a managed
  /// corporate profile.
  /// - "DEVICE_OWNER" : Device Owner privileges on the device.
  core.String? ownershipPrivilege;

  /// Whether device supports Android work profiles.
  ///
  /// If false, this service will not block access to corp data even if an
  /// administrator turns on the "Enforce Work Profile" policy.
  core.bool? supportsWorkProfile;

  GoogleAppsCloudidentityDevicesV1AndroidAttributes();

  GoogleAppsCloudidentityDevicesV1AndroidAttributes.fromJson(core.Map _json) {
    if (_json.containsKey('enabledUnknownSources')) {
      enabledUnknownSources = _json['enabledUnknownSources'] as core.bool;
    }
    if (_json.containsKey('ownerProfileAccount')) {
      ownerProfileAccount = _json['ownerProfileAccount'] as core.bool;
    }
    if (_json.containsKey('ownershipPrivilege')) {
      ownershipPrivilege = _json['ownershipPrivilege'] as core.String;
    }
    if (_json.containsKey('supportsWorkProfile')) {
      supportsWorkProfile = _json['supportsWorkProfile'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabledUnknownSources != null)
          'enabledUnknownSources': enabledUnknownSources!,
        if (ownerProfileAccount != null)
          'ownerProfileAccount': ownerProfileAccount!,
        if (ownershipPrivilege != null)
          'ownershipPrivilege': ownershipPrivilege!,
        if (supportsWorkProfile != null)
          'supportsWorkProfile': supportsWorkProfile!,
      };
}

/// Request message for approving the device to access user data.
class GoogleAppsCloudidentityDevicesV1ApproveDeviceUserRequest {
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer.
  ///
  /// If you're using this API for your own organization, use
  /// `customers/my_customer` If you're using this API to manage another
  /// organization, use `customers/{customer_id}`, where customer_id is the
  /// customer to whom the device belongs.
  ///
  /// Optional.
  core.String? customer;

  GoogleAppsCloudidentityDevicesV1ApproveDeviceUserRequest();

  GoogleAppsCloudidentityDevicesV1ApproveDeviceUserRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('customer')) {
      customer = _json['customer'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customer != null) 'customer': customer!,
      };
}

/// Response message for approving the device to access user data.
class GoogleAppsCloudidentityDevicesV1ApproveDeviceUserResponse {
  /// Resultant DeviceUser object for the action.
  GoogleAppsCloudidentityDevicesV1DeviceUser? deviceUser;

  GoogleAppsCloudidentityDevicesV1ApproveDeviceUserResponse();

  GoogleAppsCloudidentityDevicesV1ApproveDeviceUserResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('deviceUser')) {
      deviceUser = GoogleAppsCloudidentityDevicesV1DeviceUser.fromJson(
          _json['deviceUser'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceUser != null) 'deviceUser': deviceUser!.toJson(),
      };
}

/// Request message for blocking account on device.
class GoogleAppsCloudidentityDevicesV1BlockDeviceUserRequest {
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer.
  ///
  /// If you're using this API for your own organization, use
  /// `customers/my_customer` If you're using this API to manage another
  /// organization, use `customers/{customer_id}`, where customer_id is the
  /// customer to whom the device belongs.
  ///
  /// Optional.
  core.String? customer;

  GoogleAppsCloudidentityDevicesV1BlockDeviceUserRequest();

  GoogleAppsCloudidentityDevicesV1BlockDeviceUserRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('customer')) {
      customer = _json['customer'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customer != null) 'customer': customer!,
      };
}

/// Response message for blocking the device from accessing user data.
class GoogleAppsCloudidentityDevicesV1BlockDeviceUserResponse {
  /// Resultant DeviceUser object for the action.
  GoogleAppsCloudidentityDevicesV1DeviceUser? deviceUser;

  GoogleAppsCloudidentityDevicesV1BlockDeviceUserResponse();

  GoogleAppsCloudidentityDevicesV1BlockDeviceUserResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('deviceUser')) {
      deviceUser = GoogleAppsCloudidentityDevicesV1DeviceUser.fromJson(
          _json['deviceUser'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceUser != null) 'deviceUser': deviceUser!.toJson(),
      };
}

/// Request message for cancelling an unfinished device wipe.
class GoogleAppsCloudidentityDevicesV1CancelWipeDeviceRequest {
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer.
  ///
  /// If you're using this API for your own organization, use
  /// `customers/my_customer` If you're using this API to manage another
  /// organization, use `customers/{customer_id}`, where customer_id is the
  /// customer to whom the device belongs.
  ///
  /// Optional.
  core.String? customer;

  GoogleAppsCloudidentityDevicesV1CancelWipeDeviceRequest();

  GoogleAppsCloudidentityDevicesV1CancelWipeDeviceRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('customer')) {
      customer = _json['customer'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customer != null) 'customer': customer!,
      };
}

/// Response message for cancelling an unfinished device wipe.
class GoogleAppsCloudidentityDevicesV1CancelWipeDeviceResponse {
  /// Resultant Device object for the action.
  ///
  /// Note that asset tags will not be returned in the device object.
  GoogleAppsCloudidentityDevicesV1Device? device;

  GoogleAppsCloudidentityDevicesV1CancelWipeDeviceResponse();

  GoogleAppsCloudidentityDevicesV1CancelWipeDeviceResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('device')) {
      device = GoogleAppsCloudidentityDevicesV1Device.fromJson(
          _json['device'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (device != null) 'device': device!.toJson(),
      };
}

/// Request message for cancelling an unfinished user account wipe.
class GoogleAppsCloudidentityDevicesV1CancelWipeDeviceUserRequest {
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer.
  ///
  /// If you're using this API for your own organization, use
  /// `customers/my_customer` If you're using this API to manage another
  /// organization, use `customers/{customer_id}`, where customer_id is the
  /// customer to whom the device belongs.
  ///
  /// Optional.
  core.String? customer;

  GoogleAppsCloudidentityDevicesV1CancelWipeDeviceUserRequest();

  GoogleAppsCloudidentityDevicesV1CancelWipeDeviceUserRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('customer')) {
      customer = _json['customer'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customer != null) 'customer': customer!,
      };
}

/// Response message for cancelling an unfinished user account wipe.
class GoogleAppsCloudidentityDevicesV1CancelWipeDeviceUserResponse {
  /// Resultant DeviceUser object for the action.
  GoogleAppsCloudidentityDevicesV1DeviceUser? deviceUser;

  GoogleAppsCloudidentityDevicesV1CancelWipeDeviceUserResponse();

  GoogleAppsCloudidentityDevicesV1CancelWipeDeviceUserResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('deviceUser')) {
      deviceUser = GoogleAppsCloudidentityDevicesV1DeviceUser.fromJson(
          _json['deviceUser'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceUser != null) 'deviceUser': deviceUser!.toJson(),
      };
}

/// Represents the state associated with an API client calling the Devices API.
///
/// Resource representing ClientState and supports updates from API users
class GoogleAppsCloudidentityDevicesV1ClientState {
  /// The caller can specify asset tags for this resource
  core.List<core.String>? assetTags;

  /// The compliance state of the resource as specified by the API client.
  /// Possible string values are:
  /// - "COMPLIANCE_STATE_UNSPECIFIED" : The compliance state of the resource is
  /// unknown or unspecified.
  /// - "COMPLIANT" : Device is compliant with third party policies
  /// - "NON_COMPLIANT" : Device is not compliant with third party policies
  core.String? complianceState;

  /// The time the client state data was created.
  ///
  /// Output only.
  core.String? createTime;

  /// This field may be used to store a unique identifier for the API resource
  /// within which these CustomAttributes are a field.
  core.String? customId;

  /// The token that needs to be passed back for concurrency control in updates.
  ///
  /// Token needs to be passed back in UpdateRequest
  core.String? etag;

  /// The Health score of the resource.
  ///
  /// The Health score is the callers specification of the condition of the
  /// device from a usability point of view. For example, a third-party device
  /// management provider may specify a health score based on its compliance
  /// with organizational policies.
  /// Possible string values are:
  /// - "HEALTH_SCORE_UNSPECIFIED" : Default value
  /// - "VERY_POOR" : The object is in very poor health as defined by the
  /// caller.
  /// - "POOR" : The object is in poor health as defined by the caller.
  /// - "NEUTRAL" : The object health is neither good nor poor, as defined by
  /// the caller.
  /// - "GOOD" : The object is in good health as defined by the caller.
  /// - "VERY_GOOD" : The object is in very good health as defined by the
  /// caller.
  core.String? healthScore;

  /// The map of key-value attributes stored by callers specific to a device.
  ///
  /// The total serialized length of this map may not exceed 10KB. No limit is
  /// placed on the number of attributes in a map.
  core.Map<core.String, GoogleAppsCloudidentityDevicesV1CustomAttributeValue>?
      keyValuePairs;

  /// The time the client state data was last updated.
  ///
  /// Output only.
  core.String? lastUpdateTime;

  /// The management state of the resource as specified by the API client.
  /// Possible string values are:
  /// - "MANAGED_STATE_UNSPECIFIED" : The management state of the resource is
  /// unknown or unspecified.
  /// - "MANAGED" : The resource is managed.
  /// - "UNMANAGED" : The resource is not managed.
  core.String? managed;

  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the ClientState in format:
  /// `devices/{device_id}/deviceUsers/{device_user_id}/clientState/{partner_id}`,
  /// where partner_id corresponds to the partner storing the data.
  ///
  /// For partners belonging to the "BeyondCorp Alliance", this is the partner
  /// ID specified to you by Google. For all other callers, this is a string of
  /// the form: `{customer_id}-suffix`, where `customer_id` is your customer ID.
  /// The *suffix* is any string the caller specifies. This string will be
  /// displayed verbatim in the administration console. This suffix is used in
  /// setting up Custom Access Levels in Context-Aware Access. Your
  /// organization's customer ID can be obtained from the URL: `GET
  /// https://www.googleapis.com/admin/directory/v1/customers/my_customer` The
  /// `id` field in the response contains the customer ID starting with the
  /// letter 'C'. The customer ID to be used in this API is the string after the
  /// letter 'C' (not including 'C')
  ///
  /// Output only.
  core.String? name;

  /// The owner of the ClientState
  ///
  /// Output only.
  /// Possible string values are:
  /// - "OWNER_TYPE_UNSPECIFIED" : Unknown owner type
  /// - "OWNER_TYPE_CUSTOMER" : Customer is the owner
  /// - "OWNER_TYPE_PARTNER" : Partner is the owner
  core.String? ownerType;

  /// A descriptive cause of the health score.
  core.String? scoreReason;

  GoogleAppsCloudidentityDevicesV1ClientState();

  GoogleAppsCloudidentityDevicesV1ClientState.fromJson(core.Map _json) {
    if (_json.containsKey('assetTags')) {
      assetTags = (_json['assetTags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('complianceState')) {
      complianceState = _json['complianceState'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('customId')) {
      customId = _json['customId'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('healthScore')) {
      healthScore = _json['healthScore'] as core.String;
    }
    if (_json.containsKey('keyValuePairs')) {
      keyValuePairs =
          (_json['keyValuePairs'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          GoogleAppsCloudidentityDevicesV1CustomAttributeValue.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('lastUpdateTime')) {
      lastUpdateTime = _json['lastUpdateTime'] as core.String;
    }
    if (_json.containsKey('managed')) {
      managed = _json['managed'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('ownerType')) {
      ownerType = _json['ownerType'] as core.String;
    }
    if (_json.containsKey('scoreReason')) {
      scoreReason = _json['scoreReason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assetTags != null) 'assetTags': assetTags!,
        if (complianceState != null) 'complianceState': complianceState!,
        if (createTime != null) 'createTime': createTime!,
        if (customId != null) 'customId': customId!,
        if (etag != null) 'etag': etag!,
        if (healthScore != null) 'healthScore': healthScore!,
        if (keyValuePairs != null)
          'keyValuePairs': keyValuePairs!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (lastUpdateTime != null) 'lastUpdateTime': lastUpdateTime!,
        if (managed != null) 'managed': managed!,
        if (name != null) 'name': name!,
        if (ownerType != null) 'ownerType': ownerType!,
        if (scoreReason != null) 'scoreReason': scoreReason!,
      };
}

/// Additional custom attribute values may be one of these types
class GoogleAppsCloudidentityDevicesV1CustomAttributeValue {
  /// Represents a boolean value.
  core.bool? boolValue;

  /// Represents a double value.
  core.double? numberValue;

  /// Represents a string value.
  core.String? stringValue;

  GoogleAppsCloudidentityDevicesV1CustomAttributeValue();

  GoogleAppsCloudidentityDevicesV1CustomAttributeValue.fromJson(
      core.Map _json) {
    if (_json.containsKey('boolValue')) {
      boolValue = _json['boolValue'] as core.bool;
    }
    if (_json.containsKey('numberValue')) {
      numberValue = (_json['numberValue'] as core.num).toDouble();
    }
    if (_json.containsKey('stringValue')) {
      stringValue = _json['stringValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (boolValue != null) 'boolValue': boolValue!,
        if (numberValue != null) 'numberValue': numberValue!,
        if (stringValue != null) 'stringValue': stringValue!,
      };
}

///  A Device within the Cloud Identity Devices API.
///
/// Represents a Device known to Google Cloud, independent of the device
/// ownership, type, and whether it is assigned or in use by a user.
class GoogleAppsCloudidentityDevicesV1Device {
  /// Attributes specific to Android devices.
  ///
  /// Output only.
  GoogleAppsCloudidentityDevicesV1AndroidAttributes? androidSpecificAttributes;

  /// Asset tag of the device.
  core.String? assetTag;

  /// Baseband version of the device.
  ///
  /// Output only.
  core.String? basebandVersion;

  /// Device bootloader version.
  ///
  /// Example: 0.6.7.
  ///
  /// Output only.
  core.String? bootloaderVersion;

  /// Device brand.
  ///
  /// Example: Samsung.
  ///
  /// Output only.
  core.String? brand;

  /// Build number of the device.
  ///
  /// Output only.
  core.String? buildNumber;

  /// Represents whether the Device is compromised.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "COMPROMISED_STATE_UNSPECIFIED" : Default value.
  /// - "COMPROMISED" : The device is compromised (currently, this means Android
  /// device is rooted).
  /// - "UNCOMPROMISED" : The device is safe (currently, this means Android
  /// device is unrooted).
  core.String? compromisedState;

  /// When the Company-Owned device was imported.
  ///
  /// This field is empty for BYOD devices.
  ///
  /// Output only.
  core.String? createTime;

  /// Type of device.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "DEVICE_TYPE_UNSPECIFIED" : Unknown device type
  /// - "ANDROID" : Device is an Android device
  /// - "IOS" : Device is an iOS device
  /// - "GOOGLE_SYNC" : Device is a Google Sync device.
  /// - "WINDOWS" : Device is a Windows device.
  /// - "MAC_OS" : Device is a MacOS device.
  /// - "LINUX" : Device is a Linux device.
  /// - "CHROME_OS" : Device is a ChromeOS device.
  core.String? deviceType;

  /// Whether developer options is enabled on device.
  ///
  /// Output only.
  core.bool? enabledDeveloperOptions;

  /// Whether USB debugging is enabled on device.
  ///
  /// Output only.
  core.bool? enabledUsbDebugging;

  /// Device encryption state.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "ENCRYPTION_STATE_UNSPECIFIED" : Encryption Status is not set.
  /// - "UNSUPPORTED_BY_DEVICE" : Device doesn't support encryption.
  /// - "ENCRYPTED" : Device is encrypted.
  /// - "NOT_ENCRYPTED" : Device is not encrypted.
  core.String? encryptionState;

  /// IMEI number of device if GSM device; empty otherwise.
  ///
  /// Output only.
  core.String? imei;

  /// Kernel version of the device.
  ///
  /// Output only.
  core.String? kernelVersion;

  /// Most recent time when device synced with this service.
  core.String? lastSyncTime;

  /// Management state of the device
  ///
  /// Output only.
  /// Possible string values are:
  /// - "MANAGEMENT_STATE_UNSPECIFIED" : Default value. This value is unused.
  /// - "APPROVED" : Device is approved.
  /// - "BLOCKED" : Device is blocked.
  /// - "PENDING" : Device is pending approval.
  /// - "UNPROVISIONED" : The device is not provisioned. Device will start from
  /// this state until some action is taken (i.e. a user starts using the
  /// device).
  /// - "WIPING" : Data and settings on the device are being removed.
  /// - "WIPED" : All data and settings on the device are removed.
  core.String? managementState;

  /// Device manufacturer.
  ///
  /// Example: Motorola.
  ///
  /// Output only.
  core.String? manufacturer;

  /// MEID number of device if CDMA device; empty otherwise.
  ///
  /// Output only.
  core.String? meid;

  /// Model name of device.
  ///
  /// Example: Pixel 3.
  ///
  /// Output only.
  core.String? model;

  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the Device in format: `devices/{device_id}`, where device_id is the unique
  /// id assigned to the Device.
  ///
  /// Output only.
  core.String? name;

  /// Mobile or network operator of device, if available.
  ///
  /// Output only.
  core.String? networkOperator;

  /// OS version of the device.
  ///
  /// Example: Android 8.1.0.
  ///
  /// Output only.
  core.String? osVersion;

  /// Domain name for Google accounts on device.
  ///
  /// Type for other accounts on device. On Android, will only be populated if
  /// |ownership_privilege| is |PROFILE_OWNER| or |DEVICE_OWNER|. Does not
  /// include the account signed in to the device policy app if that account's
  /// domain has only one account. Examples: "com.example", "xyz.com".
  ///
  /// Output only.
  core.List<core.String>? otherAccounts;

  /// Whether the device is owned by the company or an individual
  ///
  /// Output only.
  /// Possible string values are:
  /// - "DEVICE_OWNERSHIP_UNSPECIFIED" : Default value. The value is unused.
  /// - "COMPANY" : Company owns the device.
  /// - "BYOD" : Bring Your Own Device (i.e. individual owns the device)
  core.String? ownerType;

  /// OS release version.
  ///
  /// Example: 6.0.
  ///
  /// Output only.
  core.String? releaseVersion;

  /// OS security patch update time on device.
  ///
  /// Output only.
  core.String? securityPatchTime;

  /// Serial Number of device.
  ///
  /// Example: HT82V1A01076.
  core.String? serialNumber;

  /// WiFi MAC addresses of device.
  core.List<core.String>? wifiMacAddresses;

  GoogleAppsCloudidentityDevicesV1Device();

  GoogleAppsCloudidentityDevicesV1Device.fromJson(core.Map _json) {
    if (_json.containsKey('androidSpecificAttributes')) {
      androidSpecificAttributes =
          GoogleAppsCloudidentityDevicesV1AndroidAttributes.fromJson(
              _json['androidSpecificAttributes']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('assetTag')) {
      assetTag = _json['assetTag'] as core.String;
    }
    if (_json.containsKey('basebandVersion')) {
      basebandVersion = _json['basebandVersion'] as core.String;
    }
    if (_json.containsKey('bootloaderVersion')) {
      bootloaderVersion = _json['bootloaderVersion'] as core.String;
    }
    if (_json.containsKey('brand')) {
      brand = _json['brand'] as core.String;
    }
    if (_json.containsKey('buildNumber')) {
      buildNumber = _json['buildNumber'] as core.String;
    }
    if (_json.containsKey('compromisedState')) {
      compromisedState = _json['compromisedState'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('deviceType')) {
      deviceType = _json['deviceType'] as core.String;
    }
    if (_json.containsKey('enabledDeveloperOptions')) {
      enabledDeveloperOptions = _json['enabledDeveloperOptions'] as core.bool;
    }
    if (_json.containsKey('enabledUsbDebugging')) {
      enabledUsbDebugging = _json['enabledUsbDebugging'] as core.bool;
    }
    if (_json.containsKey('encryptionState')) {
      encryptionState = _json['encryptionState'] as core.String;
    }
    if (_json.containsKey('imei')) {
      imei = _json['imei'] as core.String;
    }
    if (_json.containsKey('kernelVersion')) {
      kernelVersion = _json['kernelVersion'] as core.String;
    }
    if (_json.containsKey('lastSyncTime')) {
      lastSyncTime = _json['lastSyncTime'] as core.String;
    }
    if (_json.containsKey('managementState')) {
      managementState = _json['managementState'] as core.String;
    }
    if (_json.containsKey('manufacturer')) {
      manufacturer = _json['manufacturer'] as core.String;
    }
    if (_json.containsKey('meid')) {
      meid = _json['meid'] as core.String;
    }
    if (_json.containsKey('model')) {
      model = _json['model'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('networkOperator')) {
      networkOperator = _json['networkOperator'] as core.String;
    }
    if (_json.containsKey('osVersion')) {
      osVersion = _json['osVersion'] as core.String;
    }
    if (_json.containsKey('otherAccounts')) {
      otherAccounts = (_json['otherAccounts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('ownerType')) {
      ownerType = _json['ownerType'] as core.String;
    }
    if (_json.containsKey('releaseVersion')) {
      releaseVersion = _json['releaseVersion'] as core.String;
    }
    if (_json.containsKey('securityPatchTime')) {
      securityPatchTime = _json['securityPatchTime'] as core.String;
    }
    if (_json.containsKey('serialNumber')) {
      serialNumber = _json['serialNumber'] as core.String;
    }
    if (_json.containsKey('wifiMacAddresses')) {
      wifiMacAddresses = (_json['wifiMacAddresses'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (androidSpecificAttributes != null)
          'androidSpecificAttributes': androidSpecificAttributes!.toJson(),
        if (assetTag != null) 'assetTag': assetTag!,
        if (basebandVersion != null) 'basebandVersion': basebandVersion!,
        if (bootloaderVersion != null) 'bootloaderVersion': bootloaderVersion!,
        if (brand != null) 'brand': brand!,
        if (buildNumber != null) 'buildNumber': buildNumber!,
        if (compromisedState != null) 'compromisedState': compromisedState!,
        if (createTime != null) 'createTime': createTime!,
        if (deviceType != null) 'deviceType': deviceType!,
        if (enabledDeveloperOptions != null)
          'enabledDeveloperOptions': enabledDeveloperOptions!,
        if (enabledUsbDebugging != null)
          'enabledUsbDebugging': enabledUsbDebugging!,
        if (encryptionState != null) 'encryptionState': encryptionState!,
        if (imei != null) 'imei': imei!,
        if (kernelVersion != null) 'kernelVersion': kernelVersion!,
        if (lastSyncTime != null) 'lastSyncTime': lastSyncTime!,
        if (managementState != null) 'managementState': managementState!,
        if (manufacturer != null) 'manufacturer': manufacturer!,
        if (meid != null) 'meid': meid!,
        if (model != null) 'model': model!,
        if (name != null) 'name': name!,
        if (networkOperator != null) 'networkOperator': networkOperator!,
        if (osVersion != null) 'osVersion': osVersion!,
        if (otherAccounts != null) 'otherAccounts': otherAccounts!,
        if (ownerType != null) 'ownerType': ownerType!,
        if (releaseVersion != null) 'releaseVersion': releaseVersion!,
        if (securityPatchTime != null) 'securityPatchTime': securityPatchTime!,
        if (serialNumber != null) 'serialNumber': serialNumber!,
        if (wifiMacAddresses != null) 'wifiMacAddresses': wifiMacAddresses!,
      };
}

/// Represents a user's use of a Device in the Cloud Identity Devices API.
///
/// A DeviceUser is a resource representing a user's use of a Device
class GoogleAppsCloudidentityDevicesV1DeviceUser {
  /// Compromised State of the DeviceUser object
  /// Possible string values are:
  /// - "COMPROMISED_STATE_UNSPECIFIED" : Compromised state of Device User
  /// account is unknown or unspecified.
  /// - "COMPROMISED" : Device User Account is compromised.
  /// - "NOT_COMPROMISED" : Device User Account is not compromised.
  core.String? compromisedState;

  /// When the user first signed in to the device
  core.String? createTime;

  /// Most recent time when user registered with this service.
  ///
  /// Output only.
  core.String? firstSyncTime;

  /// Default locale used on device, in IETF BCP-47 format.
  ///
  /// Output only.
  core.String? languageCode;

  /// Last time when user synced with policies.
  ///
  /// Output only.
  core.String? lastSyncTime;

  /// Management state of the user on the device.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "MANAGEMENT_STATE_UNSPECIFIED" : Default value. This value is unused.
  /// - "WIPING" : This user's data and profile is being removed from the
  /// device.
  /// - "WIPED" : This user's data and profile is removed from the device.
  /// - "APPROVED" : User is approved to access data on the device.
  /// - "BLOCKED" : User is blocked from accessing data on the device.
  /// - "PENDING_APPROVAL" : User is awaiting approval.
  /// - "UNENROLLED" : User is unenrolled from Advanced Windows Management, but
  /// the Windows account is still intact.
  core.String? managementState;

  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the DeviceUser in format:
  /// `devices/{device_id}/deviceUsers/{device_user_id}`, where `device_user_id`
  /// uniquely identifies a user's use of a device.
  ///
  /// Output only.
  core.String? name;

  /// Password state of the DeviceUser object
  /// Possible string values are:
  /// - "PASSWORD_STATE_UNSPECIFIED" : Password state not set.
  /// - "PASSWORD_SET" : Password set in object.
  /// - "PASSWORD_NOT_SET" : Password not set in object.
  core.String? passwordState;

  /// User agent on the device for this specific user
  ///
  /// Output only.
  core.String? userAgent;

  /// Email address of the user registered on the device.
  core.String? userEmail;

  GoogleAppsCloudidentityDevicesV1DeviceUser();

  GoogleAppsCloudidentityDevicesV1DeviceUser.fromJson(core.Map _json) {
    if (_json.containsKey('compromisedState')) {
      compromisedState = _json['compromisedState'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('firstSyncTime')) {
      firstSyncTime = _json['firstSyncTime'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('lastSyncTime')) {
      lastSyncTime = _json['lastSyncTime'] as core.String;
    }
    if (_json.containsKey('managementState')) {
      managementState = _json['managementState'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('passwordState')) {
      passwordState = _json['passwordState'] as core.String;
    }
    if (_json.containsKey('userAgent')) {
      userAgent = _json['userAgent'] as core.String;
    }
    if (_json.containsKey('userEmail')) {
      userEmail = _json['userEmail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (compromisedState != null) 'compromisedState': compromisedState!,
        if (createTime != null) 'createTime': createTime!,
        if (firstSyncTime != null) 'firstSyncTime': firstSyncTime!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (lastSyncTime != null) 'lastSyncTime': lastSyncTime!,
        if (managementState != null) 'managementState': managementState!,
        if (name != null) 'name': name!,
        if (passwordState != null) 'passwordState': passwordState!,
        if (userAgent != null) 'userAgent': userAgent!,
        if (userEmail != null) 'userEmail': userEmail!,
      };
}

/// Response message that is returned in ListClientStates.
class GoogleAppsCloudidentityDevicesV1ListClientStatesResponse {
  /// Client states meeting the list restrictions.
  core.List<GoogleAppsCloudidentityDevicesV1ClientState>? clientStates;

  /// Token to retrieve the next page of results.
  ///
  /// Empty if there are no more results.
  core.String? nextPageToken;

  GoogleAppsCloudidentityDevicesV1ListClientStatesResponse();

  GoogleAppsCloudidentityDevicesV1ListClientStatesResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('clientStates')) {
      clientStates = (_json['clientStates'] as core.List)
          .map<GoogleAppsCloudidentityDevicesV1ClientState>((value) =>
              GoogleAppsCloudidentityDevicesV1ClientState.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clientStates != null)
          'clientStates': clientStates!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message that is returned from the ListDeviceUsers method.
class GoogleAppsCloudidentityDevicesV1ListDeviceUsersResponse {
  /// Devices meeting the list restrictions.
  core.List<GoogleAppsCloudidentityDevicesV1DeviceUser>? deviceUsers;

  /// Token to retrieve the next page of results.
  ///
  /// Empty if there are no more results.
  core.String? nextPageToken;

  GoogleAppsCloudidentityDevicesV1ListDeviceUsersResponse();

  GoogleAppsCloudidentityDevicesV1ListDeviceUsersResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('deviceUsers')) {
      deviceUsers = (_json['deviceUsers'] as core.List)
          .map<GoogleAppsCloudidentityDevicesV1DeviceUser>((value) =>
              GoogleAppsCloudidentityDevicesV1DeviceUser.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceUsers != null)
          'deviceUsers': deviceUsers!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message that is returned from the ListDevices method.
class GoogleAppsCloudidentityDevicesV1ListDevicesResponse {
  /// Devices meeting the list restrictions.
  core.List<GoogleAppsCloudidentityDevicesV1Device>? devices;

  /// Token to retrieve the next page of results.
  ///
  /// Empty if there are no more results.
  core.String? nextPageToken;

  GoogleAppsCloudidentityDevicesV1ListDevicesResponse();

  GoogleAppsCloudidentityDevicesV1ListDevicesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('devices')) {
      devices = (_json['devices'] as core.List)
          .map<GoogleAppsCloudidentityDevicesV1Device>((value) =>
              GoogleAppsCloudidentityDevicesV1Device.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (devices != null)
          'devices': devices!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response containing resource names of the DeviceUsers associated with the
/// caller's credentials.
class GoogleAppsCloudidentityDevicesV1LookupSelfDeviceUsersResponse {
  /// The obfuscated customer Id that may be passed back to other Devices API
  /// methods such as List, Get, etc.
  core.String? customer;

  /// [Resource names](https://cloud.google.com/apis/design/resource_names) of
  /// the DeviceUsers in the format:
  /// `devices/{device_id}/deviceUsers/{user_resource_id}`, where device_id is
  /// the unique ID assigned to a Device and user_resource_id is the unique user
  /// ID
  core.List<core.String>? names;

  /// Token to retrieve the next page of results.
  ///
  /// Empty if there are no more results.
  core.String? nextPageToken;

  GoogleAppsCloudidentityDevicesV1LookupSelfDeviceUsersResponse();

  GoogleAppsCloudidentityDevicesV1LookupSelfDeviceUsersResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('customer')) {
      customer = _json['customer'] as core.String;
    }
    if (_json.containsKey('names')) {
      names = (_json['names'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customer != null) 'customer': customer!,
        if (names != null) 'names': names!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Request message for wiping all data on the device.
class GoogleAppsCloudidentityDevicesV1WipeDeviceRequest {
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer.
  ///
  /// If you're using this API for your own organization, use
  /// `customers/my_customer` If you're using this API to manage another
  /// organization, use `customers/{customer_id}`, where customer_id is the
  /// customer to whom the device belongs.
  ///
  /// Optional.
  core.String? customer;

  GoogleAppsCloudidentityDevicesV1WipeDeviceRequest();

  GoogleAppsCloudidentityDevicesV1WipeDeviceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('customer')) {
      customer = _json['customer'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customer != null) 'customer': customer!,
      };
}

/// Response message for wiping all data on the device.
class GoogleAppsCloudidentityDevicesV1WipeDeviceResponse {
  /// Resultant Device object for the action.
  ///
  /// Note that asset tags will not be returned in the device object.
  GoogleAppsCloudidentityDevicesV1Device? device;

  GoogleAppsCloudidentityDevicesV1WipeDeviceResponse();

  GoogleAppsCloudidentityDevicesV1WipeDeviceResponse.fromJson(core.Map _json) {
    if (_json.containsKey('device')) {
      device = GoogleAppsCloudidentityDevicesV1Device.fromJson(
          _json['device'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (device != null) 'device': device!.toJson(),
      };
}

/// Request message for starting an account wipe on device.
class GoogleAppsCloudidentityDevicesV1WipeDeviceUserRequest {
  /// [Resource name](https://cloud.google.com/apis/design/resource_names) of
  /// the customer.
  ///
  /// If you're using this API for your own organization, use
  /// `customers/my_customer` If you're using this API to manage another
  /// organization, use `customers/{customer_id}`, where customer_id is the
  /// customer to whom the device belongs.
  ///
  /// Optional.
  core.String? customer;

  GoogleAppsCloudidentityDevicesV1WipeDeviceUserRequest();

  GoogleAppsCloudidentityDevicesV1WipeDeviceUserRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('customer')) {
      customer = _json['customer'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (customer != null) 'customer': customer!,
      };
}

/// Response message for wiping the user's account from the device.
class GoogleAppsCloudidentityDevicesV1WipeDeviceUserResponse {
  /// Resultant DeviceUser object for the action.
  GoogleAppsCloudidentityDevicesV1DeviceUser? deviceUser;

  GoogleAppsCloudidentityDevicesV1WipeDeviceUserResponse();

  GoogleAppsCloudidentityDevicesV1WipeDeviceUserResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('deviceUser')) {
      deviceUser = GoogleAppsCloudidentityDevicesV1DeviceUser.fromJson(
          _json['deviceUser'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceUser != null) 'deviceUser': deviceUser!.toJson(),
      };
}

/// A group within the Cloud Identity Groups API.
///
/// A `Group` is a collection of entities, where each entity is either a user,
/// another group, or a service account.
class Group {
  /// The time when the `Group` was created.
  ///
  /// Output only.
  core.String? createTime;

  /// An extended description to help users determine the purpose of a `Group`.
  ///
  /// Must not be longer than 4,096 characters.
  core.String? description;

  /// The display name of the `Group`.
  core.String? displayName;

  /// Dynamic group metadata like queries and status.
  ///
  /// Optional.
  DynamicGroupMetadata? dynamicGroupMetadata;

  /// The `EntityKey` of the `Group`.
  ///
  /// Required. Immutable.
  EntityKey? groupKey;

  /// One or more label entries that apply to the Group.
  ///
  /// Currently supported labels contain a key with an empty value. Google
  /// Groups are the default type of group and have a label with a key of
  /// `cloudidentity.googleapis.com/groups.discussion_forum` and an empty value.
  /// Existing Google Groups can have an additional label with a key of
  /// `cloudidentity.googleapis.com/groups.security` and an empty value added to
  /// them. **This is an immutable change and the security label cannot be
  /// removed once added.** Dynamic groups have a label with a key of
  /// `cloudidentity.googleapis.com/groups.dynamic`. Identity-mapped groups for
  /// Cloud Search have a label with a key of `system/groups/external` and an
  /// empty value.
  ///
  /// Required.
  core.Map<core.String, core.String>? labels;

  /// The [resource name](https://cloud.google.com/apis/design/resource_names)
  /// of the `Group`.
  ///
  /// Shall be of the form `groups/{group_id}`.
  ///
  /// Output only.
  core.String? name;

  /// The resource name of the entity under which this `Group` resides in the
  /// Cloud Identity resource hierarchy.
  ///
  /// Must be of the form `identitysources/{identity_source_id}` for external-
  /// identity-mapped groups or `customers/{customer_id}` for Google Groups. The
  /// `customer_id` must begin with "C" (for example, 'C046psxkn').
  ///
  /// Required. Immutable.
  core.String? parent;

  /// The time when the `Group` was last updated.
  ///
  /// Output only.
  core.String? updateTime;

  Group();

  Group.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('dynamicGroupMetadata')) {
      dynamicGroupMetadata = DynamicGroupMetadata.fromJson(
          _json['dynamicGroupMetadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('groupKey')) {
      groupKey = EntityKey.fromJson(
          _json['groupKey'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (dynamicGroupMetadata != null)
          'dynamicGroupMetadata': dynamicGroupMetadata!.toJson(),
        if (groupKey != null) 'groupKey': groupKey!.toJson(),
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (parent != null) 'parent': parent!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Message representing a transitive group of a user or a group.
class GroupRelation {
  /// Display name for this group.
  core.String? displayName;

  /// Resource name for this group.
  core.String? group;

  /// Entity key has an id and a namespace.
  ///
  /// In case of discussion forums, the id will be an email address without a
  /// namespace.
  EntityKey? groupKey;

  /// Labels for Group resource.
  core.Map<core.String, core.String>? labels;

  /// The relation between the member and the transitive group.
  /// Possible string values are:
  /// - "RELATION_TYPE_UNSPECIFIED" : The relation type is undefined or
  /// undetermined.
  /// - "DIRECT" : The two entities have only a direct membership with each
  /// other.
  /// - "INDIRECT" : The two entities have only an indirect membership with each
  /// other.
  /// - "DIRECT_AND_INDIRECT" : The two entities have both a direct and an
  /// indirect membership with each other.
  core.String? relationType;

  /// Membership roles of the member for the group.
  core.List<TransitiveMembershipRole>? roles;

  GroupRelation();

  GroupRelation.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('group')) {
      group = _json['group'] as core.String;
    }
    if (_json.containsKey('groupKey')) {
      groupKey = EntityKey.fromJson(
          _json['groupKey'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('relationType')) {
      relationType = _json['relationType'] as core.String;
    }
    if (_json.containsKey('roles')) {
      roles = (_json['roles'] as core.List)
          .map<TransitiveMembershipRole>((value) =>
              TransitiveMembershipRole.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (group != null) 'group': group!,
        if (groupKey != null) 'groupKey': groupKey!.toJson(),
        if (labels != null) 'labels': labels!,
        if (relationType != null) 'relationType': relationType!,
        if (roles != null)
          'roles': roles!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for ListGroups operation.
class ListGroupsResponse {
  /// Groups returned in response to list request.
  ///
  /// The results are not sorted.
  core.List<Group>? groups;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results available for listing.
  core.String? nextPageToken;

  ListGroupsResponse();

  ListGroupsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('groups')) {
      groups = (_json['groups'] as core.List)
          .map<Group>((value) =>
              Group.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (groups != null)
          'groups': groups!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response message for MembershipsService.ListMemberships.
class ListMembershipsResponse {
  /// The `Membership`s under the specified `parent`.
  core.List<Membership>? memberships;

  /// A continuation token to retrieve the next page of results, or empty if
  /// there are no more results available.
  core.String? nextPageToken;

  ListMembershipsResponse();

  ListMembershipsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('memberships')) {
      memberships = (_json['memberships'] as core.List)
          .map<Membership>((value) =>
              Membership.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (memberships != null)
          'memberships': memberships!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response message for GroupsService.LookupGroupName.
class LookupGroupNameResponse {
  /// The [resource name](https://cloud.google.com/apis/design/resource_names)
  /// of the looked-up `Group`.
  core.String? name;

  LookupGroupNameResponse();

  LookupGroupNameResponse.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
      };
}

/// The response message for MembershipsService.LookupMembershipName.
class LookupMembershipNameResponse {
  /// The [resource name](https://cloud.google.com/apis/design/resource_names)
  /// of the looked-up `Membership`.
  ///
  /// Must be of the form `groups/{group_id}/memberships/{membership_id}`.
  core.String? name;

  LookupMembershipNameResponse();

  LookupMembershipNameResponse.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
      };
}

/// Message representing a transitive membership of a group.
class MemberRelation {
  /// Resource name for this member.
  core.String? member;

  /// Entity key has an id and a namespace.
  ///
  /// In case of discussion forums, the id will be an email address without a
  /// namespace.
  core.List<EntityKey>? preferredMemberKey;

  /// The relation between the group and the transitive member.
  /// Possible string values are:
  /// - "RELATION_TYPE_UNSPECIFIED" : The relation type is undefined or
  /// undetermined.
  /// - "DIRECT" : The two entities have only a direct membership with each
  /// other.
  /// - "INDIRECT" : The two entities have only an indirect membership with each
  /// other.
  /// - "DIRECT_AND_INDIRECT" : The two entities have both a direct and an
  /// indirect membership with each other.
  core.String? relationType;

  /// The membership role details (i.e name of role and expiry time).
  core.List<TransitiveMembershipRole>? roles;

  MemberRelation();

  MemberRelation.fromJson(core.Map _json) {
    if (_json.containsKey('member')) {
      member = _json['member'] as core.String;
    }
    if (_json.containsKey('preferredMemberKey')) {
      preferredMemberKey = (_json['preferredMemberKey'] as core.List)
          .map<EntityKey>((value) =>
              EntityKey.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('relationType')) {
      relationType = _json['relationType'] as core.String;
    }
    if (_json.containsKey('roles')) {
      roles = (_json['roles'] as core.List)
          .map<TransitiveMembershipRole>((value) =>
              TransitiveMembershipRole.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (member != null) 'member': member!,
        if (preferredMemberKey != null)
          'preferredMemberKey':
              preferredMemberKey!.map((value) => value.toJson()).toList(),
        if (relationType != null) 'relationType': relationType!,
        if (roles != null)
          'roles': roles!.map((value) => value.toJson()).toList(),
      };
}

/// A membership within the Cloud Identity Groups API.
///
/// A `Membership` defines a relationship between a `Group` and an entity
/// belonging to that `Group`, referred to as a "member".
class Membership {
  /// The time when the `Membership` was created.
  ///
  /// Output only.
  core.String? createTime;

  /// The [resource name](https://cloud.google.com/apis/design/resource_names)
  /// of the `Membership`.
  ///
  /// Shall be of the form `groups/{group_id}/memberships/{membership_id}`.
  ///
  /// Output only.
  core.String? name;

  /// The `EntityKey` of the member.
  ///
  /// Required. Immutable.
  EntityKey? preferredMemberKey;

  /// The `MembershipRole`s that apply to the `Membership`.
  ///
  /// If unspecified, defaults to a single `MembershipRole` with `name`
  /// `MEMBER`. Must not contain duplicate `MembershipRole`s with the same
  /// `name`.
  core.List<MembershipRole>? roles;

  /// The type of the membership.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Default. Should not be used.
  /// - "USER" : Represents user type.
  /// - "SERVICE_ACCOUNT" : Represents service account type.
  /// - "GROUP" : Represents group type.
  /// - "SHARED_DRIVE" : Represents Shared drive.
  /// - "OTHER" : Represents other type.
  core.String? type;

  /// The time when the `Membership` was last updated.
  ///
  /// Output only.
  core.String? updateTime;

  Membership();

  Membership.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('preferredMemberKey')) {
      preferredMemberKey = EntityKey.fromJson(
          _json['preferredMemberKey'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('roles')) {
      roles = (_json['roles'] as core.List)
          .map<MembershipRole>((value) => MembershipRole.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (name != null) 'name': name!,
        if (preferredMemberKey != null)
          'preferredMemberKey': preferredMemberKey!.toJson(),
        if (roles != null)
          'roles': roles!.map((value) => value.toJson()).toList(),
        if (type != null) 'type': type!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Membership graph's path information as an adjacency list.
class MembershipAdjacencyList {
  /// Each edge contains information about the member that belongs to this
  /// group.
  ///
  /// Note: Fields returned here will help identify the specific Membership
  /// resource (e.g name, preferred_member_key and role), but may not be a
  /// comprehensive list of all fields.
  core.List<Membership>? edges;

  /// Resource name of the group that the members belong to.
  core.String? group;

  MembershipAdjacencyList();

  MembershipAdjacencyList.fromJson(core.Map _json) {
    if (_json.containsKey('edges')) {
      edges = (_json['edges'] as core.List)
          .map<Membership>((value) =>
              Membership.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('group')) {
      group = _json['group'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (edges != null)
          'edges': edges!.map((value) => value.toJson()).toList(),
        if (group != null) 'group': group!,
      };
}

/// A membership role within the Cloud Identity Groups API.
///
/// A `MembershipRole` defines the privileges granted to a `Membership`.
class MembershipRole {
  /// The expiry details of the `MembershipRole`.
  ///
  /// Expiry details are only supported for `MEMBER` `MembershipRoles`. May be
  /// set if `name` is `MEMBER`. Must not be set if `name` is any other value.
  ExpiryDetail? expiryDetail;

  /// The name of the `MembershipRole`.
  ///
  /// Must be one of `OWNER`, `MANAGER`, `MEMBER`.
  core.String? name;

  MembershipRole();

  MembershipRole.fromJson(core.Map _json) {
    if (_json.containsKey('expiryDetail')) {
      expiryDetail = ExpiryDetail.fromJson(
          _json['expiryDetail'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expiryDetail != null) 'expiryDetail': expiryDetail!.toJson(),
        if (name != null) 'name': name!,
      };
}

/// The request message for MembershipsService.ModifyMembershipRoles.
class ModifyMembershipRolesRequest {
  /// The `MembershipRole`s to be added.
  ///
  /// Adding or removing roles in the same request as updating roles is not
  /// supported. Must not be set if `update_roles_params` is set.
  core.List<MembershipRole>? addRoles;

  /// The `name`s of the `MembershipRole`s to be removed.
  ///
  /// Adding or removing roles in the same request as updating roles is not
  /// supported. It is not possible to remove the `MEMBER` `MembershipRole`. If
  /// you wish to delete a `Membership`, call
  /// MembershipsService.DeleteMembership instead. Must not contain `MEMBER`.
  /// Must not be set if `update_roles_params` is set.
  core.List<core.String>? removeRoles;

  /// The `MembershipRole`s to be updated.
  ///
  /// Updating roles in the same request as adding or removing roles is not
  /// supported. Must not be set if either `add_roles` or `remove_roles` is set.
  core.List<UpdateMembershipRolesParams>? updateRolesParams;

  ModifyMembershipRolesRequest();

  ModifyMembershipRolesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('addRoles')) {
      addRoles = (_json['addRoles'] as core.List)
          .map<MembershipRole>((value) => MembershipRole.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('removeRoles')) {
      removeRoles = (_json['removeRoles'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('updateRolesParams')) {
      updateRolesParams = (_json['updateRolesParams'] as core.List)
          .map<UpdateMembershipRolesParams>((value) =>
              UpdateMembershipRolesParams.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (addRoles != null)
          'addRoles': addRoles!.map((value) => value.toJson()).toList(),
        if (removeRoles != null) 'removeRoles': removeRoles!,
        if (updateRolesParams != null)
          'updateRolesParams':
              updateRolesParams!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for MembershipsService.ModifyMembershipRoles.
class ModifyMembershipRolesResponse {
  /// The `Membership` resource after modifying its `MembershipRole`s.
  Membership? membership;

  ModifyMembershipRolesResponse();

  ModifyMembershipRolesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('membership')) {
      membership = Membership.fromJson(
          _json['membership'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (membership != null) 'membership': membership!.toJson(),
      };
}

/// This resource represents a long-running operation that is the result of a
/// network API call.
class Operation {
  /// If the value is `false`, it means the operation is still in progress.
  ///
  /// If `true`, the operation is completed, and either `error` or `response` is
  /// available.
  core.bool? done;

  /// The error result of the operation in case of failure or cancellation.
  Status? error;

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

  Operation();

  Operation.fromJson(core.Map _json) {
    if (_json.containsKey('done')) {
      done = _json['done'] as core.bool;
    }
    if (_json.containsKey('error')) {
      error = Status.fromJson(
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

/// The response message for GroupsService.SearchGroups.
class SearchGroupsResponse {
  /// The `Group` resources that match the search query.
  core.List<Group>? groups;

  /// A continuation token to retrieve the next page of results, or empty if
  /// there are no more results available.
  core.String? nextPageToken;

  SearchGroupsResponse();

  SearchGroupsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('groups')) {
      groups = (_json['groups'] as core.List)
          .map<Group>((value) =>
              Group.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (groups != null)
          'groups': groups!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response message for MembershipsService.SearchTransitiveGroups.
class SearchTransitiveGroupsResponse {
  /// List of transitive groups satisfying the query.
  core.List<GroupRelation>? memberships;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results available for listing.
  core.String? nextPageToken;

  SearchTransitiveGroupsResponse();

  SearchTransitiveGroupsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('memberships')) {
      memberships = (_json['memberships'] as core.List)
          .map<GroupRelation>((value) => GroupRelation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (memberships != null)
          'memberships': memberships!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response message for MembershipsService.SearchTransitiveMemberships.
class SearchTransitiveMembershipsResponse {
  /// List of transitive members satisfying the query.
  core.List<MemberRelation>? memberships;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results.
  core.String? nextPageToken;

  SearchTransitiveMembershipsResponse();

  SearchTransitiveMembershipsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('memberships')) {
      memberships = (_json['memberships'] as core.List)
          .map<MemberRelation>((value) => MemberRelation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (memberships != null)
          'memberships': memberships!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs.
///
/// It is used by [gRPC](https://github.com/grpc). Each `Status` message
/// contains three pieces of data: error code, error message, and error details.
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
class Status {
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

  Status();

  Status.fromJson(core.Map _json) {
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

/// Message representing the role of a TransitiveMembership.
class TransitiveMembershipRole {
  /// TransitiveMembershipRole in string format.
  ///
  /// Currently supported TransitiveMembershipRoles: `"MEMBER"`, `"OWNER"`, and
  /// `"MANAGER"`.
  core.String? role;

  TransitiveMembershipRole();

  TransitiveMembershipRole.fromJson(core.Map _json) {
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (role != null) 'role': role!,
      };
}

/// The details of an update to a `MembershipRole`.
class UpdateMembershipRolesParams {
  /// The fully-qualified names of fields to update.
  ///
  /// May only contain the field `expiry_detail.expire_time`.
  core.String? fieldMask;

  /// The `MembershipRole`s to be updated.
  ///
  /// Only `MEMBER` `MembershipRole` can currently be updated.
  MembershipRole? membershipRole;

  UpdateMembershipRolesParams();

  UpdateMembershipRolesParams.fromJson(core.Map _json) {
    if (_json.containsKey('fieldMask')) {
      fieldMask = _json['fieldMask'] as core.String;
    }
    if (_json.containsKey('membershipRole')) {
      membershipRole = MembershipRole.fromJson(
          _json['membershipRole'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fieldMask != null) 'fieldMask': fieldMask!,
        if (membershipRole != null) 'membershipRole': membershipRole!.toJson(),
      };
}

/// The `UserInvitation` resource represents an email that can be sent to an
/// unmanaged user account inviting them to join the customer’s Google Workspace
/// or Cloud Identity account.
///
/// An unmanaged account shares an email address domain with the Google
/// Workspace or Cloud Identity account but is not managed by it yet. If the
/// user accepts the `UserInvitation`, the user account will become managed.
class UserInvitation {
  /// Number of invitation emails sent to the user.
  core.String? mailsSentCount;

  /// Shall be of the form
  /// `customers/{customer}/userinvitations/{user_email_address}`.
  core.String? name;

  /// State of the `UserInvitation`.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : The default value. This value is used if the state
  /// is omitted.
  /// - "NOT_YET_SENT" : The `UserInvitation` has been created and is ready for
  /// sending as an email.
  /// - "INVITED" : The user has been invited by email.
  /// - "ACCEPTED" : The user has accepted the invitation and is part of the
  /// organization.
  /// - "DECLINED" : The user declined the invitation.
  core.String? state;

  /// Time when the `UserInvitation` was last updated.
  core.String? updateTime;

  UserInvitation();

  UserInvitation.fromJson(core.Map _json) {
    if (_json.containsKey('mailsSentCount')) {
      mailsSentCount = _json['mailsSentCount'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mailsSentCount != null) 'mailsSentCount': mailsSentCount!,
        if (name != null) 'name': name!,
        if (state != null) 'state': state!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

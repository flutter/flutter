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

/// Cloud IoT API - v1
///
/// Registers and manages IoT (Internet of Things) devices that connect to the
/// Google Cloud Platform.
///
/// For more information, see <https://cloud.google.com/iot>
///
/// Create an instance of [CloudIotApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsRegistriesResource]
///       - [ProjectsLocationsRegistriesDevicesResource]
///         - [ProjectsLocationsRegistriesDevicesConfigVersionsResource]
///         - [ProjectsLocationsRegistriesDevicesStatesResource]
///       - [ProjectsLocationsRegistriesGroupsResource]
///         - [ProjectsLocationsRegistriesGroupsDevicesResource]
library cloudiot.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Registers and manages IoT (Internet of Things) devices that connect to the
/// Google Cloud Platform.
class CloudIotApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// Register and manage devices in the Google Cloud IoT service
  static const cloudiotScope = 'https://www.googleapis.com/auth/cloudiot';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  CloudIotApi(http.Client client,
      {core.String rootUrl = 'https://cloudiot.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsResource get locations =>
      ProjectsLocationsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsRegistriesResource get registries =>
      ProjectsLocationsRegistriesResource(_requester);

  ProjectsLocationsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsRegistriesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsRegistriesDevicesResource get devices =>
      ProjectsLocationsRegistriesDevicesResource(_requester);
  ProjectsLocationsRegistriesGroupsResource get groups =>
      ProjectsLocationsRegistriesGroupsResource(_requester);

  ProjectsLocationsRegistriesResource(commons.ApiRequester client)
      : _requester = client;

  /// Associates the device with the gateway.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the registry. For example,
  /// `projects/example-project/locations/us-central1/registries/my-registry`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BindDeviceToGatewayResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BindDeviceToGatewayResponse> bindDeviceToGateway(
    BindDeviceToGatewayRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + ':bindDeviceToGateway';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return BindDeviceToGatewayResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a device registry that contains devices.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The project and cloud region where this device
  /// registry must be created. For example,
  /// `projects/example-project/locations/us-central1`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DeviceRegistry].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DeviceRegistry> create(
    DeviceRegistry request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/registries';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DeviceRegistry.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a device registry configuration.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the device registry. For example,
  /// `projects/example-project/locations/us-central1/registries/my-registry`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+$`.
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

  /// Gets a device registry configuration.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the device registry. For example,
  /// `projects/example-project/locations/us-central1/registries/my-registry`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DeviceRegistry].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DeviceRegistry> get(
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
    return DeviceRegistry.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy for a resource.
  ///
  /// Returns an empty policy if the resource exists and does not have a policy
  /// set.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+$`.
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
    GetIamPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists device registries.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The project and cloud region path. For example,
  /// `projects/example-project/locations/us-central1`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of registries to return in the response.
  /// If this value is zero, the service will select a default size. A call may
  /// return fewer objects than requested. A non-empty `next_page_token` in the
  /// response indicates that more data is available.
  ///
  /// [pageToken] - The value returned by the last
  /// `ListDeviceRegistriesResponse`; indicates that this is a continuation of a
  /// prior `ListDeviceRegistries` call and the system should return the next
  /// page of data.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDeviceRegistriesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDeviceRegistriesResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/registries';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDeviceRegistriesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a device registry configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource path name. For example,
  /// `projects/example-project/locations/us-central1/registries/my-registry`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Only updates the `device_registry` fields
  /// indicated by this mask. The field mask must not be empty, and it must not
  /// contain fields that are immutable or only set by the server. Mutable
  /// top-level fields: `event_notification_config`, `http_config`,
  /// `mqtt_config`, and `state_notification_config`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DeviceRegistry].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DeviceRegistry> patch(
    DeviceRegistry request,
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
    return DeviceRegistry.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy on the specified resource.
  ///
  /// Replaces any existing policy.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+$`.
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

  /// Returns permissions that a caller has on the specified resource.
  ///
  /// If the resource does not exist, this will return an empty set of
  /// permissions, not a NOT_FOUND error.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+$`.
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

  /// Deletes the association between the device and the gateway.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the registry. For example,
  /// `projects/example-project/locations/us-central1/registries/my-registry`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UnbindDeviceFromGatewayResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UnbindDeviceFromGatewayResponse> unbindDeviceFromGateway(
    UnbindDeviceFromGatewayRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + ':unbindDeviceFromGateway';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return UnbindDeviceFromGatewayResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsRegistriesDevicesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsRegistriesDevicesConfigVersionsResource get configVersions =>
      ProjectsLocationsRegistriesDevicesConfigVersionsResource(_requester);
  ProjectsLocationsRegistriesDevicesStatesResource get states =>
      ProjectsLocationsRegistriesDevicesStatesResource(_requester);

  ProjectsLocationsRegistriesDevicesResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a device in a device registry.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the device registry where this device
  /// should be created. For example,
  /// `projects/example-project/locations/us-central1/registries/my-registry`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+$`.
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
  async.Future<Device> create(
    Device request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/devices';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Device.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a device.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the device. For example,
  /// `projects/p0/locations/us-central1/registries/registry0/devices/device0`
  /// or
  /// `projects/p0/locations/us-central1/registries/registry0/devices/{num_id}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+/devices/\[^/\]+$`.
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

  /// Gets details about a device.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the device. For example,
  /// `projects/p0/locations/us-central1/registries/registry0/devices/device0`
  /// or
  /// `projects/p0/locations/us-central1/registries/registry0/devices/{num_id}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+/devices/\[^/\]+$`.
  ///
  /// [fieldMask] - The fields of the `Device` resource to be returned in the
  /// response. If the field mask is unset or empty, all fields are returned.
  /// Fields have to be provided in snake_case format, for example:
  /// `last_heartbeat_time`.
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
    core.String name, {
    core.String? fieldMask,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (fieldMask != null) 'fieldMask': [fieldMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Device.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List devices in a device registry.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The device registry path. Required. For example,
  /// `projects/my-project/locations/us-central1/registries/my-registry`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+$`.
  ///
  /// [deviceIds] - A list of device string IDs. For example, `['device0',
  /// 'device12']`. If empty, this field is ignored. Maximum IDs: 10,000
  ///
  /// [deviceNumIds] - A list of device numeric IDs. If empty, this field is
  /// ignored. Maximum IDs: 10,000.
  ///
  /// [fieldMask] - The fields of the `Device` resource to be returned in the
  /// response. The fields `id` and `num_id` are always returned, along with any
  /// other fields specified in snake_case format, for example:
  /// `last_heartbeat_time`.
  ///
  /// [gatewayListOptions_associationsDeviceId] - If set, returns only the
  /// gateways with which the specified device is associated. The device ID can
  /// be numeric (`num_id`) or the user-defined string (`id`). For example, if
  /// `456` is specified, returns only the gateways to which the device with
  /// `num_id` 456 is bound.
  ///
  /// [gatewayListOptions_associationsGatewayId] - If set, only devices
  /// associated with the specified gateway are returned. The gateway ID can be
  /// numeric (`num_id`) or the user-defined string (`id`). For example, if
  /// `123` is specified, only devices bound to the gateway with `num_id` 123
  /// are returned.
  ///
  /// [gatewayListOptions_gatewayType] - If `GATEWAY` is specified, only
  /// gateways are returned. If `NON_GATEWAY` is specified, only non-gateway
  /// devices are returned. If `GATEWAY_TYPE_UNSPECIFIED` is specified, all
  /// devices are returned.
  /// Possible string values are:
  /// - "GATEWAY_TYPE_UNSPECIFIED" : If unspecified, the device is considered a
  /// non-gateway device.
  /// - "GATEWAY" : The device is a gateway.
  /// - "NON_GATEWAY" : The device is not a gateway.
  ///
  /// [pageSize] - The maximum number of devices to return in the response. If
  /// this value is zero, the service will select a default size. A call may
  /// return fewer objects than requested. A non-empty `next_page_token` in the
  /// response indicates that more data is available.
  ///
  /// [pageToken] - The value returned by the last `ListDevicesResponse`;
  /// indicates that this is a continuation of a prior `ListDevices` call and
  /// the system should return the next page of data.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDevicesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDevicesResponse> list(
    core.String parent, {
    core.List<core.String>? deviceIds,
    core.List<core.String>? deviceNumIds,
    core.String? fieldMask,
    core.String? gatewayListOptions_associationsDeviceId,
    core.String? gatewayListOptions_associationsGatewayId,
    core.String? gatewayListOptions_gatewayType,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (deviceIds != null) 'deviceIds': deviceIds,
      if (deviceNumIds != null) 'deviceNumIds': deviceNumIds,
      if (fieldMask != null) 'fieldMask': [fieldMask],
      if (gatewayListOptions_associationsDeviceId != null)
        'gatewayListOptions.associationsDeviceId': [
          gatewayListOptions_associationsDeviceId
        ],
      if (gatewayListOptions_associationsGatewayId != null)
        'gatewayListOptions.associationsGatewayId': [
          gatewayListOptions_associationsGatewayId
        ],
      if (gatewayListOptions_gatewayType != null)
        'gatewayListOptions.gatewayType': [gatewayListOptions_gatewayType],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/devices';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDevicesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Modifies the configuration for the device, which is eventually sent from
  /// the Cloud IoT Core servers.
  ///
  /// Returns the modified configuration version and its metadata.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the device. For example,
  /// `projects/p0/locations/us-central1/registries/registry0/devices/device0`
  /// or
  /// `projects/p0/locations/us-central1/registries/registry0/devices/{num_id}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+/devices/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DeviceConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DeviceConfig> modifyCloudToDeviceConfig(
    ModifyCloudToDeviceConfigRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$name') + ':modifyCloudToDeviceConfig';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DeviceConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a device.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource path name. For example,
  /// `projects/p1/locations/us-central1/registries/registry0/devices/dev0` or
  /// `projects/p1/locations/us-central1/registries/registry0/devices/{num_id}`.
  /// When `name` is populated as a response from the service, it always ends in
  /// the device numeric ID.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+/devices/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Only updates the `device` fields indicated by
  /// this mask. The field mask must not be empty, and it must not contain
  /// fields that are immutable or only set by the server. Mutable top-level
  /// fields: `credentials`, `blocked`, and `metadata`
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
  async.Future<Device> patch(
    Device request,
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
    return Device.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sends a command to the specified device.
  ///
  /// In order for a device to be able to receive commands, it must: 1) be
  /// connected to Cloud IoT Core using the MQTT protocol, and 2) be subscribed
  /// to the group of MQTT topics specified by /devices/{device-id}/commands/#.
  /// This subscription will receive commands at the top-level topic
  /// /devices/{device-id}/commands as well as commands for subfolders, like
  /// /devices/{device-id}/commands/subfolder. Note that subscribing to specific
  /// subfolders is not supported. If the command could not be delivered to the
  /// device, this method will return an error; in particular, if the device is
  /// not subscribed, this method will return FAILED_PRECONDITION. Otherwise,
  /// this method will return OK. If the subscription is QoS 1, at least once
  /// delivery will be guaranteed; for QoS 0, no acknowledgment will be expected
  /// from the device.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the device. For example,
  /// `projects/p0/locations/us-central1/registries/registry0/devices/device0`
  /// or
  /// `projects/p0/locations/us-central1/registries/registry0/devices/{num_id}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+/devices/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SendCommandToDeviceResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SendCommandToDeviceResponse> sendCommandToDevice(
    SendCommandToDeviceRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':sendCommandToDevice';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SendCommandToDeviceResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsRegistriesDevicesConfigVersionsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsRegistriesDevicesConfigVersionsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Lists the last few versions of the device configuration in descending
  /// order (i.e.: newest first).
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the device. For example,
  /// `projects/p0/locations/us-central1/registries/registry0/devices/device0`
  /// or
  /// `projects/p0/locations/us-central1/registries/registry0/devices/{num_id}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+/devices/\[^/\]+$`.
  ///
  /// [numVersions] - The number of versions to list. Versions are listed in
  /// decreasing order of the version number. The maximum number of versions
  /// retained is 10. If this value is zero, it will return all the versions
  /// available.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDeviceConfigVersionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDeviceConfigVersionsResponse> list(
    core.String name, {
    core.int? numVersions,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (numVersions != null) 'numVersions': ['${numVersions}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/configVersions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDeviceConfigVersionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsRegistriesDevicesStatesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsRegistriesDevicesStatesResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists the last few versions of the device state in descending order (i.e.:
  /// newest first).
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the device. For example,
  /// `projects/p0/locations/us-central1/registries/registry0/devices/device0`
  /// or
  /// `projects/p0/locations/us-central1/registries/registry0/devices/{num_id}`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+/devices/\[^/\]+$`.
  ///
  /// [numStates] - The number of states to list. States are listed in
  /// descending order of update time. The maximum number of states retained is
  /// 10. If this value is zero, it will return all the states available.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDeviceStatesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDeviceStatesResponse> list(
    core.String name, {
    core.int? numStates,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (numStates != null) 'numStates': ['${numStates}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/states';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDeviceStatesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsRegistriesGroupsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsRegistriesGroupsDevicesResource get devices =>
      ProjectsLocationsRegistriesGroupsDevicesResource(_requester);

  ProjectsLocationsRegistriesGroupsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets the access control policy for a resource.
  ///
  /// Returns an empty policy if the resource exists and does not have a policy
  /// set.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+/groups/\[^/\]+$`.
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
    GetIamPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy on the specified resource.
  ///
  /// Replaces any existing policy.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+/groups/\[^/\]+$`.
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

  /// Returns permissions that a caller has on the specified resource.
  ///
  /// If the resource does not exist, this will return an empty set of
  /// permissions, not a NOT_FOUND error.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+/groups/\[^/\]+$`.
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

class ProjectsLocationsRegistriesGroupsDevicesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsRegistriesGroupsDevicesResource(commons.ApiRequester client)
      : _requester = client;

  /// List devices in a device registry.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The device registry path. Required. For example,
  /// `projects/my-project/locations/us-central1/registries/my-registry`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/registries/\[^/\]+/groups/\[^/\]+$`.
  ///
  /// [deviceIds] - A list of device string IDs. For example, `['device0',
  /// 'device12']`. If empty, this field is ignored. Maximum IDs: 10,000
  ///
  /// [deviceNumIds] - A list of device numeric IDs. If empty, this field is
  /// ignored. Maximum IDs: 10,000.
  ///
  /// [fieldMask] - The fields of the `Device` resource to be returned in the
  /// response. The fields `id` and `num_id` are always returned, along with any
  /// other fields specified in snake_case format, for example:
  /// `last_heartbeat_time`.
  ///
  /// [gatewayListOptions_associationsDeviceId] - If set, returns only the
  /// gateways with which the specified device is associated. The device ID can
  /// be numeric (`num_id`) or the user-defined string (`id`). For example, if
  /// `456` is specified, returns only the gateways to which the device with
  /// `num_id` 456 is bound.
  ///
  /// [gatewayListOptions_associationsGatewayId] - If set, only devices
  /// associated with the specified gateway are returned. The gateway ID can be
  /// numeric (`num_id`) or the user-defined string (`id`). For example, if
  /// `123` is specified, only devices bound to the gateway with `num_id` 123
  /// are returned.
  ///
  /// [gatewayListOptions_gatewayType] - If `GATEWAY` is specified, only
  /// gateways are returned. If `NON_GATEWAY` is specified, only non-gateway
  /// devices are returned. If `GATEWAY_TYPE_UNSPECIFIED` is specified, all
  /// devices are returned.
  /// Possible string values are:
  /// - "GATEWAY_TYPE_UNSPECIFIED" : If unspecified, the device is considered a
  /// non-gateway device.
  /// - "GATEWAY" : The device is a gateway.
  /// - "NON_GATEWAY" : The device is not a gateway.
  ///
  /// [pageSize] - The maximum number of devices to return in the response. If
  /// this value is zero, the service will select a default size. A call may
  /// return fewer objects than requested. A non-empty `next_page_token` in the
  /// response indicates that more data is available.
  ///
  /// [pageToken] - The value returned by the last `ListDevicesResponse`;
  /// indicates that this is a continuation of a prior `ListDevices` call and
  /// the system should return the next page of data.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDevicesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDevicesResponse> list(
    core.String parent, {
    core.List<core.String>? deviceIds,
    core.List<core.String>? deviceNumIds,
    core.String? fieldMask,
    core.String? gatewayListOptions_associationsDeviceId,
    core.String? gatewayListOptions_associationsGatewayId,
    core.String? gatewayListOptions_gatewayType,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (deviceIds != null) 'deviceIds': deviceIds,
      if (deviceNumIds != null) 'deviceNumIds': deviceNumIds,
      if (fieldMask != null) 'fieldMask': [fieldMask],
      if (gatewayListOptions_associationsDeviceId != null)
        'gatewayListOptions.associationsDeviceId': [
          gatewayListOptions_associationsDeviceId
        ],
      if (gatewayListOptions_associationsGatewayId != null)
        'gatewayListOptions.associationsGatewayId': [
          gatewayListOptions_associationsGatewayId
        ],
      if (gatewayListOptions_gatewayType != null)
        'gatewayListOptions.gatewayType': [gatewayListOptions_gatewayType],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/devices';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDevicesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Request for `BindDeviceToGateway`.
class BindDeviceToGatewayRequest {
  /// The device to associate with the specified gateway.
  ///
  /// The value of `device_id` can be either the device numeric ID or the
  /// user-defined device identifier.
  ///
  /// Required.
  core.String? deviceId;

  /// The value of `gateway_id` can be either the device numeric ID or the
  /// user-defined device identifier.
  ///
  /// Required.
  core.String? gatewayId;

  BindDeviceToGatewayRequest();

  BindDeviceToGatewayRequest.fromJson(core.Map _json) {
    if (_json.containsKey('deviceId')) {
      deviceId = _json['deviceId'] as core.String;
    }
    if (_json.containsKey('gatewayId')) {
      gatewayId = _json['gatewayId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceId != null) 'deviceId': deviceId!,
        if (gatewayId != null) 'gatewayId': gatewayId!,
      };
}

/// Response for `BindDeviceToGateway`.
class BindDeviceToGatewayResponse {
  BindDeviceToGatewayResponse();

  BindDeviceToGatewayResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
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

/// The device resource.
class Device {
  /// If a device is blocked, connections or requests from this device will
  /// fail.
  ///
  /// Can be used to temporarily prevent the device from connecting if, for
  /// example, the sensor is generating bad data and needs maintenance.
  core.bool? blocked;

  /// The most recent device configuration, which is eventually sent from Cloud
  /// IoT Core to the device.
  ///
  /// If not present on creation, the configuration will be initialized with an
  /// empty payload and version value of `1`. To update this field after
  /// creation, use the `DeviceManager.ModifyCloudToDeviceConfig` method.
  DeviceConfig? config;

  /// The credentials used to authenticate this device.
  ///
  /// To allow credential rotation without interruption, multiple device
  /// credentials can be bound to this device. No more than 3 credentials can be
  /// bound to a single device at a time. When new credentials are added to a
  /// device, they are verified against the registry credentials. For details,
  /// see the description of the `DeviceRegistry.credentials` field.
  core.List<DeviceCredential>? credentials;

  /// Gateway-related configuration and state.
  GatewayConfig? gatewayConfig;

  /// The user-defined device identifier.
  ///
  /// The device ID must be unique within a device registry.
  core.String? id;

  /// The last time a cloud-to-device config version acknowledgment was received
  /// from the device.
  ///
  /// This field is only for configurations sent through MQTT.
  ///
  /// Output only.
  core.String? lastConfigAckTime;

  /// The last time a cloud-to-device config version was sent to the device.
  ///
  /// Output only.
  core.String? lastConfigSendTime;

  /// The error message of the most recent error, such as a failure to publish
  /// to Cloud Pub/Sub.
  ///
  /// 'last_error_time' is the timestamp of this field. If no errors have
  /// occurred, this field has an empty message and the status code 0 == OK.
  /// Otherwise, this field is expected to have a status code other than OK.
  ///
  /// Output only.
  Status? lastErrorStatus;

  /// The time the most recent error occurred, such as a failure to publish to
  /// Cloud Pub/Sub.
  ///
  /// This field is the timestamp of 'last_error_status'.
  ///
  /// Output only.
  core.String? lastErrorTime;

  /// The last time a telemetry event was received.
  ///
  /// Timestamps are periodically collected and written to storage; they may be
  /// stale by a few minutes.
  ///
  /// Output only.
  core.String? lastEventTime;

  /// The last time an MQTT `PINGREQ` was received.
  ///
  /// This field applies only to devices connecting through MQTT. MQTT clients
  /// usually only send `PINGREQ` messages if the connection is idle, and no
  /// other messages have been sent. Timestamps are periodically collected and
  /// written to storage; they may be stale by a few minutes.
  ///
  /// Output only.
  core.String? lastHeartbeatTime;

  /// The last time a state event was received.
  ///
  /// Timestamps are periodically collected and written to storage; they may be
  /// stale by a few minutes.
  ///
  /// Output only.
  core.String? lastStateTime;

  /// **Beta Feature** The logging verbosity for device activity.
  ///
  /// If unspecified, DeviceRegistry.log_level will be used.
  /// Possible string values are:
  /// - "LOG_LEVEL_UNSPECIFIED" : No logging specified. If not specified,
  /// logging will be disabled.
  /// - "NONE" : Disables logging.
  /// - "ERROR" : Error events will be logged.
  /// - "INFO" : Informational events will be logged, such as connections and
  /// disconnections.
  /// - "DEBUG" : All events will be logged.
  core.String? logLevel;

  /// The metadata key-value pairs assigned to the device.
  ///
  /// This metadata is not interpreted or indexed by Cloud IoT Core. It can be
  /// used to add contextual information for the device. Keys must conform to
  /// the regular expression a-zA-Z+ and be less than 128 bytes in length.
  /// Values are free-form strings. Each value must be less than or equal to 32
  /// KB in size. The total size of all keys and values must be less than 256
  /// KB, and the maximum number of key-value pairs is 500.
  core.Map<core.String, core.String>? metadata;

  /// The resource path name.
  ///
  /// For example,
  /// `projects/p1/locations/us-central1/registries/registry0/devices/dev0` or
  /// `projects/p1/locations/us-central1/registries/registry0/devices/{num_id}`.
  /// When `name` is populated as a response from the service, it always ends in
  /// the device numeric ID.
  core.String? name;

  /// A server-defined unique numeric ID for the device.
  ///
  /// This is a more compact way to identify devices, and it is globally unique.
  ///
  /// Output only.
  core.String? numId;

  /// The state most recently received from the device.
  ///
  /// If no state has been reported, this field is not present.
  ///
  /// Output only.
  DeviceState? state;

  Device();

  Device.fromJson(core.Map _json) {
    if (_json.containsKey('blocked')) {
      blocked = _json['blocked'] as core.bool;
    }
    if (_json.containsKey('config')) {
      config = DeviceConfig.fromJson(
          _json['config'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('credentials')) {
      credentials = (_json['credentials'] as core.List)
          .map<DeviceCredential>((value) => DeviceCredential.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('gatewayConfig')) {
      gatewayConfig = GatewayConfig.fromJson(
          _json['gatewayConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('lastConfigAckTime')) {
      lastConfigAckTime = _json['lastConfigAckTime'] as core.String;
    }
    if (_json.containsKey('lastConfigSendTime')) {
      lastConfigSendTime = _json['lastConfigSendTime'] as core.String;
    }
    if (_json.containsKey('lastErrorStatus')) {
      lastErrorStatus = Status.fromJson(
          _json['lastErrorStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lastErrorTime')) {
      lastErrorTime = _json['lastErrorTime'] as core.String;
    }
    if (_json.containsKey('lastEventTime')) {
      lastEventTime = _json['lastEventTime'] as core.String;
    }
    if (_json.containsKey('lastHeartbeatTime')) {
      lastHeartbeatTime = _json['lastHeartbeatTime'] as core.String;
    }
    if (_json.containsKey('lastStateTime')) {
      lastStateTime = _json['lastStateTime'] as core.String;
    }
    if (_json.containsKey('logLevel')) {
      logLevel = _json['logLevel'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('numId')) {
      numId = _json['numId'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = DeviceState.fromJson(
          _json['state'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (blocked != null) 'blocked': blocked!,
        if (config != null) 'config': config!.toJson(),
        if (credentials != null)
          'credentials': credentials!.map((value) => value.toJson()).toList(),
        if (gatewayConfig != null) 'gatewayConfig': gatewayConfig!.toJson(),
        if (id != null) 'id': id!,
        if (lastConfigAckTime != null) 'lastConfigAckTime': lastConfigAckTime!,
        if (lastConfigSendTime != null)
          'lastConfigSendTime': lastConfigSendTime!,
        if (lastErrorStatus != null)
          'lastErrorStatus': lastErrorStatus!.toJson(),
        if (lastErrorTime != null) 'lastErrorTime': lastErrorTime!,
        if (lastEventTime != null) 'lastEventTime': lastEventTime!,
        if (lastHeartbeatTime != null) 'lastHeartbeatTime': lastHeartbeatTime!,
        if (lastStateTime != null) 'lastStateTime': lastStateTime!,
        if (logLevel != null) 'logLevel': logLevel!,
        if (metadata != null) 'metadata': metadata!,
        if (name != null) 'name': name!,
        if (numId != null) 'numId': numId!,
        if (state != null) 'state': state!.toJson(),
      };
}

/// The device configuration.
///
/// Eventually delivered to devices.
class DeviceConfig {
  /// The device configuration data.
  core.String? binaryData;
  core.List<core.int> get binaryDataAsBytes =>
      convert.base64.decode(binaryData!);

  set binaryDataAsBytes(core.List<core.int> _bytes) {
    binaryData =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The time at which this configuration version was updated in Cloud IoT
  /// Core.
  ///
  /// This timestamp is set by the server.
  ///
  /// Output only.
  core.String? cloudUpdateTime;

  /// The time at which Cloud IoT Core received the acknowledgment from the
  /// device, indicating that the device has received this configuration
  /// version.
  ///
  /// If this field is not present, the device has not yet acknowledged that it
  /// received this version. Note that when the config was sent to the device,
  /// many config versions may have been available in Cloud IoT Core while the
  /// device was disconnected, and on connection, only the latest version is
  /// sent to the device. Some versions may never be sent to the device, and
  /// therefore are never acknowledged. This timestamp is set by Cloud IoT Core.
  ///
  /// Output only.
  core.String? deviceAckTime;

  /// The version of this update.
  ///
  /// The version number is assigned by the server, and is always greater than 0
  /// after device creation. The version must be 0 on the `CreateDevice` request
  /// if a `config` is specified; the response of `CreateDevice` will always
  /// have a value of 1.
  ///
  /// Output only.
  core.String? version;

  DeviceConfig();

  DeviceConfig.fromJson(core.Map _json) {
    if (_json.containsKey('binaryData')) {
      binaryData = _json['binaryData'] as core.String;
    }
    if (_json.containsKey('cloudUpdateTime')) {
      cloudUpdateTime = _json['cloudUpdateTime'] as core.String;
    }
    if (_json.containsKey('deviceAckTime')) {
      deviceAckTime = _json['deviceAckTime'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (binaryData != null) 'binaryData': binaryData!,
        if (cloudUpdateTime != null) 'cloudUpdateTime': cloudUpdateTime!,
        if (deviceAckTime != null) 'deviceAckTime': deviceAckTime!,
        if (version != null) 'version': version!,
      };
}

/// A server-stored device credential used for authentication.
class DeviceCredential {
  /// The time at which this credential becomes invalid.
  ///
  /// This credential will be ignored for new client authentication requests
  /// after this timestamp; however, it will not be automatically deleted.
  ///
  /// Optional.
  core.String? expirationTime;

  /// A public key used to verify the signature of JSON Web Tokens (JWTs).
  ///
  /// When adding a new device credential, either via device creation or via
  /// modifications, this public key credential may be required to be signed by
  /// one of the registry level certificates. More specifically, if the registry
  /// contains at least one certificate, any new device credential must be
  /// signed by one of the registry certificates. As a result, when the registry
  /// contains certificates, only X.509 certificates are accepted as device
  /// credentials. However, if the registry does not contain a certificate,
  /// self-signed certificates and public keys will be accepted. New device
  /// credentials must be different from every registry-level certificate.
  PublicKeyCredential? publicKey;

  DeviceCredential();

  DeviceCredential.fromJson(core.Map _json) {
    if (_json.containsKey('expirationTime')) {
      expirationTime = _json['expirationTime'] as core.String;
    }
    if (_json.containsKey('publicKey')) {
      publicKey = PublicKeyCredential.fromJson(
          _json['publicKey'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expirationTime != null) 'expirationTime': expirationTime!,
        if (publicKey != null) 'publicKey': publicKey!.toJson(),
      };
}

/// A container for a group of devices.
class DeviceRegistry {
  /// The credentials used to verify the device credentials.
  ///
  /// No more than 10 credentials can be bound to a single registry at a time.
  /// The verification process occurs at the time of device creation or update.
  /// If this field is empty, no verification is performed. Otherwise, the
  /// credentials of a newly created device or added credentials of an updated
  /// device should be signed with one of these registry credentials. Note,
  /// however, that existing devices will never be affected by modifications to
  /// this list of credentials: after a device has been successfully created in
  /// a registry, it should be able to connect even if its registry credentials
  /// are revoked, deleted, or modified.
  core.List<RegistryCredential>? credentials;

  /// The configuration for notification of telemetry events received from the
  /// device.
  ///
  /// All telemetry events that were successfully published by the device and
  /// acknowledged by Cloud IoT Core are guaranteed to be delivered to Cloud
  /// Pub/Sub. If multiple configurations match a message, only the first
  /// matching configuration is used. If you try to publish a device telemetry
  /// event using MQTT without specifying a Cloud Pub/Sub topic for the device's
  /// registry, the connection closes automatically. If you try to do so using
  /// an HTTP connection, an error is returned. Up to 10 configurations may be
  /// provided.
  core.List<EventNotificationConfig>? eventNotificationConfigs;

  /// The DeviceService (HTTP) configuration for this device registry.
  HttpConfig? httpConfig;

  /// The identifier of this device registry.
  ///
  /// For example, `myRegistry`.
  core.String? id;

  /// **Beta Feature** The default logging verbosity for activity from devices
  /// in this registry.
  ///
  /// The verbosity level can be overridden by Device.log_level.
  /// Possible string values are:
  /// - "LOG_LEVEL_UNSPECIFIED" : No logging specified. If not specified,
  /// logging will be disabled.
  /// - "NONE" : Disables logging.
  /// - "ERROR" : Error events will be logged.
  /// - "INFO" : Informational events will be logged, such as connections and
  /// disconnections.
  /// - "DEBUG" : All events will be logged.
  core.String? logLevel;

  /// The MQTT configuration for this device registry.
  MqttConfig? mqttConfig;

  /// The resource path name.
  ///
  /// For example,
  /// `projects/example-project/locations/us-central1/registries/my-registry`.
  core.String? name;

  /// The configuration for notification of new states received from the device.
  ///
  /// State updates are guaranteed to be stored in the state history, but
  /// notifications to Cloud Pub/Sub are not guaranteed. For example, if
  /// permissions are misconfigured or the specified topic doesn't exist, no
  /// notification will be published but the state will still be stored in Cloud
  /// IoT Core.
  StateNotificationConfig? stateNotificationConfig;

  DeviceRegistry();

  DeviceRegistry.fromJson(core.Map _json) {
    if (_json.containsKey('credentials')) {
      credentials = (_json['credentials'] as core.List)
          .map<RegistryCredential>((value) => RegistryCredential.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('eventNotificationConfigs')) {
      eventNotificationConfigs =
          (_json['eventNotificationConfigs'] as core.List)
              .map<EventNotificationConfig>((value) =>
                  EventNotificationConfig.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('httpConfig')) {
      httpConfig = HttpConfig.fromJson(
          _json['httpConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('logLevel')) {
      logLevel = _json['logLevel'] as core.String;
    }
    if (_json.containsKey('mqttConfig')) {
      mqttConfig = MqttConfig.fromJson(
          _json['mqttConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('stateNotificationConfig')) {
      stateNotificationConfig = StateNotificationConfig.fromJson(
          _json['stateNotificationConfig']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (credentials != null)
          'credentials': credentials!.map((value) => value.toJson()).toList(),
        if (eventNotificationConfigs != null)
          'eventNotificationConfigs':
              eventNotificationConfigs!.map((value) => value.toJson()).toList(),
        if (httpConfig != null) 'httpConfig': httpConfig!.toJson(),
        if (id != null) 'id': id!,
        if (logLevel != null) 'logLevel': logLevel!,
        if (mqttConfig != null) 'mqttConfig': mqttConfig!.toJson(),
        if (name != null) 'name': name!,
        if (stateNotificationConfig != null)
          'stateNotificationConfig': stateNotificationConfig!.toJson(),
      };
}

/// The device state, as reported by the device.
class DeviceState {
  /// The device state data.
  core.String? binaryData;
  core.List<core.int> get binaryDataAsBytes =>
      convert.base64.decode(binaryData!);

  set binaryDataAsBytes(core.List<core.int> _bytes) {
    binaryData =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The time at which this state version was updated in Cloud IoT Core.
  ///
  /// Output only.
  core.String? updateTime;

  DeviceState();

  DeviceState.fromJson(core.Map _json) {
    if (_json.containsKey('binaryData')) {
      binaryData = _json['binaryData'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (binaryData != null) 'binaryData': binaryData!,
        if (updateTime != null) 'updateTime': updateTime!,
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

/// The configuration for forwarding telemetry events.
class EventNotificationConfig {
  /// A Cloud Pub/Sub topic name.
  ///
  /// For example, `projects/myProject/topics/deviceEvents`.
  core.String? pubsubTopicName;

  /// If the subfolder name matches this string exactly, this configuration will
  /// be used.
  ///
  /// The string must not include the leading '/' character. If empty, all
  /// strings are matched. This field is used only for telemetry events;
  /// subfolders are not supported for state changes.
  core.String? subfolderMatches;

  EventNotificationConfig();

  EventNotificationConfig.fromJson(core.Map _json) {
    if (_json.containsKey('pubsubTopicName')) {
      pubsubTopicName = _json['pubsubTopicName'] as core.String;
    }
    if (_json.containsKey('subfolderMatches')) {
      subfolderMatches = _json['subfolderMatches'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pubsubTopicName != null) 'pubsubTopicName': pubsubTopicName!,
        if (subfolderMatches != null) 'subfolderMatches': subfolderMatches!,
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

/// Gateway-related configuration and state.
class GatewayConfig {
  /// Indicates how to authorize and/or authenticate devices to access the
  /// gateway.
  /// Possible string values are:
  /// - "GATEWAY_AUTH_METHOD_UNSPECIFIED" : No authentication/authorization
  /// method specified. No devices are allowed to access the gateway.
  /// - "ASSOCIATION_ONLY" : The device is authenticated through the gateway
  /// association only. Device credentials are ignored even if provided.
  /// - "DEVICE_AUTH_TOKEN_ONLY" : The device is authenticated through its own
  /// credentials. Gateway association is not checked.
  /// - "ASSOCIATION_AND_DEVICE_AUTH_TOKEN" : The device is authenticated
  /// through both device credentials and gateway association. The device must
  /// be bound to the gateway and must provide its own credentials.
  core.String? gatewayAuthMethod;

  /// Indicates whether the device is a gateway.
  /// Possible string values are:
  /// - "GATEWAY_TYPE_UNSPECIFIED" : If unspecified, the device is considered a
  /// non-gateway device.
  /// - "GATEWAY" : The device is a gateway.
  /// - "NON_GATEWAY" : The device is not a gateway.
  core.String? gatewayType;

  /// The ID of the gateway the device accessed most recently.
  ///
  /// Output only.
  core.String? lastAccessedGatewayId;

  /// The most recent time at which the device accessed the gateway specified in
  /// `last_accessed_gateway`.
  ///
  /// Output only.
  core.String? lastAccessedGatewayTime;

  GatewayConfig();

  GatewayConfig.fromJson(core.Map _json) {
    if (_json.containsKey('gatewayAuthMethod')) {
      gatewayAuthMethod = _json['gatewayAuthMethod'] as core.String;
    }
    if (_json.containsKey('gatewayType')) {
      gatewayType = _json['gatewayType'] as core.String;
    }
    if (_json.containsKey('lastAccessedGatewayId')) {
      lastAccessedGatewayId = _json['lastAccessedGatewayId'] as core.String;
    }
    if (_json.containsKey('lastAccessedGatewayTime')) {
      lastAccessedGatewayTime = _json['lastAccessedGatewayTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gatewayAuthMethod != null) 'gatewayAuthMethod': gatewayAuthMethod!,
        if (gatewayType != null) 'gatewayType': gatewayType!,
        if (lastAccessedGatewayId != null)
          'lastAccessedGatewayId': lastAccessedGatewayId!,
        if (lastAccessedGatewayTime != null)
          'lastAccessedGatewayTime': lastAccessedGatewayTime!,
      };
}

/// Request message for `GetIamPolicy` method.
class GetIamPolicyRequest {
  /// OPTIONAL: A `GetPolicyOptions` object for specifying options to
  /// `GetIamPolicy`.
  GetPolicyOptions? options;

  GetIamPolicyRequest();

  GetIamPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('options')) {
      options = GetPolicyOptions.fromJson(
          _json['options'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (options != null) 'options': options!.toJson(),
      };
}

/// Encapsulates settings provided to GetIamPolicy.
class GetPolicyOptions {
  /// The policy format version to be returned.
  ///
  /// Valid values are 0, 1, and 3. Requests specifying an invalid value will be
  /// rejected. Requests for policies with any conditional bindings must specify
  /// version 3. Policies without any conditional bindings may specify any valid
  /// value or leave the field unset. To learn which resources support
  /// conditions in their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  ///
  /// Optional.
  core.int? requestedPolicyVersion;

  GetPolicyOptions();

  GetPolicyOptions.fromJson(core.Map _json) {
    if (_json.containsKey('requestedPolicyVersion')) {
      requestedPolicyVersion = _json['requestedPolicyVersion'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (requestedPolicyVersion != null)
          'requestedPolicyVersion': requestedPolicyVersion!,
      };
}

/// The configuration of the HTTP bridge for a device registry.
class HttpConfig {
  /// If enabled, allows devices to use DeviceService via the HTTP protocol.
  ///
  /// Otherwise, any requests to DeviceService will fail for this registry.
  /// Possible string values are:
  /// - "HTTP_STATE_UNSPECIFIED" : No HTTP state specified. If not specified,
  /// DeviceService will be enabled by default.
  /// - "HTTP_ENABLED" : Enables DeviceService (HTTP) service for the registry.
  /// - "HTTP_DISABLED" : Disables DeviceService (HTTP) service for the
  /// registry.
  core.String? httpEnabledState;

  HttpConfig();

  HttpConfig.fromJson(core.Map _json) {
    if (_json.containsKey('httpEnabledState')) {
      httpEnabledState = _json['httpEnabledState'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (httpEnabledState != null) 'httpEnabledState': httpEnabledState!,
      };
}

/// Response for `ListDeviceConfigVersions`.
class ListDeviceConfigVersionsResponse {
  /// The device configuration for the last few versions.
  ///
  /// Versions are listed in decreasing order, starting from the most recent
  /// one.
  core.List<DeviceConfig>? deviceConfigs;

  ListDeviceConfigVersionsResponse();

  ListDeviceConfigVersionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('deviceConfigs')) {
      deviceConfigs = (_json['deviceConfigs'] as core.List)
          .map<DeviceConfig>((value) => DeviceConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceConfigs != null)
          'deviceConfigs':
              deviceConfigs!.map((value) => value.toJson()).toList(),
      };
}

/// Response for `ListDeviceRegistries`.
class ListDeviceRegistriesResponse {
  /// The registries that matched the query.
  core.List<DeviceRegistry>? deviceRegistries;

  /// If not empty, indicates that there may be more registries that match the
  /// request; this value should be passed in a new
  /// `ListDeviceRegistriesRequest`.
  core.String? nextPageToken;

  ListDeviceRegistriesResponse();

  ListDeviceRegistriesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('deviceRegistries')) {
      deviceRegistries = (_json['deviceRegistries'] as core.List)
          .map<DeviceRegistry>((value) => DeviceRegistry.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceRegistries != null)
          'deviceRegistries':
              deviceRegistries!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response for `ListDeviceStates`.
class ListDeviceStatesResponse {
  /// The last few device states.
  ///
  /// States are listed in descending order of server update time, starting from
  /// the most recent one.
  core.List<DeviceState>? deviceStates;

  ListDeviceStatesResponse();

  ListDeviceStatesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('deviceStates')) {
      deviceStates = (_json['deviceStates'] as core.List)
          .map<DeviceState>((value) => DeviceState.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceStates != null)
          'deviceStates': deviceStates!.map((value) => value.toJson()).toList(),
      };
}

/// Response for `ListDevices`.
class ListDevicesResponse {
  /// The devices that match the request.
  core.List<Device>? devices;

  /// If not empty, indicates that there may be more devices that match the
  /// request; this value should be passed in a new `ListDevicesRequest`.
  core.String? nextPageToken;

  ListDevicesResponse();

  ListDevicesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('devices')) {
      devices = (_json['devices'] as core.List)
          .map<Device>((value) =>
              Device.fromJson(value as core.Map<core.String, core.dynamic>))
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

/// Request for `ModifyCloudToDeviceConfig`.
class ModifyCloudToDeviceConfigRequest {
  /// The configuration data for the device.
  ///
  /// Required.
  core.String? binaryData;
  core.List<core.int> get binaryDataAsBytes =>
      convert.base64.decode(binaryData!);

  set binaryDataAsBytes(core.List<core.int> _bytes) {
    binaryData =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The version number to update.
  ///
  /// If this value is zero, it will not check the version number of the server
  /// and will always update the current version; otherwise, this update will
  /// fail if the version number found on the server does not match this version
  /// number. This is used to support multiple simultaneous updates without
  /// losing data.
  core.String? versionToUpdate;

  ModifyCloudToDeviceConfigRequest();

  ModifyCloudToDeviceConfigRequest.fromJson(core.Map _json) {
    if (_json.containsKey('binaryData')) {
      binaryData = _json['binaryData'] as core.String;
    }
    if (_json.containsKey('versionToUpdate')) {
      versionToUpdate = _json['versionToUpdate'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (binaryData != null) 'binaryData': binaryData!,
        if (versionToUpdate != null) 'versionToUpdate': versionToUpdate!,
      };
}

/// The configuration of MQTT for a device registry.
class MqttConfig {
  /// If enabled, allows connections using the MQTT protocol.
  ///
  /// Otherwise, MQTT connections to this registry will fail.
  /// Possible string values are:
  /// - "MQTT_STATE_UNSPECIFIED" : No MQTT state specified. If not specified,
  /// MQTT will be enabled by default.
  /// - "MQTT_ENABLED" : Enables a MQTT connection.
  /// - "MQTT_DISABLED" : Disables a MQTT connection.
  core.String? mqttEnabledState;

  MqttConfig();

  MqttConfig.fromJson(core.Map _json) {
    if (_json.containsKey('mqttEnabledState')) {
      mqttEnabledState = _json['mqttEnabledState'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mqttEnabledState != null) 'mqttEnabledState': mqttEnabledState!,
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
        if (bindings != null)
          'bindings': bindings!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (version != null) 'version': version!,
      };
}

/// A public key certificate format and data.
class PublicKeyCertificate {
  /// The certificate data.
  core.String? certificate;

  /// The certificate format.
  /// Possible string values are:
  /// - "UNSPECIFIED_PUBLIC_KEY_CERTIFICATE_FORMAT" : The format has not been
  /// specified. This is an invalid default value and must not be used.
  /// - "X509_CERTIFICATE_PEM" : An X.509v3 certificate
  /// ([RFC5280](https://www.ietf.org/rfc/rfc5280.txt)), encoded in base64, and
  /// wrapped by `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----`.
  core.String? format;

  /// The certificate details.
  ///
  /// Used only for X.509 certificates.
  ///
  /// Output only.
  X509CertificateDetails? x509Details;

  PublicKeyCertificate();

  PublicKeyCertificate.fromJson(core.Map _json) {
    if (_json.containsKey('certificate')) {
      certificate = _json['certificate'] as core.String;
    }
    if (_json.containsKey('format')) {
      format = _json['format'] as core.String;
    }
    if (_json.containsKey('x509Details')) {
      x509Details = X509CertificateDetails.fromJson(
          _json['x509Details'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (certificate != null) 'certificate': certificate!,
        if (format != null) 'format': format!,
        if (x509Details != null) 'x509Details': x509Details!.toJson(),
      };
}

/// A public key format and data.
class PublicKeyCredential {
  /// The format of the key.
  /// Possible string values are:
  /// - "UNSPECIFIED_PUBLIC_KEY_FORMAT" : The format has not been specified.
  /// This is an invalid default value and must not be used.
  /// - "RSA_PEM" : An RSA public key encoded in base64, and wrapped by
  /// `-----BEGIN PUBLIC KEY-----` and `-----END PUBLIC KEY-----`. This can be
  /// used to verify `RS256` signatures in JWT tokens (\[RFC7518\](
  /// https://www.ietf.org/rfc/rfc7518.txt)).
  /// - "RSA_X509_PEM" : As RSA_PEM, but wrapped in an X.509v3 certificate
  /// (\[RFC5280\]( https://www.ietf.org/rfc/rfc5280.txt)), encoded in base64,
  /// and wrapped by `-----BEGIN CERTIFICATE-----` and `-----END
  /// CERTIFICATE-----`.
  /// - "ES256_PEM" : Public key for the ECDSA algorithm using P-256 and
  /// SHA-256, encoded in base64, and wrapped by `-----BEGIN PUBLIC KEY-----`
  /// and `-----END PUBLIC KEY-----`. This can be used to verify JWT tokens with
  /// the `ES256` algorithm ([RFC7518](https://www.ietf.org/rfc/rfc7518.txt)).
  /// This curve is defined in [OpenSSL](https://www.openssl.org/) as the
  /// `prime256v1` curve.
  /// - "ES256_X509_PEM" : As ES256_PEM, but wrapped in an X.509v3 certificate
  /// (\[RFC5280\]( https://www.ietf.org/rfc/rfc5280.txt)), encoded in base64,
  /// and wrapped by `-----BEGIN CERTIFICATE-----` and `-----END
  /// CERTIFICATE-----`.
  core.String? format;

  /// The key data.
  core.String? key;

  PublicKeyCredential();

  PublicKeyCredential.fromJson(core.Map _json) {
    if (_json.containsKey('format')) {
      format = _json['format'] as core.String;
    }
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (format != null) 'format': format!,
        if (key != null) 'key': key!,
      };
}

/// A server-stored registry credential used to validate device credentials.
class RegistryCredential {
  /// A public key certificate used to verify the device credentials.
  PublicKeyCertificate? publicKeyCertificate;

  RegistryCredential();

  RegistryCredential.fromJson(core.Map _json) {
    if (_json.containsKey('publicKeyCertificate')) {
      publicKeyCertificate = PublicKeyCertificate.fromJson(
          _json['publicKeyCertificate'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (publicKeyCertificate != null)
          'publicKeyCertificate': publicKeyCertificate!.toJson(),
      };
}

/// Request for `SendCommandToDevice`.
class SendCommandToDeviceRequest {
  /// The command data to send to the device.
  ///
  /// Required.
  core.String? binaryData;
  core.List<core.int> get binaryDataAsBytes =>
      convert.base64.decode(binaryData!);

  set binaryDataAsBytes(core.List<core.int> _bytes) {
    binaryData =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Optional subfolder for the command.
  ///
  /// If empty, the command will be delivered to the
  /// /devices/{device-id}/commands topic, otherwise it will be delivered to the
  /// /devices/{device-id}/commands/{subfolder} topic. Multi-level subfolders
  /// are allowed. This field must not have more than 256 characters, and must
  /// not contain any MQTT wildcards ("+" or "#") or null characters.
  core.String? subfolder;

  SendCommandToDeviceRequest();

  SendCommandToDeviceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('binaryData')) {
      binaryData = _json['binaryData'] as core.String;
    }
    if (_json.containsKey('subfolder')) {
      subfolder = _json['subfolder'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (binaryData != null) 'binaryData': binaryData!,
        if (subfolder != null) 'subfolder': subfolder!,
      };
}

/// Response for `SendCommandToDevice`.
class SendCommandToDeviceResponse {
  SendCommandToDeviceResponse();

  SendCommandToDeviceResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Request message for `SetIamPolicy` method.
class SetIamPolicyRequest {
  /// REQUIRED: The complete policy to be applied to the `resource`.
  ///
  /// The size of the policy is limited to a few 10s of KB. An empty policy is a
  /// valid policy but certain Cloud Platform services (such as Projects) might
  /// reject them.
  Policy? policy;

  SetIamPolicyRequest();

  SetIamPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('policy')) {
      policy = Policy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (policy != null) 'policy': policy!.toJson(),
      };
}

/// The configuration for notification of new states received from the device.
class StateNotificationConfig {
  /// A Cloud Pub/Sub topic name.
  ///
  /// For example, `projects/myProject/topics/deviceEvents`.
  core.String? pubsubTopicName;

  StateNotificationConfig();

  StateNotificationConfig.fromJson(core.Map _json) {
    if (_json.containsKey('pubsubTopicName')) {
      pubsubTopicName = _json['pubsubTopicName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pubsubTopicName != null) 'pubsubTopicName': pubsubTopicName!,
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

/// Request for `UnbindDeviceFromGateway`.
class UnbindDeviceFromGatewayRequest {
  /// The device to disassociate from the specified gateway.
  ///
  /// The value of `device_id` can be either the device numeric ID or the
  /// user-defined device identifier.
  ///
  /// Required.
  core.String? deviceId;

  /// The value of `gateway_id` can be either the device numeric ID or the
  /// user-defined device identifier.
  ///
  /// Required.
  core.String? gatewayId;

  UnbindDeviceFromGatewayRequest();

  UnbindDeviceFromGatewayRequest.fromJson(core.Map _json) {
    if (_json.containsKey('deviceId')) {
      deviceId = _json['deviceId'] as core.String;
    }
    if (_json.containsKey('gatewayId')) {
      gatewayId = _json['gatewayId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceId != null) 'deviceId': deviceId!,
        if (gatewayId != null) 'gatewayId': gatewayId!,
      };
}

/// Response for `UnbindDeviceFromGateway`.
class UnbindDeviceFromGatewayResponse {
  UnbindDeviceFromGatewayResponse();

  UnbindDeviceFromGatewayResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Details of an X.509 certificate.
///
/// For informational purposes only.
class X509CertificateDetails {
  /// The time the certificate becomes invalid.
  core.String? expiryTime;

  /// The entity that signed the certificate.
  core.String? issuer;

  /// The type of public key in the certificate.
  core.String? publicKeyType;

  /// The algorithm used to sign the certificate.
  core.String? signatureAlgorithm;

  /// The time the certificate becomes valid.
  core.String? startTime;

  /// The entity the certificate and public key belong to.
  core.String? subject;

  X509CertificateDetails();

  X509CertificateDetails.fromJson(core.Map _json) {
    if (_json.containsKey('expiryTime')) {
      expiryTime = _json['expiryTime'] as core.String;
    }
    if (_json.containsKey('issuer')) {
      issuer = _json['issuer'] as core.String;
    }
    if (_json.containsKey('publicKeyType')) {
      publicKeyType = _json['publicKeyType'] as core.String;
    }
    if (_json.containsKey('signatureAlgorithm')) {
      signatureAlgorithm = _json['signatureAlgorithm'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('subject')) {
      subject = _json['subject'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expiryTime != null) 'expiryTime': expiryTime!,
        if (issuer != null) 'issuer': issuer!,
        if (publicKeyType != null) 'publicKeyType': publicKeyType!,
        if (signatureAlgorithm != null)
          'signatureAlgorithm': signatureAlgorithm!,
        if (startTime != null) 'startTime': startTime!,
        if (subject != null) 'subject': subject!,
      };
}

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

/// Smart Device Management API - v1
///
/// Allow select enterprise partners to access, control, and manage Google and
/// Nest devices programmatically.
///
/// For more information, see <https://developers.google.com/nest/device-access>
///
/// Create an instance of [SmartDeviceManagementApi] to access these resources:
///
/// - [EnterprisesResource]
///   - [EnterprisesDevicesResource]
///   - [EnterprisesStructuresResource]
///     - [EnterprisesStructuresRoomsResource]
library smartdevicemanagement.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Allow select enterprise partners to access, control, and manage Google and
/// Nest devices programmatically.
class SmartDeviceManagementApi {
  /// See and/or control the devices that you selected
  static const sdmServiceScope = 'https://www.googleapis.com/auth/sdm.service';

  final commons.ApiRequester _requester;

  EnterprisesResource get enterprises => EnterprisesResource(_requester);

  SmartDeviceManagementApi(http.Client client,
      {core.String rootUrl = 'https://smartdevicemanagement.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class EnterprisesResource {
  final commons.ApiRequester _requester;

  EnterprisesDevicesResource get devices =>
      EnterprisesDevicesResource(_requester);
  EnterprisesStructuresResource get structures =>
      EnterprisesStructuresResource(_requester);

  EnterprisesResource(commons.ApiRequester client) : _requester = client;
}

class EnterprisesDevicesResource {
  final commons.ApiRequester _requester;

  EnterprisesDevicesResource(commons.ApiRequester client) : _requester = client;

  /// Executes a command to device managed by the enterprise.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the device requested. For example:
  /// "enterprises/XYZ/devices/123"
  /// Value must have pattern `^enterprises/\[^/\]+/devices/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleHomeEnterpriseSdmV1ExecuteDeviceCommandResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleHomeEnterpriseSdmV1ExecuteDeviceCommandResponse>
      executeCommand(
    GoogleHomeEnterpriseSdmV1ExecuteDeviceCommandRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':executeCommand';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleHomeEnterpriseSdmV1ExecuteDeviceCommandResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a device managed by the enterprise.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the device requested. For example:
  /// "enterprises/XYZ/devices/123"
  /// Value must have pattern `^enterprises/\[^/\]+/devices/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleHomeEnterpriseSdmV1Device].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleHomeEnterpriseSdmV1Device> get(
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
    return GoogleHomeEnterpriseSdmV1Device.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists devices managed by the enterprise.
  ///
  /// Request parameters:
  ///
  /// [parent] - The parent enterprise to list devices under. E.g.
  /// "enterprises/XYZ".
  /// Value must have pattern `^enterprises/\[^/\]+$`.
  ///
  /// [filter] - Optional filter to list devices. Filters can be done on: Device
  /// custom name (substring match): 'customName=wing'
  ///
  /// [pageSize] - Optional requested page size. Server may return fewer devices
  /// than requested. If unspecified, server will pick an appropriate default.
  ///
  /// [pageToken] - Optional token of the page to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleHomeEnterpriseSdmV1ListDevicesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleHomeEnterpriseSdmV1ListDevicesResponse> list(
    core.String parent, {
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/devices';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleHomeEnterpriseSdmV1ListDevicesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class EnterprisesStructuresResource {
  final commons.ApiRequester _requester;

  EnterprisesStructuresRoomsResource get rooms =>
      EnterprisesStructuresRoomsResource(_requester);

  EnterprisesStructuresResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets a structure managed by the enterprise.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the structure requested. For example:
  /// "enterprises/XYZ/structures/ABC".
  /// Value must have pattern `^enterprises/\[^/\]+/structures/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleHomeEnterpriseSdmV1Structure].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleHomeEnterpriseSdmV1Structure> get(
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
    return GoogleHomeEnterpriseSdmV1Structure.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists structures managed by the enterprise.
  ///
  /// Request parameters:
  ///
  /// [parent] - The parent enterprise to list structures under. E.g.
  /// "enterprises/XYZ".
  /// Value must have pattern `^enterprises/\[^/\]+$`.
  ///
  /// [filter] - Optional filter to list structures.
  ///
  /// [pageSize] - Requested page size. Server may return fewer structures than
  /// requested. If unspecified, server will pick an appropriate default.
  ///
  /// [pageToken] - The token of the page to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleHomeEnterpriseSdmV1ListStructuresResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleHomeEnterpriseSdmV1ListStructuresResponse> list(
    core.String parent, {
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/structures';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleHomeEnterpriseSdmV1ListStructuresResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class EnterprisesStructuresRoomsResource {
  final commons.ApiRequester _requester;

  EnterprisesStructuresRoomsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets a room managed by the enterprise.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the room requested. For example:
  /// "enterprises/XYZ/structures/ABC/rooms/123".
  /// Value must have pattern
  /// `^enterprises/\[^/\]+/structures/\[^/\]+/rooms/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleHomeEnterpriseSdmV1Room].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleHomeEnterpriseSdmV1Room> get(
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
    return GoogleHomeEnterpriseSdmV1Room.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists rooms managed by the enterprise.
  ///
  /// Request parameters:
  ///
  /// [parent] - The parent resource name of the rooms requested. For example:
  /// "enterprises/XYZ/structures/ABC".
  /// Value must have pattern `^enterprises/\[^/\]+/structures/\[^/\]+$`.
  ///
  /// [pageSize] - Requested page size. Server may return fewer rooms than
  /// requested. If unspecified, server will pick an appropriate default.
  ///
  /// [pageToken] - The token of the page to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleHomeEnterpriseSdmV1ListRoomsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleHomeEnterpriseSdmV1ListRoomsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/rooms';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleHomeEnterpriseSdmV1ListRoomsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Device resource represents an instance of enterprise managed device in the
/// property.
class GoogleHomeEnterpriseSdmV1Device {
  /// The resource name of the device.
  ///
  /// For example: "enterprises/XYZ/devices/123".
  ///
  /// Required.
  core.String? name;

  /// Assignee details of the device.
  core.List<GoogleHomeEnterpriseSdmV1ParentRelation>? parentRelations;

  /// Device traits.
  ///
  /// Output only.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? traits;

  /// Type of the device for general display purposes.
  ///
  /// For example: "THERMOSTAT". The device type should not be used to deduce or
  /// infer functionality of the actual device it is assigned to. Instead, use
  /// the returned traits for the device.
  ///
  /// Output only.
  core.String? type;

  GoogleHomeEnterpriseSdmV1Device();

  GoogleHomeEnterpriseSdmV1Device.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parentRelations')) {
      parentRelations = (_json['parentRelations'] as core.List)
          .map<GoogleHomeEnterpriseSdmV1ParentRelation>((value) =>
              GoogleHomeEnterpriseSdmV1ParentRelation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('traits')) {
      traits = (_json['traits'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (parentRelations != null)
          'parentRelations':
              parentRelations!.map((value) => value.toJson()).toList(),
        if (traits != null) 'traits': traits!,
        if (type != null) 'type': type!,
      };
}

/// Request message for SmartDeviceManagementService.ExecuteDeviceCommand
class GoogleHomeEnterpriseSdmV1ExecuteDeviceCommandRequest {
  /// The command name to execute, represented by the fully qualified protobuf
  /// message name.
  core.String? command;

  /// The command message to execute, represented as a Struct.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? params;

  GoogleHomeEnterpriseSdmV1ExecuteDeviceCommandRequest();

  GoogleHomeEnterpriseSdmV1ExecuteDeviceCommandRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('command')) {
      command = _json['command'] as core.String;
    }
    if (_json.containsKey('params')) {
      params = (_json['params'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (command != null) 'command': command!,
        if (params != null) 'params': params!,
      };
}

/// Response message for SmartDeviceManagementService.ExecuteDeviceCommand
class GoogleHomeEnterpriseSdmV1ExecuteDeviceCommandResponse {
  /// The results of executing the command.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? results;

  GoogleHomeEnterpriseSdmV1ExecuteDeviceCommandResponse();

  GoogleHomeEnterpriseSdmV1ExecuteDeviceCommandResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('results')) {
      results = (_json['results'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (results != null) 'results': results!,
      };
}

/// Response message for SmartDeviceManagementService.ListDevices
class GoogleHomeEnterpriseSdmV1ListDevicesResponse {
  /// The list of devices.
  core.List<GoogleHomeEnterpriseSdmV1Device>? devices;

  /// The pagination token to retrieve the next page of results.
  core.String? nextPageToken;

  GoogleHomeEnterpriseSdmV1ListDevicesResponse();

  GoogleHomeEnterpriseSdmV1ListDevicesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('devices')) {
      devices = (_json['devices'] as core.List)
          .map<GoogleHomeEnterpriseSdmV1Device>((value) =>
              GoogleHomeEnterpriseSdmV1Device.fromJson(
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

/// Response message for SmartDeviceManagementService.ListRooms
class GoogleHomeEnterpriseSdmV1ListRoomsResponse {
  /// The pagination token to retrieve the next page of results.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// The list of rooms.
  core.List<GoogleHomeEnterpriseSdmV1Room>? rooms;

  GoogleHomeEnterpriseSdmV1ListRoomsResponse();

  GoogleHomeEnterpriseSdmV1ListRoomsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('rooms')) {
      rooms = (_json['rooms'] as core.List)
          .map<GoogleHomeEnterpriseSdmV1Room>((value) =>
              GoogleHomeEnterpriseSdmV1Room.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (rooms != null)
          'rooms': rooms!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for SmartDeviceManagementService.ListStructures
class GoogleHomeEnterpriseSdmV1ListStructuresResponse {
  /// The pagination token to retrieve the next page of results.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  /// The list of structures.
  core.List<GoogleHomeEnterpriseSdmV1Structure>? structures;

  GoogleHomeEnterpriseSdmV1ListStructuresResponse();

  GoogleHomeEnterpriseSdmV1ListStructuresResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('structures')) {
      structures = (_json['structures'] as core.List)
          .map<GoogleHomeEnterpriseSdmV1Structure>((value) =>
              GoogleHomeEnterpriseSdmV1Structure.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (structures != null)
          'structures': structures!.map((value) => value.toJson()).toList(),
      };
}

/// Represents device relationships, for instance, structure/room to which the
/// device is assigned to.
class GoogleHomeEnterpriseSdmV1ParentRelation {
  /// The custom name of the relation -- e.g., structure/room where the device
  /// is assigned to.
  ///
  /// Output only.
  core.String? displayName;

  /// The name of the relation -- e.g., structure/room where the device is
  /// assigned to.
  ///
  /// For example: "enterprises/XYZ/structures/ABC" or
  /// "enterprises/XYZ/structures/ABC/rooms/123"
  ///
  /// Output only.
  core.String? parent;

  GoogleHomeEnterpriseSdmV1ParentRelation();

  GoogleHomeEnterpriseSdmV1ParentRelation.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (parent != null) 'parent': parent!,
      };
}

/// Room resource represents an instance of sub-space within a structure such as
/// rooms in a hotel suite or rental apartment.
class GoogleHomeEnterpriseSdmV1Room {
  /// The resource name of the room.
  ///
  /// For example: "enterprises/XYZ/structures/ABC/rooms/123".
  ///
  /// Output only.
  core.String? name;

  /// Room traits.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? traits;

  GoogleHomeEnterpriseSdmV1Room();

  GoogleHomeEnterpriseSdmV1Room.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('traits')) {
      traits = (_json['traits'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (traits != null) 'traits': traits!,
      };
}

/// Structure resource represents an instance of enterprise managed home or
/// hotel room.
class GoogleHomeEnterpriseSdmV1Structure {
  /// The resource name of the structure.
  ///
  /// For example: "enterprises/XYZ/structures/ABC".
  ///
  /// Output only.
  core.String? name;

  /// Structure traits.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? traits;

  GoogleHomeEnterpriseSdmV1Structure();

  GoogleHomeEnterpriseSdmV1Structure.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('traits')) {
      traits = (_json['traits'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (traits != null) 'traits': traits!,
      };
}

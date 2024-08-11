// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

// TODO(bkonyi): refactor into io_resource_info.dart
const int _versionMajor = 4;
const int _versionMinor = 0;

const String _tcpSocket = 'tcp';
const String _udpSocket = 'udp';

// Creates a Map conforming to the HttpProfileRequest type defined in the
// dart:io service extension spec from an element of dart:developer's
// [_developerProfilingData].
Future<Map<String, dynamic>> _createHttpProfileRequestFromProfileMap(
    Map<String, dynamic> requestProfile,
    {required bool ref}) async {
  final responseData = requestProfile['responseData'] as Map<String, dynamic>;

  return <String, dynamic>{
    'type': '${ref ? '@' : ''}HttpProfileRequest',
    'id': requestProfile['id']!,
    'isolateId': requestProfile['isolateId']!,
    'method': requestProfile['requestMethod']!,
    'uri': requestProfile['requestUri']!,
    'events': requestProfile['events']!,
    'startTime': requestProfile['requestStartTimestamp']!,
    if (requestProfile['requestEndTimestamp'] != null)
      'endTime': requestProfile['requestEndTimestamp'],
    'request': requestProfile['requestData']!,
    'response': responseData,
    if (!ref && requestProfile['requestEndTimestamp'] != null)
      'requestBody': requestProfile['requestBodyBytes']!,
    if (!ref && responseData['endTime'] != null)
      'responseBody': requestProfile['responseBodyBytes']!,
  };
}

@pragma('vm:entry-point', !const bool.fromEnvironment("dart.vm.product"))
abstract class _NetworkProfiling {
  // Http relative RPCs
  static const _kHttpEnableTimelineLogging =
      'ext.dart.io.httpEnableTimelineLogging';
  static const _kGetHttpProfileRPC = 'ext.dart.io.getHttpProfile';
  static const _kGetHttpProfileRequestRPC = 'ext.dart.io.getHttpProfileRequest';
  static const _kClearHttpProfileRPC = 'ext.dart.io.clearHttpProfile';
  // Socket relative RPCs
  static const _kClearSocketProfileRPC = 'ext.dart.io.clearSocketProfile';
  static const _kGetSocketProfileRPC = 'ext.dart.io.getSocketProfile';
  static const _kSocketProfilingEnabledRPC =
      'ext.dart.io.socketProfilingEnabled';

  // TODO(zichangguo): This version number represents the version of service
  // extension of dart:io. Consider moving this out of web profiler class,
  // if more methods added to dart:io,
  static const _kGetVersionRPC = 'ext.dart.io.getVersion';

  @pragma('vm:entry-point', !const bool.fromEnvironment("dart.vm.product"))
  static void _registerServiceExtension() {
    registerExtension(_kHttpEnableTimelineLogging, _serviceExtensionHandler);
    registerExtension(_kGetSocketProfileRPC, _serviceExtensionHandler);
    registerExtension(_kSocketProfilingEnabledRPC, _serviceExtensionHandler);
    registerExtension(_kClearSocketProfileRPC, _serviceExtensionHandler);
    registerExtension(_kGetVersionRPC, _serviceExtensionHandler);
    registerExtension(_kGetHttpProfileRPC, _serviceExtensionHandler);
    registerExtension(_kGetHttpProfileRequestRPC, _serviceExtensionHandler);
    registerExtension(_kClearHttpProfileRPC, _serviceExtensionHandler);
  }

  static Future<ServiceExtensionResponse> _serviceExtensionHandler(
      String method, Map<String, String> parameters) async {
    try {
      String responseJson;
      switch (method) {
        case _kHttpEnableTimelineLogging:
          if (parameters.containsKey('enabled')) {
            _setHttpEnableTimelineLogging(parameters);
          }
          responseJson = _getHttpEnableTimelineLogging();
          break;
        case _kGetHttpProfileRPC:
          final updatedSince = parameters.containsKey('updatedSince')
              ? int.tryParse(parameters['updatedSince']!)
              : null;
          responseJson = json.encode({
            'type': 'HttpProfile',
            'timestamp': DateTime.now().microsecondsSinceEpoch,
            'requests': [
              ...HttpProfiler.serializeHttpProfileRequests(updatedSince),
              ...await Future.wait(getHttpClientProfilingData()
                  .where((final Map<String, dynamic> p) =>
                      updatedSince == null ||
                      (p['_lastUpdateTime'] as int) >= updatedSince)
                  .map((p) =>
                      _createHttpProfileRequestFromProfileMap(p, ref: true)))
            ],
          });
          break;
        case _kGetHttpProfileRequestRPC:
          responseJson = await _getHttpProfileRequest(parameters);
          break;
        case _kClearHttpProfileRPC:
          HttpProfiler.clear();
          responseJson = _success();
          break;
        case _kGetSocketProfileRPC:
          responseJson = _SocketProfile.toJson();
          break;
        case _kSocketProfilingEnabledRPC:
          responseJson = _socketProfilingEnabled(parameters);
          break;
        case _kClearSocketProfileRPC:
          responseJson = _SocketProfile.clear();
          break;
        case _kGetVersionRPC:
          responseJson = getVersion();
          break;
        default:
          return ServiceExtensionResponse.error(
            ServiceExtensionResponse.extensionError,
            'Method $method does not exist',
          );
      }
      return ServiceExtensionResponse.result(responseJson);
    } catch (errorMessage) {
      return ServiceExtensionResponse.error(
        ServiceExtensionResponse.invalidParams,
        errorMessage.toString(),
      );
    }
  }

  static String getVersion() => json.encode({
        'type': 'Version',
        'major': _versionMajor,
        'minor': _versionMinor,
      });
}

String _success() => json.encode({
      'type': 'Success',
    });

String _invalidArgument(String argument, dynamic value) =>
    "Value for parameter '$argument' is not valid: $value";

String _missingArgument(String argument) => "Parameter '$argument' is required";

String _getHttpEnableTimelineLogging() => json.encode({
      'type': 'HttpTimelineLoggingState',
      'enabled': HttpClient.enableTimelineLogging,
    });

String _setHttpEnableTimelineLogging(Map<String, String> parameters) {
  const String kEnabled = 'enabled';
  if (!parameters.containsKey(kEnabled)) {
    throw _missingArgument(kEnabled);
  }
  final enable = parameters[kEnabled]!.toLowerCase();
  if (enable != 'true' && enable != 'false') {
    throw _invalidArgument(kEnabled, enable);
  }
  HttpClient.enableTimelineLogging = enable == 'true';
  return _success();
}

Future<String> _getHttpProfileRequest(Map<String, String> parameters) async {
  if (!parameters.containsKey('id')) {
    throw _missingArgument('id');
  }
  final id = parameters['id']!;
  final request;
  if (id.startsWith('from_package/')) {
    final profileMap = getHttpClientProfilingData()
        .elementAtOrNull(int.parse(id.substring('from_package/'.length)) - 1);
    request = profileMap == null
        ? null
        : await _createHttpProfileRequestFromProfileMap(profileMap, ref: false);
  } else {
    request = HttpProfiler.getHttpProfileRequest(id)?.toJson(ref: false);
  }

  if (request == null) {
    throw "Unable to find request with id: '$id'";
  }
  return json.encode(request);
}

String _socketProfilingEnabled(Map<String, String> parameters) {
  const String kEnabled = 'enabled';
  if (parameters.containsKey(kEnabled)) {
    final enable = parameters[kEnabled]!.toLowerCase();
    if (enable != 'true' && enable != 'false') {
      throw _invalidArgument(kEnabled, enable);
    }
    enable == 'true' ? _SocketProfile.start() : _SocketProfile.pause();
  }
  return json.encode({
    'type': 'SocketProfilingState',
    'enabled': _SocketProfile.enableSocketProfiling,
  });
}

abstract class _SocketProfile {
  static const _kType = 'SocketProfile';
  static set enableSocketProfiling(bool enabled) {
    if (enabled != _enableSocketProfiling) {
      postEvent('SocketProfilingStateChange', {
        'isolateId': Service.getIsolateID(Isolate.current),
        'enabled': enabled,
      });
      _enableSocketProfiling = enabled;
    }
  }

  static bool get enableSocketProfiling => _enableSocketProfiling;

  static bool _enableSocketProfiling = false;
  static Map<String, _SocketStatistic> _idToSocketStatistic = {};

  static String toJson() => json.encode({
        'type': _kType,
        'sockets': _idToSocketStatistic.values.map((f) => f.toMap()).toList(),
      });

  static void collectNewSocket(
      int id, String type, InternetAddress addr, int port) {
    _SocketProfile.collectStatistic(id, _SocketProfileType.startTime);
    _SocketProfile.collectStatistic(id, _SocketProfileType.socketType, type);
    _SocketProfile.collectStatistic(id, _SocketProfileType.address, addr);
    _SocketProfile.collectStatistic(id, _SocketProfileType.port, port);
  }

  static void collectStatistic(int id, _SocketProfileType type,
      [dynamic object]) {
    final idKey = id.toString();
    if (!_enableSocketProfiling) {
      return;
    }
    // Skip socket that started before _enableSocketProfiling turned on.
    if (!_idToSocketStatistic.containsKey(idKey) &&
        type != _SocketProfileType.startTime) return;
    _SocketStatistic stats =
        _idToSocketStatistic[idKey] ??= _SocketStatistic(idKey);
    switch (type) {
      case _SocketProfileType.startTime:
        stats.startTime = Timeline.now;
        break;
      case _SocketProfileType.endTime:
        stats.endTime = Timeline.now;
        break;
      case _SocketProfileType.address:
        assert(object is InternetAddress);
        final internetAddress = object as InternetAddress;
        stats.address = (internetAddress.type == InternetAddress.anyIPv6 ||
                internetAddress.type == InternetAddress.loopbackIPv6)
            ? '[${internetAddress.address}]'
            : internetAddress.address;
        break;
      case _SocketProfileType.port:
        assert(object is int);
        stats.port = object;
        break;
      case _SocketProfileType.socketType:
        assert(object is String);
        stats.socketType = object;
        break;
      case _SocketProfileType.readBytes:
        if (object == null) return;
        stats.readBytes += object as int;
        stats.lastReadTime = Timeline.now;
        break;
      case _SocketProfileType.writeBytes:
        if (object == null) return;
        stats.writeBytes += object as int;
        stats.lastWriteTime = Timeline.now;
        break;
      default:
        throw ArgumentError('type ${type} does not exist');
    }
  }

  static String start() {
    enableSocketProfiling = true;
    return _success();
  }

  static String pause() {
    enableSocketProfiling = false;
    return _success();
  }

  // clear the storage if _idToSocketStatistic has been initialized.
  static String clear() {
    _idToSocketStatistic.clear();
    return _success();
  }
}

/// The [_SocketProfileType] is used as a parameter for
/// [_SocketProfile.collectStatistic] to determine the type of statistic.
enum _SocketProfileType {
  startTime,
  endTime,
  address,
  port,
  socketType,
  readBytes,
  writeBytes
}

/// Socket statistic
class _SocketStatistic {
  final String id;
  int? startTime;
  int? endTime;
  String? address;
  int? port;
  String? socketType;
  int readBytes = 0;
  int writeBytes = 0;
  int? lastWriteTime;
  int? lastReadTime;

  _SocketStatistic(this.id);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
    };
    _setIfNotNull(map, 'startTime', startTime);
    _setIfNotNull(map, 'endTime', endTime);
    _setIfNotNull(map, 'address', address);
    _setIfNotNull(map, 'port', port);
    _setIfNotNull(map, 'socketType', socketType);
    _setIfNotNull(map, 'readBytes', readBytes);
    _setIfNotNull(map, 'writeBytes', writeBytes);
    _setIfNotNull(map, 'lastWriteTime', lastWriteTime);
    _setIfNotNull(map, 'lastReadTime', lastReadTime);
    return map;
  }

  void _setIfNotNull(Map<String, dynamic> json, String key, Object? value) {
    if (value == null) return;
    json[key] = value;
  }
}

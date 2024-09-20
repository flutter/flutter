// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.developer;

/// Service protocol is the protocol that a client like the Observatory
/// could use to access the services provided by the Dart VM for
/// debugging and inspecting Dart programs. This class encapsulates the
/// version number and Uri for accessing this service.
final class ServiceProtocolInfo {
  /// The major version of the protocol. If the running Dart environment does
  /// not support the service protocol, this is 0.
  final int majorVersion = _getServiceMajorVersion();

  /// The minor version of the protocol. If the running Dart environment does
  /// not support the service protocol, this is 0.
  final int minorVersion = _getServiceMinorVersion();

  /// The Uri to connect to the debugger client hosted by the service. If the
  /// web server is not running, this will be null.
  final Uri? serverUri;

  /// The Uri to connect to the service via web socket. If the web server is
  /// not running, this will be null.
  @Since('2.14')
  Uri? get serverWebSocketUri {
    Uri? uri = serverUri;
    if (uri != null) {
      final pathSegments = <String>[];
      if (uri.pathSegments.isNotEmpty) {
        pathSegments.addAll(uri.pathSegments.where(
          // Strip out the empty string that appears at the end of path segments.
          // Empty string elements will result in an extra '/' being added to the
          // URI.
          (s) => s.isNotEmpty,
        ));
      }
      pathSegments.add('ws');
      uri = uri.replace(scheme: 'ws', pathSegments: pathSegments);
    }
    return uri;
  }

  ServiceProtocolInfo(this.serverUri);

  String toString() {
    if (serverUri != null) {
      return 'Dart VM Service Protocol v$majorVersion.$minorVersion '
          'listening on $serverUri';
    } else {
      return 'Dart VM Service Protocol v$majorVersion.$minorVersion';
    }
  }
}

/// Access information about the service protocol and control the web server
/// that provides access to the services provided by the Dart VM for
/// debugging and inspecting Dart programs.
final class Service {
  /// Get information about the service protocol (version number and
  /// Uri to access the service).
  static Future<ServiceProtocolInfo> getInfo() async {
    // Port to receive response from service isolate.
    final RawReceivePort receivePort =
        new RawReceivePort(null, 'Service.getInfo');
    final Completer<String?> completer = new Completer<String?>();
    receivePort.handler = (String? uriString) => completer.complete(uriString);
    // Request the information from the service isolate.
    _getServerInfo(receivePort.sendPort);
    // Await the response from the service isolate.
    String? uriString = await completer.future;
    Uri? uri = uriString == null ? null : Uri.parse(uriString);
    // Close the port.
    receivePort.close();
    return new ServiceProtocolInfo(uri);
  }

  /// Control the web server that the service protocol is accessed through.
  /// [enable] is used as a toggle to enable or disable the web server
  /// servicing requests. If [silenceOutput] is provided and is true,
  /// the server will not output information to the console.
  static Future<ServiceProtocolInfo> controlWebServer(
      {bool enable = false, bool? silenceOutput}) async {
    // TODO: When NNBD is complete, delete the following line.
    ArgumentError.checkNotNull(enable, 'enable');
    // Port to receive response from service isolate.
    final RawReceivePort receivePort =
        new RawReceivePort(null, 'Service.controlWebServer');
    final Completer<String?> completer = new Completer<String?>();
    receivePort.handler = (String? uriString) => completer.complete(uriString);
    // Request the information from the service isolate.
    _webServerControl(receivePort.sendPort, enable, silenceOutput);
    // Await the response from the service isolate.
    String? uriString = await completer.future;
    Uri? uri = uriString == null ? null : Uri.parse(uriString);
    // Close the port.
    receivePort.close();
    return new ServiceProtocolInfo(uri);
  }

  /// Returns a [String] token representing the ID of [isolate].
  ///
  /// Returns null if the running Dart environment does not support the service
  /// protocol.
  ///
  /// To get the isolate id of the current isolate, pass [Isolate.current] as
  /// the [isolate] parameter.
  @Since('3.2')
  static String? getIsolateId(Isolate isolate) {
    // TODO: When NNBD is complete, delete the following line.
    ArgumentError.checkNotNull(isolate, 'isolate');
    return _getIsolateIdFromSendPort(isolate.controlPort);
  }

  /// Returns a [String] token representing the ID of [isolate].
  ///
  /// Returns null if the running Dart environment does not support the service
  /// protocol.
  @Deprecated("Use getIsolateId instead")
  static String? getIsolateID(Isolate isolate) {
    // TODO: When NNBD is complete, delete the following line.
    ArgumentError.checkNotNull(isolate, 'isolate');
    return _getIsolateIdFromSendPort(isolate.controlPort);
  }

  /// Returns a [String] token representing the ID of [object].
  ///
  /// Returns null if the running Dart environment does not support the service
  /// protocol.
  @Since('3.2')
  static String? getObjectId(Object object) {
    return _getObjectId(object);
  }
}

/// [sendPort] will receive a Uri or null.
external void _getServerInfo(SendPort sendPort);

/// [sendPort] will receive a Uri or null.
external void _webServerControl(
    SendPort sendPort, bool enable, bool? silenceOutput);

/// Returns the major version of the service protocol.
external int _getServiceMajorVersion();

/// Returns the minor version of the service protocol.
external int _getServiceMinorVersion();

/// Returns the service id for the isolate that owns [sendPort].
external String? _getIsolateIdFromSendPort(SendPort sendPort);

/// Returns the service id of [object].
external String? _getObjectId(Object object);

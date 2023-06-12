// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build_daemon/data/build_target.dart';
import 'package:built_value/serializer.dart';
import 'package:web_socket_channel/io.dart';

import 'constants.dart';
import 'data/build_request.dart';
import 'data/build_status.dart';
import 'data/build_target_request.dart';
import 'data/serializers.dart';
import 'data/server_log.dart';
import 'data/shutdown_notification.dart';
import 'src/file_wait.dart';

Future<int> _existingPort(String workingDirectory) async {
  var portFile = File(portFilePath(workingDirectory));
  if (!await waitForFile(portFile)) throw MissingPortFile();
  return int.parse(portFile.readAsStringSync());
}

Future<void> _handleDaemonStartup(
  Process process,
  void Function(ServerLog) logHandler,
) async {
  process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
    logHandler(ServerLog((b) => b
      ..level = Level.SEVERE
      ..message = line));
  });
  var stdout = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .asBroadcastStream();

  // The daemon may log critical information prior to it successfully
  // starting. Capture this data and forward to the logHandler.
  //
  // Whenever we see a `logStartMarker` we will parse everything between that
  // and the `logEndMarker` as a `ServerLog`. Everything else is considered a
  // normal INFO level log.
  StringBuffer nextLogRecord;
  var sub = stdout.where((line) => !_isActionMessage(line)).listen((line) {
    if (nextLogRecord != null) {
      if (line == logEndMarker) {
        try {
          logHandler(serializers
              .deserialize(jsonDecode(nextLogRecord.toString())) as ServerLog);
        } catch (e, s) {
          logHandler(ServerLog((builder) => builder
            ..message = 'Failed to read log message:\n$nextLogRecord'
            ..level = Level.SEVERE
            ..error = '$e'
            ..stackTrace = '$s'));
        }
        nextLogRecord = null;
      } else {
        nextLogRecord.writeln(line);
      }
    } else if (line == logStartMarker) {
      nextLogRecord = StringBuffer();
    } else {
      logHandler(ServerLog((b) => b
        ..level = Level.INFO
        ..message = line));
    }
  });

  var daemonAction =
      await stdout.firstWhere(_isActionMessage, orElse: () => null);

  if (daemonAction == null) {
    throw StateError('Unable to start build daemon.');
  } else if (daemonAction == versionSkew) {
    throw VersionSkew();
  } else if (daemonAction == optionsSkew) {
    throw OptionsSkew();
  }
  await sub.cancel();
}

bool _isActionMessage(String line) =>
    line == versionSkew || line == readyToConnectLog || line == optionsSkew;

/// A client of the build daemon.
///
/// Handles starting and connecting to the build daemon.
///
/// Example:
///   https://pub.dev/packages/build_daemon#-example-tab-
class BuildDaemonClient {
  final _buildResults = StreamController<BuildResults>.broadcast();
  final _shutdownNotifications =
      StreamController<ShutdownNotification>.broadcast();
  final Serializers _serializers;

  IOWebSocketChannel _channel;

  BuildDaemonClient._(
    int port,
    this._serializers,
    void Function(ServerLog) logHandler,
  ) {
    _channel = IOWebSocketChannel.connect('ws://localhost:$port')
      ..stream.listen((data) {
        var message = _serializers.deserialize(jsonDecode(data as String));
        if (message is ServerLog) {
          logHandler(message);
        } else if (message is BuildResults) {
          _buildResults.add(message);
        } else if (message is ShutdownNotification) {
          _shutdownNotifications.add(message);
        } else {
          // In practice we should never reach this state due to the
          // deserialize call.
          throw StateError(
              'Unexpected message from the Dart Build Daemon\n $message');
        }
      })
          // TODO(grouma) - Implement proper error handling.
          .onError(print);
  }

  Stream<BuildResults> get buildResults => _buildResults.stream;
  Stream<ShutdownNotification> get shutdownNotifications =>
      _shutdownNotifications.stream;
  Future<void> get finished async => await _channel.sink.done;

  /// Registers a build target to be built upon any file change.
  void registerBuildTarget(BuildTarget target) => _channel.sink.add(jsonEncode(
      _serializers.serialize(BuildTargetRequest((b) => b..target = target))));

  /// Builds all registered targets, including those not from this client.
  ///
  /// Note this will wait for any ongoing build to finish before starting a new
  /// one.
  void startBuild() {
    var request = BuildRequest();
    _channel.sink.add(jsonEncode(_serializers.serialize(request)));
  }

  Future<void> close() => _channel.sink.close();

  /// Connects to the current daemon instance.
  ///
  /// If one is not running, a new daemon instance will be started.
  static Future<BuildDaemonClient> connect(
    String workingDirectory,
    List<String> daemonCommand, {
    Serializers serializersOverride,
    void Function(ServerLog) logHandler,
    bool includeParentEnvironment,
    Map<String, String> environment,
    BuildMode buildMode,
  }) async {
    logHandler ??= (_) {};
    includeParentEnvironment ??= true;
    buildMode ??= BuildMode.Auto;

    var daemonSerializers = serializersOverride ?? serializers;

    var daemonArgs = daemonCommand.sublist(1)
      ..add('--$buildModeFlag=$buildMode');

    var process = await Process.start(
      daemonCommand.first,
      daemonArgs,
      mode: ProcessStartMode.detachedWithStdio,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
    );

    await _handleDaemonStartup(process, logHandler);

    return BuildDaemonClient._(
        await _existingPort(workingDirectory), daemonSerializers, logHandler);
  }
}

/// Thrown when the port file for the running daemon instance can't be found.
class MissingPortFile implements Exception {}

/// Thrown if the client requests conflicting options with the current daemon
/// instance.
class OptionsSkew implements Exception {}

/// Thrown if the current daemon instance version does not match that of the
/// client.
class VersionSkew implements Exception {}

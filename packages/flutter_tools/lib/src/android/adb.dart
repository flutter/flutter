// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../base/logging.dart';
import '../base/process.dart';

// https://android.googlesource.com/platform/system/core/+/android-4.4_r1/adb/OVERVIEW.TXT
// https://android.googlesource.com/platform/system/core/+/android-4.4_r1/adb/SERVICES.TXT

/// A wrapper around the `adb` command-line tool and the adb server.
class Adb {
  Adb(this.adbPath);

  static const int adbServerPort = 5037;

  final String adbPath;

  bool exists() {
    try {
      runCheckedSync([adbPath, 'version']);
      return true;
    } catch (exception) {
      return false;
    }
  }

  /// Return the full text from `adb version`. E.g.,
  ///
  ///     Android Debug Bridge version 1.0.32
  ///     Revision eac51f2bb6a8-android
  ///
  /// This method throws if `adb version` fails.
  String getVersion() => runCheckedSync([adbPath, 'version']);

  /// Starts the adb server. This will throw if there's an problem starting the
  /// adb server.
  void startServer() {
    runCheckedSync([adbPath, 'start-server']);
  }

  /// Stops the adb server. This will throw if there's an problem stopping the
  /// adb server.
  void killServer() {
    runCheckedSync([adbPath, 'kill-server']);
  }

  /// Ask the ADB server for its internal version number.
  Future<String> getServerVersion() {
    return _sendAdbServerCommand('host:version').then((String response) {
      _AdbServerResponse adbResponse = new _AdbServerResponse(response);
      if (adbResponse.isOkay)
        return adbResponse.message;
      throw adbResponse.message;
    });
  }

  /// Queries the adb server for the list of connected adb devices.
  Future<List<AdbDevice>> listDevices() async {
    String stringResponse = await _sendAdbServerCommand('host:devices-l');
    _AdbServerResponse response = new _AdbServerResponse(stringResponse);
    if (response.isFail)
      throw response.message;
    String message = response.message.trim();
    if (message.isEmpty)
      return <AdbDevice>[];
    return message.split('\n').map(
      (String deviceInfo) => new AdbDevice(deviceInfo)
    ).toList();
  }

  /// Listen to device activations and deactivations via the asb server's
  /// 'track-devices' command. Call cancel on the returned stream to stop
  /// listening.
  Stream<List<AdbDevice>> trackDevices() {
    StreamController<List<AdbDevice>> controller;
    Socket socket;
    bool isFirstNotification = true;

    controller = new StreamController(
      onListen: () async {
        socket = await Socket.connect(InternetAddress.LOOPBACK_IP_V4, adbServerPort);
        logging.fine('--> host:track-devices');
        socket.add(_createAdbRequest('host:track-devices'));
        socket.listen((List<int> data) {
          String stringResult = new String.fromCharCodes(data);
          logging.fine('<-- ${stringResult.trim()}');
          _AdbServerResponse response = new _AdbServerResponse(
            stringResult,
            noStatus: !isFirstNotification
          );

          String devicesText = response.message.trim();
          isFirstNotification = false;

          if (devicesText.isEmpty) {
            controller.add(<AdbDevice>[]);
          } else {
            controller.add(devicesText.split('\n').map((String deviceInfo) {
              return new AdbDevice(deviceInfo);
            }).toList());
          }
        });
        socket.done.then((_) => controller.close());
      },
      onCancel: () => socket?.destroy()
    );

    return controller.stream;
  }

  Future<String> _sendAdbServerCommand(String command) async {
    Socket socket = await Socket.connect(InternetAddress.LOOPBACK_IP_V4, adbServerPort);

    try {
      logging.fine('--> $command');
      socket.add(_createAdbRequest(command));
      List<List<int>> result = await socket.toList();
      List<int> data = result.fold(<int>[], (List<int> previous, List<int> element) {
        return previous..addAll(element);
      });
      String stringResult = new String.fromCharCodes(data);
      logging.fine('<-- ${stringResult.trim()}');
      return stringResult;
    } finally {
      socket.destroy();
    }
  }
}

class AdbDevice {
  AdbDevice(String deviceInfo) {
    // 'TA95000FQA	device'
    // 'TA95000FQA             device usb:340787200X product:peregrine_retus model:XT1045 device:peregrine'
    // '015d172c98400a03       device usb:340787200X product:nakasi model:Nexus_7 device:grouper'

    Match match = deviceRegex.firstMatch(deviceInfo);
    id = match[1];
    status = match[2];

    String rest = match[3];
    if (rest != null && rest.isNotEmpty) {
      rest = rest.trim();
      for (String data in rest.split(' ')) {
        if (data.contains(':')) {
          List<String> fields = data.split(':');
          _info[fields[0]] = fields[1];
        }
      }
    }
  }

  static final RegExp deviceRegex = new RegExp(r'^(\S+)\s+(\S+)(.*)');

  /// Always non-null; something like `TA95000FQA`.
  String id;

  /// device, offline, unauthorized.
  String status;

  final Map<String, String> _info = <String, String>{};

  bool get isAvailable => status == 'device';

  /// Device model; can be null. `XT1045`, `Nexus_7`
  String get modelID => _info['model'];

  /// Device code name; can be null. `peregrine`, `grouper`
  String get deviceCodeName => _info['device'];

  /// Device product; can be null. `peregrine_retus`, `nakasi`
  String get productID => _info['product'];

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! AdbDevice)
      return false;
    final AdbDevice typedOther = other;
    return id == typedOther.id;
  }

  int get hashCode => id.hashCode;

  String toString() {
    if (modelID == null) {
      return '$id ($status)';
    } else {
      return '$id ($status) - $modelID';
    }
  }
}

List<int> _createAdbRequest(String payload) {
  List<int> data = payload.codeUnits;

  // A 4-byte hexadecimal string giving the length of the payload.
  String prefix = data.length.toRadixString(16).padLeft(4, '0');
  List<int> result = <int>[];
  result.addAll(prefix.codeUnits);
  result.addAll(data);
  return result;
}

class _AdbServerResponse {
  _AdbServerResponse(String text, { bool noStatus: false }) {
    if (noStatus) {
      message = text;
    } else {
      status = text.substring(0, 4);
      message = text.substring(4);
    }

    // Instead of pulling the hex length out of the response (`000C`), we depend
    // on the incoming text being the full packet.
    if (message.isNotEmpty) {
      // Skip over the 4 byte hex length (`000C`).
      message = message.substring(4);
    }
  }

  String status;
  String message;

  bool get isOkay => status == 'OKAY';

  bool get isFail => status == 'FAIL';
}

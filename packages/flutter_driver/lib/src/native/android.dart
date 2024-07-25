// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Examples can assume:
// import 'package:flutter_driver/src/native/android.dart';

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'driver.dart';

/// Drives an Android device or emulator that is running a Flutter application.
final class AndroidNativeDriver implements NativeDriver {
  /// Creates a new Android native driver with the provided configuration.
  ///
  /// The [tempDirectory] argument can be used to specify a custom directory
  /// where the driver will store temporary files. If not provided, a temporary
  /// directory will be created in the system's temporary directory.
  @visibleForTesting
  AndroidNativeDriver({
    required AndroidDeviceTarget target,
    String? adbPath,
    io.Directory? tempDirectory,
  }) : _adbPath = adbPath ?? 'adb',
       _target = target,
       _tmpDir = tempDirectory ?? io.Directory.systemTemp.createTempSync('flutter_driver.');

  /// Connects to a device or emulator identified by [target].
  static Future<AndroidNativeDriver> connect({
    AndroidDeviceTarget target = const AndroidDeviceTarget.onlyEmulatorOrDevice(),
  }) async {
    final AndroidNativeDriver driver = AndroidNativeDriver(target: target);
    await driver._smokeTest();
    return driver;
  }

  Future<void> _smokeTest() async {
    final io.ProcessResult version = await io.Process.run(
      _adbPath,
      const <String>['version'],
    );
    if (version.exitCode != 0) {
      throw StateError('Failed to run `$_adbPath version`: ${version.stderr}');
    }

    final io.ProcessResult devices = await io.Process.run(
      _adbPath,
      <String>[
        ..._target._toAdbArgs(),
        'shell',
        'echo',
        'connected',
      ],
    );
    if (devices.exitCode != 0) {
      throw StateError('Failed to connect to target: ${devices.stderr}');
    }
  }

  final String _adbPath;
  final AndroidDeviceTarget _target;
  final io.Directory _tmpDir;

  @override
  Future<void> close() async {
    await _tmpDir.delete(recursive: true);
  }

  @override
  Future<NativeScreenshot> screenshot() async {
    final io.ProcessResult result = await io.Process.run(
      _adbPath,
      <String>[
        ..._target._toAdbArgs(),
        'exec-out',
        'screencap',
        '-p',
      ],
      stdoutEncoding: null,
    );

    if (result.exitCode != 0) {
      throw StateError('Failed to take screenshot: ${result.stderr}');
    }

    final Uint8List bytes = result.stdout as Uint8List;
    return _AdbScreencap(bytes, _tmpDir);
  }
}

final class _AdbScreencap implements NativeScreenshot {
  const _AdbScreencap(this._bytes, this._tmpDir);

  /// Raw bytes of the screenshot in PNG format.
  final Uint8List _bytes;

  /// Temporary directory to default to when saving the screenshot.
  final io.Directory _tmpDir;

  static int _lastScreenshotId = 0;

  @override
  Future<String> saveAs([String? path]) async {
    final int id = _lastScreenshotId++;
    path ??= p.join(_tmpDir.path, '$id.png');
    await io.File(path).writeAsBytes(_bytes);
    return path;
  }

  @override
  Future<Uint8List> readAsBytes() async => _bytes;
}

/// Represents a target device running Android.
sealed class AndroidDeviceTarget {
  /// Represents a device with the given [serialNumber].
  ///
  /// This is the recommended way to target a specific device, and uses the
  /// device's serial number, as reported by `adb devices`, to identify the
  /// device:
  ///
  /// ```sh
  /// $ adb devices
  /// List of devices attached
  /// emulator-5554   device
  /// ```
  ///
  /// In this example, the serial number is `emulator-5554`:
  ///
  /// ```dart
  /// const AndroidDeviceTarget target = AndroidDeviceTarget.bySerial('emulator-5554');
  /// ```
  const factory AndroidDeviceTarget.bySerial(String serialNumber) = _SerialDeviceTarget;

  /// Represents the only running emulator _or_ connected device.
  ///
  /// This is equivalent to using `adb` without `-e`, `-d`, or `-s`.
  const factory AndroidDeviceTarget.onlyEmulatorOrDevice() = _SingleAnyTarget;

  /// Represents the only running emulator on the host machine.
  ///
  /// This is equivalent to using `adb -e`, a _single_ emulator must be running.
  const factory AndroidDeviceTarget.onlyRunningEmulator() = _SingleEmulatorTarget;

  /// Represents the only connected device on the host machine.
  ///
  /// This is equivalent to using `adb -d`, a _single_ device must be connected.
  const factory AndroidDeviceTarget.onlyConnectedDevice() = _SingleDeviceTarget;

  /// Returns the arguments to pass to `adb` to target this device.
  List<String> _toAdbArgs();
}

final class _SerialDeviceTarget implements AndroidDeviceTarget {
  const _SerialDeviceTarget(this.serialNumber);
  final String serialNumber;

  @override
  List<String> _toAdbArgs() => <String>['-s', serialNumber];
}

final class _SingleEmulatorTarget implements AndroidDeviceTarget {
  const _SingleEmulatorTarget();

  @override
  List<String> _toAdbArgs() => const <String>['-e'];
}

final class _SingleDeviceTarget implements AndroidDeviceTarget {
  const _SingleDeviceTarget();

  @override
  List<String> _toAdbArgs() => const <String>['-d'];
}

final class _SingleAnyTarget implements AndroidDeviceTarget {
  const _SingleAnyTarget();

  @override
  List<String> _toAdbArgs() => const <String>[];
}

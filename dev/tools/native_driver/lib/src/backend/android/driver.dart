// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../../../native_driver.dart';
import 'adb.dart';

/// Drives an Android device or emulator that is running a Flutter application.
final class AndroidNativeDriver implements NativeDriver {
  /// Assumes a connected device or emulator via [adb].
  ///
  /// This constructor is intended for testing purposes only.
  @visibleForTesting
  AndroidNativeDriver.forTesting({
    required Adb adb,
    required io.Directory tempDirectory,
  }) : this._(adb, tempDirectory);

  AndroidNativeDriver._(this._adb, this._tmpDir);
  final Adb _adb;
  final io.Directory _tmpDir;

  /// Connects to a device or emulator identified by [target], which defaults to
  /// the only running emulator or connected device.
  ///
  /// If [adbPath] is not provided, the `adb` command is assumed to be in the
  /// system's PATH.
  ///
  /// If [tempDirectory] is not provided, a temporary directory will be created
  /// in the system's temporary directory.
  static Future<AndroidNativeDriver> connect({
    AndroidDeviceTarget? target,
    String? adbPath,
    io.Directory? tempDirectory,
  }) async {
    final Adb adb = await Adb.create(
      adbPath: adbPath,
      target: target,
    );
    tempDirectory ??= io.Directory.systemTemp.createTempSync('native_driver.');
    return AndroidNativeDriver.forTesting(
      adb: adb,
      tempDirectory: tempDirectory,
    );
  }

  @override
  Future<void> close() async {
    await _tmpDir.delete(recursive: true);
  }

  @override
  Future<NativeScreenshot> screenshot() async {
    return _AdbScreencap(await _adb.screencap(), _tmpDir);
  }

  /// Background the app by pressing the home button.
  Future<void> backgroundApp() async {
    throw UnimplementedError();
  }

  /// Resumes the app by selecting it from the recent apps list.
  Future<void> resumeApp() async {
    throw UnimplementedError();
  }

  /// Send a trim memory signal to the app to force it to release memory.
  Future<void> trimMemory() async {
    throw UnimplementedError();
  }
}

final class _AdbScreencap implements NativeScreenshot {
  const _AdbScreencap(this._bytes, this._tmpDir);

  /// Raw bytes of the screenshot in PNG format.
  final Uint8List _bytes;

  /// Temporary directory to use as a default location for saving.
  final io.Directory _tmpDir;

  static int _lastScreenshotId = 0;

  @override
  Future<String> saveAs([String? path]) async {
    final int id = _lastScreenshotId++;
    path ??= p.join(_tmpDir.path, 'screenshot_$id.png');
    await io.File(path).writeAsBytes(_bytes);
    return path;
  }

  @override
  Future<Uint8List> readAsBytes() async => _bytes;
}

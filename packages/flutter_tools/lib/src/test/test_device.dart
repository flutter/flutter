// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:stream_channel/stream_channel.dart';

/// A remote device where tests can be executed on.
///
/// Reusability of an instance across multiple runs is not guaranteed for all
/// implementations.
///
/// Methods may throw [TestDeviceException] if a problem is encountered.
abstract class TestDevice {
  /// Starts the test device with the provided entrypoint.
  ///
  /// Returns a channel that can be used to communicate with the test process.
  ///
  /// It is up to the device to determine if [entrypointPath] is a precompiled
  /// or raw source file.
  Future<StreamChannel<String>> start(String entrypointPath);

  /// Should complete with null if the observatory is not enabled.
  Future<Uri?> get observatoryUri;

  /// Terminates the test device.
  Future<void> kill();

  /// Waits for the test device to stop.
  Future<void> get finished;
}

/// Thrown when the device encounters a problem.
class TestDeviceException implements Exception {
  TestDeviceException(this.message, this.stackTrace);

  final String message;
  final StackTrace stackTrace;

  @override
  String toString() => 'TestDeviceException($message)';
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

// This code has to be available in both the Flutter app and Dart VM test.
// ignore: implementation_imports
import 'package:flutter_driver/src/common/find.dart';

// This code has to be available in both the Flutter app and Dart VM test.
// ignore: implementation_imports
import 'package:flutter_driver/src/common/message.dart';

/// A command that is forwarded to a registered plugin.
final class NativeCommand extends Command {
  /// Creates a new [NativeCommand] with the given [method].
  const NativeCommand(this.method, {this.arguments, super.timeout});

  /// Requests that the device be rotated to landscape mode.
  static const NativeCommand rotateLandscape = NativeCommand(
    'rotate_landscape',
  );

  /// Requests that the device reset its rotation to the default orientation.
  static const NativeCommand rotateDefault = NativeCommand(
    'rotate_default',
  );

  /// Pings the device to ensure it is responsive.
  static const NativeCommand ping = NativeCommand(
    'ping',
  );

  /// The method to call on the plugin.
  final String method;

  /// What arguments to pass when invoking the [method].
  final Object? arguments;

  @override
  String get kind => 'native_driver';

  @override
  Map<String, String> serialize() {
    final Map<String, String> serialized = super.serialize();
    serialized['method'] = method;
    if (arguments != null) {
      serialized['arguments'] = jsonEncode(arguments);
    }
    return serialized;
  }
}

/// A result from a [NativeCommand].
final class NativeResult extends Result {
  /// Creates a new [NativeResult].
  const NativeResult();

  @override
  Map<String, dynamic> toJson() => const <String, Object?>{};
}

/// An object that descrbes searching for _native_ elements.
sealed class NativeFinder extends SerializableFinder {
  const NativeFinder();

  @override
  String get finderType => 'native_driver';
}

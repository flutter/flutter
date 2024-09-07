// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This code has to be available in both the Flutter app and Dart VM test.
// ignore: implementation_imports
import 'package:flutter_driver/src/common/message.dart';

/// A command that is forwarded to a registered plugin.
final class NativeCommand extends Command {
  /// Creates a new [NativeCommand] with the given [method].
  const NativeCommand(this.method, {this.arguments, super.timeout});

  /// The method to call on the plugin.
  final String method;

  /// What arguments to pass when invoking the [method].
  final Object? arguments;

  @override
  String get kind => 'native_driver';
}

/// A result from a [NativeCommand].
final class NativeResult extends Result {
  /// Creates a new [NativeResult].
  const NativeResult();

  @override
  Map<String, dynamic> toJson() => const <String, Object?>{};
}

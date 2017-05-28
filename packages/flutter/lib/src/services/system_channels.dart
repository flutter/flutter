// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'message_codecs.dart';
import 'platform_channel.dart';

/// Platform channels used by the Flutter system.
class SystemChannels {
  SystemChannels._();

  /// A JSON [MethodChannel] for navigation.
  static const MethodChannel navigation = const MethodChannel(
      'flutter/navigation',
      const JSONMethodCodec(),
  );

  /// A JSON [MethodChannel] for invoking miscellaneous platform methods.
  ///
  /// Ignores missing plugins.
  static const MethodChannel platform = const OptionalMethodChannel(
      'flutter/platform',
      const JSONMethodCodec(),
  );

  /// A JSON [MethodChannel] for handling text input.
  ///
  /// Ignores missing plugins.
  static const MethodChannel textInput = const OptionalMethodChannel(
      'flutter/textinput',
      const JSONMethodCodec(),
  );

  /// A JSON [BasicMessageChannel] for key events.
  static const BasicMessageChannel<dynamic> keyEvent = const BasicMessageChannel<dynamic>(
      'flutter/keyevent',
      const JSONMessageCodec(),
  );

  /// A string [BasicMessageChannel] for lifecycle events.
  ///
  /// Valid messages are string representations of the values of the
  /// [AppLifecycleState] enumeration.
  static const BasicMessageChannel<String> lifecycle = const BasicMessageChannel<String>(
      'flutter/lifecycle',
      const StringCodec(),
  );

  /// A JSON [BasicMessageChannel] for system events.
  static const BasicMessageChannel<dynamic> system = const BasicMessageChannel<dynamic>(
      'flutter/system',
      const JSONMessageCodec(),
  );

}

// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'message_codecs.dart';
import 'platform_channel.dart';

/// Platform channels used by the Flutter system.
class SystemChannels {
  SystemChannels._();

  /// A JSON [PlatformMethodChannel] for navigation.
  static const PlatformMethodChannel navigation = const PlatformMethodChannel(
      'flutter/navigation',
      const JSONMethodCodec(),
  );

  /// A JSON [PlatformMethodChannel] for invoking miscellaneous platform methods.
  ///
  /// Ignores missing plugins.
  static const PlatformMethodChannel platform = const OptionalPlatformMethodChannel(
      'flutter/platform',
      const JSONMethodCodec(),
  );

  /// A JSON [PlatformMethodChannel] for handling text input.
  ///
  /// Ignores missing plugins.
  static const PlatformMethodChannel textInput = const OptionalPlatformMethodChannel(
      'flutter/textinput',
      const JSONMethodCodec(),
  );

  /// A JSON [PlatformMessageChannel] for key events.
  static const PlatformMessageChannel<dynamic> keyEvent = const PlatformMessageChannel<dynamic>(
      'flutter/keyevent',
      const JSONMessageCodec(),
  );

  /// A string [PlatformMessageChannel] for lifecycle events.
  static const PlatformMessageChannel<String> lifecycle = const PlatformMessageChannel<String>(
      'flutter/lifecycle',
      const StringCodec(),
  );

  /// A JSON [PlatformMessageChannel] for system events.
  static const PlatformMessageChannel<dynamic> system = const PlatformMessageChannel<dynamic>(
      'flutter/system',
      const JSONMessageCodec(),
  );

}

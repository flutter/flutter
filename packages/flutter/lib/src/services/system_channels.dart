// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'platform_channel.dart';
import 'message_codecs.dart';

/// A JSON [PlatformMethodChannel] for navigation.
const PlatformMethodChannel flutterNavigationChannel = const PlatformMethodChannel(
  'flutter/navigation',
  const JSONMethodCodec(),
);

/// A standard [PlatformMethodChannel] for invoking miscellaneous platform methods.
const PlatformMethodChannel flutterPlatformChannel = const PlatformMethodChannel('flutter/platform');

/// A standard [PlatformMethodChannel] for handling text input.
const PlatformMethodChannel flutterTextInputChannel = const PlatformMethodChannel('flutter/textinput');

/// A standard [PlatformMessageChannel] for key events.
const PlatformMessageChannel<dynamic> flutterKeyEventChannel = const PlatformMessageChannel<dynamic>(
  'flutter/keyevent',
  const StandardMessageCodec(),
);

/// A string [PlatformMessageChannel] for lifecycle events.
const PlatformMessageChannel<String> flutterLifecycleChannel = const PlatformMessageChannel<String>(
  'flutter/lifecycle',
  const StringCodec(),
);

/// A standard [PlatformMessageChannel] for system events.
const PlatformMessageChannel<dynamic> flutterSystemChannel = const PlatformMessageChannel<dynamic>(
  'flutter/system',
  const StandardMessageCodec(),
);

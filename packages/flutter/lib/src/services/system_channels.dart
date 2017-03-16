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

/// A JSON [PlatformMethodChannel] for invoking miscellaneous platform methods.
const PlatformMethodChannel flutterPlatformChannel = const PlatformMethodChannel(
  'flutter/platform',
  const JSONMethodCodec(),
);

/// A JSON [PlatformMethodChannel] for handling text input.
const PlatformMethodChannel flutterTextInputChannel = const PlatformMethodChannel(
  'flutter/textinput',
  const JSONMethodCodec(),
);

/// A JSON [PlatformMessageChannel] for key events.
const PlatformMessageChannel<dynamic> flutterKeyEventChannel = const PlatformMessageChannel<dynamic>(
  'flutter/keyevent',
  const JSONMessageCodec(),
);

/// A string [PlatformMessageChannel] for lifecycle events.
const PlatformMessageChannel<String> flutterLifecycleChannel = const PlatformMessageChannel<String>(
  'flutter/lifecycle',
  const StringCodec(),
);

/// A JSON [PlatformMessageChannel] for system events.
const PlatformMessageChannel<dynamic> flutterSystemChannel = const PlatformMessageChannel<dynamic>(
  'flutter/system',
  const JSONMessageCodec(),
);

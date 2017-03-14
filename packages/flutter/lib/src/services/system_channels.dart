// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'platform_channel.dart';
import 'message_codecs.dart';

/// A standard [PlatformMethodChannel] for invoking miscellaneous platform
/// methods.
const PlatformMethodChannel flutterPlatformChannel = const PlatformMethodChannel('flutter/platform');

/// A standard [PlatformMethodChannel] for invoking platform methods related to
/// text input.
const PlatformMethodChannel flutterTextInputChannel = const PlatformMethodChannel('flutter/textinput');

/// A standard [PlatformMethodChannel] for receiving platform method calls
/// related to text input.
const PlatformMethodChannel flutterTextInputClientChannel = const PlatformMethodChannel('flutter/textinputclient');

/// A standard [PlatformMethodChannel] for receiving navigation events.
const PlatformMethodChannel flutterNavigationChannel = const PlatformMethodChannel('flutter/navigation');

/// A standard [PlatformMessageChannel] for receiving key events.
const PlatformMessageChannel<dynamic> flutterKeyEventChannel = const PlatformMessageChannel<dynamic>(
    'flutter/keyevent',
    const StandardMessageCodec(),
);

/// A standard [PlatformMessageChannel] for receiving lifecycle events.
const PlatformMessageChannel<dynamic> flutterLifecycleChannel = const PlatformMessageChannel<dynamic>(
    'flutter/lifecycle',
    const StandardMessageCodec(),
);

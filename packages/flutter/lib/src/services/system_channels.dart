// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'platform_channel.dart';
import 'message_codecs.dart';

/// A standard [PlatformMethodChannel] for localization.
const PlatformMethodChannel flutterLocalizationChannel = const PlatformMethodChannel('flutter/localization');

/// A standard [PlatformMethodChannel] for navigation.
const PlatformMethodChannel flutterNavigationChannel = const PlatformMethodChannel('flutter/navigation');

/// A standard [PlatformMethodChannel] for miscellaneous platform methods.
const PlatformMethodChannel flutterPlatformChannel = const PlatformMethodChannel('flutter/platform');

/// A standard [PlatformMethodChannel] for handling text input.
const PlatformMethodChannel flutterTextInputChannel = const PlatformMethodChannel('flutter/textinput');

/// A standard [PlatformMessageChannel] for key events.
const PlatformMessageChannel<dynamic> flutterKeyEventChannel = const PlatformMessageChannel<dynamic>(
    'flutter/keyevent',
    const StandardMessageCodec(),
);

/// A standard [PlatformMessageChannel] for lifecycle events.
const PlatformMessageChannel<dynamic> flutterLifecycleChannel = const PlatformMessageChannel<dynamic>(
    'flutter/lifecycle',
    const StandardMessageCodec(),
);

/// A standard [PlatformMessageChannel] for system events.
const PlatformMessageChannel<dynamic> flutterSystemChannel = const PlatformMessageChannel<dynamic>(
    'flutter/system',
        const StandardMessageCodec(),
);


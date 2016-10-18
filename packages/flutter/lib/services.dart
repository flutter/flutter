// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// System services exposed to Flutter apps.
///
/// To use, import `package:flutter/services.dart`.
///
/// For example, this library includes [fetch], which fetches data from the
/// network.
///
/// This library depends only on core Dart libraries, the `mojo`,
/// `mojo_services`, and `sky_services` packages, and the `foundation`
/// Flutter library.
library services;

export 'src/services/asset_bundle.dart';
export 'src/services/binding.dart';
export 'src/services/clipboard.dart';
export 'src/services/haptic_feedback.dart';
export 'src/services/host_messages.dart';
export 'src/services/image_cache.dart';
export 'src/services/image_decoder.dart';
export 'src/services/image_provider.dart';
export 'src/services/image_resolution.dart';
export 'src/services/image_stream.dart';
export 'src/services/keyboard.dart';
export 'src/services/path_provider.dart';
export 'src/services/platform_messages.dart';
export 'src/services/raw_keyboard.dart';
export 'src/services/shell.dart';
export 'src/services/system_chrome.dart';
export 'src/services/system_navigator.dart';
export 'src/services/system_sound.dart';
export 'src/services/url_launcher.dart';

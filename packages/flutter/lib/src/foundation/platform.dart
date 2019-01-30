// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'assertions.dart';

/// The platform that user interaction should adapt to target.
///
/// The [defaultTargetPlatform] getter returns the current platform.
enum TargetPlatform {
  /// Android: <https://www.android.com/>
  android,

  /// Fuchsia: <https://fuchsia.googlesource.com/>
  fuchsia,

  /// iOS: <http://www.apple.com/ios/>
  iOS,
}

/// The [TargetPlatform] that matches the platform on which the framework is
/// currently executing.
///
/// This is the default value of [ThemeData.platform] (hence the name). Widgets
/// from the material library should use [Theme.of] to determine the current
/// platform for styling purposes, rather than using [defaultTargetPlatform].
/// However, if there is widget behavior that depends on the actual underlying
/// platform, then depending on [defaultTargetPlatform] makes sense.
/// [dart.io.Platform.environment] should be used directly only when it's
/// critical to actually know the current platform, without any overrides
/// possible (for example, when a system API is about to be called).
///
/// In a test environment, the platform returned is [TargetPlatform.android]
/// regardless of the host platform. (Android was chosen because the tests were
/// originally written assuming Android-like behavior, and we added platform
/// adaptations for iOS later). Tests can check iOS behavior by using the
/// platform override APIs (such as [ThemeData.platform] in the material
/// library) or by setting [debugDefaultTargetPlatformOverride].
//
// When adding support for a new platform (e.g. Windows Phone, macOS), first
// create a new value on the [TargetPlatform] enum, then add a rule for
// selecting that platform here.
//
// It would be incorrect to make a platform that isn't supported by
// [TargetPlatform] default to the behavior of another platform, because doing
// that would mean we'd be stuck with that platform forever emulating the other,
// and we'd never be able to introduce dedicated behavior for that platform
// (since doing so would be a big breaking change).
TargetPlatform get defaultTargetPlatform {
  TargetPlatform result;
  if (Platform.isIOS) {
    result = TargetPlatform.iOS;
  } else if (Platform.isAndroid) {
    result = TargetPlatform.android;
  } else if (Platform.isFuchsia) {
    result = TargetPlatform.fuchsia;
  }
  assert(() {
    if (Platform.environment.containsKey('FLUTTER_TEST'))
      result = TargetPlatform.android;
    return true;
  }());
  if (debugDefaultTargetPlatformOverride != null)
    result = debugDefaultTargetPlatformOverride;
  if (result == null) {
    throw FlutterError(
      'Unknown platform.\n'
      '${Platform.operatingSystem} was not recognized as a target platform. '
      'Consider updating the list of TargetPlatforms to include this platform.'
    );
  }
  return result;
}

/// Override the [defaultTargetPlatform].
///
/// Setting this to null returns the [defaultTargetPlatform] to its original
/// value (based on the actual current platform).
///
/// Generally speaking this override is only useful for tests. To change the
/// platform that widgets resemble, consider using the platform override APIs
/// (such as [ThemeData.platform] in the material library) instead.
///
/// Setting [debugDefaultTargetPlatformOverride] (as opposed to, say,
/// [ThemeData.platform]) will cause unexpected and undesireable effects. For
/// example, setting this to [TargetPlatform.iOS] when the application is
/// running on Android will cause the TalkBack accessibility tool on Android to
/// be confused because it would be receiving data intended for iOS VoiceOver.
/// Similarly, setting it to [TargetPlatform.android] while on iOS will cause
/// certainly widgets to work assuming the presence of a system-wide back
/// button, which will make those widgets unusable since iOS has no such button.
///
/// In general, therefore, this property should not be used in release builds.
TargetPlatform debugDefaultTargetPlatformOverride;

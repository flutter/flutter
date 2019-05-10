// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
/// [ThemeData.platform]) will cause unexpected and undesirable effects. For
/// example, setting this to [TargetPlatform.iOS] when the application is
/// running on Android will cause the TalkBack accessibility tool on Android to
/// be confused because it would be receiving data intended for iOS VoiceOver.
/// Similarly, setting it to [TargetPlatform.android] while on iOS will cause
/// certainly widgets to work assuming the presence of a system-wide back
/// button, which will make those widgets unusable since iOS has no such button.
///
/// In general, therefore, this property should not be used in release builds.
TargetPlatform debugDefaultTargetPlatformOverride;

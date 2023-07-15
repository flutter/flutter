// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The location of the Dart Plugin Registrant. This is used by the engine to
/// execute the Dart Plugin Registrant when the Isolate is started or
/// DartPluginRegistrant.ensureInitialized() is called from a background
/// Isolate.
@pragma('vm:entry-point')
const String dartPluginRegistrantLibrary = String.fromEnvironment('flutter.dart_plugin_registrant');

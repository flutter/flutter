// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The platform channels and plugin registry implementations for
/// the web implementations of Flutter plugins.
///
/// This library provides the [Registrar] class, which is used in the
/// `registerWith` method that is itself called by the code generated
/// by the `flutter` tool for web applications.
///
/// See also:
///
///  * [How to Write a Flutter Web Plugin](https://medium.com/flutter/how-to-write-a-flutter-web-plugin-5e26c689ea1), a Medium article
///    describing how the `url_launcher` package was created using `flutter_web_plugins`.
///
/// @docImport 'src/plugin_registry.dart';
library flutter_web_plugins;

export 'src/navigation/url_strategy.dart';
export 'src/navigation/utils.dart';
export 'src/plugin_event_channel.dart';
export 'src/plugin_registry.dart';

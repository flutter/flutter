// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dtd/dtd.dart';

/// Provides services, streams, and RPC invocations to interact with Flutter developer tooling.
class WidgetPreviewScaffoldDtdServices {
  /// Environment variable for the DTD URI.
  static const String kWidgetPreviewDtdUriEnvVar = 'WIDGET_PREVIEW_DTD_URI';

  /// Connects to the Dart Tooling Daemon (DTD) specified by the Flutter tool.
  ///
  /// If the connection is successful, the Widget Preview Scaffold will register services and
  /// subscribe to various streams to interact directly with other tooling (e.g., IDEs).
  Future<void> connect() async {
    final Uri dtdWsUri = Uri.parse(
      const String.fromEnvironment(kWidgetPreviewDtdUriEnvVar),
    );
    _dtd = await DartToolingDaemon.connect(dtdWsUri);
    unawaited(
      _dtd.postEvent(
        'WidgetPreviewScaffold',
        'Connected',
        const <String, Object?>{},
      ),
    );
  }

  late final DartToolingDaemon _dtd;
}

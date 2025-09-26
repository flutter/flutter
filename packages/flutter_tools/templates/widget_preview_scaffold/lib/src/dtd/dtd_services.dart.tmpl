// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dtd/dtd.dart';
import 'package:widget_preview_scaffold/src/dtd/utils.dart';
import 'editor_service.dart';

/// Provides services, streams, and RPC invocations to interact with Flutter developer tooling.
class WidgetPreviewScaffoldDtdServices with DtdEditorService {
  /// Environment variable for the DTD URI.
  static const String kWidgetPreviewDtdUriEnvVar = 'WIDGET_PREVIEW_DTD_URI';

  // WARNING: Keep these constants and services in sync with those defined in the widget preview
  // scaffold's dtd_services.dart.
  //
  // START KEEP SYNCED

  static const String kWidgetPreviewService = 'widget-preview';
  static const String kHotRestartPreviewer = 'hotRestartPreviewer';
  static const String kResolveUri = 'resolveUri';

  // END KEEP SYNCED

  /// Connects to the Dart Tooling Daemon (DTD) specified by the Flutter tool.
  ///
  /// If the connection is successful, the Widget Preview Scaffold will register services and
  /// subscribe to various streams to interact directly with other tooling (e.g., IDEs).
  Future<void> connect({Uri? dtdUri}) async {
    final Uri dtdWsUri =
        dtdUri ??
        Uri.parse(const String.fromEnvironment(kWidgetPreviewDtdUriEnvVar));
    dtd = await DartToolingDaemon.connect(dtdWsUri);
    unawaited(
      dtd.postEvent(
        'WidgetPreviewScaffold',
        'Connected',
        const <String, Object?>{},
      ),
    );

    await initializeEditorService();
  }

  /// Disposes the DTD connection.
  @override
  Future<void> dispose() async {
    super.dispose();
    await dtd.close();
  }

  Future<DTDResponse?> _call(
    String methodName, {
    Map<String, Object?>? params,
  }) => dtd.safeCall(kWidgetPreviewService, methodName, params: params);

  /// Trigger a hot restart of the widget preview scaffold.
  Future<void> hotRestartPreviewer() => _call(kHotRestartPreviewer);

  /// Resolves a package:// URI to a file:// URI using the package_config.
  ///
  /// Returns null if [uri] can not be resolved.
  Future<Uri?> resolveUri(Uri uri) async {
    final response = await _call(kResolveUri, params: {'uri': uri.toString()});
    if (response == null) {
      return null;
    }
    final result = StringResponse.fromDTDResponse(response).value;
    return result == null ? null : Uri.parse(result);
  }

  @override
  late final DartToolingDaemon dtd;
}

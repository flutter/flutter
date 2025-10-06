// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
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

  static const kWidgetPreviewService = 'widget-preview';
  static const kIsWindows = 'isWindows';
  static const kHotRestartPreviewer = 'hotRestartPreviewer';
  static const kResolveUri = 'resolveUri';
  static const kSetPreference = 'setPreference';
  static const kGetPreference = 'getPreference';

  /// Error code for RpcException thrown when attempting to load a key from
  /// persistent preferences that doesn't have an entry.
  static const kNoValueForKey = 200;

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
    await _determineIfWindows();
    await initializeEditorService(this);
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

  /// Returns `true` if the operating system is Windows.
  late final bool isWindows;

  Future<void> _determineIfWindows() async {
    isWindows = (BoolResponse.fromDTDResponse(
      (await _call(kIsWindows))!,
    )).value!;
  }

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

  /// Retrieves an arbitrary value associated with [key] from the persistent
  /// preferences map.
  ///
  /// Returns null if [key] is not in the map.
  Future<Object?> getPreference(String key) async {
    try {
      final response = await _call(kGetPreference, params: {'key': key});
      return switch (response?.type) {
        'StringResponse' => StringResponse.fromDTDResponse(response!).value,
        'BoolResponse' => BoolResponse.fromDTDResponse(response!).value,
        _ => throw StateError('Unexpected response type: ${response?.type}'),
      };
    } on RpcException catch (e) {
      if (e.code == kNoValueForKey) {
        return null;
      }
      rethrow;
    }
  }

  /// Retrieves the state of flag [key] from the persistent preferences map.
  ///
  /// If [key] is not set, [defaultValue] is returned.
  Future<bool> getFlag(String key, {bool defaultValue = false}) async {
    final result = await getPreference(key) as bool?;
    return result ?? defaultValue;
  }

  /// Sets [key] to [value] in the persistent preferences map.
  Future<void> setPreference(String key, Object? value) async {
    await _call(kSetPreference, params: {'key': key, 'value': value});
  }

  @override
  late final DartToolingDaemon dtd;
}

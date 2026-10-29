// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart';

import 'protocol_base/service.dart';

/// The service responsible for cleaning custom platform build and ephemeral
/// artifacts during `flutter clean`.
///
/// Extension authors extend [CleanService] and pass an instance to
/// `ToolExtensionEntryPoint.run` so the host `flutter clean` command can clean
/// up platform-specific build outputs and ephemeral directories before deleting
/// the project's `build/` and `.dart_tool/` directories.
abstract base class CleanService extends ToolExtensionService {
  /// Service namespace identifier for clean.
  static const String serviceNamespace = 'clean';

  static const String _cleanRpcMethod = 'clean';

  /// RPC method identifier to trigger a custom clean.
  static const String cleanMethod = '$serviceNamespace.$_cleanRpcMethod';

  /// RPC parameter key for the serialized [CleanEnvironment].
  static const String environmentParam = 'environment';

  @override
  String get namespace => serviceNamespace;

  /// Cleans custom artifacts for the project described by [environment].
  ///
  /// The host invokes [clean] on every `flutter clean` for every active
  /// extension that registers a [CleanService], before the host deletes
  /// [CleanEnvironment.buildDir] and `.dart_tool/`. Implementations must be
  /// idempotent (for example, no-oping when target directories do not exist).
  /// Any thrown error is logged by the host without aborting `flutter clean`.
  Future<void> clean(CleanEnvironment environment);

  /// Initializes the service by registering RPC methods with the extension provider.
  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{_cleanRpcMethod: _cleanRpc};
  }

  /// Shuts down the service and cleans up any resources.
  @override
  Future<void> shutdown() async {}

  Future<Object?> _cleanRpc(Map<String, Object?> params) async {
    if (params case {environmentParam: final Map<String, Object?> envMap}) {
      final CleanEnvironment env;
      try {
        env = CleanEnvironment.fromJson(envMap);
      } on FormatException catch (e) {
        throw RpcException.invalidParams(e.message);
      }
      await clean(env);
      return null;
    }
    throw RpcException.invalidParams('Missing or invalid "$environmentParam" parameter.');
  }
}

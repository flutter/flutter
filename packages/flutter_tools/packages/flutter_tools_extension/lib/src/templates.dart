// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/json.dart';
import 'package:json_rpc_2/json_rpc_2.dart';

import 'protocol_base/service.dart';

/// The service responsible for adding custom platform support to
/// `flutter create`.
///
/// Extensions implement this service to provide platform templates
/// ([appPlatformTemplates] and [pluginPlatformTemplates]) when scaffolding
/// custom platform implementations (e.g. via
/// `flutter create . --platforms=<custom>`).
///
/// Standalone project templates (`flutter create -t <template>`) are not
/// supported by tool extensions at this time for several reasons:
///
/// 1. **Project-Scoped Discovery**: Under project-scoped `dev_dependencies`
///    discovery, the project (an app or a plugin) already exists before the
///    extension is discovered in `.dart_tool/package_config.json`. Creating an
///    entire project from scratch via `-t <template>` would be either redundant
///    or destructive (`--overwrite`).
/// 2. **Archetype vs. Platform Separation**: In `flutter create`, `-t`
///    (`--template`) selects the project archetype (`app`, `module`, `package`,
///    `plugin`, `plugin_ffi`), whereas `--platforms` selects the target
///    platforms (`android`, `ios`, `linux`, etc.). Custom platforms are
///    scaffolded into an existing project via `--platforms`.
/// 3. **Non-Breaking Evolution**: Because [TemplateService] is an `abstract base
///    class`, standalone project templates can be added in the future as a
///    defaulted getter without breaking existing extensions if a workspace- or
///    multi-package scaffolding use case arises.
abstract base class TemplateService extends ToolExtensionService {
  /// Service namespace identifier for templates.
  static const String serviceNamespace = 'template';

  static const String _getAppPlatformTemplatesRpcMethod = 'getAppPlatformTemplates';
  static const String _getPluginPlatformTemplatesRpcMethod = 'getPluginPlatformTemplates';
  static const String _generatePlatformTemplateParametersRpcMethod =
      'generatePlatformTemplateParameters';

  /// RPC method identifier to retrieve app platform templates.
  static const String getAppPlatformTemplatesMethod =
      '$serviceNamespace.$_getAppPlatformTemplatesRpcMethod';

  /// RPC method identifier to retrieve plugin platform templates.
  static const String getPluginPlatformTemplatesMethod =
      '$serviceNamespace.$_getPluginPlatformTemplatesRpcMethod';

  /// RPC method identifier to generate platform template parameters.
  static const String generatePlatformTemplateParametersMethod =
      '$serviceNamespace.$_generatePlatformTemplateParametersRpcMethod';

  /// RPC parameter key for the target platform name.
  static const String platformNameParam = 'platformName';

  /// RPC parameter key for the tool parameters map.
  static const String toolParametersParam = 'toolParameters';

  @override
  String get namespace => serviceNamespace;

  /// The map of platform name to package template URI to be initialized when
  /// adding custom platform support to an app project.
  Map<String, String> get appPlatformTemplates => const <String, String>{};

  /// The map of platform name to package template URI for platform templates
  /// for `plugin` projects.
  Map<String, String> get pluginPlatformTemplates => const <String, String>{};

  /// Generates custom template parameters for a platform template (for example,
  /// when scaffolding platform files via `flutter create --platforms=<platform>`).
  ///
  /// Defaults to returning [toolParameters] unchanged. Extensions can override
  /// this method to supply custom template variables to Mustache templates.
  Future<Map<String, Object?>> generatePlatformTemplateParameters({
    required String platformName,
    required Map<String, Object?> toolParameters,
  }) async => toolParameters;

  /// Initializes the service by registering RPC methods with the extension provider.
  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      _getAppPlatformTemplatesRpcMethod: _getAppPlatformTemplatesRpc,
      _getPluginPlatformTemplatesRpcMethod: _getPluginPlatformTemplatesRpc,
      _generatePlatformTemplateParametersRpcMethod: _generatePlatformTemplateParametersRpc,
    };
  }

  /// Shuts down the service and cleans up any resources.
  @override
  Future<void> shutdown() async {}

  Future<Object?> _getAppPlatformTemplatesRpc(Map<String, Object?> params) async =>
      appPlatformTemplates;

  Future<Object?> _getPluginPlatformTemplatesRpc(Map<String, Object?> params) async =>
      pluginPlatformTemplates;

  Future<Object?> _generatePlatformTemplateParametersRpc(Map<String, Object?> params) async {
    final String platformName;
    final Map<String, Object?> toolParameters;
    try {
      platformName = params.requiredField<String>(platformNameParam);
      toolParameters = params.requiredField<Map<String, Object?>>(toolParametersParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    return generatePlatformTemplateParameters(
      platformName: platformName,
      toolParameters: toolParameters,
    );
  }
}

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
/// `flutter create --platforms=<custom> .`; `flutter create` integration is
/// tracked in https://github.com/flutter/flutter/issues/190749).
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

  /// Templates this extension provides to add custom platform support to an
  /// app project.
  ///
  /// When a user runs `flutter create --platforms=<custom> .`, the tool looks
  /// up `<custom>` in this map. If it finds an entry, it renders that template
  /// into the project.
  ///
  /// The map's values are `package:` URIs pointing to a directory of template
  /// files inside this extension's `lib/` folder.
  ///
  /// Files ending in `.tmpl` are rendered with Mustache using the values from
  /// [generatePlatformTemplateParameters] and written to the same relative path
  /// inside the project without the `.tmpl` suffix. Files ending in
  /// `.copy.tmpl` are copied without Mustache rendering, with the `.copy.tmpl`
  /// suffix stripped. Files without `.tmpl` in their path are ignored.
  ///
  /// The template should contain only the files needed for this platform. It is
  /// added to a project that already exists, so it should not include
  /// project-wide files such as `lib/main.dart` or `pubspec.yaml`.
  ///
  /// For example, this maps `--platforms=custom_linux` to the template files in
  /// `lib/templates/custom_linux/` of the `my_linux_extension` package:
  ///
  /// ```dart
  /// @override
  /// Map<String, String> get appPlatformTemplates => const <String, String>{
  ///   'custom_linux': 'package:my_linux_extension/templates/custom_linux',
  /// };
  /// ```
  Map<String, String> get appPlatformTemplates => const <String, String>{};

  /// Templates this extension provides to add custom platform support to a
  /// `plugin` project.
  ///
  /// When a user runs `flutter create --template=plugin --platforms=<custom> .`,
  /// the tool looks up `<custom>` in this map. If it finds an entry, it renders
  /// that template into the project.
  ///
  /// The map's values are `package:` URIs pointing to a directory of `.tmpl`
  /// and `.copy.tmpl` template files inside this extension's `lib/` folder,
  /// rendered using the values from [generatePlatformTemplateParameters].
  ///
  /// See [appPlatformTemplates] for details on how platform template files are
  /// structured and rendered.
  Map<String, String> get pluginPlatformTemplates => const <String, String>{};

  /// Generates custom template parameters for both [appPlatformTemplates] and
  /// [pluginPlatformTemplates] (for example, when scaffolding platform files via
  /// `flutter create --platforms=<platform>`).
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

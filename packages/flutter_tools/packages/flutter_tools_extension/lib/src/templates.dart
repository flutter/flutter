// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
import 'package:json_rpc_2/json_rpc_2.dart';

import 'protocol_base/service.dart';

/// The service responsible for adding custom platform support to
/// `flutter create` for `app`, `plugin`, and `plugin_ffi` projects.
///
/// Extensions implement [supportedPlatforms] to advertise custom `--platforms`
/// identifiers and [resolvePlatformTemplate] to resolve the template directory
/// to render when scaffolding a project (`flutter create` integration is
/// tracked in https://github.com/flutter/flutter/issues/190749).
abstract base class TemplateService extends ToolExtensionService {
  /// Service namespace identifier for templates.
  static const String serviceNamespace = 'template';

  static const String _getSupportedPlatformsRpcMethod = 'getSupportedPlatforms';
  static const String _resolvePlatformTemplateRpcMethod = 'resolvePlatformTemplate';
  static const String _generatePlatformTemplateParametersRpcMethod =
      'generatePlatformTemplateParameters';

  /// RPC method identifier to retrieve supported platforms by template type.
  static const String getSupportedPlatformsMethod =
      '$serviceNamespace.$_getSupportedPlatformsRpcMethod';

  /// RPC method identifier to resolve a platform template descriptor.
  static const String resolvePlatformTemplateMethod =
      '$serviceNamespace.$_resolvePlatformTemplateRpcMethod';

  /// RPC method identifier to generate platform template parameters.
  static const String generatePlatformTemplateParametersMethod =
      '$serviceNamespace.$_generatePlatformTemplateParametersRpcMethod';

  /// RPC parameter key for the target platform.
  static const String platformParam = 'platform';

  /// RPC parameter key for the [ExtensionTemplateType] name.
  static const String templateTypeParam = 'templateType';

  /// RPC parameter key for the tool parameters map.
  static const String toolParametersParam = 'toolParameters';

  @override
  String get namespace => serviceNamespace;

  /// Custom platform identifiers supported by this extension for
  /// [templateType], surfaced in `flutter create --help` and `--platforms`
  /// validation.
  ///
  /// Defaults to an empty set.
  ///
  /// ```dart
  /// @override
  /// Set<String> supportedPlatforms(ExtensionTemplateType templateType) =>
  ///     switch (templateType) {
  ///       .app || .plugin => const <String>{'custom_linux'},
  ///       .ffiPlugin => const <String>{},
  ///     };
  /// ```
  Set<String> supportedPlatforms(ExtensionTemplateType templateType) => const <String>{};

  /// Resolves the [ExtensionPlatformTemplate] to render for [platform] and
  /// [templateType] using [toolParameters], or returns `null` if no template
  /// should be rendered for that `(platform, templateType)` pair.
  ///
  /// [ExtensionPlatformTemplate.templateUri] must be a `package:` URI pointing
  /// to a directory of template files inside this extension's `lib/` folder.
  /// Files ending in `.tmpl` are rendered with Mustache using the values from
  /// [generatePlatformTemplateParameters] and written to the same relative path
  /// inside the project without the `.tmpl` suffix. Files ending in
  /// `.copy.tmpl` are copied without Mustache rendering, with the `.copy.tmpl`
  /// suffix stripped. Files without `.tmpl` in their path are ignored.
  ///
  /// Extensions with multiple template variants (such as language or app-type
  /// variants) can inspect [toolParameters] to select the appropriate template
  /// directory dynamically.
  ///
  /// ```dart
  /// @override
  /// Future<ExtensionPlatformTemplate?> resolvePlatformTemplate({
  ///   required String platform,
  ///   required ExtensionTemplateType templateType,
  ///   required Map<String, Object?> toolParameters,
  /// }) async => switch ((platform, templateType)) {
  ///   ('custom_linux', .app) => ExtensionPlatformTemplate(
  ///     templateUri: Uri.parse('package:my_linux_extension/templates/app'),
  ///   ),
  ///   ('custom_linux', .plugin) => ExtensionPlatformTemplate(
  ///     templateUri: Uri.parse('package:my_linux_extension/templates/plugin'),
  ///   ),
  ///   _ => null,
  /// };
  /// ```
  Future<ExtensionPlatformTemplate?> resolvePlatformTemplate({
    required String platform,
    required ExtensionTemplateType templateType,
    required Map<String, Object?> toolParameters,
  }) async => null;

  /// Generates custom template parameters when rendering Mustache templates
  /// returned by [resolvePlatformTemplate] across all [ExtensionTemplateType]s
  /// (for example, via `flutter create --platforms=<platform>`).
  ///
  /// Defaults to returning [toolParameters] unchanged. Extensions can override
  /// this method to supply custom template variables to Mustache templates.
  Future<Map<String, Object?>> generatePlatformTemplateParameters({
    required String platform,
    required Map<String, Object?> toolParameters,
  }) async => toolParameters;

  /// Initializes the service by registering RPC methods with the extension provider.
  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      _getSupportedPlatformsRpcMethod: _getSupportedPlatformsRpc,
      _resolvePlatformTemplateRpcMethod: _resolvePlatformTemplateRpc,
      _generatePlatformTemplateParametersRpcMethod: _generatePlatformTemplateParametersRpc,
    };
  }

  /// Shuts down the service and cleans up any resources.
  @override
  Future<void> shutdown() async {}

  Future<Object?> _getSupportedPlatformsRpc(Map<String, Object?> params) async => <String, Object?>{
    for (final ExtensionTemplateType type in ExtensionTemplateType.values)
      type.name: supportedPlatforms(type).toList(),
  };

  Future<Object?> _resolvePlatformTemplateRpc(Map<String, Object?> params) async {
    final String platform;
    final ExtensionTemplateType templateType;
    final Map<String, Object?> toolParameters;
    try {
      platform = params.requiredField<String>(platformParam);
      final String rawType = params.requiredField<String>(templateTypeParam);
      templateType =
          ExtensionTemplateType.values.asNameMap()[rawType] ??
          (throw FormatException('Invalid "$templateTypeParam": "$rawType".'));
      toolParameters = params.requiredField<Map<String, Object?>>(toolParametersParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    final ExtensionPlatformTemplate? resolved = await resolvePlatformTemplate(
      platform: platform,
      templateType: templateType,
      toolParameters: toolParameters,
    );
    return resolved?.toMap();
  }

  Future<Object?> _generatePlatformTemplateParametersRpc(Map<String, Object?> params) async {
    final String platform;
    final Map<String, Object?> toolParameters;
    try {
      platform = params.requiredField<String>(platformParam);
      toolParameters = params.requiredField<Map<String, Object?>>(toolParametersParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    return generatePlatformTemplateParameters(platform: platform, toolParameters: toolParameters);
  }
}

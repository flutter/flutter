// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../generic_extension_protocol.dart';

/// The service responsible for adding custom platform support to
/// `flutter create`.
abstract base class TemplateService extends ToolExtensionService {
  static const String serviceNamespace = 'template';
  static const String getAppTemplatesMethod = 'template.getAppTemplates';
  static const String getPluginTemplatesMethod = 'template.getPluginTemplates';
  static const String getProjectTemplatesMethod = 'template.getProjectTemplates';
  static const String generateTemplateParametersMethod = 'template.generateTemplateParameters';

  @override
  String get namespace => serviceNamespace;

  /// The set of additional template files to be initialized when using
  /// the `app` template.
  Set<String> get appPlatformTemplates;

  /// The set of platform templates for `plugin` template.
  Set<String> get pluginPlatformTemplates;

  /// The set of full project templates provided by the extension.
  Set<ProjectTemplate> get projectTemplates;

  @override
  Future<Map<String, Function>> initialize() async {
    return <String, Function>{
      'getAppTemplates': _getAppTemplatesRpc,
      'getPluginTemplates': _getPluginTemplatesRpc,
      'getProjectTemplates': _getProjectTemplatesRpc,
      'generateTemplateParameters': _generateTemplateParametersRpc,
    };
  }

  @override
  Future<void> shutdown() async {}

  Future<List<String>> _getAppTemplatesRpc() async {
    return appPlatformTemplates.toList();
  }

  Future<List<String>> _getPluginTemplatesRpc() async {
    return pluginPlatformTemplates.toList();
  }

  Future<List<Map<String, Object?>>> _getProjectTemplatesRpc() async {
    return projectTemplates.map((ProjectTemplate template) => template.toMap()).toList();
  }

  Future<Map<String, Object?>> _generateTemplateParametersRpc(Map<String, Object?> params) async {
    if (params case {
      'templateName': final String templateName,
      'toolParameters': final Map<Object?, Object?> toolParametersObj,
    }) {
      final Map<String, Object?> toolParameters = toolParametersObj.cast<String, Object?>();
      for (final ProjectTemplate template in projectTemplates) {
        if (template.name == templateName) {
          return template.generateTemplateParameters(toolParameters);
        }
      }
      throw RpcException.invalidParams('Unknown project template: $templateName');
    }
    if (params['templateName'] is! String) {
      throw RpcException.invalidParams('Missing "templateName" parameter.');
    }
    throw RpcException.invalidParams('Missing "toolParameters" parameter.');
  }
}

/// A template representation used to generate an entire Flutter project.
abstract base class ProjectTemplate {
  /// The name of this project template.
  String get name;

  /// Whether this template is hidden from help displays.
  bool get hidden;

  /// Dependent template names.
  Set<String> get templateDependencies;

  /// The template source files.
  Set<String> get templateSources;

  /// The package URI string or directory path to the template sources.
  String get templatePath;

  /// Generates the variable mappings for the template.
  Future<Map<String, Object?>> generateTemplateParameters(Map<String, Object?> toolParameters);

  /// Serializes the template metadata for transmission over GEP.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'name': name,
      'hidden': hidden,
      'templateDependencies': templateDependencies.toList(),
      'templateSources': templateSources.toList(),
      'templatePath': templatePath,
    };
  }
}

/// A concrete implementation of [ProjectTemplate] that can be parsed from a JSON map.
final class ExtensionProjectTemplate extends ProjectTemplate {
  ExtensionProjectTemplate.fromJson(Map<String, Object?> json)
    : name = json['name']! as String,
      hidden = json['hidden']! as bool,
      templateDependencies = (json['templateDependencies']! as List<Object?>)
          .cast<String>()
          .toSet(),
      templateSources = (json['templateSources']! as List<Object?>).cast<String>().toSet(),
      templatePath = json['templatePath']! as String;

  /// Parse a list of [ExtensionProjectTemplate] from an RPC response.
  static List<ExtensionProjectTemplate> listFromJson(Object? rpcResult) => [
    if (rpcResult case final List<Object?> l)
      for (final item in l)
        if (item case final Map<Object?, Object?> m)
          ExtensionProjectTemplate.fromJson(m.cast<String, Object?>()),
  ];

  @override
  final String name;

  @override
  final bool hidden;

  @override
  final Set<String> templateDependencies;

  @override
  final Set<String> templateSources;

  @override
  final String templatePath;

  @override
  Future<Map<String, Object?>> generateTemplateParameters(
    Map<String, Object?> toolParameters,
  ) async {
    throw UnimplementedError(
      'ExtensionProjectTemplate.generateTemplateParameters should not be called directly on host representation.',
    );
  }
}

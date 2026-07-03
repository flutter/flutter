// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../generic_extension_protocol.dart';

/// The service responsible for adding custom platform support to
/// `flutter create`.
abstract base class TemplateService extends ToolExtensionService {
  @override
  String get namespace => 'template';

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
      'getAppTemplates': () async => appPlatformTemplates.toList(),
      'getPluginTemplates': () async => pluginPlatformTemplates.toList(),
      'getProjectTemplates': () async {
        return projectTemplates.map((ProjectTemplate template) => template.toMap()).toList();
      },
      'generateTemplateParameters': (Map<String, Object?> parameters) async {
        final templateName = parameters['templateName']! as String;
        final Map<String, Object?> toolParameters = (parameters['toolParameters']! as Map<Object?, Object?>).cast<String, Object?>();
        final ProjectTemplate template = projectTemplates.firstWhere(
          (ProjectTemplate t) => t.name == templateName,
          orElse: () => throw Exception('Template not found: $templateName'),
        );
        return template.generateTemplateParameters(toolParameters);
      },
    };
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

/// A concrete implementation of [ProjectTemplate] deserialized from GEP.
final class ExtensionProjectTemplate extends ProjectTemplate {
  ExtensionProjectTemplate.fromJson(Map<String, Object?> json)
    : name = json['name']! as String,
      hidden = json['hidden']! as bool,
      templateDependencies = (json['templateDependencies']! as List<Object?>)
          .cast<String>()
          .toSet(),
      templateSources = (json['templateSources']! as List<Object?>).cast<String>().toSet(),
      templatePath = json['templatePath']! as String;

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

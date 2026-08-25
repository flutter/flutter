// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

/// A template representation used to generate an entire Flutter project.
///
/// Extensions implement this class to define custom project templates.
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

  /// Serializes the template metadata into a JSON-compatible map.
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
///
/// This represents an extension's template on the host side. Its
/// [generateTemplateParameters] method throws an [UnimplementedError] because
/// parameter generation must be delegated to the extension isolate via RPC.
@immutable
final class ExtensionProjectTemplate extends ProjectTemplate {
  ExtensionProjectTemplate({
    required this.hidden,
    required this.name,
    required this.templateDependencies,
    required this.templatePath,
    required this.templateSources,
  });

  factory ExtensionProjectTemplate.fromJson(Map<String, Object?> json) {
    final Set<String> templateDependencies = switch (json['templateDependencies']) {
      final List<Object?> list => list.whereType<String>().toSet(),
      _ => const <String>{},
    };
    final Set<String> templateSources = switch (json['templateSources']) {
      final List<Object?> list => list.whereType<String>().toSet(),
      _ => const <String>{},
    };

    return ExtensionProjectTemplate(
      hidden: json['hidden'] == true,
      name: json['name'] as String? ?? '',
      templateDependencies: templateDependencies,
      templatePath: json['templatePath'] as String? ?? '',
      templateSources: templateSources,
    );
  }

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

  /// Deserializes a list of [ExtensionProjectTemplate] from RPC response data.
  static List<ExtensionProjectTemplate> listFromJson(Object? rpcResult) {
    if (rpcResult is! List<Object?>) {
      return const <ExtensionProjectTemplate>[];
    }
    return <ExtensionProjectTemplate>[
      for (final Object? item in rpcResult)
        if (item is Map<String, Object?>)
          ExtensionProjectTemplate.fromJson(item)
        else if (item is Map)
          ExtensionProjectTemplate.fromJson(item.cast<String, Object?>()),
    ];
  }

  @override
  String toString() =>
      'ExtensionProjectTemplate(name: $name, hidden: $hidden, templateDependencies: $templateDependencies, templateSources: $templateSources, templatePath: $templatePath)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ExtensionProjectTemplate) {
      return false;
    }
    if (name != other.name ||
        hidden != other.hidden ||
        templatePath != other.templatePath ||
        templateDependencies.length != other.templateDependencies.length ||
        templateSources.length != other.templateSources.length) {
      return false;
    }
    for (final String dep in templateDependencies) {
      if (!other.templateDependencies.contains(dep)) {
        return false;
      }
    }
    for (final String src in templateSources) {
      if (!other.templateSources.contains(src)) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    name,
    hidden,
    templatePath,
    Object.hashAllUnordered(templateDependencies),
    Object.hashAllUnordered(templateSources),
  );
}

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

  /// Generates the variable mappings for the template.
  Future<Map<String, String>> generateTemplateParameters(Map<String, String> toolParameters);
}

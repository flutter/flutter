// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../../flutter_tools_extension.dart';

/// The template service for the Linux extension prototype.
final class LinuxTemplateService extends TemplateService {
  @override
  Set<String> get appPlatformTemplates => const <String>{};

  @override
  Set<String> get pluginPlatformTemplates => const <String>{};

  @override
  Set<ProjectTemplate> get projectTemplates => <ProjectTemplate>{LinuxProjectTemplate()};
}

/// The custom project template representing the 'custom-linux-app'.
final class LinuxProjectTemplate extends ProjectTemplate {
  @override
  String get name => 'custom-linux-app';

  @override
  bool get hidden => false;

  @override
  Set<String> get templateDependencies => const <String>{};

  @override
  Set<String> get templateSources => const <String>{
    'pubspec.yaml.tmpl',
    'lib/main.dart.tmpl',
    '.custom_device_extension_info.copy.tmpl',
  };

  @override
  String get templatePath =>
      'package:flutter_tools/src/extension_prototypes/linux_extension/templates/custom-linux-app';

  @override
  Future<Map<String, Object?>> generateTemplateParameters(
    Map<String, Object?> toolParameters,
  ) async {
    return toolParameters;
  }
}

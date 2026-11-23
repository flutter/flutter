// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// The template service for the Linux extension prototype.
///
/// This service registers custom platform templates for Linux.
final class LinuxTemplateService extends TemplateService {
  /// The CLI identifier for the custom Linux platform template.
  static const String customLinuxPlatformName = 'custom_linux';

  /// Package template URI for the custom Linux platform template files.
  static final Uri customLinuxTemplateUri = Uri.parse(
    'package:flutter_tools_extension_linux_prototype/templates/custom-linux-app',
  );

  @override
  Set<String> supportedPlatforms(ExtensionTemplateType templateType) => switch (templateType) {
    .app => const <String>{customLinuxPlatformName},
    _ => const <String>{},
  };

  @override
  Future<ExtensionPlatformTemplate?> resolvePlatformTemplate({
    required String platform,
    required ExtensionTemplateType templateType,
    required Map<String, Object?> toolParameters,
  }) async => switch ((platform, templateType)) {
    (customLinuxPlatformName, .app) => ExtensionPlatformTemplate(
      templateUri: customLinuxTemplateUri,
    ),
    _ => null,
  };

  @override
  Future<Map<String, Object?>> generatePlatformTemplateParameters({
    required String platform,
    required Map<String, Object?> toolParameters,
  }) async {
    if (platform == customLinuxPlatformName) {
      return <String, Object?>{...toolParameters, 'customLinux': true};
    }
    return toolParameters;
  }
}

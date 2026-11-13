// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// The template service for the Linux extension prototype.
///
/// This service registers custom platform templates for Linux.
final class LinuxTemplateService extends TemplateService {
  /// The CLI identifier for the custom Linux platform template.
  static const String customLinuxPlatformName = 'custom_linux';

  /// Package template URI for the custom Linux platform template files.
  static const String customLinuxTemplateUri =
      'package:flutter_tools_extension_linux_prototype/templates/custom-linux-app';

  @override
  Map<String, String> get appPlatformTemplates => const <String, String>{
    customLinuxPlatformName: customLinuxTemplateUri,
  };

  @override
  Map<String, String> get pluginPlatformTemplates => const <String, String>{};

  @override
  Future<Map<String, Object?>> generatePlatformTemplateParameters({
    required String platformName,
    required Map<String, Object?> toolParameters,
  }) async {
    if (platformName == customLinuxPlatformName) {
      return <String, Object?>{...toolParameters, 'customLinux': true};
    }
    return toolParameters;
  }
}

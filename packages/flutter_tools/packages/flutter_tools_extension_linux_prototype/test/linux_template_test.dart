// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_extension_linux_prototype/src/template.dart';
import 'package:test/test.dart';

void main() {
  group('LinuxTemplateService', () {
    test('appPlatformTemplates returns custom_linux mapping', () {
      final service = LinuxTemplateService();

      expect(
        service.appPlatformTemplates,
        equals(<String, String>{
          LinuxTemplateService.customLinuxPlatformName: LinuxTemplateService.customLinuxTemplateUri,
        }),
      );
      expect(service.pluginPlatformTemplates, isEmpty);
    });

    test('generatePlatformTemplateParameters augments custom_linux parameters', () async {
      final service = LinuxTemplateService();
      final inputParams = <String, Object?>{'projectName': 'my_app', 'org': 'com.example'};

      final Map<String, Object?> result = await service.generatePlatformTemplateParameters(
        platformName: LinuxTemplateService.customLinuxPlatformName,
        toolParameters: inputParams,
      );
      expect(result, equals(<String, Object?>{...inputParams, 'customLinux': true}));
    });

    test(
      'generatePlatformTemplateParameters returns toolParameters unchanged for unknown platforms',
      () async {
        final service = LinuxTemplateService();
        final inputParams = <String, Object?>{'projectName': 'my_app', 'org': 'com.example'};

        final Map<String, Object?> result = await service.generatePlatformTemplateParameters(
          platformName: 'unknown_platform',
          toolParameters: inputParams,
        );
        expect(result, equals(inputParams));
      },
    );
  });
}

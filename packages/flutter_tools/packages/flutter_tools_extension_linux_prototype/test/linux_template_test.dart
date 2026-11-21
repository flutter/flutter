// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension_linux_prototype/src/template.dart';
import 'package:test/test.dart';

void main() {
  group('LinuxTemplateService', () {
    test(
      'supportedPlatforms and resolvePlatformTemplate return custom_linux app template',
      () async {
        final service = LinuxTemplateService();

        expect(
          service.supportedPlatforms(.app),
          equals(const <String>{LinuxTemplateService.customLinuxPlatformName}),
        );
        expect(service.supportedPlatforms(.plugin), isEmpty);
        expect(service.supportedPlatforms(.ffiPlugin), isEmpty);

        final ExtensionPlatformTemplate? appTemplate = await service.resolvePlatformTemplate(
          platform: LinuxTemplateService.customLinuxPlatformName,
          templateType: .app,
          toolParameters: const <String, Object?>{},
        );
        expect(
          appTemplate,
          equals(
            ExtensionPlatformTemplate(templateUri: LinuxTemplateService.customLinuxTemplateUri),
          ),
        );

        expect(
          await service.resolvePlatformTemplate(
            platform: LinuxTemplateService.customLinuxPlatformName,
            templateType: .plugin,
            toolParameters: const <String, Object?>{},
          ),
          isNull,
        );
        expect(
          await service.resolvePlatformTemplate(
            platform: 'unknown_platform',
            templateType: .app,
            toolParameters: const <String, Object?>{},
          ),
          isNull,
        );
      },
    );

    test('generatePlatformTemplateParameters augments custom_linux parameters', () async {
      final service = LinuxTemplateService();
      final inputParams = <String, Object?>{'projectName': 'my_app', 'org': 'com.example'};

      final Map<String, Object?> result = await service.generatePlatformTemplateParameters(
        platform: LinuxTemplateService.customLinuxPlatformName,
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
          platform: 'unknown_platform',
          toolParameters: inputParams,
        );
        expect(result, equals(inputParams));
      },
    );
  });
}

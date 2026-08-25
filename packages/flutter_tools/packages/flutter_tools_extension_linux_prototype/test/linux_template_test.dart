// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension_linux_prototype/src/template.dart';
import 'package:test/test.dart';

void main() {
  group('LinuxTemplateService', () {
    test('projectTemplates returns custom-linux-app template', () {
      final service = LinuxTemplateService();
      final Set<ProjectTemplate> templates = service.projectTemplates;

      expect(templates, hasLength(1));
      final ProjectTemplate template = templates.first;
      expect(template.name, 'custom-linux-app');
      expect(template.hidden, isFalse);
      expect(template.templateDependencies, <String>{'app'});
      expect(
        template.templateSources,
        unorderedEquals(<String>[
          'pubspec.yaml.tmpl',
          'lib/main.dart.tmpl',
          '.custom_device_extension_info.copy.tmpl',
        ]),
      );
      expect(
        template.templatePath,
        'package:flutter_tools_extension_linux_prototype/templates/custom-linux-app',
      );
    });

    test('generateTemplateParameters returns toolParameters unchanged', () async {
      final template = LinuxProjectTemplate();
      final inputParams = <String, Object?>{'projectName': 'my_app', 'org': 'com.example'};

      final Map<String, Object?> result = await template.generateTemplateParameters(inputParams);
      expect(result, equals(inputParams));
    });
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('Template Core Models', () {
    test('ExtensionProjectTemplate serializes and deserializes correctly', () {
      final template = ExtensionProjectTemplate(
        hidden: false,
        name: 'custom-linux-app',
        templateDependencies: const <String>{'app'},
        templatePath: 'package:flutter_tools_extension_linux_prototype/templates/custom-linux-app',
        templateSources: const <String>{
          'pubspec.yaml.tmpl',
          'lib/main.dart.tmpl',
          '.custom_device_extension_info.copy.tmpl',
        },
      );

      final Map<String, Object?> map = template.toMap();
      expect(map['name'], 'custom-linux-app');
      expect(map['hidden'], isFalse);
      expect(map['templateDependencies'], <String>['app']);
      expect(
        map['templateSources'],
        unorderedEquals(<String>[
          'pubspec.yaml.tmpl',
          'lib/main.dart.tmpl',
          '.custom_device_extension_info.copy.tmpl',
        ]),
      );
      expect(
        map['templatePath'],
        'package:flutter_tools_extension_linux_prototype/templates/custom-linux-app',
      );

      final parsed = ExtensionProjectTemplate.fromJson(map);
      expect(parsed, equals(template));
      expect(parsed.hashCode, equals(template.hashCode));
      expect(parsed.toString(), contains('custom-linux-app'));
    });

    test('ExtensionProjectTemplate.listFromJson handles valid and invalid lists', () {
      final templateMap = <String, Object?>{
        'name': 'custom-app',
        'hidden': true,
        'templateDependencies': <String>['module'],
        'templateSources': <String>['pubspec.yaml.tmpl'],
        'templatePath': 'path/to/template',
      };

      final List<ExtensionProjectTemplate> list = ExtensionProjectTemplate.listFromJson(<Object?>[
        templateMap,
      ]);
      expect(list, hasLength(1));
      expect(list.first.name, 'custom-app');
      expect(list.first.hidden, isTrue);
      expect(list.first.templateDependencies, <String>{'module'});

      expect(ExtensionProjectTemplate.listFromJson(null), isEmpty);
      expect(ExtensionProjectTemplate.listFromJson('invalid'), isEmpty);
    });

    test('ExtensionProjectTemplate.generateTemplateParameters throws UnimplementedError', () {
      final template = ExtensionProjectTemplate(
        name: 'custom-app',
        hidden: false,
        templateDependencies: const <String>{},
        templateSources: const <String>{},
        templatePath: 'path',
      );

      expect(
        () => template.generateTemplateParameters(const <String, Object?>{}),
        throwsUnimplementedError,
      );
    });
  });
}

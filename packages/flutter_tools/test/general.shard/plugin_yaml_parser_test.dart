// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/plugin_yaml_parser.dart';
import 'package:yaml/yaml.dart';

import '../src/common.dart';

PluginYamlParser _createParser(
  String yamlText, {
  String pluginName = 'my_plugin',
  String configKey = 'ios',
}) {
  final Object? loaded = loadYaml(yamlText);
  final YamlMap map = loaded is YamlMap ? loaded : YamlMap();
  return PluginYamlParser(map, pluginName: pluginName, configKey: configKey);
}

void main() {
  group('ParseResult', () {
    testWithoutContext('ParseResultFail throws StateError when errors list is empty', () {
      expect(() => ParseResult<int>.fail(<String>[]), throwsStateError);
    });

    testWithoutContext(
      'map and flatMap transform ParseResultPass and preserve ParseResultFail',
      () {
        final pass = ParseResult<int>.pass(2);
        expect(
          pass.map((int v) => v * 3),
          isA<ParseResultPass<int>>().having((ParseResultPass<int> r) => r.value, 'value', 6),
        );
        expect(
          pass.flatMap((int v) => ParseResult<String>.pass('v=$v')),
          isA<ParseResultPass<String>>().having(
            (ParseResultPass<String> r) => r.value,
            'value',
            'v=2',
          ),
        );
        expect(
          pass.flatMap((int v) => ParseResult<String>.fail(<String>['inner error'])),
          isA<ParseResultFail<String>>().having(
            (ParseResultFail<String> r) => r.errors,
            'errors',
            <String>['inner error'],
          ),
        );

        final fail = ParseResult<int>.fail(<String>['initial error']);
        expect(
          fail.map((int v) => v * 3),
          isA<ParseResultFail<int>>().having(
            (ParseResultFail<int> r) => r.errors,
            'errors',
            <String>['initial error'],
          ),
        );
        expect(
          fail.flatMap((int v) => ParseResult<String>.pass('v=$v')),
          isA<ParseResultFail<String>>().having(
            (ParseResultFail<String> r) => r.errors,
            'errors',
            <String>['initial error'],
          ),
        );
      },
    );

    testWithoutContext('ParseResultRecord2 combines passes and accumulates failures', () {
      final ParseResult<String> bothPass = (
        ParseResult<int>.pass(1),
        ParseResult<String>.pass('a'),
      ).map((int a, String b) => '$a:$b');
      expect(
        bothPass,
        isA<ParseResultPass<String>>().having(
          (ParseResultPass<String> r) => r.value,
          'value',
          '1:a',
        ),
      );

      final ParseResult<String> bothFail = (
        ParseResult<int>.fail(<String>['e1']),
        ParseResult<String>.fail(<String>['e2', 'e3']),
      ).map((int a, String b) => '$a:$b');
      expect(
        bothFail,
        isA<ParseResultFail<String>>().having(
          (ParseResultFail<String> r) => r.errors,
          'errors',
          <String>['e1', 'e2', 'e3'],
        ),
      );
    });

    testWithoutContext('ParseResultRecord3 combines passes and accumulates failures', () {
      final ParseResult<String> allPass = (
        ParseResult<int>.pass(1),
        ParseResult<String>.pass('a'),
        ParseResult<bool>.pass(true),
      ).map((int a, String b, bool c) => '$a:$b:$c');
      expect(
        allPass,
        isA<ParseResultPass<String>>().having(
          (ParseResultPass<String> r) => r.value,
          'value',
          '1:a:true',
        ),
      );

      final ParseResult<String> multipleFail = (
        ParseResult<int>.fail(<String>['e1']),
        ParseResult<String>.pass('a'),
        ParseResult<bool>.fail(<String>['e3']),
      ).map((int a, String b, bool c) => '$a:$b:$c');
      expect(
        multipleFail,
        isA<ParseResultFail<String>>().having(
          (ParseResultFail<String> r) => r.errors,
          'errors',
          <String>['e1', 'e3'],
        ),
      );
    });

    testWithoutContext('ParseResultRecord4 combines passes and accumulates failures', () {
      final ParseResult<String> allPass = (
        ParseResult<int>.pass(1),
        ParseResult<String>.pass('a'),
        ParseResult<bool>.pass(true),
        ParseResult<int>.pass(2),
      ).map((int a, String b, bool c, int d) => '$a:$b:$c:$d');
      expect(
        allPass,
        isA<ParseResultPass<String>>().having(
          (ParseResultPass<String> r) => r.value,
          'value',
          '1:a:true:2',
        ),
      );

      final ParseResult<String> multipleFail = (
        ParseResult<int>.fail(<String>['e1']),
        ParseResult<String>.pass('a'),
        ParseResult<bool>.fail(<String>['e3']),
        ParseResult<int>.fail(<String>['e4']),
      ).map((int a, String b, bool c, int d) => '$a:$b:$c:$d');
      expect(
        multipleFail,
        isA<ParseResultFail<String>>().having(
          (ParseResultFail<String> r) => r.errors,
          'errors',
          <String>['e1', 'e3', 'e4'],
        ),
      );
    });
  });

  group('Validation helpers', () {
    testWithoutContext('isValidPluginIdentifier validates simple and dotted identifiers', () {
      expect(isValidPluginIdentifier('MyPlugin'), isTrue);
      expect(isValidPluginIdentifier(r'_Private$Plugin1'), isTrue);
      expect(isValidPluginIdentifier('com.example.my_plugin'), isTrue);

      expect(isValidPluginIdentifier(''), isFalse);
      expect(isValidPluginIdentifier('1InvalidStart'), isFalse);
      expect(isValidPluginIdentifier('com..example'), isFalse);
      expect(isValidPluginIdentifier('Evil(); //'), isFalse);
    });

    testWithoutContext('isValidPluginDartFileName validates safe relative Dart file paths', () {
      expect(isValidPluginDartFileName('my_plugin.dart'), isTrue);
      expect(isValidPluginDartFileName('src/my_plugin-web.dart'), isTrue);

      expect(isValidPluginDartFileName(''), isFalse);
      expect(isValidPluginDartFileName('my_plugin.txt'), isFalse);
      expect(isValidPluginDartFileName('../my_plugin.dart'), isFalse);
      expect(isValidPluginDartFileName('src/../my_plugin.dart'), isFalse);
      expect(isValidPluginDartFileName("foo.dart'; //"), isFalse);
    });
  });

  group('PluginYamlParser', () {
    testWithoutContext(
      'string and requiredString handle present, absent, null, and non-string values',
      () {
        final PluginYamlParser parser = _createParser('''
present: hello
emptyKey:
numberKey: 42
''');

        expect(
          parser.string('present'),
          isA<ParseResultPass<String?>>().having(
            (ParseResultPass<String?> r) => r.value,
            'value',
            'hello',
          ),
        );
        expect(
          parser.requiredString('present'),
          isA<ParseResultPass<String>>().having(
            (ParseResultPass<String> r) => r.value,
            'value',
            'hello',
          ),
        );

        // Absent keys pass with null for string() regardless of allowNull, but fail for requiredString().
        expect(
          parser.string('absent'),
          isA<ParseResultPass<String?>>().having(
            (ParseResultPass<String?> r) => r.value,
            'value',
            isNull,
          ),
        );
        expect(
          parser.string('absent', allowNull: false),
          isA<ParseResultPass<String?>>().having(
            (ParseResultPass<String?> r) => r.value,
            'value',
            isNull,
          ),
        );
        expect(
          parser.requiredString('absent'),
          isA<ParseResultFail<String>>().having(
            (ParseResultFail<String> r) => r.errors,
            'errors',
            <String>[
              'The plugin `my_plugin` is missing the required field `absent` in pubspec.yaml',
            ],
          ),
        );

        // Present key with null value passes only when allowNull is true.
        expect(
          parser.string('emptyKey'),
          isA<ParseResultPass<String?>>().having(
            (ParseResultPass<String?> r) => r.value,
            'value',
            isNull,
          ),
        );
        expect(
          parser.string('emptyKey', allowNull: false),
          isA<ParseResultFail<String?>>().having(
            (ParseResultFail<String?> r) => r.errors,
            'errors',
            <String>['Invalid "ios" plugin specification: the "emptyKey" field must be a string.'],
          ),
        );
        expect(
          parser.requiredString('emptyKey'),
          isA<ParseResultFail<String>>().having(
            (ParseResultFail<String> r) => r.errors,
            'errors',
            <String>['Invalid "ios" plugin specification: the "emptyKey" field must be a string.'],
          ),
        );

        // Non-string value fails.
        expect(
          parser.string('numberKey'),
          isA<ParseResultFail<String?>>().having(
            (ParseResultFail<String?> r) => r.errors,
            'errors',
            <String>['Invalid "ios" plugin specification: the "numberKey" field must be a string.'],
          ),
        );
      },
    );

    testWithoutContext('identifier and requiredIdentifier validate identifier syntax', () {
      final PluginYamlParser parser = _createParser('''
validId: com.example.MyPlugin
invalidId: "Not An Identifier"
''');

      expect(
        parser.identifier('validId'),
        isA<ParseResultPass<String?>>().having(
          (ParseResultPass<String?> r) => r.value,
          'value',
          'com.example.MyPlugin',
        ),
      );
      expect(
        parser.requiredIdentifier('validId'),
        isA<ParseResultPass<String>>().having(
          (ParseResultPass<String> r) => r.value,
          'value',
          'com.example.MyPlugin',
        ),
      );
      expect(
        parser.identifier('absent'),
        isA<ParseResultPass<String?>>().having(
          (ParseResultPass<String?> r) => r.value,
          'value',
          isNull,
        ),
      );
      expect(
        parser.identifier('invalidId'),
        isA<ParseResultFail<String?>>().having(
          (ParseResultFail<String?> r) => r.errors,
          'errors',
          <String>[
            'Invalid "ios" plugin specification: the "invalidId" field must be a valid identifier, optionally with dot-separated segments.',
          ],
        ),
      );
      expect(
        parser.requiredIdentifier('absent'),
        isA<ParseResultFail<String>>().having(
          (ParseResultFail<String> r) => r.errors,
          'errors',
          <String>['The plugin `my_plugin` is missing the required field `absent` in pubspec.yaml'],
        ),
      );
    });

    testWithoutContext('dartFileName and requiredDartFileName validate relative Dart paths', () {
      final PluginYamlParser parser = _createParser('''
validFile: src/my_plugin.dart
invalidFile: ../outside.dart
''');

      expect(
        parser.dartFileName('validFile'),
        isA<ParseResultPass<String?>>().having(
          (ParseResultPass<String?> r) => r.value,
          'value',
          'src/my_plugin.dart',
        ),
      );
      expect(
        parser.requiredDartFileName('validFile'),
        isA<ParseResultPass<String>>().having(
          (ParseResultPass<String> r) => r.value,
          'value',
          'src/my_plugin.dart',
        ),
      );
      expect(
        parser.dartFileName('invalidFile'),
        isA<ParseResultFail<String?>>().having((ParseResultFail<String?> r) => r.errors, 'errors', <
          String
        >[
          'The plugin `my_plugin` has an invalid `invalidFile` for platform `ios` in pubspec.yaml.',
        ]),
      );
      expect(
        parser.requiredDartFileName('absent'),
        isA<ParseResultFail<String>>().having(
          (ParseResultFail<String> r) => r.errors,
          'errors',
          <String>['The plugin `my_plugin` is missing the required field `absent` in pubspec.yaml'],
        ),
      );
    });

    testWithoutContext('flag parses booleans and defaults absent or null to false', () {
      final PluginYamlParser parser = _createParser('''
enabled: true
disabled: false
nullFlag:
invalidFlag: "true"
''');

      expect(
        parser.flag('enabled'),
        isA<ParseResultPass<bool>>().having((ParseResultPass<bool> r) => r.value, 'value', isTrue),
      );
      expect(
        parser.flag('disabled'),
        isA<ParseResultPass<bool>>().having((ParseResultPass<bool> r) => r.value, 'value', isFalse),
      );
      expect(
        parser.flag('nullFlag'),
        isA<ParseResultPass<bool>>().having((ParseResultPass<bool> r) => r.value, 'value', isFalse),
      );
      expect(
        parser.flag('absentFlag'),
        isA<ParseResultPass<bool>>().having((ParseResultPass<bool> r) => r.value, 'value', isFalse),
      );
      expect(
        parser.flag('invalidFlag'),
        isA<ParseResultFail<bool>>().having(
          (ParseResultFail<bool> r) => r.errors,
          'errors',
          <String>[
            'Invalid "ios" plugin specification: the "invalidFlag" field must be a boolean.',
          ],
        ),
      );
    });

    testWithoutContext('parseDartPluginFields parses dartPluginClass and dartFileName', () {
      expect(
        _createParser('').parseDartPluginFields(displayName: 'iOS'),
        isA<ParseResultPass<({String dartPluginClass, String dartFileName})?>>().having(
          (ParseResultPass<({String dartPluginClass, String dartFileName})?> r) => r.value,
          'value',
          isNull,
        ),
      );

      expect(
        _createParser('dartPluginClass: MyDartPlugin').parseDartPluginFields(displayName: 'iOS'),
        isA<ParseResultPass<({String dartPluginClass, String dartFileName})?>>().having(
          (ParseResultPass<({String dartPluginClass, String dartFileName})?> r) => r.value,
          'value',
          (dartPluginClass: 'MyDartPlugin', dartFileName: 'my_plugin.dart'),
        ),
      );

      expect(
        _createParser('''
dartPluginClass: MyDartPlugin
dartFileName: src/custom.dart
''').parseDartPluginFields(displayName: 'iOS'),
        isA<ParseResultPass<({String dartPluginClass, String dartFileName})?>>().having(
          (ParseResultPass<({String dartPluginClass, String dartFileName})?> r) => r.value,
          'value',
          (dartPluginClass: 'MyDartPlugin', dartFileName: 'src/custom.dart'),
        ),
      );

      // dartFileName without dartPluginClass fails.
      expect(
        _createParser('dartFileName: src/custom.dart').parseDartPluginFields(displayName: 'iOS'),
        isA<ParseResultFail<({String dartPluginClass, String dartFileName})?>>().having(
          (ParseResultFail<({String dartPluginClass, String dartFileName})?> r) => r.errors,
          'errors',
          <String>[
            '"dartFileName" cannot be specified without "dartPluginClass" in iOS platform of plugin "my_plugin"',
          ],
        ),
      );

      // Accumulates errors when both dartPluginClass and dartFileName are invalid.
      expect(
        _createParser('''
dartPluginClass: "Invalid Class"
dartFileName: ../invalid.dart
''').parseDartPluginFields(displayName: 'iOS'),
        isA<ParseResultFail<({String dartPluginClass, String dartFileName})?>>().having(
          (ParseResultFail<({String dartPluginClass, String dartFileName})?> r) => r.errors,
          'errors',
          <String>[
            'Invalid "ios" plugin specification: the "dartPluginClass" field must be a valid identifier, optionally with dot-separated segments.',
            'The plugin `my_plugin` has an invalid `dartFileName` for platform `ios` in pubspec.yaml.',
          ],
        ),
      );
    });
  });
}

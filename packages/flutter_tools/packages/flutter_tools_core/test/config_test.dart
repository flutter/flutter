// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('Config Core Models', () {
    test('FeatureFlag serializes and deserializes correctly', () {
      const flag = FeatureFlag(
        name: 'enable-linux-custom-prototype',
        help: 'Enable custom Linux prototype',
        environmentOverride: 'FLUTTER_LINUX_PROTOTYPE',
        enabledByDefault: true,
      );

      final Map<String, Object?> map = flag.toMap();
      expect(map['name'], 'enable-linux-custom-prototype');
      expect(map['help'], 'Enable custom Linux prototype');
      expect(map['environmentOverride'], 'FLUTTER_LINUX_PROTOTYPE');
      expect(map['enabledByDefault'], isTrue);

      final parsed = FeatureFlag.fromJson(map);
      expect(parsed, equals(flag));
      expect(parsed.hashCode, equals(flag.hashCode));
      expect(
        parsed.toString(),
        'FeatureFlag(name: enable-linux-custom-prototype, help: Enable custom Linux prototype, '
        'environmentOverride: FLUTTER_LINUX_PROTOTYPE, enabledByDefault: true)',
      );
      expect(FeatureFlag.listFromJson(<Object?>[map]), <FeatureFlag>[flag]);
    });

    test(
      'ConfigOption serializes and deserializes correctly with aliases and environmentOverride',
      () {
        const config = ConfigOption(
          name: 'linux-gtk-version',
          help: 'Target GTK version',
          environmentOverride: 'FLUTTER_LINUX_GTK_VERSION',
          value: '3',
          aliases: <String>['gtk-version', 'legacy-gtk-version'],
        );

        final Map<String, Object?> map = config.toMap();
        expect(map['name'], 'linux-gtk-version');
        expect(map['help'], 'Target GTK version');
        expect(map['environmentOverride'], 'FLUTTER_LINUX_GTK_VERSION');
        expect(map['value'], '3');
        expect(map['aliases'], <String>['gtk-version', 'legacy-gtk-version']);

        final parsed = ConfigOption.fromJson(map);
        expect(parsed, equals(config));
        expect(parsed.hashCode, equals(config.hashCode));
        expect(
          parsed.toString(),
          'ConfigOption(name: linux-gtk-version, help: Target GTK version, '
          'environmentOverride: FLUTTER_LINUX_GTK_VERSION, value: 3, '
          'aliases: [gtk-version, legacy-gtk-version])',
        );
        expect(ConfigOption.listFromJson(<Object?>[map]), <ConfigOption>[config]);
      },
    );

    test('ConfigAction serializes and deserializes correctly', () {
      const action = ConfigAction(
        name: 'select-custom-signing-settings',
        help: 'Select custom signing settings interactively.',
        aliases: <String>['select-custom-signing-cert'],
        settingsKeys: <String>['custom-signing-cert', 'custom-signing-profile'],
      );

      final Map<String, Object?> map = action.toMap();
      expect(map[ConfigAction.nameKey], 'select-custom-signing-settings');
      expect(map[ConfigAction.helpKey], 'Select custom signing settings interactively.');
      expect(map[ConfigAction.aliasesKey], <String>['select-custom-signing-cert']);
      expect(map[ConfigAction.settingsKeysKey], <String>[
        'custom-signing-cert',
        'custom-signing-profile',
      ]);

      final parsed = ConfigAction.fromJson(map);
      expect(parsed, equals(action));
      expect(parsed.hashCode, equals(action.hashCode));
      expect(
        parsed.toString(),
        'ConfigAction(name: select-custom-signing-settings, help: Select custom signing settings interactively., '
        'aliases: [select-custom-signing-cert], settingsKeys: [custom-signing-cert, custom-signing-profile])',
      );

      final List<ConfigAction> list = ConfigAction.listFromJson(<Object?>[map]);
      expect(list, <ConfigAction>[action]);
    });

    test('FeatureFlag.fromJson, ConfigOption.fromJson, and ConfigAction.fromJson throw FormatException on missing or invalid fields', () {
      expect(
        () => FeatureFlag.fromJson(const <String, Object?>{
          FeatureFlag.helpKey: 'Help',
          FeatureFlag.enabledByDefaultKey: false,
        }),
        throwsFormatException,
      );
      expect(
        () => FeatureFlag.fromJson(const <String, Object?>{
          FeatureFlag.nameKey: '',
          FeatureFlag.helpKey: 'Help',
          FeatureFlag.enabledByDefaultKey: false,
        }),
        throwsFormatException,
      );
      expect(
        () => FeatureFlag.fromJson(const <String, Object?>{
          FeatureFlag.nameKey: 'enable-flag',
          FeatureFlag.helpKey: 'Help',
          FeatureFlag.enabledByDefaultKey: 'true',
        }),
        throwsFormatException,
      );
      expect(
        () => FeatureFlag.fromJson(const <String, Object?>{
          FeatureFlag.nameKey: 'enable-flag',
          FeatureFlag.helpKey: 'Help',
          FeatureFlag.enabledByDefaultKey: false,
          FeatureFlag.environmentOverrideKey: 42,
        }),
        throwsFormatException,
      );
      expect(() => FeatureFlag.listFromJson(const <Object?>['not-a-map']), throwsFormatException);
      expect(
        () => ConfigOption.fromJson(const <String, Object?>{ConfigOption.helpKey: 'Help'}),
        throwsFormatException,
      );
      expect(
        () => ConfigOption.fromJson(const <String, Object?>{
          ConfigOption.nameKey: '',
          ConfigOption.helpKey: 'Help',
        }),
        throwsFormatException,
      );
      expect(
        () => ConfigOption.fromJson(const <String, Object?>{
          ConfigOption.nameKey: 'sdk-path',
          ConfigOption.helpKey: 'Help',
          ConfigOption.valueKey: 42,
        }),
        throwsFormatException,
      );
      expect(
        () => ConfigOption.fromJson(const <String, Object?>{
          ConfigOption.nameKey: 'sdk-path',
          ConfigOption.helpKey: 'Help',
          ConfigOption.environmentOverrideKey: 42,
        }),
        throwsFormatException,
      );
      expect(
        () => ConfigOption.fromJson(const <String, Object?>{
          ConfigOption.nameKey: 'sdk-path',
          ConfigOption.helpKey: 'Help',
          ConfigOption.aliasesKey: <Object?>[123],
        }),
        throwsFormatException,
      );
      expect(() => ConfigOption.listFromJson(const <Object?>['not-a-map']), throwsFormatException);
      expect(
        () => ConfigAction.fromJson(const <String, Object?>{ConfigAction.helpKey: 'Missing name'}),
        throwsFormatException,
      );
      expect(
        () => ConfigAction.fromJson(const <String, Object?>{
          ConfigAction.nameKey: '',
          ConfigAction.helpKey: 'Empty name',
        }),
        throwsFormatException,
      );
      expect(
        () => ConfigAction.fromJson(const <String, Object?>{
          ConfigAction.nameKey: 'action',
          ConfigAction.helpKey: 'Help',
          ConfigAction.settingsKeysKey: <Object?>[42],
        }),
        throwsFormatException,
      );
      expect(() => ConfigAction.listFromJson(const <Object?>['not-a-map']), throwsFormatException);
    });
  });
}

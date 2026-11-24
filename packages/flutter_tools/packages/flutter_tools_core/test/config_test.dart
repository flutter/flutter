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

    test(
      'FeatureFlag.fromJson and ConfigOption.fromJson throw FormatException on invalid fields',
      () {
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
        expect(
          () => ConfigOption.listFromJson(const <Object?>['not-a-map']),
          throwsFormatException,
        );
      },
    );
  });
}

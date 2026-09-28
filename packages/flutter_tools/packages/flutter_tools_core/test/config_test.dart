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
        environmentVariable: 'FLUTTER_LINUX_PROTOTYPE',
        enabledByDefault: true,
      );

      final Map<String, Object?> map = flag.toMap();
      expect(map['name'], 'enable-linux-custom-prototype');
      expect(map['help'], 'Enable custom Linux prototype');
      expect(map['environmentVariable'], 'FLUTTER_LINUX_PROTOTYPE');
      expect(map['enabledByDefault'], isTrue);

      final parsed = FeatureFlag.fromJson(map);
      expect(parsed, equals(flag));
    });

    test('ConfigOption serializes and deserializes correctly', () {
      const config = ConfigOption(
        name: 'linux-gtk-version',
        help: 'Target GTK version',
        value: '3',
      );

      final Map<String, Object?> map = config.toMap();
      expect(map['name'], 'linux-gtk-version');
      expect(map['help'], 'Target GTK version');
      expect(map['value'], '3');

      final parsed = ConfigOption.fromJson(map);
      expect(parsed, equals(config));
    });
  });
}

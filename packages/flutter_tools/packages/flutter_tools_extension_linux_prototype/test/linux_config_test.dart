// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension_linux_prototype/src/config.dart';
import 'package:test/test.dart';

void main() {
  group('LinuxConfigurationExtension', () {
    test('getFeatureFlags returns Linux prototype feature flag', () async {
      final extension = LinuxConfigurationExtension();
      final List<FeatureFlag> flags = await extension.getFeatureFlags();

      expect(flags, hasLength(1));
      expect(flags.first.name, 'enable-linux-custom-prototype');
      expect(flags.first.enabledByDefault, isTrue);
    });

    test('getConfigurations returns Linux prototype config options', () async {
      final extension = LinuxConfigurationExtension();
      final List<ConfigOption> configs = await extension.getConfigurations();

      expect(configs, hasLength(1));
      expect(configs.first.name, 'linux-gtk-version');
      expect(configs.first.value, '3');
    });
  });
}

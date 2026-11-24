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

    test('getConfigActions and runConfigAction clear Linux custom settings', () async {
      final extension = LinuxConfigurationExtension();
      final List<ConfigAction> actions = await extension.getConfigActions();

      expect(actions, hasLength(1));
      expect(actions.first.name, 'clear-linux-custom-settings');
      expect(actions.first.settingsKeys, const <String>['linux-gtk-version']);

      final Map<String, String?> updates = await extension.runConfigAction(
        'clear-linux-custom-settings',
        currentSettings: const <String, String?>{'linux-gtk-version': '4'},
      );
      expect(updates, const <String, String?>{'linux-gtk-version': null});

      await expectLater(
        extension.runConfigAction('unknown-action', currentSettings: const <String, String?>{}),
        throwsA(isA<ToolExtensionException>()),
      );
    });
  });
}

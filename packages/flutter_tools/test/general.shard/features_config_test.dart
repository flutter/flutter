// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_features_config.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';

import '../src/common.dart';

const _noConfigFeature = Feature(name: 'example');
const _configOnlyFeature = Feature(name: 'example', configSetting: 'enable-flag');
const _envOnlyFeature = Feature(name: 'example', environmentOverride: 'ENABLE_FLAG');
const _configAndEnvFeature = Feature(
  name: 'example',
  configSetting: 'enable-flag',
  environmentOverride: 'ENABLE_FLAG',
);

void main() {
  bool? isEnabled(
    Feature feature, {
    Map<String, String> environment = const <String, String>{},
    Map<String, Object> globalConfig = const <String, Object>{},
    String? projectManifest,
  }) {
    final globalConfigReader = Config.test();
    for (final MapEntry<String, Object>(:String key, :Object value) in globalConfig.entries) {
      globalConfigReader.setValue(key, value);
    }

    final logger = BufferLogger.test();
    final FlutterManifest? flutterManifest = projectManifest != null
        ? FlutterManifest.createFromString(projectManifest, logger: logger)
        : FlutterManifest.empty(logger: logger);
    if (flutterManifest == null) {
      fail(logger.errorText);
    }

    final featuresConfig = FlutterFeaturesConfig(
      globalConfig: globalConfigReader,
      platform: FakePlatform(environment: <String, String>{...environment}),
      projectManifest: flutterManifest,
    );
    return featuresConfig.isEnabled(feature);
  }

  test('returns null if cannot be overriden', () {
    expect(
      isEnabled(
        _noConfigFeature,
        environment: <String, String>{'ENABLE_FLAG': 'true'},
        globalConfig: <String, Object>{'enable-flag': true},
        projectManifest: '''
        flutter:
          config:
            enable-flag: true
        ''',
      ),
      isNull,
    );
  });

  test('returns null if every source is omitted', () {
    expect(isEnabled(_configAndEnvFeature), isNull);
  });

  test('overrides from local manifest', () {
    expect(
      isEnabled(
        _configOnlyFeature,
        projectManifest: '''
        flutter:
          config:
            enable-flag: true
        ''',
      ),
      isTrue,
    );
  });

  test('local manifest config must be a map', () {
    expect(
      () => isEnabled(
        _configOnlyFeature,
        projectManifest: '''
        flutter:
          config: true
        ''',
      ),
      throwsToolExit(message: 'must be a map'),
    );
  });

  test('local manifest value must be a boolean', () {
    expect(
      () => isEnabled(
        _configOnlyFeature,
        projectManifest: '''
        flutter:
          config:
            enable-flag: NOT-A-BOOLEAN
        ''',
      ),
      throwsToolExit(message: 'must be a boolean'),
    );
  });

  test('overrides from global configuration', () {
    expect(
      isEnabled(_configOnlyFeature, globalConfig: <String, Object>{'enable-flag': true}),
      isTrue,
    );
  });

  test('global configuration value must be a boolean', () {
    expect(
      () => isEnabled(
        _configOnlyFeature,
        globalConfig: <String, Object>{'enable-flag': 'NOT-A-BOOLEAN'},
      ),
      throwsToolExit(message: 'must be a boolean'),
    );
  });

  test('overrides from local manifest take precedence over global configuration', () {
    expect(
      isEnabled(
        _configOnlyFeature,
        projectManifest: '''
        flutter:
          config:
            enable-flag: true
        ''',
        globalConfig: <String, Object>{'enable-flag': false},
      ),
      isTrue,
    );
  });

  test('overrides from environment', () {
    expect(
      isEnabled(_envOnlyFeature, environment: <String, String>{'ENABLE_FLAG': 'true'}),
      isTrue,
    );
  });

  test('overrides from environment are case insensitive', () {
    expect(
      isEnabled(_envOnlyFeature, environment: <String, String>{'ENABLE_FLAG': 'tRuE'}),
      isTrue,
    );
  });

  test('overrides from environment are lowest priority', () {
    expect(
      isEnabled(
        _configAndEnvFeature,
        environment: <String, String>{'ENABLE_FLAG': 'true'},
        globalConfig: <String, Object>{'enable-flag': false},
      ),
      isFalse,
    );
  });
}

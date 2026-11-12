// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/web/bootstrap.dart';
import 'package:package_config/package_config.dart';

import '../../src/common.dart';

void main() {
  test('generateTestEntrypoint generates proper imports and mappings for tests', () {
    final String result = generateTestEntrypoint(
      testInfos: <WebTestInfo>[
        (entryPoint: 'foo.dart', goldensUri: Uri.parse('foo.dart'), configFile: null),
        (entryPoint: 'bar.dart', goldensUri: Uri.parse('bar.dart'), configFile: 'bar_config.dart'),
      ],
      languageVersion: LanguageVersion(2, 8),
    );

    expect(result, contains("import 'org-dartlang-app:///foo.dart'"));
    expect(result, contains("import 'org-dartlang-app:///bar.dart'"));
    expect(result, contains("import 'org-dartlang-app:///bar_config.dart'"));
  });

  test('bootstrap script embeds urls correctly', () {
    final String result = generateDDCLibraryBundleBootstrapScript(
      ddcModuleLoaderUrl: 'ddc_module_loader.js',
      mapperUrl: 'mapper.js',
      generateLoadingIndicator: true,
      isWindows: false,
    );
    // ddc module loader js source is interpolated correctly.
    expect(result, contains('"src": "ddc_module_loader.js"'));
    // stack trace mapper source is interpolated correctly.
    expect(result, contains('"src": "mapper.js"'));
    // data-main is set to correct bootstrap module.
    expect(result, contains('"src": "main_module.bootstrap.js"'));
    expect(result, contains('"id": "data-main"'));
  });

  test('bootstrap script initializes configuration objects', () {
    final String result = generateDDCLibraryBundleBootstrapScript(
      ddcModuleLoaderUrl: 'ddc_module_loader.js',
      mapperUrl: 'mapper.js',
      generateLoadingIndicator: true,
      isWindows: false,
    );
    // LoadConfiguration and DDCLoader objects must be constructed.
    expect(result, contains(r'new window.$dartLoader.LoadConfiguration('));
    expect(result, contains(r'new window.$dartLoader.DDCLoader('));
    // Specific fields must be set on the LoadConfiguration.
    expect(result, contains('.bootstrapScript ='));
    expect(result, contains('.loadScriptFn ='));
    // DDCLoader.nextAttempt must be invoked to begin loading.
    expect(result, contains('nextAttempt()'));
    // Proper window objects are initialized.
    expect(result, contains(r'window.$dartLoader.loadConfig ='));
    expect(result, contains(r'window.$dartLoader.loader ='));
  });

  test('bootstrap script includes loading indicator', () {
    final String result = generateDDCLibraryBundleBootstrapScript(
      ddcModuleLoaderUrl: 'ddc_module_loader.js',
      mapperUrl: 'mapper.js',
      generateLoadingIndicator: true,
      isWindows: false,
    );
    expect(result, contains('"flutter-loader"'));
    expect(result, contains('"indeterminate"'));
  });

  test('bootstrap script does not include loading indicator', () {
    final String result = generateDDCLibraryBundleBootstrapScript(
      ddcModuleLoaderUrl: 'ddc_module_loader.js',
      mapperUrl: 'mapper.js',
      generateLoadingIndicator: false,
      isWindows: false,
    );
    expect(result, isNot(contains('"flutter-loader"')));
    expect(result, isNot(contains('"indeterminate"')));
    expect(result, isNot(contains('_removeFlutterLoader')));
  });

  // https://github.com/flutter/flutter/issues/107742
  test('bootstrap script loading indicator does not trigger scrollbars', () {
    final String result = generateDDCLibraryBundleBootstrapScript(
      ddcModuleLoaderUrl: 'ddc_module_loader.js',
      mapperUrl: 'mapper.js',
      generateLoadingIndicator: true,
      isWindows: false,
    );

    // See: https://regexr.com/6q0ft
    final regex = RegExp(r'(?:\.flutter-loader\s*\{)[^}]+(?:overflow\:\s*hidden;)[^}]+}');

    expect(result, matches(regex), reason: '.flutter-loader must have overflow: hidden');
  });

  test('bootstrap script defines window._removeFlutterLoader and '
      'does not listen to dart-app-ready', () {
    final String result = generateDDCLibraryBundleBootstrapScript(
      ddcModuleLoaderUrl: 'ddc_module_loader.js',
      mapperUrl: 'mapper.js',
      generateLoadingIndicator: true,
      isWindows: false,
    );
    expect(result, contains(r'window._removeFlutterLoader = function()'));
    expect(result, isNot(contains('dart-app-ready')));
  });

  test('generateDDCLibraryBundleMainModule embeds the entrypoint correctly', () {
    final String result = generateDDCLibraryBundleMainModule(
      entrypoint: 'main.js',
      nativeNullAssertions: false,
      onLoadEndBootstrap: 'on_load_end_bootstrap.js',
      isCi: true,
    );
    // bootstrap main module has correct defined module.
    expect(result, contains('const appName = "org-dartlang-app:///main.js";'));
    expect(result, contains('dartDevEmbedder.runMain(appName, sdkOptions);'));
  });

  test('generateDDCLibraryBundleMainModule invokes window._removeFlutterLoader', () {
    final String result = generateDDCLibraryBundleMainModule(
      entrypoint: 'main.js',
      nativeNullAssertions: false,
      onLoadEndBootstrap: 'on_load_end_bootstrap.js',
      isCi: true,
    );
    expect(result, contains(r'if (window._removeFlutterLoader)'));
    expect(result, contains(r'window._removeFlutterLoader();'));
  });

  test('generateDDCLibraryBundleMainModule includes null safety switches', () {
    final String result = generateDDCLibraryBundleMainModule(
      entrypoint: 'main.js',
      nativeNullAssertions: true,
      onLoadEndBootstrap: 'on_load_end_bootstrap.js',
      isCi: true,
    );

    expect(result, contains('nativeNonNullAsserts: true'));
  });

  test('generateDDCLibraryBundleMainModule can disable null safety switches', () {
    final String result = generateDDCLibraryBundleMainModule(
      entrypoint: 'main.js',
      nativeNullAssertions: false,
      onLoadEndBootstrap: 'on_load_end_bootstrap.js',
      isCi: true,
    );

    expect(result, contains('nativeNonNullAsserts: false'));
  });

  test('generateDDCLibraryBundleMainModule sets max requests when isCi only', () {
    String result = generateDDCLibraryBundleMainModule(
      entrypoint: 'main.js',
      nativeNullAssertions: false,
      onLoadEndBootstrap: 'on_load_end_bootstrap.js',
      isCi: true,
    );

    expect(result, contains('maxRequestPoolSize ='));

    result = generateDDCLibraryBundleMainModule(
      entrypoint: 'main.js',
      nativeNullAssertions: false,
      onLoadEndBootstrap: 'on_load_end_bootstrap.js',
      isCi: false,
    );

    expect(result, isNot(contains('maxRequestPoolSize =')));
  });
}

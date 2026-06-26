// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:test/test.dart';

import 'felt_config.dart';

void main() {
  test('parses optional skwasm variant from run config', () {
    final io.File configFile = _writeConfig('''
compile-configs:
  - name: dart2wasm-skwasm
    compiler: dart2wasm
    renderer: skwasm

test-sets:
  - name: skwasm
    directory: skwasm

test-bundles:
  - name: dart2wasm-skwasm-skwasm
    test-set: skwasm
    compile-configs: dart2wasm-skwasm

run-configs:
  - name: safari-coi-wasm-normal
    browser: safari
    canvaskit-variant: full
    cross-origin-isolated: true
    skwasm-variant: normal
    wasm-allow-list:
      webkit: true

test-suites:
  - name: safari-dart2wasm-skwasm-skwasm
    test-bundle: dart2wasm-skwasm-skwasm
    run-config: safari-coi-wasm-normal
    artifact-deps: [ skwasm ]
''');
    addTearDown(() => configFile.parent.deleteSync(recursive: true));

    final config = FeltConfig.fromFile(configFile.path);

    expect(config.runConfigs.single.skwasmVariant, SkwasmVariant.normal);
  });

  test('leaves skwasm variant unset by default', () {
    final io.File configFile = _writeConfig('''
compile-configs:
  - name: dart2wasm-skwasm
    compiler: dart2wasm
    renderer: skwasm

test-sets:
  - name: skwasm
    directory: skwasm

test-bundles:
  - name: dart2wasm-skwasm-skwasm
    test-set: skwasm
    compile-configs: dart2wasm-skwasm

run-configs:
  - name: safari-coi-wasm
    browser: safari
    canvaskit-variant: full
    cross-origin-isolated: true
    wasm-allow-list:
      webkit: true

test-suites:
  - name: safari-dart2wasm-skwasm-skwasm
    test-bundle: dart2wasm-skwasm-skwasm
    run-config: safari-coi-wasm
    artifact-deps: [ skwasm ]
''');
    addTearDown(() => configFile.parent.deleteSync(recursive: true));

    final config = FeltConfig.fromFile(configFile.path);

    expect(config.runConfigs.single.skwasmVariant, isNull);
  });

  test('parses wimp artifact dependency separately from skwasm', () {
    final io.File configFile = _writeConfig('''
compile-configs:
  - name: dart2wasm-skwasm
    compiler: dart2wasm
    renderer: skwasm

test-sets:
  - name: skwasm
    directory: skwasm

test-bundles:
  - name: dart2wasm-skwasm-skwasm
    test-set: skwasm
    compile-configs: dart2wasm-skwasm

run-configs:
  - name: chrome-wimp
    browser: chrome
    canvaskit-variant: chromium
    cross-origin-isolated: true
    enable-wimp: true

test-suites:
  - name: chrome-dart2wasm-wimp-skwasm
    test-bundle: dart2wasm-skwasm-skwasm
    run-config: chrome-wimp
    artifact-deps: [ skwasm, wimp ]
''');
    addTearDown(() => configFile.parent.deleteSync(recursive: true));

    final ArtifactDependencies artifactDependencies = FeltConfig.fromFile(
      configFile.path,
    ).testSuites.single.artifactDependencies;

    expect(artifactDependencies.skwasm, isTrue);
    expect(artifactDependencies.wimp, isTrue);
  });
}

io.File _writeConfig(String contents) {
  final io.Directory directory = io.Directory.systemTemp.createTempSync('felt_config_test.');
  final file = io.File('${directory.path}/felt_config.yaml');
  file.writeAsStringSync(contents);
  return file;
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
@TestOn('vm && linux')

import 'dart:io' as io;

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'common.dart';
import 'environment.dart';
import 'firefox_installer.dart';

void main() async {
  void deleteFirefoxInstallIfExists() {
    final io.Directory firefoxInstallationDir = io.Directory(
      path.join(environment.webUiDartToolDir.path, 'firefox'),
    );

    if (firefoxInstallationDir.existsSync()) {
      firefoxInstallationDir.deleteSync(recursive: true);
    }
  }

  setUpAll(() {
    deleteFirefoxInstallIfExists();
  });

  tearDown(() {
    deleteFirefoxInstallIfExists();
  });

  test('installs a given version of Firefox', () async {
    FirefoxInstaller installer = FirefoxInstaller(version: '69.0.2');
    expect(installer.isInstalled, isFalse);

    BrowserInstallation installation = await getOrInstallFirefox('69.0.2');

    expect(installation.version, '69.0.2');
    expect(installer.isInstalled, isTrue);
    expect(io.File(installation.executable).existsSync(), isTrue);
  });
}

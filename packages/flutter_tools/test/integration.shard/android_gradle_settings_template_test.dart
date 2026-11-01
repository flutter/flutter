// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart' show getGradlewFileName;
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  testWithoutContext('Android Gradle configuration accepts a symbolic-link flutter.sdk', () async {
    final Directory tempDirectory = createResolvedTempDirectorySync('android_gradle_symlink.');
    addTearDown(() => tempDirectory.deleteSync(recursive: true));

    final Directory projectDirectory = tempDirectory.childDirectory('app');
    final ProcessResult createResult = await processManager.run(<String>[
      flutterBin,
      'create',
      '--platforms=android',
      '--no-pub',
      projectDirectory.path,
    ]);
    expect(createResult, const ProcessResultMatcher());

    final Link sdkLink = tempDirectory.childLink('flutter_sdk')..createSync(getFlutterRoot());
    final File localProperties = projectDirectory
        .childDirectory('android')
        .childFile('local.properties');
    final String linkPath = sdkLink.path.replaceAll(r'\', '/');
    localProperties.writeAsStringSync(
      localProperties.readAsStringSync().replaceFirst(
        RegExp(r'^flutter\.sdk=.*$', multiLine: true),
        'flutter.sdk=$linkPath',
      ),
    );

    final File initScript = tempDirectory.childFile('print_included_builds.gradle')
      ..writeAsStringSync(r'''
gradle.settingsEvaluated { settings ->
  settings.pluginManagement.includedBuilds.each { println "INCLUDED_BUILD=${it.rootDir}" }
}
''');
    final Directory androidDirectory = projectDirectory.childDirectory('android');
    final ProcessResult configResult = await processManager.run(<String>[
      '.${platform.pathSeparator}${getGradlewFileName(platform)}',
      '--init-script',
      initScript.path,
      'prepareKotlinBuildScriptModel',
    ], workingDirectory: androidDirectory.path);
    expect(configResult, const ProcessResultMatcher());

    final String canonicalGradleDir = fileSystem
        .directory(fileSystem.path.join(getFlutterRoot(), 'packages', 'flutter_tools', 'gradle'))
        .resolveSymbolicLinksSync();
    expect(configResult.stdout, contains('INCLUDED_BUILD=$canonicalGradleDir'));
  });
}

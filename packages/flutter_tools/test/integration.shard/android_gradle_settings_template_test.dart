// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart' show getGradlewFileName;
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  testWithoutContext('Android Gradle template contract uses canonical included-build paths', () {
    expect(
      fileSystem.file('templates/app/android.tmpl/settings.gradle.kts.tmpl').readAsStringSync(),
      contains(
        r'includeBuild(file("$flutterSdkPath/packages/flutter_tools/gradle").canonicalPath)',
      ),
    );
    expect(
      fileSystem
          .file('templates/module/android/host_app_ephemeral/settings.gradle.tmpl')
          .readAsStringSync(),
      contains(
        r'includeBuild(file("$flutterSdkPath/packages/flutter_tools/gradle").canonicalPath)',
      ),
    );
    expect(
      fileSystem
          .file('templates/module/android/library_new_embedding/include_flutter.groovy.copy.tmpl')
          .readAsStringSync(),
      contains(
        r'includeBuild(new File("$flutterSdkPath/packages/flutter_tools/gradle").canonicalPath)',
      ),
    );
  });

  testWithoutContext('canonical path resolves an SDK symbolic link', () {
    final Directory tempDirectory = fileSystem.systemTempDirectory.createTempSync(
      'flutter_gradle_',
    );
    addTearDown(() => tempDirectory.deleteSync(recursive: true));
    final Directory sdkDirectory = tempDirectory.childDirectory('sdk')..createSync();
    final Link sdkLink = tempDirectory.childLink('flutter_sdk')..createSync(sdkDirectory.path);

    expect(sdkLink.resolveSymbolicLinksSync(), sdkDirectory.resolveSymbolicLinksSync());
  });

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

    final Directory androidDirectory = projectDirectory.childDirectory('android');
    final ProcessResult configResult = await processManager.run(<String>[
      '.${platform.pathSeparator}${getGradlewFileName(platform)}',
      'prepareKotlinBuildScriptModel',
    ], workingDirectory: androidDirectory.path);
    expect(configResult, const ProcessResultMatcher());
  });
}

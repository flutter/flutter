// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_project_validator.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/project_validator_result.dart';

import '../../src/common.dart';

void main() {
  group('AndroidManifestProjectValidator', () {
    late MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem.test();
    });

    void createFakeAndroidProject(String manifestContent) {
      fs.file('android/build.gradle').createSync(recursive: true);
      final File manifestFile = fs.file('android/app/src/main/AndroidManifest.xml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync(manifestContent);
    }

    testWithoutContext('supports project with android directory', () {
      final FlutterProject project = FlutterProject.fromDirectoryTest(fs.currentDirectory);
      const validator = AndroidManifestProjectValidator();
      expect(validator.supportsProject(project), false);

      fs.directory('android').createSync();
      expect(validator.supportsProject(project), true);
    });

    testWithoutContext('succeeds if manifest is clean', () async {
      createFakeAndroidProject('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:name="io.flutter.app.FlutterApplication">
        <meta-data android:name="io.flutter.embedding.android.EnableImpeller" android:value="true" />
        <activity android:name=".MainActivity">
            <meta-data android:name="io.flutter.Entrypoint" android:value="customMain" />
        </activity>
    </application>
</manifest>
''');

      final FlutterProject project = FlutterProject.fromDirectoryTest(fs.currentDirectory);
      const validator = AndroidManifestProjectValidator();
      final List<ProjectValidatorResult> results = await validator.start(project);

      expect(results.length, 1);
      expect(results[0].status, StatusProjectValidator.success);
      expect(results[0].value, 'No issues found');
    });

    testWithoutContext('warns if activity key is under application', () async {
      createFakeAndroidProject('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:name="io.flutter.app.FlutterApplication">
        <meta-data android:name="io.flutter.Entrypoint" android:value="customMain" />
        <activity android:name=".MainActivity">
        </activity>
    </application>
</manifest>
''');

      final FlutterProject project = FlutterProject.fromDirectoryTest(fs.currentDirectory);
      const validator = AndroidManifestProjectValidator();
      final List<ProjectValidatorResult> results = await validator.start(project);

      expect(results.length, 1);
      expect(results[0].status, StatusProjectValidator.error);
      expect(results[0].name, 'io.flutter.Entrypoint');
      expect(results[0].value, 'Declared in <application> but must be declared in <activity>');
    });

    testWithoutContext('warns if application key is under activity', () async {
      createFakeAndroidProject('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:name="io.flutter.app.FlutterApplication">
        <activity android:name=".MainActivity">
            <meta-data android:name="io.flutter.embedding.android.EnableImpeller" android:value="true" />
        </activity>
    </application>
</manifest>
''');

      final FlutterProject project = FlutterProject.fromDirectoryTest(fs.currentDirectory);
      const validator = AndroidManifestProjectValidator();
      final List<ProjectValidatorResult> results = await validator.start(project);

      expect(results.length, 1);
      expect(results[0].status, StatusProjectValidator.error);
      expect(results[0].name, 'io.flutter.embedding.android.EnableImpeller');
      expect(results[0].value, 'Declared in <activity> but must be declared in <application>');
    });
  });
}

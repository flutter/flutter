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
      expect(
        results[0].value,
        'Declared in <application> but must be declared in <activity> or <activity-alias>',
      );
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

    testWithoutContext('warns if AndroidManifest.xml is missing', () async {
      fs.directory('android').createSync();
      final FlutterProject project = FlutterProject.fromDirectoryTest(fs.currentDirectory);
      const validator = AndroidManifestProjectValidator();
      final List<ProjectValidatorResult> results = await validator.start(project);

      expect(results.length, 1);
      expect(results[0].status, StatusProjectValidator.warning);
      expect(results[0].name, 'AndroidManifest.xml');
      expect(results[0].value, 'Manifest file not found');
    });

    testWithoutContext('errors if AndroidManifest.xml is malformed XML', () async {
      createFakeAndroidProject('malformed xml <manifest>');
      final FlutterProject project = FlutterProject.fromDirectoryTest(fs.currentDirectory);
      const validator = AndroidManifestProjectValidator();
      final List<ProjectValidatorResult> results = await validator.start(project);

      expect(results.length, 1);
      expect(results[0].status, StatusProjectValidator.error);
      expect(results[0].name, 'AndroidManifest.xml');
      expect(results[0].value, contains('Error parsing XML'));
    });

    testWithoutContext('warns if activity key is under service', () async {
      createFakeAndroidProject('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:name="io.flutter.app.FlutterApplication">
        <service android:name=".MyService">
            <meta-data android:name="io.flutter.Entrypoint" android:value="customMain" />
        </service>
    </application>
</manifest>
''');

      final FlutterProject project = FlutterProject.fromDirectoryTest(fs.currentDirectory);
      const validator = AndroidManifestProjectValidator();
      final List<ProjectValidatorResult> results = await validator.start(project);

      expect(results.length, 1);
      expect(results[0].status, StatusProjectValidator.error);
      expect(results[0].name, 'io.flutter.Entrypoint');
      expect(
        results[0].value,
        'Declared in <service> but must be declared in <activity> or <activity-alias>',
      );
    });

    testWithoutContext('warns if application key is under receiver', () async {
      createFakeAndroidProject('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:name="io.flutter.app.FlutterApplication">
        <receiver android:name=".MyReceiver">
            <meta-data android:name="io.flutter.embedding.android.EnableImpeller" android:value="true" />
        </receiver>
    </application>
</manifest>
''');

      final FlutterProject project = FlutterProject.fromDirectoryTest(fs.currentDirectory);
      const validator = AndroidManifestProjectValidator();
      final List<ProjectValidatorResult> results = await validator.start(project);

      expect(results.length, 1);
      expect(results[0].status, StatusProjectValidator.error);
      expect(results[0].name, 'io.flutter.embedding.android.EnableImpeller');
    });

    testWithoutContext('warns if activity key is under provider', () async {
      createFakeAndroidProject('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:name="io.flutter.app.FlutterApplication">
        <provider android:name=".MyProvider" android:authorities="com.example.provider">
            <meta-data android:name="io.flutter.Entrypoint" android:value="customMain" />
        </provider>
    </application>
</manifest>
''');

      final FlutterProject project = FlutterProject.fromDirectoryTest(fs.currentDirectory);
      const validator = AndroidManifestProjectValidator();
      final List<ProjectValidatorResult> results = await validator.start(project);

      expect(results.length, 1);
      expect(results[0].status, StatusProjectValidator.error);
      expect(results[0].name, 'io.flutter.Entrypoint');
      expect(
        results[0].value,
        'Declared in <provider> but must be declared in <activity> or <activity-alias>',
      );
    });

    testWithoutContext('reports multiple misplaced keys', () async {
      createFakeAndroidProject('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:name="io.flutter.app.FlutterApplication">
        <meta-data android:name="io.flutter.Entrypoint" android:value="customMain" />
        <activity android:name=".MainActivity">
            <meta-data android:name="io.flutter.embedding.android.EnableImpeller" android:value="true" />
        </activity>
    </application>
</manifest>
''');

      final FlutterProject project = FlutterProject.fromDirectoryTest(fs.currentDirectory);
      const validator = AndroidManifestProjectValidator();
      final List<ProjectValidatorResult> results = await validator.start(project);

      expect(results.length, 2);
      expect(results[0].status, StatusProjectValidator.error);
      expect(results[0].name, 'io.flutter.Entrypoint');
      expect(
        results[0].value,
        'Declared in <application> but must be declared in <activity> or <activity-alias>',
      );

      expect(results[1].status, StatusProjectValidator.error);
      expect(results[1].name, 'io.flutter.embedding.android.EnableImpeller');
      expect(results[1].value, 'Declared in <activity> but must be declared in <application>');
    });

    testWithoutContext('succeeds if activity key is under activity-alias', () async {
      createFakeAndroidProject('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:name="io.flutter.app.FlutterApplication">
        <activity-alias android:name=".MainActivityAlias" android:targetActivity=".MainActivity">
            <meta-data android:name="io.flutter.Entrypoint" android:value="customMain" />
        </activity-alias>
        <activity android:name=".MainActivity">
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
  });
}

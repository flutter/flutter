// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/multidex.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  testUsingContext('ensureMultidexUtilsExists patches file when invalid', () async {
    final Directory directory = globals.fs.currentDirectory;
    final File applicationFile = directory.childDirectory('android')
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childDirectory('java')
      .childDirectory('io')
      .childDirectory('flutter')
      .childDirectory('app')
      .childFile('FlutterMultiDexApplication.java');
    applicationFile.createSync(recursive: true);
    applicationFile.writeAsStringSync('hello', flush: true);
    expect(applicationFile.readAsStringSync(), 'hello');

    ensureMultiDexApplicationExists(directory);

    // File should remain untouched
    expect(applicationFile.readAsStringSync(), '''
// Generated file.
//
// If you wish to remove Flutter's multidex support, delete this entire file.
//
// Modifications to this file should be done in a copy under a different name
// as this file may be regenerated.

package io.flutter.app;

import android.app.Application;
import android.content.Context;
import androidx.annotation.CallSuper;
import androidx.multidex.MultiDex;

/**
 * Extension of {@link android.app.Application}, adding multidex support.
 */
public class FlutterMultiDexApplication extends Application {
  @Override
  @CallSuper
  protected void attachBaseContext(Context base) {
    super.attachBaseContext(base);
    MultiDex.install(this);
  }
}
''');
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('ensureMultiDexApplicationExists generates when does not exist', () async {
    final Directory directory = globals.fs.currentDirectory;
    final File applicationFile = directory.childDirectory('android')
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childDirectory('java')
      .childDirectory('io')
      .childDirectory('flutter')
      .childDirectory('app')
      .childFile('FlutterMultiDexApplication.java');

    ensureMultiDexApplicationExists(directory);

    final String contents = applicationFile.readAsStringSync();
    expect(contents.contains('FlutterMultiDexApplication'), true);
    expect(contents.contains('MultiDex.install(this);'), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('multiDexApplicationExists false when does not exist', () async {
    final Directory directory = globals.fs.currentDirectory;
    expect(multiDexApplicationExists(directory), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('multiDexApplicationExists true when does exist', () async {
    final Directory directory = globals.fs.currentDirectory;
    final File utilsFile = directory.childDirectory('android')
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childDirectory('java')
      .childDirectory('io')
      .childDirectory('flutter')
      .childDirectory('app')
      .childFile('FlutterMultiDexApplication.java');
    utilsFile.createSync(recursive: true);

    expect(multiDexApplicationExists(directory), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('androidManifestHasNameVariable true with valid manifest', () async {
    final Directory directory = globals.fs.currentDirectory;
    final File applicationFile = directory.childDirectory('android')
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childFile('AndroidManifest.xml');
    applicationFile.createSync(recursive: true);
    applicationFile.writeAsStringSync(r'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.multidexapp">
   <application
        android:label="multidextest2"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
    </application>
</manifest>
''', flush: true);
    expect(androidManifestHasNameVariable(directory), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('androidManifestHasNameVariable false with no android:name attribute', () async {
    final Directory directory = globals.fs.currentDirectory;
    final File applicationFile = directory.childDirectory('android')
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childFile('AndroidManifest.xml');
    applicationFile.createSync(recursive: true);
    applicationFile.writeAsStringSync(r'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.multidexapp">
   <application
        android:label="multidextest2"
        android:icon="@mipmap/ic_launcher">
    </application>
''', flush: true);
    expect(androidManifestHasNameVariable(directory), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('androidManifestHasNameVariable false with incorrect android:name attribute', () async {
    final Directory directory = globals.fs.currentDirectory;
    final File applicationFile = directory.childDirectory('android')
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childFile('AndroidManifest.xml');
    applicationFile.createSync(recursive: true);
    applicationFile.writeAsStringSync(r'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.multidexapp">
   <application
        android:label="multidextest2"
        android:name="io.flutter.app.FlutterApplication"
        android:icon="@mipmap/ic_launcher">
    </application>
''', flush: true);
    expect(androidManifestHasNameVariable(directory), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('androidManifestHasNameVariable false with invalid xml manifest', () async {
    final Directory directory = globals.fs.currentDirectory;
    final File applicationFile = directory.childDirectory('android')
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childFile('AndroidManifest.xml');
    applicationFile.createSync(recursive: true);
    applicationFile.writeAsStringSync(r'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.multidexapp">
   <application
        android:label="multidextest2"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
    </application>
''', flush: true);
    expect(androidManifestHasNameVariable(directory), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('androidManifestHasNameVariable false with no manifest file', () async {
    final Directory directory = globals.fs.currentDirectory;
    expect(androidManifestHasNameVariable(directory), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });
}

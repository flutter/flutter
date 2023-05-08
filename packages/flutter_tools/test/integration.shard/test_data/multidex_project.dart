// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';

import '../../src/common.dart';
import '../test_utils.dart';
import 'project.dart';

class MultidexProject extends Project {
  MultidexProject(this.includeFlutterMultiDexApplication);

  @override
  Future<void> setUpIn(Directory dir, {
    bool useDeferredLoading = false,
    bool useSyntheticPackage = false,
  }) {
    this.dir = dir;
    writeFile(fileSystem.path.join(dir.path, 'android', 'settings.gradle'), androidSettings);
    writeFile(fileSystem.path.join(dir.path, 'android', 'build.gradle'), androidBuild);
    writeFile(fileSystem.path.join(dir.path, 'android', 'local.properties'), androidLocalProperties);
    writeFile(fileSystem.path.join(dir.path, 'android', 'gradle.properties'), androidGradleProperties);
    writeFile(fileSystem.path.join(dir.path, 'android', 'app', 'build.gradle'), appBuild);
    writeFile(fileSystem.path.join(dir.path, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'), appManifest);
    writeFile(fileSystem.path.join(dir.path, 'android', 'app', 'src', 'main', 'res', 'values', 'strings.xml'), appStrings);
    writeFile(fileSystem.path.join(dir.path, 'android', 'app', 'src', 'main', 'res', 'values', 'styles.xml'), appStyles);
    writeFile(fileSystem.path.join(dir.path, 'android', 'app', 'src', 'main', 'res', 'drawable', 'launch_background.xml'), appLaunchBackground);
    if (includeFlutterMultiDexApplication) {
      writeFile(fileSystem.path.join(dir.path, 'android', 'app', 'src', 'main', 'java', fileSystem.path.join('io', 'flutter', 'app', 'FlutterMultiDexApplication.java')), appMultidexApplication);
    }
    return super.setUpIn(dir);
  }

  final bool includeFlutterMultiDexApplication;

  @override
  final String pubspec = '''
  name: test
  environment:
    sdk: '>=3.0.0-0 <4.0.0'

  dependencies:
    flutter:
      sdk: flutter
    # Pin to specific plugin versions to avoid out-of-band failures.
    cloud_firestore: 2.5.3
    firebase_core: 1.6.0
  ''';

  @override
  final String main = r'''
  import 'package:flutter/material.dart';

  void main() {
    runApp(MyApp());
  }

  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Flutter Demo',
        home: Container(),
      );
    }
  }
  ''';

  String get androidSettings => r'''
  include ':app'

  def localPropertiesFile = new File(rootProject.projectDir, "local.properties")
  def properties = new Properties()

  assert localPropertiesFile.exists()
  localPropertiesFile.withReader("UTF-8") { reader -> properties.load(reader) }

  def flutterSdkPath = properties.getProperty("flutter.sdk")
  assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
  apply from: "$flutterSdkPath/packages/flutter_tools/gradle/app_plugin_loader.gradle"
  ''';

  String get androidBuild => r'''
  buildscript {
      ext.kotlin_version = '1.3.50'
      repositories {
          google()
          mavenCentral()
      }

      dependencies {
          classpath 'com.android.tools.build:gradle:4.1.0'
          classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
      }
  }

  allprojects {
      repositories {
          google()
          mavenCentral()
      }
  }

  rootProject.buildDir = '../build'
  subprojects {
      project.buildDir = "${rootProject.buildDir}/${project.name}"
  }
  subprojects {
      project.evaluationDependsOn(':app')
  }

  tasks.register("clean", Delete) {
      delete rootProject.buildDir
  }
  ''';

  String get appBuild => r'''
  def localProperties = new Properties()
  def localPropertiesFile = rootProject.file('local.properties')
  if (localPropertiesFile.exists()) {
      localPropertiesFile.withReader('UTF-8') { reader ->
          localProperties.load(reader)
      }
  }

  def flutterRoot = localProperties.getProperty('flutter.sdk')
  if (flutterRoot == null) {
      throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
  }

  def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
  if (flutterVersionCode == null) {
      flutterVersionCode = '1'
  }

  def flutterVersionName = localProperties.getProperty('flutter.versionName')
  if (flutterVersionName == null) {
      flutterVersionName = '1.0'
  }

  apply plugin: 'com.android.application'
  apply plugin: 'kotlin-android'
  apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"

  android {
      compileSdkVersion 31

      compileOptions {
          sourceCompatibility JavaVersion.VERSION_1_8
          targetCompatibility JavaVersion.VERSION_1_8
      }

      kotlinOptions {
          jvmTarget = '1.8'
      }

      sourceSets {
          main.java.srcDirs += 'src/main/kotlin'
      }

      defaultConfig {
          // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
          applicationId "com.example.multidextest2"
          minSdkVersion 16
          targetSdkVersion 30
          versionCode flutterVersionCode.toInteger()
          versionName flutterVersionName
      }

      buildTypes {
          release {
              // TODO: Add your own signing config for the release build.
              // Signing with the debug keys for now, so `flutter run --release` works.
              signingConfig signingConfigs.debug
          }
      }
  }

  flutter {
      source '../..'
  }

  dependencies {
      implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
  }
  ''';

  String get androidLocalProperties => '''
  flutter.sdk=${getFlutterRoot()}
  flutter.buildMode=debug
  flutter.versionName=1.0.0
  flutter.versionCode=22
  ''';

  String get androidGradleProperties => '''
  org.gradle.jvmargs=-Xmx1536M
  android.useAndroidX=true
  android.enableJetifier=true
  android.enableR8=true
  android.experimental.enableNewResourceShrinker=true
  ''';

  String get appManifest => r'''
  <manifest xmlns:android="http://schemas.android.com/apk/res/android"
      package="com.example.multidextest">
     <application
          android:label="multidextest"
          android:name="${applicationName}">
          <activity
              android:name=".MainActivity"
              android:launchMode="singleTop"
              android:theme="@style/LaunchTheme"
              android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
              android:hardwareAccelerated="true"
              android:windowSoftInputMode="adjustResize">
              <!-- Specifies an Android theme to apply to this Activity as soon as
                   the Android process has started. This theme is visible to the user
                   while the Flutter UI initializes. After that, this theme continues
                   to determine the Window background behind the Flutter UI. -->
              <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"
                />
              <intent-filter>
                  <action android:name="android.intent.action.MAIN"/>
                  <category android:name="android.intent.category.LAUNCHER"/>
              </intent-filter>
          </activity>
          <!-- Don't delete the meta-data below.
               This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
          <meta-data
              android:name="flutterEmbedding"
              android:value="2" />
      </application>
  </manifest>
  ''';

  String get appStrings => r'''
<?xml version="1.0" encoding="utf-8"?>
<resources>
</resources>
  ''';

  String get appStyles => r'''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme applied to the Android Window while the process is starting -->
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <!-- Show a splash screen on the activity. Automatically removed when
             the Flutter engine draws its first frame -->
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <!-- Theme applied to the Android Window as soon as the process has started.
         This theme determines the color of the Android Window while your
         Flutter UI initializes, as well as behind your Flutter UI while its
         running.

         This Theme is only used starting with V2 of Flutter's Android embedding. -->
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@android:color/white</item>
    </style>
</resources>
  ''';

  String get appLaunchBackground => r'''
<?xml version="1.0" encoding="utf-8"?>
<!-- Modify this file to customize your launch splash screen -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />

    <!-- You can insert your own image assets here -->
    <!-- <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/launch_image" />
    </item> -->
</layer-list>
  ''';

  String get appMultidexApplication => r'''
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
  ''';
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic_project.dart';
import 'deferred_components_config.dart';
import 'deferred_components_project.dart';

class LegacySettingsGradleProject extends BasicProject {
  @override
  String get pubspec => r'''
name: test_plugin_example
environment:
  sdk: '>=3.2.0-0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  ''';

  @override
  final DeferredComponentsConfig? deferredComponents =
      LegacySettingsGradleDeferredComponentsConfig();
}

class LegacySettingsGradleDeferredComponentsConfig
    extends BasicDeferredComponentsConfig {
  @override
  String get androidBuild => r'''
buildscript {
    ext.kotlin_version = '1.7.10'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
    configurations.classpath {
        resolutionStrategy.activateDependencyLocking()
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
    dependencyLocking {
        ignoredDependencies.add('io.flutter:*')
        lockFile = file("${rootProject.projectDir}/project-${project.name}.lockfile")
        if (!project.hasProperty('local-engine-repo')) {
          lockAllConfigurations()
        }
    }
}
tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
''';

  @override
  String get androidGradleProperties => r'''
org.gradle.jvmargs=-Xmx4G
android.useAndroidX=true
android.enableJetifier=true
''';

  @override
  String get androidSettings => r'''
include ':app'
def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()
def plugins = new Properties()
def pluginsFile = new File(flutterProjectRoot.toFile(), '.flutter-plugins')
if (pluginsFile.exists()) {
    pluginsFile.withReader('UTF-8') { reader -> plugins.load(reader) }
}
plugins.each { name, path ->
    def pluginDirectory = flutterProjectRoot.resolve(path).resolve('android').toFile()
    include ":$name"
    project(":$name").projectDir = pluginDirectory
}
  ''';

  @override
  String get appBuild => r'''
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withInputStream { stream ->
        localProperties.load(stream)
    }
}
def flutterRoot = localProperties.getProperty('flutter.sdk')
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}
apply plugin: 'com.android.application'
apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"
android {
    compileSdkVersion 33
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    defaultConfig {
        applicationId "com.yourcompany.flavors"
        minSdkVersion 21
        targetSdkVersion flutter.targetSdkVersion
        versionCode 1
        versionName "1.0"
    }
    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}
flutter {
    source '../..'
}
''';

  @override
  String get appManifest => r'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.yourcompany.flavors">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:name="${applicationName}"
        android:label="flavors">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
''';
}

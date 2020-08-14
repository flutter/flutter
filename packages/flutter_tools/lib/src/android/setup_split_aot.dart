// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/depfile.dart';
import '../build_system/targets/android.dart';
import '../build_system/targets/assets.dart';
import '../build_system/targets/common.dart';
import '../build_system/targets/ios.dart';
import '../build_system/targets/linux.dart';
import '../build_system/targets/macos.dart';
import '../build_system/targets/web.dart';
import '../build_system/targets/windows.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';

void setupBundleGradle(Environment env, BuildResult result) {
  print('setup Bundle Gradle');
  
  Directory androidDir = env.projectDir.childDirectory('android');

	List<FileSystemEntity> files = env.outputDir.listSync(recursive: true);
  while (files.length != 0) {
    if (files.last is File) {
    	File file = files.last;
      String subPath = file.path;
      if (!subPath.contains('manifest.json')) {
        files.removeLast();
        continue;
      }
      // Read gen_snapshot manifest
			String fileString = file.readAsStringSync();
			Map manifest = jsonDecode(fileString);

			// Setup android source directory
			print('FINDING MODULES ${file.path}');
			for (Map loadingUnitMetadata in manifest['loadingUnits']) {
				if (loadingUnitMetadata['id'] == 1) continue;
				String moduleName = 'module${loadingUnitMetadata['id'].toString()}';
				print('FOUND MODULE: $moduleName');
  			Directory moduleDir = androidDir.childDirectory(moduleName);
			  setupFiles(moduleDir, androidDir, moduleName, false, result, env);
			}
			break;
    }
    files.removeLast();
  }

}

void setupFiles(Directory moduleDir, Directory androidDir, String moduleName, bool isBase, BuildResult result, Environment env) {
  print('setupFiles');
  // File(path.join(rootDir, moduleSoPath)).copySync(path.join(modulePath, 'lib', 'libflutter.so'));

  File stringRes = androidDir.childDirectory('app').childDirectory('src').childDirectory('main').childDirectory('res').childDirectory('values').childFile('strings.xml');
  stringRes.createSync(recursive: true);
  stringRes.writeAsStringSync(
'''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="${moduleName}Name">$moduleName</string>
</resources>

''', flush: true);

  File androidManifest = moduleDir.childDirectory('src').childDirectory('main').childFile('AndroidManifest.xml');
  androidManifest.createSync(recursive: true);
//   androidManifest.writeAsStringSync(
// '''
// <manifest xmlns:dist="http://schemas.android.com/apk/distribution"
//     package="com.example.$moduleName"
//     split="$moduleName"
//     android:isFeatureSplit="${isBase ? false : true}">

//     <dist:module dist:instant="false"
//         dist:title="@string/$moduleName"
//         <dist:fusing dist:include="true" />
//     </dist:module>
//     <dist:delivery>
//         <dist:install-time>
//             <dist:removable value="false" />
//         </dist:install-time>
//         <dist:on-demand/>
//     </dist:delivery>
//     <application android:hasCode="${isBase ? 'true' : 'false'}"${isBase ? ' tools:replace="android:hasCode"' : ''}>
//     </application>
// </manifest>
// ''', flush: true);

  androidManifest.writeAsStringSync(
'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:dist="http://schemas.android.com/apk/distribution"
    package="com.example.$moduleName">

    <dist:$moduleName
        dist:instant="false"
        dist:title="@string/${moduleName}Name">
        <dist:delivery>
            <dist:on-demand />
        </dist:delivery>
        <dist:fusing dist:include="true" />
    </dist:$moduleName>
</manifest>
''', flush: true);

	// settings.gradle add ':module'
  File settingsGradle = androidDir.childFile('settings.gradle');
  File settingsGradleTemp = androidDir.childFile('settings.gradle.temp');
  if (settingsGradleTemp.existsSync()) settingsGradleTemp.deleteSync();
  List<String> lines = settingsGradle.readAsLinesSync();
  for (String line in lines) {
    if (line.length >= 7 && line.substring(0, 7) == 'include') {
      List<String> elements = line.substring(7).split(', ');
      bool moduleFound = false;
      for (int i = 1; i < elements.length; i++) {
        if (elements[i] == '\':$moduleName\'') {
          moduleFound = true;
          break;
        }
      }
      if (!moduleFound) {
        line += ', \':$moduleName\'';
      }
    }
    settingsGradleTemp.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  }
  settingsGradleTemp.copySync(settingsGradle.path);
  settingsGradleTemp.deleteSync();


  // app/build.gradle add dynamicFeatures = [':modules', ...]
  File appBuildGradle = androidDir.childDirectory('app').childFile('build.gradle');
  File appBuildGradleTemp = androidDir.childDirectory('app').childFile('build.gradle.temp');
  if (appBuildGradleTemp.existsSync()) appBuildGradleTemp.deleteSync();
  lines = appBuildGradle.readAsLinesSync();
  bool inAndroidBlock = false;
  int androidStartLineIndex = 0;
  int androidEndLineIndex = 0;
  for (int lineNum = 0; lineNum < lines.length; lineNum++) {
  	String line = lines[lineNum];
  	if (line.contains('android') && line.contains('{')) {
  		inAndroidBlock = true;
  		androidStartLineIndex = lineNum;
  	} else if (inAndroidBlock && line.length > 0 && line.substring(0, 1) == '}') {
  		inAndroidBlock = false;
  		androidEndLineIndex = lineNum;
  		appBuildGradleTemp.writeAsStringSync('    dynamicFeatures = [\':$moduleName\']\n', mode: FileMode.append, flush: true);
  	}

  	if (inAndroidBlock) {
  		if (line.contains('dynamicFeatures = [')) {
  			List<String> components = line.substring(line.lastIndexOf('dynamicFeatures = [\'') + 20, line.length - 2).split(', ');
  			if (!components.contains(':$moduleName')) {
  				components.add(':$moduleName');
  			}
  			line = '    dynamicFeatures = [\'${components.first}\'';
  			components.removeAt(0);
  			for (String component in components) {
  				line += ', \'$component\'';
  			}
  			line += ']';
  			inAndroidBlock = false;
  		}
  	}
    appBuildGradleTemp.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  }
  appBuildGradleTemp.copySync(appBuildGradle.path);
  appBuildGradleTemp.deleteSync();

  File moduleBuildGradle = moduleDir.childFile('build.gradle');
  moduleBuildGradle.createSync(recursive: true);
  moduleBuildGradle.writeAsStringSync(
'''
apply plugin: "com.android.dynamic-feature"

android {
    compileSdkVersion 28

    defaultConfig {
        minSdkVersion 16
        targetSdkVersion 28
        versionCode 1
        versionName "1.0"

        testInstrumentationRunner "android.support.test.runner.AndroidJUnitRunner"
    }
    compileOptions {
        sourceCompatibility 1.8
        targetCompatibility 1.8
    }
}

dependencies {
    implementation fileTree(dir: "libs", include: ["*.jar"])
    implementation project(":app")
    testImplementation 'junit:junit:4.12'
    androidTestImplementation 'com.android.support.test:runner:1.0.2'
    androidTestImplementation 'com.android.support.test.espresso:espresso-core:3.0.2'
    androidTestImplementation 'com.android.support:support-annotations:28.0.0'
}

''', flush: true);

  // MOVE TO ASSEMBLE/POSTBUILD
  Directory jniLibsDir = moduleDir.childDirectory('src').childDirectory('main').childDirectory('jniLibs');
  jniLibsDir.createSync(recursive: true);
  List<FileSystemEntity> files = env.outputDir.listSync(recursive: true);
  while (files.length != 0) {
    FileSystemEntity file = files.last;
    if (file is File) {
      String subPath = file.path;
      if (!subPath.contains('part.so')) {
        files.removeLast();
        continue;
      }
      subPath = subPath.substring(subPath.lastIndexOf('release/') + 8);
      print(jniLibsDir.childFile(subPath).path);
      jniLibsDir.childFile(subPath).createSync(recursive: true);
      (file as File).copySync(jniLibsDir.childFile(subPath).path);
    }
    files.removeLast();
  }
}

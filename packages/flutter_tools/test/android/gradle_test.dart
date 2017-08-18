// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:test/test.dart';


const String _kBuildDirectory = '/build/app/outputs';

void main() {
  group('gradle project', () {
    GradleProject projectFrom(String properties) => new GradleProject.fromAppProperties(properties);

    test('should extract build directory from app properties', () {
      final GradleProject project = projectFrom('''
someProperty: someValue
buildDir: /Users/some/apps/hello/build/app
someOtherProperty: someOtherValue
      ''');
      expect(project.apkDirectory, fs.path.normalize('/Users/some/apps/hello/build/app/outputs/apk'));
    });
    test('should extract default build variants from app properties', () {
      final GradleProject project = projectFrom('''
someProperty: someValue
assemble: task ':app:assemble'
assembleAndroidTest: task ':app:assembleAndroidTest'
assembleDebug: task ':app:assembleDebug'
assembleProfile: task ':app:assembleProfile'
assembleRelease: task ':app:assembleRelease'
buildDir: /Users/some/apps/hello/build/app
someOtherProperty: someOtherValue
      ''');
      expect(project.buildTypes, <String>['debug', 'profile', 'release']);
      expect(project.productFlavors, isEmpty);
    });
    test('should extract custom build variants from app properties', () {
      final GradleProject project = projectFrom('''
someProperty: someValue
assemble: task ':app:assemble'
assembleAndroidTest: task ':app:assembleAndroidTest'
assembleDebug: task ':app:assembleDebug'
assembleFree: task ':app:assembleFree'
assembleFreeAndroidTest: task ':app:assembleFreeAndroidTest'
assembleFreeDebug: task ':app:assembleFreeDebug'
assembleFreeProfile: task ':app:assembleFreeProfile'
assembleFreeRelease: task ':app:assembleFreeRelease'
assemblePaid: task ':app:assemblePaid'
assemblePaidAndroidTest: task ':app:assemblePaidAndroidTest'
assemblePaidDebug: task ':app:assemblePaidDebug'
assemblePaidProfile: task ':app:assemblePaidProfile'
assemblePaidRelease: task ':app:assemblePaidRelease'
assembleProfile: task ':app:assembleProfile'
assembleRelease: task ':app:assembleRelease'
buildDir: /Users/some/apps/hello/build/app
someOtherProperty: someOtherValue
      ''');
      expect(project.buildTypes, <String>['debug', 'profile', 'release']);
      expect(project.productFlavors, <String>['free', 'paid']);
    });
    test('should provide apk file name for default build types', () {
      final GradleProject project = new GradleProject(<String>['debug', 'profile', 'release'], <String>[], '/some/dir');
      expect(project.apkFileFor(BuildInfo.debug), 'app-debug.apk');
      expect(project.apkFileFor(BuildInfo.profile), 'app-profile.apk');
      expect(project.apkFileFor(BuildInfo.release), 'app-release.apk');
      expect(project.apkFileFor(const BuildInfo(BuildMode.release, 'unknown')), isNull);
    });
    test('should provide apk file name for flavored build types', () {
      final GradleProject project = new GradleProject(<String>['debug', 'profile', 'release'], <String>['free', 'paid'], '/some/dir');
      expect(project.apkFileFor(const BuildInfo(BuildMode.debug, 'free')), 'app-free-debug.apk');
      expect(project.apkFileFor(const BuildInfo(BuildMode.release, 'paid')), 'app-paid-release.apk');
      expect(project.apkFileFor(const BuildInfo(BuildMode.release, 'unknown')), isNull);
    });
    test('should provide assemble task name for default build types', () {
      final GradleProject project = new GradleProject(<String>['debug', 'profile', 'release'], <String>[], '/some/dir');
      expect(project.assembleTaskFor(BuildInfo.debug), 'assembleDebug');
      expect(project.assembleTaskFor(BuildInfo.profile), 'assembleProfile');
      expect(project.assembleTaskFor(BuildInfo.release), 'assembleRelease');
      expect(project.assembleTaskFor(const BuildInfo(BuildMode.release, 'unknown')), isNull);
    });
    test('should provide assemble task name for flavored build types', () {
      final GradleProject project = new GradleProject(<String>['debug', 'profile', 'release'], <String>['free', 'paid'], '/some/dir');
      expect(project.assembleTaskFor(const BuildInfo(BuildMode.debug, 'free')), 'assembleFreeDebug');
      expect(project.assembleTaskFor(const BuildInfo(BuildMode.release, 'paid')), 'assemblePaidRelease');
      expect(project.assembleTaskFor(const BuildInfo(BuildMode.release, 'unknown')), isNull);
    });
  });
}

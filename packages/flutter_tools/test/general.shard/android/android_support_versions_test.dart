// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_support_versions.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:test/test.dart';

void main() {
  late FileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
  });

  test('AndroidSupportVersions parses JSON correctly', () {
    final File file = fileSystem.file('android_support_versions.json');
    file.writeAsStringSync('''
{
  "gradle": {
    "warn": "9.1.0",
    "error": "8.14.0"
  },
  "java": {
    "warn": "17",
    "error": "17"
  },
  "agp": {
    "warn": "9.0.1",
    "error": "8.11.1"
  },
  "kgp": {
    "warn": "2.3.20",
    "error": "2.2.20"
  },
  "minSdkVersion": {
    "warn": 24,
    "error": 23
  },
  "maxKnownVersions": {
    "gradle": "9.3.1",
    "kgp": "2.4.0",
    "agp": "9.2",
    "agpWithKotlin": "9.1.0"
  },
  "oldestConsideredVersions": {
    "gradle": "4.10.1",
    "agp": "3.3.0",
    "kgp": "1.6.20",
    "javaAgp": "4.2",
    "java": "1.8",
    "javaGradle": "2.0"
  },
  "oneMajorVersionHigherJavaVersion": "26",
  "gradleAgpCompat": {
    "comment": "Gradle-AGP compatibility matrix",
    "sourceUrls": [
      "https://developer.android.com/studio/releases/gradle-plugin#updating-gradle"
    ],
    "rules": [
      { "agpMin": "9.1.0", "agpMax": "9.1.99", "gradleMin": "9.3.1", "inclusiveMaxAgp": true }
    ]
  },
  "javaGradleCompat": {
    "comment": "Java-Gradle compatibility matrix",
    "sourceUrls": [
      "https://docs.gradle.org/current/userguide/compatibility.html#java"
    ],
    "rules": [
      { "javaMin": "25", "javaMax": "26", "gradleMin": "9.1.0", "gradleMax": "9.2.0" }
    ]
  },
  "javaAgpCompat": {
    "comment": "Java-AGP compatibility matrix",
    "sourceUrls": [
      "https://developer.android.com/studio/releases/gradle-plugin#compatibility"
    ],
    "rules": [
      { "javaMin": "17", "javaDefault": "17", "agpMin": "8.0", "agpMax": "9.2" }
    ]
  },
  "kgpGradleCompat": {
    "comment": "Kotlin-Gradle compatibility matrix",
    "sourceUrls": [
      "https://kotlinlang.org/docs/gradle.html#compatibility"
    ],
    "rules": [
      { "kgpMin": "2.4.0", "kgpMax": "2.4.29", "gradleMin": "8.5", "gradleMax": "9.5.99", "inclusiveMaxKgp": false, "inclusiveMaxGradle": false }
    ]
  },
  "agpKgpCompat": {
    "comment": "AGP-Kotlin compatibility matrix",
    "sourceUrls": [
      "https://kotlinlang.org/docs/kmp-compatibility-guide.html"
    ],
    "rules": [
      { "kgpMin": "2.4.0", "kgpMax": "2.4.29", "agpMin": "8.2.2", "agpMax": "9.2.99", "inclusiveMaxKgp": false, "inclusiveMaxAgp": false }
    ]
  },
  "gradleVersionForAgp": {
    "comment": "Gradle version requirement for AGP",
    "sourceUrls": [
      "https://developer.android.com/studio/releases/gradle-plugin#updating-gradle"
    ],
    "rules": [
      { "agpMin": "1.0.0", "agpMax": "1.1.3", "minRequiredGradle": "2.3" }
    ]
  }
}
''');

    final versions = AndroidSupportVersions.load(fileSystem, file.path);

    expect(versions.gradle.warn, '9.1.0');
    expect(versions.gradle.error, '8.14.0');
    expect(versions.java.warn, '17');
    expect(versions.java.error, '17');
    expect(versions.agp.warn, '9.0.1');
    expect(versions.agp.error, '8.11.1');
    expect(versions.kgp.warn, '2.3.20');
    expect(versions.kgp.error, '2.2.20');
    expect(versions.minSdkVersion.warn, 24);
    expect(versions.minSdkVersion.error, 23);

    expect(versions.maxKnownVersions.gradle, '9.3.1');
    expect(versions.maxKnownVersions.kgp, '2.4.0');
    expect(versions.maxKnownVersions.agp, '9.2');
    expect(versions.maxKnownVersions.agpWithKotlin, '9.1.0');

    expect(versions.oldestConsideredVersions.gradle, '4.10.1');
    expect(versions.oldestConsideredVersions.agp, '3.3.0');
    expect(versions.oldestConsideredVersions.kgp, '1.6.20');
    expect(versions.oldestConsideredVersions.javaAgp, '4.2');
    expect(versions.oldestConsideredVersions.java, '1.8');
    expect(versions.oldestConsideredVersions.javaGradle, '2.0');

    expect(versions.oneMajorVersionHigherJavaVersion, '26');

    expect(versions.gradleAgpCompat.comment, 'Gradle-AGP compatibility matrix');
    expect(
      versions.gradleAgpCompat.sourceUrls.first,
      'https://developer.android.com/studio/releases/gradle-plugin#updating-gradle',
    );
    expect(versions.gradleAgpCompat.rules.length, 1);
    expect(versions.gradleAgpCompat.rules.first.agpMin, '9.1.0');
    expect(versions.gradleAgpCompat.rules.first.agpMax, '9.1.99');
    expect(versions.gradleAgpCompat.rules.first.gradleMin, '9.3.1');
    expect(versions.gradleAgpCompat.rules.first.inclusiveMaxAgp, true);

    expect(versions.javaGradleCompat.comment, 'Java-Gradle compatibility matrix');
    expect(
      versions.javaGradleCompat.sourceUrls.first,
      'https://docs.gradle.org/current/userguide/compatibility.html#java',
    );
    expect(versions.javaGradleCompat.rules.length, 1);
    expect(versions.javaGradleCompat.rules.first.javaMin, '25');
    expect(versions.javaGradleCompat.rules.first.javaMax, '26');
    expect(versions.javaGradleCompat.rules.first.gradleMin, '9.1.0');
    expect(versions.javaGradleCompat.rules.first.gradleMax, '9.2.0');

    expect(versions.javaAgpCompat.comment, 'Java-AGP compatibility matrix');
    expect(
      versions.javaAgpCompat.sourceUrls.first,
      'https://developer.android.com/studio/releases/gradle-plugin#compatibility',
    );
    expect(versions.javaAgpCompat.rules.length, 1);
    expect(versions.javaAgpCompat.rules.first.javaMin, '17');
    expect(versions.javaAgpCompat.rules.first.javaDefault, '17');
    expect(versions.javaAgpCompat.rules.first.agpMin, '8.0');
    expect(versions.javaAgpCompat.rules.first.agpMax, '9.2');

    expect(versions.kgpGradleCompat.comment, 'Kotlin-Gradle compatibility matrix');
    expect(
      versions.kgpGradleCompat.sourceUrls.first,
      'https://kotlinlang.org/docs/gradle.html#compatibility',
    );
    expect(versions.kgpGradleCompat.rules.length, 1);
    expect(versions.kgpGradleCompat.rules.first.kgpMin, '2.4.0');
    expect(versions.kgpGradleCompat.rules.first.kgpMax, '2.4.29');
    expect(versions.kgpGradleCompat.rules.first.gradleMin, '8.5');
    expect(versions.kgpGradleCompat.rules.first.gradleMax, '9.5.99');
    expect(versions.kgpGradleCompat.rules.first.inclusiveMaxKgp, false);
    expect(versions.kgpGradleCompat.rules.first.inclusiveMaxGradle, false);

    expect(versions.agpKgpCompat.comment, 'AGP-Kotlin compatibility matrix');
    expect(
      versions.agpKgpCompat.sourceUrls.first,
      'https://kotlinlang.org/docs/kmp-compatibility-guide.html',
    );
    expect(versions.agpKgpCompat.rules.length, 1);
    expect(versions.agpKgpCompat.rules.first.kgpMin, '2.4.0');
    expect(versions.agpKgpCompat.rules.first.kgpMax, '2.4.29');
    expect(versions.agpKgpCompat.rules.first.agpMin, '8.2.2');
    expect(versions.agpKgpCompat.rules.first.agpMax, '9.2.99');
    expect(versions.agpKgpCompat.rules.first.inclusiveMaxKgp, false);
    expect(versions.agpKgpCompat.rules.first.inclusiveMaxAgp, false);

    expect(versions.gradleVersionForAgp.comment, 'Gradle version requirement for AGP');
    expect(
      versions.gradleVersionForAgp.sourceUrls.first,
      'https://developer.android.com/studio/releases/gradle-plugin#updating-gradle',
    );
    expect(versions.gradleVersionForAgp.rules.length, 1);
    expect(versions.gradleVersionForAgp.rules.first.agpMin, '1.0.0');
    expect(versions.gradleVersionForAgp.rules.first.agpMax, '1.1.3');
    expect(versions.gradleVersionForAgp.rules.first.minRequiredGradle, '2.3');
  });
}

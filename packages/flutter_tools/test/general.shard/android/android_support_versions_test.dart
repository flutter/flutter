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
  "gradleAgpCompat": [
    { "agpMin": "9.1.0", "agpMax": "9.1.99", "gradleMin": "9.3.1", "inclusiveMaxAgp": true }
  ],
  "javaGradleCompat": [
    { "javaMin": "25", "javaMax": "26", "gradleMin": "9.1.0", "gradleMax": "9.2.0" }
  ],
  "javaAgpCompat": [
    { "javaMin": "17", "javaDefault": "17", "agpMin": "8.0", "agpMax": "9.2" }
  ],
  "kgpGradleCompat": [
    { "kgpMin": "2.4.0", "kgpMax": "2.4.29", "gradleMin": "8.5", "gradleMax": "9.5.99", "inclusiveMaxKgp": false, "inclusiveMaxGradle": false }
  ],
  "agpKgpCompat": [
    { "kgpMin": "2.4.0", "kgpMax": "2.4.29", "agpMin": "8.2.2", "agpMax": "9.2.99", "inclusiveMaxKgp": false, "inclusiveMaxAgp": false }
  ],
  "gradleVersionForAgp": [
    { "agpMin": "1.0.0", "agpMax": "1.1.3", "minRequiredGradle": "2.3" }
  ]
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

    expect(versions.gradleAgpCompat.length, 1);
    expect(versions.gradleAgpCompat.first.agpMin, '9.1.0');
    expect(versions.gradleAgpCompat.first.agpMax, '9.1.99');
    expect(versions.gradleAgpCompat.first.gradleMin, '9.3.1');
    expect(versions.gradleAgpCompat.first.inclusiveMaxAgp, true);

    expect(versions.javaGradleCompat.length, 1);
    expect(versions.javaGradleCompat.first.javaMin, '25');
    expect(versions.javaGradleCompat.first.javaMax, '26');
    expect(versions.javaGradleCompat.first.gradleMin, '9.1.0');
    expect(versions.javaGradleCompat.first.gradleMax, '9.2.0');

    expect(versions.javaAgpCompat.length, 1);
    expect(versions.javaAgpCompat.first.javaMin, '17');
    expect(versions.javaAgpCompat.first.javaDefault, '17');
    expect(versions.javaAgpCompat.first.agpMin, '8.0');
    expect(versions.javaAgpCompat.first.agpMax, '9.2');

    expect(versions.kgpGradleCompat.length, 1);
    expect(versions.kgpGradleCompat.first.kgpMin, '2.4.0');
    expect(versions.kgpGradleCompat.first.kgpMax, '2.4.29');
    expect(versions.kgpGradleCompat.first.gradleMin, '8.5');
    expect(versions.kgpGradleCompat.first.gradleMax, '9.5.99');
    expect(versions.kgpGradleCompat.first.inclusiveMaxKgp, false);
    expect(versions.kgpGradleCompat.first.inclusiveMaxGradle, false);

    expect(versions.agpKgpCompat.length, 1);
    expect(versions.agpKgpCompat.first.kgpMin, '2.4.0');
    expect(versions.agpKgpCompat.first.kgpMax, '2.4.29');
    expect(versions.agpKgpCompat.first.agpMin, '8.2.2');
    expect(versions.agpKgpCompat.first.agpMax, '9.2.99');
    expect(versions.agpKgpCompat.first.inclusiveMaxKgp, false);
    expect(versions.agpKgpCompat.first.inclusiveMaxAgp, false);

    expect(versions.gradleVersionForAgp.length, 1);
    expect(versions.gradleVersionForAgp.first.agpMin, '1.0.0');
    expect(versions.gradleVersionForAgp.first.agpMax, '1.1.3');
    expect(versions.gradleVersionForAgp.first.minRequiredGradle, '2.3');
  });
}

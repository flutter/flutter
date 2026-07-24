// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  testWithoutContext('Android Gradle settings templates canonicalize flutter.sdk', () {
    const expectedIncludeBuild =
        r'includeBuild("${file(flutterSdkPath).canonicalPath}/packages/flutter_tools/gradle")';
    const templatePaths = <String>[
      'templates/app/android.tmpl/settings.gradle.kts.tmpl',
      'templates/module/android/host_app_ephemeral/settings.gradle.tmpl',
      'templates/module/android/library_new_embedding/include_flutter.groovy.copy.tmpl',
    ];

    for (final templatePath in templatePaths) {
      expect(fileSystem.file(templatePath).readAsStringSync(), contains(expectedIncludeBuild));
    }
  });
}

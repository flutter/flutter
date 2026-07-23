// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import '../src/common.dart';
import 'test_utils.dart';

void main() {
  testWithoutContext(
    'Gradle templates do not use legacy allprojects repository declaration and settings.gradle uses dependencyResolutionManagement',
    () {
      final String flutterRoot = getFlutterRoot();

      final buildGradleTemplates = <String>[
        'packages/flutter_tools/templates/app/android-java.tmpl/build.gradle.kts.tmpl',
        'packages/flutter_tools/templates/app/android-kotlin.tmpl/build.gradle.kts.tmpl',
        'packages/flutter_tools/templates/module/android/gradle/build.gradle.tmpl',
        'packages/flutter_tools/templates/plugin/android-java.tmpl/build.gradle.kts.tmpl',
        'packages/flutter_tools/templates/plugin/android-kotlin.tmpl/build.gradle.kts.tmpl',
        'packages/flutter_tools/templates/plugin_ffi/android.tmpl/build.gradle.tmpl',
      ];

      final settingsGradleTemplates = <String>[
        'packages/flutter_tools/templates/app/android.tmpl/settings.gradle.kts.tmpl',
        'packages/flutter_tools/templates/module/android/gradle/settings.gradle.tmpl',
        'packages/flutter_tools/templates/module/android/host_app_ephemeral/settings.gradle.tmpl',
        'packages/flutter_tools/templates/module/android/host_app_editable/settings.gradle.copy.tmpl',
        'packages/flutter_tools/templates/module/android/library_new_embedding/settings.gradle.copy.tmpl',
        'packages/flutter_tools/templates/plugin/android.tmpl/settings.gradle.kts.tmpl',
      ];

      for (final buildGradlePath in buildGradleTemplates) {
        final File buildGradleFile = fileSystem.file(
          fileSystem.path.join(flutterRoot, buildGradlePath),
        );
        expect(buildGradleFile.existsSync(), isTrue, reason: '$buildGradlePath does not exist');

        final String buildGradleContent = buildGradleFile.readAsStringSync();

        // Ensure build.gradle templates do not contain legacy `allprojects` block
        expect(
          buildGradleContent.contains('allprojects'),
          isFalse,
          reason:
              '$buildGradlePath uses legacy "allprojects" block for declaring repositories. '
              'Please remove the "allprojects" repository block from the build.gradle template.',
        );
      }

      for (final settingsGradlePath in settingsGradleTemplates) {
        final File settingsGradleFile = fileSystem.file(
          fileSystem.path.join(flutterRoot, settingsGradlePath),
        );
        expect(
          settingsGradleFile.existsSync(),
          isTrue,
          reason: '$settingsGradlePath does not exist',
        );

        final String settingsGradleContent = settingsGradleFile.readAsStringSync();

        // Ensure settings.gradle templates contain modern `dependencyResolutionManagement` block
        expect(
          settingsGradleContent.contains('dependencyResolutionManagement'),
          isTrue,
          reason:
              '$settingsGradlePath is missing the modern "dependencyResolutionManagement" block '
              'for centralized repository declaration.',
        );
      }
    },
  );
}

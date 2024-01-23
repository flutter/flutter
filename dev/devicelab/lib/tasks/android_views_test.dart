// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';


/// Tests the following Android lifecycles: Activity#onStop(), Activity#onResume(), Activity#onPause(),
/// and Activity#onDestroy() from Dart perspective in debug, profile, and release modes.
TaskFunction androidViewsTest({
  Map<String, String>? environment,
}){
    return () async {
        //return TaskResult.failure('aaa');
        section('Build APK');
        await flutter(
          'configure android project',
          options: <String>[
            'build',
            'apk',
            '--config-only',
          ],
          environment: environment,
        );

        // Any gradle command downloads gradle if not already present in the cache.
        // ./gradlew dependencies downloads any gradle defined dependencies to the cache.
        // https://docs.gradle.org/current/userguide/viewing_debugging_dependencies.html
        // Downloading gradle and downloading dependencies are a common source of flakes
        // and moving those to an infra step that can be retried shifts the blame
        // individual tests to the infra itself.
        /////// android_path = views_test_dir.join('android')
        /////// with api.context(env=env, env_prefixes=env_prefixes, cwd=android_path):
        section('Download android dependencies');
        final int exitCode = await exec(
          'gradlew',
           <String>['-q', 'dependencies'],
        );
        if (exitCode != 0) {
          return TaskResult.failure('Failed to download dependencies');
        }
        await flutter(
          'Android Views Integration Tests',
          options: <String>[
              'drive', '--browser-name=android-chrome',
              '--android-emulator', '--no-start-paused',
              '--purge-persistent-cache', '--device-timeout=30',
          ],
          environment: environment,
        );
        return TaskResult.success(null);
      };
}

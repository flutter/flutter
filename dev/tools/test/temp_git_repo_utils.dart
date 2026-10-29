// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';

/// Environment variables that turn off Git's automatic maintenance and garbage
/// collection for every `git` process that receives them.
///
/// Commands like `git commit` and `git fetch` can start
/// `git maintenance run --auto` as a detached background process (the default
/// in recent versions of Git). That process may still be writing to `.git`
/// after the command returns, so a test that deletes its temporary repository
/// right away can fail with "Directory not empty".
/// See https://github.com/flutter/flutter/issues/194368.
///
/// Passing these through the environment, rather than with `git config`,
/// also covers repositories and `git` commands created by the scripts under
/// test. Requires Git 2.31 or newer.
const Map<String, String> kDisableGitAutoMaintenanceEnvironment = <String, String>{
  'GIT_CONFIG_COUNT': '3',
  'GIT_CONFIG_KEY_0': 'maintenance.auto',
  'GIT_CONFIG_VALUE_0': 'false',
  'GIT_CONFIG_KEY_1': 'gc.auto',
  'GIT_CONFIG_VALUE_1': '0',
  'GIT_CONFIG_KEY_2': 'gc.autoDetach',
  'GIT_CONFIG_VALUE_2': 'false',
};

/// Recursively deletes [directory], retrying briefly if the deletion fails.
///
/// Deleting a temporary Git repository can fail transiently if another process
/// is still writing to it, or on Windows if a file handle has not been released
/// yet. After the last attempt, the failure is printed instead of thrown,
/// because failing to clean up a temporary directory is not a test failure.
///
/// Returns whether [directory] was deleted.
Future<bool> deleteTempDirectory(Directory directory, {int attempts = 5}) async {
  for (var attempt = 1; ; attempt++) {
    try {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
      return true;
    } on FileSystemException catch (error) {
      if (attempt >= attempts) {
        print('Failed to delete ${directory.path}: $error');
        return false;
      }
      await Future<void>.delayed(Duration(milliseconds: 100 * attempt));
    }
  }
}

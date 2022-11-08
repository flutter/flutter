// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/logger.dart';

/// The name of the test configuration file that will be discovered by the
/// test harness if it exists in the project directory hierarchy.
const String _kTestConfigFileName = 'flutter_test_config.dart';

/// The name of the web test configuration file that will be discovered by the
/// test harness if it exists in the project directory hierarchy.
const String _kWebTestConfigFileName = 'flutter_web_test_config.dart';

/// The name of the file that signals the root of the project and that will
/// cause the test harness to stop scanning for configuration files.
const String _kProjectRootSentinel = 'pubspec.yaml';

/// Find the `flutter_test_config.dart` file for a specific test file.
File? findTestConfigFile(File testFile, Logger logger) {
  return _findConfigFile(testFile, _kTestConfigFileName, logger);
}

/// Find the `flutter_web_test_config.dart` file for a specific test file.
File? findWebTestConfigFile(File testFile, Logger logger) {
  return _findConfigFile(testFile, _kWebTestConfigFileName, logger);
}

File? _findConfigFile(File testFile, String configFileName, Logger logger) {
  File? testConfigFile;
  Directory directory = testFile.parent;
  while (directory.path != directory.parent.path) {
    final File configFile = directory.childFile(configFileName);
    if (configFile.existsSync()) {
      logger.printTrace('Discovered $configFileName in ${directory.path}');
      testConfigFile = configFile;
      break;
    }
    if (directory.childFile(_kProjectRootSentinel).existsSync()) {
      logger.printTrace('Stopping scan for $configFileName; '
          'found project root at ${directory.path}');
      break;
    }
    directory = directory.parent;
  }
  return testConfigFile;
}

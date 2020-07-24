// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6

import 'dart:io' as io;
import 'package:path/path.dart' as pathlib;

import 'chrome_installer.dart';
import 'driver_manager.dart';
import 'environment.dart';
import 'exceptions.dart';
import 'common.dart';
import 'utils.dart';

const String _unsupportedConfigurationWarning = 'WARNING: integration tests '
    'are only supported on Chrome, Firefox and on Safari (running on macOS)';

class IntegrationTestsManager {
  final String _browser;

  final bool _useSystemFlutter;

  final DriverManager _driverManager;

  IntegrationTestsManager(this._browser, this._useSystemFlutter)
      : _driverManager = DriverManager.chooseDriver(_browser);

  Future<bool> runTests() async {
    if (validateIfTestsShouldRun()) {
      await _driverManager.prepareDriver();
      return await _runTests();
    } else {
      return false;
    }
  }

  Future<void> _runPubGet(String workingDirectory) async {
    if (!_useSystemFlutter) {
      await _cloneFlutterRepo();
      await _enableWeb(workingDirectory);
    }
    await runFlutter(workingDirectory, <String>['pub', 'get'],
        useSystemFlutter: _useSystemFlutter);
  }

  /// Clone flutter repository, use the youngest commit older than the engine
  /// commit.
  ///
  /// Use engine/src/flutter/.dart_tools to clone the Flutter repo.
  /// TODO(nurhan): Use git pull instead if repo exists.
  Future<void> _cloneFlutterRepo() async {
    // Delete directory if exists.
    if (environment.engineDartToolDir.existsSync()) {
      environment.engineDartToolDir.deleteSync(recursive: true);
    }
    environment.engineDartToolDir.createSync();

    final int exitCode = await runProcess(
      environment.cloneFlutterScript.path,
      <String>[
        environment.engineDartToolDir.path,
      ],
      workingDirectory: environment.webUiRootDir.path,
    );

    if (exitCode != 0) {
      throw ToolException('ERROR: Failed to clone flutter repo. Exited with '
          'exit code $exitCode');
    }
  }

  Future<void> _enableWeb(String workingDirectory) async {
    await runFlutter(workingDirectory, <String>['config', '--enable-web'],
        useSystemFlutter: _useSystemFlutter);
  }

  /// Runs all the web tests under e2e_tests/web.
  Future<bool> _runTests() async {
    // Only list the files under e2e_tests/web.
    final List<io.FileSystemEntity> entities =
        environment.integrationTestsDir.listSync(followLinks: false);

    bool allTestsPassed = true;
    for (io.FileSystemEntity e in entities) {
      // The tests should be under this directories.
      if (e is io.Directory) {
        allTestsPassed = allTestsPassed && await _validateAndRunTests(e);
      }
    }
    return allTestsPassed;
  }

  /// Run tests in a single directory under: e2e_tests/web.
  ///
  /// Run `flutter pub get` as the first step.
  ///
  /// Validate the directory before running the tests. Each directory is
  /// expected to be a test project which includes a `pubspec.yaml` file
  /// and a `test_driver` directory.
  Future<bool> _validateAndRunTests(io.Directory directory) async {
    _validateTestDirectory(directory);
    await _runPubGet(directory.path);
    final bool testResults = await _runTestsInDirectory(directory);
    return testResults;
  }

  Future<bool> _runTestsInDirectory(io.Directory directory) async {
    final io.Directory testDirectory =
        io.Directory(pathlib.join(directory.path, 'test_driver'));
    final List<io.File> entities = testDirectory
        .listSync(followLinks: false)
        .whereType<io.File>()
        .toList();

    final List<String> e2eTestsToRun = <String>[];
    final List<String> blockedTests =
        blockedTestsListsMap[getBlockedTestsListMapKey(_browser)] ?? <String>[];

    // The following loops over the contents of the directory and saves an
    // expected driver file name for each e2e test assuming any dart file
    // not ending with `_test.dart` is an e2e test.
    // Other files are not considered since developers can add files such as
    // README.
    for (io.File f in entities) {
      final String basename = pathlib.basename(f.path);
      if (!basename.contains('_test.dart') && basename.endsWith('.dart')) {
        // Do not add the basename if it is in the `blockedTests`.
        if (!blockedTests.contains(basename)) {
          e2eTestsToRun.add(basename);
        } else {
          print('INFO: Test $basename is skipped since it is blocked for '
              '${getBlockedTestsListMapKey(_browser)}');
        }
      }
    }

    print(
        'INFO: In project ${directory} ${e2eTestsToRun.length} tests to run.');

    int numberOfPassedTests = 0;
    int numberOfFailedTests = 0;
    for (String fileName in e2eTestsToRun) {
      final bool testResults =
          await _runTestsInProfileMode(directory, fileName);
      if (testResults) {
        numberOfPassedTests++;
      } else {
        numberOfFailedTests++;
      }
    }
    final int numberOfTestsRun = numberOfPassedTests + numberOfFailedTests;

    print('INFO: ${numberOfTestsRun} tests run. ${numberOfPassedTests} passed '
        'and ${numberOfFailedTests} failed.');
    return numberOfFailedTests == 0;
  }

  Future<bool> _runTestsInProfileMode(
      io.Directory directory, String testName) async {
    final String executable =
        _useSystemFlutter ? 'flutter' : environment.flutterCommand.path;
    final IntegrationArguments arguments =
        IntegrationArguments.fromBrowser(_browser);
    final int exitCode = await runProcess(
      executable,
      arguments.getTestArguments(testName, 'profile'),
      workingDirectory: directory.path,
    );

    if (exitCode != 0) {
      io.stderr
          .writeln('ERROR: Failed to run test. Exited with exit code $exitCode'
              '. To run $testName locally use the following command:'
              '\n\n${arguments.getCommandToRun(testName, 'profile')}');
      return false;
    } else {
      return true;
    }
  }

  /// Validate the directory has a `pubspec.yaml` file and a `test_driver`
  /// directory.
  ///
  /// Also check the validity of files under `test_driver` directory calling
  /// [_checkE2ETestsValidity] method.
  void _validateTestDirectory(io.Directory directory) {
    final List<io.FileSystemEntity> entities =
        directory.listSync(followLinks: false);

    // Whether the project has the pubspec.yaml file.
    bool pubSpecFound = false;
    // The test directory 'test_driver'.
    io.Directory testDirectory;

    for (io.FileSystemEntity e in entities) {
      // The tests should be under this directories.
      final String baseName = pathlib.basename(e.path);
      if (e is io.Directory && baseName == 'test_driver') {
        testDirectory = e;
      }
      if (e is io.File && baseName == 'pubspec.yaml') {
        pubSpecFound = true;
      }
    }
    if (!pubSpecFound) {
      throw StateError('ERROR: pubspec.yaml file not found in the test project '
          'in the directory ${directory.path}.');
    }
    if (testDirectory == null) {
      throw StateError(
          'ERROR: test_driver folder not found in the test project.'
          'in the directory ${directory.path}.');
    } else {
      _checkE2ETestsValidity(testDirectory);
    }
  }

  /// Checks if each e2e test file in the directory has a driver test
  /// file to run it.
  ///
  /// Prints informative message to the developer if an error has found.
  /// For each e2e test which has name {name}.dart there will be a driver
  /// file which drives it. The driver file should be named:
  /// {name}_test.dart
  void _checkE2ETestsValidity(io.Directory testDirectory) {
    final Iterable<io.Directory> directories =
        testDirectory.listSync(followLinks: false).whereType<io.Directory>();

    if (directories.length > 0) {
      throw StateError('${testDirectory.path} directory should not contain '
          'any sub-directories');
    }

    final Iterable<io.File> entities =
        testDirectory.listSync(followLinks: false).whereType<io.File>();

    final Set<String> expectedDriverFileNames = Set<String>();
    final Set<String> foundDriverFileNames = Set<String>();
    int numberOfTests = 0;

    // The following loops over the contents of the directory and saves an
    // expected driver file name for each e2e test assuming any file
    // not ending with `_test.dart` is an e2e test.
    for (io.File f in entities) {
      final String basename = pathlib.basename(f.path);
      if (basename.contains('_test.dart')) {
        // First remove this from expectedSet if not there add to the foundSet.
        if (!expectedDriverFileNames.remove(basename)) {
          foundDriverFileNames.add(basename);
        }
      } else if (basename.contains('.dart')) {
        // Only run on dart files.
        final String e2efileName = pathlib.basenameWithoutExtension(f.path);
        final String expectedDriverName = '${e2efileName}_test.dart';
        numberOfTests++;
        // First remove this from foundSet if not there add to the expectedSet.
        if (!foundDriverFileNames.remove(expectedDriverName)) {
          expectedDriverFileNames.add(expectedDriverName);
        }
      }
    }

    if (numberOfTests == 0) {
      throw StateError(
          'WARNING: No tests to run in this directory ${testDirectory.path}');
    }

    // TODO(nurhan): In order to reduce the work required from team members,
    // remove the need for driver file, by using the same template file.
    // Some driver files are missing.
    if (expectedDriverFileNames.length > 0) {
      for (String expectedDriverName in expectedDriverFileNames) {
        print('ERROR: Test driver file named has ${expectedDriverName} '
            'not found under directory ${testDirectory.path}. Stopping the '
            'integration tests. Please add ${expectedDriverName}. Check to '
            'README file on more details on how to setup integration tests.');
      }
      throw StateError('Error in test files. Check the logs for '
          'further instructions');
    }
  }

  /// Validate the given `browser`, `platform` combination is suitable for
  /// integration tests to run.
  bool validateIfTestsShouldRun() {
    // Chrome tests should run at all Platforms (Linux, macOS, Windows).
    // They can also run successfully on CI and local.
    if (_browser == 'chrome') {
      return true;
    } else if (_browser == 'firefox' &&
        (io.Platform.isLinux || io.Platform.isMacOS)) {
      return true;
    } else if (_browser == 'safari' && io.Platform.isMacOS && !isLuci) {
      return true;
    } else {
      io.stderr.writeln(_unsupportedConfigurationWarning);
      return false;
    }
  }
}

/// Interface for collecting arguments to give `flutter drive` to run the
/// integration tests.
abstract class IntegrationArguments {
  IntegrationArguments();

  factory IntegrationArguments.fromBrowser(String browser) {
    if (browser == 'chrome') {
      return ChromeIntegrationArguments();
    } else if (browser == 'firefox') {
      return FirefoxIntegrationArguments();
    } else if (browser == 'safari' && io.Platform.isMacOS) {
      return SafariIntegrationArguments();
    } else {
      throw StateError(_unsupportedConfigurationWarning);
    }
  }

  List<String> getTestArguments(String testName, String mode);

  String getCommandToRun(String testName, String mode);
}

/// Arguments to give `flutter drive` to run the integration tests on Chrome.
class ChromeIntegrationArguments extends IntegrationArguments {
  List<String> getTestArguments(String testName, String mode) {
    return <String>[
      'drive',
      '--target=test_driver/${testName}',
      '-d',
      'web-server',
      '--$mode',
      '--browser-name=chrome',
      if (isLuci) '--chrome-binary=${preinstalledChromeExecutable()}',
      if (isLuci) '--headless',
      '--local-engine=host_debug_unopt',
    ];
  }

  String getCommandToRun(String testName, String mode) {
    String statementToRun = 'flutter drive '
        '--target=test_driver/${testName} -d web-server --profile '
        '--browser-name=chrome --local-engine=host_debug_unopt';
    if (isLuci) {
      statementToRun = '$statementToRun --chrome-binary='
          '${preinstalledChromeExecutable()}';
    }
    return statementToRun;
  }
}

/// Arguments to give `flutter drive` to run the integration tests on Firefox.
class FirefoxIntegrationArguments extends IntegrationArguments {
  List<String> getTestArguments(String testName, String mode) {
    return <String>[
      'drive',
      '--target=test_driver/${testName}',
      '-d',
      'web-server',
      '--$mode',
      '--browser-name=firefox',
      '--headless',
      '--local-engine=host_debug_unopt',
    ];
  }

  String getCommandToRun(String testName, String mode) =>
      'flutter ${getTestArguments(testName, mode).join(' ')}';
}

/// Arguments to give `flutter drive` to run the integration tests on Safari.
class SafariIntegrationArguments extends IntegrationArguments {
  SafariIntegrationArguments();

  List<String> getTestArguments(String testName, String mode) {
    return <String>[
      'drive',
      '--target=test_driver/${testName}',
      '-d',
      'web-server',
      '--$mode',
      '--browser-name=safari',
      '--local-engine=host_debug_unopt',
    ];
  }

  String getCommandToRun(String testName, String mode) =>
      'flutter ${getTestArguments(testName, mode).join(' ')}';
}

/// Prepares a key for the [blackList] map.
///
/// Uses the browser name and the operating system name.
String getBlockedTestsListMapKey(String browser) =>
    '${browser}-${io.Platform.operatingSystem}';

/// Tests that should be skipped run for a specific platform-browser
/// combination.
///
/// These tests might be failing or might have been implemented for a specific
/// configuration.
///
/// For example when adding a tests only intended for mobile browsers, it should
/// be added to [blockedTests] for `chrome-linux`, `safari-macos` and
/// `chrome-macos`. It will work on `chrome-android`, `safari-ios`.
///
/// Note that integration tests are only running on chrome for now.
const Map<String, List<String>> blockedTestsListsMap = <String, List<String>>{
  'chrome-linux': [
    'target_platform_android_e2e.dart',
    'target_platform_ios_e2e.dart',
    'target_platform_macos_e2e.dart',
  ],
  'chrome-macos': [
    'target_platform_ios_e2e.dart',
    'target_platform_android_e2e.dart',
  ],
  'safari-macos': [
    'target_platform_ios_e2e.dart',
    'target_platform_android_e2e.dart',
    'image_loading_e2e.dart',
  ],
  'firefox-linux': [
    'target_platform_android_e2e.dart',
    'target_platform_ios_e2e.dart',
    'target_platform_macos_e2e.dart',
  ],
  'firefox-macos': [
    'target_platform_android_e2e.dart',
    'target_platform_ios_e2e.dart',
  ],
};

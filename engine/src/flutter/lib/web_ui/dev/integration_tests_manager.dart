// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6

import 'dart:io' as io;
import 'package:args/args.dart';
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

  final bool _doUpdateScreenshotGoldens;

  IntegrationTestsManager(
      this._browser, this._useSystemFlutter, this._doUpdateScreenshotGoldens)
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

  int _numberOfPassedTests = 0;
  int _numberOfFailedTests = 0;

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

    // If no target is specified run all the tests.
    if (_runAllTestTargets) {
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
      if (isVerboseLoggingEnabled) {
        print(
            'INFO: In project ${directory} ${e2eTestsToRun.length} tests to run.');
      }
    } else {
      // If a target is specified it will run regardless of if it's blocked or
      // not. There will be an info note to warn the developer.
      final String targetTest =
          IntegrationTestsArgumentParser.instance.testTarget;
      final io.File file =
          entities.singleWhere((f) => pathlib.basename(f.path) == targetTest);
      final String basename = pathlib.basename(file.path);
      if (blockedTests.contains(basename) && isVerboseLoggingEnabled) {
        print('INFO: Test $basename do not run on CI environments. Please '
            'remove it from the blocked tests list if you want to enable this '
            'test on CI.');
      }
      e2eTestsToRun.add(basename);
    }

    final Set<String> buildModes = _getBuildModes();

    for (String fileName in e2eTestsToRun) {
      await _runTestsTarget(directory, fileName, buildModes);
    }

    final int numberOfTestsRun = _numberOfPassedTests + _numberOfFailedTests;

    print('INFO: ${numberOfTestsRun} tests run. ${_numberOfPassedTests} passed '
        'and ${_numberOfFailedTests} failed.');
    return _numberOfFailedTests == 0;
  }

  Future<void> _runTestsTarget(
      io.Directory directory, String target, Set<String> buildModes) async {
    final Set<String> renderingBackends = _getRenderingBackends();
    for (String renderingBackend in renderingBackends) {
      for (String mode in buildModes) {
        if (!blockedTestsListsMapForModes[mode].contains(target) &&
            !blockedTestsListsMapForRenderBackends[renderingBackend]
                .contains(target)) {
          final bool result = await _runTestsInMode(directory, target,
              mode: mode, webRenderer: renderingBackend);
          if (result) {
            _numberOfPassedTests++;
          } else {
            _numberOfFailedTests++;
          }
        }
      }
    }
  }

  Future<bool> _runTestsInMode(io.Directory directory, String testName,
      {String mode = 'profile', String webRenderer = 'html'}) async {
    String executable =
        _useSystemFlutter ? 'flutter' : environment.flutterCommand.path;
    Map<String, String> enviroment = Map<String, String>();
    if (_doUpdateScreenshotGoldens) {
      enviroment['UPDATE_GOLDENS'] = 'true';
    }
    final IntegrationArguments arguments =
        IntegrationArguments.fromBrowser(_browser);
    final int exitCode = await runProcess(
      executable,
      arguments.getTestArguments(testName, mode, webRenderer),
      workingDirectory: directory.path,
      environment: enviroment,
    );

    if (exitCode != 0) {
      final String command =
          arguments.getCommandToRun(testName, mode, webRenderer);
      io.stderr
          .writeln('ERROR: Failed to run test. Exited with exit code $exitCode'
              '. To run $testName locally use the following command:'
              '\n\n$command');
      return false;
    } else {
      return true;
    }
  }

  Set<String> _getRenderingBackends() {
    Set<String> renderingBackends;
    if (_renderingBackendSelected) {
      final String mode = IntegrationTestsArgumentParser.instance.webRenderer;
      renderingBackends = <String>{mode};
    } else {
      // TODO(nurhan): Enable `auto` when recipe is sharded.
      renderingBackends = {'html', 'canvaskit'};
    }
    return renderingBackends;
  }

  Set<String> _getBuildModes() {
    Set<String> buildModes;
    if (_buildModeSelected) {
      final String mode = IntegrationTestsArgumentParser.instance.buildMode;
      if (mode == 'debug' && _browser != 'chrome') {
        throw ToolException('Debug mode is only supported for Chrome.');
      } else {
        buildModes = <String>{mode};
      }
    } else {
      // TODO(nurhan): Enable `release` when recipe is sharded.
      buildModes = _browser == 'chrome'
          ? {'debug', 'profile'}
          : {'profile'};
    }
    return buildModes;
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

  bool get _buildModeSelected =>
      !IntegrationTestsArgumentParser.instance.buildMode.isEmpty;

  bool get _renderingBackendSelected =>
      !IntegrationTestsArgumentParser.instance.webRenderer.isEmpty;

  bool get _runAllTestTargets =>
      IntegrationTestsArgumentParser.instance.testTarget.isEmpty;

  /// Validate the given `browser`, `platform` combination is suitable for
  /// integration tests to run.
  bool validateIfTestsShouldRun() {
    if (_buildModeSelected) {
      final String mode = IntegrationTestsArgumentParser.instance.buildMode;
      if (mode == 'debug' && _browser != 'chrome') {
        throw ToolException('Debug mode is only supported for Chrome.');
      }
    }

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

  List<String> getTestArguments(
      String testName, String mode, String webRenderer);

  String getCommandToRun(String testName, String mode, String webRenderer);
}

/// Arguments to give `flutter drive` to run the integration tests on Chrome.
class ChromeIntegrationArguments extends IntegrationArguments {
  List<String> getTestArguments(
      String testName, String mode, String webRenderer) {
    return <String>[
      'drive',
      '--target=test_driver/${testName}',
      '-d',
      'web-server',
      '--$mode',
      '--browser-name=chrome',
      if (isLuci) '--chrome-binary=${preinstalledChromeExecutable()}',
      '--headless',
      '--local-engine=host_debug_unopt',
      '--web-renderer=$webRenderer',
    ];
  }

  String getCommandToRun(String testName, String mode, String webRenderer) {
    String statementToRun = 'flutter drive '
        '--target=test_driver/${testName} -d web-server --$mode '
        '--browser-name=chrome --local-engine=host_debug_unopt '
        '--web-renderer=$webRenderer';
    if (isLuci) {
      statementToRun = '$statementToRun --chrome-binary='
          '${preinstalledChromeExecutable()}';
    }
    return statementToRun;
  }
}

/// Arguments to give `flutter drive` to run the integration tests on Firefox.
class FirefoxIntegrationArguments extends IntegrationArguments {
  List<String> getTestArguments(
      String testName, String mode, String webRenderer) {
    return <String>[
      'drive',
      '--target=test_driver/${testName}',
      '-d',
      'web-server',
      '--$mode',
      '--browser-name=firefox',
      '--headless',
      '--local-engine=host_debug_unopt',
      '--web-renderer=$webRenderer',
    ];
  }

  String getCommandToRun(String testName, String mode, String webRenderer) {
    final String arguments =
        getTestArguments(testName, mode, webRenderer).join(' ');
    return 'flutter $arguments';
  }
}

/// Arguments to give `flutter drive` to run the integration tests on Safari.
class SafariIntegrationArguments extends IntegrationArguments {
  SafariIntegrationArguments();

  List<String> getTestArguments(
      String testName, String mode, String webRenderer) {
    return <String>[
      'drive',
      '--target=test_driver/${testName}',
      '-d',
      'web-server',
      '--$mode',
      '--browser-name=safari',
      '--local-engine=host_debug_unopt',
      '--web-renderer=$webRenderer',
    ];
  }

  String getCommandToRun(String testName, String mode, String webRenderer) {
    final String arguments =
        getTestArguments(testName, mode, webRenderer).join(' ');
    return 'flutter $arguments';
  }
}

/// Parses additional options that can be used when running integration tests.
class IntegrationTestsArgumentParser {
  static final IntegrationTestsArgumentParser _singletonInstance =
      IntegrationTestsArgumentParser._();

  /// The [IntegrationTestsArgumentParser] singleton.
  static IntegrationTestsArgumentParser get instance => _singletonInstance;

  IntegrationTestsArgumentParser._();

  /// If target name is provided integration tests can run that one test
  /// instead of running all the tests.
  String testTarget;

  /// The build mode to run the integration tests.
  ///
  /// If not specified, these tests will run using 'debug, profile, release'
  /// modes on Chrome and will run using 'profile, release' on other browsers.
  ///
  /// In order to skip a test for one of the modes, add the test to the
  /// `blockedTestsListsMapForModes` list for the relevant compile mode.
  String buildMode;

  /// Whether to use html, canvaskit or auto for web renderer.
  ///
  /// If not set all backends will be used one after another for integration
  /// tests. If set only the provided option will be used.
  String webRenderer;

  void populateOptions(ArgParser argParser) {
    argParser
      ..addOption(
        'target',
        defaultsTo: '',
        help: 'By default integration tests are run for all the tests under'
            'flutter/e2etests/web directory. If a test name is specified, that '
            'only that test will run. The test name will be the name of the '
            'integration test (e2e test) file. For example: '
            'text_editing_integration.dart or '
            'profile_diagnostics_integration.dart',
      )
      ..addOption('build-mode',
          defaultsTo: '',
          help: 'Flutter supports three modes when building your app. This '
              'option sets the build mode for the integration tests. '
              'By default an integration test will sequentially run on '
              'multiple modes. All three modes (debug, release, profile) are '
              'used for Chrome. Only profile, release modes will be used for '
              'other browsers. In other words, if a build mode is selected '
              'tests will only be run using that mode. '
              'See https://flutter.dev/docs/testing/build-modes for more '
              'details on the build modes.')
      ..addOption('web-renderer',
          defaultsTo: '',
          help: 'By default all three options (`html`, `canvaskit`, `auto`) '
              ' for rendering backends are tested when running integration '
              ' tests. If this option is set only the backend provided by this '
              ' option will be used. `auto`, `canvaskit` and `html`'
              ' are the available options. ');
  }

  /// Populate results of the arguments passed.
  void parseOptions(ArgResults argResults) {
    testTarget = argResults['target'] as String;
    buildMode = argResults['build-mode'] as String;
    if (!buildMode.isEmpty &&
        buildMode != 'debug' &&
        buildMode != 'profile' &&
        buildMode != 'release') {
      throw ArgumentError('Unexpected build mode: $buildMode');
    }
    webRenderer = argResults['web-renderer'] as String;
    if (!webRenderer.isEmpty &&
        webRenderer != 'html' &&
        webRenderer != 'canvaskit' &&
        webRenderer != 'auto') {
      throw ArgumentError('Unexpected rendering backend: $webRenderer');
    }
  }
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
    'target_platform_android_integration.dart',
    'target_platform_ios_integration.dart',
    'target_platform_macos_integration.dart',
  ],
  'chrome-macos': [
    'target_platform_ios_integration.dart',
    'target_platform_android_integration.dart',
  ],
  'safari-macos': [
    'target_platform_ios_integration.dart',
    'target_platform_android_integration.dart',
    'image_loading_integration.dart',
  ],
  'firefox-linux': [
    'target_platform_android_integration.dart',
    'target_platform_ios_integration.dart',
    'target_platform_macos_integration.dart',
  ],
  'firefox-macos': [
    'target_platform_android_integration.dart',
    'target_platform_ios_integration.dart',
  ],
};

/// Tests blocked for one of the build modes.
///
/// If a test is not supposed to run for one of the modes also add that test
/// to the corresponding list.
// TODO(nurhan): Remove the failing test after fixing.
const Map<String, List<String>> blockedTestsListsMapForModes =
    <String, List<String>>{
  'debug': [
    'treeshaking_integration.dart',
    'text_editing_integration.dart',
    'url_strategy_integration.dart',
  ],
  'profile': [],
  'release': [],
};

/// Tests blocked for one of the rendering backends.
///
/// If a test is not suppose to run for one of the backends also add that test
/// to the corresponding list.
// TODO(nurhan): Remove the failing test after fixing.
const Map<String, List<String>> blockedTestsListsMapForRenderBackends =
    <String, List<String>>{
  'auto': [],
  'html': [],
  // This test failed on canvaskit on all three build modes.
  'canvaskit': ['image_loading_integration.dart'],
};

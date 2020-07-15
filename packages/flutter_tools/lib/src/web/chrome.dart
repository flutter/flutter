// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../convert.dart';

/// An environment variable used to override the location of Google Chrome.
const String kChromeEnvironment = 'CHROME_EXECUTABLE';

/// An environment variable used to override the location of Microsoft Edge.
const String kEdgeEnvironment = 'EDGE_ENVIRONMENT';

/// The expected executable name on linux.
const String kLinuxExecutable = 'google-chrome';

/// The expected executable name on macOS.
const String kMacOSExecutable =
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

/// The expected Chrome executable name on Windows.
const String kWindowsExecutable = r'Google\Chrome\Application\chrome.exe';

/// The expected Edge executable name on Windows.
const String kWindowsEdgeExecutable = r'Microsoft\Edge\Application\msedge.exe';

typedef BrowserFinder = String Function(Platform, FileSystem);

/// Find the chrome executable on the current platform.
///
/// Does not verify whether the executable exists.
String findChromeExecutable(Platform platform, FileSystem fileSystem) {
  if (platform.environment.containsKey(kChromeEnvironment)) {
    return platform.environment[kChromeEnvironment];
  }
  if (platform.isLinux) {
    return kLinuxExecutable;
  }
  if (platform.isMacOS) {
    return kMacOSExecutable;
  }
  if (platform.isWindows) {
    /// The possible locations where the chrome executable can be located on windows.
    final List<String> kWindowsPrefixes = <String>[
      platform.environment['LOCALAPPDATA'],
      platform.environment['PROGRAMFILES'],
      platform.environment['PROGRAMFILES(X86)'],
    ];
    final String windowsPrefix = kWindowsPrefixes.firstWhere((String prefix) {
      if (prefix == null) {
        return false;
      }
      final String path = fileSystem.path.join(prefix, kWindowsExecutable);
      return fileSystem.file(path).existsSync();
    }, orElse: () => '.');
    return fileSystem.path.join(windowsPrefix, kWindowsExecutable);
  }
  throwToolExit('Platform ${platform.operatingSystem} is not supported.');
  return null;
}

/// Find the Microsoft Edge executable on the current platform.
///
/// Does not verify whether the executable exists.
String findEdgeExecutable(Platform platform, FileSystem fileSystem) {
  if (platform.environment.containsKey(kEdgeEnvironment)) {
    return platform.environment[kEdgeEnvironment];
  }
  if (platform.isWindows) {
    /// The possible locations where the Edge executable can be located on windows.
    final List<String> kWindowsPrefixes = <String>[
      platform.environment['LOCALAPPDATA'],
      platform.environment['PROGRAMFILES'],
      platform.environment['PROGRAMFILES(X86)'],
    ];
    final String windowsPrefix = kWindowsPrefixes.firstWhere((String prefix) {
      if (prefix == null) {
        return false;
      }
      final String path = fileSystem.path.join(prefix, kWindowsEdgeExecutable);
      return fileSystem.file(path).existsSync();
    }, orElse: () => '.');
    return fileSystem.path.join(windowsPrefix, kWindowsEdgeExecutable);
  }
  // Not yet supported for macOS and Linux.
  return '';
}

/// A launcher for Chromium browsers with devtools configured.
class ChromiumLauncher {
  ChromiumLauncher({
    @required FileSystem fileSystem,
    @required Platform platform,
    @required ProcessManager processManager,
    @required OperatingSystemUtils operatingSystemUtils,
    @required BrowserFinder browserFinder,
    @required Logger logger,
  }) : _fileSystem = fileSystem,
       _platform = platform,
       _processManager = processManager,
       _operatingSystemUtils = operatingSystemUtils,
       _browserFinder = browserFinder,
       _logger = logger,
       _fileSystemUtils = FileSystemUtils(
         fileSystem: fileSystem,
         platform: platform,
       );

  final FileSystem _fileSystem;
  final Platform _platform;
  final ProcessManager _processManager;
  final OperatingSystemUtils _operatingSystemUtils;
  final BrowserFinder _browserFinder;
  final FileSystemUtils _fileSystemUtils;
  final Logger _logger;

  bool get hasChromeInstance => _currentCompleter.isCompleted;

  Completer<Chromium> _currentCompleter = Completer<Chromium>();

  @visibleForTesting
  void testLaunchChromium(Chromium chromium) {
    _currentCompleter.complete(chromium);
  }

  /// Whether we can locate the chrome executable.
  bool canFindExecutable() {
    final String chrome = _browserFinder(_platform, _fileSystem);
    try {
      return _processManager.canRun(chrome);
    } on ArgumentError {
      return false;
    }
  }

  /// The executable this launcher will use.
  String findExecutable() =>  _browserFinder(_platform, _fileSystem);

  /// Launch a Chromium browser to a particular `host` page.
  ///
  /// `headless` defaults to false, and controls whether we open a headless or
  /// a `headfull` browser.
  ///
  /// `debugPort` is Chrome's debugging protocol port. If null, a random free
  /// port is picked automatically.
  ///
  /// `skipCheck` does not attempt to make a devtools connection before returning.
  Future<Chromium> launch(String url, {
    bool headless = false,
    int debugPort,
    bool skipCheck = false,
    Directory cacheDir,
  }) async {
    if (_currentCompleter.isCompleted) {
      throwToolExit('Only one instance of chrome can be started.');
    }

    final String chromeExecutable = _browserFinder(_platform, _fileSystem);
    final Directory userDataDir = _fileSystem.systemTempDirectory
      .createTempSync('flutter_tools_chrome_device.');

    if (cacheDir != null) {
      // Seed data dir with previous state.
      _restoreUserSessionInformation(cacheDir, userDataDir);
    }

    final int port = debugPort ?? await _operatingSystemUtils.findFreePort();
    final List<String> args = <String>[
      chromeExecutable,
      // Using a tmp directory ensures that a new instance of chrome launches
      // allowing for the remote debug port to be enabled.
      '--user-data-dir=${userDataDir.path}',
      '--remote-debugging-port=$port',
      // When the DevTools has focus we don't want to slow down the application.
      '--disable-background-timer-throttling',
      // Since we are using a temp profile, disable features that slow the
      // Chrome launch.
      '--disable-extensions',
      '--disable-popup-blocking',
      '--bwsi',
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-default-apps',
      '--disable-translate',
      if (headless)
        ...<String>[
          '--headless',
          '--disable-gpu',
          '--no-sandbox',
          '--window-size=2400,1800',
        ],
      url,
    ];

    final Process process = await _processManager.start(args);

    process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
        _logger.printTrace('[CHROME]: $line');
      });

    // Wait until the DevTools are listening before trying to connect. This is
    // only required for flutter_test --platform=chrome and not flutter run.
    await process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .map((String line) {
        _logger.printTrace('[CHROME]:$line');
        return line;
      })
      .firstWhere((String line) => line.startsWith('DevTools listening'), orElse: () {
        return 'Failed to spawn stderr';
      });

    // When the process exits, copy the user settings back to the provided data-dir.
    if (cacheDir != null) {
      unawaited(process.exitCode.whenComplete(() {
        _cacheUserSessionInformation(userDataDir, cacheDir);
      }));
    }
    return _connect(Chromium._(
      port,
      ChromeConnection('localhost', port),
      url: url,
      process: process,
      chromiumLauncher: this,
    ), skipCheck);
  }

  // This is a JSON file which contains configuration from the browser session,
  // such as window position. It is located under the Chrome data-dir folder.
  String get _preferencesPath => _fileSystem.path.join('Default', 'preferences');

  // The directory that Chrome uses to store local storage information for web apps.
  String get _localStoragePath => _fileSystem.path.join('Default', 'Local Storage');

  /// Copy Chrome user information from a Chrome session into a per-project
  /// cache.
  ///
  /// Note: more detailed docs of the Chrome user preferences store exists here:
  /// https://www.chromium.org/developers/design-documents/preferences.
  void _cacheUserSessionInformation(Directory userDataDir, Directory cacheDir) {
    final File targetPreferencesFile = _fileSystem.file(_fileSystem.path.join(cacheDir?.path ?? '', _preferencesPath));
    final File sourcePreferencesFile = _fileSystem.file(_fileSystem.path.join(userDataDir.path, _preferencesPath));
    final Directory targetLocalStorageDir = _fileSystem.directory(_fileSystem.path.join(cacheDir?.path ?? '', _localStoragePath));
    final Directory sourceLocalStorageDir = _fileSystem.directory(_fileSystem.path.join(userDataDir.path, _localStoragePath));

    if (sourcePreferencesFile.existsSync()) {
      targetPreferencesFile.parent.createSync(recursive: true);
      // If the file contains a crash string, remove it to hide the popup on next run.
      final String contents = sourcePreferencesFile.readAsStringSync();
      targetPreferencesFile.writeAsStringSync(contents
          .replaceFirst('"exit_type":"Crashed"', '"exit_type":"Normal"'));
    }

    if (sourceLocalStorageDir.existsSync()) {
      targetLocalStorageDir.createSync(recursive: true);
      _fileSystemUtils.copyDirectorySync(sourceLocalStorageDir, targetLocalStorageDir);
    }
  }

  /// Restore Chrome user information from a per-project cache into Chrome's
  /// user data directory.
  void _restoreUserSessionInformation(Directory cacheDir, Directory userDataDir) {
    final File sourcePreferencesFile = _fileSystem.file(_fileSystem.path.join(cacheDir.path ?? '', _preferencesPath));
    final File targetPreferencesFile = _fileSystem.file(_fileSystem.path.join(userDataDir.path, _preferencesPath));
    final Directory sourceLocalStorageDir = _fileSystem.directory(_fileSystem.path.join(cacheDir.path ?? '', _localStoragePath));
    final Directory targetLocalStorageDir = _fileSystem.directory(_fileSystem.path.join(userDataDir.path, _localStoragePath));

    if (sourcePreferencesFile.existsSync()) {
      targetPreferencesFile.parent.createSync(recursive: true);
      sourcePreferencesFile.copySync(targetPreferencesFile.path);
    }

    if (sourceLocalStorageDir.existsSync()) {
      targetLocalStorageDir.createSync(recursive: true);
      _fileSystemUtils.copyDirectorySync(sourceLocalStorageDir, targetLocalStorageDir);
    }
  }

  Future<Chromium> _connect(Chromium chrome, bool skipCheck) async {
    // The connection is lazy. Try a simple call to make sure the provided
    // connection is valid.
    if (!skipCheck) {
      try {
        await chrome.chromeConnection.getTabs();
      } on Exception catch (e) {
        await chrome.close();
        throwToolExit(
            'Unable to connect to Chrome debug port: ${chrome.debugPort}\n $e');
      }
    }
    _currentCompleter.complete(chrome);
    return chrome;
  }

  Future<Chromium> get connectedInstance => _currentCompleter.future;
}

/// A class for managing an instance of a Chromium browser.
class Chromium {
  Chromium._(
    this.debugPort,
    this.chromeConnection, {
    this.url,
    Process process,
    @required ChromiumLauncher chromiumLauncher,
  })  : _process = process,
        _chromiumLauncher = chromiumLauncher;

  final String url;
  final int debugPort;
  final Process _process;
  final ChromeConnection chromeConnection;
  final ChromiumLauncher _chromiumLauncher;

  Future<int> get onExit => _process.exitCode;

  Future<void> close() async {
    if (_chromiumLauncher.hasChromeInstance) {
      _chromiumLauncher._currentCompleter = Completer<Chromium>();
    }
    chromeConnection.close();
    _process?.kill();
    await _process?.exitCode;
  }
}

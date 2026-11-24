// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:async/async.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart' hide StackTrace;

import '../base/common.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/utils.dart';
import 'chrome.dart' show BrowserFinder;
import 'web_browser.dart';

/// An environment variable used to override the location of Mozilla Firefox.
const kFirefoxEnvironment = 'FIREFOX_EXECUTABLE';

/// The expected Firefox executable name on Linux.
const kLinuxFirefoxExecutable = 'firefox';

/// The expected Firefox executable path on macOS.
const kMacOSFirefoxExecutable = '/Applications/Firefox.app/Contents/MacOS/firefox';

/// The expected Firefox executable path suffix on Windows.
const kWindowsFirefoxExecutable = r'Mozilla Firefox\firefox.exe';

const _kFirefoxCloseTimeout = Duration(seconds: 5);

/// Firefox profile preferences written to `user.js` for isolated automated test runs.
const _kFirefoxUserPrefs = '''
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("dom.disable_open_during_load", false);
user_pref("dom.max_script_run_time", 0);
user_pref("trailhead.firstrun.branches", "nofirstrun-empty");
user_pref("browser.aboutwelcome.enabled", false);
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
user_pref("webgl.force-enabled", true);
user_pref("webgl.disabled", false);
user_pref("webgl.forbid-software", false);
user_pref("webgl.disable-fail-if-major-performance-caveat", true);
user_pref("gfx.webrender.software", true);
user_pref("security.sandbox.content.level", 0);
user_pref("intl.accept_languages", "en-US, en");
user_pref("network.proxy.no_proxies_on", "localhost, 127.0.0.1, ::1");
user_pref("toolkit.shutdown.fastShutdownStage", 3);
''';

/// Find the Firefox executable on the current platform.
///
/// Does not verify whether the executable exists.
String findFirefoxExecutable(Platform platform, FileSystem fileSystem) {
  if (platform.environment.containsKey(kFirefoxEnvironment)) {
    return platform.environment[kFirefoxEnvironment]!;
  }
  if (platform.isLinux) {
    return kLinuxFirefoxExecutable;
  }
  if (platform.isMacOS) {
    return kMacOSFirefoxExecutable;
  }
  if (platform.isWindows) {
    final windowsPrefixes = <String>[
      ?platform.environment['LOCALAPPDATA'],
      ?platform.environment['PROGRAMFILES'],
      ?platform.environment['PROGRAMFILES(X86)'],
    ];
    final String windowsPrefix = windowsPrefixes.firstWhere((String prefix) {
      final String path = fileSystem.path.join(prefix, kWindowsFirefoxExecutable);
      return fileSystem.file(path).existsSync();
    }, orElse: () => '.');
    return fileSystem.path.join(windowsPrefix, kWindowsFirefoxExecutable);
  }
  throwToolExit('Platform ${platform.operatingSystem} is not supported.');
}

/// A launcher for Mozilla Firefox with an isolated temporary profile.
class FirefoxLauncher implements WebTestBrowserLauncher {
  FirefoxLauncher({
    required this._fileSystem,
    required this._platform,
    required this._processManager,
    required this._logger,
    this._browserFinder = findFirefoxExecutable,
  });

  final FileSystem _fileSystem;
  final Platform _platform;
  final ProcessManager _processManager;
  final Logger _logger;
  final BrowserFinder _browserFinder;

  /// Whether we can locate the Firefox executable.
  bool canFindExecutable() {
    final String firefox = _browserFinder(_platform, _fileSystem);
    try {
      return _processManager.canRun(firefox);
    } on ArgumentError {
      return false;
    }
  }

  /// The executable this launcher will use.
  String findExecutable() => _browserFinder(_platform, _fileSystem);

  @override
  Future<Firefox> launch(
    String url, {
    bool headless = false,
    List<String> webBrowserFlags = const <String>[],
  }) async {
    final String firefoxExecutable = findExecutable();
    if (_logger.isVerbose) {
      _logger.printTrace('Launching Firefox (url = $url, headless = $headless)');
      _logger.printTrace('Will use Firefox executable at $firefoxExecutable');
    }
    if (!canFindExecutable()) {
      throwToolExit(
        'Unable to locate a Firefox executable at "$firefoxExecutable". '
        'Install Firefox or set the $kFirefoxEnvironment environment variable.',
      );
    }

    // Create a fresh temporary profile directory per launch so cached test
    // assets (`Cache-Control: max-age`) never outlive a single invocation.
    final Directory profileDir = _fileSystem.systemTempDirectory.createTempSync(
      'flutter_tools_firefox_profile.',
    );
    profileDir.childFile('user.js').writeAsStringSync(_kFirefoxUserPrefs);

    final args = <String>[
      firefoxExecutable,
      '--profile',
      profileDir.path,
      if (headless) '--headless',
      '-width',
      '1280',
      '-height',
      '800',
      '-no-remote',
      '-new-instance',
      ...webBrowserFlags,
      url,
    ];

    final environment = <String, String>{
      ..._platform.environment,
      'MOZ_CRASHREPORTER_DISABLE': '1',
      if (!_platform.environment.containsKey('LANG')) 'LANG': 'en_US.UTF-8',
      if (headless) ...<String, String>{
        'MOZ_HEADLESS': '1',
        if (_platform.isLinux) ...<String, String>{
          if (!_platform.environment.containsKey('LIBGL_ALWAYS_SOFTWARE'))
            'LIBGL_ALWAYS_SOFTWARE': '1',
          'MOZ_DISABLE_CONTENT_SANDBOX': '1',
          'MOZ_DISABLE_GPU_SANDBOX': '1',
          'MOZ_DISABLE_RDD_SANDBOX': '1',
          'MOZ_DISABLE_SOCKET_PROCESS_SANDBOX': '1',
        },
      },
    };

    final Process process;
    try {
      process = await _processManager.start(args, environment: environment);
    } on Object catch (error) {
      ErrorHandlingFileSystem.deleteIfExists(profileDir, recursive: true);
      throwToolExit('Failed to launch Firefox at "$firefoxExecutable": $error');
    }

    unawaited(
      process.exitCode.whenComplete(() {
        ErrorHandlingFileSystem.deleteIfExists(profileDir, recursive: true);
      }),
    );

    return Firefox(process: process, profileDirectory: profileDir, logger: _logger);
  }
}

/// Manages a running instance of Mozilla Firefox.
class Firefox implements WebTestBrowser {
  Firefox({required this._process, required this._profileDirectory, required this._logger}) {
    void addLog(String type, String line) {
      _logger.printTrace('[FIREFOX]: $line');
      _logBuffer.add('[$type]: $line');
      if (_logBuffer.length > 200) {
        _logBuffer.removeFirst();
      }
    }

    _stdoutSubscription = _process.stdout
        .transform(utf8LineDecoder)
        .listen((String line) => addLog('FIREFOX STDOUT', line));
    _stderrSubscription = _process.stderr
        .transform(utf8LineDecoder)
        .listen((String line) => addLog('FIREFOX STDERR', line));

    unawaited(
      _process.exitCode.then((int code) {
        if (!_didClose && code != 0) {
          _logger.printError(
            'Firefox process PID $pid exited unexpectedly with code $code.\n'
            'Last 200 lines of Firefox output:\n'
            '${_logBuffer.join('\n')}',
          );
        }
      }),
    );
  }

  final Process _process;
  final Directory _profileDirectory;
  final Logger _logger;
  final _logBuffer = ListQueue<String>(200);
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  final _closeMemoizer = AsyncMemoizer<void>();
  var _didClose = false;

  @override
  String get name => 'Firefox';

  @override
  int get pid => _process.pid;

  @override
  Future<int> get onExit => _process.exitCode;

  @override
  Uri? get remoteDebuggerUrl => null;

  @override
  Future<WipConnection?>? get wipConnection => null;

  @visibleForTesting
  Process get process => _process;

  @visibleForTesting
  Directory get profileDirectory => _profileDirectory;

  @override
  Future<void> close() {
    return _closeMemoizer.runOnce(() async {
      _didClose = true;
      if (_logger.isVerbose) {
        _logger.printTrace('Shutting down Firefox.');
      }

      unawaited(_stdoutSubscription?.cancel());
      unawaited(_stderrSubscription?.cancel());

      ProcessSignal.sigterm.kill(_process);
      await _process.exitCode.timeout(
        _kFirefoxCloseTimeout,
        onTimeout: () {
          _logger.printWarning(
            'Failed to exit Firefox (pid: ${_process.pid}) using SIGTERM. Will try '
            'sending SIGKILL instead.',
          );
          ProcessSignal.sigkill.kill(_process);
          return _process.exitCode.timeout(
            _kFirefoxCloseTimeout,
            onTimeout: () async {
              _logger.printWarning(
                'Failed to exit Firefox (pid: ${_process.pid}) using SIGKILL. Giving '
                'up. Will continue, assuming Firefox has exited successfully.',
              );
              return 0;
            },
          );
        },
      );

      ErrorHandlingFileSystem.deleteIfExists(_profileDirectory, recursive: true);
    });
  }
}

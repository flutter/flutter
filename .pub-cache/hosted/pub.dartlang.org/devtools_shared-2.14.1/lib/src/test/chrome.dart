// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    hide ChromeTab;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    as wip show ChromeTab;

import 'utils_io.dart';

// Change this if you want to be able to see Chrome opening while tests run
// to aid debugging.
const useChromeHeadless = true;

// Chrome headless currently hangs on Windows (both Travis and locally),
// so we won't use it there.
final headlessModeIsSupported = !Platform.isWindows;

class Chrome {
  Chrome._(this.executable);

  static Chrome? from(String executable) {
    return FileSystemEntity.isFileSync(executable)
        ? Chrome._(executable)
        : null;
  }

  static Chrome? locate() {
    if (Platform.isMacOS) {
      const String defaultPath = '/Applications/Google Chrome.app';
      const String bundlePath = 'Contents/MacOS/Google Chrome';

      if (FileSystemEntity.isDirectorySync(defaultPath)) {
        return Chrome.from(path.join(defaultPath, bundlePath));
      }
    } else if (Platform.isLinux) {
      const String defaultPath = '/usr/bin/google-chrome';

      if (FileSystemEntity.isFileSync(defaultPath)) {
        return Chrome.from(defaultPath);
      }
    } else if (Platform.isWindows) {
      final String progFiles = Platform.environment['PROGRAMFILES(X86)']!;
      final String chromeInstall = '$progFiles\\Google\\Chrome';
      final String defaultPath = '$chromeInstall\\Application\\chrome.exe';

      if (FileSystemEntity.isFileSync(defaultPath)) {
        return Chrome.from(defaultPath);
      }
    }

    final pathFromEnv = Platform.environment['CHROME_PATH'];
    if (pathFromEnv != null && FileSystemEntity.isFileSync(pathFromEnv)) {
      return Chrome.from(pathFromEnv);
    }

    // TODO(devoncarew): check default install locations for linux
    // TODO(devoncarew): try `which` on mac, linux

    return null;
  }

  /// Return the path to a per-user Chrome data dir.
  ///
  /// This method will create the directory if it does not exist.
  static String getCreateChromeDataDir() {
    final Directory prefsDir = getDartPrefsDirectory();
    final Directory chromeDataDir =
        Directory(path.join(prefsDir.path, 'chrome'));
    if (!chromeDataDir.existsSync()) {
      chromeDataDir.createSync(recursive: true);
    }
    return chromeDataDir.path;
  }

  final String executable;

  Future<ChromeProcess> start({String? url, int debugPort = 9222}) {
    final List<String> args = <String>[
      '--no-default-browser-check',
      '--no-first-run',
      '--user-data-dir=${getCreateChromeDataDir()}',
      '--remote-debugging-port=$debugPort'
    ];
    if (useChromeHeadless && headlessModeIsSupported) {
      args.addAll(<String>[
        '--headless',
        '--disable-gpu',
      ]);
    }
    if (url != null) {
      args.add(url);
    }
    return Process.start(executable, args).then((Process process) {
      return ChromeProcess(process, debugPort);
    });
  }
}

class ChromeProcess {
  ChromeProcess(this.process, this.debugPort);

  final Process process;
  final int debugPort;
  bool _processAlive = true;

  Future<ChromeTab?> connectToTab(
    String url, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    return await _connectToTab(
      connection: ChromeConnection(Uri.parse(url).host, debugPort),
      tabFound: (tab) => tab.url == url,
      timeout: timeout,
    );
  }

  Future<ChromeTab?> connectToTabId(
    String host,
    String id, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    return await _connectToTab(
      connection: ChromeConnection(host, debugPort),
      tabFound: (tab) => tab.id == id,
      timeout: timeout,
    );
  }

  Future<ChromeTab?> getFirstTab({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    return await _connectToTab(
      connection: ChromeConnection('localhost', debugPort),
      tabFound: (tab) => !tab.isBackgroundPage && !tab.isChromeExtension,
      timeout: timeout,
    );
  }

  Future<ChromeTab?> _connectToTab({
    required ChromeConnection connection,
    required bool Function(wip.ChromeTab) tabFound,
    required Duration timeout,
  }) async {
    final wip.ChromeTab? wipTab = await connection.getTab(
      (wip.ChromeTab tab) {
        return tabFound(tab);
      },
      retryFor: timeout,
    );

    unawaited(
      process.exitCode.then((_) {
        _processAlive = false;
      }),
    );

    return wipTab == null ? null : ChromeTab(wipTab);
  }

  bool get isAlive => _processAlive;

  /// Returns `true` if the signal is successfully delivered to the process.
  /// Otherwise the signal could not be sent, usually meaning that the process
  /// is already dead.
  bool kill() => process.kill();

  Future<int> get onExit => process.exitCode;
}

class ChromeTab {
  ChromeTab(this.wipTab);

  final wip.ChromeTab wipTab;
  WipConnection? _wip;

  final StreamController<LogEntry> _entryAddedController =
      StreamController<LogEntry>.broadcast();
  final StreamController<ConsoleAPIEvent> _consoleAPICalledController =
      StreamController<ConsoleAPIEvent>.broadcast();
  final StreamController<ExceptionThrownEvent> _exceptionThrownController =
      StreamController<ExceptionThrownEvent>.broadcast();

  num? _lostConnectionTime;

  Future<WipConnection?> connect({bool verbose = false}) async {
    _wip = await wipTab.connect();
    final WipConnection wipConnection = _wip!;

    await wipConnection.log.enable();
    wipConnection.log.onEntryAdded.listen((LogEntry entry) {
      if (_lostConnectionTime == null ||
          entry.timestamp > _lostConnectionTime!) {
        _entryAddedController.add(entry);
      }
    });

    await wipConnection.runtime.enable();
    wipConnection.runtime.onConsoleAPICalled.listen((ConsoleAPIEvent event) {
      if (_lostConnectionTime == null ||
          event.timestamp > _lostConnectionTime!) {
        _consoleAPICalledController.add(event);
      }
    });

    unawaited(
      _exceptionThrownController
          .addStream(wipConnection.runtime.onExceptionThrown),
    );

    unawaited(wipConnection.page.enable());

    wipConnection.onClose.listen((_) {
      _wip = null;
      _disconnectStream.add(null);
      _lostConnectionTime = DateTime.now().millisecondsSinceEpoch;
    });

    if (verbose) {
      onLogEntryAdded.listen((entry) {
        print('chrome • log:${entry.source} • ${entry.text} ${entry.url}');
      });

      onConsoleAPICalled.listen((entry) {
        print(
          'chrome • console:${entry.type} • '
          '${entry.args.map((a) => a.value).join(', ')}',
        );
      });

      onExceptionThrown.listen((ex) {
        throw 'JavaScript exception occurred: ${ex.method}\n\n'
            '${ex.params}\n\n'
            '${ex.exceptionDetails.text}\n\n'
            '${ex.exceptionDetails.exception}\n\n'
            '${ex.exceptionDetails.stackTrace}';
      });
    }

    return _wip;
  }

  Future<String> createNewTarget() {
    return _wip!.target.createTarget('about:blank');
  }

  bool get isConnected => _wip != null;

  Stream<void> get onDisconnect => _disconnectStream.stream;
  final _disconnectStream = StreamController<void>.broadcast();

  Stream<LogEntry> get onLogEntryAdded => _entryAddedController.stream;

  Stream<ConsoleAPIEvent> get onConsoleAPICalled =>
      _consoleAPICalledController.stream;

  Stream<ExceptionThrownEvent> get onExceptionThrown =>
      _exceptionThrownController.stream;

  Future<WipResponse> reload() => _wip!.page.reload();

  Future<dynamic> navigate(String url) => _wip!.page.navigate(url);

  WipConnection? get wipConnection => _wip;
}

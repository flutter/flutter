// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

const _chromeEnvironments = ['CHROME_EXECUTABLE', 'CHROME_PATH'];
const _linuxExecutable = 'google-chrome';
const _macOSExecutable =
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const _windowsExecutable = r'Google\Chrome\Application\chrome.exe';

String get _executable {
  for (var chromeEnv in _chromeEnvironments) {
    if (Platform.environment.containsKey(chromeEnv)) {
      return Platform.environment[chromeEnv]!;
    }
  }
  if (Platform.isLinux) return _linuxExecutable;
  if (Platform.isMacOS) return _macOSExecutable;
  if (Platform.isWindows) {
    final windowsPrefixes = [
      Platform.environment['LOCALAPPDATA'],
      Platform.environment['PROGRAMFILES'],
      Platform.environment['PROGRAMFILES(X86)']
    ];
    return p.join(
      windowsPrefixes.firstWhere((prefix) {
        if (prefix == null) return false;
        final path = p.join(prefix, _windowsExecutable);
        return File(path).existsSync();
      }, orElse: () => '.')!,
      _windowsExecutable,
    );
  }
  throw StateError('Unexpected platform type.');
}

/// Manager for an instance of Chrome.
class Chrome {
  Chrome._(
    this.debugPort,
    this.chromeConnection, {
    Process? process,
    Directory? dataDir,
    this.deleteDataDir = false,
  })  : _process = process,
        _dataDir = dataDir;

  final int debugPort;
  final ChromeConnection chromeConnection;
  final Process? _process;
  final Directory? _dataDir;
  final bool deleteDataDir;

  /// Connects to an instance of Chrome with an open debug port.
  static Future<Chrome> fromExisting(int port) async =>
      _connect(Chrome._(port, ChromeConnection('localhost', port)));

  /// Starts Chrome with the given arguments and a specific port.
  ///
  /// Each url in [urls] will be loaded in a separate tab.
  ///
  /// If [userDataDir] is `null`, a new temp directory will be
  /// passed to chrome as a user data directory. Chrome will
  /// start without sign in and with extensions disabled.
  ///
  /// If [userDataDir] is not `null`, it will be passed to chrome
  /// as a user data directory. Chrome will start signed into
  /// the default profile with extensions enabled if [signIn]
  /// is also true.
  static Future<Chrome> startWithDebugPort(
    List<String> urls, {
    int debugPort = 0,
    bool headless = false,
    String? userDataDir,
    bool signIn = false,
  }) async {
    Directory dataDir;
    if (userDataDir == null) {
      signIn = false;
      dataDir = Directory.systemTemp.createTempSync();
    } else {
      dataDir = Directory(userDataDir);
    }
    final port = debugPort == 0 ? await findUnusedPort() : debugPort;
    final args = [
      // Using a tmp directory ensures that a new instance of chrome launches
      // allowing for the remote debug port to be enabled.
      '--user-data-dir=${dataDir.path}',
      '--remote-debugging-port=$port',
      // When the DevTools has focus we don't want to slow down the application.
      '--disable-background-timer-throttling',
      // Since we are using a temp profile, disable features that slow the
      // Chrome launch.
      if (!signIn) '--disable-extensions',
      '--disable-popup-blocking',
      if (!signIn) '--bwsi',
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-default-apps',
      '--disable-translate',
      '--start-maximized',
    ];
    if (headless) {
      args.add('--headless');
    }

    final process = await _startProcess(urls, args: args);

    // Wait until the DevTools are listening before trying to connect.
    var _errorLines = <String>[];
    try {
      await process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .firstWhere((line) {
        _errorLines.add(line);
        return line.startsWith('DevTools listening');
      }).timeout(Duration(seconds: 60));
    } catch (_) {
      throw Exception('Unable to connect to Chrome DevTools.\n\n'
              'Chrome STDERR:\n' +
          _errorLines.join('\n'));
    }

    return _connect(Chrome._(
      port,
      ChromeConnection('localhost', port),
      process: process,
      dataDir: dataDir,
      deleteDataDir: userDataDir == null,
    ));
  }

  /// Starts Chrome with the given arguments.
  ///
  /// Each url in [urls] will be loaded in a separate tab.
  static Future<Process> start(
    List<String> urls, {
    List<String> args = const [],
  }) async {
    return await _startProcess(urls, args: args);
  }

  static Future<Process> _startProcess(
    List<String> urls, {
    List<String> args = const [],
  }) async {
    final processArgs = args.toList()..addAll(urls);
    return await Process.start(_executable, processArgs);
  }

  static Future<Chrome> _connect(Chrome chrome) async {
    // The connection is lazy. Try a simple call to make sure the provided
    // connection is valid.
    try {
      await chrome.chromeConnection.getTabs();
    } catch (e) {
      await chrome.close();
      throw ChromeError(
          'Unable to connect to Chrome debug port: ${chrome.debugPort}\n $e');
    }
    return chrome;
  }

  Future<void> close() async {
    chromeConnection.close();
    _process?.kill(ProcessSignal.sigkill);
    await _process?.exitCode;
    try {
      // Chrome starts another process as soon as it dies that modifies the
      // profile information. Give it some time before attempting to delete
      // the directory.
      if (deleteDataDir) {
        await Future.delayed(Duration(milliseconds: 500));
        await _dataDir?.delete(recursive: true);
      }
    } catch (_) {
      // Silently fail if we can't clean up the profile information.
      // It is a system tmp directory so it should get cleaned up eventually.
    }
  }
}

class ChromeError extends Error {
  final String details;
  ChromeError(this.details);

  @override
  String toString() => 'ChromeError: $details';
}

/// Returns a port that is probably, but not definitely, not in use.
///
/// This has a built-in race condition: another process may bind this port at
/// any time after this call has returned.
Future<int> findUnusedPort() async {
  int port;
  ServerSocket socket;
  try {
    socket =
        await ServerSocket.bind(InternetAddress.loopbackIPv6, 0, v6Only: true);
  } on SocketException {
    socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  }
  port = socket.port;
  await socket.close();
  return port;
}

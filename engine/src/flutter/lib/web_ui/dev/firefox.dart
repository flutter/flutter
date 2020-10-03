// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:io';

import 'package:pedantic/pedantic.dart';

import 'package:path/path.dart' as path;
import 'package:test_core/src/util/io.dart'; // ignore: implementation_imports

import 'browser.dart';
import 'common.dart';
import 'environment.dart';
import 'firefox_installer.dart';

/// A class for running an instance of Firefox.
///
/// Most of the communication with the browser is expected to happen via HTTP,
/// so this exposes a bare-bones API. The browser starts as soon as the class is
/// constructed, and is killed when [close] is called.
///
/// Any errors starting or running the process are reported through [onExit].
class Firefox extends Browser {
  @override
  final name = 'Firefox';

  @override
  final Future<Uri> remoteDebuggerUrl;

  static String version;

  /// Starts a new instance of Firefox open to the given [url], which may be a
  /// [Uri] or a [String].
  factory Firefox(Uri url, {bool debug = false}) {
    version = FirefoxArgParser.instance.version;

    assert(version != null);
    var remoteDebuggerCompleter = Completer<Uri>.sync();
    return Firefox._(() async {
      final BrowserInstallation installation = await getOrInstallFirefox(
        version,
        infoLog: isCirrus ? stdout : DevNull(),
      );

      // Using a profile on opening will prevent popups related to profiles.
      final _profile = '''
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("dom.disable_open_during_load", false);
user_pref("dom.max_script_run_time", 0);
''';

      final Directory temporaryProfileDirectory = Directory(
          path.join(environment.webUiDartToolDir.path, 'firefox_profile'));

      // A good source of various Firefox Command Line options:
      // https://developer.mozilla.org/en-US/docs/Mozilla/Command_Line_Options#Browser
      //
      if (temporaryProfileDirectory.existsSync()) {
        temporaryProfileDirectory.deleteSync(recursive: true);
      }
      temporaryProfileDirectory.createSync(recursive: true);

      File(path.join(temporaryProfileDirectory.path, 'prefs.js'))
          .writeAsStringSync(_profile);
      bool isMac = Platform.isMacOS;
      var args = [
        url.toString(),
        '--profile',
        '${temporaryProfileDirectory.path}',
        if (!debug)
          '--headless',
        '-width $kMaxScreenshotWidth',
        '-height $kMaxScreenshotHeight',
        isMac ? '--new-window' : '-new-window',
        isMac ? '--new-instance' : '-new-instance',
        '--start-debugger-server $kDevtoolsPort',
      ];

      final Process process =
          await Process.start(installation.executable, args);

      remoteDebuggerCompleter.complete(
          getRemoteDebuggerUrl(Uri.parse('http://localhost:$kDevtoolsPort')));

      unawaited(process.exitCode.then((_) {
        temporaryProfileDirectory.deleteSync(recursive: true);
      }));

      return process;
    }, remoteDebuggerCompleter.future);
  }

  Firefox._(Future<Process> startBrowser(), this.remoteDebuggerUrl)
      : super(startBrowser);
}

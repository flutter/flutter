// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pedantic/pedantic.dart';

import 'package:test_core/src/util/io.dart'; // ignore: implementation_imports

import 'browser.dart';
import 'chrome_installer.dart';
import 'common.dart';

/// A class for running an instance of Chrome.
///
/// Most of the communication with the browser is expected to happen via HTTP,
/// so this exposes a bare-bones API. The browser starts as soon as the class is
/// constructed, and is killed when [close] is called.
///
/// Any errors starting or running the process are reported through [onExit].
class Chrome extends Browser {
  @override
  final name = 'Chrome';

  @override
  final Future<Uri> remoteDebuggerUrl;

  static String version;

  /// Starts a new instance of Chrome open to the given [url], which may be a
  /// [Uri] or a [String].
  factory Chrome(Uri url, {bool debug = false}) {
    version = ChromeArgParser.instance.version;

    assert(version != null);
    var remoteDebuggerCompleter = Completer<Uri>.sync();
    return Chrome._(() async {
      final BrowserInstallation installation = await getOrInstallChrome(
        version,
        infoLog: isCirrus ? stdout : DevNull(),
      );

      // A good source of various Chrome CLI options:
      // https://peter.sh/experiments/chromium-command-line-switches/
      //
      // Things to try:
      // --font-render-hinting
      // --enable-font-antialiasing
      // --gpu-rasterization-msaa-sample-count
      // --disable-gpu
      // --disallow-non-exact-resource-reuse
      // --disable-font-subpixel-positioning
      final bool isChromeNoSandbox =
          Platform.environment['CHROME_NO_SANDBOX'] == 'true';
      var dir = createTempDir();
      var args = [
        '--user-data-dir=$dir',
        url.toString(),
        if (!debug)
          '--headless',
        if (isChromeNoSandbox)
          '--no-sandbox',
        '--window-size=$kMaxScreenshotWidth,$kMaxScreenshotHeight', // When headless, this is the actual size of the viewport
        '--disable-extensions',
        '--disable-popup-blocking',
        // Indicates that the browser is in "browse without sign-in" (Guest session) mode.
        '--bwsi',
        '--no-first-run',
        '--no-default-browser-check',
        '--disable-default-apps',
        '--disable-translate',
        '--remote-debugging-port=$kDevtoolsPort',
      ];

      final Process process =
          await _spawnChromiumProcess(installation.executable, args);

      remoteDebuggerCompleter.complete(
          getRemoteDebuggerUrl(Uri.parse('http://localhost:${kDevtoolsPort}')));

      unawaited(process.exitCode
          .then((_) => Directory(dir).deleteSync(recursive: true)));

      return process;
    }, remoteDebuggerCompleter.future);
  }

  Chrome._(Future<Process> startBrowser(), this.remoteDebuggerUrl)
      : super(startBrowser);
}

/// Used by [Chrome] to detect a glibc bug and retry launching the
/// browser.
///
/// Once every few thousands of launches we hit this glibc bug:
///
/// https://sourceware.org/bugzilla/show_bug.cgi?id=19329.
///
/// When this happens Chrome spits out something like the following then exits with code 127:
///
///     Inconsistency detected by ld.so: ../elf/dl-tls.c: 493: _dl_allocate_tls_init: Assertion `listp->slotinfo[cnt].gen <= GL(dl_tls_generation)' failed!
const String _kGlibcError = 'Inconsistency detected by ld.so';

Future<Process> _spawnChromiumProcess(String executable, List<String> args, { String workingDirectory }) async {
  // Keep attempting to launch the browser until one of:
  // - Chrome launched successfully, in which case we just return from the loop.
  // - The tool detected an unretriable Chrome error, in which case we throw ToolExit.
  while (true) {
    final Process process = await Process.start(executable, args, workingDirectory: workingDirectory);

    process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
        print('[CHROME STDOUT]: $line');
      });

    // Wait until the DevTools are listening before trying to connect. This is
    // only required for flutter_test --platform=chrome and not flutter run.
    bool hitGlibcBug = false;
    await process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .map((String line) {
        print('[CHROME STDERR]:$line');
        if (line.contains(_kGlibcError)) {
          hitGlibcBug = true;
        }
        return line;
      })
      .firstWhere((String line) => line.startsWith('DevTools listening'), orElse: () {
        if (hitGlibcBug) {
          print(
            'Encountered glibc bug https://sourceware.org/bugzilla/show_bug.cgi?id=19329. '
            'Will try launching browser again.',
          );
          return null;
        }
        print('Failed to launch browser. Command used to launch it: ${args.join(' ')}');
        throw Exception(
          'Failed to launch browser. Make sure you are using an up-to-date '
          'Chrome or Edge. Otherwise, consider using -d web-server instead '
          'and filing an issue at https://github.com/flutter/flutter/issues.',
        );
      });

    if (!hitGlibcBug) {
      return process;
    }

    // A precaution that avoids accumulating browser processes, in case the
    // glibc bug doesn't cause the browser to quit and we keep looping and
    // launching more processes.
    process.exitCode.timeout(const Duration(seconds: 1), onTimeout: () {
      process.kill();
      return null;
    });
  }
}

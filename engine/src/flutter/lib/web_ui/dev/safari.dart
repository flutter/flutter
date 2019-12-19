// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'environment.dart';

import 'package:path/path.dart' as path;
import 'package:pedantic/pedantic.dart';

import 'package:test_core/src/util/io.dart'; // ignore: implementation_imports

import 'browser.dart';
import 'safari_installation.dart';
import 'common.dart';

/// A class for running an instance of Safari.
///
/// Most of the communication with the browser is expected to happen via HTTP,
/// so this exposes a bare-bones API. The browser starts as soon as the class is
/// constructed, and is killed when [close] is called.
///
/// Any errors starting or running the process are reported through [onExit].
class Safari extends Browser {
  @override
  final name = 'Safari';

  static String version;

  /// Starts a new instance of Safari open to the given [url], which may be a
  /// [Uri] or a [String].
  factory Safari(Uri url, {bool debug = false}) {
    version = SafariArgParser.instance.version;

    assert(version != null);
    return Safari._(() async {
      // TODO(nurhan): Configure info log for LUCI.
      final BrowserInstallation installation = await getOrInstallSafari(
        version,
        infoLog: DevNull(),
      );

      // Safari will only open files (not general URLs) via the command-line
      // API, so we create a dummy file to redirect it to the page we actually
      // want it to load.
      final Directory redirectDir = Directory(
        path.join(environment.webUiDartToolDir.path),
      );
      final redirect = path.join(redirectDir.path, 'redirect.html');
      File(redirect).writeAsStringSync(
          '<script>location = ' + jsonEncode(url.toString()) + '</script>');

      var process =
          await Process.start(installation.executable, [redirect] /* args */);

      unawaited(process.exitCode
          .then((_) => File(redirect).deleteSync(recursive: true)));

      return process;
    });
  }

  Safari._(Future<Process> startBrowser()) : super(startBrowser);
}

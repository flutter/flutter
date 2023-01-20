// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library observatory_sky_shell_launcher;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ShellProcess {
  final Completer<Uri> _observatoryUriCompleter = Completer<Uri>();
  final Process _process;

  ShellProcess(this._process) {
    // Scan stdout and scrape the Observatory Uri.
    _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      final uri = _extractVMServiceUri(line);
      if (uri != null) {
        _observatoryUriCompleter.complete(uri);
      }
    });
  }

  Future<bool> kill() async {
    return _process.kill();
  }

  Future<Uri> waitForObservatory() async {
    return _observatoryUriCompleter.future;
  }

  Uri? _extractVMServiceUri(String str) {
    final listeningMessageRegExp = RegExp(
      r'(?:Observatory|The Dart VM service is) listening on ((http|//)[a-zA-Z0-9:/=_\-\.\[\]]+)',
    );
    final match = listeningMessageRegExp.firstMatch(str);
    if (match != null) {
      return Uri.parse(match[1]!);
    }
    return null;
  }
}

class ShellLauncher {
  final List<String> args = <String>[
    '--observatory-port=0',
    '--non-interactive',
    '--run-forever',
    '--disable-service-auth-codes',
  ];
  final String shellExecutablePath;
  final String mainDartPath;
  final bool startPaused;

  ShellLauncher(this.shellExecutablePath, this.mainDartPath, this.startPaused,
      List<String> extraArgs) {
    args.addAll(extraArgs);
    args.add(mainDartPath);
  }

  Future<ShellProcess?> launch() async {
    try {
      final List<String> shellArguments = <String>[];
      if (startPaused) {
        shellArguments.add('--start-paused');
      }
      shellArguments.addAll(args);
      print('Launching $shellExecutablePath $shellArguments');
      final Process process =
          await Process.start(shellExecutablePath, shellArguments);
      return ShellProcess(process);
    } catch (e) {
      print('Error launching shell: $e');
      return null;
    }
  }
}

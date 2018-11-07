// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library observatory_sky_shell_launcher;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ShellProcess {
  final Completer<Uri> _observatoryUriCompleter = new Completer<Uri>();
  final Process _process;

  ShellProcess(this._process) : assert(_process != null) {
    // Scan stdout and scrape the Observatory Uri.
    _process.stdout.transform(utf8.decoder)
                   .transform(const LineSplitter()).listen((String line) {
      const String observatoryUriPrefix = 'Observatory listening on ';
      if (line.startsWith(observatoryUriPrefix)) {
        print(line);
        final Uri uri = Uri.parse(line.substring(observatoryUriPrefix.length));
        _observatoryUriCompleter.complete(uri);
      }
    });
  }

  Future<bool> kill() async {
    if (_process == null) {
      return false;
    }
    return _process.kill();
  }

  Future<Uri> waitForObservatory() async {
    return _observatoryUriCompleter.future;
  }
}

class ShellLauncher {
  final List<String> args = <String>[
    '--observatory-port=0',
    '--non-interactive',
    '--run-forever',
  ];
  final String shellExecutablePath;
  final String mainDartPath;
  final bool startPaused;

  ShellLauncher(this.shellExecutablePath,
                this.mainDartPath,
                this.startPaused,
                List<String> extraArgs) {
    if (extraArgs is List) {
      args.addAll(extraArgs);
    }
    args.add(mainDartPath);
  }

  Future<ShellProcess> launch() async {
    try {
      final List<String> shellArguments = <String>[];
      if (startPaused) {
        shellArguments.add('--start-paused');
      }
      shellArguments.addAll(args);
      print('Launching $shellExecutablePath $shellArguments');
      final Process process = await Process.start(shellExecutablePath, shellArguments);
      return new ShellProcess(process);
    } catch (e) {
      print('Error launching shell: $e');
    }
    return null;
  }
}

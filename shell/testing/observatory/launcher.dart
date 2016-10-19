// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library observatory_sky_shell_launcher;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ShellProcess {
  final Completer _observatoryUriCompleter = new Completer();
  final Process _process;

  ShellProcess(this._process) {
    assert(_process != null);
    // Scan stdout and scrape the Observatory Uri.
    _process.stdout.transform(UTF8.decoder)
                   .transform(new LineSplitter()).listen((line) {
      const String observatoryUriPrefix = 'Observatory listening on ';
      if (line.startsWith(observatoryUriPrefix)) {
        print(line);
        Uri uri = Uri.parse(line.substring(observatoryUriPrefix.length));
        _observatoryUriCompleter.complete(uri);
      }
    });
  }

  Future kill() async {
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
  final List<String> args = [
    '--observatory-port=0',
    '--non-interactive',
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
      List<String> shellArguments = [];
      if (startPaused) {
        shellArguments.add('--start-paused');
      }
      shellArguments.addAll(args);
      print('Launching $shellExecutablePath $shellArguments');
      var process = await Process.start(shellExecutablePath, shellArguments);
      return new ShellProcess(process);
    } catch (e) {
      print('Error launching shell: $e');
    }
    return null;
  }
}

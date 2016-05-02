// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Process daemon;

// To use, start from the console and enter:
//   version: print version
//   shutdown: terminate the server
//   start: start an app
//   stopAll: stop any running app
//   devices: list devices

Future<Null> main() async {
  daemon = await Process.start('dart', <String>['bin/flutter_tools.dart', 'daemon']);
  print('daemon process started, pid: ${daemon.pid}');

  daemon.stdout
    .transform(UTF8.decoder)
    .transform(const LineSplitter())
    .listen((String line) => print('<== $line'));
  daemon.stderr.listen((dynamic data) => stderr.add(data));

  stdout.write('> ');
  stdin.transform(UTF8.decoder).transform(const LineSplitter()).listen((String line) {
    if (line == 'version' || line == 'v') {
      _send(<String, dynamic>{'method': 'daemon.version'});
    } else if (line == 'shutdown' || line == 'q') {
      _send(<String, dynamic>{'method': 'daemon.shutdown'});
    } else if (line == 'start') {
      _send(<String, dynamic>{'method': 'app.start'});
    } else if (line == 'stopAll') {
      _send(<String, dynamic>{'method': 'app.stopAll'});
    } else if (line == 'devices') {
      _send(<String, dynamic>{'method': 'device.getDevices'});
    } else {
      print('command not understood: $line');
    }
    stdout.write('> ');
  });

  daemon.exitCode.then((int code) {
    print('daemon exiting ($code)');
    exit(code);
  });
}

int id = 0;

void _send(Map<String, dynamic> map) {
  map['id'] = id++;
  String str = '[${JSON.encode(map)}]';
  daemon.stdin.writeln(str);
  print('==> $str');
}

// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'utils.dart';

void _checkExitCode(int code) {
  if (code != 0) {
    throw Exception(
      'Unexpected exit code = $code!',
    );
  }
}

Future<void> _execAndCheck(String executable, List<String> args) async {
  _checkExitCode(await exec(executable, args));
}

// Measure the CPU/GPU percentage for [duration] while a Flutter app is running
// on an iOS device (e.g., right after a Flutter driver test has finished, which
// doesn't close the Flutter app, and the Flutter app has an indefinite
// animation). The return should have a format like the following json
// ```
// {"gpu_percentage":12.6,"cpu_percentage":18.15}
// ```
Future<Map<String, dynamic>> measureIosCpuGpu({
    Duration duration = const Duration(seconds: 10),
    String deviceId,
}) async {
  await _execAndCheck('pub', <String>[
    'global',
    'activate',
    'gauge',
    '0.1.4',
  ]);

  await _execAndCheck('pub', <String>[
    'global',
    'run',
    'gauge',
    'ioscpugpu',
    'new',
    if (deviceId != null) ...<String>['-w', deviceId],
    '-l',
    '${duration.inMilliseconds}',
  ]);
  return json.decode(file('$cwd/result.json').readAsStringSync());
}

Future<String> dylibSymbols(String pathToDylib) {
  return eval('nm', <String>['-g', pathToDylib]);
}

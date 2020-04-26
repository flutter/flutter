// Copyright 2014 The Flutter Authors. All rights reserved.
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
    '0.1.5',
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
  return json.decode(file('$cwd/result.json').readAsStringSync()) as Map<String, dynamic>;
}

Future<String> dylibSymbols(String pathToDylib) {
  return eval('nm', <String>['-g', pathToDylib]);
}

Future<String> fileType(String pathToBinary) {
  return eval('file', <String>[pathToBinary]);
}

Future<bool> containsBitcode(String pathToBinary) async {
  // See: https://stackoverflow.com/questions/32755775/how-to-check-a-static-library-is-built-contain-bitcode
  final String loadCommands = await eval('otool', <String>[
    '-l',
    pathToBinary,
  ]);
  if (!loadCommands.contains('__LLVM')) {
    return false;
  }
  // Presence of the section may mean a bitcode marker was embedded (size=1), but there is no content.
  if (!loadCommands.contains('size 0x0000000000000001')) {
    return true;
  }
  // Check the false positives: size=1 wasn't referencing the __LLVM section.

  bool emptyBitcodeMarkerFound = false;
  //  Section
  //  sectname __bundle
  //  segname __LLVM
  //  addr 0x003c4000
  //  size 0x0042b633
  //  offset 3932160
  //  ...
  final List<String> lines = LineSplitter.split(loadCommands).toList();
  lines.asMap().forEach((int index, String line) {
    if (line.contains('segname __LLVM') && lines.length - index - 1 > 3) {
      final String emptyBitcodeMarker = lines
        .skip(index - 1)
        .take(3)
        .firstWhere(
          (String line) => line.contains(' size 0x0000000000000001'),
          orElse: () => null,
      );
      if (emptyBitcodeMarker != null) {
        emptyBitcodeMarkerFound = true;
        return;
      }
    }
  });
  return !emptyBitcodeMarkerFound;
}

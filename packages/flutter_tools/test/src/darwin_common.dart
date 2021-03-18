// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert';

import 'package:process/process.dart';
import 'package:flutter_tools/src/base/io.dart';

bool containsBitcode(String pathToBinary, ProcessManager processManager) {
  // See: https://stackoverflow.com/questions/32755775/how-to-check-a-static-library-is-built-contain-bitcode
  final ProcessResult result = processManager.runSync(<String>[
    'otool',
    '-l',
    '-arch',
    'arm64',
    pathToBinary,
  ]);
  final String loadCommands = result.stdout as String;
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
      final String emptyBitcodeMarker =
      lines.skip(index - 1).take(4).firstWhere(
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

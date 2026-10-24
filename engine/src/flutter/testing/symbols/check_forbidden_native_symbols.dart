// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

/// Symbols pulled in by `std::format` and `libc++`'s Ryu floating-point tables
/// (~200 KiB in engine binaries). Use `std::stringstream` or `fml::StringPrintf`
/// instead.
const List<String> forbiddenSymbolSubstrings = <String>[
  'std::__fl::__format',
  'std::__fl::vformat',
  'std::__fl::__vformat_to',
  'std::__fl::__d2fixed_buffered_n',
  'std::__fl::__d2s_buffered_n',
  'std::__fl::__f2s_buffered_n',
];

/// Checks [binaryPath] using `llvm-nm` at [nmPath] and returns `true` if no
/// forbidden symbols are defined in the binary.
bool checkForbiddenNativeSymbols({required String nmPath, required String binaryPath}) {
  final ProcessResult nmResult = Process.runSync(nmPath, <String>[
    '--defined-only',
    '-C',
    binaryPath,
  ]);
  if (nmResult.exitCode != 0) {
    stderr.writeln(
      'ERROR: failed to execute "$nmPath --defined-only -C $binaryPath":\n'
      '${nmResult.stderr}',
    );
    return false;
  }

  final found = <String>[];
  for (final String line in LineSplitter.split(nmResult.stdout as String)) {
    for (final String pattern in forbiddenSymbolSubstrings) {
      if (line.contains(pattern)) {
        found.add(line);
        break;
      }
    }
  }

  if (found.isNotEmpty) {
    stderr.writeln('ERROR: $binaryPath contains forbidden std::format / Ryu symbols:');
    for (final String symbol in found.take(20)) {
      stderr.writeln('  - $symbol');
    }
    if (found.length > 20) {
      stderr.writeln('  ... and ${found.length - 20} more.');
    }
    stderr.writeln('Use std::stringstream or fml::StringPrintf instead of std::format.');
    return false;
  }

  return true;
}

void _printUsage() {
  stderr.writeln(
    'Usage: dart check_forbidden_native_symbols.dart '
    '--nm <path> --library <path> [--stamp <path>]',
  );
}

void main(List<String> arguments) {
  String? nmPath;
  String? binaryPath;
  String? stampPath;

  for (var i = 0; i < arguments.length; i++) {
    final String arg = arguments[i];
    if ((arg == '--nm' || arg == '--library' || arg == '--binary' || arg == '--stamp') &&
        i + 1 < arguments.length) {
      final String value = arguments[++i];
      switch (arg) {
        case '--nm':
          nmPath = value;
        case '--library' || '--binary':
          binaryPath = value;
        case '--stamp':
          stampPath = value;
      }
    } else if (arg.startsWith('--nm=')) {
      nmPath = arg.substring('--nm='.length);
    } else if (arg.startsWith('--library=')) {
      binaryPath = arg.substring('--library='.length);
    } else if (arg.startsWith('--binary=')) {
      binaryPath = arg.substring('--binary='.length);
    } else if (arg.startsWith('--stamp=')) {
      stampPath = arg.substring('--stamp='.length);
    } else {
      stderr.writeln('ERROR: unknown or incomplete argument: $arg');
      _printUsage();
      exit(1);
    }
  }

  if (nmPath == null || binaryPath == null) {
    _printUsage();
    exit(1);
  }

  if (!checkForbiddenNativeSymbols(nmPath: nmPath, binaryPath: binaryPath)) {
    exit(1);
  }

  if (stampPath != null) {
    File(stampPath).writeAsStringSync('');
  }
}

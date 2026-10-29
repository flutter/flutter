// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

/// Template symbols instantiated from `<format>`. These are only emitted when a
/// translation unit uses `std::format`, so they are forbidden in both optimized
/// and unoptimized builds.
const List<String> forbiddenFormatSymbolSubstrings = <String>[
  'std::__fl::__format',
  'std::__fl::vformat',
  'std::__fl::__vformat_to',
];

/// Out-of-line `libc++` Ryu floating-point table symbols (~200 KiB) defined in
/// `libcxx/src/ryu/*.cpp` and referenced by `libcxx/src/charconv.cpp`.
///
/// Because `libcxx` is linked as a `source_set`, these symbols remain present
/// in unoptimized (`is_debug`) builds where linker dead-code stripping
/// (`--gc-sections` / `-dead_strip`) is disabled, and are stripped in optimized
/// builds unless engine code pulls in floating-point `std::to_chars` or
/// `std::format`.
const List<String> forbiddenRyuSymbolSubstrings = <String>[
  'std::__fl::__d2fixed_buffered_n',
  'std::__fl::__d2s_buffered_n',
  'std::__fl::__f2s_buffered_n',
];

/// Checks [binaryPath] using `llvm-nm` at [nmPath] and returns `true` if no
/// forbidden symbols are defined in the binary.
bool checkForbiddenNativeSymbols({
  required String nmPath,
  required String binaryPath,
  bool unoptimized = false,
}) {
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

  final forbiddenSubstrings = <String>[
    ...forbiddenFormatSymbolSubstrings,
    if (!unoptimized) ...forbiddenRyuSymbolSubstrings,
  ];

  final found = <String>[];
  for (final String line in LineSplitter.split(nmResult.stdout as String)) {
    for (final pattern in forbiddenSubstrings) {
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
    stderr.writeln('Use absl::StrCat or absl::StrFormat instead of std::format.');
    return false;
  }

  return true;
}

void _printUsage() {
  stderr.writeln(
    'Usage: dart check_forbidden_native_symbols.dart '
    '--nm <path> --library <path> [--stamp <path>] [--unoptimized]',
  );
}

void main(List<String> arguments) {
  String? nmPath;
  String? binaryPath;
  String? stampPath;
  var unoptimized = false;

  for (var i = 0; i < arguments.length; i++) {
    final String arg = arguments[i];
    if (arg == '--unoptimized') {
      unoptimized = true;
    } else if ((arg == '--nm' || arg == '--library' || arg == '--binary' || arg == '--stamp') &&
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

  if (!checkForbiddenNativeSymbols(
    nmPath: nmPath,
    binaryPath: binaryPath,
    unoptimized: unoptimized,
  )) {
    exit(1);
  }

  if (stampPath != null) {
    File(stampPath).writeAsStringSync('');
  }
}

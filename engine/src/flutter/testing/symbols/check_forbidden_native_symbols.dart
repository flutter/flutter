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

/// Prefixes of the symbols that libunwind defines: the `_Unwind_*` ABI, the
/// `unw_*` API and its `__unw_*` implementation, and the
/// `__register_frame*`/`__deregister_frame*` frame registration functions.
const List<String> unwindSymbolPrefixes = <String>[
  '_Unwind_',
  'unw_',
  '__unw_',
  '__register_frame',
  '__deregister_frame',
];

/// Checks the dynamic symbol table of the ELF shared library at [binaryPath]
/// using `llvm-nm` at [nmPath] and returns `true` if it doesn't export any
/// unwinder symbols.
bool checkNoExportedUnwindSymbols({required String nmPath, required String binaryPath}) {
  final ProcessResult nmResult = Process.runSync(nmPath, <String>[
    '--dynamic',
    '--defined-only',
    binaryPath,
  ]);
  if (nmResult.exitCode != 0) {
    stderr.writeln(
      'ERROR: failed to execute "$nmPath --dynamic --defined-only $binaryPath":\n'
      '${nmResult.stderr}',
    );
    return false;
  }

  final found = <String>[
    for (final String line in LineSplitter.split(nmResult.stdout as String))
      if (unwindSymbolPrefixes.any(line.trim().split(RegExp(r'\s+')).last.startsWith)) line,
  ];

  if (found.isNotEmpty) {
    stderr.writeln('ERROR: $binaryPath exports unwinder symbols:');
    for (final symbol in found) {
      stderr.writeln('  - $symbol');
    }
    stderr.writeln(
      "These interpose on the host process's unwinder and break C++ exceptions "
      'in plugins. Hide them, for example with -Wl,--exclude-libs. ',
    );
    return false;
  }

  return true;
}

void _printUsage() {
  stderr.writeln(
    'Usage: dart check_forbidden_native_symbols.dart '
    '--nm <path> --library <path> [--stamp <path>] [--unoptimized] '
    '[--forbid-exported-unwind-symbols]',
  );
}

void main(List<String> arguments) {
  String? nmPath;
  String? binaryPath;
  String? stampPath;
  var unoptimized = false;
  var forbidExportedUnwindSymbols = false;

  for (var i = 0; i < arguments.length; i++) {
    final String arg = arguments[i];
    if (arg == '--unoptimized') {
      unoptimized = true;
    } else if (arg == '--forbid-exported-unwind-symbols') {
      forbidExportedUnwindSymbols = true;
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

  bool passed = checkForbiddenNativeSymbols(
    nmPath: nmPath,
    binaryPath: binaryPath,
    unoptimized: unoptimized,
  );
  if (forbidExportedUnwindSymbols) {
    passed = checkNoExportedUnwindSymbols(nmPath: nmPath, binaryPath: binaryPath) && passed;
  }
  if (!passed) {
    exit(1);
  }

  if (stampPath != null) {
    File(stampPath).writeAsStringSync('');
  }
}

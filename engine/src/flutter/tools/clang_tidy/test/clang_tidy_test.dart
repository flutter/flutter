// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io show File, Platform, stderr;

import 'package:clang_tidy/clang_tidy.dart';
import 'package:clang_tidy/src/command.dart';
import 'package:litetest/litetest.dart';
import 'package:process_runner/process_runner.dart';

Future<int> main(List<String> args) async {
  if (args.isEmpty) {
    io.stderr.writeln(
      'Usage: clang_tidy_test.dart [path/to/compile_commands.json]',
    );
    return 1;
  }
  final String buildCommands = args[0];

  test('--help gives help', () async {
    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy.fromCommandLine(
      <String>[
      '--help',
      ],
      outSink: outBuffer,
      errSink: errBuffer,
    );

    final int result = await clangTidy.run();

    expect(clangTidy.options.help, isTrue);
    expect(result, equals(0));
    expect(errBuffer.toString(), contains('Usage: '));
  });

  test('Error when --compile-commands and --target-variant are used together', () async {
    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy.fromCommandLine(
      <String>[
        '--compile-commands',
        '/unused',
        '--target-variant',
        'unused'
      ],
      outSink: outBuffer,
      errSink: errBuffer,
    );

    final int result = await clangTidy.run();

    expect(clangTidy.options.help, isFalse);
    expect(result, equals(1));
    expect(errBuffer.toString(), contains(
      'ERROR: --compile-commands option cannot be used with --target-variant.',
    ));
  });

  test('Error when --compile-commands and --src-dir are used together', () async {
    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy.fromCommandLine(
      <String>[
        '--compile-commands',
        '/unused',
        '--src-dir',
        '/unused',
      ],
      outSink: outBuffer,
      errSink: errBuffer,
    );

    final int result = await clangTidy.run();

    expect(clangTidy.options.help, isFalse);
    expect(result, equals(1));
    expect(errBuffer.toString(), contains(
      'ERROR: --compile-commands option cannot be used with --src-dir.',
    ));
  });

  test('Error when --compile-commands path does not exist', () async {
    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy.fromCommandLine(
      <String>[
        '--compile-commands',
        '/does/not/exist',
      ],
      outSink: outBuffer,
      errSink: errBuffer,
    );

    final int result = await clangTidy.run();

    expect(clangTidy.options.help, isFalse);
    expect(result, equals(1));
    expect(errBuffer.toString(), contains(
      "ERROR: Build commands path /does/not/exist doesn't exist.",
    ));
  });

  test('Error when --src-dir path does not exist, uses target variant in path', () async {
    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy.fromCommandLine(
      <String>[
        '--src-dir',
        '/does/not/exist',
        '--target-variant',
        'ios_debug_unopt',
      ],
      outSink: outBuffer,
      errSink: errBuffer,
    );

    final int result = await clangTidy.run();

    expect(clangTidy.options.help, isFalse);
    expect(result, equals(1));
    expect(errBuffer.toString(), contains(
      "ERROR: Build commands path /does/not/exist/out/ios_debug_unopt/compile_commands.json doesn't exist.",
    ));
  });

  test('lintAll=true checks all files', () async {
    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy(
      buildCommandsPath: io.File(buildCommands),
      lintAll: true,
      outSink: outBuffer,
      errSink: errBuffer,
    );
    final List<io.File> fileList = await clangTidy.computeChangedFiles();
    expect(fileList.length, greaterThan(1000));
  });

  test('lintAll=false does not check all files', () async {
    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy(
      buildCommandsPath: io.File(buildCommands),
      outSink: outBuffer,
      errSink: errBuffer,
    );
    final List<io.File> fileList = await clangTidy.computeChangedFiles();
    expect(fileList.length, lessThan(300));
  });

  test('No Commands are produced when no files changed', () async {
    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy(
      buildCommandsPath: io.File(buildCommands),
      lintAll: true,
      outSink: outBuffer,
      errSink: errBuffer,
    );
    const String filePath = '/path/to/a/source_file.cc';
    final List<dynamic> buildCommandsData = <Map<String, dynamic>>[
      <String, dynamic>{
        'directory': '/unused',
        'command': '../../buildtools/mac-x64/clang/bin/clang $filePath',
        'file': filePath,
      },
    ];
    final List<Command> commands = await clangTidy.getLintCommandsForChangedFiles(
      buildCommandsData,
      <io.File>[],
    );

    expect(commands, isEmpty);
  });

  test('A Command is produced when a file is changed', () async {
    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy(
      buildCommandsPath: io.File(buildCommands),
      lintAll: true,
      outSink: outBuffer,
      errSink: errBuffer,
    );

    // This file needs to exist, and be UTF8 line-parsable.
    final String filePath = io.Platform.script.path;
    final List<dynamic> buildCommandsData = <Map<String, dynamic>>[
      <String, dynamic>{
        'directory': '/unused',
        'command': '../../buildtools/mac-x64/clang/bin/clang $filePath',
        'file': filePath,
      },
    ];
    final List<Command> commands = await clangTidy.getLintCommandsForChangedFiles(
      buildCommandsData,
      <io.File>[io.File(filePath)],
    );

    expect(commands, isNotEmpty);
    final Command command = commands.first;
    expect(command.tidyPath, contains('clang/bin/clang-tidy'));
    final WorkerJob jobNoFix = command.createLintJob(null, false);
    expect(jobNoFix.command, <String>[
      '../../buildtools/mac-x64/clang/bin/clang-tidy',
      filePath,
      '--',
      '',
      filePath,
    ]);

    final WorkerJob jobWithFix = command.createLintJob(null, true);
    expect(jobWithFix.command, <String>[
      '../../buildtools/mac-x64/clang/bin/clang-tidy',
      filePath,
      '--fix',
      '--format-style=file',
      '--',
      '',
      filePath,
    ]);
  });

  test('Command getLintAction flags third_party files', () async {
    final LintAction lintAction = await Command.getLintAction(
      '/some/file/in/a/third_party/dependency',
    );

    expect(lintAction, equals(LintAction.skipThirdParty));
  });

  test('Command getLintAction flags missing files', () async {
    final LintAction lintAction = await Command.getLintAction(
      '/does/not/exist',
    );

    expect(lintAction, equals(LintAction.skipMissing));
  });

  test('Command getLintActionFromContents flags FLUTTER_NOLINT', () async {
    final LintAction lintAction = await Command.lintActionFromContents(
      Stream<String>.fromIterable(<String>[
        '// Copyright 2013 The Flutter Authors. All rights reserved.\n',
        '// Use of this source code is governed by a BSD-style license that can be\n',
        '// found in the LICENSE file.\n',
        '\n',
        '// FLUTTER_NOLINT: https://github.com/flutter/flutter/issues/68332\n',
        '\n',
        '#include "flutter/shell/version/version.h"\n',
      ]),
    );

    expect(lintAction, equals(LintAction.skipNoLint));
  });

  test('Command getLintActionFromContents flags malformed FLUTTER_NOLINT', () async {
    final LintAction lintAction = await Command.lintActionFromContents(
      Stream<String>.fromIterable(<String>[
        '// Copyright 2013 The Flutter Authors. All rights reserved.\n',
        '// Use of this source code is governed by a BSD-style license that can be\n',
        '// found in the LICENSE file.\n',
        '\n',
        '// FLUTTER_NOLINT: https://gir/flutter/issues/68332\n',
        '\n',
        '#include "flutter/shell/version/version.h"\n',
      ]),
    );

    expect(lintAction, equals(LintAction.failMalformedNoLint));
  });

  test('Command getLintActionFromContents flags that we should lint', () async {
    final LintAction lintAction = await Command.lintActionFromContents(
      Stream<String>.fromIterable(<String>[
        '// Copyright 2013 The Flutter Authors. All rights reserved.\n',
        '// Use of this source code is governed by a BSD-style license that can be\n',
        '// found in the LICENSE file.\n',
        '\n',
        '#include "flutter/shell/version/version.h"\n',
      ]),
    );

    expect(lintAction, equals(LintAction.lint));
  });

  return 0;
}

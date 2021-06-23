// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io show Directory, File, Platform, stderr;

import 'package:clang_tidy/clang_tidy.dart';
import 'package:clang_tidy/src/command.dart';
import 'package:litetest/litetest.dart';

Future<int> main(List<String> args) async {
  if (args.length < 2) {
    io.stderr.writeln(
      'Usage: clang_tidy_test.dart [build commands] [repo root]',
    );
    return 1;
  }
  final String buildCommands = args[0];
  final String repoRoot = args[1];

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

  test('Error when --compile-commands is missing', () async {
    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy.fromCommandLine(
      <String>[],
      outSink: outBuffer,
      errSink: errBuffer,
    );

    final int result = await clangTidy.run();

    expect(clangTidy.options.help, isFalse);
    expect(result, equals(1));
    expect(errBuffer.toString(), contains(
      'ERROR: The --compile-commands argument is required.',
    ));
  });

  test('Error when --repo is missing', () async {
    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy.fromCommandLine(
      <String>[
        '--compile-commands',
        '/unused',
      ],
      outSink: outBuffer,
      errSink: errBuffer,
    );

    final int result = await clangTidy.run();

    expect(clangTidy.options.help, isFalse);
    expect(result, equals(1));
    expect(errBuffer.toString(), contains(
      'ERROR: The --repo argument is required.',
    ));
  });

  test('Error when --compile-commands path does not exist', () async {
    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy.fromCommandLine(
      <String>[
        '--compile-commands',
        '/does/not/exist',
        '--repo',
        '/unused',
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

  test('Error when --repo path does not exist', () async {
    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy.fromCommandLine(
      <String>[
        '--compile-commands',
        // This just has to exist.
        io.Platform.executable,
        '--repo',
        '/does/not/exist',
      ],
      outSink: outBuffer,
      errSink: errBuffer,
    );

    final int result = await clangTidy.run();

    expect(clangTidy.options.help, isFalse);
    expect(result, equals(1));
    expect(errBuffer.toString(), contains(
      "ERROR: Repo path /does/not/exist doesn't exist.",
    ));
  });

  test('lintAll=true checks all files', () async {
    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy(
      buildCommandsPath: io.File(buildCommands),
      repoPath: io.Directory(repoRoot),
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
      repoPath: io.Directory(repoRoot),
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
      repoPath: io.Directory(repoRoot),
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
    final List<Command> commands = clangTidy.getLintCommandsForChangedFiles(
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
      repoPath: io.Directory(repoRoot),
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
    final List<Command> commands = clangTidy.getLintCommandsForChangedFiles(
      buildCommandsData,
      <io.File>[io.File(filePath)],
    );

    expect(commands, isNotEmpty);
    expect(commands.first.tidyPath, contains('clang/bin/clang-tidy'));
  });

  test('Command getLintAction flags third_party files', () async {
    final LintAction lintAction = await Command.getLintAction(
      '/some/file/in/a/third_party/dependency',
    );

    expect(lintAction, equals(LintAction.skipThirdParty));
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

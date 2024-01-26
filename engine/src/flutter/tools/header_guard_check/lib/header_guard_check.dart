// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'src/header_file.dart';

/// Checks C++ header files for header guards.
@immutable
final class HeaderGuardCheck {
  /// Creates a new header guard checker.
  const HeaderGuardCheck({
    required this.source,
    required this.exclude,
    this.include = const <String>[],
    this.fix = false,
  });

  /// Parses the command line arguments and creates a new header guard checker.
  factory HeaderGuardCheck.fromCommandLine(List<String> arguments) {
    final ArgResults argResults = _parser.parse(arguments);
    return HeaderGuardCheck(
      source: Engine.fromSrcPath(argResults['root'] as String),
      include: argResults['include'] as List<String>,
      exclude: argResults['exclude'] as List<String>,
      fix: argResults['fix'] as bool,
    );
  }

  /// Engine source root.
  final Engine source;

  /// Whether to automatically fix most header guards.
  final bool fix;

  /// Path directories to include in the check.
  final List<String> include;

  /// Path directories to exclude from the check.
  final List<String> exclude;

  /// Runs the header guard check.
  Future<int> run() async {
    final List<HeaderFile> badFiles = _checkFiles(_findIncludedHeaderFiles()).toList();

    if (badFiles.isNotEmpty) {
      io.stdout.writeln('The following ${badFiles.length} files have invalid header guards:');
      for (final HeaderFile headerFile in badFiles) {
        io.stdout.writeln('  ${headerFile.path}');
      }

      // If we're fixing, fix the files.
      if (fix) {
        for (final HeaderFile headerFile in badFiles) {
          headerFile.fix(engineRoot: source.flutterDir.path);
        }

        io.stdout.writeln('Fixed ${badFiles.length} files.');
        return 0;
      }

      return 1;
    }

    return 0;
  }

  Iterable<io.File> _findIncludedHeaderFiles() sync* {
    final io.Directory dir = source.flutterDir;
    for (final io.FileSystemEntity entity in dir.listSync(recursive: true)) {
      if (entity is! io.File) {
        continue;
      }

      if (!entity.path.endsWith('.h')) {
        continue;
      }

      if (!_isIncluded(entity.path) || _isExcluded(entity.path)) {
        continue;
      }

      yield entity;
    }
  }

  bool _isIncluded(String path) {
    for (final String includePath in include) {
      final String relativePath = p.relative(includePath, from: source.flutterDir.path);
      if (p.isWithin(relativePath, path) || p.equals(relativePath, path)) {
        return true;
      }
    }
    return include.isEmpty;
  }

  bool _isExcluded(String path) {
    for (final String excludePath in exclude) {
      final String relativePath = p.relative(excludePath, from: source.flutterDir.path);
      if (p.isWithin(relativePath, path) || p.equals(relativePath, path)) {
        return true;
      }
    }
    return false;
  }

  Iterable<HeaderFile> _checkFiles(Iterable<io.File> headers) sync* {
    for (final io.File header in headers) {
      final HeaderFile headerFile = HeaderFile.parse(header.path);
      if (headerFile.pragmaOnce != null) {
        io.stderr.writeln(headerFile.pragmaOnce!.message('Unexpected #pragma once'));
        yield headerFile;
      }

      if (headerFile.guard == null) {
        io.stderr.writeln('Missing header guard in ${headerFile.path}');
        yield headerFile;
      }

      final String expectedGuard = headerFile.computeExpectedName(engineRoot: source.flutterDir.path);
      if (headerFile.guard!.ifndefValue != expectedGuard) {
        io.stderr.writeln(headerFile.guard!.ifndefSpan!.message('Expected #ifndef $expectedGuard'));
        yield headerFile;
      }
      if (headerFile.guard!.defineValue != expectedGuard) {
        io.stderr.writeln(headerFile.guard!.defineSpan!.message('Expected #define $expectedGuard'));
        yield headerFile;
      }
      if (headerFile.guard!.endifValue != expectedGuard) {
        io.stderr.writeln(headerFile.guard!.endifSpan!.message('Expected #endif // $expectedGuard'));
        yield headerFile;
      }
    }
  }
}

final Engine? _engine = Engine.tryFindWithin(p.dirname(p.fromUri(io.Platform.script)));

final ArgParser _parser = ArgParser()
  ..addFlag(
    'fix',
    help: 'Automatically fixes most header guards.',
  )
  ..addOption(
    'root',
    abbr: 'r',
    help: 'Path to the engine source root.',
    valueHelp: 'path/to/engine/src',
    defaultsTo: _engine?.srcDir.path,
  )
  ..addMultiOption(
    'include',
    abbr: 'i',
    help: 'Paths to include in the check.',
    valueHelp: 'path/to/dir/or/file (relative to the engine root)',
    defaultsTo: <String>[],
  )
  ..addMultiOption(
    'exclude',
    abbr: 'e',
    help: 'Paths to exclude from the check.',
    valueHelp: 'path/to/dir/or/file (relative to the engine root)',
    defaultsTo: _engine != null ? <String>[
      'build',
      'impeller/compiler/code_gen_template.h',
      'prebuilts',
      'third_party',
    ] : null,
  );

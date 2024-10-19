// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: always_specify_types

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';

enum GitRevisionStrategy {
  mergeBase,
  head,
}

final _hashRegex = RegExp(r'^([a-fA-F0-9]+)');

final parser = ArgParser()
  ..addOption(
    'strategy',
    abbr: 's',
    allowed: ['head', 'mergeBase'],
    defaultsTo: 'head',
    allowedHelp: {
      'head': 'hash from git HEAD',
      'mergeBase': 'hash from the merge-base of HEAD and upstream/master',
    },
  )
  ..addFlag('help', abbr: 'h', negatable: false);

Never printHelp({String? error}) {
  if (error != null) {
    stdout.writeln(error);
    stdout.writeln();
  }
  stdout.writeln('''
Calculate the hash signature for the Flutter Engine
${parser.usage}
''');
  exit(error != null ? 1 : 0);
}

Future<int> main(List<String> args) async {
  final ArgResults arguments;
  try {
    arguments = parser.parse(args);
  } catch (e) {
    printHelp(error: '$e');
  }

  if (arguments.wasParsed('help')) {
    printHelp();
  }

  final result = await engineHash(
    (List<String> command) => Process.run(
      command.first,
      command.sublist(1),
      stdoutEncoding: utf8,
    ),
    revisionStrategy: GitRevisionStrategy.values.byName(
      arguments.option('strategy')!,
    ),
  );

  if (result.error != null) {
    stderr.writeln('Error calculating engine hash: ${result.error}');
    return 1;
  }

  stdout.writeln(result.result);

  return 0;
}

/// Returns the hash signature for the engine source code.
Future<({String result, String? error})> engineHash(
  Future<ProcessResult> Function(List<String> command) runProcess, {
  GitRevisionStrategy revisionStrategy = GitRevisionStrategy.mergeBase,
}) async {
  // First figure out the hash we're working with
  final String base;
  switch (revisionStrategy) {
    case GitRevisionStrategy.head:
      base = 'HEAD';
    case GitRevisionStrategy.mergeBase:
      final processResult = await runProcess(
        <String>[
          'git',
          'merge-base',
          'upstream/main',
          'HEAD',
        ],
      );

      if (processResult.exitCode != 0) {
        return (
          result: '',
          error: '''
Unable to find merge-base hash of the repository:
${processResult.stderr}''',
        );
      }

      final baseHash = _hashRegex.matchAsPrefix(processResult.stdout as String);
      if (baseHash == null || baseHash.groupCount != 1) {
        return (
          result: '',
          error: '''
Unable to parse merge-base hash of the repository
${processResult.stdout}''',
        );
      }
      base = baseHash[1]!;
  }

  // List the tree (not the working tree) recursively for the merge-base.
  // This is important for future filtering of files, but also do not include
  // the developer's changes / in flight PRs.
  // The presence `engine` and `DEPS` are signals that you live in a monorepo world.
  final processResult = await runProcess(
    <String>['git', 'ls-tree', '-r', base, 'engine', 'DEPS'],
  );

  if (processResult.exitCode != 0) {
    return (
      result: '',
      error: '''
Unable to list tree
${processResult.stderr}''',
    );
  }

  // Ensure stable line endings so our hash calculation is stable
  final lsTree = processResult.stdout as String;
  if (lsTree.trim().isEmpty) {
    return (
      result: '',
      error: 'Not in a monorepo',
    );
  }

  final treeLines = LineSplitter.split(processResult.stdout as String);

  // We could call `git hash-object --stdin` which would just take the input, calculate the size,
  // and then sha1sum it like: `blob $size\0$string'. However, that can have different line endings.
  // Instead this is equivalent to:
  //     git ls-tree -r $(git merge-base upstream/main HEAD) | <only newlines> | sha1sum
  final output = StreamController<Digest>();
  final sink = sha1.startChunkedConversion(output);
  for (final line in treeLines) {
    sink.add(utf8.encode(line));
    sink.add([0x0a]);
  }
  sink.close();
  final digest = await output.stream.first;

  return (result: '$digest', error: null);
}

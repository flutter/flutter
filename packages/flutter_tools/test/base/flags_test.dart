// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/flags.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

import '../src/common.dart';
import '../src/context.dart';

typedef _TestMethod = FutureOr<void> Function();

void main() {
  Cache.disableLocking();

  Future<void> runCommand(Iterable<String> flags, _TestMethod testMethod) async {
    final List<String> args = <String>['test']..addAll(flags);
    final _TestCommand command = _TestCommand(testMethod);
    await createTestCommandRunner(command).run(args);
  }

  testUsingContext('runCommand works as expected', () async {
    bool testRan = false;
    await runCommand(<String>[], () {
      testRan = true;
    });
    expect(testRan, isTrue);
  });

  group('flags', () {
    testUsingContext('returns null for undefined flags', () async {
      await runCommand(<String>[], () {
        expect(flags['undefined-flag'], isNull);
      });
    });

    testUsingContext('picks up default values', () async {
      await runCommand(<String>[], () {
        expect(flags['verbose'], isFalse);
        expect(flags['flag-defaults-to-false'], isFalse);
        expect(flags['flag-defaults-to-true'], isTrue);
        expect(flags['option-defaults-to-foo'], 'foo');
      });
    });

    testUsingContext('returns null for flags with no default values', () async {
      await runCommand(<String>[], () {
        expect(flags['device-id'], isNull);
        expect(flags['option-no-default'], isNull);
      });
    });

    testUsingContext('picks up explicit values', () async {
      await runCommand(<String>[
        '--verbose',
        '--flag-defaults-to-false',
        '--option-no-default=explicit',
        '--option-defaults-to-foo=qux',
      ], () {
        expect(flags['verbose'], isTrue);
        expect(flags['flag-defaults-to-false'], isTrue);
        expect(flags['option-no-default'], 'explicit');
        expect(flags['option-defaults-to-foo'], 'qux');
      });
    });
  });
}

class _TestCommand extends FlutterCommand {
  _TestCommand(this.testMethod) {
    argParser.addFlag('flag-defaults-to-false', defaultsTo: false);
    argParser.addFlag('flag-defaults-to-true', defaultsTo: true);
    argParser.addOption('option-no-default');
    argParser.addOption('option-defaults-to-foo', defaultsTo: 'foo');
  }

  final _TestMethod testMethod;

  @override
  String get name => 'test';

  @override
  String get description => 'runs a test method';

  @override
  Future<FlutterCommandResult> runCommand() async {
    await testMethod();
    return null;
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/experimental/extension_arg_parser.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

import '../src/context.dart';
import '../src/test_flutter_command_runner.dart';

class _FakeExtensionCommand extends FlutterCommand with ExtensionArgParserMixin {
  _FakeExtensionCommand() {
    argParser.addFlag('test-flag', help: 'A test flag');
  }

  List<String> dynamicOptionNames = <String>[];

  @override
  final String name = 'test-cmd';

  @override
  final String description = 'Test command with dynamic arg parser.';

  @override
  ArgParser createBaseArgParser() => ArgParser(allowTrailingOptions: false);

  @override
  void populateBaseArgParser(ArgParser parser) {
    parser.addOption('base-opt');
  }

  @override
  String? get extensionArgParserCacheKey {
    if (dynamicOptionNames.isEmpty) {
      return null;
    }
    return dynamicOptionNames.join(',');
  }

  @override
  ArgParser buildDynamicArgParser(ArgParser baseParser) {
    final newParser = ArgParser(allowTrailingOptions: baseParser.allowTrailingOptions);
    for (final Option opt in baseParser.options.values) {
      if (opt.isFlag) {
        newParser.addFlag(opt.name, help: opt.help);
      } else {
        newParser.addOption(opt.name, help: opt.help);
      }
    }
    dynamicOptionNames.forEach(newParser.addOption);
    return newParser;
  }

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.success();
}

void main() {
  testUsingContext('ExtensionArgParserMixin builds base parser and avoids recursion', () {
    final cmd = _FakeExtensionCommand();
    createTestCommandRunner(cmd);
    expect(cmd.argParser.options.containsKey('test-flag'), isTrue);
    expect(cmd.argParser.options.containsKey('base-opt'), isTrue);
  }, overrides: <Type, Generator>{OutputPreferences: () => OutputPreferences.test()});

  testUsingContext('ExtensionArgParserMixin lazily rebuilds parser when cache key changes', () {
    final cmd = _FakeExtensionCommand();
    createTestCommandRunner(cmd);
    expect(cmd.argParser.options.containsKey('dynamic-1'), isFalse);

    cmd.dynamicOptionNames = <String>['dynamic-1'];
    expect(cmd.argParser.options.containsKey('dynamic-1'), isTrue);
    final ArgParser cachedParser = cmd.argParser;
    expect(identical(cmd.argParser, cachedParser), isTrue);

    cmd.dynamicOptionNames = <String>['dynamic-1', 'dynamic-2'];
    expect(cmd.argParser.options.containsKey('dynamic-2'), isTrue);
    expect(identical(cmd.argParser, cachedParser), isFalse);
  }, overrides: <Type, Generator>{OutputPreferences: () => OutputPreferences.test()});
}

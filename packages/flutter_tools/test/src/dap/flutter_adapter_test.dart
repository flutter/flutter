// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/debug_adapters/flutter_adapter_args.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  group('flutter adapter', () {
    setUpAll(() {
    Cache.flutterRoot = '/fake/flutter';
  });

    test('includes toolArgs', () async {
      final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(fileSystem: globals.fs, platform: globals.platform);
      final Completer<void> responseCompleter = Completer<void>();

      final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
        cwd: '/project',
        program: 'foo.dart',
        toolArgs: <String>['tool_arg'],
        noDebug: true,
      );

      await adapter.configurationDoneRequest(MockRequest(), null, () {});
      await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
      await responseCompleter.future;

      expect(adapter.executable, equals('/fake/flutter/bin/flutter'));
      expect(adapter.processArgs, contains('tool_arg'));
    });

    group('includes customTool', () {
      test('with no args replaced', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(fileSystem: globals.fs, platform: globals.platform);
        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
          customTool: '/custom/flutter',
          noDebug: true,
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        final Completer<void> responseCompleter = Completer<void>();
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.executable, equals('/custom/flutter'));
        // args should be in-tact
        expect(adapter.processArgs, contains('--machine'));
      });

      test('with all args replaced', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(fileSystem: globals.fs, platform: globals.platform);
        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
          customTool: '/custom/flutter',
          customToolReplacesArgs: 9999, // replaces all built-in args
          noDebug: true,
          toolArgs: <String>['tool_args'], // should still be in args
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        final Completer<void> responseCompleter = Completer<void>();
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.executable, equals('/custom/flutter'));
        // normal built-in args are replaced by customToolReplacesArgs, but
        // user-provided toolArgs are not.
        expect(adapter.processArgs, isNot(contains('--machine')));
        expect(adapter.processArgs, contains('tool_args'));
      });
    });
  });
}

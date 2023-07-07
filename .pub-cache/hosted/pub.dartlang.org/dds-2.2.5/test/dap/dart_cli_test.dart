// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/dap.dart';
import 'package:test/test.dart';

import 'mocks.dart';

main() {
  group('dart cli adapter', () {
    test('includes vmAdditionalArgs', () async {
      final adapter = MockDartCliDebugAdapter();
      final responseCompleter = Completer<void>();
      final request = MockRequest();
      final args = DartLaunchRequestArguments(
        program: 'foo.dart',
        vmAdditionalArgs: ['vm_arg'],
        noDebug: true,
      );

      await adapter.configurationDoneRequest(request, null, () {});
      await adapter.launchRequest(request, args, responseCompleter.complete);
      await responseCompleter.future;

      expect(adapter.executable, equals(Platform.resolvedExecutable));
      expect(adapter.processArgs, containsAllInOrder(['vm_arg', 'foo.dart']));
    });

    test('includes toolArgs', () async {
      final adapter = MockDartCliDebugAdapter();
      final responseCompleter = Completer<void>();
      final request = MockRequest();
      final args = DartLaunchRequestArguments(
        program: 'foo.dart',
        toolArgs: ['tool_arg'],
        noDebug: true,
      );

      await adapter.configurationDoneRequest(request, null, () {});
      await adapter.launchRequest(request, args, responseCompleter.complete);
      await responseCompleter.future;

      expect(adapter.executable, equals(Platform.resolvedExecutable));
      expect(adapter.processArgs, containsAllInOrder(['tool_arg', 'foo.dart']));
    });

    test('includes env', () async {
      final adapter = MockDartCliDebugAdapter();
      final responseCompleter = Completer<void>();
      final request = MockRequest();
      final args = DartLaunchRequestArguments(
        program: 'foo.dart',
        env: {
          'ENV1': 'VAL1',
          'ENV2': 'VAL2',
        },
        noDebug: true,
      );

      await adapter.configurationDoneRequest(request, null, () {});
      await adapter.launchRequest(request, args, responseCompleter.complete);
      await responseCompleter.future;

      expect(adapter.executable, equals(Platform.resolvedExecutable));
      expect(adapter.env!['ENV1'], 'VAL1');
      expect(adapter.env!['ENV2'], 'VAL2');
    });

    group('includes customTool', () {
      test('with no args replaced', () async {
        final adapter = MockDartCliDebugAdapter();
        final responseCompleter = Completer<void>();
        final request = MockRequest();
        final args = DartLaunchRequestArguments(
          program: 'foo.dart',
          customTool: '/custom/dart',
          noDebug: true,
        );

        await adapter.configurationDoneRequest(request, null, () {});
        await adapter.launchRequest(request, args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.executable, equals('/custom/dart'));
        // a standard built-in arg should be present.
        expect(adapter.processArgs, contains('--disable-dart-dev'));
      });

      test('with all args replaced', () async {
        final adapter = MockDartCliDebugAdapter();
        final responseCompleter = Completer<void>();
        final request = MockRequest();
        final args = DartLaunchRequestArguments(
          program: 'foo.dart',
          customTool: '/custom/dart',
          customToolReplacesArgs: 9999, // replaces all built-in args
          noDebug: true,
          toolArgs: ['tool_args'], // should still be in args
        );

        await adapter.configurationDoneRequest(request, null, () {});
        await adapter.launchRequest(request, args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.executable, equals('/custom/dart'));
        // normal built-in args are replaced by customToolReplacesArgs, but
        // user-provided toolArgs are not.
        expect(adapter.processArgs, isNot(contains('--disable-dart-dev')));
        expect(adapter.processArgs, contains('tool_args'));
      });
    });
  });
}

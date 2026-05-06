// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/debug_adapters/flutter_adapter_args.dart';
import 'package:flutter_tools/src/globals.dart' as globals show platform;
import 'package:test/test.dart';

import '../general.shard/dap/mocks.dart';

void main() {
  final platform = FakePlatform.fromPlatform(globals.platform);
  final fsStyle = platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix;
  final expectedFlutterExecutable =
      platform.isWindows ? r'C:\fake\flutter\bin\flutter.bat' : '/fake/flutter/bin/flutter';

  setUpAll(() {
    Cache.flutterRoot = platform.isWindows ? r'C:\fake\flutter' : '/fake/flutter';
  });

  test('launch adapter ignores customTool', () async {
    final adapter = FakeFlutterDebugAdapter(
      fileSystem: MemoryFileSystem.test(style: fsStyle),
      platform: platform,
    );
    final responseCompleter = Completer<void>();
    final request = FakeRequest();
    final args = FlutterLaunchRequestArguments(
      cwd: '.',
      program: 'foo.dart',
      customTool: '/custom/flutter',
      customToolReplacesArgs: 9999,
      noDebug: true,
      toolArgs: <String>['tool_args'],
    );

    await adapter.configurationDoneRequest(request, null, () {});
    await adapter.launchRequest(request, args, responseCompleter.complete);
    await responseCompleter.future;

    expect(adapter.executable, expectedFlutterExecutable);
    expect(adapter.processArgs, contains('--machine'));
    expect(adapter.processArgs, contains('tool_args'));
  });

  test('test adapter ignores customTool', () async {
    final adapter = FakeFlutterTestDebugAdapter(
      fileSystem: MemoryFileSystem.test(style: fsStyle),
      platform: platform,
    );
    final responseCompleter = Completer<void>();
    final request = FakeRequest();
    final args = FlutterLaunchRequestArguments(
      cwd: '.',
      program: 'foo.dart',
      customTool: '/custom/flutter',
      customToolReplacesArgs: 9999,
      noDebug: true,
      toolArgs: <String>['tool_args'],
    );

    await adapter.configurationDoneRequest(request, null, () {});
    await adapter.launchRequest(request, args, responseCompleter.complete);
    await responseCompleter.future;

    expect(adapter.executable, expectedFlutterExecutable);
    expect(adapter.processArgs, contains('--machine'));
    expect(adapter.processArgs, contains('tool_args'));
  });
}

// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_kernel.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;
  MockKernelCompilerFactory mockKernelCompilerFactory;
  MockKernelCompiler mockKernelCompiler;
  Cache.disableLocking();
  Cache.flutterRoot = '';

  setUp(() {
    mockKernelCompilerFactory = MockKernelCompilerFactory();
    mockKernelCompiler = MockKernelCompiler();
    when(mockKernelCompilerFactory.create(any)).thenAnswer((Invocation invocation) async {
      return mockKernelCompiler;
    });
    testbed = Testbed(overrides: <Type, Generator>{
      KernelCompilerFactory: () => mockKernelCompilerFactory,
    });
  });

  test('can build dill files', () => testbed.run(() async {
    final CommandRunner<void> runner = createTestCommandRunner(BuildKernelCommand());
    when(mockKernelCompiler.compile(
      trackWidgetCreation: false,
      targetModel: TargetModel.vm,
      mainPath: 'foo',
      packagesPath: '.packages',
      sdkRoot: anyNamed('sdkRoot'),
      platformDill: 'vm_platform_strong.dill',
      outputFilePath: 'example',
    )).thenAnswer((Invocation invocation) async {
      return const CompilerOutput('example', 0, <Uri>[]);
    });
    fs.file('foo').createSync();

    await runner.run(<String>['kernel', '--output=example', '--target=foo']);
    final BufferLogger bufferLogger = context.get<Logger>();

    expect(bufferLogger.statusText, contains('example'));
  }));

  test('can throw if kernel compiler fails', () => testbed.run(() async {
    final CommandRunner<void> runner = createTestCommandRunner(BuildKernelCommand());
    when(mockKernelCompiler.compile(
      trackWidgetCreation: false,
      targetModel: TargetModel.vm,
      mainPath: 'foo',
      packagesPath: '.packages',
      sdkRoot: anyNamed('sdkRoot'),
      platformDill: 'vm_platform_strong.dill',
      outputFilePath: 'example',
    )).thenAnswer((Invocation invocation) async {
      return const CompilerOutput('example', 1, <Uri>[]);
    });
    fs.file('foo').createSync();

    expect(runner.run(<String>['kernel', '--output=example', '--target=foo']),
        throwsA(isInstanceOf<ToolExit>()));
  }));
}

class MockKernelCompilerFactory extends Mock implements KernelCompilerFactory {}
class MockKernelCompiler extends Mock implements KernelCompiler {}

// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/testbed.dart';

void main() {
  group('unpack_linux', () {
    Testbed testbed;
    BuildSystem buildSystem;
    Environment environment;

    setUp(() {
      testbed = Testbed(setup: () {
        final Directory cacheDir = fs.currentDirectory.childDirectory('cache');
        environment = Environment(
          projectDir: fs.currentDirectory,
          cacheDir: cacheDir,
          targetPlatform: TargetPlatform.linux_x64,
          buildMode: BuildMode.debug,
        );
        buildSystem = const BuildSystem(<Target>[
          unpackLinux,
        ]);
        fs.file('cache/linux-x64/libflutter_linux.so').createSync(recursive: true);
        fs.file('cache/linux-x64/flutter_export.h').createSync();
        fs.file('cache/linux-x64/flutter_messenger.h').createSync();
        fs.file('cache/linux-x64/flutter_plugin_registrar.h').createSync();
        fs.file('cache/linux-x64/flutter_glfw.h').createSync();
        fs.file('cache/linux-x64/icudtl.dat').createSync();
        fs.file('cache/linux-x64/cpp_client_wrapper/foo').createSync(recursive: true);
        fs.directory('linux').createSync();
      });
    });

    test('Copies files to correct cache directory', () => testbed.run(() async {
      await buildSystem.build('unpack_linux', environment);

      expect(fs.file('linux/flutter/libflutter_linux.so').existsSync(), true);
      expect(fs.file('linux/flutter/flutter_export.h').existsSync(), true);
      expect(fs.file('linux/flutter/flutter_messenger.h').existsSync(), true);
      expect(fs.file('linux/flutter/flutter_plugin_registrar.h').existsSync(), true);
      expect(fs.file('linux/flutter/flutter_glfw.h').existsSync(), true);
      expect(fs.file('linux/flutter/icudtl.dat').existsSync(), true);
      expect(fs.file('linux/flutter/cpp_client_wrapper/foo').existsSync(), true);
    }));

    test('Does not re-copy files unecessarily', () => testbed.run(() async {
      await buildSystem.build('unpack_linux', environment);
      final DateTime modified = fs.file('linux/flutter/libflutter_linux.so').statSync().modified;
      await buildSystem.build('unpack_linux', environment);

      expect(fs.file('linux/flutter/libflutter_linux.so').statSync().modified, equals(modified));
    }));

    test('Detects changes in input cache files', () => testbed.run(() async {
      await buildSystem.build('unpack_linux', environment);
      final DateTime modified = fs.file('linux/flutter/libflutter_linux.so').statSync().modified;
      fs.file('cache/linux-x64/libflutter_linux.so').writeAsStringSync('asd'); // modify cache.

      await buildSystem.build('unpack_linux', environment);

      expect(fs.file('linux/flutter/libflutter_linux.so').statSync().modified, isNot(modified));
    }));
  });

  group('unpack_windows', () {
    Testbed testbed;
    BuildSystem buildSystem;
    Environment environment;

    setUp(() {
      testbed = Testbed(setup: () {
        final Directory cacheDir = fs.currentDirectory.childDirectory('cache');
        environment = Environment(
          projectDir: fs.currentDirectory,
          cacheDir: cacheDir,
          targetPlatform: TargetPlatform.windows_x64,
          buildMode: BuildMode.debug,
        );
        buildSystem = const BuildSystem(<Target>[
          unpackWindows,
        ]);
        fs.file(r'C:\cache\windows-x64\flutter_export.h').createSync(recursive: true);
        fs.file(r'C:\cache\windows-x64\flutter_messenger.h').createSync();
        fs.file(r'C:\cache\windows-x64\flutter_windows.dll').createSync();
        fs.file(r'C:\cache\windows-x64\flutter_windows.dll.exp').createSync();
        fs.file(r'C:\cache\windows-x64\flutter_windows.dll.lib').createSync();
        fs.file(r'C:\cache\windows-x64\flutter_windows.dll.pdb').createSync();
        fs.file(r'C:\cache\windows-x64\lutter_export.h').createSync();
        fs.file(r'C:\cache\windows-x64\flutter_messenger.h').createSync();
        fs.file(r'C:\cache\windows-x64\flutter_plugin_registrar.h').createSync();
        fs.file(r'C:\cache\windows-x64\flutter_glfw.h').createSync();
        fs.file(r'C:\cache\windows-x64\icudtl.dat').createSync();
        fs.file(r'C:\cache\windows-x64\cpp_client_wrapper\foo').createSync(recursive: true);
        fs.directory('windows').createSync();
      }, overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem(style: FileSystemStyle.windows),
      });
    });

    test('Copies files to correct cache directory', () => testbed.run(() async {
      await buildSystem.build('unpack_windows', environment);

      expect(fs.file(r'C:\windows\flutter\flutter_export.h').existsSync(), true);
      expect(fs.file(r'C:\windows\flutter\flutter_messenger.h').existsSync(), true);
      expect(fs.file(r'C:\windows\flutter\flutter_windows.dll').existsSync(), true);
      expect(fs.file(r'C:\windows\flutter\flutter_windows.dll.exp').existsSync(), true);
      expect(fs.file(r'C:\windows\flutter\flutter_windows.dll.lib').existsSync(), true);
      expect(fs.file(r'C:\windows\flutter\flutter_windows.dll.pdb').existsSync(), true);
      expect(fs.file(r'C:\windows\flutter\flutter_export.h').existsSync(), true);
      expect(fs.file(r'C:\windows\flutter\flutter_messenger.h').existsSync(), true);
      expect(fs.file(r'C:\windows\flutter\flutter_plugin_registrar.h').existsSync(), true);
      expect(fs.file(r'C:\windows\flutter\flutter_glfw.h').existsSync(), true);
      expect(fs.file(r'C:\windows\flutter\icudtl.dat').existsSync(), true);
      expect(fs.file(r'C:\windows\flutter\cpp_client_wrapper\foo').existsSync(), true);
    }));

    test('Does not re-copy files unecessarily', () => testbed.run(() async {
      await buildSystem.build('unpack_windows', environment);
      final DateTime modified = fs.file(r'C:\windows\flutter\flutter_export.h').statSync().modified;
      await buildSystem.build('unpack_windows', environment);

      expect(fs.file(r'C:\windows\flutter\flutter_export.h').statSync().modified, equals(modified));
    }));

    test('Detects changes in input cache files', () => testbed.run(() async {
      await buildSystem.build('unpack_windows', environment);
      final DateTime modified = fs.file(r'C:\windows\flutter\flutter_export.h').statSync().modified;
      fs.file(r'C:\cache\windows-x64\flutter_export.h').writeAsStringSync('asd'); // modify cache.

      await buildSystem.build('unpack_windows', environment);

      expect(fs.file(r'C:\windows\flutter\flutter_export.h').statSync().modified, isNot(modified));
    }));
  });

  group('unpack_macos', () {
    Testbed testbed;
    BuildSystem buildSystem;
    Environment environment;

    setUp(() {
      testbed = Testbed(setup: () {
        final Directory cacheDir = fs.currentDirectory.childDirectory('cache');
        environment = Environment(
          projectDir: fs.currentDirectory,
          cacheDir: cacheDir,
          targetPlatform: TargetPlatform.darwin_x64,
          buildMode: BuildMode.debug,
        );
        buildSystem = const BuildSystem(<Target>[
          unpackMacos,
        ]);
        fs.directory('cache/darwin-x64/FlutterMacOS.framework').createSync(recursive: true);
        fs.file('cache/darwin-x64/FlutterMacOS.framework/foo').createSync();
        when(processManager.runSync(any)).thenAnswer((Invocation invocation) {
          final List<String> arguments = invocation.positionalArguments.first;
          fs.directory(arguments.last).createSync(recursive: true);
          return FakeProcessResult()..exitCode = 0;
        });
      }, overrides: <Type, Generator>{
        ProcessManager: () => MockProcessManager(),
      });
    });

    test('Copies files to correct cache directory', () => testbed.run(() async {
      await buildSystem.build('unpack_macos', environment);

      expect(fs.directory('macos/flutter/FlutterMacOS.framework').existsSync(), true);
    }));
  });

  group('kernel_snapshot', () {
    Testbed testbed;
    BuildSystem buildSystem;
    Environment environment;

    setUp(() {
      testbed = Testbed(setup: () {
        final Directory cacheDir = fs.currentDirectory.childDirectory('cache');
        environment = Environment(
          projectDir: fs.currentDirectory,
          cacheDir: cacheDir,
          targetPlatform: TargetPlatform.darwin_x64,
          buildMode: BuildMode.debug,
        );
        buildSystem = const BuildSystem(<Target>[
          kernelSnapshot,
        ]);
        fs.file('lib/foo.dart').createSync(recursive: true);
        fs.file('lib/bar.dart').createSync();
        fs.file('lib/fizz').createSync();
      }, overrides: <Type, Generator>{
        KernelCompilerFactory: () => FakeKernelCompilerFactory(),
      });
    });

    test('Produces correct output directory', () => testbed.run(() async {
      await buildSystem.build('kernel_snapshot', environment);

      expect(fs.file('build/debug/main.app.dill').existsSync(), true);
    }));
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class FakeProcessResult implements ProcessResult {
  @override
  int exitCode;

  @override
  int pid = 0;

  @override
  String stderr = '';

  @override
  String stdout = '';
}

class FakeKernelCompilerFactory implements KernelCompilerFactory {
  FakeKernelCompiler kernelCompiler = FakeKernelCompiler();

  @override
  Future<KernelCompiler> create(FlutterProject flutterProject) async {
    return kernelCompiler;
  }
}

class FakeKernelCompiler implements KernelCompiler {
  @override
  Future<CompilerOutput> compile({
    String sdkRoot,
    String mainPath,
    String outputFilePath,
    String depFilePath,
    TargetModel targetModel = TargetModel.flutter,
    bool linkPlatformKernelIn = false,
    bool aot = false,
    bool trackWidgetCreation,
    List<String> extraFrontEndOptions,
    String incrementalCompilerByteStorePath,
    String packagesPath,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    bool targetProductVm = false,
    String initializeFromDill}) async {
      fs.file(outputFilePath).createSync(recursive: true);
      return CompilerOutput(outputFilePath, 0, null);
  }
}

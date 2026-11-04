// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:package_config/package_config.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';
import '../src/fakes.dart';

void main() {
  testWithoutContext('StdoutHandler can parse output for successful batch compilation', () async {
    final logger = BufferLogger.test();
    final stdoutHandler = StdoutHandler(logger: logger, fileSystem: MemoryFileSystem.test());

    stdoutHandler.reset();
    'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0'
        .split('\n')
        .forEach(stdoutHandler.handler);
    final CompilerOutput? output = await stdoutHandler.compilerOutput?.future;

    expect(logger.errorText, equals('line1\nline2\n'));
    expect(output?.outputFilename, equals('/path/to/main.dart.dill'));
  });

  testWithoutContext('StdoutHandler can parse output for failed batch compilation', () async {
    final logger = BufferLogger.test();
    final stdoutHandler = StdoutHandler(logger: logger, fileSystem: MemoryFileSystem.test());

    stdoutHandler.reset();
    'result abc\nline1\nline2\nabc\nabc'.split('\n').forEach(stdoutHandler.handler);
    final CompilerOutput? output = await stdoutHandler.compilerOutput?.future;

    expect(logger.errorText, equals('line1\nline2\n'));
    expect(output, equals(null));
  });

  testWithoutContext(
    'KernelCompiler passes correct configuration to frontend server process',
    () async {
      final logger = BufferLogger.test();
      final stdoutHandler = StdoutHandler(logger: logger, fileSystem: MemoryFileSystem.test());
      final completer = Completer<void>();

      final kernelCompiler = KernelCompiler(
        artifacts: Artifacts.test(),
        fileSystem: MemoryFileSystem.test(),
        fileSystemRoots: <String>[],
        fileSystemScheme: '',
        logger: logger,
        processManager: FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: const <String>[
              'Artifact.engineDartAotRuntime',
              'Artifact.frontendServerSnapshotForEngineDartSdk',
              '--sdk-root',
              '/path/to/sdkroot/',
              '--target=flutter',
              '--no-print-incremental-dependencies',
              '-Ddart.vm.profile=false',
              '-Ddart.vm.product=false',
              '--enable-asserts',
              '--no-link-platform',
              '--packages',
              '.dart_tool/package_config.json',
              '--verbosity=error',
              'file:///path/to/main.dart',
            ],
            completer: completer,
          ),
        ]),
        stdoutHandler: stdoutHandler,
      );
      final Future<CompilerOutput?> output = kernelCompiler.compile(
        sdkRoot: '/path/to/sdkroot',
        mainPath: '/path/to/main.dart',
        buildMode: BuildMode.debug,
        trackWidgetCreation: false,
        dartDefines: const <String>[],
        packageConfig: PackageConfig.empty,
        packagesPath: '.dart_tool/package_config.json',
      );
      stdoutHandler.compilerOutput?.complete(const CompilerOutput('', 0, <Uri>[]));
      completer.complete();

      expect((await output)?.outputFilename, '');
    },
  );

  testWithoutContext('KernelCompiler exits the tool and invalidates stamps when dartaotruntime cannot run', () async {
    final fileSystem = MemoryFileSystem.test();
    final Directory cacheDir = fileSystem.directory('/bin/cache')..createSync(recursive: true);
    final File engineStamp = cacheDir.childFile('engine-dart-sdk.stamp')..createSync();
    final File toolsStamp = cacheDir.childFile('flutter_tools.stamp')..createSync();
    final logger = BufferLogger.test();
    final stdoutHandler = StdoutHandler(logger: logger, fileSystem: fileSystem);

    final kernelCompiler = KernelCompiler(
      artifacts: FakeArtifacts(fileSystem: fileSystem, sdkPath: '/bin/cache/dart-sdk'),
      fileSystem: fileSystem,
      fileSystemRoots: <String>[],
      fileSystemScheme: '',
      logger: logger,
      processManager: FakeProcessManager.empty()
        ..excludedExecutables.add('Artifact.engineDartAotRuntime'),
      stdoutHandler: stdoutHandler,
    );

    await expectLater(
      kernelCompiler.compile(
        sdkRoot: '/path/to/sdkroot',
        mainPath: '/path/to/main.dart',
        buildMode: BuildMode.debug,
        trackWidgetCreation: false,
        dartDefines: const <String>[],
        packageConfig: PackageConfig.empty,
        packagesPath: '.dart_tool/package_config.json',
      ),
      throwsToolExit(
        message:
            'Unable to find dartaotruntime binary at Artifact.engineDartAotRuntime.\n'
            'The Dart SDK cache appears to be incomplete (often caused by antivirus '
            'software quarantining files) and has been invalidated.\n'
            'Please re-run your command to automatically re-download the Dart SDK. '
            'If this issue persists, add your Flutter SDK directory to your antivirus exclusions.',
      ),
    );
    expect(engineStamp.existsSync(), isFalse);
    expect(toolsStamp.existsSync(), isFalse);
  });

  testWithoutContext('KernelCompiler exits the tool with cache deletion advice when stamps cannot be invalidated', () async {
    final fileSystem = MemoryFileSystem.test();
    final logger = BufferLogger.test();
    final stdoutHandler = StdoutHandler(logger: logger, fileSystem: fileSystem);

    final kernelCompiler = KernelCompiler(
      artifacts: FakeArtifacts(fileSystem: fileSystem, sdkPath: '/bin/cache/dart-sdk'),
      fileSystem: fileSystem,
      fileSystemRoots: <String>[],
      fileSystemScheme: '',
      logger: logger,
      processManager: FakeProcessManager.empty()
        ..excludedExecutables.add('Artifact.engineDartAotRuntime'),
      stdoutHandler: stdoutHandler,
    );

    await expectLater(
      kernelCompiler.compile(
        sdkRoot: '/path/to/sdkroot',
        mainPath: '/path/to/main.dart',
        buildMode: BuildMode.debug,
        trackWidgetCreation: false,
        dartDefines: const <String>[],
        packageConfig: PackageConfig.empty,
        packagesPath: '.dart_tool/package_config.json',
      ),
      throwsToolExit(
        message:
            'Unable to find dartaotruntime binary at Artifact.engineDartAotRuntime.\n'
            'The Dart SDK cache appears to be incomplete or corrupted (often caused '
            'by antivirus software quarantining files).\n'
            'Please delete /bin/cache and re-run your command '
            'to re-download the Dart SDK. '
            'If this issue persists, add your Flutter SDK directory to your antivirus exclusions.',
      ),
    );
  });

  testWithoutContext('KernelCompiler exits the tool with engine rebuild advice when dartaotruntime cannot run on local engine', () async {
    final fileSystem = MemoryFileSystem.test();
    final logger = BufferLogger.test();
    final stdoutHandler = StdoutHandler(logger: logger, fileSystem: fileSystem);

    final kernelCompiler = KernelCompiler(
      artifacts: Artifacts.testLocalEngine(
        localEngine: 'host_debug',
        localEngineHost: 'host_debug',
        fileSystem: fileSystem,
      ),
      fileSystem: fileSystem,
      fileSystemRoots: <String>[],
      fileSystemScheme: '',
      logger: logger,
      processManager: FakeProcessManager.empty()
        ..excludedExecutables.add('Artifact.engineDartAotRuntime'),
      stdoutHandler: stdoutHandler,
    );

    await expectLater(
      kernelCompiler.compile(
        sdkRoot: '/path/to/sdkroot',
        mainPath: '/path/to/main.dart',
        buildMode: BuildMode.debug,
        trackWidgetCreation: false,
        dartDefines: const <String>[],
        packageConfig: PackageConfig.empty,
        packagesPath: '.dart_tool/package_config.json',
      ),
      throwsToolExit(
        message:
            'Unable to find dartaotruntime binary at Artifact.engineDartAotRuntime. '
            'Rebuild your local engine to generate the missing binary.',
      ),
    );
  });

  testWithoutContext(
    'KernelCompiler exits the tool when Dart binary cannot run with frontendServerStarterPath',
    () async {
      final fileSystem = MemoryFileSystem.test();
      final logger = BufferLogger.test();
      final stdoutHandler = StdoutHandler(logger: logger, fileSystem: fileSystem);

      final kernelCompiler = KernelCompiler(
        artifacts: Artifacts.test(fileSystem: fileSystem),
        fileSystem: fileSystem,
        fileSystemRoots: <String>[],
        fileSystemScheme: '',
        logger: logger,
        processManager: FakeProcessManager.empty()
          ..excludedExecutables.add('Artifact.engineDartBinary'),
        stdoutHandler: stdoutHandler,
      );

      await expectLater(
        kernelCompiler.compile(
          sdkRoot: '/path/to/sdkroot',
          mainPath: '/path/to/main.dart',
          frontendServerStarterPath: '/path/to/frontend_server_starter.dart',
          buildMode: BuildMode.debug,
          trackWidgetCreation: false,
          dartDefines: const <String>[],
          packageConfig: PackageConfig.empty,
          packagesPath: '.dart_tool/package_config.json',
        ),
        throwsToolExit(message: 'Unable to find Dart binary at Artifact.engineDartBinary'),
      );
    },
  );

  testWithoutContext('KernelCompiler runs the frontend server from source with the Dart binary '
      'when frontendServerStarterPath is provided', () async {
    final logger = BufferLogger.test();
    final stdoutHandler = StdoutHandler(logger: logger, fileSystem: MemoryFileSystem.test());
    final completer = Completer<void>();
    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>[
          'Artifact.engineDartBinary',
          '/path/to/frontend_server_starter.dart',
          '--sdk-root',
          '/path/to/sdkroot/',
          '--target=flutter',
          '--no-print-incremental-dependencies',
          '-Ddart.vm.profile=false',
          '-Ddart.vm.product=false',
          '--enable-asserts',
          '--no-link-platform',
          '--packages',
          '.dart_tool/package_config.json',
          '--verbosity=error',
          'file:///path/to/main.dart',
        ],
        completer: completer,
      ),
    ])..excludedExecutables.add('Artifact.engineDartAotRuntime');

    final kernelCompiler = KernelCompiler(
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      fileSystemRoots: <String>[],
      fileSystemScheme: '',
      logger: logger,
      processManager: processManager,
      stdoutHandler: stdoutHandler,
    );

    final Future<CompilerOutput?> output = kernelCompiler.compile(
      sdkRoot: '/path/to/sdkroot',
      mainPath: '/path/to/main.dart',
      frontendServerStarterPath: '/path/to/frontend_server_starter.dart',
      buildMode: BuildMode.debug,
      trackWidgetCreation: false,
      dartDefines: const <String>[],
      packageConfig: PackageConfig.empty,
      packagesPath: '.dart_tool/package_config.json',
    );
    stdoutHandler.compilerOutput?.complete(const CompilerOutput('', 0, <Uri>[]));
    completer.complete();

    expect((await output)?.outputFilename, '');
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('KernelCompiler returns null if StdoutHandler returns null', () async {
    final logger = BufferLogger.test();
    final stdoutHandler = StdoutHandler(logger: logger, fileSystem: MemoryFileSystem.test());
    final completer = Completer<void>();

    final kernelCompiler = KernelCompiler(
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      fileSystemRoots: <String>[],
      fileSystemScheme: '',
      logger: logger,
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'Artifact.engineDartAotRuntime',
            'Artifact.frontendServerSnapshotForEngineDartSdk',
            '--sdk-root',
            '/path/to/sdkroot/',
            '--target=flutter',
            '--no-print-incremental-dependencies',
            '-Ddart.vm.profile=false',
            '-Ddart.vm.product=false',
            '--enable-asserts',
            '--no-link-platform',
            '--packages',
            '.dart_tool/package_config.json',
            '--verbosity=error',
            'file:///path/to/main.dart',
          ],
          completer: completer,
        ),
      ]),
      stdoutHandler: stdoutHandler,
    );
    final Future<CompilerOutput?> output = kernelCompiler.compile(
      sdkRoot: '/path/to/sdkroot',
      mainPath: '/path/to/main.dart',
      buildMode: BuildMode.debug,
      trackWidgetCreation: false,
      dartDefines: const <String>[],
      packageConfig: PackageConfig.empty,
      packagesPath: '.dart_tool/package_config.json',
    );
    stdoutHandler.compilerOutput?.complete();
    completer.complete();

    expect(await output, null);
  });

  testWithoutContext(
    'KernelCompiler returns null if frontend_server process exits with non-zero code',
    () async {
      final logger = BufferLogger.test();
      final stdoutHandler = StdoutHandler(logger: logger, fileSystem: MemoryFileSystem.test());
      final completer = Completer<void>();

      final kernelCompiler = KernelCompiler(
        artifacts: Artifacts.test(),
        fileSystem: MemoryFileSystem.test(),
        fileSystemRoots: <String>[],
        fileSystemScheme: '',
        logger: logger,
        processManager: FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: const <String>[
              'Artifact.engineDartAotRuntime',
              'Artifact.frontendServerSnapshotForEngineDartSdk',
              '--sdk-root',
              '/path/to/sdkroot/',
              '--target=flutter',
              '--no-print-incremental-dependencies',
              '-Ddart.vm.profile=false',
              '-Ddart.vm.product=false',
              '--enable-asserts',
              '--no-link-platform',
              '--packages',
              '.dart_tool/package_config.json',
              '--verbosity=error',
              'file:///path/to/main.dart',
            ],
            completer: completer,
            exitCode: 127,
          ),
        ]),
        stdoutHandler: stdoutHandler,
      );
      final Future<CompilerOutput?> output = kernelCompiler.compile(
        sdkRoot: '/path/to/sdkroot',
        mainPath: '/path/to/main.dart',
        buildMode: BuildMode.debug,
        trackWidgetCreation: false,
        dartDefines: const <String>[],
        packageConfig: PackageConfig.empty,
        packagesPath: '.dart_tool/package_config.json',
      );
      stdoutHandler.compilerOutput?.complete(const CompilerOutput('', 0, <Uri>[]));
      completer.complete();

      expect(await output, null);
    },
  );

  testWithoutContext(
    'KernelCompiler passes correct AOT config to frontend_server in aot/profile mode',
    () async {
      final logger = BufferLogger.test();
      final stdoutHandler = StdoutHandler(logger: logger, fileSystem: MemoryFileSystem.test());
      final completer = Completer<void>();

      final kernelCompiler = KernelCompiler(
        artifacts: Artifacts.test(),
        fileSystem: MemoryFileSystem.test(),
        fileSystemRoots: <String>[],
        fileSystemScheme: '',
        logger: logger,
        processManager: FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: const <String>[
              'Artifact.engineDartAotRuntime',
              'Artifact.frontendServerSnapshotForEngineDartSdk',
              '--sdk-root',
              '/path/to/sdkroot/',
              '--target=flutter',
              '--no-print-incremental-dependencies',
              '-Ddart.vm.profile=true',
              '-Ddart.vm.product=false',
              '--delete-tostring-package-uri=dart:ui',
              '--delete-tostring-package-uri=package:flutter',
              '--no-link-platform',
              '--aot',
              '--tfa',
              '--packages',
              '.dart_tool/package_config.json',
              '--verbosity=error',
              'file:///path/to/main.dart',
            ],
            completer: completer,
          ),
        ]),
        stdoutHandler: stdoutHandler,
      );
      final Future<CompilerOutput?> output = kernelCompiler.compile(
        sdkRoot: '/path/to/sdkroot',
        mainPath: '/path/to/main.dart',
        buildMode: BuildMode.profile,
        trackWidgetCreation: false,
        aot: true,
        dartDefines: const <String>[],
        packageConfig: PackageConfig.empty,
        packagesPath: '.dart_tool/package_config.json',
      );
      stdoutHandler.compilerOutput?.complete(const CompilerOutput('', 0, <Uri>[]));
      completer.complete();

      expect((await output)?.outputFilename, '');
    },
  );

  testWithoutContext('passes correct AOT config to kernel compiler in aot/release mode', () async {
    final logger = BufferLogger.test();
    final stdoutHandler = StdoutHandler(logger: logger, fileSystem: MemoryFileSystem.test());
    final completer = Completer<void>();

    final kernelCompiler = KernelCompiler(
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      fileSystemRoots: <String>[],
      fileSystemScheme: '',
      logger: logger,
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'Artifact.engineDartAotRuntime',
            'Artifact.frontendServerSnapshotForEngineDartSdk',
            '--sdk-root',
            '/path/to/sdkroot/',
            '--target=flutter',
            '--no-print-incremental-dependencies',
            '-Ddart.vm.profile=false',
            '-Ddart.vm.product=true',
            '--delete-tostring-package-uri=dart:ui',
            '--delete-tostring-package-uri=package:flutter',
            '--no-link-platform',
            '--aot',
            '--tfa',
            '--packages',
            '.dart_tool/package_config.json',
            '--verbosity=error',
            'file:///path/to/main.dart',
          ],
          completer: completer,
        ),
      ]),
      stdoutHandler: stdoutHandler,
    );
    final Future<CompilerOutput?> output = kernelCompiler.compile(
      sdkRoot: '/path/to/sdkroot',
      mainPath: '/path/to/main.dart',
      buildMode: BuildMode.release,
      trackWidgetCreation: false,
      aot: true,
      dartDefines: const <String>[],
      packageConfig: PackageConfig.empty,
      packagesPath: '.dart_tool/package_config.json',
    );
    stdoutHandler.compilerOutput?.complete(const CompilerOutput('', 0, <Uri>[]));
    completer.complete();

    expect((await output)?.outputFilename, '');
  });

  testWithoutContext('KernelCompiler passes dartDefines to the frontend_server', () async {
    final logger = BufferLogger.test();
    final stdoutHandler = StdoutHandler(logger: logger, fileSystem: MemoryFileSystem.test());
    final completer = Completer<void>();

    final kernelCompiler = KernelCompiler(
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      fileSystemRoots: <String>[],
      fileSystemScheme: '',
      logger: logger,
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'Artifact.engineDartAotRuntime',
            'Artifact.frontendServerSnapshotForEngineDartSdk',
            '--sdk-root',
            '/path/to/sdkroot/',
            '--target=flutter',
            '--no-print-incremental-dependencies',
            '-DFOO=bar',
            '-DBAZ=qux',
            '-Ddart.vm.profile=false',
            '-Ddart.vm.product=false',
            '--enable-asserts',
            '--no-link-platform',
            '--packages',
            '.dart_tool/package_config.json',
            '--verbosity=error',
            'file:///path/to/main.dart',
          ],
          completer: completer,
        ),
      ]),
      stdoutHandler: stdoutHandler,
    );

    final Future<CompilerOutput?> output = kernelCompiler.compile(
      sdkRoot: '/path/to/sdkroot',
      mainPath: '/path/to/main.dart',
      buildMode: BuildMode.debug,
      trackWidgetCreation: false,
      dartDefines: const <String>['FOO=bar', 'BAZ=qux'],
      packageConfig: PackageConfig.empty,
      packagesPath: '.dart_tool/package_config.json',
    );

    stdoutHandler.compilerOutput?.complete(const CompilerOutput('', 0, <Uri>[]));
    completer.complete();

    expect((await output)?.outputFilename, '');
  });

  testWithoutContext('KernelCompiler maps a file to a multi-root scheme if provided', () async {
    final logger = BufferLogger.test();
    final stdoutHandler = StdoutHandler(logger: logger, fileSystem: MemoryFileSystem.test());
    final completer = Completer<void>();

    final kernelCompiler = KernelCompiler(
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      fileSystemRoots: <String>['/foo/bar/fizz'],
      fileSystemScheme: 'scheme',
      logger: logger,
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'Artifact.engineDartAotRuntime',
            'Artifact.frontendServerSnapshotForEngineDartSdk',
            '--sdk-root',
            '/path/to/sdkroot/',
            '--target=flutter',
            '--no-print-incremental-dependencies',
            '-Ddart.vm.profile=false',
            '-Ddart.vm.product=false',
            '--enable-asserts',
            '--no-link-platform',
            '--packages',
            '.dart_tool/package_config.json',
            '--verbosity=error',
            'scheme:///main.dart',
          ],
          completer: completer,
        ),
      ]),
      stdoutHandler: stdoutHandler,
    );

    final Future<CompilerOutput?> output = kernelCompiler.compile(
      sdkRoot: '/path/to/sdkroot',
      mainPath: '/foo/bar/fizz/main.dart',
      buildMode: BuildMode.debug,
      trackWidgetCreation: false,
      dartDefines: const <String>[],
      packageConfig: PackageConfig.empty,
      packagesPath: '.dart_tool/package_config.json',
    );

    stdoutHandler.compilerOutput?.complete(const CompilerOutput('', 0, <Uri>[]));
    completer.complete();

    expect((await output)?.outputFilename, '');
  });

  testWithoutContext('KernelCompiler uses generated entrypoint', () async {
    final logger = BufferLogger.test();
    final stdoutHandler = StdoutHandler(logger: logger, fileSystem: MemoryFileSystem.test());
    final completer = Completer<void>();
    final fs = MemoryFileSystem.test();
    final kernelCompiler = KernelCompiler(
      artifacts: Artifacts.test(),
      fileSystem: fs,
      fileSystemRoots: <String>['/foo/bar/fizz'],
      fileSystemScheme: 'scheme',
      logger: logger,
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'Artifact.engineDartAotRuntime',
            'Artifact.frontendServerSnapshotForEngineDartSdk',
            '--sdk-root',
            '/path/to/sdkroot/',
            '--target=flutter',
            '--no-print-incremental-dependencies',
            '-Ddart.vm.profile=false',
            '-Ddart.vm.product=false',
            '--enable-asserts',
            '--no-link-platform',
            '--packages',
            '.dart_tool/package_config.json',
            '--source',
            '.dart_tools/flutter_build/dart_plugin_registrant.dart',
            '--source',
            'package:flutter/src/dart_plugin_registrant.dart',
            '-Dflutter.dart_plugin_registrant=.dart_tools/flutter_build/dart_plugin_registrant.dart',
            '--verbosity=error',
            'scheme:///main.dart',
          ],
          completer: completer,
        ),
      ]),
      stdoutHandler: stdoutHandler,
    );

    final Directory buildDir = fs
        .directory('.dart_tools')
        .childDirectory('flutter_build')
        .childDirectory('test');

    buildDir.parent.childFile('dart_plugin_registrant.dart').createSync(recursive: true);

    final Future<CompilerOutput?> output = kernelCompiler.compile(
      sdkRoot: '/path/to/sdkroot',
      mainPath: '/foo/bar/fizz/main.dart',
      buildMode: BuildMode.debug,
      trackWidgetCreation: false,
      dartDefines: const <String>[],
      packageConfig: PackageConfig.empty,
      packagesPath: '.dart_tool/package_config.json',
      buildDir: buildDir,
      checkDartPluginRegistry: true,
    );

    stdoutHandler.compilerOutput?.complete(const CompilerOutput('', 0, <Uri>[]));
    completer.complete();
    await output;
  });

  testWithoutContext('KernelCompiler passes native assets', () async {
    final logger = BufferLogger.test();
    final stdoutHandler = StdoutHandler(logger: logger, fileSystem: MemoryFileSystem.test());
    final completer = Completer<void>();

    final kernelCompiler = KernelCompiler(
      artifacts: Artifacts.test(),
      fileSystem: MemoryFileSystem.test(),
      fileSystemRoots: <String>[],
      fileSystemScheme: '',
      logger: logger,
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'Artifact.engineDartAotRuntime',
            'Artifact.frontendServerSnapshotForEngineDartSdk',
            '--sdk-root',
            '/path/to/sdkroot/',
            '--target=flutter',
            '--no-print-incremental-dependencies',
            '-Ddart.vm.profile=false',
            '-Ddart.vm.product=false',
            '--enable-asserts',
            '--no-link-platform',
            '--packages',
            '.dart_tool/package_config.json',
            '--native-assets',
            'path/to/native_assets.yaml',
            '--verbosity=error',
            'file:///path/to/main.dart',
          ],
          completer: completer,
        ),
      ]),
      stdoutHandler: stdoutHandler,
    );
    final Future<CompilerOutput?> output = kernelCompiler.compile(
      sdkRoot: '/path/to/sdkroot',
      mainPath: '/path/to/main.dart',
      buildMode: BuildMode.debug,
      trackWidgetCreation: false,
      dartDefines: const <String>[],
      packageConfig: PackageConfig.empty,
      packagesPath: '.dart_tool/package_config.json',
      nativeAssets: 'path/to/native_assets.yaml',
    );
    stdoutHandler.compilerOutput?.complete(const CompilerOutput('', 0, <Uri>[]));
    completer.complete();

    expect((await output)?.outputFilename, '');
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/test.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/flutter_platform.dart';
import 'package:flutter_tools/src/test/test_wrapper.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/fake.dart';
import 'package:test_core/src/platform.dart'; // ignore: implementation_imports
import 'package:vm_service/vm_service.dart' as vm_service;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_devices.dart';
import '../../src/package_config.dart';
import '../../src/test_flutter_command_runner.dart';

const _pubspecContents = '''
name: my_app
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter''';

void main() {
  Cache.disableLocking();
  late MemoryFileSystem fs;
  late BufferLogger logger;
  late BuildSpammyDevice spammyDevice;
  FakeFlutterVmService? fakeVmService;

  setUp(() {
    fs = MemoryFileSystem.test(
      style: globals.platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
    );

    final Directory package = fs.directory('package');

    package.childFile('pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(_pubspecContents);

    writePackageConfigFiles(
      directory: package,
      packages: <String, String>{
        'test_api': 'file:///path/to/pubcache/.pub-cache/hosted/pub.dartlang.org/test_api-0.2.19',
        'integration_test': 'file:///path/to/flutter/packages/integration_test',
      },
      mainLibName: 'my_app',
      devDependencies: <String>['test_api', 'integration_test'],
    );

    package
        .childDirectory('integration_test')
        .childFile('some_integration_test.dart')
        .createSync(recursive: true);

    writePackageConfigFiles(
      directory: fs.directory(fs.path.join(getFlutterRoot(), 'packages', 'flutter_tools')),
      packages: <String, String>{
        'ffi': 'file:///path/to/pubcache/.pub-cache/hosted/pub.dev/ffi-2.1.2',
        'test': 'file:///path/to/pubcache/.pub-cache/hosted/pub.dev/test-1.24.9',
        'test_api': 'file:///path/to/pubcache/.pub-cache/hosted/pub.dev/test_api-0.6.1',
        'test_core': 'file:///path/to/pubcache/.pub-cache/hosted/pub.dev/test_core-0.5.9',
      },
      mainLibName: 'my_app',
    );

    fs.currentDirectory = package.path;

    logger = BufferLogger.test();
    spammyDevice = BuildSpammyDevice();
    fakeVmService = null;
  });

  testUsingContext(
    'integration test with json reporter does not include Gradle output or status messages in stdout (statusText)',
    () async {
      final fakeTestWrapper = FakeTestWrapper();
      StreamChannel<Object?>? channel;

      fakeTestWrapper.runInsideMain = (FlutterPlatform platformPlugin) async {
        // Trigger the platform plugin to load the test, which will launch the spammy device.
        final suitePlatform = SuitePlatform(Runtime.vm);

        // Just start a dummy listener channel.
        channel = platformPlugin.loadChannel(
          'integration_test/some_integration_test.dart',
          suitePlatform,
        );

        // We expect the device to be started and print status logs.
        Future<void> expectEventually(bool Function() condition) async {
          final sw = Stopwatch()..start();
          while (!condition()) {
            if (sw.elapsed > const Duration(seconds: 5)) {
              throw StateError('Timed out waiting for condition');
            }
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        }

        await expectEventually(() => logger.errorText.contains('Running Gradle task'));

        expect(logger.statusText, isNot(contains('Running Gradle task')));
        expect(logger.statusText, isNot(contains('Installing app')));
        expect(logger.statusText, isNot(contains('Built some_app.apk')));

        // Instead, it should be redirected to errorText!
        expect(logger.errorText, contains('Running Gradle task'));
        expect(logger.errorText, contains('Installing app'));
        expect(logger.errorText, contains('Built some_app.apk'));
      };

      final testCommand = TestCommand(testWrapper: fakeTestWrapper);
      final CommandRunner<void> commandRunner = createTestCommandRunner(testCommand);
      await commandRunner.run(const <String>[
        'test',
        '--no-pub',
        '--no-dds',
        '-r',
        'json',
        'integration_test/some_integration_test.dart',
      ]);
      fakeVmService?.service.done();
      await channel!.sink.close();
    },
    overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      Logger: () => logger,
      DeviceManager: () => _FakeDeviceManager(<Device>[spammyDevice]),
      ApplicationPackageFactory: () => FakeApplicationPackageFactory(),
      VMServiceConnector: () =>
          (
            Uri httpUri, {
            ReloadSources? reloadSources,
            Restart? restart,
            CompileExpression? compileExpression,
            FlutterProject? flutterProject,
            PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
            io.CompressionOptions? compression,
            Device? device,
            Logger? logger,
          }) async {
            fakeVmService = FakeFlutterVmService();
            return fakeVmService!;
          },
    },
  );
}

class FakeTestWrapper implements TestWrapper {
  PlatformPlugin? platformPlugin;
  List<String>? lastArgs;
  Future<void> Function(FlutterPlatform platformPlugin)? runInsideMain;

  @override
  void registerPlatformPlugin(
    Iterable<Runtime> runtimes,
    FutureOr<PlatformPlugin> Function() platforms,
  ) {
    final FutureOr<PlatformPlugin> platform = platforms();
    if (platform is PlatformPlugin) {
      platformPlugin = platform;
    } else {
      platform.then((PlatformPlugin value) {
        platformPlugin = value;
      });
    }
  }

  @override
  Future<void> main(List<String> args) async {
    lastArgs = args;
    if (runInsideMain != null) {
      while (platformPlugin == null) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      await runInsideMain!(platformPlugin! as FlutterPlatform);
    }
  }
}

class BuildSpammyDevice extends FakeDevice {
  BuildSpammyDevice() : super('spammy', 'spammy', type: PlatformType.android);

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    String? mainPath,
    String? route,
    DebuggingOptions? debuggingOptions,
    Map<String, dynamic>? platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String? userIdentifier,
  }) async {
    // Print Gradle build output and installation progress.
    globals.logger.printStatus("Running Gradle task 'assembleDebug'...");
    globals.logger.printStatus('Built some_app.apk.');
    final Status progress = globals.logger.startProgress('Installing app...');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    progress.stop();
    return LaunchResult.succeeded(vmServiceUri: Uri.parse('http://127.0.0.1:12345/'));
  }
}

class _FakeDeviceManager extends DeviceManager {
  _FakeDeviceManager(this._devices) : super(logger: BufferLogger.test());

  final List<Device> _devices;

  @override
  Future<List<Device>> getAllDevices({DeviceDiscoveryFilter? filter}) async {
    if (filter?.deviceConnectionInterface == DeviceConnectionInterface.wireless) {
      return <Device>[];
    }
    return _devices;
  }

  @override
  List<DeviceDiscovery> get deviceDiscoverers => <DeviceDiscovery>[];
}

class FakeApplicationPackageFactory extends Fake implements ApplicationPackageFactory {
  @override
  Future<ApplicationPackage> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo? buildInfo,
    File? applicationBinary,
  }) async {
    return FakeApplicationPackage();
  }
}

class FakeApplicationPackage extends Fake implements ApplicationPackage {
  @override
  String get name => 'Fake Integration Test Package';
}

class FakeFlutterVmService extends Fake implements FlutterVmService {
  @override
  Future<vm_service.IsolateRef> findExtensionIsolate(String extensionName) async {
    return vm_service.IsolateRef(id: '1', number: '1', name: 'main');
  }

  @override
  final FakeVmService service = FakeVmService();
}

class FakeVmService extends Fake implements vm_service.VmService {
  final Completer<void> _onDoneCompleter = Completer<void>();

  @override
  Future<void> get onDone => _onDoneCompleter.future;

  void done() {
    if (!_onDoneCompleter.isCompleted) {
      _onDoneCompleter.complete();
    }
  }

  @override
  Future<vm_service.Success> streamListen(String streamId) async {
    return vm_service.Success();
  }

  @override
  Stream<vm_service.Event> get onExtensionEvent => const Stream<vm_service.Event>.empty();

  @override
  Stream<vm_service.Event> get onIsolateEvent => const Stream<vm_service.Event>.empty();

  @override
  Future<vm_service.Success> streamCancel(String streamId) async {
    return vm_service.Success();
  }

  @override
  Stream<vm_service.Event> onEvent(String streamId) => const Stream<vm_service.Event>.empty();
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_vm_services.dart';
import '../../src/fakes.dart';
import '../../src/testbed.dart';
import '../resident_runner_helpers.dart';

void main() {
  late TestBed testbed;
  late FakeDevFS devFS;
  FakeVmServiceHost? fakeVmServiceHost;

  setUp(() {
    testbed = TestBed(
      setup: () {
        globals.fs.file(globals.fs.path.join('build', 'app.dill'))
          ..createSync(recursive: true)
          ..writeAsStringSync('ABC');
      },
    );
    devFS = FakeDevFS();
  });

  testUsingContext(
    'use the nativeAssetsYamlFile when provided',
    () => testbed.run(() async {
      final device = FakeDevice(targetPlatform: TargetPlatform.darwin, sdkNameAndVersion: 'Macos');
      final residentCompiler = FakeResidentCompiler();
      final flutterDevice = FakeFlutterDevice()
        ..testUri = testUri
        ..vmServiceHost = (() => fakeVmServiceHost)
        ..device = device
        ..fakeDevFS = devFS
        ..targetPlatform = TargetPlatform.darwin
        ..generator = residentCompiler;

      fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[listViews, listViews]);
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      final residentRunner = HotRunner(
        <FlutterDevice>[flutterDevice],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(
          const BuildInfo(
            BuildMode.debug,
            '',
            treeShakeIcons: false,
            trackWidgetCreation: true,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
        target: 'main.dart',
        analytics: getInitializedFakeAnalyticsInstance(
          fs: MemoryFileSystem.test(),
          fakeFlutterVersion: FakeFlutterVersion(),
        ),
        nativeAssetsYamlFile: 'foo.yaml',
        logger: globals.logger,
      );

      final int result = await residentRunner.run();
      expect(result, 0);

      expect(residentCompiler.recompileCalled, true);
      expect(residentCompiler.receivedNativeAssetsYaml, globals.fs.path.toUri('foo.yaml'));
    }),
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.any(),
      FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true, isMacOSEnabled: true),
    },
  );
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/web.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/web/compiler_config.dart';
import 'package:unified_analytics/testing.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';
import '../../../src/fakes.dart';
import '../../../src/package_config.dart';
import '../../../src/testbed.dart';

final Map<String, String> _fakePackageVersions = {
  'foo': '4.3.23',
  'bar': '2.6.1',
  'baz': '1.2.5',
  'fizz': '1.2.3-alpha1',
  'lesslong': '2.12.7865-${'alpha' * 14}',
  'morelong': '2.12.78650-${'alpha' * 14}',
};

void main() {
  late TestBed testbed;
  late MemoryFileSystem fs;
  late Environment environment;
  late FakeProcessManager processManager;
  late FakeAnalytics fakeAnalytics;
  late List<String> commandArgs;

  final Platform linux = FakePlatform(environment: <String, String>{});

  Dart2WasmTarget createTarget() =>
      Dart2WasmTarget(const WasmCompilerConfig(dryRun: true), fakeAnalytics)
        ..dryRunRandom = Random(0);

  setUp(() {
    testbed = TestBed(
      setup: () {
        fs = MemoryFileSystem.test();
        fs.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('''
name: my_app
''');

        writePackageConfigFiles(
          directory: fs.currentDirectory,
          packages: _fakePackageVersions.map(
            (k, v) => MapEntry(k, 'file:///path/to/pubcache/.pub-cache/hosted/pub.dev/$k-$v'),
          ),
          mainLibName: 'my_app',
        );
        fs.currentDirectory.childDirectory('bar').createSync();
        processManager = FakeProcessManager.empty();
        fs.file('bin/cache/flutter_web_sdk/flutter_js/flutter.js').createSync(recursive: true);

        environment = Environment.test(
          fs.currentDirectory,
          projectDir: fs.currentDirectory.childDirectory('foo'),
          outputDir: fs.currentDirectory.childDirectory('bar'),
          defines: <String, String>{
            kTargetFile: fs.path.join('foo', 'lib', 'main.dart'),
            kBuildMode: BuildMode.debug.cliName,
          },
          artifacts: Artifacts.test(),
          processManager: processManager,
          logger: globals.logger,
          fileSystem: fs,
        );
        environment.buildDir.createSync(recursive: true);

        fakeAnalytics = getInitializedFakeAnalyticsInstance(
          fs: fs,
          fakeFlutterVersion: FakeFlutterVersion(),
        );
        commandArgs = [
          'Artifact.engineDartBinary.TargetPlatform.web_javascript',
          'compile',
          'wasm',
          '--packages=/.dart_tool/package_config.json',
          '--extra-compiler-option=--platform=HostArtifact.webPlatformKernelFolder/dart2wasm_platform.dill',
          '-Ddart.vm.profile=false',
          '-Ddart.vm.product=false',
          '--extra-compiler-option=--import-shared-memory',
          '--extra-compiler-option=--shared-memory-max-pages=32768',
          '-DFLUTTER_WEB_USE_SKIA=false',
          '-DFLUTTER_WEB_USE_SKWASM=true',
          '-DFLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/abcdefghijklmnopqrstuvwxyz/',
          '--extra-compiler-option=--depfile=${environment.buildDir.childFile('dart2wasm.d').path}',
          '-O0',
          '--no-strip-wasm',
          '--no-minify',
          '--extra-compiler-option=--enable-asserts',
          '--extra-compiler-option=--dry-run',
          '-o',
          environment.buildDir.childFile('main.dart.wasm').absolute.path,
          environment.buildDir.childFile('main.dart').absolute.path,
        ];
      },
      overrides: <Type, Generator>{Platform: () => linux},
    );
  });

  test(
    'wasm dry run success',
    () => testbed.run(() async {
      processManager.addCommand(FakeCommand(command: commandArgs));
      final Dart2WasmTarget target = createTarget();
      await target.build(environment);

      expect(fakeAnalytics.sentEvents, hasLength(1));

      final Event event = fakeAnalytics.sentEvents[0];
      expect(event.eventName, equals(DashEvent.flutterWasmDryRunPackage));
      expect(event.eventData, hasLength(2));
      expect(event.eventData['result'], 'success');
      expect(event.eventData['exitCode'], 0);
    }),
  );

  test(
    'wasm dry run crash',
    () => testbed.run(() async {
      processManager.addCommand(
        FakeCommand(
          command: commandArgs,
          exitCode: 100,
          stdout: '''
Found incompatibilities with WebAssembly.

package:foo/some/path.dart 6:1 - dart:html unsupported (0)
''',
        ),
      );
      final Dart2WasmTarget target = createTarget();
      await target.build(environment);

      expect(fakeAnalytics.sentEvents, hasLength(1));

      final Event event = fakeAnalytics.sentEvents[0];
      expect(event.eventName, equals(DashEvent.flutterWasmDryRunPackage));
      expect(event.eventData, hasLength(2));
      expect(event.eventData['result'], 'crash');
      expect(event.eventData['exitCode'], 100);
    }),
  );

  test(
    'wasm dry run failure',
    () => testbed.run(() async {
      processManager.addCommand(
        FakeCommand(
          command: commandArgs,
          exitCode: 254,
          stdout: '''
Found incompatibilities with WebAssembly.

package:foo/some/path.dart 6:1 - dart:html unsupported (0)
''',
          stderr: 'Failure reason',
        ),
      );
      final Dart2WasmTarget target = createTarget();
      await target.build(environment);

      expect(fakeAnalytics.sentEvents, hasLength(1));

      final Event event = fakeAnalytics.sentEvents[0];
      expect(event.eventName, DashEvent.flutterWasmDryRunPackage);
      expect(event.eventData, hasLength(2));
      expect(event.eventData['result'], 'failure');
      expect(event.eventData['exitCode'], 254);
    }),
  );

  test(
    'dry run findings public packages',
    () => testbed.run(() async {
      processManager.addCommand(
        FakeCommand(
          command: commandArgs,
          exitCode: 254,
          stdout: '''
Found incompatibilities with WebAssembly.

package:foo/some/path.dart 6:1 - dart:html unsupported (0)
package:bar/some/path.dart 120:5 - dart:js unsupported (1)
package:foo/some/path.dart 7:20 - dart:html unsupported (0)
package:baz/some/path.dart 54:8 - dart:html unsupported (0)
package:bar/some/path.dart 94:6 - package:js unsupported (2)
package:baz/some/path.dart 16:6 - dart:js unsupported (1)
package:fizz/some/path.dart 80:2 - dart:ffi unsupported (3)
package:foo/some(5)/path.dart 103:20 - dart:io unsupported (4)
''',
        ),
      );
      final Dart2WasmTarget target = createTarget();
      await target.build(environment);

      expect(fakeAnalytics.sentEvents, hasLength(1));

      final Event event = fakeAnalytics.sentEvents[0];
      expect(event.eventName, equals(DashEvent.flutterWasmDryRunPackage));
      expect(event.eventData, hasLength(7));
      expect(event.eventData['result'], 'findings');
      expect(event.eventData['exitCode'], 254);
      expect(
        event.eventData['E0'],
        'foo:${_fakePackageVersions['foo']},baz:${_fakePackageVersions['baz']}',
      );
      expect(
        event.eventData['E1'],
        'bar:${_fakePackageVersions['bar']},baz:${_fakePackageVersions['baz']}',
      );
      expect(event.eventData['E2'], 'bar:${_fakePackageVersions['bar']}');
      expect(event.eventData['E3'], 'fizz:${_fakePackageVersions['fizz']}');
      expect(event.eventData['E4'], 'foo:${_fakePackageVersions['foo']}');
    }),
  );

  test(
    'dry run findings public packages with private package',
    () => testbed.run(() async {
      writePackageConfigFiles(
        directory: fs.currentDirectory,
        packages: _fakePackageVersions.map(
          (k, v) => MapEntry(k, 'file:///path/to/pubcache/.pub-cache/hosted/pub.dev/$k-$v'),
        )..addAll({'priv': 'file:///path/to/local/pkg/private_package'}),
        mainLibName: 'my_app',
      );

      processManager.addCommand(
        FakeCommand(
          command: commandArgs,
          exitCode: 254,
          stdout: '''
Found incompatibilities with WebAssembly.

package:foo/some/path.dart 6:1 - dart:html unsupported (0)
package:priv/some/path.dart 943:10 - dart:js unsupported (1)
package:priv/some/path.dart 195:54 - dart:html unsupported (0)
''',
        ),
      );
      final Dart2WasmTarget target = createTarget();
      await target.build(environment);

      expect(fakeAnalytics.sentEvents, hasLength(1));

      final Event event = fakeAnalytics.sentEvents[0];
      expect(event.eventName, equals(DashEvent.flutterWasmDryRunPackage));
      expect(event.eventData, hasLength(4));
      expect(event.eventData['result'], 'findings');
      expect(event.eventData['exitCode'], 254);
      expect(event.eventData['E0'], '-p,foo:${_fakePackageVersions['foo']}');
      expect(event.eventData['E1'], '-p');
    }),
  );

  test(
    'dry run findings public packages with host app',
    () => testbed.run(() async {
      processManager.addCommand(
        FakeCommand(
          command: commandArgs,
          exitCode: 254,
          stdout: '''
Found incompatibilities with WebAssembly.

package:foo/some/path.dart 6:1 - dart:html unsupported (0)
file:///some/local/path.dart 943:10 - dart:js unsupported (1)
file:///some/local/path.dart 195:54 - dart:html unsupported (0)
package:priv/some/local/path.dart 243:12 - package:js unsupported (2)
''',
        ),
      );
      final Dart2WasmTarget target = createTarget();
      await target.build(environment);

      expect(fakeAnalytics.sentEvents, hasLength(1));

      final Event event = fakeAnalytics.sentEvents[0];
      expect(event.eventName, equals(DashEvent.flutterWasmDryRunPackage));
      expect(event.eventData, hasLength(5));
      expect(event.eventData['result'], 'findings');
      expect(event.eventData['exitCode'], 254);
      expect(event.eventData['E0'], '-h,foo:${_fakePackageVersions['foo']}');
      expect(event.eventData['E1'], '-h');
      expect(event.eventData['E2'], '-h');
    }),
  );

  test(
    'dry run findings public packages with host app and private packages',
    () => testbed.run(() async {
      writePackageConfigFiles(
        directory: fs.currentDirectory,
        packages: _fakePackageVersions.map(
          (k, v) => MapEntry(k, 'file:///path/to/pubcache/.pub-cache/hosted/pub.dev/$k-$v'),
        )..addAll({'priv': 'file:///path/to/local/pkg/private_package'}),
        mainLibName: 'my_app',
      );

      processManager.addCommand(
        FakeCommand(
          command: commandArgs,
          exitCode: 254,
          stdout: '''
Found incompatibilities with WebAssembly.

package:foo/some/path.dart 6:1 - dart:html unsupported (0)
package:priv/some/path.dart 239:15 - dart:html unsupported (0)
file:///some/local/path.dart 943:10 - dart:js unsupported (1)
file:///some/local/path.dart 195:54 - dart:html unsupported (0)
package:priv/some/path.dart 193:32 - package:js unsupported (2)
''',
        ),
      );
      final Dart2WasmTarget target = createTarget();
      await target.build(environment);

      expect(fakeAnalytics.sentEvents, hasLength(1));

      final Event event = fakeAnalytics.sentEvents[0];
      expect(event.eventName, equals(DashEvent.flutterWasmDryRunPackage));
      expect(event.eventData, hasLength(5));
      expect(event.eventData['result'], 'findings');
      expect(event.eventData['exitCode'], 254);
      expect(event.eventData['E0'], '-hp,foo:${_fakePackageVersions['foo']}');
      expect(event.eventData['E1'], '-h');
      expect(event.eventData['E2'], '-p');
    }),
  );

  test(
    'dry run findings deduplicate entries',
    () => testbed.run(() async {
      processManager.addCommand(
        FakeCommand(
          command: commandArgs,
          exitCode: 254,
          stdout: '''
Found incompatibilities with WebAssembly.

package:foo/some/path.dart 6:1 - dart:html unsupported (0)
package:foo/other/path.dart 18:1 - dart:html unsupported (0)
''',
        ),
      );
      final Dart2WasmTarget target = createTarget();
      await target.build(environment);

      expect(fakeAnalytics.sentEvents, hasLength(1));

      final Event event = fakeAnalytics.sentEvents[0];
      expect(event.eventName, equals(DashEvent.flutterWasmDryRunPackage));
      expect(event.eventData, hasLength(3));
      expect(event.eventData['result'], 'findings');
      expect(event.eventData['exitCode'], 254);
      expect(event.eventData['E0'], 'foo:${_fakePackageVersions['foo']}');
    }),
  );

  test(
    'wasm dry run package config load failure',
    () => testbed.run(() async {
      processManager.addCommand(
        FakeCommand(
          command: commandArgs,
          exitCode: 254,
          stdout: '''
Found incompatibilities with WebAssembly.

package:foo/some/path.dart 6:1 - dart:html unsupported (0)
package:bar/some/path.dart 8:10 - package:js unsupported (2)
''',
        ),
      );

      fs.currentDirectory
          .childDirectory('.dart_tool')
          .childFile('package_config.json')
          .writeAsStringSync('Invalid file');

      final Dart2WasmTarget target = createTarget();
      await target.build(environment);

      expect(fakeAnalytics.sentEvents, hasLength(1));

      final Event event = fakeAnalytics.sentEvents[0];
      expect(event.eventName, equals(DashEvent.flutterWasmDryRunPackage));
      expect(event.eventData, hasLength(4));
      expect(event.eventData['result'], 'findings');
      expect(event.eventData['exitCode'], 254);
      expect(event.eventData['error'], 'packageConfigNotLoaded');
      expect(event.eventData['findings'], '0,2');
    }),
  );

  test(
    'wasm dry run package config load failure',
    () => testbed.run(() async {
      processManager.addCommand(
        FakeCommand(
          command: commandArgs,
          exitCode: 254,
          stdout: '''
Found incompatibilities with WebAssembly.

package:foo/some/path.dart 6:1 - dart:html unsupported (0)
package:bar/some/path.dart 8:10 - package:js unsupported (2)
''',
        ),
      );

      fs.currentDirectory
          .childDirectory('.dart_tool')
          .childFile('package_config.json')
          .writeAsStringSync('Invalid file');

      final Dart2WasmTarget target = createTarget();
      await target.build(environment);

      expect(fakeAnalytics.sentEvents, hasLength(1));

      final Event event = fakeAnalytics.sentEvents[0];
      expect(event.eventName, equals(DashEvent.flutterWasmDryRunPackage));
      expect(event.eventData, hasLength(4));
      expect(event.eventData['result'], 'findings');
      expect(event.eventData['exitCode'], 254);
      expect(event.eventData['error'], 'packageConfigNotLoaded');
      expect(event.eventData['findings'], '0,2');
    }),
  );

  test(
    'wasm dry run findings include up to 100 characters',
    () => testbed.run(() async {
      processManager.addCommand(
        FakeCommand(
          command: commandArgs,
          exitCode: 254,
          stdout: '''
Found incompatibilities with WebAssembly.

package:foo/some/path.dart 6:1 - dart:html unsupported (0)
package:lesslong/some/path.dart 9:20 - dart:html unsupported (0)
''',
        ),
      );

      final Dart2WasmTarget target = createTarget();
      await target.build(environment);

      expect(fakeAnalytics.sentEvents, hasLength(1));

      final Event event = fakeAnalytics.sentEvents[0];
      expect(event.eventName, equals(DashEvent.flutterWasmDryRunPackage));
      expect(event.eventData, hasLength(3));
      expect(event.eventData['result'], 'findings');
      expect(event.eventData['exitCode'], 254);
      expect(event.eventData['E0'], hasLength(100));
      expect(
        event.eventData['E0'],
        'foo:${_fakePackageVersions['foo']},lesslong:${_fakePackageVersions['lesslong']}',
      );
    }),
  );

  test(
    'wasm dry run findings truncate longer than 100 characters',
    () => testbed.run(() async {
      processManager.addCommand(
        FakeCommand(
          command: commandArgs,
          exitCode: 254,
          stdout: '''
Found incompatibilities with WebAssembly.

package:foo/some/path.dart 6:1 - dart:html unsupported (0)
package:morelong/some/path.dart 9:20 - dart:html unsupported (0)
''',
        ),
      );

      final Dart2WasmTarget target = createTarget();
      await target.build(environment);

      expect(fakeAnalytics.sentEvents, hasLength(1));

      final Event event = fakeAnalytics.sentEvents[0];
      expect(event.eventName, equals(DashEvent.flutterWasmDryRunPackage));
      expect(event.eventData, hasLength(3));
      expect(event.eventData['result'], 'findings');
      expect(event.eventData['exitCode'], 254);
      expect(event.eventData['E0'], hasLength(10));
      expect(event.eventData['E0'], 'foo:${_fakePackageVersions['foo']}');
    }),
  );
}

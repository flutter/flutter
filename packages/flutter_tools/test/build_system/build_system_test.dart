// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/convert.dart';

import '../src/common.dart';
import '../src/testbed.dart';

void main() {
  group(Target, () {
    Testbed testbed;
    Environment environment;
    Target fooTarget;
    Target barTarget;
    BuildSystem buildSystem;
    int fooInvocations;
    int barInvocations;

    setUp(() {
      fooInvocations = 0;
      barInvocations = 0;
      testbed = Testbed(
        setup: () {
          environment = Environment(
            projectDir: fs.currentDirectory,
            targetPlatform: TargetPlatform.android_arm,
            buildMode: BuildMode.debug,
          );
          fs.file('foo.dart').createSync(recursive: true);
          fs.file('pubspec.yaml').createSync();
          fooTarget = Target(
            name: 'foo',
            inputs: <dynamic>[
              '{PROJECT_DIR}/foo.dart',
            ],
            outputs: <dynamic>[
              '{BUILD_DIR}/out'
            ],
            dependencies: <Target>[],
            invocation: (List<FileSystemEntity> inputs, Environment environment) {
              environment.buildDir.childFile('out')
                ..createSync(recursive: true)
                ..writeAsStringSync('');
              fooInvocations++;
            }
          );
          barTarget = Target(
            name: 'bar',
            inputs: <dynamic>[
              '{BUILD_DIR}/out',
            ],
            outputs: <dynamic>[
              '{BUILD_DIR}/bar',
            ],
            dependencies: <Target>[fooTarget],
            invocation: (List<FileSystemEntity> inputs, Environment environment) {
              environment.buildDir.childFile('bar')
                ..createSync(recursive: true)
                ..writeAsStringSync('');
              barInvocations++;
            }
          );
          buildSystem = BuildSystem(<Target>[
            fooTarget,
            barTarget,
          ]);
        }
      );
    });

    test('Throws exception if asked to build non-existent target', () => testbed.run(() {
      expect(buildSystem.build('not_real', environment), throwsA(isInstanceOf<Exception>()));
    }));

    test('Throws exception if asked to build with missing inputs', () => testbed.run(() {
      // Delete required input file.
      fs.file('foo.dart').deleteSync();

      expect(buildSystem.build('foo', environment), throwsA(isInstanceOf<AssertionError>()));
    }));

    test('Saves a stamp file with inputs and outputs', () => testbed.run(() async {
      await buildSystem.build('foo', environment);

      final File stampFile = fs.file('build/foo.debug.android-arm');
      expect(stampFile.existsSync(), true);

      final Map<String, Object> stampContents = json.decode(stampFile.readAsStringSync());
      expect(stampContents['inputs'], <Object>[
        <Object>[
          contains('/foo.dart'),
          '[212, 29, 140, 217, 143, 0, 178, 4, 233, 128, 9, 152, 236, 248, 66, 126]',
        ]
      ]);
      expect(stampContents['outputs'], <Object>['/build/out']);
      expect(stampContents['build_number'], null);
    }));

    test('Does not re-invoke build if stamp is valid', () => testbed.run(() async {
      await buildSystem.build('foo', environment);
      await buildSystem.build('foo', environment);

      expect(fooInvocations, 1);
    }));

    test('Re-invoke build if input is modified', () => testbed.run(() async {
      await buildSystem.build('foo', environment);

      fs.file('foo.dart').writeAsStringSync('new contents');

      await buildSystem.build('foo', environment);
      expect(fooInvocations, 2);
    }));

    test('Runs dependencies of targets', () => testbed.run(() async {
      await buildSystem.build('bar', environment);

      expect(fs.file('build/bar').existsSync(), true);
      expect(fooInvocations, 1);
      expect(barInvocations, 1);
    }));

    test('Can describe itself with JSON output', () => testbed.run(() {
      expect(fooTarget.toJson(environment), <String, dynamic>{
        'inputs':  <Object>[
          '/foo.dart'
        ],
        'outputs': <Object>[
          '/build/out'
        ],
        'dependencies': <Object>[],
        'name':  'foo',
        'phony': false,
      });
    }));
  });
}
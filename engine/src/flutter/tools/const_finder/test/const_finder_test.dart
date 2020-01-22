// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonEncode;
import 'dart:io';

import 'package:const_finder/const_finder.dart';
import 'package:path/path.dart' as path;

void expect<T>(T value, T expected) {
  if (value != expected) {
    stderr.writeln('Expected: $expected');
    stderr.writeln('Actual:   $value');
    exitCode = -1;
  }
}

final String basePath =
    path.canonicalize(path.join(path.dirname(Platform.script.path), '..'));
final String fixtures = path.join(basePath, 'test', 'fixtures');
final String consts = path.join(fixtures, 'lib', 'consts.dart');
final String dotPackages = path.join(fixtures, '.packages');
final String constsAndNon = path.join(fixtures, 'lib', 'consts_and_non.dart');
final String constsDill = path.join(fixtures, 'consts.dill');
final String constsAndNonDill = path.join(fixtures, 'consts_and_non.dill');

// This test is assuming the `dart` used to invoke the tests is compatible
// with the version of package:kernel in //third-party/dart/pkg/kernel
final String dart = Platform.resolvedExecutable;
final String bat = Platform.isWindows ? '.bat' : '';

void _checkConsts() {
  print('Checking for expected constants.');
  final ConstFinder finder = ConstFinder(
    kernelFilePath: constsDill,
    classLibraryUri: 'package:const_finder_fixtures/target.dart',
    className: 'Target',
  );

  expect<String>(
    jsonEncode(finder.findInstances()),
    jsonEncode(<String, dynamic>{
      'constantInstances': <Map<String, dynamic>>[
        <String, dynamic>{'stringValue': '1', 'intValue': 1, 'targetValue': null},
        <String, dynamic>{'stringValue': '4', 'intValue': 4, 'targetValue': null},
        <String, dynamic>{'stringValue': '2', 'intValue': 2},
        <String, dynamic>{'stringValue': '6', 'intValue': 6, 'targetValue': null},
        <String, dynamic>{'stringValue': '8', 'intValue': 8, 'targetValue': null},
        <String, dynamic>{'stringValue': '10', 'intValue': 10, 'targetValue': null},
        <String, dynamic>{'stringValue': '9', 'intValue': 9},
        <String, dynamic>{'stringValue': '7', 'intValue': 7, 'targetValue': null},
        <String, dynamic>{'stringValue': 'package', 'intValue':-1, 'targetValue': null},
      ],
      'nonConstantLocations': <dynamic>[],
    }),
  );
}

void _checkNonConsts() {
  print('Checking for non-constant instances.');
  final ConstFinder finder = ConstFinder(
    kernelFilePath: constsAndNonDill,
    classLibraryUri: 'package:const_finder_fixtures/target.dart',
    className: 'Target',
  );

  expect<String>(
    jsonEncode(finder.findInstances()),
    jsonEncode(<String, dynamic>{
      'constantInstances': <dynamic>[
        <String, dynamic>{'stringValue': '1', 'intValue': 1, 'targetValue': null},
        <String, dynamic>{'stringValue': '6', 'intValue': 6, 'targetValue': null},
        <String, dynamic>{'stringValue': '8', 'intValue': 8, 'targetValue': null},
        <String, dynamic>{'stringValue': '10', 'intValue': 10, 'targetValue': null},
        <String, dynamic>{'stringValue': '9', 'intValue': 9},
        <String, dynamic>{'stringValue': '7', 'intValue': 7, 'targetValue': null},
      ],
      'nonConstantLocations': <dynamic>[
        <String, dynamic>{
          'file': 'file://$fixtures/lib/consts_and_non.dart',
          'line': 14,
          'column': 26,
        },
        <String, dynamic>{
          'file': 'file://$fixtures/lib/consts_and_non.dart',
          'line': 17,
          'column': 26,
        },
        <String, dynamic>{
          'file': 'file://$fixtures/lib/consts_and_non.dart',
          'line': 19,
          'column': 26,
        },
        <String, dynamic>{
          'file': 'file://$fixtures/pkg/package.dart',
          'line': 10,
          'column': 25,
        }
      ]
    }),
  );
}

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln('The first argument must be the path to the forntend server dill.');
    stderr.writeln('The second argument must be the path to the flutter_patched_sdk');
    exit(-1);
  }
  final String frontendServer = args[0];
  final String sdkRoot = args[1];
  try {
    void _checkProcessResult(ProcessResult result) {
      if (result.exitCode != 0) {
        stdout.writeln(result.stdout);
        stderr.writeln(result.stderr);
      }
      expect(result.exitCode, 0);
    }

    stdout.writeln('Generating kernel fixtures...');
    stdout.writeln(consts);
    _checkProcessResult(Process.runSync(dart, <String>[
      frontendServer,
      '--sdk-root=$sdkRoot',
      '--target=flutter',
      '--aot',
      '--tfa',
      '--packages=$dotPackages',
      '--output-dill=$constsDill',
      consts,
    ]));

    _checkProcessResult(Process.runSync(dart, <String>[
      frontendServer,
      '--sdk-root=$sdkRoot',
      '--target=flutter',
      '--aot',
      '--tfa',
      '--packages=$dotPackages',
      '--output-dill=$constsAndNonDill',
      constsAndNon,
    ]));

    _checkConsts();
    _checkNonConsts();
  } finally {
    try {
      File(constsDill).deleteSync();
      File(constsAndNonDill).deleteSync();
    } finally {
      stdout.writeln('Tests ${exitCode == 0 ? 'succeeded' : 'failed'} - exit code: $exitCode');
    }
  }
}

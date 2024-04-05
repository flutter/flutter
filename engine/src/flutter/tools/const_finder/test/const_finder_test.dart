// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:kernel/const_finder.dart';
import 'package:path/path.dart' as path;

void expect<T>(T value, T expected) {
  if (value != expected) {
    stderr.writeln('Expected: $expected');
    stderr.writeln('Actual:   $value');
    exitCode = -1;
  }
}

void expectInstances(dynamic value, dynamic expected, Compiler compiler) {
  // To ensure we ignore insertion order into maps as well as lists we use
  // DeepCollectionEquality as well as sort the lists.

  int compareByStringValue(dynamic a, dynamic b) {
    return a['stringValue'].compareTo(b['stringValue']) as int;
  }
  value['constantInstances'].sort(compareByStringValue);
  expected['constantInstances'].sort(compareByStringValue);

  final Equality<Object?> equality;
  if (compiler == Compiler.dart2js) {
    equality = const Dart2JSDeepCollectionEquality();
  } else {
    equality = const DeepCollectionEquality();
  }
  if (!equality.equals(value, expected)) {
    stderr.writeln('Expected: ${jsonEncode(expected)}');
    stderr.writeln('Actual:   ${jsonEncode(value)}');
    exitCode = -1;
  }
}

// This test is assuming the `dart` used to invoke the tests is compatible
// with the version of package:kernel in //third-party/dart/pkg/kernel
final String dart = Platform.resolvedExecutable;

void _checkRecursion(String dillPath, Compiler compiler) {
  stdout.writeln('Checking recursive calls.');
  final ConstFinder finder = ConstFinder(
    kernelFilePath: dillPath,
    classLibraryUri: 'package:const_finder_fixtures/box.dart',
    className: 'Box',
  );
  // Will timeout if we did things wrong.
  jsonEncode(finder.findInstances());
}

void _checkConsts(String dillPath, Compiler compiler) {
  stdout.writeln('Checking for expected constants.');
  final ConstFinder finder = ConstFinder(
    kernelFilePath: dillPath,
    classLibraryUri: 'package:const_finder_fixtures/target.dart',
    className: 'Target',
  );
  final Map<String, Object?> expectation = <String, dynamic>{
      'constantInstances': <Map<String, dynamic>>[
        <String, dynamic>{'stringValue': '100', 'intValue': 100, 'targetValue': null},
        <String, dynamic>{'stringValue': '102', 'intValue': 102, 'targetValue': null},
        <String, dynamic>{'stringValue': '101', 'intValue': 101},
        <String, dynamic>{'stringValue': '103', 'intValue': 103, 'targetValue': null},
        <String, dynamic>{'stringValue': '105', 'intValue': 105, 'targetValue': null},
        <String, dynamic>{'stringValue': '104', 'intValue': 104},
        <String, dynamic>{'stringValue': '106', 'intValue': 106, 'targetValue': null},
        <String, dynamic>{'stringValue': '108', 'intValue': 108, 'targetValue': null},
        <String, dynamic>{'stringValue': '107', 'intValue': 107},
        <String, dynamic>{'stringValue': '1', 'intValue': 1, 'targetValue': null},
        <String, dynamic>{'stringValue': '4', 'intValue': 4, 'targetValue': null},
        <String, dynamic>{'stringValue': '2', 'intValue': 2},
        <String, dynamic>{'stringValue': '6', 'intValue': 6, 'targetValue': null},
        <String, dynamic>{'stringValue': '8', 'intValue': 8, 'targetValue': null},
        <String, dynamic>{'stringValue': '10', 'intValue': 10, 'targetValue': null},
        <String, dynamic>{'stringValue': '9', 'intValue': 9},
        <String, dynamic>{'stringValue': '7', 'intValue': 7, 'targetValue': null},
        <String, dynamic>{'stringValue': '11', 'intValue': 11, 'targetValue': null},
        <String, dynamic>{'stringValue': '12', 'intValue': 12, 'targetValue': null},
        <String, dynamic>{'stringValue': 'package', 'intValue':-1, 'targetValue': null},
      ],
      'nonConstantLocations': <dynamic>[],
    };
  if (compiler == Compiler.aot) {
    expectation['nonConstantLocations'] = <Object?>[];
  } else {
    final String fixturesUrl = Platform.isWindows
      ? '/$fixtures'.replaceAll(Platform.pathSeparator, '/')
      : fixtures;

    // Without true tree-shaking, there is a non-const reference in a
    // never-invoked function that will be present in the dill.
    expectation['nonConstantLocations'] = <Object?>[
      <String, dynamic>{
        'file': 'file://$fixturesUrl/pkg/package.dart',
        'line': 14,
        'column': 25,
      },
    ];
  }
  expectInstances(
    finder.findInstances(),
    expectation,
    compiler,
  );

  final ConstFinder finder2 = ConstFinder(
    kernelFilePath: dillPath,
    classLibraryUri: 'package:const_finder_fixtures/target.dart',
    className: 'MixedInTarget',
  );
  expectInstances(
    finder2.findInstances(),
    <String, dynamic>{
      'constantInstances': <Map<String, dynamic>>[
        <String, dynamic>{'val': '13'},
      ],
      'nonConstantLocations': <dynamic>[],
    },
    compiler,
  );
}

void _checkAnnotation(String dillPath, Compiler compiler) {
  stdout.writeln('Checking constant instances in a class annotated with instance of StaticIconProvider are ignored with $compiler');
  final ConstFinder finder = ConstFinder(
    kernelFilePath: dillPath,
    classLibraryUri: 'package:const_finder_fixtures/target.dart',
    className: 'Target',
    annotationClassName: 'StaticIconProvider',
    annotationClassLibraryUri: 'package:const_finder_fixtures/static_icon_provider.dart',
  );
  final Map<String, dynamic> instances = finder.findInstances();
  expectInstances(
    instances,
    <String, dynamic>{
      'constantInstances': <Map<String, Object?>>[
        <String, Object?>{
          'stringValue': 'used1',
          'intValue': 1,
          'targetValue': null,
        },
        <String, Object?>{
          'stringValue': 'used2',
          'intValue': 2,
          'targetValue': null,
        },
      ],
      // TODO(fujino): This should have non-constant locations from the use of
      // a tear-off, see https://github.com/flutter/flutter/issues/116797
      'nonConstantLocations': <Object?>[],
    },
    compiler,
  );
}

void _checkNonConstsFrontend(String dillPath, Compiler compiler) {
  stdout.writeln('Checking for non-constant instances with $compiler');
  final ConstFinder finder = ConstFinder(
    kernelFilePath: dillPath,
    classLibraryUri: 'package:const_finder_fixtures/target.dart',
    className: 'Target',
  );
  final String fixturesUrl = Platform.isWindows
    ? '/$fixtures'.replaceAll(Platform.pathSeparator, '/')
    : fixtures;

  expectInstances(
    finder.findInstances(),
    <String, dynamic>{
      'constantInstances': <dynamic>[
        <String, dynamic>{'stringValue': '1', 'intValue': 1, 'targetValue': null},
        <String, dynamic>{'stringValue': '4', 'intValue': 4, 'targetValue': null},
        <String, dynamic>{'stringValue': '6', 'intValue': 6, 'targetValue': null},
        <String, dynamic>{'stringValue': '8', 'intValue': 8, 'targetValue': null},
        <String, dynamic>{'stringValue': '10', 'intValue': 10, 'targetValue': null},
        <String, dynamic>{'stringValue': '9', 'intValue': 9},
        <String, dynamic>{'stringValue': '7', 'intValue': 7, 'targetValue': null},
      ],
      'nonConstantLocations': <dynamic>[
        <String, dynamic>{
          'file': 'file://$fixturesUrl/lib/consts_and_non.dart',
          'line': 14,
          'column': 26,
        },
        <String, dynamic>{
          'file': 'file://$fixturesUrl/lib/consts_and_non.dart',
          'line': 16,
          'column': 26,
        },
        <String, dynamic>{
          'file': 'file://$fixturesUrl/lib/consts_and_non.dart',
          'line': 16,
          'column': 41,
        },
        <String, dynamic>{
          'file': 'file://$fixturesUrl/lib/consts_and_non.dart',
          'line': 17,
          'column': 26,
        },
        <String, dynamic>{
          'file': 'file://$fixturesUrl/pkg/package.dart',
          'line': 14,
          'column': 25,
        }
      ]
    },
    compiler,
  );
}

// Note, since web dills don't have tree shaking, we aren't able to eliminate
// an additional const versus _checkNonConstFrontend.
void _checkNonConstsWeb(String dillPath, Compiler compiler) {
  assert(compiler == Compiler.dart2js);
  stdout.writeln('Checking for non-constant instances with $compiler');
  final ConstFinder finder = ConstFinder(
    kernelFilePath: dillPath,
    classLibraryUri: 'package:const_finder_fixtures/target.dart',
    className: 'Target',
  );

  final String fixturesUrl = Platform.isWindows
    ? '/$fixtures'.replaceAll(Platform.pathSeparator, '/')
    : fixtures;
  expectInstances(
    finder.findInstances(),
    <String, dynamic>{
      'constantInstances': <dynamic>[
        <String, dynamic>{'stringValue': '1', 'intValue': 1, 'targetValue': null},
        <String, dynamic>{'stringValue': '4', 'intValue': 4, 'targetValue': null},
        <String, dynamic>{'stringValue': '6', 'intValue': 6, 'targetValue': null},
        <String, dynamic>{'stringValue': '8', 'intValue': 8, 'targetValue': null},
        <String, dynamic>{'stringValue': '10', 'intValue': 10, 'targetValue': null},
        <String, dynamic>{'stringValue': '9', 'intValue': 9},
        <String, dynamic>{'stringValue': '7', 'intValue': 7, 'targetValue': null},
        <String, dynamic>{'stringValue': 'package', 'intValue': -1, 'targetValue': null},
      ],
      'nonConstantLocations': <dynamic>[
        <String, dynamic>{
          'file': 'file://$fixturesUrl/lib/consts_and_non.dart',
          'line': 14,
          'column': 26,
        },
        <String, dynamic>{
          'file': 'file://$fixturesUrl/lib/consts_and_non.dart',
          'line': 16,
          'column': 26,
        },
        <String, dynamic>{
          'file': 'file://$fixturesUrl/lib/consts_and_non.dart',
          'line': 16,
          'column': 41,
        },
        <String, dynamic>{
          'file': 'file://$fixturesUrl/lib/consts_and_non.dart',
          'line': 17,
          'column': 26,
        },
        <String, dynamic>{
          'file': 'file://$fixturesUrl/pkg/package.dart',
          'line': 14,
          'column': 25,
        }
      ],
    },
    compiler,
  );
}

void checkProcessResult(ProcessResult result) {
  if (result.exitCode != 0) {
    stdout.writeln(result.stdout);
    stderr.writeln(result.stderr);
  }
  expect(result.exitCode, 0);
}

final String basePath =
    path.canonicalize(path.join(path.dirname(Platform.script.toFilePath()), '..'));
final String fixtures = path.join(basePath, 'test', 'fixtures');
final String packageConfig = path.join(fixtures, '.dart_tool', 'package_config.json');

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln('The first argument must be the path to the frontend server dill.');
    stderr.writeln('The second argument must be the path to the flutter_patched_sdk');
    stderr.writeln('The third argument must be the path to libraries.json');
    exit(-1);
  }

  final String frontendServer = args[0];
  final String sdkRoot = args[1];
  final String librariesSpec = args[2];

  final List<_Test> tests = <_Test>[
    _Test(
      name: 'box_frontend',
      dartSource: path.join(fixtures, 'lib', 'box.dart'),
      frontendServer: frontendServer,
      sdkRoot: sdkRoot,
      librariesSpec: librariesSpec,
      verify: _checkRecursion,
      compiler: Compiler.aot,
    ),
    _Test(
      name: 'box_web',
      dartSource: path.join(fixtures, 'lib', 'box.dart'),
      frontendServer: frontendServer,
      sdkRoot: sdkRoot,
      librariesSpec: librariesSpec,
      verify: _checkRecursion,
      compiler: Compiler.dart2js,
    ),
    _Test(
      name: 'consts_frontend',
      dartSource: path.join(fixtures, 'lib', 'consts.dart'),
      frontendServer: frontendServer,
      sdkRoot: sdkRoot,
      librariesSpec: librariesSpec,
      verify: _checkConsts,
      compiler: Compiler.aot,
    ),
    _Test(
      name: 'consts_web',
      dartSource: path.join(fixtures, 'lib', 'consts.dart'),
      frontendServer: frontendServer,
      sdkRoot: sdkRoot,
      librariesSpec: librariesSpec,
      verify: _checkConsts,
      compiler: Compiler.dart2js,
    ),
    _Test(
      name: 'consts_and_non_frontend',
      dartSource: path.join(fixtures, 'lib', 'consts_and_non.dart'),
      frontendServer: frontendServer,
      sdkRoot: sdkRoot,
      librariesSpec: librariesSpec,
      verify: _checkNonConstsFrontend,
      compiler: Compiler.aot,
    ),
    _Test(
      name: 'consts_and_non_web',
      dartSource: path.join(fixtures, 'lib', 'consts_and_non.dart'),
      frontendServer: frontendServer,
      sdkRoot: sdkRoot,
      librariesSpec: librariesSpec,
      verify: _checkNonConstsWeb,
      compiler: Compiler.dart2js,
    ),
    _Test(
      name: 'static_icon_provider_frontend',
      dartSource: path.join(fixtures, 'lib', 'static_icon_provider.dart'),
      frontendServer: frontendServer,
      sdkRoot: sdkRoot,
      librariesSpec: librariesSpec,
      verify: _checkAnnotation,
      compiler: Compiler.aot,
    ),
    _Test(
      name: 'static_icon_provider_web',
      dartSource: path.join(fixtures, 'lib', 'static_icon_provider.dart'),
      frontendServer: frontendServer,
      sdkRoot: sdkRoot,
      librariesSpec: librariesSpec,
      verify: _checkAnnotation,
      compiler: Compiler.dart2js,
    ),
  ];
  try {
    stdout.writeln('Generating kernel fixtures...');

    for (final _Test test in tests) {
      test.run();
    }
  } finally {
    try {
      for (final _Test test in tests) {
        test.dispose();
      }
    } finally {
      stdout.writeln('Tests ${exitCode == 0 ? 'succeeded' : 'failed'} - exit code: $exitCode');
    }
  }
}

enum Compiler {
  // Uses TFA tree-shaking.
  aot,
  // Does not have TFA tree-shaking.
  dart2js,
}

class _Test {
  _Test({
    required this.name,
    required this.dartSource,
    required this.sdkRoot,
    required this.verify,
    required this.frontendServer,
    required this.librariesSpec,
    required this.compiler,
  }) : dillPath = path.join(fixtures, '$name.dill');

  final String name;
  final String dartSource;
  final String sdkRoot;
  final String frontendServer;
  final String librariesSpec;
  final String dillPath;
  void Function(String, Compiler) verify;
  final Compiler compiler;

  final List<String> resourcesToDispose = <String>[];

  void run() {
    stdout.writeln('Compiling $dartSource to $dillPath with $compiler');

    if (compiler == Compiler.aot) {
      _compileAOTDill();
    } else {
      _compileWebDill();
    }

    stdout.writeln('Testing $dillPath');

    verify(dillPath, compiler);
  }

  void dispose() {
    for (final String resource in resourcesToDispose) {
      stdout.writeln('Deleting $resource');
      File(resource).deleteSync();
    }
  }

  void _compileAOTDill() {
    checkProcessResult(Process.runSync(dart, <String>[
      frontendServer,
      '--sdk-root=$sdkRoot',
      '--target=flutter',
      '--aot',
      '--tfa',
      '--packages=$packageConfig',
      '--output-dill=$dillPath',
      dartSource,
    ]));

    resourcesToDispose.add(dillPath);
  }

  void _compileWebDill() {
    final ProcessResult result = Process.runSync(dart, <String>[
      'compile',
      'js',
      '--libraries-spec=$librariesSpec',
      '-Ddart.vm.product=true',
      '-o',
      dillPath,
      '--packages=$packageConfig',
      '--cfe-only',
      dartSource,
    ]);
    checkProcessResult(result);

    resourcesToDispose.add(dillPath);
  }
}

/// Equality that casts all [num]'s to [double] before comparing.
class Dart2JSDeepCollectionEquality extends DeepCollectionEquality {
  const Dart2JSDeepCollectionEquality();

  @override
  bool equals(Object? e1, Object? e2) {
    if (e1 is num && e2 is num) {
      return e1.toDouble() == e2.toDouble();
    }
    return super.equals(e1, e2);
  }
}

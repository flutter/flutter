// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'package:_test_common/common.dart';

void main() {
  group('build integration tests', () {
    group('build script', () {
      var originalBuildContent = '''
import 'dart:io';
import 'package:build_runner/build_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_test/build_test.dart';

main(List<String> args) async {
  exitCode = await run(
      args, [applyToRoot(new TestBuilder())]);
}
''';
      setUp(() async {
        await d.dir('a', [
          await pubspec('a', currentIsolateDependencies: [
            'build',
            'build_config',
            'build_daemon',
            'build_resolvers',
            'build_runner',
            'build_runner_core',
            'build_test',
            'glob'
          ]),
          d.dir('tool', [d.file('build.dart', originalBuildContent)]),
          d.dir('web', [
            d.file('a.txt', 'a'),
          ]),
        ]).create();

        await pubGet('a');

        // Run a build and validate the output.
        var result = await runDart('a', 'tool/build.dart', args: ['build']);
        expect(result.exitCode, 0, reason: result.stderr as String);
        await d.dir('a', [
          d.dir('web', [d.file('a.txt.copy', 'a')])
        ]).validate();
      });

      test('updates cause a rebuild', () async {
        // Append a newline to the build script!
        await d.dir('a', [
          d.dir('tool', [d.file('build.dart', '$originalBuildContent\n')])
        ]).create();

        // Run a build and validate the full rebuild output.
        var result = await runDart('a', 'tool/build.dart',
            args: ['build', '--delete-conflicting-outputs']);
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout,
            contains('Invalidating asset graph due to build script update'));
        await d.dir('a', [
          d.dir('web', [d.file('a.txt.copy', 'a')])
        ]).validate();
      });

      test('--output creates a merged directory', () async {
        // Run a build and validate the full rebuild output.
        var result = await runDart('a', 'tool/build.dart',
            args: ['build', '--output', 'build']);
        expect(result.exitCode, 0, reason: result.stderr as String);
        await d.dir('a', [
          d.dir('build', [
            d.dir('web', [d.file('a.txt.copy', 'a')])
          ])
        ]).validate();
      });

      test('--output respects build filters', () async {
        await d.dir('a', [
          d.dir('web', [
            d.file('b.txt', 'b'),
          ]),
        ]).create();
        // Run a build and validate the full rebuild output.
        var result = await runDart('a', 'tool/build.dart', args: [
          'build',
          '--output',
          'build',
          '--build-filter',
          'web/b.txt.copy',
        ]);
        expect(result.exitCode, 0, reason: result.stderr as String);
        await d.dir('a', [
          d.dir('build', [
            d.dir('web', [
              d.nothing('a.txt.copy'),
              d.file('b.txt.copy', 'b'),
            ])
          ])
        ]).validate();
      });

      test('when --output fails a proper error code is returned', () async {
        await d.dir('a', [
          d.dir('build', [
            d.file('non_empty', 'blah'),
          ])
        ]).create();
        var result = await runDart('a', 'tool/build.dart',
            args: ['build', '--output', 'build']);
        expect(result.exitCode, 73, reason: result.stderr as String);
      });

      test('--output creates a merged directory from the provided root',
          () async {
        // Run a build and validate the full rebuild output.
        var result = await runDart('a', 'tool/build.dart',
            args: ['build', '--output', 'web:build']);
        expect(result.exitCode, 0, reason: result.stderr as String);
        await d.dir('a', [
          d.dir('build', [d.file('a.txt.copy', 'a')])
        ]).validate();
      });

      test('multiple --output options create multiple merged directories',
          () async {
        // Run a build and validate the full rebuild output.
        var result = await runDart('a', 'tool/build.dart',
            args: ['build', '--output', 'build', '--output', 'foo']);
        expect(result.exitCode, 0, reason: result.stderr as String);
        await d.dir('a', [
          d.dir('build', [
            d.dir('web', [d.file('a.txt.copy', 'a')])
          ]),
          d.dir('foo', [
            d.dir('web', [d.file('a.txt.copy', 'a')])
          ])
        ]).validate();
      });
    });

    group('--build-filter', () {
      setUp(() async {
        await d.dir('a', [
          await pubspec('a', currentIsolateDependencies: [
            'build',
            'build_config',
            'build_daemon',
            'build_resolvers',
            'build_runner',
            'build_runner_core',
            'build_test',
            'glob'
          ], pathDependencies: {
            'b': '../b'
          }),
          d.dir('tool', [
            d.file('build.dart', '''
import 'dart:io';
import 'package:build_runner/build_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_test/build_test.dart';

main(List<String> args) async {
  exitCode = await run(
      args, [
          apply('', [(_) => TestBuilder()], toAllPackages(), hideOutput: true)
      ]);
}
''')
          ]),
          d.dir('lib', [d.file('a.txt', 'a'), d.file('b.txt', 'b')]),
          d.dir('web', [d.file('a.txt', 'a'), d.file('b.txt', 'b')])
        ]).create();

        await d.dir('b', [
          await pubspec('b'),
          d.dir('lib', [d.file('a.txt', 'a'), d.file('b.txt', 'b')])
        ]).create();

        await pubGet('a');
      });

      test('only builds matching files', () async {
        await runBuild(extraArgs: [
          '--build-filter',
          'package:*/a.txt.copy',
          '--build-filter',
          'web/a.txt.copy'
        ]);
        await d.dir('a', [
          d.dir('.dart_tool', [
            d.dir('build', [
              d.dir('generated', [
                d.dir('a', [
                  d.dir('lib', [
                    d.file('a.txt.copy', 'a'),
                    d.nothing('b.txt.copy'),
                  ]),
                  d.dir('web', [
                    d.file('a.txt.copy', 'a'),
                    d.nothing('b.txt.copy'),
                  ])
                ]),
                d.dir('b', [
                  d.dir('lib', [
                    d.file('a.txt.copy', 'a'),
                    d.nothing('b.txt.copy'),
                  ]),
                ]),
              ])
            ])
          ])
        ]).validate();
      });
    });

    group('findAssets', () {
      setUp(() async {
        await d.dir('a', [
          await pubspec('a', currentIsolateDependencies: [
            'build',
            'build_config',
            'build_daemon',
            'build_resolvers',
            'build_runner',
            'build_runner_core',
            'build_test',
            'glob'
          ]),
          d.dir('tool', [
            d.file('build.dart', '''
import 'dart:async';

import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';

main() async {
  await run(
    ['build'],
    [applyToRoot(new GlobbingBuilder(new Glob('**.txt')))]);
}
''')
          ]),
          d.dir('web', [
            d.file('a.globPlaceholder'),
            d.file('a.txt', ''),
            d.file('b.txt', ''),
          ]),
        ]).create();

        await pubGet('a');

        // Run a build and validate the output.
        var result = await runDart('a', 'tool/build.dart', args: ['build']);
        expect(result.exitCode, 0, reason: result.stderr as String);
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt')])
        ]).validate();
      });

      test('picks up new files that match the glob', () async {
        // Add a new file matching the glob.
        await d.dir('a', [
          d.dir('web', [d.file('c.txt', '')])
        ]).create();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart', args: ['build']);
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 1 outputs'));
        await d.dir('a', [
          d.dir('web', [
            d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt\na|web/c.txt')
          ])
        ]).validate();
      });

      test('picks up deleted files that match the glob', () async {
        // Delete a file matching the glob.
        File(p.join(d.sandbox, 'a', 'web', 'a.txt')).deleteSync();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart', args: ['build']);
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 1 outputs'));
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/b.txt')])
        ]).validate();
      });

      test(
          'doesn\'t cause new builds for files that don\'t match '
          'any globs', () async {
        // Add a new file not matching the glob.
        await d.dir('a', [
          d.dir('web', [d.file('c.other', '')])
        ]).create();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart', args: ['build']);
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 0 outputs'));
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt')])
        ]).validate();
      });

      test('doesn\'t cause new builds for file changes', () async {
        // Change a file matching the glob.
        await d.dir('a', [
          d.dir('web', [d.file('a.txt', 'changed!')])
        ]).create();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart', args: ['build']);
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 0 outputs'));
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt')])
        ]).validate();
      });
    });

    group('findAssets with no initial output', () {
      setUp(() async {
        await d.dir('a', [
          await pubspec('a', currentIsolateDependencies: [
            'build',
            'build_config',
            'build_daemon',
            'build_resolvers',
            'build_runner',
            'build_runner_core',
            'build_test',
            'glob'
          ]),
          d.dir('tool', [
            d.file('build.dart', '''
import 'dart:async';

import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';

main() async {
  await run(
    ['build'],
    [applyToRoot(new OverDeclaringGlobbingBuilder(
        new Glob('**.txt')))]);
}

class OverDeclaringGlobbingBuilder extends GlobbingBuilder {
  OverDeclaringGlobbingBuilder(Glob glob) : super(glob);

  @override
  Future build(BuildStep buildStep) async {
    var assets = await buildStep.findAssets(glob).toList();
    // Only output if we have a 'web/b.txt' file.
    if (assets.any((id) => id.path == 'web/b.txt')) {
      await super.build(buildStep);
    }
  }
}
''')
          ]),
          d.dir('web', [
            d.file('a.globPlaceholder'),
            d.file('a.txt', ''),
          ]),
        ]).create();

        await pubGet('a');

        // Run a build and validate the output.
        var result = await runDart('a', 'tool/build.dart', args: ['build']);
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 0 outputs'));
        await d.dir('a', [
          d.dir('web', [d.nothing('a.matchingFiles')])
        ]).validate();
      });

      test('picks up new files that match the glob', () async {
        // Add a new file matching the glob which causes a real output.
        await d.dir('a', [
          d.dir('web', [d.file('b.txt', '')])
        ]).create();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart', args: ['build']);
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 1 outputs'));
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt')])
        ]).validate();
      });
    });

    group('--define overrides build.yaml', () {
      final buildContent = '''
import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_test/build_test.dart';

main(List<String> args) async {
  var buildApplications = [
    apply(
        'root:copy',
        [
          (options) {
            var copyFromId = options.config['copy_from'];
            var build = copyFromId != null ?
                copyFrom(new AssetId.parse(copyFromId)) : null;
            return new TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.txt'),
              build: build);
          }
        ],
        toRoot(),
        hideOutput: false,
        isOptional: false),
  ];
  await run(args, buildApplications);
}
''';

      /// Expects the build output based on [expectedContent].
      Future<void> expectBuildOutput(String expectedContent) async {
        await d.dir('a', [
          d.dir('web', [
            d.file('a.txt', 'a'),
            d.file('a.txt.copy', expectedContent),
          ]),
        ]).validate();
      }

      test('--define overrides build.yaml', () async {
        await d.dir('a', [
          await pubspec('a', currentIsolateDependencies: [
            'build',
            'build_config',
            'build_daemon',
            'build_resolvers',
            'build_runner',
            'build_runner_core',
            'build_test',
          ]),
          d.file('build.yaml', r'''
targets:
  $default:
    builders:
      root:copy:
        options:
          copy_from: a|web/b.txt
'''),
          d.dir('tool', [d.file('build.dart', buildContent)]),
          d.dir('web', [
            d.file('a.txt', 'a'),
            d.file('b.txt', 'b'),
            d.file('c.txt', 'c'),
          ]),
        ]).create();

        await pubGet('a');

        // Run a basic build with no --define config.
        await runBuild();
        await expectBuildOutput('b');

        // Run another build but add the --define.
        await runBuild(extraArgs: ['--define=root:copy=copy_from=a|web/c.txt']);
        await expectBuildOutput('c');
      });
    });
  });

  group('config validation', () {
    final buildContent = '''
import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_test/build_test.dart';

main(List<String> args) async {
  var buildApplications = [
    apply('root:copy', [(_) => new TestBuilder()], toRoot(),
        hideOutput: false, isOptional: false),
  ];
  await run(args, buildApplications);
}
''';

    test('warns on invalid builder key in target options', () async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_config',
          'build_daemon',
          'build_resolvers',
          'build_runner',
          'build_runner_core',
          'build_test',
        ]),
        d.file('build.yaml', r'''
targets:
  $default:
    builders:
      bad:builder:
'''),
        d.dir('tool', [d.file('build.dart', buildContent)]),
        d.dir('web', [
          d.file('a.txt', 'a'),
        ]),
      ]).create();

      await pubGet('a');

      var result = await runBuild();

      expect(result, contains('not a known Builder'));
    });

    test('warns on invalid builder key in global options', () async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_config',
          'build_daemon',
          'build_resolvers',
          'build_runner',
          'build_runner_core',
          'build_test',
        ]),
        d.file('build.yaml', r'''
global_options:
  bad:builder:
'''),
        d.dir('tool', [d.file('build.dart', buildContent)]),
        d.dir('web', [
          d.file('a.txt', 'a'),
        ]),
      ]).create();

      await pubGet('a');

      var result = await runBuild();

      expect(result, contains('not a known Builder'));
    });

    test('warns on invalid builder key --define', () async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_config',
          'build_daemon',
          'build_resolvers',
          'build_runner',
          'build_runner_core',
          'build_test',
        ]),
        d.dir('tool', [d.file('build.dart', buildContent)]),
        d.dir('web', [
          d.file('a.txt', 'a'),
        ]),
      ]).create();

      await pubGet('a');

      var result = await runBuild(extraArgs: ['--define=bad:key=foo=bar']);

      expect(result, contains('not a known Builder'));
    });
  });

  group('regression tests', () {
    test(
        'checking for existing outputs works with deleted '
        'intermediate outputs', () async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_config',
          'build_daemon',
          'build_resolvers',
          'build_runner',
          'build_runner_core',
          'build_test',
          'glob'
        ]),
        d.dir('tool', [
          d.file('build.dart', '''
import 'dart:io';

import 'package:build_runner/build_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_test/build_test.dart';

main() async {
  exitCode = await run(
    ['build'],
    [
      applyToRoot(new TestBuilder()),
      applyToRoot(new TestBuilder(
          buildExtensions: appendExtension('.copy', from: '.txt.copy'))),
    ]);
}
''')
        ]),
        d.dir('web', [
          d.file('a.txt', 'a'),
          d.file('a.txt.copy.copy', 'a'),
        ]),
      ]).create();

      await pubGet('a');

      var result = await runDart('a', 'tool/build.dart', args: ['build']);

      expect(result.exitCode, isNot(0),
          reason: 'build should fail due to conflicting outputs');
      expect(
          result.stdout,
          allOf(contains('Conflicting outputs'),
              contains('web/a.txt.copy.copy')));
    });

    test('Missing build_test dependency reports the right error', () async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_config',
          'build_daemon',
          'build_resolvers',
          'build_runner',
          'build_runner_core',
        ]),
        d.dir('web', [
          d.file('a.txt', 'a'),
        ]),
      ]).create();

      await pubGet('a');
      var result = await runPub('a', 'run', args: ['build_runner', 'test']);

      expect(result.exitCode, isNot(0),
          reason: 'build should fail due to missing build_test dependency');
      expect(result.stdout,
          contains('Missing dev dependency on package:build_test'));
    });

    test('Missing build_web_compilers dependency warns the user', () async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_config',
          'build_daemon',
          'build_resolvers',
          'build_runner',
          'build_runner_core',
          'build_test'
        ]),
        d.dir('web', [
          d.file('a.dart', 'void main() {}'),
        ]),
      ]).create();

      await pubGet('a');
      var result = await startPub('a', 'run', args: ['build_runner', 'serve']);
      addTearDown(result.kill);
      var error = 'Missing dev dependency on package:build_web_compilers';

      await for (final log in result.stdout.transform(utf8.decoder)) {
        if (log.contains(error)) {
          return;
        }
      }

      fail('No warning issued when running the "serve" command');
    });
  });
}

Future<String> runBuild({List<String> extraArgs}) async {
  extraArgs ??= [];
  var buildArgs = ['build', '-o', 'build', ...extraArgs];
  var result = await runDart('a', 'tool/build.dart', args: buildArgs);
  expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  printOnFailure('${result.stdout}\n${result.stderr}');
  return '${result.stdout}';
}

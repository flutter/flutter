// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show IOSink;

import 'package:bazel_tools/bazel_tools.dart';
import 'package:test/test.dart';

/// Builds an `aquery --output=jsonproto` document with one target per
/// action, the way Bazel lays it out.
Map<String, Object?> graph(List<Map<String, Object?>> actions) {
  return <String, Object?>{
    'targets': <Object?>[
      for (var i = 0; i < actions.length; i++)
        <String, Object?>{
          'id': i + 1,
          'label': actions[i].remove('label') ?? '//pkg:target${i + 1}',
          'ruleClassId': 1,
        },
    ],
    'configuration': <Object?>[
      <String, Object?>{'id': 1, 'mnemonic': 'k8-fastbuild', 'platformName': 'k8'},
    ],
    'actions': <Object?>[
      for (var i = 0; i < actions.length; i++)
        <String, Object?>{'targetId': i + 1, 'configurationId': 1, ...actions[i]},
    ],
  };
}

const String clang = 'external/+synced_deps+clang_linux_x64/bin/clang++';

Map<String, Object?> compile(
  List<String> arguments, {
  String? label,
  List<Map<String, String>>? environment,
}) {
  return <String, Object?>{
    if (label != null) 'label': label,
    'mnemonic': 'CppCompile',
    'arguments': <String>[
      clang,
      ...arguments,
      '-c',
      'engine/src/flutter/fml/file.cc',
      '-o',
      'bazel-out/k8-fastbuild/bin/engine/src/flutter/fml/_objs/fml/file.pic.o',
    ],
    'environmentVariables':
        environment ??
        <Map<String, String>>[
          <String, String>{'key': 'PATH', 'value': '/bin:/usr/bin:/usr/local/bin'},
          <String, String>{'key': 'PWD', 'value': '/proc/self/cwd'},
        ],
  };
}

void main() {
  group('absolutePathReferences', () {
    test('finds paths at the start of a token and after separators', () {
      expect(absolutePathReferences('/usr/bin/clang'), <String>['/usr/bin/clang']);
      expect(absolutePathReferences('--sysroot=/usr'), <String>['/usr']);
      expect(absolutePathReferences('-Wl,-rpath,/usr/lib'), <String>['/usr/lib']);
      expect(absolutePathReferences('/bin:/usr/bin:/usr/local/bin'), <String>[
        '/bin',
        '/usr/bin',
        '/usr/local/bin',
      ]);
      expect(absolutePathReferences('-DFIXTURES="/home/me/src/assets"'), <String>[
        '/home/me/src/assets',
      ]);
      expect(absolutePathReferences('-fdebug-prefix-map=/home/me/src=.'), <String>['/home/me/src']);
    });

    test('finds paths joined to include and library flags', () {
      expect(absolutePathReferences('-I/usr/include'), <String>['/usr/include']);
      expect(absolutePathReferences('-isystem/usr/include/c++/12'), <String>[
        '/usr/include/c++/12',
      ]);
      expect(absolutePathReferences('-L/usr/lib/x86_64-linux-gnu'), <String>[
        '/usr/lib/x86_64-linux-gnu',
      ]);
      expect(absolutePathReferences('-F/Library/Frameworks'), <String>['/Library/Frameworks']);
    });

    test('ignores relative paths, labels and flags without paths', () {
      expect(
        absolutePathReferences('bazel-out/k8-fastbuild/bin/engine/src/flutter/fml/libfml.a'),
        isEmpty,
      );
      expect(absolutePathReferences('external/+synced_deps+clang_linux_x64/bin/clang++'), isEmpty);
      expect(absolutePathReferences('--sysroot=external/+synced_deps+sysroot_linux_x64'), isEmpty);
      expect(absolutePathReferences('-Iengine/src'), isEmpty);
      expect(absolutePathReferences('-Iexternal/+synced_deps+icu/source/common'), isEmpty);
      expect(absolutePathReferences('//engine/src/flutter/fml:fml'), isEmpty);
      expect(absolutePathReferences('@@//engine/src/flutter/fml:fml'), isEmpty);
      expect(absolutePathReferences('-DURL="https://flutter.dev/"'), isEmpty);
      expect(absolutePathReferences('-Wl,-z,defs'), isEmpty);
      expect(absolutePathReferences('-std=c++20'), isEmpty);
      expect(
        absolutePathReferences('-Wl,--version-script=engine/src/flutter/shell/exports.lds'),
        isEmpty,
      );
    });
  });

  group('scanActionGraph', () {
    test('accepts a graph that only references the execution root', () {
      final HermeticityReport report = scanActionGraph(
        graph(<Map<String, Object?>>[
          compile(<String>[
            '-Iengine/src',
            '--sysroot=external/+synced_deps+sysroot_linux_x64',
            '-Wall',
          ]),
          <String, Object?>{
            'mnemonic': 'CppLink',
            'arguments': <String>[
              clang,
              '-o',
              'bazel-out/k8-fastbuild/bin/engine/src/flutter/fml/fml_unittests',
              '-Wl,-z,defs',
            ],
            'environmentVariables': <Map<String, String>>[
              <String, String>{'key': 'PATH', 'value': '/bin:/usr/bin:/usr/local/bin'},
            ],
          },
          <String, Object?>{
            'mnemonic': 'TestRunner',
            'arguments': <String>[
              'external/bazel_tools/tools/test/test-setup.sh',
              'engine/src/flutter/fml/fml_unittests',
            ],
          },
        ]),
      );
      expect(report.isHermetic, isTrue, reason: report.violations.join('\n'));
      expect(report.actionCount, 3);
      expect(report.targetCount, 3);
      expect(report.actionsByMnemonic, <String, int>{
        'CppCompile': 1,
        'CppLink': 1,
        'TestRunner': 1,
      });
    });

    test('reports absolute include paths and sysroots', () {
      final HermeticityReport report = scanActionGraph(
        graph(<Map<String, Object?>>[
          compile(<String>[
            '-I/usr/include',
            '--sysroot=/',
            '-isystem',
            '/usr/lib/clang/18/include',
          ], label: '//engine/src/flutter/fml:fml'),
        ]),
      );
      expect(
        report.violations.map((HermeticityViolation v) => v.kind),
        everyElement(HermeticityViolationKind.absolutePath),
      );
      expect(report.violations.map((HermeticityViolation v) => v.toString()), <String>[
        '//engine/src/flutter/fml:fml (CppCompile, k8-fastbuild): absolutePath: /usr/include in argument `-I/usr/include`',
        '//engine/src/flutter/fml:fml (CppCompile, k8-fastbuild): absolutePath: / in argument `--sysroot=/`',
        '//engine/src/flutter/fml:fml (CppCompile, k8-fastbuild): absolutePath: /usr/lib/clang/18/include in argument `/usr/lib/clang/18/include`',
      ]);
    });

    test('reports a compiler outside the hermetic toolchains', () {
      final HermeticityReport report = scanActionGraph(
        graph(<Map<String, Object?>>[
          <String, Object?>{
            'mnemonic': 'CppCompile',
            'arguments': <String>['/usr/bin/gcc', '-c', 'a.cc'],
          },
          <String, Object?>{
            'mnemonic': 'CppArchive',
            'arguments': <String>[
              'external/rules_cc++cc_configure_extension+local_config_cc/cc_wrapper.sh',
              'rcsD',
              'liba.a',
            ],
          },
          <String, Object?>{
            'mnemonic': 'Genrule',
            'arguments': <String>['external/some_tool/bin/tool', 'a.cc'],
          },
        ]),
      );
      expect(
        report.violations.map(
          (HermeticityViolation v) => '${v.mnemonic} ${v.kind.name}: ${v.detail}',
        ),
        <String>[
          'CppCompile executable: runs /usr/bin/gcc',
          'CppCompile absolutePath: /usr/bin/gcc in argument `/usr/bin/gcc`',
          'CppArchive executable: runs external/rules_cc++cc_configure_extension+local_config_cc/cc_wrapper.sh',
        ],
      );
    });

    test(
      'accepts every tool of a clang repository for any platform, and the Emscripten wrappers',
      () {
        for (final executable in <String>[
          'external/+synced_deps+clang_linux_x64/bin/clang',
          'external/+synced_deps+clang_linux_x64/bin/llvm-ar',
          'external/+synced_deps+clang_linux_x64/bin/llvm-strip',
          'external/+synced_deps+clang_mac_arm64/bin/clang++',
          'external/+synced_deps+clang_win_x64/bin/clang-cl.exe',
          'engine/src/flutter/build/bazel/toolchains/emscripten/emcc.sh',
          'engine/src/flutter/build/bazel/toolchains/emscripten/em++.sh',
          'engine/src/flutter/build/bazel/toolchains/emscripten/emar.sh',
        ]) {
          expect(defaultToolchainExecutable.hasMatch(executable), isTrue, reason: executable);
        }
        for (final executable in <String>[
          '/usr/bin/clang',
          'external/local_config_cc/cc_wrapper.sh',
          'external/+synced_deps+emsdk/upstream/emscripten/em++',
          'external/+synced_deps+clang_linux_x64/lib/clang',
        ]) {
          expect(defaultToolchainExecutable.hasMatch(executable), isFalse, reason: executable);
        }
      },
    );

    test('checks environment variables', () {
      final HermeticityReport report = scanActionGraph(
        graph(<Map<String, Object?>>[
          compile(
            <String>['-Wall'],
            environment: <Map<String, String>>[
              <String, String>{'key': 'PATH', 'value': '/usr/local/google/home/me/bin:/usr/bin'},
              <String, String>{'key': 'PWD', 'value': '/proc/self/cwd'},
              <String, String>{'key': 'LD_LIBRARY_PATH', 'value': '/opt/lib'},
              <String, String>{'key': 'CC_FLAGS', 'value': '-O2'},
            ],
          ),
        ]),
      );
      expect(
        report.violations.map((HermeticityViolation v) => '${v.kind.name}: ${v.detail}'),
        <String>[
          'environment: PATH=/usr/local/google/home/me/bin:/usr/bin (expected /bin:/usr/bin:/usr/local/bin)',
          'absolutePath: /opt/lib in environment variable LD_LIBRARY_PATH=/opt/lib',
        ],
      );
    });

    test('scans parameter files', () {
      final HermeticityReport report = scanActionGraph(
        graph(<Map<String, Object?>>[
          <String, Object?>{
            'mnemonic': 'CppLink',
            'arguments': <String>[
              clang,
              '@bazel-out/k8-fastbuild/bin/engine/src/flutter/fml/fml_unittests-2.params',
            ],
            'paramFiles': <Object?>[
              <String, Object?>{
                'execPath':
                    'bazel-out/k8-fastbuild/bin/engine/src/flutter/fml/fml_unittests-2.params',
                'arguments': <String>[
                  '-o',
                  'bazel-out/k8-fastbuild/bin/engine/src/flutter/fml/fml_unittests',
                  '-L/usr/lib',
                  '-lGL',
                ],
              },
            ],
          },
        ]),
      );
      expect(
        report.violations.single.detail,
        '/usr/lib in bazel-out/k8-fastbuild/bin/engine/src/flutter/fml/fml_unittests-2.params line `-L/usr/lib`',
      );
    });

    test('honours the allow list as exact paths or prefixes', () {
      final actions = <Map<String, Object?>>[
        compile(<String>[
          '-fdebug-prefix-map=/proc/self/cwd=.',
          '-fprofile-list=/dev/null',
          '-DX="/opt/tool/bin"',
        ]),
      ];
      expect(
        scanActionGraph(graph(actions)).violations.single.detail,
        '/opt/tool/bin in argument `-DX="/opt/tool/bin"`',
      );
      expect(
        scanActionGraph(
          graph(<Map<String, Object?>>[
            compile(<String>['-DX="/opt/tool/bin"', '-DY="/opt/toolkit"']),
          ]),
          policy: HermeticityPolicy(
            allowedAbsolutePaths: <String>[...defaultAllowedAbsolutePaths, '/opt/tool'],
          ),
        ).violations.single.detail,
        '/opt/toolkit in argument `-DY="/opt/toolkit"`',
      );
    });

    test('names unknown targets and configurations gracefully', () {
      final document = json.decode('''
        {"actions": [{"targetId": 9, "configurationId": 9, "mnemonic": "CppCompile", "arguments": ["/usr/bin/cc"]}]}
      ''') as Map<String, Object?>;
      final HermeticityReport report = scanActionGraph(document);
      expect(
        report.violations.first.toString(),
        '<unknown> (CppCompile, <unknown>): executable: runs /usr/bin/cc',
      );
    });
  });

  group('CheckHermeticityCommand', () {
    test('prints usage for --help and rejects unknown options', () async {
      final help = _Output();
      expect(
        CheckHermeticityCommand.fromCommandLine(
          <String>['--help'],
          stdout: help.stdout,
          stderr: help.stderr,
        ),
        isNull,
      );
      expect(await help.readStdout(), contains('Usage: dart bin/check_hermeticity.dart'));

      final bogus = _Output();
      expect(
        CheckHermeticityCommand.fromCommandLine(
          <String>['--bogus'],
          stdout: bogus.stdout,
          stderr: bogus.stderr,
        ),
        isNull,
      );
      expect(await bogus.readStderr(), contains('Could not find an option named "--bogus"'));
    });

    test('passes options after -- to Bazel and extra allowed paths to the policy', () {
      final CheckHermeticityCommand command = CheckHermeticityCommand.fromCommandLine(<String>[
        '--input',
        'graph.json',
        '--allow=/opt/tool',
        '--',
        '-c',
        'opt',
      ])!;
      expect(command.bazelArguments, <String>['-c', 'opt']);
      expect(command.policy.allows('/opt/tool/bin/x'), isTrue);
      expect(command.policy.allows('/proc/self/cwd'), isTrue);
      expect(command.policy.allows('/opt/toolkit'), isFalse);
      expect(command.repoRoot, isNull);
    });
  });
}

/// Captures what a command writes to its stdout and stderr sinks.
final class _Output {
  _Output() {
    stdout = IOSink(_stdout.sink);
    stderr = IOSink(_stderr.sink);
  }

  final StreamController<List<int>> _stdout = StreamController<List<int>>();
  final StreamController<List<int>> _stderr = StreamController<List<int>>();

  late final IOSink stdout;
  late final IOSink stderr;

  Future<String> readStdout() async {
    final Future<String> text = utf8.decodeStream(_stdout.stream);
    await stdout.close();
    return text;
  }

  Future<String> readStderr() async {
    final Future<String> text = utf8.decodeStream(_stderr.stream);
    await stderr.close();
    return text;
  }
}

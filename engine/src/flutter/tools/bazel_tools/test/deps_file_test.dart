// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:bazel_tools/bazel_tools.dart';
import 'package:test/test.dart';

void main() {
  group('DepsFile.parse', () {
    test('evaluates vars, Var() and {name} substitution like gclient', () {
      final deps = DepsFile.parse('''
# A comment.
vars = {
  'git': 'https://example.googlesource.com',
  'rev': 'abc123',
  'enabled': True,
  'indirect': Var('rev'),  # Var() in vars is kept symbolic.
}

deps = {
  'engine/src/foo': Var('git') + '/foo.git' + '@' + Var('rev'),
  'engine/src/bar': {
    'url': '{git}/bar.git@{rev}',
    'condition': 'host_os == "linux"',
  },
  'engine/src/baz': {
    'url': '{git}/baz.git',
    'dep_type': 'git',
  },
}
''');
      expect(deps.vars, <String, Object?>{
        'git': 'https://example.googlesource.com',
        'rev': 'abc123',
        'enabled': true,
        'indirect': '{rev}',
      });
      expect(deps.deps, hasLength(3));
      final foo = deps.deps[0] as GitDep;
      expect(foo.path, 'engine/src/foo');
      expect(foo.url, 'https://example.googlesource.com/foo.git');
      expect(foo.revision, 'abc123');
      expect(foo.condition, isNull);
      final bar = deps.deps[1] as GitDep;
      expect(bar.url, 'https://example.googlesource.com/bar.git');
      expect(bar.revision, 'abc123');
      expect(bar.condition, 'host_os == "linux"');
      final baz = deps.deps[2] as GitDep;
      expect(baz.revision, isNull);
    });

    test('parses cipd dependencies', () {
      final deps = DepsFile.parse(r'''
vars = {'dart_revision': 'deadbeef'}
deps = {
  'engine/src/flutter/prebuilts/linux-x64/dart-sdk': {
    'packages': [
      {
        'package': 'dart/dart-sdk/${{platform}}',
        'version': 'git_revision:' + Var('dart_revision'),
      },
      {
        'package': 'other/package',
        'version': 'version:2@1.2.3',
      },
    ],
    'condition': 'download_dart_sdk and host_os == "linux"',
    'dep_type': 'cipd',
  },
}
''');
      final CipdDep dep = deps.cipdDeps.single;
      expect(dep.path, 'engine/src/flutter/prebuilts/linux-x64/dart-sdk');
      // `${{platform}}` is a Python format escape for `${platform}`.
      expect(dep.packages, const <CipdPackage>[
        CipdPackage(package: r'dart/dart-sdk/${platform}', version: 'git_revision:deadbeef'),
        CipdPackage(package: 'other/package', version: 'version:2@1.2.3'),
      ]);
      expect(dep.condition, 'download_dart_sdk and host_os == "linux"');
      expect(deps.gitDeps, isEmpty);
    });

    test('keeps host-specific builtin variables as placeholders', () {
      final deps = DepsFile.parse('''
vars = {}
hooks = [
  {
    'name': 'example',
    'pattern': '.',
    'action': ['python3', 'script.py', Var('host_os'), '{host_cpu}'],
  },
]
''');
      expect(deps.hooks.single['action'], <String>[
        'python3',
        'script.py',
        '{host_os}',
        '{host_cpu}',
      ]);
    });

    test('parses the remaining top-level statements', () {
      final deps = DepsFile.parse('''
vars = {'checkout_llvm': False}
gclient_gn_args_file = 'engine/src/build/config/gclient_args.gni'
gclient_gn_args = ['checkout_llvm']
allowed_hosts = ['chromium.googlesource.com']
recursedeps = []
''');
      expect(deps.gclientGnArgsFile, 'engine/src/build/config/gclient_args.gni');
      expect(deps.gclientGnArgs, <String>['checkout_llvm']);
      expect(deps.allowedHosts, <String>['chromium.googlesource.com']);
      expect(deps.recursedeps, isEmpty);
      expect(deps.deps, isEmpty);
    });

    test('supports Python string syntax gclient accepts', () {
      final deps = DepsFile.parse(r'''
vars = {
  "double": "quoted",
  'escaped': 'it\'s a \\ backslash\n',
  'adjacent': 'a' 'b'
              'c',
  'raw': r'\d+',
  'triple': """multi
line""",
  'grouped': ('x' +
              'y'),
  'percent': '%s-%s' % ['a', 'b'],
  'braces': 'literal {{braces}}',
  'number': 42,
  'none': None,
}
''');
      expect(deps.vars, <String, Object?>{
        'double': 'quoted',
        'escaped': "it's a \\ backslash\n",
        'adjacent': 'abc',
        'raw': r'\d+',
        'triple': 'multi\nline',
        'grouped': 'xy',
        'percent': 'a-b',
        // vars itself is not formatted, so the escape is preserved verbatim.
        'braces': 'literal {{braces}}',
        'number': 42,
        'none': null,
      });
    });

    test('formats strings outside vars, including boolean values', () {
      final deps = DepsFile.parse('''
vars = {'flag': True, 'name': 'x'}
hooks = [{'name': 'n', 'pattern': '.', 'action': ['FLAG={flag}', '{{{name}}}']}]
''');
      expect(deps.hooks.single['action'], <String>['FLAG=True', '{x}']);
    });

    group('rejects', () {
      void expectRejects(String source, String messageFragment, {int? line}) {
        expect(
          () => DepsFile.parse(source),
          throwsA(
            isA<DepsFormatException>()
                .having((DepsFormatException e) => e.message, 'message', contains(messageFragment))
                .having((DepsFormatException e) => e.line, 'line', line ?? isPositive),
          ),
        );
      }

      test('undeclared variables', () {
        expectRejects("vars = {}\ndeps = {'a': Var('missing')}", 'missing was used', line: 2);
        expectRejects("vars = {}\ndeps = {'a': '{missing}'}", 'missing was used', line: 2);
      });

      test('statements that are not assignments', () {
        expectRejects('import os', 'expected "="', line: 1);
        expectRejects('vars = {}\nvars = {}', 'overrides var "vars"', line: 2);
      });

      test('unsupported functions and names', () {
        expectRejects("vars = {'a': getcwd()}", 'Str and Var are the only', line: 1);
        expectRejects("vars = {'a': Var()}", 'Var takes exactly one argument', line: 1);
        expectRejects("vars = {'a': Var('b', 'c')}", 'Var takes exactly one argument', line: 1);
        expectRejects("vars = {'a': undefined_name}", 'invalid name', line: 1);
      });

      test('malformed syntax', () {
        expectRejects("vars = {'a': 'b'", 'expected', line: 1);
        expectRejects("vars = {'a': 'unterminated}", 'unterminated string', line: 1);
        expectRejects(
          "vars = {'a': 'b'}\n\ndeps = {'x': 'y' 'z' +}",
          'expected an expression',
          line: 3,
        );
      });

      test('dependencies outside the schema', () {
        expectRejects("vars = {}\ndeps = {'a': 1}", 'must be a string or a dictionary');
        expectRejects("vars = {}\ndeps = {'a': {'dep_type': 'cipd'}}", 'require a packages list');
        expectRejects(
          "vars = {}\ndeps = {'a': {'dep_type': 'svn', 'url': 'u'}}",
          'unsupported dep_type',
        );
        expectRejects(
          "vars = {}\ndeps = {'a': {'url': 'u', 'condition': True}}",
          'condition must be',
        );
      });

      test('non-string dictionary keys and duplicate keys', () {
        expectRejects("vars = {1: 'a'}", 'keys must be strings');
        expectRejects("vars = {'a': 'x', 'a': 'y'}", 'duplicate key');
      });
    });
  });
}

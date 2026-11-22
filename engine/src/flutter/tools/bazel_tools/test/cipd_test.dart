// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:bazel_tools/bazel_tools.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A [CipdResolver] that answers from a table and records what it was asked.
final class _FakeResolver implements CipdResolver {
  _FakeResolver(this.answers);

  /// The answer for each `cipdKey`: a sha256, `null` for a package CIPD does
  /// not have, or a [CipdException] to throw.
  final Map<String, Object?> answers;

  final List<String> asked = <String>[];

  @override
  Future<String?> resolve(String package, String version) async {
    final String key = cipdKey(package, version);
    asked.add(key);
    if (!answers.containsKey(key)) {
      fail('unexpected question: $key');
    }
    final Object? answer = answers[key];
    if (answer is CipdException) {
      throw answer;
    }
    return answer as String?;
  }
}

String _hash(String character) => character * 64;

void main() {
  group('sha256OfInstanceId', () {
    test('reads the hash off an instance id', () {
      // flutter_internal/rbe/reclient_cfgs in DEPS, and the sha256 of its zip.
      expect(
        sha256OfInstanceId('Vk7WiSKwQdBHbCrZ9PtRl3po2WpRFQZSag9M6-sxF_0C'),
        '564ed68922b041d0476c2ad9f4fb51977a68d96a511506526a0f4cebeb3117fd',
      );
    });

    test('is null for tags, refs and other things', () {
      expect(sha256OfInstanceId('git_revision:07d67299a15ce03b053736e2d31a668ee0576987'), isNull);
      expect(sha256OfInstanceId('version:2@1.11.1.chromium.4'), isNull);
      expect(sha256OfInstanceId('latest'), isNull);
      // 44 characters of base64 whose last byte is not the sha256 marker.
      expect(sha256OfInstanceId('Vk7WiSKwQdBHbCrZ9PtRl3po2WpRFQZSag9M6-sxF_0B'), isNull);
      // A sha1 instance id of the old kind.
      expect(sha256OfInstanceId('a' * 40), isNull);
    });
  });

  group('expandCipdPackage', () {
    test('leaves a resolved name alone', () {
      expect(expandCipdPackage('fuchsia/third_party/clang/linux-amd64'), <String>[
        'fuchsia/third_party/clang/linux-amd64',
      ]);
    });

    test('names a templated package once per platform', () {
      expect(expandCipdPackage(r'gn/gn/${platform}'), <String>[
        for (final String platform in cipdPlatforms) 'gn/gn/$platform',
      ]);
      expect(cipdPlatforms, containsAll(<String>['linux-amd64', 'mac-arm64']));
    });
  });

  group('parseResolveVersionResponse', () {
    const body =
        ")]}'\n"
        '{"package":"gn/gn/linux-amd64", "instance":{"hashAlgo":"SHA256", '
        '"hexDigest":"cd330cb4f4e0d8e5c82ca3a583798ea5337fd01308952dbe227c9dd8bc51d854"}, '
        '"registeredBy":"user:someone@example.com", "registeredTs":"2025-09-18T13:04:41.300881Z"}';

    String? parse(int status, String text) =>
        parseResolveVersionResponse(status, text, package: 'gn/gn/linux-amd64', version: 'v');

    test('reads the digest of an answer', () {
      expect(parse(200, body), 'cd330cb4f4e0d8e5c82ca3a583798ea5337fd01308952dbe227c9dd8bc51d854');
    });

    test('is null for a package CIPD does not have or does not show', () {
      expect(parse(404, 'no such package: gn/gn/windows-arm64'), isNull);
      expect(parse(403, 'not visible to unauthenticated callers'), isNull);
    });

    test('throws on anything else', () {
      expect(() => parse(500, 'internal error'), throwsA(isA<CipdException>()));
      expect(() => parse(200, 'not json'), throwsA(isA<CipdException>()));
      expect(
        () => parse(200, '{"instance":{"hashAlgo":"SHA1","hexDigest":"${'a' * 40}"}}'),
        throwsA(isA<CipdException>()),
      );
    });
  });

  group('CIPD_SHA256 in the lock', () {
    final deps = DepsFile.parse(r'''
deps = {
  'engine/src/flutter/build/rbe': {
    'packages': [{'package': 'flutter_internal/rbe/reclient_cfgs', 'version': 'Vk7WiSKwQdBHbCrZ9PtRl3po2WpRFQZSag9M6-sxF_0C'}],
    'dep_type': 'cipd',
  },
  'third_party/ninja': {
    'packages': [{'package': 'infra/3pp/tools/ninja/${{platform}}', 'version': 'version:3@1.12.1'}],
    'dep_type': 'cipd',
  },
}
''');

    test('has a key for every package, a templated one per platform', () {
      expect(cipdLockKeys(deps), <String>[
        'flutter_internal/rbe/reclient_cfgs@Vk7WiSKwQdBHbCrZ9PtRl3po2WpRFQZSag9M6-sxF_0C',
        for (final String platform in cipdPlatforms)
          'infra/3pp/tools/ninja/$platform@version:3@1.12.1',
      ]);
    });

    test('is written sorted and read back as written', () {
      final hashes = <String, String>{
        'infra/3pp/tools/ninja/mac-arm64@version:3@1.12.1': _hash('b'),
        'infra/3pp/tools/ninja/linux-amd64@version:3@1.12.1': _hash('a'),
        'infra/3pp/tools/ninja/windows-amd64@version:3@1.12.1': '',
      };
      final String lock = generateDepsLock(deps, generator: 'g', cipdSha256: hashes);
      expect(
        lock,
        contains('''
CIPD_SHA256 = {
    "infra/3pp/tools/ninja/linux-amd64@version:3@1.12.1": "${_hash('a')}",
    "infra/3pp/tools/ninja/mac-arm64@version:3@1.12.1": "${_hash('b')}",
    "infra/3pp/tools/ninja/windows-amd64@version:3@1.12.1": "",
}
'''),
      );
      expect(parseCipdSha256(lock), hashes);
    });

    test('is an empty dictionary without hashes, and none in a file without it', () {
      expect(generateDepsLock(deps, generator: 'g'), contains('CIPD_SHA256 = {}\n'));
      expect(parseCipdSha256(generateDepsLock(deps, generator: 'g')), isEmpty);
      expect(parseCipdSha256('VARS = {}\n'), isEmpty);
    });
  });

  group('GenDepsCommand and CIPD', () {
    late io.Directory root;
    late io.File lock;

    const reclient =
        'flutter_internal/rbe/reclient_cfgs@Vk7WiSKwQdBHbCrZ9PtRl3po2WpRFQZSag9M6-sxF_0C';
    String ninja(String platform, [String version = 'version:3@1.12.1']) =>
        'infra/3pp/tools/ninja/$platform@$version';

    void writeDeps({String ninjaVersion = 'version:3@1.12.1'}) {
      io.File(p.join(root.path, 'DEPS')).writeAsStringSync('''
deps = {
  'engine/src/flutter/build/rbe': {
    'packages': [{'package': 'flutter_internal/rbe/reclient_cfgs', 'version': 'Vk7WiSKwQdBHbCrZ9PtRl3po2WpRFQZSag9M6-sxF_0C'}],
    'dep_type': 'cipd',
  },
  'third_party/ninja': {
    'packages': [{'package': 'infra/3pp/tools/ninja/\${{platform}}', 'version': '$ninjaVersion'}],
    'dep_type': 'cipd',
  },
}
''');
    }

    Map<String, Object?> answers([String version = 'version:3@1.12.1']) => <String, Object?>{
      for (final String platform in cipdPlatforms)
        ninja(platform, version): platform == 'windows-amd64'
            ? null
            : _hash('${cipdPlatforms.indexOf(platform)}'),
    };

    Future<({int exitCode, String errors})> run(
      List<String> arguments,
      CipdResolver resolver,
    ) async {
      final errors = io.File(p.join(root.path, 'stderr.txt'));
      final io.IOSink sink = errors.openWrite();
      final GenDepsCommand command = GenDepsCommand.fromCommandLine(
        <String>[...arguments, '--repo-root=${root.path}'],
        stderr: sink,
        cipdResolver: resolver,
      )!;
      final int exitCode = await command.run();
      await sink.close();
      return (exitCode: exitCode, errors: errors.readAsStringSync());
    }

    setUp(() {
      root = io.Directory.systemTemp.createTempSync('gen_deps_cipd_test.');
      io.Directory(p.join(root.path, 'engine', 'src', 'flutter')).createSync(recursive: true);
      lock = io.File(p.join(root.path, defaultDepsLockPath));
      writeDeps();
    });

    tearDown(() {
      root.deleteSync(recursive: true);
    });

    test('asks CIPD for a tag once per platform and for an instance id not at all', () async {
      final resolver = _FakeResolver(answers());
      expect((await run(<String>[], resolver)).exitCode, 0);
      expect(resolver.asked, <String>[
        for (final String platform in cipdPlatforms) ninja(platform),
      ]);
      expect(parseCipdSha256(lock.readAsStringSync()), <String, String>{
        reclient: '564ed68922b041d0476c2ad9f4fb51977a68d96a511506526a0f4cebeb3117fd',
        for (final String platform in cipdPlatforms)
          ninja(platform): platform == 'windows-amd64'
              ? ''
              : _hash('${cipdPlatforms.indexOf(platform)}'),
      });
    });

    test('asks nothing again while the pins stand, a missing package included', () async {
      expect((await run(<String>[], _FakeResolver(answers()))).exitCode, 0);
      final String first = lock.readAsStringSync();
      final again = _FakeResolver(<String, Object?>{});
      expect((await run(<String>[], again)).exitCode, 0);
      expect(again.asked, isEmpty);
      expect(lock.readAsStringSync(), first);
    });

    test('--check passes on a current lock and asks nothing', () async {
      expect((await run(<String>[], _FakeResolver(answers()))).exitCode, 0);
      final resolver = _FakeResolver(<String, Object?>{});
      expect((await run(<String>['--check'], resolver)).exitCode, 0);
      expect(resolver.asked, isEmpty);
    });

    test('--check fails after a changed pin, asks nothing and writes nothing', () async {
      expect((await run(<String>[], _FakeResolver(answers()))).exitCode, 0);
      final String before = lock.readAsStringSync();
      writeDeps(ninjaVersion: 'version:3@1.13.0');
      final resolver = _FakeResolver(<String, Object?>{});
      final ({int exitCode, String errors}) result = await run(<String>['--check'], resolver);
      expect(result.exitCode, 1);
      expect(resolver.asked, isEmpty);
      expect(result.errors, contains('no sha256 for ${cipdPlatforms.length} CIPD package(s)'));
      expect(result.errors, contains('with access to the network'));
      expect(lock.readAsStringSync(), before);
    });

    test('a changed pin replaces its hashes and keeps the others', () async {
      expect((await run(<String>[], _FakeResolver(answers()))).exitCode, 0);
      writeDeps(ninjaVersion: 'version:3@1.13.0');
      final resolver = _FakeResolver(answers('version:3@1.13.0'));
      expect((await run(<String>[], resolver)).exitCode, 0);
      expect(resolver.asked, hasLength(cipdPlatforms.length));
      final Map<String, String> hashes = parseCipdSha256(lock.readAsStringSync());
      expect(hashes.keys, contains(reclient));
      expect(hashes.keys, contains(ninja('linux-amd64', 'version:3@1.13.0')));
      expect(hashes.keys, isNot(contains(ninja('linux-amd64'))));
    });

    test('fails without writing when CIPD cannot be asked', () async {
      final resolver = _FakeResolver(<String, Object?>{
        ninja(cipdPlatforms.first): CipdException('no route to host'),
      });
      final ({int exitCode, String errors}) result = await run(<String>[], resolver);
      expect(result.exitCode, 1);
      expect(result.errors, contains('no route to host'));
      expect(result.errors, contains('with access to the network'));
      expect(lock.existsSync(), isFalse);
    });
  });
}

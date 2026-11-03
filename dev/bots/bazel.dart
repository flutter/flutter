// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The shards under Bazel.
//
// `dart dev/bots/test.dart --bazel` -- or a SHARD or SUBSHARD name with a
// `_bazel` suffix, `SHARD=framework_tests SUBSHARD=widgets_bazel`, which is
// how a .ci.yaml target opts in without a change to the flutter_drone
// recipe, which passes the names through as they are -- runs the
// framework_tests and tool shards' tests that have Bazel targets with
//
//   bazelisk test --config=prebuilt_engine <targets>
//
// from the repository root: the tests compiled and run by the repository's
// Bazel rules (build_defs/dart) against the prebuilt engine the flutter tool
// laid in bin/cache -- the same flutter_tester, Dart SDK and platform kernels
// `flutter test` runs them with (build_defs/repositories/flutter_bin_cache.bzl,
// which checks the cache's stamps against bin/cache/engine.stamp and says to
// run `flutter precache` when they differ) -- so that no engine checkout or
// build is needed. The test files of a shard that have no Bazel target (a
// BUILD file's exclusions: tests of the repository's own scripts, a
// browser's) run through `flutter test` and `dart test` as they do without
// --bazel, so that a shard covers the same files either way; the steps that
// are not a package's tests (the test harness checks, `dart fix` goldens,
// Gradle unit tests, app builds) run as before as well. One `bazelisk test`
// runs a shard's targets; numbered subshards slice the same file lists as
// without --bazel.
//
// Bazel's state goes where engine/src/flutter/build/bazel/bazel_ci.py keeps
// it for this checkout (.bazel_ci/ for a developer, the task's temporary
// directory on a bot, BAZEL_CI_HOME overriding both); bazelisk is the one on
// PATH, the engine checkout's (DEPS' download_bazelisk) or a download of the
// release DEPS pins. See engine/src/flutter/build/bazel/README.md.

import 'dart:ffi' show Abi;
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import 'run_command.dart';
import 'utils.dart';

/// The bazelisk release [findBazelisk] downloads when the host has none: the
/// version DEPS pins for the engine's builders (third_party/bazelisk).
const String kBazeliskVersion = '1.30.0';

/// The SHA-256 digests of the release's binaries, by host.
const Map<Abi, String> _bazeliskDigests = <Abi, String>{
  Abi.linuxX64: 'a248ae2b2b62b5baebb748f6fba7203bff1a27e5d01b55399a8406744cb539e8',
  Abi.linuxArm64: 'b2bcc040c213b44586b121bda6d983c35df121b917c3a7a66fb16f2fa0df1a4f',
  Abi.macosX64: 'a0e6468b0c6b812f782d8cbfb05824121f6980c0bd70aaa1774fb8272bb7b2ad',
  Abi.macosArm64: '555d2ff912ccd336d0060bdb5251ef2f62629c6f8fbadb59005a45d5625793ec',
};

/// The release asset for a host, as GitHub names it.
String bazeliskAssetName(Abi abi) {
  return switch (abi) {
    Abi.linuxX64 => 'bazelisk-linux-amd64',
    Abi.linuxArm64 => 'bazelisk-linux-arm64',
    Abi.macosX64 => 'bazelisk-darwin-amd64',
    Abi.macosArm64 => 'bazelisk-darwin-arm64',
    _ => throw UnsupportedError('No bazelisk release is pinned for $abi.'),
  };
}

/// Where Bazel keeps this checkout's state: the output root and bazelisk's
/// download of Bazel.
///
/// What bazel_ci.py (engine/src/flutter/build/bazel) chooses, so that the
/// two share a server and its caches: the checkout's `.bazel_ci/`, which git
/// ignores, for a developer; on a bot the task's temporary directory
/// (TMPDIR, which swarming removes with the task -- the recipe clobbers the
/// checkout before every build, and an output root under it made that take
/// an hour); BAZEL_CI_HOME overrides both.
String bazelHome() {
  final String? override = Platform.environment['BAZEL_CI_HOME'];
  if (override != null && override.isNotEmpty) {
    return override;
  }
  if (isLuci) {
    final String? luciContext = Platform.environment['LUCI_CONTEXT'];
    final String taskTemporaryDirectory =
        Platform.environment['TMPDIR'] ??
        (luciContext == null
            ? Directory.systemTemp.path
            : path.dirname(path.absolute(luciContext)));
    return path.join(taskTemporaryDirectory, 'bazel_ci');
  }
  return path.join(flutterRoot, '.bazel_ci');
}

/// Bazel's startup options: the output root under [bazelHome]; on a bot a
/// server that exits five minutes after its last command (the recipe's
/// process cleanup does not know it, and it would idle into the next task).
List<String> bazelStartupOptions() {
  return <String>[
    '--output_user_root=${path.join(bazelHome(), 'output')}',
    if (isLuci) '--max_idle_secs=300',
  ];
}

/// The environment of the Bazel commands: bazelisk's download of Bazel
/// under [bazelHome].
Map<String, String> bazelEnvironment() {
  return <String, String>{'BAZELISK_HOME': path.join(bazelHome(), 'bazelisk')};
}

/// `bazelisk test`'s options: the prebuilt engine; every target built and
/// run whatever fails, failures' output only; the targets of another host
/// skipped rather than refused (the tool's apple shard is declared on every
/// host); the bots' .bazelrc config and sandbox location.
List<String> bazelTestOptions() {
  return <String>[
    if (isLuci) '--config=ci',
    '--config=prebuilt_engine',
    '--keep_going',
    '--test_output=errors',
    '--skip_incompatible_explicit_targets',
    ..._botSandboxOptions(),
  ];
}

/// `--sandbox_base=/dev/shm` on a bot with a tmpfs of 16 GB or more there
/// (bazel_ci.py's bot_sandbox_options): the trees the sandboxes lay cost a
/// bot's network disk minutes to remove.
List<String> _botSandboxOptions() {
  if (!isLuci || !Platform.isLinux) {
    return const <String>[];
  }
  const base = '/dev/shm';
  if (!Directory(base).existsSync()) {
    return const <String>[];
  }
  final ProcessResult df = Process.runSync('df', <String>['-k', '--output=size', base]);
  if (df.exitCode != 0) {
    return const <String>[];
  }
  final int? kilobytes = int.tryParse((df.stdout as String).trim().split('\n').last.trim());
  if (kilobytes == null || kilobytes < 16 * 1024 * 1024) {
    return const <String>[];
  }
  return const <String>['--sandbox_base=$base'];
}

/// bazelisk: what BAZELISK names, else the one on PATH, else the engine
/// checkout's (third_party/bazelisk, DEPS' download_bazelisk), else a
/// download of release [kBazeliskVersion] under [bazelHome], checked against
/// its digest. Null, an error reported, when there is none to be had.
Future<String?> findBazelisk() async {
  if (dryRun) {
    return 'bazelisk';
  }
  final String? named = Platform.environment['BAZELISK'];
  if (named != null && named.isNotEmpty) {
    return named;
  }
  final executable = 'bazelisk$exe';
  final String searchPath = Platform.environment['PATH'] ?? '';
  for (final String directory in searchPath.split(Platform.isWindows ? ';' : ':')) {
    if (directory.isNotEmpty && File(path.join(directory, executable)).existsSync()) {
      return path.join(directory, executable);
    }
  }
  final String synced = path.join(
    flutterRoot,
    'engine',
    'src',
    'flutter',
    'third_party',
    'bazelisk',
    executable,
  );
  if (File(synced).existsSync()) {
    return synced;
  }
  return _downloadBazelisk();
}

Future<String?> _downloadBazelisk() async {
  final abi = Abi.current();
  final String? digest = _bazeliskDigests[abi];
  if (digest == null) {
    foundError(<String>[
      '${red}No bazelisk for this host ($abi).$reset',
      'Install bazelisk (https://github.com/bazelbuild/bazelisk#installation) or name one in BAZELISK.',
    ]);
    return null;
  }
  final file = File(path.join(bazelHome(), 'bazelisk', 'bazelisk-$kBazeliskVersion$exe'));
  if (file.existsSync() && sha256.convert(file.readAsBytesSync()).toString() == digest) {
    return file.path;
  }
  final url = Uri.https(
    'github.com',
    '/bazelbuild/bazelisk/releases/download/v$kBazeliskVersion/${bazeliskAssetName(abi)}',
  );
  printProgress('Downloading bazelisk $kBazeliskVersion from $url');
  final client = HttpClient();
  try {
    final HttpClientRequest request = await client.getUrl(url);
    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      foundError(<String>[
        '${red}Downloading $url failed: HTTP ${response.statusCode}.$reset',
        'Install bazelisk (https://github.com/bazelbuild/bazelisk#installation) or name one in BAZELISK.',
      ]);
      return null;
    }
    final builder = BytesBuilder(copy: false);
    await response.forEach(builder.add);
    final Uint8List bytes = builder.takeBytes();
    final actual = sha256.convert(bytes).toString();
    if (actual != digest) {
      foundError(<String>[
        '${red}The download of $url has SHA-256 $actual, not the pinned $digest.$reset',
      ]);
      return null;
    }
    file.parent.createSync(recursive: true);
    final partial = File('${file.path}.part');
    partial.writeAsBytesSync(bytes, flush: true);
    if (!Platform.isWindows) {
      final ProcessResult chmod = Process.runSync('chmod', <String>['+x', partial.path]);
      if (chmod.exitCode != 0) {
        foundError(<String>['${red}chmod +x ${partial.path} failed: ${chmod.stderr}$reset']);
        return null;
      }
    }
    partial.renameSync(file.path);
  } finally {
    client.close();
  }
  return file.path;
}

/// The test files under [root]'s [directory] (`test` by default), as paths
/// relative to [root], sorted: what `flutter test` and `dart test` run in
/// [root] (every `*_test.dart` beneath it).
List<String> testFilesUnder(String root, [String directory = 'test']) {
  final tests = Directory(path.join(root, directory));
  if (!tests.existsSync()) {
    return const <String>[];
  }
  return tests
      .listSync(recursive: true)
      .whereType<File>()
      .map<String>((File file) => path.relative(file.path, from: root))
      .where((String file) => path.basename(file).endsWith('_test.dart'))
      .toList()
    ..sort();
}

/// The Bazel target of the test file [file] (a path relative to the
/// repository root, or absolute) under the test suites of the package
/// [package] (`packages/flutter_tools`): `//<package>:<name>`, the name the
/// file's path relative to the package's directory, `.dart` dropped and
/// slashes to underscores (build_defs/dart/dart_test.bzl's dart_tests,
/// flutter_test.bzl's flutter_tests, which declare one target per file).
String bazelTestTarget(String package, String file) {
  final String packageDirectory = path.join(flutterRoot, package);
  final String absolute = path.join(flutterRoot, file);
  if (!path.isWithin(packageDirectory, absolute)) {
    throw ArgumentError('$file is not under //$package.');
  }
  final String relative = path.posix.joinAll(
    path.split(path.relative(absolute, from: packageDirectory)),
  );
  if (!relative.endsWith('.dart')) {
    throw ArgumentError('$file is not a Dart file.');
  }
  return '//$package:${relative.substring(0, relative.length - '.dart'.length).replaceAll('/', '_')}';
}

/// The package of a target label: `//packages/flutter_tools:general_shard` is
/// `packages/flutter_tools`'s.
String bazelPackageOf(String label) {
  if (!label.startsWith('//') || !label.contains(':')) {
    throw ArgumentError('$label is not an absolute label.');
  }
  return label.substring(2, label.indexOf(':'));
}

/// A step's test files under some suites of one package, and what runs the
/// files the suites have no target for.
class _CoveredFiles {
  _CoveredFiles(this.suites, this.root, this.files, this.whole, this.orElse)
    : package = bazelPackageOf(suites.first) {
    for (final String suite in suites) {
      if (bazelPackageOf(suite) != package) {
        throw ArgumentError('${suites.join(', ')} are not all of one package.');
      }
    }
  }

  final List<String> suites;
  final String package;
  final String root;
  final List<String> files;
  final bool whole;
  final Future<void> Function(List<String> files) orElse;

  String target(String file) => bazelTestTarget(package, path.join(root, file));
}

/// A shard's tests under Bazel: the suites and test files it runs in one
/// `bazelisk test`, and the test files that have no Bazel target, which run
/// as they do without --bazel.
class BazelShard {
  final List<String> _suites = <String>[];
  final List<_CoveredFiles> _covered = <_CoveredFiles>[];

  /// Suites that run whole, having no `flutter test` or `dart test` step to
  /// split against: a second build of files another step covers
  /// (widgets_without_creation_locations, the Impeller variants).
  void addSuites(List<String> suites) {
    _suites.addAll(suites);
  }

  /// [suites] (test_suite labels of one package, `//dev/bots:tests`) cover
  /// the test [files] a step runs without --bazel: paths relative to [root],
  /// or absolute. The files the suites have a target for ([bazelTestTarget])
  /// run under Bazel; the rest run through [orElse], as they were given.
  /// With [whole], [files] are every test file the suites could have (a
  /// directory's, not a numbered subshard's slice of it), and the suites
  /// stand for them when all are covered.
  void cover(
    List<String> suites, {
    required String root,
    required List<String> files,
    required Future<void> Function(List<String> files) orElse,
    bool whole = true,
  }) {
    _covered.add(_CoveredFiles(suites, root, files, whole, orElse));
  }

  /// Runs the shard: one `bazelisk query` for the suites' tests, the steps
  /// of the files without one, then one `bazelisk test` of the rest.
  Future<void> run() async {
    // test.dart passes --local-engine* through to `flutter test`.
    if (flutterTestArgs.any((String argument) => argument.startsWith('--local-engine'))) {
      foundError(<String>[
        '$red--bazel runs the tests on the prebuilt engine in bin/cache: it cannot take --local-engine.$reset',
      ]);
      return;
    }
    if (Platform.environment['REDUCED_TEST_SET'] == 'True') {
      print(
        '${yellow}REDUCED_TEST_SET is set, but Bazel runs every test of a target: the whole set runs.$reset',
      );
    }
    final String? bazelisk = await findBazelisk();
    if (bazelisk == null) {
      return;
    }
    final targets = <String>[..._suites];
    if (_covered.isNotEmpty) {
      Set<String>? available;
      if (!dryRun) {
        available = await _queryTests(bazelisk, <String>[
          for (final _CoveredFiles covered in _covered) ...covered.suites,
        ]);
        if (available == null) {
          return;
        }
      }
      for (final _CoveredFiles covered in _covered) {
        final under = <String>[];
        final remainder = <String>[];
        for (final String file in covered.files) {
          final String target = covered.target(file);
          if (available == null || available.contains(target)) {
            under.add(target);
          } else {
            remainder.add(file);
          }
        }
        if (remainder.isEmpty && covered.whole) {
          targets.addAll(covered.suites);
        } else {
          targets.addAll(under);
        }
        if (remainder.isNotEmpty) {
          printProgress(
            '$yellow${remainder.length} of ${covered.files.length} test files of ${covered.suites.join(', ')} '
            'have no Bazel target and run as without --bazel:$reset\n  ${remainder.join('\n  ')}',
          );
          await covered.orElse(remainder);
        }
      }
    }
    if (targets.isEmpty) {
      return;
    }
    printProgress('${green}Running ${targets.length} Bazel targets$reset');
    await runCommand(
      bazelisk,
      <String>[...bazelStartupOptions(), 'test', ...bazelTestOptions(), '--', ...targets],
      workingDirectory: flutterRoot,
      environment: bazelEnvironment(),
    );
  }

  /// The tests of [suites], by label. Null, an error reported, when the
  /// query fails.
  Future<Set<String>?> _queryTests(String bazelisk, List<String> suites) async {
    final CommandResult result = await runCommand(
      bazelisk,
      <String>[
        ...bazelStartupOptions(),
        'query',
        if (isLuci) '--config=ci',
        '--output=label',
        'tests(set(${suites.join(' ')}))',
      ],
      workingDirectory: flutterRoot,
      environment: bazelEnvironment(),
      outputMode: OutputMode.capture,
    );
    if (result.exitCode != 0) {
      return null;
    }
    return <String>{
      for (final String line in result.flattenedStdout!.split('\n'))
        if (line.trim().startsWith('//') || line.trim().startsWith('@')) line.trim(),
    };
  }
}

/// `flutter precache` of the artifact sets the tool's tests want from
/// bin/cache beyond the default ones -- the host desktop's profile and
/// release engines and the web SDK (flutter_bin_cache.bzl's optional sets)
/// -- which the tests' builds through the tool read from their facsimile of
/// the cache, the tool having no network inside the sandbox to fetch them.
Future<void> precacheForBazelToolTests() async {
  final String desktop = switch (Platform.operatingSystem) {
    'macos' => '--macos',
    'windows' => '--windows',
    _ => '--linux',
  };
  await runCommand(flutter, <String>['precache', desktop, '--web'], workingDirectory: flutterRoot);
}

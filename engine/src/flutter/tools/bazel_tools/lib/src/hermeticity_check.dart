// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Scans a Bazel action graph (`bazel aquery --output=jsonproto`) for
/// references to the host that would make a build depend on the machine it
/// runs on: absolute paths in command lines or environment variables, and
/// C/C++ actions that run a compiler other than the hermetic toolchains'.
///
/// The scan is purely textual. It cannot tell whether a tool *behaves*
/// hermetically, only whether an action's command line and environment
/// mention anything outside the execution root; sandboxing and
/// `--incompatible_strict_action_env` cover the rest.
library;

/// Absolute paths an action may mention, as exact paths or path prefixes.
const List<String> defaultAllowedAbsolutePaths = <String>[
  // Bazel sets PWD to this for sandboxed actions, and clang records it as
  // the compilation directory (DW_AT_comp_dir), which is why binaries end
  // up containing no absolute path of the checkout.
  '/proc/self/cwd',
  '/dev/null',
];

/// Environment variables Bazel itself sets on every action, with the only
/// values they are allowed to have.
///
/// `PATH` is the fixed value `--incompatible_strict_action_env` (set in the
/// root `.bazelrc`) gives every action instead of the invoking user's.
const Map<String, String> defaultExpectedEnvironment = <String, String>{
  'PATH': '/bin:/usr/bin:/usr/local/bin',
  'PWD': '/proc/self/cwd',
};

/// The mnemonics of the actions that must run a tool from the hermetic
/// C/C++ toolchains.
const Set<String> defaultToolchainMnemonics = <String>{
  'CppCompile',
  'CppHeaderParsing',
  'CppModuleCompile',
  'CppModuleCodegen',
  'CppLinkstampCompile',
  'CppLink',
  'CppArchive',
  'CppLTOIndexing',
  'CcLtoBackendCompile',
  'CcStrip',
  'ObjcCompile',
  // The Emscripten toolchain's module link (build/bazel/toolchains/emscripten/wasm.bzl).
  'WasmLink',
};

/// What the executable of such an action must look like: a binary inside one
/// of the `clang_<platform>` repositories that `extensions.bzl` defines
/// (`external/<canonical repository name>/bin/<tool>`), or one of the
/// Emscripten toolchain's wrapper scripts
/// (`build/bazel/toolchains/emscripten/{emcc,em++,emar}.sh`), which run the
/// synced SDK's drivers under the engine's Python with the SDK's paths from
/// the action's environment.
///
/// Bazel's auto-detected toolchain would show up as `/usr/bin/gcc` or as a
/// wrapper script under `local_config_cc`, and neither matches; nor does
/// the SDK's own `em++` launcher, which finds things through the host.
final RegExp defaultToolchainExecutable = RegExp(
  r'^(external/[^/]*\bclang_[^/]+/bin/[^/]+'
  r'|engine/src/flutter/build/bazel/toolchains/emscripten/(emcc|em\+\+|emar)\.sh)$',
);

/// What a hermetic action graph may reference outside the execution root.
final class HermeticityPolicy {
  /// Creates a policy; every parameter defaults to the engine's rules.
  HermeticityPolicy({
    this.allowedAbsolutePaths = defaultAllowedAbsolutePaths,
    this.expectedEnvironment = defaultExpectedEnvironment,
    this.toolchainMnemonics = defaultToolchainMnemonics,
    RegExp? toolchainExecutable,
  }) : toolchainExecutable = toolchainExecutable ?? defaultToolchainExecutable;

  /// Absolute paths (exact, or as a prefix followed by `/`) that actions may
  /// mention.
  final List<String> allowedAbsolutePaths;

  /// Environment variables that may be set, with their required values.
  /// Any other variable is scanned for absolute paths like an argument.
  final Map<String, String> expectedEnvironment;

  /// Mnemonics of the actions whose executable must match
  /// [toolchainExecutable].
  final Set<String> toolchainMnemonics;

  /// The pattern the executable of a toolchain action must match.
  final RegExp toolchainExecutable;

  /// Whether [path] is covered by [allowedAbsolutePaths].
  bool allows(String path) {
    return allowedAbsolutePaths.any(
      (String allowed) => path == allowed || path.startsWith('$allowed/'),
    );
  }
}

/// The ways an action can fail the scan.
enum HermeticityViolationKind {
  /// An argument, parameter file line or environment variable mentions an
  /// absolute path that is not allowed.
  absolutePath,

  /// An environment variable Bazel sets has an unexpected value.
  environment,

  /// A C/C++ action runs something other than a hermetic toolchain binary.
  executable,
}

/// One finding of the scan.
final class HermeticityViolation {
  /// Creates a violation.
  const HermeticityViolation({
    required this.label,
    required this.mnemonic,
    required this.configuration,
    required this.kind,
    required this.detail,
  });

  /// The label of the target that owns the action.
  final String label;

  /// The action's mnemonic (`CppCompile`, `CppLink`, ...).
  final String mnemonic;

  /// The configuration the action was analyzed in (`k8-fastbuild`, ...).
  final String configuration;

  /// What went wrong.
  final HermeticityViolationKind kind;

  /// A description of the offending argument or variable.
  final String detail;

  @override
  String toString() => '$label ($mnemonic, $configuration): ${kind.name}: $detail';
}

/// The result of scanning an action graph.
final class HermeticityReport {
  /// Creates a report.
  const HermeticityReport({
    required this.actionCount,
    required this.targetCount,
    required this.actionsByMnemonic,
    required this.violations,
  });

  /// How many actions were scanned.
  final int actionCount;

  /// How many targets own them.
  final int targetCount;

  /// The scanned actions, counted per mnemonic.
  final Map<String, int> actionsByMnemonic;

  /// The findings, in the order of the actions in the graph.
  final List<HermeticityViolation> violations;

  /// Whether nothing was found.
  bool get isHermetic => violations.isEmpty;
}

/// Flags that take their path argument joined to the flag (`-I/usr/include`).
///
/// Everywhere else an absolute path is recognized by what precedes its first
/// `/`; after these prefixes it is recognized unconditionally.
const List<String> _joinedPathFlags = <String>[
  '-isystem',
  '-iquote',
  '-idirafter',
  '-iframework',
  '-isysroot',
  '-imacros',
  '-include',
  '-I',
  '-L',
  '-F',
  '-B',
];

/// An absolute path that starts a token or follows a separator (`=`, `:`,
/// `,`, a quote, ...), including a bare `/` as in `--sysroot=/`. A `/` that
/// continues a relative path such as `bazel-out/k8-fastbuild/...` or starts
/// a label such as `//foo:bar` does not count. The path ends at the next
/// separator.
final RegExp _absolutePath = RegExp(
  r'''(?<![A-Za-z0-9_.+~/-])/(?!/)(?:[A-Za-z0-9_.][^\s:;,="']*)?''',
);

/// Returns the absolute paths mentioned in [text], an argument or an
/// environment variable value.
List<String> absolutePathReferences(String text) {
  final paths = <String>[];
  for (final String flag in _joinedPathFlags) {
    if (text.length > flag.length && text.startsWith(flag) && text[flag.length] == '/') {
      paths.add(text.substring(flag.length));
      return paths;
    }
  }
  for (final RegExpMatch match in _absolutePath.allMatches(text)) {
    paths.add(match[0]!);
  }
  return paths;
}

/// Scans [graph], the decoded JSON of `bazel aquery --output=jsonproto
/// --include_param_files`, against [policy].
HermeticityReport scanActionGraph(Map<String, Object?> graph, {HermeticityPolicy? policy}) {
  final HermeticityPolicy rules = policy ?? HermeticityPolicy();
  final labels = <int, String>{
    for (final Map<String, Object?> target in _objects(graph['targets']))
      _int(target['id']): target['label'] as String? ?? '<unknown>',
  };
  final configurations = <int, String>{
    for (final Map<String, Object?> configuration in _objects(graph['configuration']))
      _int(configuration['id']): configuration['mnemonic'] as String? ?? '<unknown>',
  };

  final violations = <HermeticityViolation>[];
  final actionsByMnemonic = <String, int>{};
  final targetIds = <int>{};
  var actionCount = 0;

  for (final Map<String, Object?> action in _objects(graph['actions'])) {
    actionCount += 1;
    final String mnemonic = action['mnemonic'] as String? ?? '<unknown>';
    actionsByMnemonic.update(mnemonic, (int count) => count + 1, ifAbsent: () => 1);
    final int targetId = _int(action['targetId']);
    targetIds.add(targetId);
    final String label = labels[targetId] ?? '<unknown>';
    final String configuration = configurations[_int(action['configurationId'])] ?? '<unknown>';

    void report(HermeticityViolationKind kind, String detail) {
      violations.add(
        HermeticityViolation(
          label: label,
          mnemonic: mnemonic,
          configuration: configuration,
          kind: kind,
          detail: detail,
        ),
      );
    }

    void scan(String text, String where) {
      for (final String path in absolutePathReferences(text)) {
        if (!rules.allows(path)) {
          report(HermeticityViolationKind.absolutePath, '$path in $where');
        }
      }
    }

    final List<String> arguments = _strings(action['arguments']);
    if (arguments.isNotEmpty && rules.toolchainMnemonics.contains(mnemonic)) {
      final String executable = arguments.first;
      if (!rules.toolchainExecutable.hasMatch(executable)) {
        report(HermeticityViolationKind.executable, 'runs $executable');
      }
    }
    for (final argument in arguments) {
      scan(argument, 'argument `$argument`');
    }
    for (final Map<String, Object?> paramFile in _objects(action['paramFiles'])) {
      final String name = paramFile['execPath'] as String? ?? '<param file>';
      for (final String line in _strings(paramFile['arguments'])) {
        scan(line, '$name line `$line`');
      }
    }
    for (final Map<String, Object?> variable in _objects(action['environmentVariables'])) {
      final String key = variable['key'] as String? ?? '';
      final String value = variable['value'] as String? ?? '';
      final String? expected = rules.expectedEnvironment[key];
      if (expected != null) {
        if (value != expected) {
          report(HermeticityViolationKind.environment, '$key=$value (expected $expected)');
        }
        continue;
      }
      scan(value, 'environment variable $key=$value');
    }
  }

  return HermeticityReport(
    actionCount: actionCount,
    targetCount: targetIds.length,
    actionsByMnemonic: actionsByMnemonic,
    violations: violations,
  );
}

Iterable<Map<String, Object?>> _objects(Object? list) {
  if (list is! List<Object?>) {
    return const <Map<String, Object?>>[];
  }
  return list.whereType<Map<String, Object?>>();
}

List<String> _strings(Object? list) {
  if (list is! List<Object?>) {
    return const <String>[];
  }
  return list.whereType<String>().toList();
}

int _int(Object? value) {
  return switch (value) {
    final int i => i,
    final String s => int.tryParse(s) ?? -1,
    _ => -1,
  };
}

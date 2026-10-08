// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as p;

import 'deps_file.dart';

/// The license header used for generated files that support `#` comments.
const String generatedFileLicenseHeader = '''
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
''';

/// Directories that are not declared in `DEPS` but are created by gclient
/// hooks or by the GN build, relative to the repository root.
///
/// Bazel must ignore them for the same reasons it ignores the synced trees:
/// they are large, change outside of Bazel's knowledge and may contain
/// `BUILD` files that are not meant for this workspace.
const List<String> defaultIgnoredDirectories = <String>[
  // gclient's CIPD cache.
  '.cipd',
  // The framework tool's cache (Dart SDK, engine artifacts, ...).
  'bin/cache',
  // GN output directories; also hosts Bazel's convenience symlinks
  // (see --symlink_prefix in the root .bazelrc).
  'engine/src/out',
  // Populated by gclient hooks (clang, gn, ninja, sysroots, emsdk, ...).
  'engine/src/flutter/buildtools',
  'engine/src/flutter/prebuilts',
  // Downloaded by tools/download_fuchsia_sdk.py.
  'engine/src/third_party/fuchsia-sdk',
];

/// Generates the contents of `deps.lock.bzl` from [deps].
///
/// The result is a Starlark file declaring the dependency pins so that Bazel
/// module extensions can consume them without parsing `DEPS` themselves.
/// Entries are sorted so that the output is stable across runs.
String generateDepsLock(DepsFile deps, {required String generator}) {
  final out = StringBuffer();
  out
    ..write(generatedFileLicenseHeader)
    ..writeln()
    ..writeln('# DO NOT EDIT. Generated from //DEPS by $generator.')
    ..writeln('# Re-run that tool whenever DEPS changes; CI checks that this file is up to date.')
    ..writeln()
    ..writeln('"""Dependency pins mirrored from the repository\'s DEPS file.')
    ..writeln()
    ..writeln('Bazel never runs gclient. During the GN/Bazel transition the trees that')
    ..writeln('gclient syncs are consumed in place (see the root .bazelignore) and the')
    ..writeln('pins below let module extensions fetch the same CIPD packages and git')
    ..writeln('revisions hermetically.')
    ..writeln()
    ..writeln('Conditions are gclient expressions kept verbatim. Strings may contain')
    ..writeln('`{host_os}`-style placeholders for the variables gclient computes per host.')
    ..writeln('"""')
    ..writeln()
    ..writeln('# The `vars` dictionary from DEPS.')
    ..write('VARS = ')
    ..write(_starlark(_sortedMap(deps.vars)))
    ..writeln()
    ..writeln()
    ..writeln('# Git dependencies keyed by checkout path relative to the repository root.')
    ..write('GIT_DEPS = ')
    ..write(
      _starlark(<String, Object?>{
        for (final GitDep dep in _sortedByPath(deps.gitDeps))
          dep.path: <String, Object?>{
            'url': dep.url,
            if (dep.revision != null) 'revision': dep.revision,
            if (dep.condition != null) 'condition': dep.condition,
          },
      }),
    )
    ..writeln()
    ..writeln()
    ..writeln('# CIPD dependencies keyed by install path relative to the repository root.')
    ..write('CIPD_DEPS = ')
    ..write(
      _starlark(<String, Object?>{
        for (final CipdDep dep in _sortedByPath(deps.cipdDeps))
          dep.path: <String, Object?>{
            'packages': <Object?>[
              for (final CipdPackage package in dep.packages)
                <String, Object?>{'package': package.package, 'version': package.version},
            ],
            if (dep.condition != null) 'condition': dep.condition,
          },
      }),
    )
    ..writeln()
    ..writeln()
    ..writeln('# The GN arguments gclient writes to GCLIENT_GN_ARGS_FILE (values in VARS).')
    ..write('GCLIENT_GN_ARGS_FILE = ')
    ..write(_starlark(deps.gclientGnArgsFile))
    ..writeln()
    ..writeln()
    ..write('GCLIENT_GN_ARGS = ')
    ..write(_starlark(deps.gclientGnArgs))
    ..writeln();
  return out.toString();
}

/// Generates the contents of the root `.bazelignore` from [deps].
///
/// Every dependency path plus [extraDirectories] is listed, after removing
/// entries nested inside another entry (ignoring a directory ignores its
/// subtree). `.bazelignore` has no glob support, so every directory is
/// spelled out. [extraDirectories] defaults to [defaultIgnoredDirectories].
String generateBazelignore(
  DepsFile deps, {
  required String generator,
  List<String> extraDirectories = defaultIgnoredDirectories,
}) {
  final directories = <String>{
    for (final Dep dep in deps.deps) p.posix.normalize(dep.path),
    for (final String directory in extraDirectories) p.posix.normalize(directory),
  };
  final List<String> sorted = directories.toList()..sort();
  final pruned = <String>[];
  for (final directory in sorted) {
    final bool nested = pruned.any((String parent) => p.posix.isWithin(parent, directory));
    if (!nested) {
      pruned.add(directory);
    }
  }

  final out = StringBuffer();
  out
    ..writeln('# DO NOT EDIT. Generated from //DEPS by $generator.')
    ..writeln('#')
    ..writeln('# Directories Bazel must not treat as part of this workspace: the trees that')
    ..writeln('# gclient syncs or its hooks populate (several ship their own BUILD files), the')
    ..writeln('# GN output directories and tool caches. Ignoring a directory ignores its')
    ..writeln('# subtree, so nested entries are omitted.');
  pruned.forEach(out.writeln);
  return out.toString();
}

Iterable<T> _sortedByPath<T extends Dep>(Iterable<T> deps) =>
    deps.toList()..sort((T a, T b) => a.path.compareTo(b.path));

Map<String, Object?> _sortedMap(Map<String, Object?> map) {
  final List<String> keys = map.keys.toList()..sort();
  return <String, Object?>{for (final String key in keys) key: map[key]};
}

/// Renders [value] as a Starlark literal in Buildifier's style.
///
/// Scalars are rendered inline; non-empty lists and dictionaries are rendered
/// one element per line with trailing commas and four-space indentation.
String _starlark(Object? value, [int indent = 0]) {
  final String pad = '    ' * indent;
  final String innerPad = '    ' * (indent + 1);
  switch (value) {
    case null:
      return 'None';
    case true:
      return 'True';
    case false:
      return 'False';
    case final int i:
      return '$i';
    case final String s:
      return _quote(s);
    case final List<Object?> list:
      if (list.isEmpty) {
        return '[]';
      }
      final out = StringBuffer('[\n');
      for (final element in list) {
        out.writeln('$innerPad${_starlark(element, indent + 1)},');
      }
      return (out..write('$pad]')).toString();
    case final Map<String, Object?> map:
      if (map.isEmpty) {
        return '{}';
      }
      final out = StringBuffer('{\n');
      for (final MapEntry<String, Object?> entry in map.entries) {
        out.writeln('$innerPad${_quote(entry.key)}: ${_starlark(entry.value, indent + 1)},');
      }
      return (out..write('$pad}')).toString();
    default:
      throw ArgumentError.value(value, 'value', 'cannot be rendered as Starlark');
  }
}

String _quote(String s) {
  final out = StringBuffer('"');
  for (final int unit in s.codeUnits) {
    switch (unit) {
      case 0x22: // "
        out.write(r'\"');
      case 0x5c: // \
        out.write(r'\\');
      case 0x0a:
        out.write(r'\n');
      case 0x0d:
        out.write(r'\r');
      case 0x09:
        out.write(r'\t');
      default:
        out.writeCharCode(unit);
    }
  }
  return (out..write('"')).toString();
}

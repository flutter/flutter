// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// A hosted package of a `pubspec.lock`: fetched from a pub server as an
/// archive, which the lock pins by its sha256.
final class HostedPackage {
  /// A hosted package [name] at [version], the [sha256] of its archive, from
  /// the pub server at [url].
  const HostedPackage({
    required this.name,
    required this.version,
    required this.sha256,
    required this.url,
  });

  /// The package's name.
  final String name;

  /// The resolved version.
  final String version;

  /// The sha256 of the package archive (`<url>/api/archives/<name>-<version>.tar.gz`).
  final String sha256;

  /// The pub server (`https://pub.dev`).
  final String url;

  /// The archive's URL, as pub downloads it.
  String get archiveUrl => '$url/api/archives/$name-$version.tar.gz';
}

/// What a `pubspec.lock` resolves: the hosted packages, pinned, and the
/// packages of the other sources by name (the SDK's, the git and path ones),
/// which the Bazel side provides otherwise or does without.
final class PubLock {
  /// A lock of [hosted] packages and [others].
  const PubLock({required this.hosted, required this.others});

  /// The hosted packages, by name.
  final Map<String, HostedPackage> hosted;

  /// The packages of every other source: name to source (`sdk`, `git`, `path`).
  final Map<String, String> others;

  /// Parses the YAML of a `pubspec.lock`.
  static PubLock parse(String lockYaml, {String? fileName}) {
    final Object? document = loadYaml(
      lockYaml,
      sourceUrl: fileName == null ? null : Uri.file(fileName),
    );
    if (document is! YamlMap) {
      throw FormatException('pubspec.lock is not a map', fileName);
    }
    final Object? packages = document['packages'];
    if (packages is! YamlMap) {
      throw FormatException('pubspec.lock has no packages map', fileName);
    }
    final hosted = <String, HostedPackage>{};
    final others = <String, String>{};
    for (final MapEntry<Object?, Object?> entry in packages.entries) {
      final name = entry.key.toString();
      final Object? package = entry.value;
      if (package is! YamlMap) {
        throw FormatException('package $name is not a map', fileName);
      }
      final source = package['source'].toString();
      if (source != 'hosted') {
        others[name] = source;
        continue;
      }
      final Object? description = package['description'];
      if (description is! YamlMap) {
        throw FormatException('hosted package $name has no description', fileName);
      }
      final Object? sha256 = description['sha256'];
      final Object? url = description['url'];
      final Object? version = package['version'];
      if (sha256 is! String || url is! String || version == null) {
        throw FormatException('hosted package $name lacks sha256, url or version', fileName);
      }
      hosted[name] = HostedPackage(
        name: name,
        version: version.toString(),
        sha256: sha256,
        url: url,
      );
    }
    return PubLock(
      hosted: Map<String, HostedPackage>.unmodifiable(hosted),
      others: Map<String, String>.unmodifiable(others),
    );
  }
}

/// The dependencies a `pubspec.yaml` declares, by name: `dependencies` and
/// `dev_dependencies` (the versions and sources are the lock's business).
final class PubspecDependencies {
  /// A pubspec's [dependencies] and [devDependencies], each sorted.
  const PubspecDependencies({required this.dependencies, required this.devDependencies});

  /// The names under `dependencies`.
  final List<String> dependencies;

  /// The names under `dev_dependencies`.
  final List<String> devDependencies;

  /// Parses the YAML of a `pubspec.yaml`.
  static PubspecDependencies parse(String pubspecYaml, {String? fileName}) {
    final Object? document = loadYaml(
      pubspecYaml,
      sourceUrl: fileName == null ? null : Uri.file(fileName),
    );
    if (document is! YamlMap) {
      throw FormatException('pubspec.yaml is not a map', fileName);
    }
    List<String> names(String key) {
      final Object? section = document[key];
      if (section == null) {
        return const <String>[];
      }
      if (section is! YamlMap) {
        throw FormatException('pubspec.yaml: $key is not a map', fileName);
      }
      return section.keys.map((Object? name) => name.toString()).toList()..sort();
    }

    return PubspecDependencies(
      dependencies: names('dependencies'),
      devDependencies: names('dev_dependencies'),
    );
  }
}

/// A package of the repository's own tree -- a member of the root
/// `pubspec.yaml`'s workspace, or a package the lock takes by path -- with
/// the dependencies its pubspec declares.
final class WorkspacePackage {
  /// The package [name] at [path] under the repository root, with its
  /// [dependencies].
  const WorkspacePackage({required this.name, required this.path, required this.dependencies});

  /// The package's name.
  final String name;

  /// The package's directory, relative to the repository root, with `/`.
  final String path;

  /// What its pubspec declares.
  final PubspecDependencies dependencies;
}

/// The repository's pub workspace as `pub get` resolved it: the lock's
/// packages with the dependency graph their pubspecs declare, read from
/// `.dart_tool/package_config.json` (which says where every package is: the
/// hosted ones in the pub cache, the workspace's in the tree).
///
/// The graph is what lets a Bazel target name the packages it reaches
/// instead of all of them: `pub_package_config` (pub.bzl) walks it to the
/// closure of a package's dependencies, fetching only those.
final class PubWorkspace {
  /// A workspace of the lock's [hostedDependencies] and the tree's [packages].
  const PubWorkspace({required this.hostedDependencies, required this.packages});

  /// Each hosted package's `dependencies`, by name.
  final Map<String, List<String>> hostedDependencies;

  /// The repository's own packages, by name.
  final Map<String, WorkspacePackage> packages;

  /// Resolves the workspace of [lock] from a `package_config.json` at
  /// [packageConfigUri] (its `rootUri`s are relative to it) under the
  /// repository at [repositoryRoot]; [readPubspec] returns the contents of a
  /// package root's `pubspec.yaml`, or null when there is none.
  ///
  /// Every hosted package of the lock must be in the configuration with a
  /// readable pubspec (it is, after `pub get`); the SDK's and git packages
  /// are left to [PubLock.others]. Throws a [FormatException] otherwise.
  static PubWorkspace resolve({
    required PubLock lock,
    required String packageConfigJson,
    required Uri packageConfigUri,
    required Uri repositoryRoot,
    required String? Function(Uri pubspec) readPubspec,
  }) {
    final Object? document = jsonDecode(packageConfigJson);
    if (document is! Map<String, Object?> || document['packages'] is! List<Object?>) {
      throw FormatException('package_config.json has no packages list', packageConfigUri);
    }
    final String root = repositoryRoot.toFilePath(windows: false);
    final hosted = <String, List<String>>{};
    final packages = <String, WorkspacePackage>{};
    for (final entry in document['packages']! as List<Object?>) {
      if (entry is! Map<String, Object?> ||
          entry['name'] is! String ||
          entry['rootUri'] is! String) {
        throw FormatException(
          'package_config.json: a package lacks name or rootUri',
          packageConfigUri,
        );
      }
      final name = entry['name']! as String;
      // A root URI may lack its trailing slash (pub writes none for the
      // hosted packages); a directory's URI needs it to resolve against.
      final rootUri = entry['rootUri']! as String;
      final Uri packageRoot = packageConfigUri.resolve(
        rootUri.endsWith('/') ? rootUri : '$rootUri/',
      );
      final Uri pubspecUri = packageRoot.resolve('pubspec.yaml');
      final String? source = lock.others[name];
      if (source == 'sdk' || source == 'git') {
        continue;
      }
      PubspecDependencies dependencies() {
        final String? pubspec = readPubspec(pubspecUri);
        if (pubspec == null) {
          throw FormatException(
            'package $name has no pubspec at $pubspecUri (run `pub get` first)',
            packageConfigUri,
          );
        }
        return PubspecDependencies.parse(pubspec, fileName: pubspecUri.toFilePath());
      }

      if (lock.hosted.containsKey(name)) {
        hosted[name] = dependencies().dependencies;
        continue;
      }
      final String rootPath = packageRoot.toFilePath(windows: false);
      if (!p.posix.isWithin(root, rootPath) && !p.posix.equals(root, rootPath)) {
        throw FormatException(
          'package $name is neither hosted nor in the repository: $packageRoot',
          packageConfigUri,
        );
      }
      packages[name] = WorkspacePackage(
        name: name,
        path: p.posix.normalize(p.posix.relative(rootPath, from: root)),
        dependencies: dependencies(),
      );
    }
    final List<String> unresolved =
        lock.hosted.keys.where((String n) => !hosted.containsKey(n)).toList()..sort();
    if (unresolved.isNotEmpty) {
      throw FormatException(
        'hosted packages of the lock missing from package_config.json (run `pub get` first): '
        '${unresolved.join(', ')}',
        packageConfigUri,
      );
    }
    return PubWorkspace(
      hostedDependencies: Map<String, List<String>>.unmodifiable(hosted),
      packages: Map<String, WorkspacePackage>.unmodifiable(packages),
    );
  }
}

void _writeNames(
  StringBuffer buffer,
  String field,
  List<String> names, {
  String indent = '        ',
}) {
  if (names.isEmpty) {
    buffer.writeln('$indent$field = [],');
    return;
  }
  buffer.writeln('$indent$field = [');
  for (final name in names) {
    buffer.writeln('$indent    "$name",');
  }
  buffer.writeln('$indent],');
}

/// Renders [lock] and [workspace] as `pub.lock.bzl`: `PUB_HOSTED`, the hosted
/// packages by name with version, sha256, archive URL and dependencies, for
/// the `pub` module extension to fetch and `pub_package_config` to walk;
/// `PUB_WORKSPACE`, the repository's own packages with their paths and
/// dependencies; and `PUB_OTHER_SOURCES`, the rest by source, on record.
String generatePubLock(PubLock lock, PubWorkspace workspace, {required String generator}) {
  final buffer = StringBuffer()
    ..writeln('# Copyright 2013 The Flutter Authors. All rights reserved.')
    ..writeln('# Use of this source code is governed by a BSD-style license that can be')
    ..writeln('# found in the LICENSE file.')
    ..writeln()
    ..writeln("# DO NOT EDIT. Generated from //pubspec.lock and the packages' pubspecs by")
    ..writeln('# $generator.')
    ..writeln(
      '# Re-run that tool whenever pubspec.lock or a pubspec.yaml changes; CI checks that this file is up to date.',
    )
    ..writeln()
    ..writeln("\"\"\"The pub packages of the repository's workspace, as pubspec.lock pins them.")
    ..writeln()
    ..writeln("The `pub` module extension (pub.bzl) fetches each hosted package's archive")
    ..writeln("from its pub server and verifies it against the lock's sha256, so the")
    ..writeln("workspace's dependencies are repositories Bazel caches like any other,")
    ..writeln('with no pub cache or `pub get` involved -- and only the packages a target')
    ..writeln("reaches: each package's dependencies are here, for pub_package_config to")
    ..writeln("walk. The packages of the other sources -- the Flutter SDK's own")
    ..writeln('(sky_engine, which the engine builds) and the git ones -- are listed for')
    ..writeln('the record; the Bazel side provides them from the tree or does without.')
    ..writeln('"""')
    ..writeln()
    ..writeln("# name: (version, sha256 of the archive, the archive's URL, the names under")
    ..writeln('# its `dependencies`).')
    ..writeln('PUB_HOSTED = {');
  for (final String name in lock.hosted.keys.toList()..sort()) {
    final HostedPackage package = lock.hosted[name]!;
    buffer
      ..writeln('    "$name": struct(')
      ..writeln('        version = "${package.version}",')
      ..writeln('        sha256 = "${package.sha256}",')
      ..writeln('        url = "${package.archiveUrl}",');
    _writeNames(buffer, 'deps', workspace.hostedDependencies[name] ?? const <String>[]);
    buffer.writeln('    ),');
  }
  buffer
    ..writeln('}')
    ..writeln()
    ..writeln("# name: (the package's directory under the repository root, the names under")
    ..writeln('# its `dependencies` and under its `dev_dependencies`).')
    ..writeln('PUB_WORKSPACE = {');
  for (final String name in workspace.packages.keys.toList()..sort()) {
    final WorkspacePackage package = workspace.packages[name]!;
    buffer
      ..writeln('    "$name": struct(')
      ..writeln('        path = "${package.path}",');
    _writeNames(buffer, 'deps', package.dependencies.dependencies);
    _writeNames(buffer, 'dev_deps', package.dependencies.devDependencies);
    buffer.writeln('    ),');
  }
  buffer
    ..writeln('}')
    ..writeln()
    ..writeln(
      '# name: source, for the packages the lock takes from neither a pub server nor the tree.',
    )
    ..writeln('PUB_OTHER_SOURCES = {');
  for (final String name in lock.others.keys.toList()..sort()) {
    if (workspace.packages.containsKey(name)) {
      continue;
    }
    buffer.writeln('    "$name": "${lock.others[name]}",');
  }
  buffer.writeln('}');
  return buffer.toString();
}

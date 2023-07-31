// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library pubspec.spec;

import 'dart:async';
import 'dart:io' hide Platform;

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'executable.dart';
import 'json_utils.dart';
import 'dependency.dart';
import 'platform.dart';
import 'yaml_to_string.dart';

/// Represents a [pubspec](https://www.dartlang.org/tools/pub/pubspec.html).
///
/// Example Usage:
///
///
///     // load it
///     var pubSpec = await PubSpec.load(myDirectory);
///
///     // change the dependencies to a single path dependency on project 'foo'
///     var PubSpec = pubSpec.copy(dependencies: { 'foo': PathReference('../foo') });
///
///     // save it
///     await PubSpec.save(myDirectory);
///
///
class PubSpec implements Jsonable {
  final String? name;

  final String? author;

  final Version? version;

  final String? homepage;

  final String? documentation;

  final String? description;

  final Uri? publishTo;

  final Environment? environment;

  final Map<String, DependencyReference> dependencies;

  final Map<String, DependencyReference> devDependencies;

  /// [dependencies] and [devDependencies] combined.
  /// Does not include [dependencyOverrides]
  Map<String, DependencyReference> get allDependencies {
    final all = <String, DependencyReference>{};

    dependencies.forEach((k, v) {
      all[k] = v;
    });

    devDependencies.forEach((k, v) {
      all[k] = v;
    });

    return all;
  }

  final Map<String, DependencyReference> dependencyOverrides;

  final Map<String, Executable> executables;

  final Map<String, Platform> platforms;

  final Map? unParsedYaml;

  const PubSpec(
      {this.name,
      this.author,
      this.version,
      this.homepage,
      this.documentation,
      this.description,
      this.publishTo,
      this.environment,
      this.dependencies: const {},
      this.devDependencies: const {},
      this.dependencyOverrides: const {},
      this.executables: const {},
      this.platforms: const {},
      this.unParsedYaml: const {}});

  factory PubSpec.fromJson(Map? json) {
    final p = parseJson(json, consumeMap: true);
    return PubSpec(
        name: p.single('name'),
        author: p.single('author'),
        version: p.single('version', (v) => Version.parse(v)),
        homepage: p.single('homepage'),
        documentation: p.single('documentation'),
        description: p.single('description'),
        publishTo: p.single('publish_to', (v) => Uri.parse(v)),
        environment: p.single('environment', (v) => Environment.fromJson(v)),
        dependencies:
            p.mapValues('dependencies', (v) => DependencyReference.fromJson(v)),
        devDependencies: p.mapValues(
            'dev_dependencies', (v) => DependencyReference.fromJson(v)),
        dependencyOverrides: p.mapValues(
            'dependency_overrides', (v) => DependencyReference.fromJson(v)),
        executables: p.mapEntries<String, Executable, String?>(
            'executables', (k, v) => Executable.fromJson(k, v)),
        platforms: p.mapEntries<String, Platform, String?>(
            'platforms', (k, v) => Platform.fromJson(k)),
        unParsedYaml: p.unconsumed);
  }

  factory PubSpec.fromYamlString(String yamlString) =>
      PubSpec.fromJson(loadYaml(yamlString));

  /// loads the pubspec from the [projectDirectory]
  static Future<PubSpec> load(Directory projectDirectory) =>
      loadFile(p.join(projectDirectory.path, 'pubspec.yaml'));

  /// loads the pubspec from the [file]
  static Future<PubSpec> loadFile(String file) async =>
      PubSpec.fromJson(loadYaml(await File(file).readAsString()));

  /// creates a copy of the pubspec with the changes provided
  PubSpec copy({
    String? name,
    String? author,
    Version? version,
    String? homepage,
    String? documentation,
    String? description,
    Uri? publishTo,
    Environment? environment,
    Map<String, DependencyReference>? dependencies,
    Map<String, DependencyReference>? devDependencies,
    Map<String, DependencyReference>? dependencyOverrides,
    Map<String, Executable>? executables,
    Map<String, Platform>? platforms,
    Map? unParsedYaml,
  }) {
    return PubSpec(
        name: name ?? this.name,
        author: author ?? this.author,
        version: version ?? this.version,
        homepage: homepage ?? this.homepage,
        documentation: documentation ?? this.documentation,
        description: description ?? this.description,
        publishTo: publishTo ?? this.publishTo,
        environment: environment ?? this.environment,
        dependencies: dependencies ?? this.dependencies,
        devDependencies: devDependencies ?? this.devDependencies,
        dependencyOverrides: dependencyOverrides ?? this.dependencyOverrides,
        executables: executables ?? this.executables,
        platforms: platforms ?? this.platforms,
        unParsedYaml: unParsedYaml ?? this.unParsedYaml);
  }

  /// saves the pubspec to the [projectDirectory]
  Future save(Directory projectDirectory) async {
    final ioSink =
        File(p.join(projectDirectory.path, 'pubspec.yaml')).openWrite();
    try {
      YamlToString().writeYamlString(toJson(), ioSink);
    } finally {
      return ioSink.close();
    }
  }

  /// Converts to a Map that can be serialised to Yaml or Json
  @override
  Map toJson() {
    return (buildJson
          ..add('name', name)
          ..add('author', author)
          ..add('version', version)
          ..add('homepage', homepage)
          ..add('documentation', documentation)
          ..add('publish_to', publishTo)
          ..add('environment', environment)
          ..add('description', description)
          ..add('dependencies', dependencies)
          ..add('dev_dependencies', devDependencies)
          ..add('dependency_overrides', dependencyOverrides)
          ..add('executables', executables)
          ..add('platforms', platforms)
          ..addAll(unParsedYaml!))
        .json;
  }
}

class Environment implements Jsonable {
  final VersionConstraint? sdkConstraint;
  final Map? unParsedYaml;

  const Environment(this.sdkConstraint, this.unParsedYaml);

  factory Environment.fromJson(Map json) {
    final p = parseJson(json, consumeMap: true);
    return Environment(
        p.single('sdk', (v) => VersionConstraint.parse(v)), p.unconsumed);
  }

  @override
  Map toJson() {
    return (buildJson
          ..add('sdk', "${sdkConstraint.toString()}")
          ..addAll(unParsedYaml!))
        .json;
  }
}

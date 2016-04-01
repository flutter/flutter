// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

import '../artifacts.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class UpdatePackagesCommand extends FlutterCommand {
  UpdatePackagesCommand({ this.hidden: false }) {
    argParser.addFlag(
      'upgrade',
      help: 'Run "pub upgrade" rather than "pub get".',
      defaultsTo: false
    );
  }

  @override
  final String name = 'update-packages';

  @override
  final String description = 'Update the packages inside the Flutter repo.';

  @override
  final bool hidden;

  @override
  bool get requiresProjectRoot => false;

  @override
  Future<int> runInProject() async {
    Stopwatch timer = new Stopwatch()..start();

    bool upgrade = argResults['upgrade'];

    List<PackageInfo> packages = <PackageInfo>[];
    _parsePackages(new Directory("${ArtifactStore.flutterRoot}/packages"), packages);
    _parsePackages(new Directory("${ArtifactStore.flutterRoot}/examples"), packages);
    _parsePackages(new Directory("${ArtifactStore.flutterRoot}/dev"), packages);

    String validationResult = _validatePackages(packages);

    if (validationResult.isNotEmpty) {
      printError(validationResult);
      return 1;
    }

    int result = await _getUpgrade(packages, upgrade: upgrade);

    if (result == 0) {
      printStatus('');
      printStatus('Elapsed time ${(timer.elapsedMilliseconds / 1000).toStringAsFixed(3)} seconds.');
    }

    return result;
  }

  void _parsePackages(Directory directory, List<PackageInfo> packages) {
    for (FileSystemEntity dir in directory.listSync()) {
      if (dir is! Directory)
        continue;

      File pubspec = new File(path.join(dir.path, 'pubspec.yaml'));
      if (pubspec.existsSync())
        packages.add(new PackageInfo(dir));
    }
  }

  String _validatePackages(List<PackageInfo> packages) {
    StringBuffer buf = new StringBuffer();

    // Remove all the relative references to other repo packages.
    for (String name in packages.map((PackageInfo package) => package.name))
      for (PackageInfo package in packages)
        package.removePathRef(name);

    // Check for compatible versions.
    Map<String, Dep> deps = <String, Dep>{};

    for (PackageInfo package in packages) {
      for (Dep dep in package.deps.values) {
        deps[dep.name] = _getMostSpecificDep(deps[dep.name], dep);

        // There's a validation error.
        if (deps[dep.name] == null)
          _printErrorFor(packages, buf, dep.name);
      }
    }

    return buf.toString();
  }

  void _printErrorFor(List<PackageInfo> packages, StringBuffer buf, String name) {
    buf.writeln('Package conflict for "$name":');

    for (PackageInfo package in packages) {
      Dep dep = package.deps[name];
      if (dep == null || dep.isAny)
        continue;
      buf.writeln('  package ${package.name} uses as "$dep"');
    }
  }

  Future<int> _getUpgrade(List<PackageInfo> packages, { bool upgrade: false }) async {
    for (PackageInfo package in packages) {
      for (Dep dep in package.deps.values)
        if (dep.isPath)
          dep.normalize();
    }

    Map<String, Dep> deps = <String, Dep>{};

    // Create the repo package references.
    Set<String> repoRefs = new Set<String>();
    for (PackageInfo package in packages) {
      Dep dep = new Dep(package, package.name, <String, dynamic>{ 'path': package.dir.path });
      deps[package.name] = dep;
      repoRefs.add(package.name);
    }

    // Create the direct references.
    Set<String> directRefs = new Set<String>();
    for (PackageInfo package in packages) {
      for (Dep dep in package.deps.values) {
        directRefs.add(dep.name);
        deps[dep.name] = _getMostSpecificDep(deps[dep.name], dep);
      }
    }

    final String kPackageProjectName = 'repo_packages';

    Directory packageDir = new Directory(path.join(ArtifactStore.getBaseCacheDir().path, kPackageProjectName));
    packageDir.createSync(recursive: true);
    File pubspecFile = new File(path.join(packageDir.path, 'pubspec.yaml'));

    String contents = 'name: $kPackageProjectName\n';
    contents += 'dependencies:\n';
    contents += deps.values.map((Dep dep) => dep.pubFormat).join('\n');

    pubspecFile.writeAsStringSync(contents);

    int result = await pubGet(directory: packageDir.path, upgrade: upgrade);

    if (result != 0)
      return result;

    String packagesSource = new File(path.join(packageDir.path, '.packages')).readAsStringSync();
    String lockSource = new File(path.join(packageDir.path, 'pubspec.lock')).readAsStringSync();

    // Remove the synthetic project reference.
    packagesSource = (packagesSource.split('\n')..removeWhere((String line) {
      return line.startsWith('$kPackageProjectName:');
    })).join('\n');

    // Print the versions used.
    printStatus('');
    printStatus('Repo packages (${packages.length}):');
    for (PackageInfo package in packages)
      printStatus('  ${path.relative(package.dir.path, from: ArtifactStore.flutterRoot)}');

    yaml.YamlMap publock = yaml.loadYaml(lockSource);

    printStatus('');
    printStatus('Direct depencencies (${directRefs.length}):');
    for (String ref in directRefs.toList()..sort())
      printStatus('  $ref: ${publock['packages'][ref]['version']}');

    Set<String> transitiveRefs = new Set<String>();

    for (String key in publock['packages'].keys)
      if (!repoRefs.contains(key) && !directRefs.contains(key))
        transitiveRefs.add(key);

    printStatus('');
    printStatus('Transitive depencencies (${transitiveRefs.length}):');
    for (String key in transitiveRefs.toList()..sort())
      printStatus('  $key: ${publock['packages'][key]['version']}');

    // Copy the .packages file around.
    for (PackageInfo package in packages) {
      File destPackages = new File(path.join(package.dir.path, '.packages'));
      File destLock = new File(path.join(package.dir.path, 'pubspec.lock'));

      destPackages.writeAsStringSync(packagesSource);
      destLock.writeAsStringSync(lockSource);
    }

    return 0;
  }

  Dep _getMostSpecificDep(Dep dep1, Dep dep2) {
    if (dep1 == null)
      return dep2;
    if (dep2 == null)
      return dep1;
    if (dep1.isAny)
      return dep2;
    if (dep2.isAny)
      return dep1;

    if (dep1 == dep2)
      return dep1;

    return null;
  }
}

class PackageInfo {
  PackageInfo(this.dir) {
    package = yaml.loadYaml(new File(path.join(dir.path, 'pubspec.yaml')).readAsStringSync());

    if (package.containsKey('dependencies'))
      package['dependencies'].forEach((String key, dynamic dep) => deps[key] = new Dep(this, key, dep));
    if (package.containsKey('dev_dependencies'))
      package['dev_dependencies'].forEach((String key, dynamic dep) => deps[key] = new Dep(this, key, dep));
  }

  final Directory dir;
  final Map<String, Dep> deps = <String, Dep>{};
  yaml.YamlMap package;

  String get name => package['name'];

  void removePathRef(String name) {
    Dep dep = deps[name];
    if (dep != null && dep.isPath)
      deps.remove(name);
  }

  @override
  String toString() => '$name $deps';
}

class Dep {
  Dep(this.package, this.name, this.dep);

  final PackageInfo package;
  final String name;
  dynamic dep;

  bool get isHosted => dep is String;

  bool get isAny => dep == 'any';

  bool get isPath => dep is Map<String, dynamic> && dep['path'] != null;

  String get pubFormat {
    if (isPath)
      return '  $name:\n    path: \'${dep['path']}\'';
    else
      return '  $name: \'$dep\'';
  }

  @override
  String toString() => '$dep';

  @override
  bool operator==(dynamic other) => other is Dep && pubFormat == other.pubFormat;

  @override
  int get hashCode => pubFormat.hashCode;

  void normalize() {
    String pathValue = path.normalize(path.join(package.dir.path, dep['path']));
    dep = <String, dynamic> { 'path': pathValue };
  }
}

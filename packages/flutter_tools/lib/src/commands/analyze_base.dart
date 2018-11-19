// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart' as yaml;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../globals.dart';

/// Common behavior for `flutter analyze` and `flutter analyze --watch`
abstract class AnalyzeBase {
  AnalyzeBase(this.argResults);

  /// The parsed argument results for execution.
  final ArgResults argResults;

  /// Called by [AnalyzeCommand] to start the analysis process.
  Future<void> analyze();

  void dumpErrors(Iterable<String> errors) {
    if (argResults['write'] != null) {
      try {
        final RandomAccessFile resultsFile = fs.file(argResults['write']).openSync(mode: FileMode.write);
        try {
          resultsFile.lockSync();
          resultsFile.writeStringSync(errors.join('\n'));
        } finally {
          resultsFile.close();
        }
      } catch (e) {
        printError('Failed to save output to "${argResults['write']}": $e');
      }
    }
  }

  void writeBenchmark(Stopwatch stopwatch, int errorCount, int membersMissingDocumentation) {
    const String benchmarkOut = 'analysis_benchmark.json';
    final Map<String, dynamic> data = <String, dynamic>{
      'time': stopwatch.elapsedMilliseconds / 1000.0,
      'issues': errorCount,
      'missingDartDocs': membersMissingDocumentation
    };
    fs.file(benchmarkOut).writeAsStringSync(toPrettyJson(data));
    printStatus('Analysis benchmark written to $benchmarkOut ($data).');
  }

  bool get isBenchmarking => argResults['benchmark'];
}

/// Return true if [fileList] contains a path that resides inside the Flutter repository.
/// If [fileList] is empty, then return true if the current directory resides inside the Flutter repository.
bool inRepo(List<String> fileList) {
  if (fileList == null || fileList.isEmpty)
    fileList = <String>[fs.path.current];
  final String root = fs.path.normalize(fs.path.absolute(Cache.flutterRoot));
  final String prefix = root + fs.path.separator;
  for (String file in fileList) {
    file = fs.path.normalize(fs.path.absolute(file));
    if (file == root || file.startsWith(prefix))
      return true;
  }
  return false;
}

class PackageDependency {
  // This is a map from dependency targets (lib directories) to a list
  // of places that ask for that target (.packages or pubspec.yaml files)
  Map<String, List<String>> values = <String, List<String>>{};
  String canonicalSource;
  void addCanonicalCase(String packagePath, String pubSpecYamlPath) {
    assert(canonicalSource == null);
    add(packagePath, pubSpecYamlPath);
    canonicalSource = pubSpecYamlPath;
  }
  void add(String packagePath, String sourcePath) {
    values.putIfAbsent(packagePath, () => <String>[]).add(sourcePath);
  }
  bool get hasConflict => values.length > 1;
  bool get hasConflictAffectingFlutterRepo {
    assert(fs.path.isAbsolute(Cache.flutterRoot));
    for (List<String> targetSources in values.values) {
      for (String source in targetSources) {
        assert(fs.path.isAbsolute(source));
        if (fs.path.isWithin(Cache.flutterRoot, source))
          return true;
      }
    }
    return false;
  }
  void describeConflict(StringBuffer result) {
    assert(hasConflict);
    final List<String> targets = values.keys.toList();
    targets.sort((String a, String b) => values[b].length.compareTo(values[a].length));
    for (String target in targets) {
      final int count = values[target].length;
      result.writeln('  $count ${count == 1 ? 'source wants' : 'sources want'} "$target":');
      bool canonical = false;
      for (String source in values[target]) {
        result.writeln('    $source');
        if (source == canonicalSource)
          canonical = true;
      }
      if (canonical) {
        result.writeln('    (This is the actual package definition, so it is considered the canonical "right answer".)');
      }
    }
  }
  String get target => values.keys.single;
}

class PackageDependencyTracker {
  /// Packages whose source is defined in the vended SDK.
  static const List<String> _vendedSdkPackages = <String>['analyzer', 'front_end', 'kernel'];

  // This is a map from package names to objects that track the paths
  // involved (sources and targets).
  Map<String, PackageDependency> packages = <String, PackageDependency>{};

  PackageDependency getPackageDependency(String packageName) {
    return packages.putIfAbsent(packageName, () => PackageDependency());
  }

  /// Read the .packages file in [directory] and add referenced packages to [dependencies].
  void addDependenciesFromPackagesFileIn(Directory directory) {
    final String dotPackagesPath = fs.path.join(directory.path, '.packages');
    final File dotPackages = fs.file(dotPackagesPath);
    if (dotPackages.existsSync()) {
      // this directory has opinions about what we should be using
      final Iterable<String> lines = dotPackages
        .readAsStringSync()
        .split('\n')
        .where((String line) => !line.startsWith(RegExp(r'^ *#')));
      for (String line in lines) {
        final int colon = line.indexOf(':');
        if (colon > 0) {
          final String packageName = line.substring(0, colon);
          final String packagePath = fs.path.fromUri(line.substring(colon+1));
          // Ensure that we only add `analyzer` and dependent packages defined in the vended SDK (and referred to with a local
          // fs.path. directive). Analyzer package versions reached via transitive dependencies (e.g., via `test`) are ignored
          // since they would produce spurious conflicts.
          if (!_vendedSdkPackages.contains(packageName) || packagePath.startsWith('..'))
            add(packageName, fs.path.normalize(fs.path.absolute(directory.path, packagePath)), dotPackagesPath);
        }
      }
    }
  }

  void addCanonicalCase(String packageName, String packagePath, String pubSpecYamlPath) {
    getPackageDependency(packageName).addCanonicalCase(packagePath, pubSpecYamlPath);
  }

  void add(String packageName, String packagePath, String dotPackagesPath) {
    getPackageDependency(packageName).add(packagePath, dotPackagesPath);
  }

  void checkForConflictingDependencies(Iterable<Directory> pubSpecDirectories, PackageDependencyTracker dependencies) {
    for (Directory directory in pubSpecDirectories) {
      final String pubSpecYamlPath = fs.path.join(directory.path, 'pubspec.yaml');
      final File pubSpecYamlFile = fs.file(pubSpecYamlPath);
      if (pubSpecYamlFile.existsSync()) {
        // we are analyzing the actual canonical source for this package;
        // make sure we remember that, in case all the packages are actually
        // pointing elsewhere somehow.
        final yaml.YamlMap pubSpecYaml = yaml.loadYaml(fs.file(pubSpecYamlPath).readAsStringSync());
        final String packageName = pubSpecYaml['name'];
        final String packagePath = fs.path.normalize(fs.path.absolute(fs.path.join(directory.path, 'lib')));
        dependencies.addCanonicalCase(packageName, packagePath, pubSpecYamlPath);
      }
      dependencies.addDependenciesFromPackagesFileIn(directory);
    }

    // prepare a union of all the .packages files
    if (dependencies.hasConflicts) {
      final StringBuffer message = StringBuffer();
      message.writeln(dependencies.generateConflictReport());
      message.writeln('Make sure you have run "pub upgrade" in all the directories mentioned above.');
      if (dependencies.hasConflictsAffectingFlutterRepo) {
        message.writeln(
          'For packages in the flutter repository, try using "flutter update-packages" to do all of them at once.\n'
          'If you need to actually upgrade them, consider "flutter update-packages --force-upgrade". '
          '(This will update your pubspec.yaml files as well, so you may wish to do this on a separate branch.)'
        );
      }
      message.write(
        'If this does not help, to track down the conflict you can use '
        '"pub deps --style=list" and "pub upgrade --verbosity=solver" in the affected directories.'
      );
      throwToolExit(message.toString());
    }
  }

  bool get hasConflicts {
    return packages.values.any((PackageDependency dependency) => dependency.hasConflict);
  }

  bool get hasConflictsAffectingFlutterRepo {
    return packages.values.any((PackageDependency dependency) => dependency.hasConflictAffectingFlutterRepo);
  }

  String generateConflictReport() {
    assert(hasConflicts);
    final StringBuffer result = StringBuffer();
    for (String package in packages.keys.where((String package) => packages[package].hasConflict)) {
      result.writeln('Package "$package" has conflicts:');
      packages[package].describeConflict(result);
    }
    return result.toString();
  }

  Map<String, String> asPackageMap() {
    final Map<String, String> result = <String, String>{};
    for (String package in packages.keys)
      result[package] = packages[package].target;
    return result;
  }
}

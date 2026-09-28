// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'analyze.dart';
/// @docImport 'analyze_continuously.dart';
/// @docImport 'analyze_once.dart';
library;

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:yaml/yaml.dart' as yaml;

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../cache.dart';

/// Common behavior for `flutter analyze` and `flutter analyze --watch`
abstract class AnalyzeBase {
  AnalyzeBase(
    this.argResults, {
    required this.artifacts,
    required this.fileSystem,
    required this.logger,
    required this.platform,
    required this.processManager,
    required this.repoPackages,
    required this.suppressAnalytics,
    required this.terminal,
  });

  /// The parsed argument results for execution.
  final ArgResults argResults;
  @protected
  final List<Directory> repoPackages;
  @protected
  final FileSystem fileSystem;
  @protected
  final Logger logger;
  @protected
  final ProcessManager processManager;
  @protected
  final Platform platform;
  @protected
  final Terminal terminal;
  @protected
  final Artifacts artifacts;
  @protected
  final bool suppressAnalytics;

  @protected
  String get flutterRoot => fileSystem.path.absolute(Cache.flutterRoot!);

  /// Called by [AnalyzeCommand] to start the analysis process.
  Future<void> analyze();

  void dumpErrors(Iterable<String> errors) {
    if (argResults['write'] != null) {
      try {
        final RandomAccessFile resultsFile = fileSystem
            .file(argResults['write'])
            .openSync(mode: FileMode.write);
        try {
          resultsFile.lockSync();
          resultsFile.writeStringSync(errors.join('\n'));
        } finally {
          resultsFile.close();
        }
      } on Exception catch (e) {
        logger.printError('Failed to save output to "${argResults['write']}": $e');
      }
    }
  }

  void writeBenchmark(Stopwatch stopwatch, int errorCount) {
    const benchmarkOut = 'analysis_benchmark.json';
    final data = <String, dynamic>{
      'time': stopwatch.elapsedMilliseconds / 1000.0,
      'issues': errorCount,
    };
    fileSystem.file(benchmarkOut).writeAsStringSync(toPrettyJson(data));
    logger.printStatus('Analysis benchmark written to $benchmarkOut ($data).');
  }

  bool get isFlutterRepo => argResults['flutter-repo'] as bool;
  String get sdkPath {
    final dartSdk = argResults['dart-sdk'] as String?;
    return dartSdk ?? artifacts.getArtifactPath(Artifact.engineDartSdkPath);
  }

  bool get isBenchmarking => argResults['benchmark'] as bool;
  String? get protocolTrafficLog => argResults['protocol-traffic-log'] as String?;

  @protected
  bool get usePlugins {
    if (argResults.options.contains('plugins') && argResults.wasParsed('plugins')) {
      return argResults['plugins'] as bool;
    }
    return !isBenchmarking;
  }

  /// Generate an analysis summary for both [AnalyzeOnce], [AnalyzeContinuously].
  static String generateErrorsMessage({
    required int issueCount,
    int? issueDiff,
    int? files,
    required String seconds,
  }) {
    final errorsMessage = StringBuffer(
      issueCount > 0 ? '$issueCount ${pluralize('issue', issueCount)} found.' : 'No issues found!',
    );

    // Only [AnalyzeContinuously] has issueDiff message.
    if (issueDiff != null) {
      if (issueDiff > 0) {
        errorsMessage.write(' ($issueDiff new)');
      } else if (issueDiff < 0) {
        errorsMessage.write(' (${-issueDiff} fixed)');
      }
    }

    // Only [AnalyzeContinuously] has files message.
    if (files != null) {
      errorsMessage.write(' • analyzed $files ${pluralize('file', files)}');
    }
    errorsMessage.write(' (ran in ${seconds}s)');
    return errorsMessage.toString();
  }
}

class PackageDependency {
  // This is a map from dependency targets (lib directories) to a list
  // of places that ask for that target (package_config.json or pubspec.yaml files)
  Map<String, List<String>> values = <String, List<String>>{};
  String? canonicalSource;
  void addCanonicalCase(String packagePath, String pubSpecYamlPath) {
    assert(canonicalSource == null);
    add(packagePath, pubSpecYamlPath);
    canonicalSource = pubSpecYamlPath;
  }

  void add(String packagePath, String sourcePath) {
    values.putIfAbsent(packagePath, () => <String>[]).add(sourcePath);
  }

  bool get hasConflict => values.length > 1;
  bool hasConflictAffectingFlutterRepo(FileSystem fileSystem) {
    final String? flutterRoot = Cache.flutterRoot;
    assert(flutterRoot != null && fileSystem.path.isAbsolute(flutterRoot));
    for (final List<String> targetSources in values.values) {
      for (final source in targetSources) {
        assert(fileSystem.path.isAbsolute(source));
        if (fileSystem.path.isWithin(flutterRoot!, source)) {
          return true;
        }
      }
    }
    return false;
  }

  void describeConflict(StringBuffer result) {
    assert(hasConflict);
    final List<String> targets = values.keys.toList();
    targets.sort((String a, String b) => values[b]!.length.compareTo(values[a]!.length));
    for (final target in targets) {
      final List<String> targetList = values[target]!;
      final int count = targetList.length;
      result.writeln('  $count ${count == 1 ? 'source wants' : 'sources want'} "$target":');
      var canonical = false;
      for (final source in targetList) {
        result.writeln('    $source');
        if (source == canonicalSource) {
          canonical = true;
        }
      }
      if (canonical) {
        result.writeln(
          '    (This is the actual package definition, so it is considered the canonical "right answer".)',
        );
      }
    }
  }

  String get target => values.keys.single;
}

class PackageDependencyTracker {
  // This is a map from package names to objects that track the paths
  // involved (sources and targets).
  Map<String, PackageDependency> packages = <String, PackageDependency>{};

  PackageDependency getPackageDependency(String packageName) {
    return packages.putIfAbsent(packageName, () => PackageDependency());
  }

  void addCanonicalCase(String packageName, String packagePath, String pubSpecYamlPath) {
    getPackageDependency(packageName).addCanonicalCase(packagePath, pubSpecYamlPath);
  }

  void add(String packageName, String packagePath, String dotPackagesPath) {
    getPackageDependency(packageName).add(packagePath, dotPackagesPath);
  }

  void checkForConflictingDependencies(
    Iterable<Directory> pubSpecDirectories, {
    required FileSystem fileSystem,
  }) {
    for (final directory in pubSpecDirectories) {
      final String pubSpecYamlPath = fileSystem.path.join(directory.path, 'pubspec.yaml');
      final File pubSpecYamlFile = fileSystem.file(pubSpecYamlPath);
      if (pubSpecYamlFile.existsSync()) {
        // we are analyzing the actual canonical source for this package;
        // make sure we remember that, in case all the packages are actually
        // pointing elsewhere somehow.
        final dynamic pubSpecYaml = yaml.loadYaml(pubSpecYamlFile.readAsStringSync());
        if (pubSpecYaml is yaml.YamlMap) {
          final dynamic packageName = pubSpecYaml['name'];
          if (packageName is String) {
            final String packagePath = fileSystem.path.normalize(
              fileSystem.path.absolute(fileSystem.path.join(directory.path, 'lib')),
            );
            addCanonicalCase(packageName, packagePath, pubSpecYamlPath);
          } else {
            throwToolExit('pubspec.yaml is malformed. The name should be a String.');
          }
        } else {
          throwToolExit('pubspec.yaml is malformed.');
        }
      }
    }

    if (hasConflicts) {
      final message = StringBuffer();
      message.writeln(generateConflictReport());
      message.writeln(
        'Make sure you have run "pub upgrade" in all the directories mentioned above.',
      );
      if (hasConflictsAffectingFlutterRepo(fileSystem)) {
        message.writeln(
          'For packages in the flutter repository, try using "flutter update-packages" to do all of them at once.\n'
          'If you need to actually upgrade them, consider "flutter update-packages --force-upgrade". '
          '(This will update your pubspec.yaml files as well, so you may wish to do this on a separate branch.)',
        );
      }
      message.write(
        'If this does not help, to track down the conflict you can use '
        '"pub deps --style=list" and "pub upgrade --verbosity=solver" in the affected directories.',
      );
      throwToolExit(message.toString());
    }
  }

  bool get hasConflicts {
    return packages.values.any((PackageDependency dependency) => dependency.hasConflict);
  }

  bool hasConflictsAffectingFlutterRepo(FileSystem fileSystem) {
    return packages.values.any(
      (PackageDependency dependency) => dependency.hasConflictAffectingFlutterRepo(fileSystem),
    );
  }

  String generateConflictReport() {
    assert(hasConflicts);
    final result = StringBuffer();
    packages.forEach((String package, PackageDependency dependency) {
      if (dependency.hasConflict) {
        result.writeln('Package "$package" has conflicts:');
        dependency.describeConflict(result);
      }
    });
    return result.toString();
  }

  Map<String, String> asPackageMap() {
    final result = <String, String>{};
    packages.forEach((String package, PackageDependency dependency) {
      result[package] = dependency.target;
    });
    return result;
  }
}

/// Find directories or files from argResults.rest.
Set<String> findDirectories(ArgResults argResults, FileSystem fileSystem) {
  final items = Set<String>.of(
    argResults.rest.map<String>((String path) => fileSystem.path.canonicalize(path)),
  );
  if (items.isNotEmpty) {
    for (final item in items) {
      final FileSystemEntityType type = fileSystem.typeSync(item);

      if (type == FileSystemEntityType.notFound) {
        throwToolExit("You provided the path '$item', however it does not exist on disk");
      }
    }
  }

  return items;
}

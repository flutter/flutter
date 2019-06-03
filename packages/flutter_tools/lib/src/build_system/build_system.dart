// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import '../base/file_system.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart';
import 'exceptions.dart';
import 'file_cache.dart';
import 'source.dart';

export 'source.dart';

/// The function signature of a build target which can be invoked to perform
/// the underlying task.
typedef BuildInvocation = FutureOr<void> Function(
    Map<String, ChangeType> inputs, Environment environment);

/// A description of the update to each input file.
enum ChangeType {
  /// The file was added.
  Added,
  /// The file was deleted.
  Removed,
  /// The file was modified.
  Modified,
}

/// A Target describes a single step during a flutter build.
///
/// The target inputs are required to be files discoverable via a combination
/// of at least one of the environment values and zero or more local values.
///
/// To determine if a target needs to be executed, the [BuildSystem] performs
/// an md5 hash of the file contents. This is tracked separately in the
/// [FileCache].
///
/// The name of each stamp is the target name, joined with target platform and
/// mode if the target declares that it depends on them. The output files are
/// also stored to protect against deleted files.
///
///  file: `example_target.debug.android_arm64`
///
/// {
///   "inputs": [
///      "absolute/path/foo",
///      "absolute/path/bar",
///      ...
///    ],
///    "outputs": [
///      "absolute/path/fizz"
///    ]
/// }
///
/// We don't re-run if the target or mode change because we expect that these
/// invocations will produce different outputs. For example, if I separately run
/// a target which produces the gen_snapshot output for `android_arm` and
/// `android_arm64`, this should not produce files which overwrite each other.
/// This is not currently the case and will need to be adjusted.
class Target {
  const Target({
    @required this.name,
    @required this.inputs,
    @required this.outputs,
    @required this.invocation,
    this.dependencies = const <Target>[],
    this.platforms = const <TargetPlatform>[],
    this.modes = const <BuildMode>[],
  });

  final String name;
  final List<Target> dependencies;
  final List<Source> inputs;
  final List<Source> outputs;
  final BuildInvocation invocation;

  /// The target platform this target supports.
  ///
  /// If left empty, this supports all platforms.
  final List<TargetPlatform> platforms;

  /// The build modes this target supports.
  ///
  /// If left empty, this supports all modes.
  final List<BuildMode> modes;

  /// Check if we can skip the target invocation and collect hashes for all inputs.
  Future<Map<String, ChangeType>> computeChanges(
    List<FileSystemEntity> inputs,
    Environment environment,
    FileCache fileCache,
  ) async {
    final Map<String, ChangeType> updates = <String, ChangeType>{};
    final File stamp = _findStampFile(name, environment);
    final Set<String> previousInputs = <String>{};

    // If the stamp file doesn't exist, we haven't run this step before and
    // all inputs were added.
    if (stamp.existsSync()) {
      final String content = stamp.readAsStringSync();
      // Something went wrong writing the stamp file.
      if (content == null || content.isEmpty) {
        stamp.deleteSync();
      } else {
        final Map<String, Object> values = json.decode(content);
        final List<Object> inputs = values['inputs'];
        inputs.cast<String>().forEach(previousInputs.add);
      }
    }

    // For each input type, first determine if we've already compute the hash
    // for it. If not, if it is a directory we skip hashing and instead use a
    // timestamp. If it is a file we store it to be sent of for hashing as
    // a group.
    final List<File> filesToHash = <File>[];
    for (FileSystemEntity entity in inputs) {
      if (!entity.existsSync()) {
        throw MissingInputException(entity, name);
      }

      final String absolutePath = entity.absolute.path;
      final String previousHash = fileCache.previousHashes[absolutePath];
      if (fileCache.currentHashes.containsKey(absolutePath)) {
        final String currentHash = fileCache.currentHashes[absolutePath];
        if (currentHash != previousHash) {
          updates[entity.absolute.path] = previousInputs.contains(entity.absolute.path)
              ? ChangeType.Modified
              : ChangeType.Added;
        }
      } else if (entity is File) {
        filesToHash.add(entity);
      } else if (entity is Directory) {
        // In case of a directory use the stat for now.
        final String currentHash = entity
            .statSync()
            .modified
            .toIso8601String();
        if (currentHash != previousHash) {
          updates[entity.absolute.path] = previousInputs.contains(entity.absolute.path)
              ? ChangeType.Modified
              : ChangeType.Added;
        }
        fileCache.currentHashes[absolutePath] = currentHash;
      } else {
        assert(false);
      }
    }

    // If we have files to hash, compute them asynchronously and then
    // update the result.
    if (filesToHash.isNotEmpty) {
      final List<File> dirty = await fileCache.hashFiles(filesToHash);
      for (File file in dirty) {
        updates[file.absolute.path] = previousInputs.contains(file.absolute.path)
            ? ChangeType.Modified
            : ChangeType.Added;
      }
    }

    // Find which, if any, inputs have been deleted.
    final Set<String> currentInputPaths = <String>{
      for (FileSystemEntity entity in inputs)
        entity.absolute.path
    };
    for (String previousInput in previousInputs) {
      if (!currentInputPaths.contains(previousInput)) {
        updates[previousInput] = ChangeType.Removed;
      }
    }

    return updates;
  }


  void _writeStamp(
    List<FileSystemEntity> inputs,
    List<FileSystemEntity> outputs,
    Environment environment,
  ) {
    final File stamp = _findStampFile(name, environment);
    final List<String> inputStamps = <String>[];
    for (FileSystemEntity input in inputs) {
      inputStamps.add(input.absolute.path);
    }
    final List<String> outputStamps = <String>[];
    for (FileSystemEntity output in outputs) {
      if (!output.existsSync()) {
        throw MissingOutputException(output, name);
      }
      outputStamps.add(output.absolute.path);
    }
    final Map<String, Object> result = <String, Object>{
      'inputs': inputStamps,
      'outputs': outputStamps,
    };
    if (!stamp.existsSync()) {
      stamp.createSync();
    }
    stamp.writeAsStringSync(json.encode(result));
  }

  /// Resolve the set of input patterns and functions into a concrete list of
  /// files.
  List<FileSystemEntity> resolveInputs(
    Environment environment,
  ) {
    return _resolveConfiguration(inputs, environment);
  }

  /// Find the current set of declared outputs, including wildcard directories.
  List<FileSystemEntity> resolveOutputs(
    Environment environment,
  ) {
    return _resolveConfiguration(outputs, environment);
  }

  /// Performs a fold across this target and its dependencies.
  T fold<T>(T initialValue, T combine(T previousValue, Target target)) {
    final T dependencyResult = dependencies.fold(
        initialValue, (T prev, Target t) => t.fold(prev, combine));
    return combine(dependencyResult, this);
  }

  /// Convert the target to a JSON structure appropriate for consumption by
  /// external systems.
  ///
  /// This requires an environment variable to resolve the paths of inputs
  /// and outputs.
  Map<String, Object> toJson(Environment environment) {
    return <String, Object>{
      'name': name,
      'dependencies': dependencies.map((Target target) => target.name).toList(),
      'inputs': resolveInputs(environment)
          .map((FileSystemEntity file) => file.absolute.path)
          .toList(),
      'stamp': _findStampFile(name, environment),
    };
  }

  /// Locate the stamp file for a particular target name and environment.
  static File _findStampFile(String name, Environment environment) {
    final String platform = getNameForTargetPlatform(environment.targetPlatform);
    final String mode = getNameForBuildMode(environment.buildMode);
    final String flavor = environment.flavor;
    final String fileName = '$name.$mode.$platform.$flavor';
    return environment.buildDir.childFile(fileName);
  }

  static List<FileSystemEntity> _resolveConfiguration(
      List<Source> config, Environment environment) {
    final SourceVisitor collector = SourceVisitor(environment);
    for (Source source in config) {
      source.accept(collector);
    }
    return collector.sources;
  }
}

/// The [Environment] contains special paths configured by the user.
///
/// These are defined by a top level configuration or build arguments
/// passed to the flutter tool. The intention is that  it makes it easier
/// to integrate it into existing arbitrary build systems, while keeping
/// the build backwards compatible.
///
/// # Environment Values:
///
/// ## PROJECT_DIR
///
///   The root of the flutter project where a pubspec and dart files can be
///   found.
///
///   This value is computed from the location of the relevant pubspec. Most
///   other defaults are defined relative to this directory.
///
/// ## BUILD_DIR
///
///   The root of the output directory where build step intermediates and
///   products are written.
///
///   Defaults to {PROJECT_DIR}/build/
///
/// ## CACHE_DIR
///
///   The root of the artifact cache for the flutter tool. Defaults to
///   FLUTTER_ROOT/bin/cache/artifacts/. Can be overriden with local-engine
///   flags.
///
/// # Build local values
///
/// These are defined by the particular invocation of the target itself.
///
/// ## platform
///
/// The current platform the target is being executed for. Certain targets do
/// not require a target at all, in which case this value will be null and
/// substitution will fail.
///
/// ## mode
///
/// The current build mode the target is being executed for, one of `release`,
/// `debug`, and `profile`. Defaults to `debug` if not specified.
///
/// ## flavor
///
/// The current flavor name, or 'none' if not specified.
class Environment {
  /// Create a new [Environment] object.
  ///
  /// Only [projectDir] is required. The remaining environment locations have
  /// defaults based on it.
  ///
  /// If [targetPlatform] and/or [buildMode] are not defined, they will often
  /// default to `any`.
  factory Environment({
    @required Directory projectDir,
    Directory buildDir,
    Directory cacheDir,
    TargetPlatform targetPlatform,
    BuildMode buildMode,
    String flavor,
  }) {
    assert(projectDir != null);
    return Environment._(
      projectDir: projectDir,
      buildDir: buildDir ?? projectDir.childDirectory('build'),
      cacheDir: cacheDir ??
          Cache.instance.getCacheArtifacts().childDirectory('engine'),
      targetPlatform: targetPlatform,
      buildMode: buildMode,
      flavor: flavor ?? 'none',
    );
  }

  Environment._({
    @required this.projectDir,
    @required this.buildDir,
    @required this.cacheDir,
    @required this.targetPlatform,
    @required this.buildMode,
    @required this.flavor,
  });

  /// The `PROJECT_DIR` environment variable.
  final Directory projectDir;

  /// The `BUILD_DIR` environment variable.
  ///
  /// Defaults to `{PROJECT_ROOT}/build`.
  final Directory buildDir;

  /// The `CACHE_DIR` environment variable.
  ///
  /// Defaults to `{FLUTTER_ROOT}/bin/cache`.
  final Directory cacheDir;

  /// The currently selected build mode.
  final BuildMode buildMode;

  /// The current target platform, or `null` if none.
  final TargetPlatform targetPlatform;

  /// The current flavor, or 'none' if none.
  final String flavor;
}

/// The build system is responsible for invoking and ordering [Target]s.
class BuildSystem {
  const BuildSystem([this.targets]);

  final List<Target> targets;

  /// Build the target `name` and all of its dependencies.
  Future<void> build(
    String name,
    Environment environment,
  ) async {
    final Target target = _getNamedTarget(name);
    final FileCache fileCache = FileCache(environment);

    if (!environment.buildDir.existsSync()) {
      environment.buildDir.createSync();
    }

    // Load file cache from previous builds.
    fileCache.initialize();

    // Perform sanity checks on build.
    checkCycles(target);
    final bool isBuildValid = target.fold(true, (bool isValid, Target target) {
      if (target.modes.isNotEmpty && !target.modes.contains(environment.buildMode)) {
        return false;
      }
      if (target.platforms.isNotEmpty && !target.platforms.contains(environment.targetPlatform)) {
        return false;
      }
      return isValid;
    });
    if (!isBuildValid) {
      throw InvalidBuildException(environment, target);
    }

    final Pool resourcePool = Pool(platform?.numberOfProcessors ?? 1);
    final Map<String, AsyncMemoizer<void>> pending = <String, AsyncMemoizer<void>>{};

    Future<void> invokeTarget(Target target) async {
      await Future.wait(target.dependencies.map(invokeTarget));

      final AsyncMemoizer<void> memoizer = pending[target.name] ??= AsyncMemoizer<void>();
      await memoizer.runOnce(() async {
        final PoolResource resource = await resourcePool.request();
        try {
          final List<FileSystemEntity> inputs = target.resolveInputs(
              environment);
          final Map<String, ChangeType> updates = await target.computeChanges(
              inputs, environment, fileCache);
          if (updates.isEmpty) {
            printTrace('Skipping target: ${target.name}');
          } else {
            printTrace('${target.name}: Starting');
            await target.invocation(updates, environment);
            printTrace('${target.name}: Complete');

            final List<FileSystemEntity> outputs = target.resolveOutputs(
                environment);
            target._writeStamp(inputs, outputs, environment);
          }
        } finally {
          resource.release();
        }
      });
    }

    try {
      await invokeTarget(target);
    } finally {
      // Always persist the file cache to disk.
      fileCache.persist();
    }
  }

  /// Describe the target `name` and all of its dependencies.
  List<Map<String, Object>> describe(
    String name,
    Environment environment,
  ) {
    final Target target = _getNamedTarget(name);
    checkCycles(target);
    // Cheat a bit and re-use the same map.
    Map<String, Map<String, Object>> fold(Map<String, Map<String, Object>> accumulation, Target current) {
      accumulation[current.name] = current.toJson(environment);
      return accumulation;
    }

    final Map<String, Map<String, Object>> result =
        <String, Map<String, Object>>{};
    final Map<String, Map<String, Object>> targets = target.fold(result, fold);
    return targets.values.toList();
  }

  // Returns the corresponding target or throws.
  Target _getNamedTarget(String name) {
    final Target target = targets
        .firstWhere((Target target) => target.name == name, orElse: () => null);
    if (target == null) {
      throw Exception('No registered target named $name.');
    }
    return target;
  }
}

/// Check if there are any dependency cycles in the target.
///
/// Throws a [CycleException] if one is encountered.
void checkCycles(Target initial) {
  void checkInternal(Target target, Set<Target> visited, Set<Target> stack) {
    if (stack.contains(target)) {
      throw CycleException(stack..add(target));
    }
    if (visited.contains(target)) {
      return;
    }
    visited.add(target);
    stack.add(target);
    for (Target dependency in target.dependencies) {
      checkInternal(dependency, visited, stack);
    }
    stack.remove(target);
  }

  checkInternal(initial, <Target>{}, <Target>{});
}

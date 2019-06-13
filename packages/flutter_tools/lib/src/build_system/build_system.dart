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

/// Configuration for the build system itself.
class BuildSystemConfig {
  const BuildSystemConfig({this.resourcePoolSize});

  /// The maximum number of concurrent tasks the build system will run.
  ///
  /// If not provided, defaults to [platform.numberOfProcessors].
  final int resourcePoolSize;
}

/// A Target describes a single step during a flutter build.
///
/// The target inputs are required to be files discoverable via a combination
/// of at least one of the environment values and zero or more local values.
///
/// To determine if a target needs to be executed, the [BuildSystem] performs
/// a  hash of the file contents. This is tracked separately in the
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

  /// The user-readable name of the target.
  ///
  /// This information is surfaced in the assemble commands and used as an
  /// argument to build a particular target.
  final String name;

  /// The dependencies of this target.
  final List<Target> dependencies;

  /// The input [Source]s which are diffed to determine if a target should run.
  final List<Source> inputs;

  /// The output [Source]s which we attempt to verify are correctly produced.
  // TODO(jonahwilliams): track outputs to allow more surgical flutter clean.
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
    List<SourceFile> inputs,
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

    // For each input type, first determine if we've already computed the hash
    // for it. If not and it is a directory we skip hashing and instead use a
    // timestamp. If it is a file we collect it to be sent of for hashing as
    // a group.
    final List<SourceFile> sourcesToHash = <SourceFile>[];
    for (SourceFile entity in inputs) {
      if (!entity.existsSync()) {
        throw MissingInputException(entity.unresolvedPath, name);
      }

      final String absolutePath = entity.path;
      final String previousHash = fileCache.previousHashes[absolutePath];
      if (fileCache.currentHashes.containsKey(absolutePath)) {
        final String currentHash = fileCache.currentHashes[absolutePath];
        if (currentHash != previousHash) {
          updates[absolutePath] = previousInputs.contains(absolutePath)
              ? ChangeType.Modified
              : ChangeType.Added;
        }
      } else {
        sourcesToHash.add(entity);
      }
    }

    // If we have files to hash, compute them asynchronously and then
    // update the result.
    if (sourcesToHash.isNotEmpty) {
      final List<SourceFile> dirty = await fileCache.hashFiles(sourcesToHash);
      for (SourceFile file in dirty) {
        final String absolutePath = file.path;
        updates[absolutePath] = previousInputs.contains(absolutePath)
            ? ChangeType.Modified
            : ChangeType.Added;
      }
    }

    // Find which, if any, inputs have been deleted.
    final Set<String> currentInputPaths = Set<String>.from(
      inputs.map<String>((SourceFile entity) => entity.path)
    );
    for (String previousInput in previousInputs) {
      if (!currentInputPaths.contains(previousInput)) {
        updates[previousInput] = ChangeType.Removed;
      }
    }
    return updates;
  }

  void _writeStamp(
    List<SourceFile> inputs,
    List<SourceFile> outputs,
    Environment environment,
  ) {
    final File stamp = _findStampFile(name, environment);
    final List<String> inputStamps = <String>[];
    for (SourceFile input in inputs) {
      inputStamps.add(input.path);
    }
    final List<String> outputStamps = <String>[];
    for (SourceFile output in outputs) {
      if (!output.existsSync()) {
        throw MissingOutputException(output.unresolvedPath, name);
      }
      outputStamps.add(output.path);
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
  List<SourceFile> resolveInputs(
    Environment environment,
  ) {
    return _resolveConfiguration(inputs, environment);
  }

  /// Find the current set of declared outputs, including wildcard directories.
  List<SourceFile> resolveOutputs(
    Environment environment,
  ) {
    final List<SourceFile> outputEntities = _resolveConfiguration(outputs, environment);
    verifyOutputDirectories(outputEntities, environment, this);
    return outputEntities;
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
  /// This requires constants from the [Environment] to resolve the paths of
  /// inputs and the output stamp.
  Map<String, Object> toJson(Environment environment) {
    return <String, Object>{
      'name': name,
      'dependencies': dependencies.map((Target target) => target.name).toList(),
      'inputs': resolveInputs(environment)
          .map((SourceFile file) => file.path)
          .toList(),
      'stamp': _findStampFile(name, environment).absolute.path,
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

  static List<SourceFile> _resolveConfiguration(
      List<Source> config, Environment environment) {
    final SourceVisitor collector = SourceVisitor(environment);
    for (Source source in config) {
      source.accept(collector);
    }
    return collector.sources;
  }
}

/// The [Environment] defines several constants for use during the build.
///
/// The environment contains configuration and file paths that are safe to
/// depend on and reference during the build.
///
/// Example (Good):
///
/// Use the environment to determine where to write an output file.
///
///    environment.buildDir.childFile('output')
///      ..createSync()
///      ..writeAsStringSync('output data');
///
/// Example (Bad):
///
/// Use a hard-coded path or directory relative to the current working
/// directory to write an output file.
///
///   fs.file('build/linux/out')
///     ..createSync()
///     ..writeAsStringSync('output data');
///
/// Example (Good):
///
/// Using the build mode to produce different output. Note that the invocation
/// is still responsible for outputting a different file, as defined by the
/// corresponding output [Source].
///
///    if (environment.buildMode == BuildMode.debug) {
///      environment.buildDir.childFile('debug.output)
///        ..createSync()
///        ..writeAsStringSync('debug');
///    } else {
///      environment.buildDir.childFile('non_debug.output)
///        ..createSync()
///        ..writeAsStringSync('non_debug');
///    }
// TODO(jonahwilliams): allow passing serializable defines to each rule that
// could include somewhat arbitary config and be used to invalidate. Example:
// android_arch, ios_arch.
class Environment {
  /// Create a new [Environment] object.
  ///
  /// Only [projectDir] is required. The remaining environment locations have
  /// defaults based on it.
  factory Environment({
    @required Directory projectDir,
    @required TargetPlatform targetPlatform,
    @required BuildMode buildMode,
    Directory buildDir,
    Directory cacheDir,
    Directory flutterRootDir,
    String flavor,
  }) {
    assert(projectDir != null);
    assert(targetPlatform != null);
    assert(buildMode != null);
    return Environment._(
      projectDir: projectDir,
      flutterRootDir: flutterRootDir ?? fs.directory(Cache.flutterRoot),
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
    @required this.flutterRootDir,
  });

  /// The [Source] value which is substituted with the path to [projectDir].
  static const String kProjectDirectory = '{PROJECT_DIR}';

  /// The [Source] value which is substituted with the path to [buildDir].
  static const String kBuildDirectory = '{BUILD_DIR}';

  /// The [Source] value which is substituted with the path to [cacheDir].
  static const String kCacheDirectory = '{CACHE_DIR}';

  /// The [Source] value which is substituted with a path to the flutter root.
  static const String kFlutterRootDirectory = '{FLUTTER_ROOT}';

  /// The [Source] value which is substituted with [targetPlatform].
  static const String kPlatform = '{platform}';

  /// The [Source] value which is substituted with [buildMode].
  static const String kMode = '{mode}';

  /// The [Source] value which is substituted with [flavor].
  static const String kFlavor = '{flavor}';

  /// The `PROJECT_DIR` environment variable.
  ///
  /// This should be root of the flutter project where a pubspec and dart files
  /// can be located.
  final Directory projectDir;

  /// The `BUILD_DIR` environment variable.
  ///
  /// Defaults to `{PROJECT_ROOT}/build`. The root of the output directory where
  /// build step intermediates and outputs are written.
  final Directory buildDir;

  /// The `CACHE_DIR` environment variable.
  ///
  /// Defaults to `{FLUTTER_ROOT}/bin/cache`. The root of the artifact cache for
  /// the flutter tool.
  final Directory cacheDir;

  /// The `FLUTTER_ROOT` environment variable.
  ///
  /// Defaults to the root of the flutter checkout for which this command is run.
  final Directory flutterRootDir;

  /// The currently selected build mode.
  final BuildMode buildMode;

  /// The current target platform.
  ///
  /// Certain targets do not require a [TargetPlatform], while others will fail
  /// if paired with an incorrect [TargetPlatform].
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
    BuildSystemConfig buildSystemConfig,
  ) async {
    final Target target = _getNamedTarget(name);
    environment.buildDir.createSync(recursive: true);

    // Load file cache from previous builds.
    final FileCache fileCache = FileCache(environment)
      ..initialize();

    // Perform sanity checks on build.
    checkCycles(target);
    final bool isBuildValid = target.fold(true, (bool isValid, Target target) {
      return isValid
        && (target.modes.isEmpty || target.modes.contains(environment.buildMode))
        && (target.platforms.isEmpty || target.platforms.contains(environment.targetPlatform));
    });
    if (!isBuildValid) {
      throw InvalidBuildException(environment, target);
    }

    // TODO(jonahwilliams): create a separate configuration for the settings and
    // constants which effect build running.
    final _BuildInstance buildInstance = _BuildInstance(environment, fileCache, buildSystemConfig);
    try {
      await buildInstance.invokeTarget(target);
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

/// An active instance of a build.
class _BuildInstance {
  _BuildInstance(this.environment, this.fileCache, this.buildSystemConfig)
    : resourcePool = Pool(buildSystemConfig.resourcePoolSize ?? platform?.numberOfProcessors ?? 1);

  final BuildSystemConfig buildSystemConfig;
  final Pool resourcePool;
  final Map<String, AsyncMemoizer<void>> pending = <String, AsyncMemoizer<void>>{};
  final Environment environment;
  final FileCache fileCache;

  Future<void> invokeTarget(Target target) async {
    await Future.wait(target.dependencies.map(invokeTarget));
    final AsyncMemoizer<void> memoizer = pending[target.name] ??= AsyncMemoizer<void>();
    await memoizer.runOnce(() => _invokeInternal(target));
  }

  Future<void> _invokeInternal(Target target) async {
    final PoolResource resource = await resourcePool.request();
    try {
      final List<SourceFile> inputs = target.resolveInputs(environment);
      final Map<String, ChangeType> updates = await target.computeChanges(inputs, environment, fileCache);
      if (updates.isEmpty) {
        printTrace('Skipping target: ${target.name}');
      } else {
        printTrace('${target.name}: Starting');
        await target.invocation(updates, environment);
        printTrace('${target.name}: Complete');

        final List<SourceFile> outputs = target.resolveOutputs(environment);
        target._writeStamp(inputs, outputs, environment);
      }
    } finally {
      resource.release();
    }
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

/// Verifies that all  files are in a subdirectory of [Environment.buildDir].
void verifyOutputDirectories(List<SourceFile> outputs, Environment environment, Target target) {
  final String buildDirectory = environment.buildDir.resolveSymbolicLinksSync();
  final String projectDirectory = environment.projectDir.resolveSymbolicLinksSync();
  for (SourceFile sourceFile in outputs) {
    final String path = sourceFile.path;
    if (!path.startsWith(buildDirectory) && !path.startsWith(projectDirectory)) {
      throw MisplacedOutputException(path, target);
    }
  }
}

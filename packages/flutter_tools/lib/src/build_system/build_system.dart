// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/platform.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart';
import 'exceptions.dart';
import 'file_hash_store.dart';
import 'source.dart';
import 'targets/assets.dart';
import 'targets/dart.dart';
import 'targets/ios.dart';
import 'targets/linux.dart';
import 'targets/macos.dart';
import 'targets/windows.dart';

export 'source.dart';

/// The [BuildSystem] instance.
BuildSystem get buildSystem => context.get<BuildSystem>();

/// The function signature of a build target which can be invoked to perform
/// the underlying task.
typedef BuildAction = FutureOr<void> Function(
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
  /// Create a new [BuildSystemConfig].
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
/// To determine if the action for a target needs to be executed, the
/// [BuildSystem] performs a hash of the file contents for both inputs and
/// outputs. This is tracked separately in the [FileHashStore].
///
/// A Target has both implicit and explicit inputs and outputs. Only the
/// later are safe to evaluate before invoking the [buildAction]. For example,
/// a wildcard output pattern requires the outputs to exist before it can
/// glob files correctly.
///
/// - All listed inputs are considered explicit inputs.
/// - Outputs which are provided as [Source.pattern].
///   without wildcards are considered explicit.
/// - The remaining outputs are considered implicit.
///
/// For each target, executing its action creates a corresponding stamp file
/// which records both the input and output files. This file is read by
/// subsequent builds to determine which file hashes need to be checked. If the
/// stamp file is missing, the target's action is always rerun.
///
///  file: `example_target.stamp`
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
/// ## Code review
///
/// ### Targes should only depend on files that are provided as inputs
///
/// Example: gen_snapshot must be provided as an input to the aot_elf
/// build steps, even though it isn't a source file. This ensures that changes
/// to the gen_snapshot binary (during a local engine build) correctly
/// trigger a corresponding build update.
///
/// Example: aot_elf has a dependency on the dill and packages file
/// produced by the kernel_snapshot step.
///
/// ### Targest should declare all outputs produced
///
/// If a target produces an output it should be listed, even if it is not
/// intended to be consumed by another target.
///
/// ## Unit testing
///
/// Most targets will invoke an external binary which makes unit testing
/// trickier. It is recommend that for unit testing that a Fake is used and
/// provided via the dependency injection system. a [Testbed] may be used to
/// set up the environment before the test is run. Unit tests should fully
/// exercise the rule, ensuring that the existing input and output verification
/// logic can run, as well as verifying it correctly handles provided defines
/// and meets any additional contracts present in the target.
class Target {
  const Target({
    @required this.name,
    @required this.inputs,
    @required this.outputs,
    @required this.buildAction,
    this.defines = const <String, String>{},
    this.dependencies = const <Target>[],
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
  final List<Source> outputs;

  /// The action which performs this build step.
  final BuildAction buildAction;

  /// A set of default defines which are automatically applied to an action.
  ///
  /// When a build is performed, all defaults and user provided defines are
  /// aggregated and combined into a single map.
  ///
  /// It is an error if the same define is provided with a different value.
  final Map<String, String> defines;

  /// Collect hashes for all inputs to determine if any have changed.
  Future<Map<String, ChangeType>> computeChanges(
    List<File> inputs,
    Environment environment,
    FileHashStore fileHashStore,
  ) async {
    final Map<String, ChangeType> updates = <String, ChangeType>{};
    final File stamp = _findStampFile(environment);
    final Set<String> previousInputs = <String>{};
    final List<String> previousOutputs = <String>[];

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
        final List<Object> outputs = values['outputs'];
        inputs.cast<String>().forEach(previousInputs.add);
        outputs.cast<String>().forEach(previousOutputs.add);
      }
    }

    // For each input type, first determine if we've already computed the hash
    // for it. If not and it is a directory we skip hashing and instead use a
    // timestamp. If it is a file we collect it to be sent off for hashing as
    // a group.
    final List<File> sourcesToHash = <File>[];
    final List<File> missingInputs = <File>[];
    for (File file in inputs) {
      if (!file.existsSync()) {
        missingInputs.add(file);
        continue;
      }

      final String absolutePath = file.resolveSymbolicLinksSync();
      final String previousHash = fileHashStore.previousHashes[absolutePath];
      if (fileHashStore.currentHashes.containsKey(absolutePath)) {
        final String currentHash = fileHashStore.currentHashes[absolutePath];
        if (currentHash != previousHash) {
          updates[absolutePath] = previousInputs.contains(absolutePath)
              ? ChangeType.Modified
              : ChangeType.Added;
        }
      } else {
        sourcesToHash.add(file);
      }
    }
    // Check if any outputs were deleted or modified from the previous run.
    for (String previousOutput in previousOutputs) {
      final File file = fs.file(previousOutput);
      if (!file.existsSync()) {
        updates[previousOutput] = ChangeType.Removed;
        continue;
      }
      final String absolutePath = file.resolveSymbolicLinksSync();
      final String previousHash = fileHashStore.previousHashes[absolutePath];
      if (fileHashStore.currentHashes.containsKey(absolutePath)) {
        final String currentHash = fileHashStore.currentHashes[absolutePath];
        if (currentHash != previousHash) {
          updates[absolutePath] = previousInputs.contains(absolutePath)
              ? ChangeType.Modified
              : ChangeType.Added;
        }
      } else {
        sourcesToHash.add(file);
      }
    }

    if (missingInputs.isNotEmpty) {
      throw MissingInputException(missingInputs, name);
    }

    // If we have files to hash, compute them asynchronously and then
    // update the result.
    if (sourcesToHash.isNotEmpty) {
      final List<File> dirty = await fileHashStore.hashFiles(sourcesToHash);
      for (File file in dirty) {
        final String absolutePath = file.resolveSymbolicLinksSync();
        updates[absolutePath] = previousInputs.contains(absolutePath)
            ? ChangeType.Modified
            : ChangeType.Added;
      }
    }

    // Find which, if any, inputs have been deleted.
    final Set<String> currentInputPaths = Set<String>.from(
      inputs.map<String>((File entity) => entity.resolveSymbolicLinksSync())
    );
    for (String previousInput in previousInputs) {
      if (!currentInputPaths.contains(previousInput)) {
        updates[previousInput] = ChangeType.Removed;
      }
    }
    return updates;
  }

  /// Invoke to remove the stamp file if the [buildAction] threw an exception;
  void clearStamp(Environment environment) {
    final File stamp = _findStampFile(environment);
    if (stamp.existsSync()) {
      stamp.deleteSync();
    }
  }

  void _writeStamp(
    List<File> inputs,
    List<File> outputs,
    Environment environment,
  ) {
    final File stamp = _findStampFile(environment);
    final List<String> inputPaths = <String>[];
    for (File input in inputs) {
      inputPaths.add(input.resolveSymbolicLinksSync());
    }
    final List<String> outputPaths = <String>[];
    for (File output in outputs) {
      outputPaths.add(output.resolveSymbolicLinksSync());
    }
    final Map<String, Object> result = <String, Object>{
      'inputs': inputPaths,
      'outputs': outputPaths,
    };
    if (!stamp.existsSync()) {
      stamp.createSync();
    }
    stamp.writeAsStringSync(json.encode(result));
  }

  /// Resolve the set of input patterns and functions into a concrete list of
  /// files.
  List<File> resolveInputs(
    Environment environment,
  ) {
    return _resolveConfiguration(inputs, environment, implicit: true, inputs: true);
  }

  /// Find the current set of declared outputs, including wildcard directories.
  ///
  /// The [implicit] flag controls whether it is safe to evaluate [Source]s
  /// which uses functions, behaviors, or patterns.
  List<File> resolveOutputs(
    Environment environment,
    { bool implicit = true, }
  ) {
    final List<File> outputEntities = _resolveConfiguration(outputs, environment, implicit: implicit, inputs: false);
    if (implicit) {
      verifyOutputDirectories(outputEntities, environment, this);
    }
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
          .map((File file) => file.resolveSymbolicLinksSync())
          .toList(),
      'outputs': resolveOutputs(environment, implicit: false)
          .map((File file) => file.path)
          .toList(),
      'stamp': _findStampFile(environment).absolute.path,
    };
  }

  /// Locate the stamp file for a particular target name and environment.
  File _findStampFile(Environment environment) {
    final String fileName = '$name.stamp';
    return environment.buildDir.childFile(fileName);
  }

  static List<File> _resolveConfiguration(
      List<Source> config, Environment environment, { bool implicit = true, bool inputs = true }) {
    final SourceVisitor collector = SourceVisitor(environment, inputs);
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
/// Using the build mode to produce different output. Note that the action
/// is still responsible for outputting a different file, as defined by the
/// corresponding output [Source].
///
///    final BuildMode buildMode = getBuildModeFromDefines(environment.defines);
///    if (buildMode == BuildMode.debug) {
///      environment.buildDir.childFile('debug.output')
///        ..createSync()
///        ..writeAsStringSync('debug');
///    } else {
///      environment.buildDir.childFile('non_debug.output')
///        ..createSync()
///        ..writeAsStringSync('non_debug');
///    }
class Environment {
  /// Create a new [Environment] object.
  ///
  /// Only [projectDir] is required. The remaining environment locations have
  /// defaults based on it.
  factory Environment({
    @required Directory projectDir,
    Directory buildDir,
    Map<String, String> defines = const <String, String>{},
  }) {
    // Compute a unique hash of this build's particular environment.
    // Sort the keys by key so that the result is stable. We always
    // include the engine and dart versions.
    String buildPrefix;
    final List<String> keys = defines.keys.toList()..sort();
    final StringBuffer buffer = StringBuffer();
    for (String key in keys) {
      buffer.write(key);
      buffer.write(defines[key]);
    }
    // in case there was no configuration, provide some value.
    buffer.write('Flutter is awesome');
    final String output = buffer.toString();
    final Digest digest = md5.convert(utf8.encode(output));
    buildPrefix = hex.encode(digest.bytes);

    final Directory rootBuildDir = buildDir ?? projectDir.childDirectory('build');
    final Directory buildDirectory = rootBuildDir.childDirectory(buildPrefix);
    return Environment._(
      projectDir: projectDir,
      buildDir: buildDirectory,
      rootBuildDir: rootBuildDir,
      cacheDir: Cache.instance.getRoot(),
      defines: defines,
    );
  }

  Environment._({
    @required this.projectDir,
    @required this.buildDir,
    @required this.rootBuildDir,
    @required this.cacheDir,
    @required this.defines,
  });

  /// The [Source] value which is substituted with the path to [projectDir].
  static const String kProjectDirectory = '{PROJECT_DIR}';

  /// The [Source] value which is substituted with the path to [buildDir].
  static const String kBuildDirectory = '{BUILD_DIR}';

  /// The [Source] value which is substituted with the path to [cacheDir].
  static const String kCacheDirectory = '{CACHE_DIR}';

  /// The [Source] value which is substituted with a path to the flutter root.
  static const String kFlutterRootDirectory = '{FLUTTER_ROOT}';

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

  /// Additional configuration passed to the build targets.
  ///
  /// Setting values here forces a unique build directory to be chosen
  /// which prevents the config from leaking into different builds.
  final Map<String, String> defines;

  /// The root build directory shared by all builds.
  final Directory rootBuildDir;
}

/// The result information from the build system.
class BuildResult {
  BuildResult(this.success, this.exceptions, this.performance);

  final bool success;
  final Map<String, ExceptionMeasurement> exceptions;
  final Map<String, PerformanceMeasurement> performance;

  bool get hasException => exceptions.isNotEmpty;
}

/// The build system is responsible for invoking and ordering [Target]s.
class BuildSystem {
  BuildSystem([Map<String, Target> targets])
    : targets = targets ?? _defaultTargets;

  /// All currently registered targets.
  static final Map<String, Target> _defaultTargets = <String, Target>{
    unpackMacos.name: unpackMacos,
    debugMacosApplication.name: debugMacosApplication,
    macoReleaseApplication.name: macoReleaseApplication,
    unpackLinux.name: unpackLinux,
    unpackWindows.name: unpackWindows,
    copyAssets.name: copyAssets,
    kernelSnapshot.name: kernelSnapshot,
    aotElfProfile.name: aotElfProfile,
    aotElfRelease.name: aotElfRelease,
    aotAssemblyProfile.name: aotAssemblyProfile,
    aotAssemblyRelease.name: aotAssemblyRelease,
    releaseIosApplication.name: releaseIosApplication,
    profileIosApplication.name: profileIosApplication,
    debugIosApplication.name: debugIosApplication,
  };

  final Map<String, Target> targets;

  /// Build the target `name` and all of its dependencies.
  Future<BuildResult> build(
    String name,
    Environment environment,
    BuildSystemConfig buildSystemConfig,
  ) async {
    final Target target = _getNamedTarget(name);
    environment.buildDir.createSync(recursive: true);

    // Load file hash store from previous builds.
    final FileHashStore fileCache = FileHashStore(environment)
      ..initialize();

    // Perform sanity checks on build.
    checkCycles(target);

    final _BuildInstance buildInstance = _BuildInstance(environment, fileCache, buildSystemConfig);
    bool passed = true;
    try {
      passed = await buildInstance.invokeTarget(target);
    } finally {
      // Always persist the file cache to disk.
      fileCache.persist();
    }
    return BuildResult(
      passed,
      buildInstance.exceptionMeasurements,
      buildInstance.stepTimings,
    );
  }

  /// Collect any default defines provided by the targets.
  ///
  /// Throws a [ConflictingDefineException] if there are multiple different
  /// values for the same key.
  Map<String, String> collectDefines(String name, Map<String, String> initial) {
    final Target target = _getNamedTarget(name);
    checkCycles(target);
    Map<String, String> fold(Map<String, String> accumulation, Target current) {
      if (current.defines != null) {
        for (MapEntry<String, String> entry in current.defines.entries) {
          if (accumulation.containsKey(entry.key)) {
            final String previousValue = accumulation[entry.key];
            if (previousValue != entry.value) {
              throw ConflictingDefineException(entry.key, previousValue, entry.value);
            }
          } else {
            accumulation[entry.key] = entry.value;
          }
        }
      }
      return accumulation;
    }
    return target.fold(initial, fold);
  }

  /// Describe the target `name` and all of its dependencies.
  List<Map<String, Object>> describe(
    String name,
    Environment environment,
  ) {
    final Target target = _getNamedTarget(name);
    environment.buildDir.createSync(recursive: true);
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

  /// Return the stamp files for a previously run build.
  List<File> stampFilesFor(String name, Environment environment) {
    final Target target = _getNamedTarget(name);
    final List<File> result = <File>[];
    target.fold(result, (List<File> files, Target current) {
      result.add(current._findStampFile(environment));
    });
    return result;
  }

  // Returns the corresponding target or throws.
  Target _getNamedTarget(String name) {
    final Target target = targets[name];
    if (target == null) {
      throw Exception('No registered target:$name.');
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
  final FileHashStore fileCache;

  // Timings collected during target invocation.
  final Map<String, PerformanceMeasurement> stepTimings = <String, PerformanceMeasurement>{};

  // Exceptions caught during the build process.
  final Map<String, ExceptionMeasurement> exceptionMeasurements = <String, ExceptionMeasurement>{};

  Future<bool> invokeTarget(Target target) async {
    final List<bool> results = await Future.wait(target.dependencies.map(invokeTarget));
    if (results.any((bool result) => !result)) {
      return false;
    }
    final AsyncMemoizer<bool> memoizer = pending[target.name] ??= AsyncMemoizer<bool>();
    return memoizer.runOnce(() => _invokeInternal(target));
  }

  Future<bool> _invokeInternal(Target target) async {
    final PoolResource resource = await resourcePool.request();
    final Stopwatch stopwatch = Stopwatch()..start();
    bool passed = true;
    bool skipped = false;
    try {
      final List<File> inputs = target.resolveInputs(environment);
      final Map<String, ChangeType> updates = await target.computeChanges(inputs, environment, fileCache);
      if (updates.isEmpty) {
        skipped = true;
        printTrace('Skipping target: ${target.name}');
      } else {
        printTrace('${target.name}: Starting');
        // build actions may be null.
        await target?.buildAction(updates, environment);
        printTrace('${target.name}: Complete');

        final List<File> outputs = target.resolveOutputs(environment);
        // Update hashes for output files.
        await fileCache.hashFiles(outputs);
        target._writeStamp(inputs, outputs, environment);
      }
    } catch (exception, stackTrace) {
      // TODO(jonahwilliams): test
      target.clearStamp(environment);
      passed = false;
      skipped = false;
      exceptionMeasurements[target.name] = ExceptionMeasurement(
          target.name, exception, stackTrace);
    } finally {
      resource.release();
      stopwatch.stop();
      stepTimings[target.name] = PerformanceMeasurement(
          target.name, stopwatch.elapsedMilliseconds, skipped, passed);
    }
    return passed;
  }
}

/// Helper class to collect exceptions.
class ExceptionMeasurement {
  ExceptionMeasurement(this.target, this.exception, this.stackTrace);

  final String target;
  final dynamic exception;
  final StackTrace stackTrace;
}

/// Helper class to collect measurement data.
class PerformanceMeasurement {
  PerformanceMeasurement(this.target, this.elapsedMilliseconds, this.skiped, this.passed);
  final int elapsedMilliseconds;
  final String target;
  final bool skiped;
  final bool passed;
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

/// Verifies that all files exist and are in a subdirectory of [Environment.buildDir].
void verifyOutputDirectories(List<File> outputs, Environment environment, Target target) {
  final String buildDirectory = environment.buildDir.resolveSymbolicLinksSync();
  final String projectDirectory = environment.projectDir.resolveSymbolicLinksSync();
  final List<File> missingOutputs = <File>[];
  for (File sourceFile in outputs) {
    if (!sourceFile.existsSync()) {
      missingOutputs.add(sourceFile);
      continue;
    }
    final String path = sourceFile.resolveSymbolicLinksSync();
    if (!path.startsWith(buildDirectory) && !path.startsWith(projectDirectory)) {
      throw MisplacedOutputException(path, target.name);
    }
  }
  if (missingOutputs.isNotEmpty) {
    throw MissingOutputException(missingOutputs, target.name);
  }
}

// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import '../base/file_system.dart';
import '../base/platform.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart';
import 'exceptions.dart';
import 'file_hash_store.dart';
import 'source.dart';

export 'source.dart';

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
/// ### Targets should declare all outputs produced
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
abstract class Target {
  const Target();
  /// The user-readable name of the target.
  ///
  /// This information is surfaced in the assemble commands and used as an
  /// argument to build a particular target.
  String get name;

  /// The dependencies of this target.
  List<Target> get dependencies;

  /// The input [Source]s which are diffed to determine if a target should run.
  List<Source> get inputs;

  /// The output [Source]s which we attempt to verify are correctly produced.
  List<Source> get outputs;

  /// The action which performs this build step.
  Future<void> build(Environment environment);

  /// Create a [Node] with resolved inputs and outputs.
  Node _toNode(Environment environment) {
    final List<File> inputs = resolveInputs(environment);
    final List<File> outputs = resolveOutputs(environment);
    return Node(
      this,
      inputs,
      outputs,
      <Node>[
        for (Target target in dependencies) target._toNode(environment)
      ],
      environment
    );
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
      inputPaths.add(input.path);
    }
    final List<String> outputPaths = <String>[];
    for (File output in outputs) {
      outputPaths.add(output.path);
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
  ) {
    final List<File> outputEntities = _resolveConfiguration(outputs, environment, inputs: false);
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
          .map((File file) => file.path)
          .toList(),
      'outputs': resolveOutputs(environment)
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
    @required Directory outputDir,
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
      outputDir: outputDir,
      projectDir: projectDir,
      buildDir: buildDirectory,
      rootBuildDir: rootBuildDir,
      cacheDir: Cache.instance.getRoot(),
      defines: defines,
      flutterRootDir: fs.directory(Cache.flutterRoot),
    );
  }

  Environment._({
    @required this.outputDir,
    @required this.projectDir,
    @required this.buildDir,
    @required this.rootBuildDir,
    @required this.cacheDir,
    @required this.defines,
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

  /// The [Source] value which is substituted with a path to [outputDir].
  static const String kOutputDirectory = '{OUTPUT_DIR}';

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
  /// Defaults to to the value of [Cache.flutterRoot].
  final Directory flutterRootDir;

  /// The `OUTPUT_DIR` environment variable.
  ///
  /// Must be provided to configure the output location for the final artifacts.
  final Directory outputDir;

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
  BuildResult({
    @required this.success,
    this.exceptions = const <String, ExceptionMeasurement>{},
    this.performance = const <String, PerformanceMeasurement>{},
    this.inputFiles = const <File>[],
    this.outputFiles = const <File>[],
  });

  final bool success;
  final Map<String, ExceptionMeasurement> exceptions;
  final Map<String, PerformanceMeasurement> performance;
  final List<File> inputFiles;
  final List<File> outputFiles;

  bool get hasException => exceptions.isNotEmpty;
}

/// The build system is responsible for invoking and ordering [Target]s.
class BuildSystem {
  const BuildSystem();

  /// Build `target` and all of its dependencies.
  Future<BuildResult> build(
    Target target,
    Environment environment,
    { BuildSystemConfig buildSystemConfig = const BuildSystemConfig() }
  ) async {
    environment.buildDir.createSync(recursive: true);
    environment.outputDir.createSync(recursive: true);

    // Load file hash store from previous builds.
    final FileHashStore fileCache = FileHashStore(environment)
      ..initialize();

    // Perform sanity checks on build.
    checkCycles(target);

    final Node node = target._toNode(environment);
    final _BuildInstance buildInstance = _BuildInstance(environment, fileCache, buildSystemConfig);
    bool passed = true;
    try {
      passed = await buildInstance.invokeTarget(node);
    } finally {
      // Always persist the file cache to disk.
      fileCache.persist();
    }
    // TODO(jonahwilliams): this is a bit of a hack, due to various parts of
    // the flutter tool writing these files unconditionally. Since Xcode uses
    // timestamps to track files, this leads to unnecessary rebuilds if they
    // are included. Once all the places that write these files have been
    // tracked down and moved into assemble, these checks should be removable.
    // We also remove files under .dart_tool, since these are intermediaries
    // and don't need to be tracked by external systems.
    {
      buildInstance.inputFiles.removeWhere((String path, File file) {
        return path.contains('.flutter-plugins') ||
                       path.contains('xcconfig') ||
                     path.contains('.dart_tool');
      });
      buildInstance.outputFiles.removeWhere((String path, File file) {
        return path.contains('.flutter-plugins') ||
                       path.contains('xcconfig') ||
                     path.contains('.dart_tool');
      });
    }
    return BuildResult(
      success: passed,
      exceptions: buildInstance.exceptionMeasurements,
      performance: buildInstance.stepTimings,
      inputFiles: buildInstance.inputFiles.values.toList()
          ..sort((File a, File b) => a.path.compareTo(b.path)),
      outputFiles: buildInstance.outputFiles.values.toList()
          ..sort((File a, File b) => a.path.compareTo(b.path)),
    );
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
  final Map<String, File> inputFiles = <String, File>{};
  final Map<String, File> outputFiles = <String, File>{};

  // Timings collected during target invocation.
  final Map<String, PerformanceMeasurement> stepTimings = <String, PerformanceMeasurement>{};

  // Exceptions caught during the build process.
  final Map<String, ExceptionMeasurement> exceptionMeasurements = <String, ExceptionMeasurement>{};

  Future<bool> invokeTarget(Node node) async {
    final List<bool> results = await Future.wait(node.dependencies.map(invokeTarget));
    if (results.any((bool result) => !result)) {
      return false;
    }
    final AsyncMemoizer<bool> memoizer = pending[node.target.name] ??= AsyncMemoizer<bool>();
    return memoizer.runOnce(() => _invokeInternal(node));
  }

  Future<bool> _invokeInternal(Node node) async {
    final PoolResource resource = await resourcePool.request();
    final Stopwatch stopwatch = Stopwatch()..start();
    bool passed = true;
    bool skipped = false;
    try {
      final bool canSkip = await node.computeChanges(environment, fileCache);
      for (File input in node.inputs) {
        // The build system should produce a list of aggregate input and output
        // files for the overall build. The goal is to provide this to a hosting
        // build system, such as Xcode, to configure logic for when to skip the
        // rule/phase which contains the flutter build. When looking at the
        // inputs and outputs for the individual rules, we need to be careful to
        // remove inputs that were actually output from previous build steps.
        // This indicates that the file is actual an output or intermediary. If
        // these files are included as both inputs and outputs then it isn't
        // possible to construct a DAG describing the build.
        final String resolvedPath = input.resolveSymbolicLinksSync();
        if (outputFiles.containsKey(resolvedPath)) {
          continue;
        }
        inputFiles[resolvedPath] = input;
      }
      if (canSkip) {
        skipped = true;
        printStatus('Skipping target: ${node.target.name}');
        for (File output in node.outputs) {
          outputFiles[output.path] = output;
        }
      } else {
        printStatus('${node.target.name}: Starting due to ${node.invalidatedReasons}');
        await node.target.build(environment);
        printStatus('${node.target.name}: Complete');

        // Update hashes for output files.
        await fileCache.hashFiles(node.outputs);
        node.target._writeStamp(node.inputs, node.outputs, environment);
        for (File output in node.outputs) {
          outputFiles[output.path] = output;
        }
        // Delete outputs from previous stages that are no longer a part of the build.
        for (String previousOutput in node.previousOutputs) {
          if (!outputFiles.containsKey(previousOutput)) {
            fs.file(previousOutput).deleteSync();
          }
        }
      }
    } catch (exception, stackTrace) {
      node.target.clearStamp(environment);
      passed = false;
      skipped = false;
      exceptionMeasurements[node.target.name] = ExceptionMeasurement(
          node.target.name, exception, stackTrace);
    } finally {
      resource.release();
      stopwatch.stop();
      stepTimings[node.target.name] = PerformanceMeasurement(
          node.target.name, stopwatch.elapsedMilliseconds, skipped, passed);
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
  PerformanceMeasurement(this.target, this.elapsedMilliseconds, this.skipped, this.passed);
  final int elapsedMilliseconds;
  final String target;
  final bool skipped;
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
    final String path = sourceFile.path;
    if (!path.startsWith(buildDirectory) && !path.startsWith(projectDirectory)) {
      throw MisplacedOutputException(path, target.name);
    }
  }
  if (missingOutputs.isNotEmpty) {
    throw MissingOutputException(missingOutputs, target.name);
  }
}

/// A node in the build graph.
class Node {
  Node(this.target, this.inputs, this.outputs, this.dependencies,
      Environment environment) {
    final File stamp = target._findStampFile(environment);

    // If the stamp file doesn't exist, we haven't run this step before and
    // all inputs were added.
    if (!stamp.existsSync()) {
      // No stamp file, not safe to skip.
      _dirty = true;
      return;
    }
    final String content = stamp.readAsStringSync();
    // Something went wrong writing the stamp file.
    if (content == null || content.isEmpty) {
      stamp.deleteSync();
      // Malformed stamp file, not safe to skip.
      _dirty = true;
      return;
    }
    Map<String, Object> values;
    try {
      values = json.decode(content);
    } on FormatException {
      // The json is malformed in some way.
      _dirty = true;
      return;
    }
    final Object inputs = values['inputs'];
    final Object outputs = values['outputs'];
    if (inputs is List<Object> && outputs is List<Object>) {
      inputs?.cast<String>()?.forEach(previousInputs.add);
      outputs?.cast<String>()?.forEach(previousOutputs.add);
    } else {
      // The json is malformed in some way.
      _dirty = true;
    }
  }

  /// The resolved input files.
  ///
  /// These files may not yet exist if they are produced by previous steps.
  final List<File> inputs;

  /// The resolved output files.
  ///
  /// These files may not yet exist if the target hasn't run yet.
  final List<File> outputs;

  /// The target definition which contains the build action to invoke.
  final Target target;

  /// All of the nodes that this one depends on.
  final List<Node> dependencies;

  /// Output file paths from the previous invocation of this build node.
  final Set<String> previousOutputs = <String>{};

  /// Input file paths from the previous invocation of this build node.
  final Set<String> previousInputs = <String>{};

  /// One or more reasons why a task was invalidated.
  ///
  /// May be empty if the task was skipped.
  final Set<InvalidedReason> invalidatedReasons = <InvalidedReason>{};

  /// Whether this node needs an action performed.
  bool get dirty => _dirty;
  bool _dirty = false;

  /// Collect hashes for all inputs to determine if any have changed.
  ///
  /// Returns whether this target can be skipped.
  Future<bool> computeChanges(
    Environment environment,
    FileHashStore fileHashStore,
  ) async {
    final Set<String> currentOutputPaths = <String>{
      for (File file in outputs) file.path
    };
    // For each input, first determine if we've already computed the hash
    // for it. Then collect it to be sent off for hashing as a group.
    final List<File> sourcesToHash = <File>[];
    final List<File> missingInputs = <File>[];
    for (File file in inputs) {
      if (!file.existsSync()) {
        missingInputs.add(file);
        continue;
      }

      final String absolutePath = file.path;
      final String previousHash = fileHashStore.previousHashes[absolutePath];
      if (fileHashStore.currentHashes.containsKey(absolutePath)) {
        final String currentHash = fileHashStore.currentHashes[absolutePath];
        if (currentHash != previousHash) {
          invalidatedReasons.add(InvalidedReason.inputChanged);
          _dirty = true;
        }
      } else {
        sourcesToHash.add(file);
      }
    }

    // For each output, first determine if we've already computed the hash
    // for it. Then collect it to be sent off for hashing as a group.
    for (String previousOutput in previousOutputs) {
      // output paths changed.
      if (!currentOutputPaths.contains(previousOutput)) {
        _dirty = true;
        invalidatedReasons.add(InvalidedReason.outputSetChanged);
        // if this isn't a current output file there is no reason to compute the hash.
        continue;
      }
      final File file = fs.file(previousOutput);
      if (!file.existsSync()) {
        invalidatedReasons.add(InvalidedReason.outputMissing);
        _dirty = true;
        continue;
      }
      final String absolutePath = file.path;
      final String previousHash = fileHashStore.previousHashes[absolutePath];
      if (fileHashStore.currentHashes.containsKey(absolutePath)) {
        final String currentHash = fileHashStore.currentHashes[absolutePath];
        if (currentHash != previousHash) {
          invalidatedReasons.add(InvalidedReason.outputChanged);
          _dirty = true;
        }
      } else {
        sourcesToHash.add(file);
      }
    }

    // If we depend on a file that doesnt exist on disk, kill the build.
    if (missingInputs.isNotEmpty) {
      throw MissingInputException(missingInputs, target.name);
    }

    // If we have files to hash, compute them asynchronously and then
    // update the result.
    if (sourcesToHash.isNotEmpty) {
      final List<File> dirty = await fileHashStore.hashFiles(sourcesToHash);
      if (dirty.isNotEmpty) {
        invalidatedReasons.add(InvalidedReason.inputChanged);
        _dirty = true;
      }
    }
    return !_dirty;
  }
}

/// A description of why a task was rerun.
enum InvalidedReason {
  /// An input file has an updated hash.
  inputChanged,

  /// An output file has an updated hash.
  outputChanged,

  /// An output file that is expected is missing.
  outputMissing,

  /// The set of expected output files changed.
  outputSetChanged,
}

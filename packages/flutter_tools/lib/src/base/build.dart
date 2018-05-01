// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;

import 'package:crypto/crypto.dart' show md5;
import 'package:meta/meta.dart';
import 'package:quiver/core.dart' show hash2;

import '../android/android_sdk.dart';
import '../artifacts.dart';
import '../build_info.dart';
import '../compile.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import '../ios/mac.dart';
import '../version.dart';
import 'context.dart';
import 'file_system.dart';
import 'process.dart';

GenSnapshot get genSnapshot => context[GenSnapshot];

/// A snapshot build configuration.
class SnapshotType {
  SnapshotType(this.platform, this.mode)
    : assert(mode != null);

  final TargetPlatform platform;
  final BuildMode mode;

  @override
  String toString() => '$platform $mode';
}

/// Interface to the gen_snapshot command-line tool.
class GenSnapshot {
  const GenSnapshot();

  Future<int> run({
    @required SnapshotType snapshotType,
    @required String packagesPath,
    @required String depfilePath,
    Iterable<String> additionalArgs: const <String>[],
  }) {
    final List<String> args = <String>[
      '--await_is_keyword',
      '--causal_async_stacks',
      '--packages=$packagesPath',
      '--dependencies=$depfilePath',
      '--print_snapshot_sizes',
    ]..addAll(additionalArgs);
    final String snapshotterPath = artifacts.getArtifactPath(Artifact.genSnapshot, snapshotType.platform, snapshotType.mode);

    // iOS gen_snapshot is a multi-arch binary. Running as an i386 binary will
    // generate armv7 code. Running as an x86_64 binary will generate arm64
    // code. /usr/bin/arch can be used to run binaries with the specified
    // architecture.
    if (snapshotType.platform == TargetPlatform.ios) {
      // TODO(cbracken): for the moment, always generate only arm64 code.
      return runCommandAndStreamOutput(<String>['/usr/bin/arch', '-x86_64', snapshotterPath]..addAll(args));
    }
    return runCommandAndStreamOutput(<String>[snapshotterPath]..addAll(args));
  }
}

/// A fingerprint for a set of build input files and properties.
///
/// This class can be used during build actions to compute a fingerprint of the
/// build action inputs, and if unchanged from the previous build, skip the
/// build step. This assumes that build outputs are strictly a product of the
/// fingerprint inputs.
class Fingerprint {
  Fingerprint.fromBuildInputs(Map<String, String> properties, Iterable<String> inputPaths) {
    final Iterable<File> files = inputPaths.map(fs.file);
    final Iterable<File> missingInputs = files.where((File file) => !file.existsSync());
    if (missingInputs.isNotEmpty)
      throw new ArgumentError('Missing input files:\n' + missingInputs.join('\n'));

    _checksums = <String, String>{};
    for (File file in files) {
      final List<int> bytes = file.readAsBytesSync();
      _checksums[file.path] = md5.convert(bytes).toString();
    }
    _properties = <String, String>{}..addAll(properties);
  }

  /// Creates a Fingerprint from serialized JSON.
  ///
  /// Throws [ArgumentError], if there is a version mismatch between the
  /// serializing framework and this framework.
  Fingerprint.fromJson(String jsonData) {
    final Map<String, dynamic> content = json.decode(jsonData);

    final String version = content['version'];
    if (version != FlutterVersion.instance.frameworkRevision)
      throw new ArgumentError('Incompatible fingerprint version: $version');
    _checksums = content['files'] ?? <String, String>{};
    _properties = content['properties'] ?? <String, String>{};
  }

  Map<String, String> _checksums;
  Map<String, String> _properties;

  String toJson() => json.encode(<String, dynamic>{
    'version': FlutterVersion.instance.frameworkRevision,
    'properties': _properties,
    'files': _checksums,
  });

  @override
  bool operator==(dynamic other) {
    if (identical(other, this))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final Fingerprint typedOther = other;
    return _equalMaps(typedOther._checksums, _checksums)
        && _equalMaps(typedOther._properties, _properties);
  }

  bool _equalMaps(Map<String, String> a, Map<String, String> b) {
    return a.length == b.length
        && a.keys.every((String key) => a[key] == b[key]);
  }

  @override
  // Ignore map entries here to avoid becoming inconsistent with equals
  // due to differences in map entry order.
  int get hashCode => hash2(_properties.length, _checksums.length);
}

final RegExp _separatorExpr = new RegExp(r'([^\\]) ');
final RegExp _escapeExpr = new RegExp(r'\\(.)');

/// Parses a VM snapshot dependency file.
///
/// Snapshot dependency files are a single line mapping the output snapshot to a
/// space-separated list of input files used to generate that output. Spaces and
/// backslashes are escaped with a backslash. e.g,
///
/// outfile : file1.dart fil\\e2.dart fil\ e3.dart
///
/// will return a set containing: 'file1.dart', 'fil\e2.dart', 'fil e3.dart'.
Future<Set<String>> readDepfile(String depfilePath) async {
  // Depfile format:
  // outfile1 outfile2 : file1.dart file2.dart file3.dart
  final String contents = await fs.file(depfilePath).readAsString();
  final String dependencies = contents.split(': ')[1];
  return dependencies
      .replaceAllMapped(_separatorExpr, (Match match) => '${match.group(1)}\n')
      .split('\n')
      .map((String path) => path.replaceAllMapped(_escapeExpr, (Match match) => match.group(1)).trim())
      .where((String path) => path.isNotEmpty)
      .toSet();
}

/// Dart snapshot builder.
///
/// Builds Dart snapshots in one of three modes:
///   * Script snapshot: architecture-independent snapshot of a Dart script
///     and core libraries.
///   * AOT snapshot: architecture-specific ahead-of-time compiled snapshot
///     suitable for loading with `mmap`.
///   * Assembly AOT snapshot: architecture-specific ahead-of-time compile to
///     assembly suitable for compilation as a static or dynamic library.
class Snapshotter {
  /// Builds an architecture-independent snapshot of the specified script.
  Future<int> buildScriptSnapshot({
    @required String mainPath,
    @required String snapshotPath,
    @required String depfilePath,
    @required String packagesPath
  }) async {
    final SnapshotType snapshotType = new SnapshotType(null, BuildMode.debug);
    final String vmSnapshotData = artifacts.getArtifactPath(Artifact.vmSnapshotData);
    final String isolateSnapshotData = artifacts.getArtifactPath(Artifact.isolateSnapshotData);
    final List<String> args = <String>[
      '--snapshot_kind=script',
      '--script_snapshot=$snapshotPath',
      '--vm_snapshot_data=$vmSnapshotData',
      '--isolate_snapshot_data=$isolateSnapshotData',
      '--enable-mirrors=false',
      mainPath,
    ];

    final String fingerprintPath = '$depfilePath.fingerprint';
    final Set<String> outputPaths = <String>[snapshotPath].toSet();
    if (!await _isBuildRequired(snapshotType, outputPaths, depfilePath, mainPath, fingerprintPath)) {
      printTrace('Skipping script snapshot build. Fingerprints match.');
      return 0;
    }

    // Build the snapshot.
    final int exitCode = await genSnapshot.run(
        snapshotType: snapshotType,
        packagesPath: packagesPath,
        depfilePath: depfilePath,
        additionalArgs: args,
    );

    if (exitCode != 0)
      return exitCode;
    await _writeFingerprint(snapshotType, outputPaths, depfilePath, mainPath, fingerprintPath);
    return exitCode;
  }

  /// Compiles a Dart file to kernel.
  ///
  /// Returns the output kernel file path, or null on failure.
  Future<String> compileKernel({
    @required TargetPlatform platform,
    @required BuildMode buildMode,
    @required String mainPath,
    @required String outputPath,
    List<String> extraFrontEndOptions: const <String>[],
  }) async {
    final Directory outputDir = fs.directory(outputPath);
    outputDir.createSync(recursive: true);

    printTrace('Compiling Dart to kernel: $mainPath');
    final List<String> entryPointsJsonFiles = <String>[
      artifacts.getArtifactPath(Artifact.entryPointsJson, platform, buildMode),
      artifacts.getArtifactPath(Artifact.entryPointsExtraJson, platform, buildMode),
    ];

    if ((extraFrontEndOptions != null) && extraFrontEndOptions.isNotEmpty)
      printTrace('Extra front-end options: $extraFrontEndOptions');

    final String depfilePath = fs.path.join(outputPath, 'kernel_compile.d');
    final CompilerOutput compilerOutput = await kernelCompiler.compile(
      sdkRoot: artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath),
      mainPath: mainPath,
      outputFilePath: fs.path.join(outputPath, 'app.dill'),
      depFilePath: depfilePath,
      extraFrontEndOptions: extraFrontEndOptions,
      linkPlatformKernelIn: true,
      aot: true,
      entryPointsJsonFiles: entryPointsJsonFiles,
      trackWidgetCreation: false,
    );

    // Write path to frontend_server, since things need to be re-generated when that changes.
    final String frontendPath = artifacts.getArtifactPath(Artifact.frontendServerSnapshotForEngineDartSdk);
    await fs.directory(outputPath).childFile('frontend_server.d').writeAsString('frontend_server.d: $frontendPath\n');

    return compilerOutput?.outputFilename;
  }

  /// Builds an architecture-specific ahead-of-time compiled snapshot of the specified script.
  Future<int> buildAotSnapshot({
    @required TargetPlatform platform,
    @required BuildMode buildMode,
    @required String mainPath,
    @required String packagesPath,
    @required String outputPath,
    @required bool previewDart2,
    @required bool preferSharedLibrary,
    List<String> extraGenSnapshotOptions: const <String>[],
  }) async {
    if (!_isValidAotPlatform(platform, buildMode)) {
      printError('${getNameForTargetPlatform(platform)} does not support AOT compilation.');
      return -1;
    }

    final bool compileToSharedLibrary = preferSharedLibrary && androidSdk.ndkCompiler != null;
    if (preferSharedLibrary && !compileToSharedLibrary) {
      printStatus('Could not find NDK compiler. Not building in shared library mode.');
    }

    final PackageMap packageMap = new PackageMap(packagesPath);
    final String packageMapError = packageMap.checkValid();
    if (packageMapError != null) {
      printError(packageMapError);
      return -2;
    }

    final Directory outputDir = fs.directory(outputPath);
    outputDir.createSync(recursive: true);

    final String skyEnginePkg = _getPackagePath(packageMap, 'sky_engine');
    final String uiPath = fs.path.join(skyEnginePkg, 'lib', 'ui', 'ui.dart');
    final String vmServicePath = fs.path.join(skyEnginePkg, 'sdk_ext', 'vmservice_io.dart');
    final String vmEntryPoints = artifacts.getArtifactPath(Artifact.dartVmEntryPointsTxt, platform, buildMode);
    final String ioEntryPoints = artifacts.getArtifactPath(Artifact.dartIoEntriesTxt, platform, buildMode);

    final List<String> inputPaths = <String>[uiPath, vmServicePath, vmEntryPoints, ioEntryPoints, mainPath];
    final Set<String> outputPaths = new Set<String>();

    final String vmSnapshotData = fs.path.join(outputDir.path, 'vm_snapshot_data');
    final String isolateSnapshotData = fs.path.join(outputDir.path, 'isolate_snapshot_data');
    final String depfilePath = fs.path.join(outputDir.path, 'snapshot.d');
    final List<String> genSnapshotArgs = <String>[
      '--vm_snapshot_data=$vmSnapshotData',
      '--isolate_snapshot_data=$isolateSnapshotData',
      '--url_mapping=dart:ui,$uiPath',
      '--url_mapping=dart:vmservice_io,$vmServicePath',
      '--embedder_entry_points_manifest=$vmEntryPoints',
      '--embedder_entry_points_manifest=$ioEntryPoints',
      '--dependencies=$depfilePath',
    ];
    if (previewDart2) {
      genSnapshotArgs.addAll(<String>[
        '--reify-generic-functions',
        '--strong',
      ]);
    }
    if (buildMode != BuildMode.release) {
      genSnapshotArgs.addAll(<String>[
        '--no-checked',
        '--conditional_directives',
      ]);
    }
    if (extraGenSnapshotOptions != null && extraGenSnapshotOptions.isNotEmpty) {
      printTrace('Extra gen_snapshot options: $extraGenSnapshotOptions');
      genSnapshotArgs.addAll(extraGenSnapshotOptions);
    }

    final String assembly = fs.path.join(outputDir.path, 'snapshot_assembly.S');
    if (compileToSharedLibrary || platform == TargetPlatform.ios) {
      // Assembly AOT snapshot.
      outputPaths.add(assembly);
      genSnapshotArgs.add('--snapshot_kind=app-aot-assembly');
      genSnapshotArgs.add('--assembly=$assembly');
    } else {
      // Blob AOT snapshot.
      final String vmSnapshotInstructions = fs.path.join(outputDir.path, 'vm_snapshot_instr');
      final String isolateSnapshotInstructions = fs.path.join(outputDir.path, 'isolate_snapshot_instr');
      outputPaths.addAll(<String>[vmSnapshotData, isolateSnapshotData]);
      genSnapshotArgs.addAll(<String>[
        '--snapshot_kind=app-aot-blobs',
        '--vm_snapshot_instructions=$vmSnapshotInstructions',
        '--isolate_snapshot_instructions=$isolateSnapshotInstructions',
      ]);
    }

    if (platform == TargetPlatform.android_arm) {
      // Not supported by the Pixel in 32-bit mode.
      genSnapshotArgs.add('--no-use-integer-division');
    }

    genSnapshotArgs.add(mainPath);

    // Verify that all required inputs exist.
    final Iterable<String> missingInputs = inputPaths.where((String p) => !fs.isFileSync(p));
    if (missingInputs.isNotEmpty) {
      printError('Missing input files: $missingInputs from $inputPaths');
      return -3;
    }

    // If inputs and outputs have not changed since last run, skip the build.
    final String fingerprintPath = '$depfilePath.fingerprint';
    final SnapshotType snapshotType = new SnapshotType(platform, buildMode);
    if (!await _isBuildRequired(snapshotType, outputPaths, depfilePath, mainPath, fingerprintPath)) {
      printTrace('Skipping AOT snapshot build. Fingerprint match.');
      return 0;
    }

    final int genSnapshotExitCode = await genSnapshot.run(
      snapshotType: new SnapshotType(platform, buildMode),
      packagesPath: packageMap.packagesPath,
      depfilePath: depfilePath,
      additionalArgs: genSnapshotArgs,
    );
    if (genSnapshotExitCode != 0) {
      printError('Dart snapshot generator failed with exit code $genSnapshotExitCode');
      return -4;
    }

    // Write path to gen_snapshot, since snapshots have to be re-generated when we roll
    // the Dart SDK.
    await outputDir.childFile('gen_snapshot.d').writeAsString('snapshot.d: $genSnapshot\n');

    // On iOS, we use Xcode to compile the snapshot into a dynamic library that the
    // end-developer can link into their app.
    if (platform == TargetPlatform.ios) {
      printStatus('Building App.framework...');
      const List<String> commonBuildOptions = const <String>['-arch', 'arm64', '-miphoneos-version-min=8.0'];

      final String assemblyO = fs.path.join(outputDir.path, 'snapshot_assembly.o');
      await xcode.cc(commonBuildOptions.toList()..addAll(<String>['-c', assembly, '-o', assemblyO]));

      final String frameworkDir = fs.path.join(outputDir.path, 'App.framework');
      fs.directory(frameworkDir).createSync(recursive: true);
      final String appLib = fs.path.join(frameworkDir, 'App');
      final List<String> linkArgs = commonBuildOptions.toList()..addAll(<String>[
          '-dynamiclib',
          '-Xlinker', '-rpath', '-Xlinker', '@executable_path/Frameworks',
          '-Xlinker', '-rpath', '-Xlinker', '@loader_path/Frameworks',
          '-install_name', '@rpath/App.framework/App',
          '-o', appLib,
          assemblyO,
      ]);
      await xcode.clang(linkArgs);
    } else {
      if (compileToSharedLibrary) {
        // A word of warning: Instead of compiling via two steps, to a .o file and
        // then to a .so file we use only one command. When using two commands
        // gcc will end up putting a .eh_frame and a .debug_frame into the shared
        // library. Without stripping .debug_frame afterwards, unwinding tools
        // based upon libunwind use just one and ignore the contents of the other
        // (which causes it to not look into the other section and therefore not
        // find the correct unwinding information).
        final String assemblySo = fs.path.join(outputDir.path, 'app.so');
        await runCheckedAsync(<String>[androidSdk.ndkCompiler]
            ..addAll(androidSdk.ndkCompilerArgs)
            ..addAll(<String>[ '-shared', '-nostdlib', '-o', assemblySo, assembly ]));
      }
    }

    // Compute and record build fingerprint.
    await _writeFingerprint(snapshotType, outputPaths, depfilePath, mainPath, fingerprintPath);
    return 0;
  }

  bool _isValidAotPlatform(TargetPlatform platform, BuildMode buildMode) {
    if (platform == TargetPlatform.ios && buildMode == BuildMode.debug)
      return false;
    return const <TargetPlatform>[
      TargetPlatform.android_arm,
      TargetPlatform.android_arm64,
      TargetPlatform.ios,
    ].contains(platform);
  }

  String _getPackagePath(PackageMap packageMap, String package) {
    return fs.path.dirname(fs.path.fromUri(packageMap.map[package]));
  }

  Future<bool> _isBuildRequired(SnapshotType type, Set<String> outputPaths, String depfilePath, String mainPath, String fingerprintPath) async {
    final File fingerprintFile = fs.file(fingerprintPath);
    final List<String> requiredFiles = <String>[fingerprintPath, depfilePath]..addAll(outputPaths);
    if (!requiredFiles.every(fs.isFileSync))
      return true;

    try {
      if (fingerprintFile.existsSync()) {
        final Fingerprint oldFingerprint = new Fingerprint.fromJson(await fingerprintFile.readAsString());
        final Set<String> inputFilePaths = await readDepfile(depfilePath)..add(mainPath)..addAll(outputPaths);
        final Fingerprint newFingerprint = createFingerprint(type, mainPath, inputFilePaths);
        return oldFingerprint != newFingerprint;
      }
    } catch (e) {
      // Log exception and continue, this step is a performance improvement only.
      printTrace('Rebuilding snapshot due to fingerprint check error: $e');
    }
    return true;
  }

  Future<Null> _writeFingerprint(SnapshotType type, Set<String> outputPaths, String depfilePath, String mainPath, String fingerprintPath) async {
    try {
      final Set<String> inputFilePaths = await readDepfile(depfilePath)
        ..add(mainPath)
        ..addAll(outputPaths);
      final Fingerprint fingerprint = createFingerprint(type, mainPath, inputFilePaths);
      await fs.file(fingerprintPath).writeAsString(fingerprint.toJson());
    } catch (e, s) {
      // Log exception and continue, this step is a performance improvement only.
      printStatus('Error during snapshot fingerprinting: $e\n$s');
    }
  }

  static Fingerprint createFingerprint(SnapshotType type, String mainPath, Iterable<String> inputFilePaths) {
    final Map<String, String> properties = <String, String>{
      'buildMode': type.mode.toString(),
      'targetPlatform': type.platform?.toString() ?? '',
      'entryPoint': mainPath,
    };
    final List<String> pathsWithSnapshotData = inputFilePaths.toList()
      ..add(artifacts.getArtifactPath(Artifact.vmSnapshotData))
      ..add(artifacts.getArtifactPath(Artifact.isolateSnapshotData));
    return new Fingerprint.fromBuildInputs(properties, pathsWithSnapshotData);
  }
}

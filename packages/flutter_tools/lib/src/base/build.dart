// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../android/android_sdk.dart';
import '../artifacts.dart';
import '../build_info.dart';
import '../compile.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import '../ios/mac.dart';
import 'context.dart';
import 'file_system.dart';
import 'fingerprint.dart';
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
    IOSArch iosArch,
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
      final String hostArch = iosArch == IOSArch.armv7 ? '-i386' : '-x86_64';
      return runCommandAndStreamOutput(<String>['/usr/bin/arch', hostArch, snapshotterPath]..addAll(args));
    }
    return runCommandAndStreamOutput(<String>[snapshotterPath]..addAll(args));
  }
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
class ScriptSnapshotter {
  /// Builds an architecture-independent snapshot of the specified script.
  Future<int> build({
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

    final Fingerprinter fingerprinter = new Fingerprinter(
      fingerprintPath: '$depfilePath.fingerprint',
      paths: <String>[
        mainPath,
        snapshotPath,
        vmSnapshotData,
        isolateSnapshotData,
      ],
      properties: <String, String>{
        'buildMode': snapshotType.mode.toString(),
        'targetPlatform': snapshotType.platform?.toString() ?? '',
        'entryPoint': mainPath,
      },
      depfilePaths: <String>[depfilePath],
    );
    if (await fingerprinter.doesFingerprintMatch()) {
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
    await fingerprinter.writeFingerprint();
    return exitCode;
  }
}

class AOTSnapshotter {
  /// Builds an architecture-specific ahead-of-time compiled snapshot of the specified script.
  Future<int> build({
    @required TargetPlatform platform,
    @required BuildMode buildMode,
    @required String mainPath,
    @required String packagesPath,
    @required String outputPath,
    @required bool previewDart2,
    @required bool preferSharedLibrary,
    IOSArch iosArch,
    List<String> extraGenSnapshotOptions: const <String>[],
  }) async {
    if (!_isValidAotPlatform(platform, buildMode)) {
      printError('${getNameForTargetPlatform(platform)} does not support AOT compilation.');
      return -1;
    }
    // TODO(cbracken): replace IOSArch with TargetPlatform.ios_{armv7,arm64}.
    assert(platform != TargetPlatform.ios || iosArch != null);

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

    final String depfilePath = fs.path.join(outputDir.path, 'snapshot.d');
    final List<String> genSnapshotArgs = <String>[
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
      final String vmSnapshotData = fs.path.join(outputDir.path, 'vm_snapshot_data');
      final String isolateSnapshotData = fs.path.join(outputDir.path, 'isolate_snapshot_data');
      final String vmSnapshotInstructions = fs.path.join(outputDir.path, 'vm_snapshot_instr');
      final String isolateSnapshotInstructions = fs.path.join(outputDir.path, 'isolate_snapshot_instr');
      outputPaths.addAll(<String>[vmSnapshotData, isolateSnapshotData, vmSnapshotInstructions, isolateSnapshotInstructions]);
      genSnapshotArgs.addAll(<String>[
        '--snapshot_kind=app-aot-blobs',
        '--vm_snapshot_data=$vmSnapshotData',
        '--isolate_snapshot_data=$isolateSnapshotData',
        '--vm_snapshot_instructions=$vmSnapshotInstructions',
        '--isolate_snapshot_instructions=$isolateSnapshotInstructions',
      ]);
    }

    if (platform == TargetPlatform.android_arm || iosArch == IOSArch.armv7) {
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
    final Fingerprinter fingerprinter = new Fingerprinter(
      fingerprintPath: '$depfilePath.fingerprint',
      paths: <String>[mainPath]..addAll(inputPaths)..addAll(outputPaths),
      properties: <String, String>{
        'buildMode': buildMode.toString(),
        'targetPlatform': platform.toString(),
        'entryPoint': mainPath,
        'dart2': previewDart2.toString(),
        'sharedLib': compileToSharedLibrary.toString(),
        'extraGenSnapshotOptions': extraGenSnapshotOptions.join(' '),
      },
      depfilePaths: <String>[depfilePath],
    );
    if (await fingerprinter.doesFingerprintMatch()) {
      printTrace('Skipping AOT snapshot build. Fingerprint match.');
      return 0;
    }

    final int genSnapshotExitCode = await genSnapshot.run(
      snapshotType: new SnapshotType(platform, buildMode),
      packagesPath: packageMap.packagesPath,
      depfilePath: depfilePath,
      additionalArgs: genSnapshotArgs,
      iosArch: iosArch,
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
      final RunResult result = await _buildIosFramework(iosArch: iosArch, assemblyPath: assembly, outputPath: outputDir.path);
      if (result.exitCode != 0)
        return result.exitCode;
    } else if (compileToSharedLibrary) {
      final RunResult result = await _buildAndroidSharedLibrary(assemblyPath: assembly, outputPath: outputDir.path);
      if (result.exitCode != 0)
        return result.exitCode;
    }

    // Compute and record build fingerprint.
    await fingerprinter.writeFingerprint();
    return 0;
  }

  /// Builds an iOS framework at [outputPath]/App.framework from the assembly
  /// source at [assemblyPath].
  Future<RunResult> _buildIosFramework({
    @required IOSArch iosArch,
    @required String assemblyPath,
    @required String outputPath,
  }) async {
    final String targetArch = iosArch == IOSArch.armv7 ? 'armv7' : 'arm64';
    printStatus('Building App.framework for $targetArch...');
    final List<String> commonBuildOptions = <String>['-arch', targetArch, '-miphoneos-version-min=8.0'];

    final String assemblyO = fs.path.join(outputPath, 'snapshot_assembly.o');
    final RunResult compileResult = await xcode.cc(commonBuildOptions.toList()..addAll(<String>['-c', assemblyPath, '-o', assemblyO]));
    if (compileResult.exitCode != 0)
      return compileResult;

    final String frameworkDir = fs.path.join(outputPath, 'App.framework');
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
    final RunResult linkResult = await xcode.clang(linkArgs);
    return linkResult;
  }

  /// Builds an Android shared library at [outputPath]/app.so from the assembly
  /// source at [assemblyPath].
  Future<RunResult> _buildAndroidSharedLibrary({
    @required String assemblyPath,
    @required String outputPath,
  }) async {
    // A word of warning: Instead of compiling via two steps, to a .o file and
    // then to a .so file we use only one command. When using two commands
    // gcc will end up putting a .eh_frame and a .debug_frame into the shared
    // library. Without stripping .debug_frame afterwards, unwinding tools
    // based upon libunwind use just one and ignore the contents of the other
    // (which causes it to not look into the other section and therefore not
    // find the correct unwinding information).
    final String assemblySo = fs.path.join(outputPath, 'app.so');
    return await runCheckedAsync(<String>[androidSdk.ndkCompiler]
        ..addAll(androidSdk.ndkCompilerArgs)
        ..addAll(<String>[ '-shared', '-nostdlib', '-o', assemblySo, assemblyPath ]));
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
}

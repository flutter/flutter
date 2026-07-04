// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:process/process.dart';

import '../../../flutter_tools_extension.dart';
import '../../artifacts.dart';

const _cmakeCacheFileName = 'CMakeCache.txt';
const _cmakeFilesDirectoryName = 'CMakeFiles';
const _expectedNinjaGeneratorLine = 'CMAKE_GENERATOR:INTERNAL=Ninja';

final List<ArtifactDependency> _kLinuxArtifactDependencies = <ArtifactDependency>[
  ArtifactDependency(
    hostPlatform: 'linux-x64',
    name: Artifact.linuxDesktopPath.name,
    sha256Checksums: <String, String>{},
    targetArchitecture: 'x64',
    targetPlatform: 'linux',
  ),
  ArtifactDependency(
    hostPlatform: 'linux-x64',
    name: Artifact.linuxHeaders.name,
    sha256Checksums: <String, String>{},
    targetArchitecture: 'x64',
    targetPlatform: 'linux',
  ),
  ArtifactDependency(
    hostPlatform: 'linux-x64',
    name: Artifact.icuData.name,
    sha256Checksums: <String, String>{},
    targetArchitecture: 'x64',
    targetPlatform: 'linux',
  ),
];

/// The build service implementation for Linux platform devices.
base class LinuxBuildService extends BuildService {
  LinuxBuildService({FileSystem? fileSystem, ProcessManager? processManager})
    : _fileSystem = fileSystem ?? const LocalFileSystem(),
      _processManager = processManager ?? const LocalProcessManager();

  final FileSystem _fileSystem;
  final ProcessManager _processManager;

  @override
  late final List<Target> targets = <Target>[
    LinuxAssembleTarget(fileSystem: _fileSystem, processManager: _processManager),
  ];

  @override
  Map<String, Object?> get nativeAssetsConfig => const <String, Object?>{};

  @override
  List<ArtifactDependency> get artifactDependencies => _kLinuxArtifactDependencies;
}

/// The compilation target for the Linux application.
base class LinuxAssembleTarget extends Target {
  LinuxAssembleTarget({required FileSystem fileSystem, required ProcessManager processManager})
    : _fileSystem = fileSystem,
      _processManager = processManager;

  final FileSystem _fileSystem;
  final ProcessManager _processManager;

  @override
  String get name => 'assemble_linux_app';

  @override
  String? get cliSubcommand => 'custom-linux';

  @override
  String? get cliDescription => 'Build a prototype Linux extension desktop application.';

  @override
  List<String> get dependencies => const <String>[];

  @override
  List<String> get inputs => const <String>[];

  @override
  List<String> get outputs => const <String>[];

  @override
  Future<Map<String, Object?>> build(BuildEnvironment env) async {
    final String projectPath = _fileSystem.path.fromUri(env.projectRoot);
    final String outputPath = _fileSystem.path.fromUri(env.outputDirectory);

    // Make sure the output directory exists.
    final Directory outputDir = _fileSystem.directory(outputPath);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final String buildType = env.defines['CMAKE_BUILD_TYPE'] ?? 'Debug';
    final String targetPlatform = env.defines['FLUTTER_TARGET_PLATFORM'] ?? 'linux-x64';

    try {
      final File cacheFile = _fileSystem.file(
        _fileSystem.path.join(outputPath, _cmakeCacheFileName),
      );
      if (cacheFile.existsSync()) {
        var isNinjaGenerator = false;
        try {
          final String cacheContent = cacheFile.readAsStringSync();
          isNinjaGenerator = cacheContent.contains(_expectedNinjaGeneratorLine);
        } on FileSystemException {
          isNinjaGenerator = false;
        }
        if (!isNinjaGenerator) {
          _cleanCMakeCache(outputPath);
        }
      }
    } on FileSystemException {
      // Safely ignore file system exceptions during proactive cache check.
    }

    // 1. cmake -G Ninja -DCMAKE_BUILD_TYPE=<buildType> -DFLUTTER_TARGET_PLATFORM=<targetPlatform> -S <project>/linux -B <output>
    final String linuxProjectPath = _fileSystem.path.join(projectPath, 'linux');
    final cmakeConfigureCmd = <String>[
      'cmake',
      '-G',
      'Ninja',
      '-DCMAKE_BUILD_TYPE=$buildType',
      '-DFLUTTER_TARGET_PLATFORM=$targetPlatform',
      '-S',
      linuxProjectPath,
      '-B',
      outputPath,
    ];
    ProcessResult configureResult = await _processManager.run(
      cmakeConfigureCmd,
      environment: env.defines,
    );
    if (configureResult.exitCode != 0) {
      var cacheFilesExist = false;
      try {
        final File cacheFile = _fileSystem.file(
          _fileSystem.path.join(outputPath, _cmakeCacheFileName),
        );
        final Directory cmakeFilesDir = _fileSystem.directory(
          _fileSystem.path.join(outputPath, _cmakeFilesDirectoryName),
        );
        cacheFilesExist = cacheFile.existsSync() || cmakeFilesDir.existsSync();
      } on FileSystemException {
        cacheFilesExist = false;
      }
      if (cacheFilesExist) {
        _cleanCMakeCache(outputPath);
        configureResult = await _processManager.run(cmakeConfigureCmd, environment: env.defines);
      }
    }
    if (configureResult.exitCode != 0) {
      throw Exception(
        'CMake configuration failed with exit code ${configureResult.exitCode}.\n'
        'Stdout: ${configureResult.stdout}\n'
        'Stderr: ${configureResult.stderr}',
      );
    }

    // 2. cmake --build <output>
    final cmakeBuildCmd = <String>['cmake', '--build', outputPath];
    final ProcessResult buildResult = await _processManager.run(
      cmakeBuildCmd,
      environment: env.defines,
    );
    if (buildResult.exitCode != 0) {
      throw Exception(
        'CMake build failed with exit code ${buildResult.exitCode}.\n'
        'Stdout: ${buildResult.stdout}\n'
        'Stderr: ${buildResult.stderr}',
      );
    }

    // 3. Resolve the executable name from pubspec.yaml
    final File pubspec = _fileSystem.file(_fileSystem.path.join(projectPath, 'pubspec.yaml'));
    var appName = 'app';
    if (pubspec.existsSync()) {
      final String pubspecContent = pubspec.readAsStringSync();
      final nameRegExp = RegExp(r'^name:\s+(\w+)', multiLine: true);
      final Match? match = nameRegExp.firstMatch(pubspecContent);
      if (match != null) {
        appName = match.group(1)!;
      }
    }

    final String executablePath = _fileSystem.path.join(outputPath, 'bundle', appName);
    return <String, Object?>{
      'executablePath': _fileSystem.file(executablePath).absolute.uri.toString(),
    };
  }

  void _cleanCMakeCache(String outputPath) {
    final File cacheFile = _fileSystem.file(_fileSystem.path.join(outputPath, _cmakeCacheFileName));
    try {
      if (cacheFile.existsSync()) {
        cacheFile.deleteSync();
      }
    } on FileSystemException {
      // Safely ignore file system exceptions when cleaning cache files.
    }

    final Directory cmakeFilesDir = _fileSystem.directory(
      _fileSystem.path.join(outputPath, _cmakeFilesDirectoryName),
    );
    try {
      if (cmakeFilesDir.existsSync()) {
        cmakeFilesDir.deleteSync(recursive: true);
      }
    } on FileSystemException {
      // Safely ignore file system exceptions when cleaning cache files.
    }
  }
}

/// The artifact service implementation for Linux platform devices.
base class LinuxArtifactService extends ArtifactService {
  LinuxArtifactService({FileSystem? fileSystem})
    : _fileSystem = fileSystem ?? const LocalFileSystem();

  final FileSystem _fileSystem;

  @override
  Set<ArtifactDependency> get artifacts => _kLinuxArtifactDependencies.toSet();

  @override
  Future<void> downloadArtifacts(
    Set<ArtifactDependency> artifacts, {
    required String buildMode,
    required String hostPlatform,
    required String targetPlatform,
  }) async {
    final Directory cacheDir = _fileSystem.systemTempDirectory
        .childDirectory('flutter_tools_extension_artifacts')
        .childDirectory(targetPlatform)
        .childDirectory(buildMode);
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    for (final dep in artifacts) {
      final File artifactFile = cacheDir.childFile(dep.name);
      if (!artifactFile.existsSync()) {
        artifactFile.writeAsStringSync(
          'Simulated artifact content for ${dep.name} ($hostPlatform -> $targetPlatform)',
        );
      }
    }
  }
}

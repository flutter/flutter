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
const String _kTargetPlatformLinuxX64 = 'linux-x64';
const String _kAssembleLinuxAppTarget = 'assemble_linux_app';
const String _kCustomLinuxSubcommand = 'custom-linux';
final RegExp _kAppNamePattern = RegExp(r'^name:\s+(\w+)', multiLine: true);

final List<ArtifactDependency> _kLinuxArtifactDependencies = <ArtifactDependency>[
  ArtifactDependency(
    hostPlatform: _kTargetPlatformLinuxX64,
    name: Artifact.linuxDesktopPath.name,
    sha256Checksums: const <String, String>{},
    targetArchitecture: 'x64',
    targetPlatform: 'linux',
  ),
  ArtifactDependency(
    hostPlatform: _kTargetPlatformLinuxX64,
    name: Artifact.linuxHeaders.name,
    sha256Checksums: const <String, String>{},
    targetArchitecture: 'x64',
    targetPlatform: 'linux',
  ),
  ArtifactDependency(
    hostPlatform: _kTargetPlatformLinuxX64,
    name: Artifact.icuData.name,
    sha256Checksums: const <String, String>{},
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
    LinuxAssembleTarget(_fileSystem, _processManager),
  ];

  @override
  Map<String, Object?> get nativeAssetsConfig => const <String, Object?>{};

  @override
  List<ArtifactDependency> get artifactDependencies => _kLinuxArtifactDependencies;
}

/// The compilation target for the Linux application.
base class LinuxAssembleTarget extends Target {
  LinuxAssembleTarget(this._fileSystem, this._processManager);

  final FileSystem _fileSystem;
  final ProcessManager _processManager;

  @override
  String get name => _kAssembleLinuxAppTarget;

  @override
  String? get cliSubcommand => _kCustomLinuxSubcommand;

  @override
  String? get cliDescription => 'Build a prototype Linux extension desktop application.';

  @override
  String? get targetPlatformDirectory => 'linux-x64';

  @override
  String? get targetDeviceDirectory => 'linux-proto-1';

  @override
  String? get pluginPlatformKey => 'linux';

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

    final Directory outputDir = _fileSystem.directory(outputPath);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final String targetPlatform =
        env.defines['FLUTTER_TARGET_PLATFORM'] ??
        env.defines['targetPlatform'] ??
        _kTargetPlatformLinuxX64;
    final String buildMode = env.defines['buildMode'] ?? 'debug';

    // Parse the app name from pubspec.yaml.
    var appName = 'app';
    final File pubspecFile = _fileSystem.file(_fileSystem.path.join(projectPath, 'pubspec.yaml'));
    if (pubspecFile.existsSync()) {
      final String content = pubspecFile.readAsStringSync();
      final Match? match = _kAppNamePattern.firstMatch(content);
      if (match != null && match.group(1) != null) {
        appName = match.group(1)!;
      }
    }

    final String cmakeBuildType =
        env.defines['CMAKE_BUILD_TYPE'] ??
        switch (buildMode) {
          'release' => 'Release',
          'profile' => 'Profile',
          _ => 'Debug',
        };

    // Clean up stale CMake cache if it was configured with a non-Ninja generator.
    final File cacheFile = _fileSystem.file(_fileSystem.path.join(outputPath, _cmakeCacheFileName));
    if (cacheFile.existsSync() && !_isNinjaGenerator(cacheFile)) {
      _cleanCMakeCache(outputPath);
    }

    final String linuxProjectPath = _fileSystem.path.join(projectPath, 'linux');
    final File generatedPluginsFile = _fileSystem.file(
      _fileSystem.path.join(linuxProjectPath, 'flutter', 'generated_plugins.cmake'),
    );
    final File generatedPluginHeader = _fileSystem.file(
      _fileSystem.path.join(linuxProjectPath, 'flutter', 'generated_plugin_registrant.h'),
    );
    final File generatedPluginSource = _fileSystem.file(
      _fileSystem.path.join(linuxProjectPath, 'flutter', 'generated_plugin_registrant.cc'),
    );

    // Extension-Side Plugin Symlinking
    //
    // Unlike standard host-side injection, the extension is responsible for setting up symlinks
    // to the plugins. It creates symlinks in the target project's ephemeral directory.
    final Directory symlinkDirectory = _fileSystem.directory(
      _fileSystem.path.join(linuxProjectPath, 'flutter', 'ephemeral', '.plugin_symlinks'),
    );
    if (symlinkDirectory.existsSync()) {
      symlinkDirectory.deleteSync(recursive: true);
    }
    symlinkDirectory.createSync(recursive: true);

    for (final ExtensionPlugin plugin in env.plugins) {
      final Link link = symlinkDirectory.childLink(plugin.name);
      link.createSync(plugin.path);
    }

    String camelCaseToUnderscore(String camelCaseSelector) {
      final regex = RegExp(r'(?<=[a-z])(?=[A-Z])');
      return camelCaseSelector.split(regex).join('_').toLowerCase();
    }

    final methodChannelPlugins = <Map<String, Object?>>[];
    final ffiPlugins = <Map<String, Object?>>[];

    // Classify resolved plugins into MethodChannel plugins vs FFI plugins based
    // on their custom plugin configuration map.
    for (final ExtensionPlugin plugin in env.plugins) {
      final Map<String, Object?> config = plugin.configuration;
      final isFfi = config['ffiPlugin'] == true;
      final String? pluginClass = config['class'] as String? ?? config['pluginClass'] as String?;

      if (pluginClass != null) {
        final String filename = config['filename'] as String? ?? camelCaseToUnderscore(pluginClass);
        methodChannelPlugins.add(<String, Object?>{
          'name': plugin.name,
          'class': pluginClass,
          'filename': filename,
          'path': plugin.path,
        });
      } else if (isFfi) {
        ffiPlugins.add(<String, Object?>{'name': plugin.name, 'path': plugin.path});
      }
    }

    // Step 1: Write generated_plugins.cmake
    // This dynamically generates the CMake script to include and link each plugin natively
    // in the custom Linux build, using the relative symlink paths created above.
    final cmakeContent = StringBuffer();
    cmakeContent.writeln('# Generated file, do not edit.');
    cmakeContent.writeln();
    cmakeContent.writeln('list(APPEND FLUTTER_PLUGIN_LIST');
    for (final plugin in methodChannelPlugins) {
      cmakeContent.writeln('  ${plugin["name"]}');
    }
    cmakeContent.writeln(')');
    cmakeContent.writeln();
    cmakeContent.writeln('list(APPEND FLUTTER_FFI_PLUGIN_LIST');
    for (final plugin in ffiPlugins) {
      cmakeContent.writeln('  ${plugin["name"]}');
    }
    cmakeContent.writeln(')');
    cmakeContent.writeln();
    cmakeContent.writeln('set(PLUGIN_BUNDLED_LIBRARIES)');
    cmakeContent.writeln();
    cmakeContent.writeln(r'foreach(plugin ${FLUTTER_PLUGIN_LIST})');
    cmakeContent.writeln(
      r'  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/linux plugins/${plugin})',
    );
    cmakeContent.writeln(r'  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)');
    cmakeContent.writeln(
      r'  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)',
    );
    cmakeContent.writeln(r'  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})');
    cmakeContent.writeln('endforeach(plugin)');
    cmakeContent.writeln();
    cmakeContent.writeln(r'foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})');
    cmakeContent.writeln(
      r'  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/linux plugins/${ffi_plugin})',
    );
    cmakeContent.writeln(
      r'  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})',
    );
    cmakeContent.writeln('endforeach(ffi_plugin)');

    generatedPluginsFile.writeAsStringSync(cmakeContent.toString());

    // 2. Write generated_plugin_registrant.h
    final headerContent = StringBuffer();
    headerContent.writeln('// Generated file. Do not edit.');
    headerContent.writeln('#ifndef GENERATED_PLUGIN_REGISTRANT_');
    headerContent.writeln('#define GENERATED_PLUGIN_REGISTRANT_');
    headerContent.writeln();
    headerContent.writeln('#include <flutter_linux/flutter_linux.h>');
    headerContent.writeln();
    headerContent.writeln('// Registers Flutter plugins.');
    headerContent.writeln('void fl_register_plugins(FlPluginRegistry* registry);');
    headerContent.writeln();
    headerContent.writeln('#endif  // GENERATED_PLUGIN_REGISTRANT_');

    generatedPluginHeader.writeAsStringSync(headerContent.toString());

    // 3. Write generated_plugin_registrant.cc
    final sourceContent = StringBuffer();
    sourceContent.writeln('// Generated file. Do not edit.');
    sourceContent.writeln('#include "generated_plugin_registrant.h"');
    sourceContent.writeln();
    for (final plugin in methodChannelPlugins) {
      sourceContent.writeln('#include <${plugin["name"]}/${plugin["filename"]}.h>');
    }
    sourceContent.writeln();
    sourceContent.writeln('void fl_register_plugins(FlPluginRegistry* registry) {');
    for (final plugin in methodChannelPlugins) {
      sourceContent.writeln('  g_autoptr(FlPluginRegistrar) ${plugin["name"]}_registrar =');
      sourceContent.writeln(
        '      fl_plugin_registry_get_registrar_for_plugin(registry, "${plugin["class"]}");',
      );
      sourceContent.writeln(
        '  ${plugin["filename"]}_register_with_registrar(${plugin["name"]}_registrar);',
      );
    }
    sourceContent.writeln('}');

    generatedPluginSource.writeAsStringSync(sourceContent.toString());

    final cmakeConfigureCmd = <String>[
      'cmake',
      '-G',
      'Ninja',
      '-DCMAKE_BUILD_TYPE=$cmakeBuildType',
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
        final File cf = _fileSystem.file(_fileSystem.path.join(outputPath, _cmakeCacheFileName));
        final Directory cmakeFilesDir = _fileSystem.directory(
          _fileSystem.path.join(outputPath, _cmakeFilesDirectoryName),
        );
        cacheFilesExist = cf.existsSync() || cmakeFilesDir.existsSync();
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

    final cmakeBuildCmd = <String>['cmake', '--build', outputPath, '--target', 'install'];
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

    final String executablePath = _fileSystem.path.join(outputPath, 'bundle', appName);
    return <String, Object?>{
      'executablePath': _fileSystem.file(executablePath).absolute.uri.toString(),
    };
  }

  bool _isNinjaGenerator(File cacheFile) {
    try {
      return cacheFile.readAsStringSync().contains(_expectedNinjaGeneratorLine);
    } on FileSystemException {
      return false;
    }
  }

  void _cleanCMakeCache(String outputPath) {
    try {
      _fileSystem.file(_fileSystem.path.join(outputPath, _cmakeCacheFileName)).deleteSync();
    } on FileSystemException {
      // Safely ignore if cache file does not exist or cannot be deleted.
    }
    try {
      _fileSystem
          .directory(_fileSystem.path.join(outputPath, _cmakeFilesDirectoryName))
          .deleteSync(recursive: true);
    } on FileSystemException {
      // Safely ignore if cache directory does not exist or cannot be deleted.
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
    for (final artifact in artifacts) {
      final File artifactFile = cacheDir.childFile(artifact.name);
      if (!artifactFile.existsSync()) {
        artifactFile.writeAsStringSync('Mock binary content for ${artifact.name}');
      }
    }
  }
}

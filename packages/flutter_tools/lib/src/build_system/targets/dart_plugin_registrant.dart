// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';

import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../dart/package_map.dart';
import '../../flutter_plugins.dart';
import '../../project.dart';
import '../build_system.dart';

/// Generates a new `./dart_tool/flutter_build/dart_plugin_registrant.dart`
/// based on the current dependency map in `pubspec.lock`.
class DartPluginRegistrantTarget extends Target {
  /// Construct a [DartPluginRegistrantTarget].
  const DartPluginRegistrantTarget() : _project = null;

  /// Construct a [DartPluginRegistrantTarget].
  ///
  /// If `project` is unset, a [FlutterProject] based on environment is used.
  @visibleForTesting
  const DartPluginRegistrantTarget.test(FlutterProject project) : _project = project;

  static const _builtInPlatformKeys = <String>{
    'android',
    'ios',
    'linux',
    'macos',
    'web',
    'windows',
  };

  final FlutterProject? _project;

  @override
  Future<void> build(Environment environment) async {
    assert(environment.generateDartPluginRegistry);
    final FlutterProject project = _project ?? FlutterProject.fromDirectory(environment.projectDir);
    final File packageConfigFile = findPackageConfigFileOrDefault(environment.projectDir);
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      packageConfigFile,
      logger: environment.logger,
    );
    final String targetFilePath =
        environment.defines[kTargetFile] ?? environment.fileSystem.path.join('lib', 'main.dart');
    final File mainFile = environment.fileSystem.file(targetFilePath);
    final String? rawPluginPlatformKey = environment.defines[kExtensionPluginPlatformKey]?.trim();
    final String? customPlatformKey =
        (rawPluginPlatformKey != null && rawPluginPlatformKey.isNotEmpty)
        ? rawPluginPlatformKey
        : environment.defines[kExtensionTargetOs]?.trim().toLowerCase();
    final extraPlatformKeys = <String>{
      if (customPlatformKey != null &&
          customPlatformKey.isNotEmpty &&
          !_builtInPlatformKeys.contains(customPlatformKey))
        customPlatformKey,
    };

    await generateMainDartWithPluginRegistrant(
      project,
      packageConfig,
      mainFile,
      extraPlatformKeys: extraPlatformKeys,
    );
  }

  @override
  Future<bool> canSkip(Environment environment) async {
    if (!environment.generateDartPluginRegistry) {
      return true;
    }
    final String? platformName = environment.defines[kTargetPlatform];
    TargetPlatform? targetPlatform;
    if (platformName != null) {
      try {
        targetPlatform = TargetPlatform.fromName(platformName);
      } on Exception {
        final String? extensionTargetOs = environment.defines[kExtensionTargetOs];
        final String? extensionPluginPlatformKey = environment.defines[kExtensionPluginPlatformKey];
        final bool hasExtensionPlatform =
            (extensionTargetOs != null && extensionTargetOs.trim().isNotEmpty) ||
            (extensionPluginPlatformKey != null && extensionPluginPlatformKey.trim().isNotEmpty);
        if (!hasExtensionPlatform) {
          rethrow;
        }
        // Custom extension target platforms are not part of the built-in
        // TargetPlatform enum and should still generate a Dart plugin
        // registrant when extension platform defines are present.
      }
    }
    // TODO(stuartmorgan): Investigate removing this check entirely; ideally the
    // source generation step shouldn't be platform dependent, and the generated
    // code should just do the right thing on every platform.
    // Failing that, consider throwing if `targetPlatform` isn't set and finding
    // all violations, as it's not consistently set here.
    return switch (targetPlatform?.os) {
      .fuchsia || .web => true,
      _ => false,
    };
  }

  @override
  List<Target> get dependencies => <Target>[];

  @override
  List<Source> get inputs => <Source>[
    const Source.pattern('{WORKSPACE_DIR}/.dart_tool/package_config.json'),
  ];

  @override
  String get name => 'gen_dart_plugin_registrant';

  @override
  List<Source> get outputs => <Source>[
    Source.fromProject((FlutterProject project) => project.dartPluginRegistrant, optional: true),
  ];
}

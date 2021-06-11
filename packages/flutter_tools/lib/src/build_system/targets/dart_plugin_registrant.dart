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

/// Generates a new `./dart_tool/flutter_build/generated_main.dart`
/// based on the current dependency map in `pubspec.lock`.
class DartPluginRegistrantTarget extends Target {
  /// Construct a [DartPluginRegistrantTarget].
  const DartPluginRegistrantTarget() : _project = null;

  /// Construct a [DartPluginRegistrantTarget].
  ///
  /// If `project` is unset, a [FlutterProject] based on environment is used.
  @visibleForTesting
  factory DartPluginRegistrantTarget.test(FlutterProject project) {
    return DartPluginRegistrantTarget._(project);
  }

  DartPluginRegistrantTarget._(this._project);

  final FlutterProject? _project;

  @override
  Future<void> build(Environment environment) async {
    assert(environment.generateDartPluginRegistry);
    final File packagesFile = environment.projectDir
        .childDirectory('.dart_tool')
        .childFile('package_config.json');
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      packagesFile,
      logger: environment.logger,
    );
    final String targetFile = environment.defines[kTargetFile] ??
        environment.fileSystem.path.join('lib', 'main.dart');
    final File mainFile = environment.fileSystem.file(targetFile);
    final Uri mainFileUri = mainFile.absolute.uri;
    final String mainUri = packageConfig.toPackageUri(mainFileUri)?.toString() ?? mainFileUri.toString();
    final File newMainDart = environment.projectDir
        .childDirectory('.dart_tool')
        .childDirectory('flutter_build')
        .childFile('generated_main.dart');
    await generateMainDartWithPluginRegistrant(
      _project ?? FlutterProject.fromDirectory(environment.projectDir),
      packageConfig,
      mainUri,
      newMainDart,
      mainFile,
      throwOnPluginPubspecError: false,
    );
  }

  @override
  bool canSkip(Environment environment) {
    if (!environment.generateDartPluginRegistry) {
      return true;
    }
    final String? platformName = environment.defines[kTargetPlatform];
    if (platformName == null) {
      return true;
    }
    final TargetPlatform? targetPlatform = getTargetPlatformForName(platformName);
    // TODO(egarciad): Support Android and iOS.
    // https://github.com/flutter/flutter/issues/52267
    return targetPlatform != TargetPlatform.darwin &&
           targetPlatform != TargetPlatform.linux_x64 &&
           targetPlatform != TargetPlatform.linux_arm64 &&
           targetPlatform != TargetPlatform.windows_x64 &&
           targetPlatform != TargetPlatform.windows_uwp_x64;
  }

  @override
  List<Target> get dependencies => <Target>[];

  @override
  List<Source> get inputs => <Source>[
    const Source.pattern('{PROJECT_DIR}/.dart_tool/package_config_subset'),
  ];

  @override
  String get name => 'gen_dart_plugin_registrant';

  @override
  List<Source> get outputs => <Source>[
    const Source.pattern(
      '{PROJECT_DIR}/.dart_tool/flutter_build/generated_main.dart',
      optional: true,
    ),
  ];
}

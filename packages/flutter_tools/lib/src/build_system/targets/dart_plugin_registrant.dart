// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:package_config/package_config.dart';

import '../../dart/package_map.dart';
import '../../base/file_system.dart';
import '../../plugins.dart';
import '../../project.dart';
import '../build_system.dart';
import 'common.dart';

/// Based on the current dependency map in `pubspec.lock`. Generated a new `generated_main.dart`
/// and replace the `./dart_tool/flutter_build/generated_main.dart`.
class DartPluginRegistrantTarget extends Target {

  const DartPluginRegistrantTarget();

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
    final String targetFile = environment.defines[kTargetFile] ?? environment.fileSystem.path.join('lib', 'main.dart');
    final File mainFile = environment.fileSystem.file(targetFile);
    final Uri mainFileUri = mainFile.uri;
    assert(packagesFile.path != null);
    final String mainUri = packageConfig.toPackageUri(mainFileUri)?.toString();
    final File newMainDart = environment.projectDir
      .childDirectory('.dart_tool')
      .childDirectory('flutter_build')
      .childFile('generated_main.dart');
    assert(newMainDart.existsSync());
    await generateMainDartWithPluginRegistrant(
      FlutterProject.current(),
      packageConfig,
      mainUri,
      newMainDart,
      mainFile,
      // TODO(egarciad): Turn this on when the plugins are fixed.
      throwOnPluginPubspecError: false,
    );
  }

  @override
  bool canSkip(Environment environment) {
    return !environment.generateDartPluginRegistry;
  }

  @override
  List<Target> get dependencies => <Target>[];

  @override
  List<Source> get inputs => <Source>[
    const Source.pattern('{PROJECT_DIR}/pubspec.lock'),
  ];

  @override
  String get name => 'gen_dart_plugin_registrant';

  @override
  List<Source> get outputs => <Source>[
    const Source.pattern('{PROJECT_DIR}/.dart_tool/flutter_build/generated_main.dart'),
  ];

}

// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../asset.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/process_manager.dart';
import '../../build_info.dart';
import '../../dart/package_map.dart';
import '../../globals.dart';
import '../../project.dart';
import '../build_system.dart';
import 'assets.dart';
import 'dart.dart';

/// Whether web builds should call the platform initialization logic.
const String kInitializePlatform = 'InitializePlatform';

/// Whether the application has web plugins.
const String kHasWebPlugins = 'HasWebPlugins';

/// An override for the dart2js build mode.
///
/// Valid values are O1 (lowest, profile default) to O4 (highest, release default).
const String kDart2jsOptimization = 'Dart2jsOptimization';

/// Generates an entrypoint for a web target.
class WebEntrypointTarget extends Target {
  const WebEntrypointTarget();

  @override
  String get name => 'web_entrypoint';

  @override
  List<Target> get dependencies => const <Target>[];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/web.dart'),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/main.dart'),
  ];

  @override
  Future<void> build(Environment environment) async {
    final String targetFile = environment.defines[kTargetFile];
    final bool shouldInitializePlatform = environment.defines[kInitializePlatform] == 'true';
    final bool hasPlugins = environment.defines[kHasWebPlugins] == 'true';
    final String import = fs.file(fs.path.absolute(targetFile)).uri.toString();

    String contents;
    if (hasPlugins) {
      contents = '''
import 'dart:ui' as ui;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'generated_plugin_registrant.dart';
import "$import" as entrypoint;

Future<void> main() async {
  registerPlugins(webPluginRegistry);
  if ($shouldInitializePlatform) {
    await ui.webOnlyInitializePlatform();
  }
  entrypoint.main();
}
''';
    } else {
      contents = '''
import 'dart:ui' as ui;

import "$import" as entrypoint;

Future<void> main() async {
  if ($shouldInitializePlatform) {
    await ui.webOnlyInitializePlatform();
  }
  entrypoint.main();
}
''';
    }
    environment.buildDir.childFile('main.dart')
      ..writeAsStringSync(contents);
  }
}

/// Compiles a web entrypoint with dart2js.
class Dart2JSTarget extends Target {
  const Dart2JSTarget();

  @override
  String get name => 'dart2js';

  @override
  List<Target> get dependencies => const <Target>[
    WebEntrypointTarget()
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/web.dart'),
    Source.artifact(Artifact.flutterWebSdk),
    Source.artifact(Artifact.dart2jsSnapshot),
    Source.artifact(Artifact.engineDartBinary),
    Source.artifact(Artifact.engineDartSdkPath),
    Source.pattern('{BUILD_DIR}/main.dart'),
    Source.pattern('{PROJECT_DIR}/.packages'),
    Source.function(listDartSources), // <- every dart file under {PROJECT_DIR}/lib and in .packages
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/main.dart.js'),
  ];

  @override
  Future<void> build(Environment environment) async {
    final String dart2jsOptimization = environment.defines[kDart2jsOptimization];
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final String specPath = fs.path.join(artifacts.getArtifactPath(Artifact.flutterWebSdk), 'libraries.json');
    final String packageFile = FlutterProject.fromDirectory(environment.projectDir).hasBuilders
      ? PackageMap.globalGeneratedPackagesPath
      : PackageMap.globalPackagesPath;
    final ProcessResult result = await processManager.run(<String>[
      artifacts.getArtifactPath(Artifact.engineDartBinary),
      artifacts.getArtifactPath(Artifact.dart2jsSnapshot),
      '--libraries-spec=$specPath',
      if (dart2jsOptimization != null)
        '-$dart2jsOptimization'
      else if (buildMode == BuildMode.profile)
        '-O1'
      else
        '-O4',
      '-o',
      environment.buildDir.childFile('main.dart.js').path,
      '--packages=$packageFile',
      if (buildMode == BuildMode.profile)
        '-Ddart.vm.profile=true'
      else
        '-Ddart.vm.product=true',
      environment.buildDir.childFile('main.dart').path,
    ]);
    if (result.exitCode != 0) {
      throw Exception(result.stdout + result.stderr);
    }
  }
}

/// Unpacks the dart2js compilation to a given output directory
class WebReleaseBundle extends Target {
  const WebReleaseBundle();

  @override
  String get name => 'web_release_bundle';

  @override
  List<Target> get dependencies => const <Target>[
    Dart2JSTarget(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/main.dart.js'),
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/web.dart'),
    Source.behavior(AssetOutputBehavior('assets')),
    Source.pattern('{PROJECT_DIR}/web/index.html'),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/main.dart.js'),
    Source.pattern('{OUTPUT_DIR}/assets/AssetManifest.json'),
    Source.pattern('{OUTPUT_DIR}/assets/FontManifest.json'),
    Source.pattern('{OUTPUT_DIR}/assets/LICENSE'),
    Source.pattern('{OUTPUT_DIR}/index.html'),
    Source.behavior(AssetOutputBehavior('assets'))
  ];

  @override
  Future<void> build(Environment environment) async {
    for (File outputFile in environment.buildDir.listSync(recursive: true).whereType<File>()) {
      if (!fs.path.basename(outputFile.path).contains('main.dart.js')) {
        continue;
      }
      outputFile.copySync(
        environment.outputDir.childFile(fs.path.basename(outputFile.path)).path
      );
    }
    environment.projectDir
      .childDirectory('web')
      .childFile('index.html')
      .copySync(fs.path.join(environment.outputDir.path, 'index.html'));
    final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
    await assetBundle.build();
    await copyAssets(assetBundle, environment, 'assets');
  }
}

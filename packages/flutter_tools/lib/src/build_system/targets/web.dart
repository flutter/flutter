// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../build_info.dart';
import '../../compile.dart';
import '../../dart/package_map.dart';
import '../../globals.dart' as globals;
import '../../project.dart';
import '../build_system.dart';
import '../depfile.dart';
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

/// Generates an entry point for a web target.
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
    final String importPath = globals.fs.path.absolute(targetFile);

    // Use the package uri mapper to find the correct package-scheme import path
    // for the user application. If the application has a mix of package-scheme
    // and relative imports for a library, then importing the entrypoint as a
    // file-scheme will cause said library to be recognized as two distinct
    // libraries. This can cause surprising behavior as types from that library
    // will be considered distinct from each other.
    final PackageUriMapper packageUriMapper = PackageUriMapper(
      importPath,
      PackageMap.globalPackagesPath,
      null,
      null,
    );

    // By construction, this will only be null if the .packages file does not
    // have an entry for the user's application or if the main file is
    // outside of the lib/ directory.
    final String mainImport = packageUriMapper.map(importPath)?.toString()
      ?? globals.fs.file(importPath).absolute.uri.toString();

    String contents;
    if (hasPlugins) {
      final String generatedPath = environment.projectDir
        .childDirectory('lib')
        .childFile('generated_plugin_registrant.dart')
        .absolute.path;
      final Uri generatedImport = packageUriMapper.map(generatedPath);
      contents = '''
import 'dart:ui' as ui;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import '$generatedImport';
import '$mainImport' as entrypoint;

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

import '$mainImport' as entrypoint;

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

/// Compiles a web entry point with dart2js.
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
    Source.artifact(Artifact.flutterWebSdk),
    Source.artifact(Artifact.dart2jsSnapshot),
    Source.artifact(Artifact.engineDartBinary),
    Source.pattern('{BUILD_DIR}/main.dart'),
    Source.pattern('{PROJECT_DIR}/.packages'),
  ];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<String> get depfiles => const <String>[
    'dart2js.d',
  ];

  @override
  Future<void> build(Environment environment) async {
    final String dart2jsOptimization = environment.defines[kDart2jsOptimization];
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final String specPath = globals.fs.path.join(globals.artifacts.getArtifactPath(Artifact.flutterWebSdk), 'libraries.json');
    final String packageFile = FlutterProject.fromDirectory(environment.projectDir).hasBuilders
      ? PackageMap.globalGeneratedPackagesPath
      : PackageMap.globalPackagesPath;
    final File outputFile = environment.buildDir.childFile('main.dart.js');

    final ProcessResult result = await globals.processManager.run(<String>[
      globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
      globals.artifacts.getArtifactPath(Artifact.dart2jsSnapshot),
      '--libraries-spec=$specPath',
      if (dart2jsOptimization != null)
        '-$dart2jsOptimization'
      else
        '-O4',
      if (buildMode == BuildMode.profile)
        '--no-minify',
      '-o',
      outputFile.path,
      '--packages=$packageFile',
      if (buildMode == BuildMode.profile)
        '-Ddart.vm.profile=true'
      else
        '-Ddart.vm.product=true',
      for (final String dartDefine in parseDartDefines(environment))
        '-D$dartDefine',
      environment.buildDir.childFile('main.dart').path,
    ]);
    if (result.exitCode != 0) {
      throw Exception(result.stdout + result.stderr);
    }
    final File dart2jsDeps = environment.buildDir
      .childFile('main.dart.js.deps');
    if (!dart2jsDeps.existsSync()) {
      globals.printError('Warning: dart2js did not produced expected deps list at '
        '${dart2jsDeps.path}');
      return;
    }
    final Depfile depfile = Depfile.parseDart2js(
      environment.buildDir.childFile('main.dart.js.deps'),
      outputFile,
    );
    depfile.writeToFile(environment.buildDir.childFile('dart2js.d'));
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
    Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
    Source.pattern('{PROJECT_DIR}/web/index.html'),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/main.dart.js'),
    Source.pattern('{OUTPUT_DIR}/index.html'),
  ];

  @override
  List<String> get depfiles => const <String>[
    'dart2js.d',
  ];

  @override
  Future<void> build(Environment environment) async {
    for (final File outputFile in environment.buildDir.listSync(recursive: true).whereType<File>()) {
      if (!globals.fs.path.basename(outputFile.path).contains('main.dart.js')) {
        continue;
      }
      outputFile.copySync(
        environment.outputDir.childFile(globals.fs.path.basename(outputFile.path)).path
      );
    }
    final Directory outputDirectory = environment.outputDir.childDirectory('assets');
    outputDirectory.createSync(recursive: true);
    environment.projectDir
      .childDirectory('web')
      .childFile('index.html')
      .copySync(globals.fs.path.join(environment.outputDir.path, 'index.html'));
    final Depfile depfile = await copyAssets(environment, environment.outputDir.childDirectory('assets'));
    depfile.writeToFile(environment.buildDir.childFile('flutter_assets.d'));
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:crypto/crypto.dart';
import 'package:package_config/package_config.dart';

import '../../artifacts.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../build_info.dart';
import '../../dart/package_map.dart';
import '../../globals.dart' as globals;
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

/// Whether to disable dynamic generation code to satisfy csp policies.
const String kCspMode = 'cspMode';

/// Generates an entry point for a web target.
// Keep this in sync with build_runner/resident_web_runner.dart
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
    final Uri importUri = environment.fileSystem.file(targetFile).absolute.uri;
    final PackageConfig packageConfig = await loadPackageConfigUri(
      environment.projectDir.childFile('.packages').absolute.uri,
      loader: (Uri uri) {
        final File file = environment.fileSystem.file(uri);
        if (!file.existsSync()) {
          return null;
        }
        return file.readAsBytes();
      }
    );

    // Use the PackageConfig to find the correct package-scheme import path
    // for the user application. If the application has a mix of package-scheme
    // and relative imports for a library, then importing the entrypoint as a
    // file-scheme will cause said library to be recognized as two distinct
    // libraries. This can cause surprising behavior as types from that library
    // will be considered distinct from each other.
    // By construction, this will only be null if the .packages file does not
    // have an entry for the user's application or if the main file is
    // outside of the lib/ directory.
    final String mainImport = packageConfig.toPackageUri(importUri)?.toString()
      ?? importUri.toString();

    String contents;
    if (hasPlugins) {
      final Uri generatedUri = environment.projectDir
        .childDirectory('lib')
        .childFile('generated_plugin_registrant.dart')
        .absolute
        .uri;
      final String generatedImport = packageConfig.toPackageUri(generatedUri)?.toString()
        ?? generatedUri.toString();
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
      .writeAsStringSync(contents);
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
    final bool csp = environment.defines[kCspMode] == 'true';
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final String specPath = globals.fs.path.join(globals.artifacts.getArtifactPath(Artifact.flutterWebSdk), 'libraries.json');
    final String packageFile = PackageMap.globalPackagesPath;
    final File outputKernel = environment.buildDir.childFile('app.dill');
    final File outputFile = environment.buildDir.childFile('main.dart.js');
    final List<String> dartDefines = parseDartDefines(environment);

    // Run the dart2js compilation in two stages, so that icon tree shaking can
    // parse the kernel file for web builds.
    final ProcessResult kernelResult = await globals.processManager.run(<String>[
      globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
      globals.artifacts.getArtifactPath(Artifact.dart2jsSnapshot),
      '--libraries-spec=$specPath',
      '-o',
      outputKernel.path,
      for (final String dartDefine in dartDefines)
        '-D$dartDefine',
      '--packages=$packageFile',
      '--cfe-only',
      environment.buildDir.childFile('main.dart').path,
    ]);
    if (kernelResult.exitCode != 0) {
      throw Exception(kernelResult.stdout + kernelResult.stderr);
    }
    final ProcessResult javaScriptResult = await globals.processManager.run(<String>[
      globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
      globals.artifacts.getArtifactPath(Artifact.dart2jsSnapshot),
      '--libraries-spec=$specPath',
      if (dart2jsOptimization != null)
        '-$dart2jsOptimization'
      else
        '-O4',
      if (buildMode == BuildMode.profile)
        '-Ddart.vm.profile=true'
      else
        '-Ddart.vm.product=true',
      for (final String dartDefine in dartDefines)
        '-D$dartDefine',
      if (buildMode == BuildMode.profile)
        '--no-minify',
      if (csp)
        '--csp',
      '-o',
      outputFile.path,
      environment.buildDir.childFile('app.dill').path,
    ]);
    if (javaScriptResult.exitCode != 0) {
      throw Exception(javaScriptResult.stdout + javaScriptResult.stderr);
    }
    final File dart2jsDeps = environment.buildDir
      .childFile('app.dill.deps');
    if (!dart2jsDeps.existsSync()) {
      globals.printError('Warning: dart2js did not produced expected deps list at '
        '${dart2jsDeps.path}');
      return;
    }
    final DepfileService depfileService = DepfileService(
      fileSystem: globals.fs,
      logger: globals.logger,
      platform: globals.platform,
    );
    final Depfile depfile = depfileService.parseDart2js(
      environment.buildDir.childFile('app.dill.deps'),
      outputFile,
    );
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile('dart2js.d'),
    );
  }
}

/// Unpacks the dart2js compilation and resources to a given output directory
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
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/main.dart.js'),
  ];

  @override
  List<String> get depfiles => const <String>[
    'dart2js.d',
    'flutter_assets.d',
    'web_resources.d',
  ];

  @override
  Future<void> build(Environment environment) async {
    for (final File outputFile in environment.buildDir.listSync(recursive: true).whereType<File>()) {
      final String basename = globals.fs.path.basename(outputFile.path);
      if (!basename.contains('main.dart.js')) {
        continue;
      }
      // Do not copy the deps file.
      if (basename.endsWith('.deps')) {
        continue;
      }
      outputFile.copySync(
        environment.outputDir.childFile(globals.fs.path.basename(outputFile.path)).path
      );
    }
    final Directory outputDirectory = environment.outputDir.childDirectory('assets');
    outputDirectory.createSync(recursive: true);
    final Depfile depfile = await copyAssets(environment, environment.outputDir.childDirectory('assets'));
    final DepfileService depfileService = DepfileService(
      fileSystem: globals.fs,
      logger: globals.logger,
      platform: globals.platform,
    );
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile('flutter_assets.d'),
    );

    final Directory webResources = environment.projectDir
      .childDirectory('web');
    final List<File> inputResourceFiles = webResources
      .listSync(recursive: true)
      .whereType<File>()
      .toList();

    // Copy other resource files out of web/ directory.
    final List<File> outputResourcesFiles = <File>[];
    for (final File inputFile in inputResourceFiles) {
      final File outputFile = globals.fs.file(globals.fs.path.join(
        environment.outputDir.path,
        globals.fs.path.relative(inputFile.path, from: webResources.path)));
      if (!outputFile.parent.existsSync()) {
        outputFile.parent.createSync(recursive: true);
      }
      inputFile.copySync(outputFile.path);
      outputResourcesFiles.add(outputFile);
    }
    final Depfile resourceFile = Depfile(inputResourceFiles, outputResourcesFiles);
    depfileService.writeToFile(
      resourceFile,
      environment.buildDir.childFile('web_resources.d'),
    );
  }
}

/// Generate a service worker for a web target.
class WebServiceWorker extends Target {
  const WebServiceWorker();

  @override
  String get name => 'web_service_worker';

  @override
  List<Target> get dependencies => const <Target>[
    Dart2JSTarget(),
    WebReleaseBundle(),
  ];

  @override
  List<String> get depfiles => const <String>[
    'service_worker.d',
  ];

  @override
  List<Source> get inputs => const <Source>[];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  Future<void> build(Environment environment) async {
    final List<File> contents = environment.outputDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((File file) => !file.path.endsWith('flutter_service_worker.js')
        && !globals.fs.path.basename(file.path).startsWith('.'))
      .toList();

    final Map<String, String> urlToHash = <String, String>{};
    for (final File file in contents) {
      // Do not force caching of source maps.
      if (file.path.endsWith('main.dart.js.map')) {
        continue;
      }
      final String url = globals.fs.path.toUri(
        globals.fs.path.relative(
          file.path,
          from: environment.outputDir.path),
        ).toString();
      final String hash = md5.convert(await file.readAsBytes()).toString();
      urlToHash[url] = hash;
      // Add an additional entry for the base URL.
      if (globals.fs.path.basename(url) == 'index.html') {
        urlToHash['/'] = hash;
      }
    }

    final File serviceWorkerFile = environment.outputDir
      .childFile('flutter_service_worker.js');
    final Depfile depfile = Depfile(contents, <File>[serviceWorkerFile]);
    final String serviceWorker = generateServiceWorker(urlToHash);
    serviceWorkerFile
      .writeAsStringSync(serviceWorker);
    final DepfileService depfileService = DepfileService(
      fileSystem: globals.fs,
      logger: globals.logger,
      platform: globals.platform,
    );
    depfileService.writeToFile(
      depfile,
      environment.buildDir.childFile('service_worker.d'),
    );
  }
}

/// Generate a service worker with an app-specific cache name a map of
/// resource files.
///
/// We embed file hashes directly into the worker so that the byte for byte
/// invalidation will automatically reactivate workers whenever a new
/// version is deployed.
// TODO(jonahwilliams): on re-activate, only evict stale assets.
String generateServiceWorker(Map<String, String> resources) {
  return '''
'use strict';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  ${resources.entries.map((MapEntry<String, String> entry) => '"${entry.key}": "${entry.value}"').join(",\n")}
};

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys().then(function (cacheName) {
      return caches.delete(cacheName);
    }).then(function (_) {
      return caches.open(CACHE_NAME);
    }).then(function (cache) {
      return cache.addAll(Object.keys(RESOURCES));
    })
  );
});

self.addEventListener('fetch', function (event) {
  event.respondWith(
    caches.match(event.request)
      .then(function (response) {
        if (response) {
          return response;
        }
        return fetch(event.request);
      })
  );
});
''';
}

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
import 'localizations.dart';

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
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      environment.projectDir.childFile('.packages'),
      logger: environment.logger,
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
    WebEntrypointTarget(),
    GenerateLocalizationsTarget(),
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
    final String specPath = globals.fs.path.join(
      globals.artifacts.getArtifactPath(Artifact.flutterWebSdk), 'libraries.json');
    final String packageFile = globalPackagesPath;
    final File outputKernel = environment.buildDir.childFile('app.dill');
    final File outputFile = environment.buildDir.childFile('main.dart.js');
    final List<String> dartDefines = decodeDartDefines(environment.defines, kDartDefines);
    final List<String> extraFrontEndOptions = decodeDartDefines(environment.defines, kExtraFrontEndOptions);

    // Run the dart2js compilation in two stages, so that icon tree shaking can
    // parse the kernel file for web builds.
    final ProcessResult kernelResult = await globals.processManager.run(<String>[
      globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
      '--disable-dart-dev',
      globals.artifacts.getArtifactPath(Artifact.dart2jsSnapshot),
      '--libraries-spec=$specPath',
      ...?extraFrontEndOptions,
      '-o',
      outputKernel.path,
      '--packages=$packageFile',
      if (buildMode == BuildMode.profile)
        '-Ddart.vm.profile=true'
      else
        '-Ddart.vm.product=true',
      for (final String dartDefine in dartDefines)
        '-D$dartDefine',
      '--cfe-only',
      environment.buildDir.childFile('main.dart').path,
    ]);
    if (kernelResult.exitCode != 0) {
      throw Exception(kernelResult.stdout + kernelResult.stderr);
    }
    final ProcessResult javaScriptResult = await globals.processManager.run(<String>[
      globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
      '--disable-dart-dev',
      globals.artifacts.getArtifactPath(Artifact.dart2jsSnapshot),
      '--libraries-spec=$specPath',
      ...?extraFrontEndOptions,
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
      if (file.path.endsWith('main.dart.js.map') ||
        file.path.endsWith('.part.js.map')) {
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
    final String serviceWorker = generateServiceWorker(urlToHash, <String>[
      '/',
      'main.dart.js',
      'index.html',
      'assets/LICENSE',
      if (urlToHash.containsKey('assets/AssetManifest.json'))
        'assets/AssetManifest.json',
      if (urlToHash.containsKey('assets/FontManifest.json'))
        'assets/FontManifest.json',
    ]);
    serviceWorkerFile
      .writeAsStringSync(serviceWorker);
    final DepfileService depfileService = DepfileService(
      fileSystem: globals.fs,
      logger: globals.logger,
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
/// The tool embeds file hashes directly into the worker so that the byte for byte
/// invalidation will automatically reactivate workers whenever a new
/// version is deployed.
String generateServiceWorker(Map<String, String> resources, List<String> coreBundle) {
  return '''
'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  ${resources.entries.map((MapEntry<String, String> entry) => '"${entry.key}": "${entry.value}"').join(",\n")}
};

// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  ${coreBundle.map((String file) => '"$file"').join(',\n')}];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      // Provide a no-cache param to ensure the latest version is downloaded.
      return cache.addAll(CORE.map((value) => new Request(value, {'cache': 'no-cache'})));
    })
  );
});

// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');

      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        return;
      }

      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});

// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#')) {
    key = '/';
  }
  // If the URL is not the the RESOURCE list, skip the cache.
  if (!RESOURCES[key]) {
    return event.respondWith(fetch(event.request));
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache. Ensure the resources are not cached
        // by the browser for longer than the service worker expects.
        var modifiedRequest = new Request(event.request, {'cache': 'no-cache'});
        return response || fetch(modifiedRequest).then((response) => {
          cache.put(event.request, response.clone());
          return response;
        });
      })
    })
  );
});

self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.message == 'skipWaiting') {
    return self.skipWaiting();
  }

  if (event.message = 'downloadOffline') {
    downloadOffline();
  }
});

// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey in Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.add(resourceKey);
    }
  }
  return Cache.addAll(resources);
}
''';
}

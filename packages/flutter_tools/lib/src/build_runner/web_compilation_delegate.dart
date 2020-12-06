// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:build_daemon/client.dart';
import 'package:build_daemon/constants.dart' as daemon;
import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:build_daemon/data/server_log.dart';
import 'package:path/path.dart' as path; // ignore: package_path_import

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../globals.dart' as globals;
import '../platform_plugins.dart';
import '../plugins.dart';
import '../project.dart';
import '../web/compile.dart';

/// A build_runner specific implementation of the [WebCompilationProxy].
class BuildRunnerWebCompilationProxy extends WebCompilationProxy {
  BuildRunnerWebCompilationProxy();

  @override
  Future<bool> initialize({
    Directory projectDirectory,
    String testOutputDir,
    List<String> testFiles,
    BuildMode mode,
    String projectName,
    bool initializePlatform,
  }) async {
    // Create the .dart_tool directory if it doesn't exist.
    projectDirectory
      .childDirectory('.dart_tool')
      .createSync();
    final FlutterProject flutterProject = FlutterProject.fromDirectory(projectDirectory);
    final bool hasWebPlugins = (await findPlugins(flutterProject))
      .any((Plugin p) => p.platforms.containsKey(WebPlugin.kConfigKey));
    final BuildDaemonClient client = await const BuildDaemonCreator().startBuildDaemon(
      projectDirectory.path,
      release: mode == BuildMode.release,
      profile: mode == BuildMode.profile,
      hasPlugins: hasWebPlugins,
      initializePlatform: initializePlatform,
      testTargets: WebTestTargetManifest(
        testFiles
          .map<String>((String absolutePath) {
            final String relativePath = path.relative(absolutePath, from: projectDirectory.path);
            return '${path.withoutExtension(relativePath)}.*';
          })
          .toList(),
      ),
    );
    client.startBuild();
    bool success = true;
    await for (final BuildResults results in client.buildResults) {
      final BuildResult result = results.results.firstWhere((BuildResult result) {
        return result.target == 'web';
      }, orElse: () {
        // Assume build failed if we lack any results.
        return DefaultBuildResult((DefaultBuildResultBuilder b) => b.status == BuildStatus.failed);
      });
      if (result.status == BuildStatus.failed) {
        success = false;
        break;
      }
      if (result.status == BuildStatus.succeeded) {
        break;
      }
    }
    if (!success || testOutputDir == null) {
      return success;
    }
    final Directory rootDirectory = projectDirectory
      .childDirectory('.dart_tool')
      .childDirectory('build')
      .childDirectory('flutter_web');

    final Iterable<Directory> childDirectories = rootDirectory
      .listSync()
      .whereType<Directory>();
    for (final Directory childDirectory in childDirectories) {
      final String path = globals.fs.path.join(
        testOutputDir,
        'packages',
        globals.fs.path.basename(childDirectory.path),
      );
      globals.fsUtils.copyDirectorySync(
        childDirectory.childDirectory('lib'),
        globals.fs.directory(path),
      );
    }
    final Directory outputDirectory = rootDirectory
      .childDirectory(projectName)
      .childDirectory('test');
    globals.fsUtils.copyDirectorySync(
      outputDirectory,
      globals.fs.directory(globals.fs.path.join(testOutputDir)),
    );
    return success;
  }
}

class WebTestTargetManifest {
  WebTestTargetManifest(this.buildFilters);

  WebTestTargetManifest.all() : buildFilters = null;

  final List<String> buildFilters;

  bool get hasBuildFilters => buildFilters != null && buildFilters.isNotEmpty;
}

/// A testable interface for starting a build daemon.
class BuildDaemonCreator {
  const BuildDaemonCreator();

  // TODO(jonahwilliams): find a way to get build checks working for flutter for web.
  static const String _ignoredLine1 = 'Warning: Interpreting this as package URI';
  static const String _ignoredLine2 = 'build_script.dart was not found in the asset graph, incremental builds will not work';
  static const String _ignoredLine3 = 'have your dependencies specified fully in your pubspec.yaml';

  /// Start a build daemon and register the web targets.
  ///
  /// [initializePlatform] controls whether we should invoke [webOnlyInitializePlatform].
  Future<BuildDaemonClient> startBuildDaemon(String workingDirectory, {
    bool release = false,
    bool profile = false,
    bool hasPlugins = false,
    bool initializePlatform = true,
    WebTestTargetManifest testTargets,
  }) async {
    try {
      final BuildDaemonClient client = await _connectClient(
        workingDirectory,
        release: release,
        profile: profile,
        hasPlugins: hasPlugins,
        initializePlatform: initializePlatform,
        testTargets: testTargets,
      );
      _registerBuildTargets(client, testTargets);
      return client;
    } on OptionsSkew {
      throwToolExit(
        'Incompatible options with current running build daemon.\n\n'
        'Please stop other flutter_tool instances running in this directory '
        'before starting a new instance with these options.'
      );
    }
    return null;
  }

  void _registerBuildTargets(
    BuildDaemonClient client,
    WebTestTargetManifest testTargets,
  ) {
    final OutputLocation outputLocation = OutputLocation((OutputLocationBuilder b) => b
      ..output = ''
      ..useSymlinks = true
      ..hoist = false);
    client.registerBuildTarget(DefaultBuildTarget((DefaultBuildTargetBuilder b) => b
      ..target = 'web'
      ..outputLocation = outputLocation?.toBuilder()));
    if (testTargets != null) {
      client.registerBuildTarget(DefaultBuildTarget((DefaultBuildTargetBuilder b) {
        b.target = 'test';
        b.outputLocation = outputLocation?.toBuilder();
        if (testTargets.hasBuildFilters) {
          b.buildFilters.addAll(testTargets.buildFilters);
        }
      }));
    }
  }

  Future<BuildDaemonClient> _connectClient(
    String workingDirectory, {
    bool release,
    bool profile,
    bool hasPlugins,
    bool initializePlatform,
    WebTestTargetManifest testTargets,
  }) async {
    // The build script is stored in an auxiliary package to reduce
    // dependencies of the main tool.
    final String buildScriptPackages = globals.fs.path.join(
      Cache.flutterRoot,
      'packages',
      '_flutter_web_build_script',
      '.packages',
    );
    final String buildScript = globals.fs.path.join(
      Cache.flutterRoot,
      'packages',
      '_flutter_web_build_script',
      'lib',
      'build_script.dart',
    );
    if (!globals.fs.isFileSync(buildScript)) {
      throwToolExit('Expected a file $buildScript to exist in the Flutter SDK.');
    }
    // If we're missing the .packages file, perform a pub get.
    if (!globals.fs.isFileSync(buildScriptPackages)) {
      await pub.get(
        context: PubContext.pubGet,
        directory: globals.fs.file(buildScriptPackages).parent.path,
        generateSyntheticPackage: false,
      );
    }
    final String flutterWebSdk = globals.artifacts.getArtifactPath(Artifact.flutterWebSdk);

    // On Windows we need to call the snapshot directly otherwise
    // the process will start in a disjoint cmd without access to
    // STDIO.
    final List<String> args = <String>[
      globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
      '--disable-dart-dev',
      '--packages=$buildScriptPackages',
      buildScript,
      'daemon',
      '--skip-build-script-check',
      '--define', 'flutter_tools:ddc=flutterWebSdk=$flutterWebSdk',
      '--define', 'flutter_tools:entrypoint=flutterWebSdk=$flutterWebSdk',
      '--define', 'flutter_tools:entrypoint=release=$release',
      '--define', 'flutter_tools:entrypoint=profile=$profile',
      '--define', 'flutter_tools:shell=flutterWebSdk=$flutterWebSdk',
      '--define', 'flutter_tools:shell=hasPlugins=$hasPlugins',
      '--define', 'flutter_tools:shell=initializePlatform=$initializePlatform',
      // The following will cause build runner to only build tests that were requested.
      if (testTargets != null && testTargets.hasBuildFilters)
        for (final String buildFilter in testTargets.buildFilters)
          '--build-filter=$buildFilter',
    ];

    return BuildDaemonClient.connect(
      workingDirectory,
      args,
      logHandler: (ServerLog serverLog) {
        switch (serverLog.level) {
          case Level.SEVERE:
          case Level.SHOUT:
            // Ignore certain non-actionable messages on startup.
            if (serverLog.message.contains(_ignoredLine1) ||
                serverLog.message.contains(_ignoredLine2) ||
                serverLog.message.contains(_ignoredLine3)) {
              return;
            }
            globals.printError(serverLog.message);
            if (serverLog.error != null) {
              globals.printError(serverLog.error);
            }
            if (serverLog.stackTrace != null) {
              globals.printTrace(serverLog.stackTrace);
            }
            break;
          default:
            if (serverLog.message.contains('Skipping compiling')) {
              globals.printError(serverLog.message);
            } else {
              globals.printTrace(serverLog.message);
            }
        }
      },
      buildMode: daemon.BuildMode.Manual,
    );
  }
}

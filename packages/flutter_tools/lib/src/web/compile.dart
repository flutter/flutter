// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../asset.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../globals.dart';
import '../project.dart';
import '../reporting/reporting.dart';

/// The [WebCompilationProxy] instance.
WebCompilationProxy get webCompilationProxy => context.get<WebCompilationProxy>();

Future<void> buildWeb(FlutterProject flutterProject, String target, BuildInfo buildInfo) async {
  if (!flutterProject.web.existsSync()) {
    throwToolExit('Missing index.html.');
  }
  final Status status = logger.startProgress('Compiling $target for the Web...', timeout: null);
  final Stopwatch sw = Stopwatch()..start();
  final Directory outputDir = fs.directory(getWebBuildDirectory())
    ..createSync(recursive: true);
  bool result;
  try {
    result = await webCompilationProxy.initialize(
      projectDirectory: FlutterProject.current().directory,
      mode: buildInfo.mode,
      projectName: flutterProject.manifest.appName,
    );
    if (result) {
      // Places assets adjacent to the web stuff.
      final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
      await assetBundle.build();
      await writeBundle(fs.directory(fs.path.join(outputDir.path, 'assets')), assetBundle.entries);

      // Copy results to output directory.
      final String outputPath = fs.path.join(
        flutterProject.dartTool.path,
        'build',
        'flutter_web',
        flutterProject.manifest.appName,
        '${fs.path.withoutExtension(target)}_web_entrypoint.dart.js'
      );
      fs.file(outputPath).copySync(fs.path.join(outputDir.path, 'main.dart.js'));
      fs.file('$outputPath.map').copySync(fs.path.join(outputDir.path, 'main.dart.js.map'));
      flutterProject.web.indexFile.copySync(fs.path.join(outputDir.path, 'index.html'));
    }
  } catch (err) {
    printError(err.toString());
    result = false;
  } finally {
    status.stop();
  }
  if (result == false) {
    throwToolExit('Failed to compile $target for the Web.');
  }
  String buildName = 'ddc';
  if (buildInfo.isRelease) {
    buildName = 'dart2js';
  }
  flutterUsage.sendTiming('build', buildName, Duration(milliseconds: sw.elapsedMilliseconds));
}

/// An indirection on web compilation.
///
/// Avoids issues with syncing build_runner_core to other repos.
class WebCompilationProxy {
  const WebCompilationProxy();

  /// Initialize the web compiler from the `projectDirectory`.
  ///
  /// Returns whether or not the build was successful.
  ///
  /// `release` controls whether we build the bundle for dartdevc or only
  /// the entrypoints for dart2js to later take over.
  Future<bool> initialize({
    @required Directory projectDirectory,
    @required String projectName,
    String testOutputDir,
    BuildMode mode,
  }) async {
    throw UnimplementedError();
  }
}

// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../convert.dart';
import '../globals.dart';

/// The [WebCompiler] instance.
WebCompiler get webCompiler => context.get<WebCompiler>();

/// A wrapper around dart2js for web compilation.
class WebCompiler {
  const WebCompiler();

  /// Compile `target` using dart2js.
  ///
  /// `minify` controls whether minifaction of the source is enabled. Defaults to `true`.
  /// `enabledAssertions` controls whether assertions are enabled. Defaults to `false`.
  Future<int> compile({@required String target, bool minify = true, bool enabledAssertions = false}) async {
    final String engineDartPath = artifacts.getArtifactPath(Artifact.engineDartBinary);
    final String dart2jsPath = artifacts.getArtifactPath(Artifact.dart2jsSnapshot);
    final String flutterWebSdkPath = artifacts.getArtifactPath(Artifact.flutterWebSdk);
    final String librariesPath = fs.path.join(flutterWebSdkPath, 'libraries.json');
    final Directory outputDir = fs.directory(getWebBuildDirectory());
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
    final String outputPath = fs.path.join(outputDir.path, 'main.dart.js');
    if (!processManager.canRun(engineDartPath)) {
      throwToolExit('Unable to find Dart binary at $engineDartPath');
    }
    /// Compile Dart to JavaScript.
    final List<String> command = <String>[
      engineDartPath,
      dart2jsPath,
      target,
      '-o',
      '$outputPath',
      '--libraries-spec=$librariesPath',
    ];
    if (minify) {
      command.add('-m');
    }
    if (enabledAssertions) {
      command.add('--enable-asserts');
    }
    printTrace(command.join(' '));
    final Process result = await processManager.start(command);
    result
        .stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(printStatus);
    result
        .stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(printError);
    return result.exitCode;
  }
}

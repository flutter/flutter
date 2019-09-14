// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../convert.dart';
import '../globals.dart';
import '../project.dart';

import 'fuchsia_sdk.dart';

/// This is a simple wrapper around the custom kernel compiler from the Fuchsia
/// SDK.
class FuchsiaKernelCompiler {
  /// Compiles the [fuchsiaProject] with entrypoint [target] to a collection of
  /// .dilp files (consisting of the app split along package: boundaries, but
  /// the Flutter tool should make no use of that fact), and a manifest that
  /// refers to them.
  Future<void> build({
    @required FuchsiaProject fuchsiaProject,
    @required String target, // E.g., lib/main.dart
    BuildInfo buildInfo = BuildInfo.debug,
  }) async {
    // TODO(zra): Use filesystem root and scheme information from buildInfo.
    if (fuchsiaArtifacts.kernelCompiler == null) {
      throwToolExit('Fuchisa kernel compiler not found');
    }
    const String multiRootScheme = 'main-root';
    final String packagesFile = fuchsiaProject.project.packagesFile.path;
    final String outDir = getFuchsiaBuildDirectory();
    final String appName = fuchsiaProject.project.manifest.appName;
    final String fsRoot = fuchsiaProject.project.directory.path;
    final String relativePackagesFile =
        fs.path.relative(packagesFile, from: fsRoot);
    final String manifestPath = fs.path.join(outDir, '$appName.dilpmanifest');
    List<String> flags = <String>[
      '--target', 'flutter_runner',
      '--platform', fuchsiaArtifacts.platformKernelDill.path,
      '--filesystem-scheme', 'main-root',
      '--filesystem-root', fsRoot,
      '--packages', '$multiRootScheme:///$relativePackagesFile',
      '--output', fs.path.join(outDir, '$appName.dil'),
      '--no-link-platform',
      '--split-output-by-packages',
      '--manifest', manifestPath,
      '--component-name', appName,
    ];

    if (buildInfo.isDebug) {
      flags += <String>[
        '--embed-sources',
      ];
    } else if (buildInfo.isProfile) {
      flags += <String>[
        '--no-embed-sources',
        '-Ddart.vm.profile=true',
        '--gen-bytecode',
        '--drop-ast',
      ];
    } else if (buildInfo.isRelease) {
      flags += <String>[
        '--no-embed-sources',
        '-Ddart.vm.release=true',
        '--gen-bytecode',
        '--drop-ast',
      ];
    } else {
      throwToolExit('Expected build type to be debug, profile, or release');
    }

    flags += <String>[
      '$multiRootScheme:///$target',
    ];

    final List<String> command = <String>[
      artifacts.getArtifactPath(Artifact.engineDartBinary),
      fuchsiaArtifacts.kernelCompiler.path,
      ...flags,
    ];
    final Process process = await processUtils.start(command);
    final Status status = logger.startProgress(
      'Building Fuchsia application...',
      timeout: null,
    );
    int result;
    try {
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(printError);
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(printTrace);
      result = await process.exitCode;
    } finally {
      status.cancel();
    }
    if (result != 0) {
      throwToolExit('Build process failed');
    }
  }
}

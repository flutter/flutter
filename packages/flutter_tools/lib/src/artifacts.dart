// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'build_info.dart';
import 'globals.dart';

enum ArtifactType {
  snapshot,
  shell,
  mojo,
  androidClassesJar,
  androidIcuData,
  androidKeystore,
  androidLibSkyShell,
}

class Artifact {
  const Artifact._({
    this.name,
    this.fileName,
    this.type,
    this.hostPlatform,
    this.targetPlatform
  });

  final String name;
  final String fileName;
  final ArtifactType type;
  final HostPlatform hostPlatform;
  final TargetPlatform targetPlatform;

  String get platform {
    if (targetPlatform != null)
      return getNameForTargetPlatform(targetPlatform);
    if (hostPlatform != null)
      return getNameForHostPlatform(hostPlatform);
    assert(false);
    return null;
  }
}

class ArtifactStore {
  static const List<Artifact> knownArtifacts = const <Artifact>[
    // tester
    const Artifact._(
      name: 'Flutter Tester',
      fileName: 'sky_shell',
      type: ArtifactType.shell,
      targetPlatform: TargetPlatform.linux_x64
    ),

    // snapshotters
    const Artifact._(
      name: 'Sky Snapshot',
      fileName: 'sky_snapshot',
      type: ArtifactType.snapshot,
      hostPlatform: HostPlatform.linux_x64
    ),
    const Artifact._(
      name: 'Sky Snapshot',
      fileName: 'sky_snapshot',
      type: ArtifactType.snapshot,
      hostPlatform: HostPlatform.darwin_x64
    ),

    // mojo
    const Artifact._(
      name: 'Flutter for Mojo',
      fileName: 'flutter.mojo',
      type: ArtifactType.mojo,
      targetPlatform: TargetPlatform.android_arm
    ),
    const Artifact._(
      name: 'Flutter for Mojo',
      fileName: 'flutter.mojo',
      type: ArtifactType.mojo,
      targetPlatform: TargetPlatform.linux_x64
    ),

    // android-arm
    const Artifact._(
      name: 'Compiled Java code',
      fileName: 'classes.dex.jar',
      type: ArtifactType.androidClassesJar,
      targetPlatform: TargetPlatform.android_arm
    ),
    const Artifact._(
      name: 'ICU data table',
      fileName: 'icudtl.dat',
      type: ArtifactType.androidIcuData,
      targetPlatform: TargetPlatform.android_arm
    ),
    const Artifact._(
      name: 'Key Store',
      fileName: 'chromium-debug.keystore',
      type: ArtifactType.androidKeystore,
      targetPlatform: TargetPlatform.android_arm
    ),
    const Artifact._(
      name: 'Compiled C++ code',
      fileName: 'libsky_shell.so',
      type: ArtifactType.androidLibSkyShell,
      targetPlatform: TargetPlatform.android_arm
    ),

    // android-x86
    const Artifact._(
      name: 'Compiled Java code',
      fileName: 'classes.dex.jar',
      type: ArtifactType.androidClassesJar,
      targetPlatform: TargetPlatform.android_x64
    ),
    const Artifact._(
      name: 'ICU data table',
      fileName: 'icudtl.dat',
      type: ArtifactType.androidIcuData,
      targetPlatform: TargetPlatform.android_x64
    ),
    const Artifact._(
      name: 'Key Store',
      fileName: 'chromium-debug.keystore',
      type: ArtifactType.androidKeystore,
      targetPlatform: TargetPlatform.android_x64
    ),
    const Artifact._(
      name: 'Compiled C++ code',
      fileName: 'libsky_shell.so',
      type: ArtifactType.androidLibSkyShell,
      targetPlatform: TargetPlatform.android_x64
    ),
  ];

  static Artifact getArtifact({
    ArtifactType type,
    HostPlatform hostPlatform,
    TargetPlatform targetPlatform
  }) {
    for (Artifact artifact in ArtifactStore.knownArtifacts) {
      if (type != null &&
          type != artifact.type)
        continue;
      if (hostPlatform != null &&
          artifact.hostPlatform != null &&
          hostPlatform != artifact.hostPlatform)
        continue;
      if (targetPlatform != null &&
          artifact.targetPlatform != null &&
          targetPlatform != artifact.targetPlatform)
        continue;
      return artifact;
    }
    return null;
  }

  // Initialized by FlutterCommandRunner on startup.
  static String flutterRoot;

  static String _engineRevision;

  static String get engineRevision {
    if (_engineRevision == null) {
      File revisionFile = new File(path.join(flutterRoot, 'bin', 'cache', 'engine.version'));
      if (revisionFile.existsSync())
        _engineRevision = revisionFile.readAsStringSync().trim();
    }
    return _engineRevision;
  }

  static Directory _getBaseCacheDir() {
    return new Directory(path.join(flutterRoot, 'bin', 'cache', 'artifacts'));
  }

  // TODO(devoncarew): There are 5 call-sites of this (run_mojo, build_apk, the
  // test command, toolchain, setup_xcodeproj); move them over to using
  // something from `cache.dart`.
  static String getPath(Artifact artifact) {
    File cachedFile = new File(
      path.join(_getBaseCacheDir().path, 'engine', artifact.platform, artifact.fileName)
    );

    if (!cachedFile.existsSync()) {
      printError('File not found in the platform artifacts: ${cachedFile.path}');
      return null;
    } else {
      return cachedFile.path;
    }
  }
}

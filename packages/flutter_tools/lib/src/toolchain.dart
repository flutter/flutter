// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base/context.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'cache.dart';
import 'globals.dart';

enum HostTool {
  SkySnapshot,
  SkyShell,
}

const Map<HostTool, String> _kHostToolFileName = const <HostTool, String>{
  HostTool.SkySnapshot: 'sky_snapshot',
  HostTool.SkyShell: 'sky_shell',
};

/// A ToolConfiguration can return the tools directory for the current host platform
/// and the engine artifact directory for a given target platform. It is configurable
/// via command-line arguments in order to support local engine builds.
class ToolConfiguration {
  ToolConfiguration();

  Cache get cache => context[Cache];

  static ToolConfiguration get instance => context[ToolConfiguration];

  /// Override using the artifacts from the cache directory (--engine-src-path).
  String engineSrcPath;

  /// Path to a local engine build acting as a source for artifacts (--local-engine).
  String engineBuildPath;

  bool get isLocalEngine => engineSrcPath != null;

  /// Return the directory that contains engine artifacts for the given targets.
  /// This directory might contain artifacts like `libsky_shell.so`.
  Directory getEngineArtifactsDirectory(TargetPlatform platform, BuildMode mode) {
    Directory dir = _getEngineArtifactsDirectory(platform, mode);
    if (dir != null)
      printTrace('Using engine artifacts dir: ${dir.path}');
    return dir;
  }

  Directory _getEngineArtifactsDirectory(TargetPlatform platform, BuildMode mode) {
    if (engineBuildPath != null) {
      return fs.directory(engineBuildPath);
    } else {
      String suffix = mode != BuildMode.debug ? '-${getModeName(mode)}' : '';

      // Create something like `android-arm` or `android-arm-release`.
      String dirName = getNameForTargetPlatform(platform) + suffix;
      Directory engineDir = cache.getArtifactDirectory('engine');
      return fs.directory(path.join(engineDir.path, dirName));
    }
  }

  String getHostToolPath(HostTool tool) {
    if (engineBuildPath == null) {
      return path.join(cache.getArtifactDirectory('engine').path,
                       getNameForHostPlatform(getCurrentHostPlatform()),
                       _kHostToolFileName[tool]);
    }

    if (tool == HostTool.SkySnapshot) {
      String clangPath = path.join(engineBuildPath, 'clang_x64', 'sky_snapshot');
      if (fs.isFileSync(clangPath))
        return clangPath;
      return path.join(engineBuildPath, 'sky_snapshot');
    } else if (tool == HostTool.SkyShell) {
      if (getCurrentHostPlatform() == HostPlatform.linux_x64) {
        return path.join(engineBuildPath, 'sky_shell');
      } else if (getCurrentHostPlatform() == HostPlatform.darwin_x64) {
        return path.join(engineBuildPath, 'SkyShell.app', 'Contents', 'MacOS', 'SkyShell');
      }
    }

    throw 'Unexpected host tool: $tool';
  }
}

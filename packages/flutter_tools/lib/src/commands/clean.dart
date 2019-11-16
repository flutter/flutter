// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../globals.dart';
import '../ios/xcodeproj.dart';
import '../macos/xcode.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class CleanCommand extends FlutterCommand {
  CleanCommand() {
    requiresPubspecYaml();
  }

  @override
  final String name = 'clean';

  @override
  final String description = 'Delete the build/ and .dart_tool/ directories.';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    // Clean Xcode to remove intermediate DerivedData artifacts.
    // Do this before removing ephemeral directory, which would delete the xcworkspace.
    final FlutterProject flutterProject = FlutterProject.current();
    if (xcode.isInstalledAndMeetsVersionCheck) {
      await _cleanXcode(flutterProject.ios);
      await _cleanXcode(flutterProject.macos);
    }

    final Directory buildDir = fs.directory(getBuildDirectory());
    deleteFile(buildDir);

    deleteFile(flutterProject.dartTool);

    final Directory androidEphemeralDirectory = flutterProject.android.ephemeralDirectory;
    deleteFile(androidEphemeralDirectory);

    final Directory iosEphemeralDirectory = flutterProject.ios.ephemeralDirectory;
    deleteFile(iosEphemeralDirectory);

    final Directory linuxEphemeralDirectory = flutterProject.linux.ephemeralDirectory;
    deleteFile(linuxEphemeralDirectory);

    final Directory macosEphemeralDirectory = flutterProject.macos.ephemeralDirectory;
    deleteFile(macosEphemeralDirectory);

    final Directory windowsEphemeralDirectory = flutterProject.windows.ephemeralDirectory;
    deleteFile(windowsEphemeralDirectory);

    return const FlutterCommandResult(ExitStatus.success);
  }

  Future<void> _cleanXcode(XcodeBasedProject xcodeProject) async {
    if (!xcodeProject.existsSync()) {
      return;
    }
    final Status xcodeStatus = logger.startProgress('Cleaning Xcode workspace...', timeout: timeoutConfiguration.slowOperation);
    try {
      final Directory xcodeWorkspace = xcodeProject.xcodeWorkspace;
      final XcodeProjectInfo projectInfo = await xcodeProjectInterpreter.getInfo(xcodeWorkspace.parent.path);
      for (String scheme in projectInfo.schemes) {
        xcodeProjectInterpreter.cleanWorkspace(xcodeWorkspace.path, scheme);
      }
    } catch (error) {
      printTrace('Could not clean Xcode workspace: $error');
    } finally {
      xcodeStatus?.stop();
    }
  }

  @visibleForTesting
  void deleteFile(FileSystemEntity file) {
    // This will throw a FileSystemException if the directory is missing permissions.
    try {
      if (!file.existsSync()) {
        return;
      }
    } on FileSystemException catch (err) {
      printError('Cannot clean ${file.path}.\n$err');
      return;
    }
    final Status deletionStatus = logger.startProgress('Deleting ${file.basename}...', timeout: timeoutConfiguration.fastOperation);
    try {
      file.deleteSync(recursive: true);
    } on FileSystemException catch (error) {
      final String path = file.path;
      if (platform.isWindows) {
        printError(
          'Failed to remove $path. '
            'A program may still be using a file in the directory or the directory itself. '
            'To find and stop such a program, see: '
            'https://superuser.com/questions/1333118/cant-delete-empty-folder-because-it-is-used');
      } else {
        printError('Failed to remove $path: $error');
      }
    } finally {
      deletionStatus.stop();
    }
  }
}

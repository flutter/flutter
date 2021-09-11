// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

import 'base/common.dart';
import 'base/file_system.dart';
import 'base/utils.dart';
import 'cmake.dart';
import 'platform_plugins.dart';
import 'project.dart';

/// Represents a CMake-based sub-project.
///
/// This defines interfaces common to Windows and Linux projects.
abstract class CmakeBasedProject {
  /// The parent of this project.
  FlutterProject get parent;

  /// Whether the subproject (either Windows or Linux) exists in the Flutter project.
  bool existsSync();

  /// The native project CMake specification.
  File get cmakeFile;

  /// Contains definitions for the Flutter library and the tool.
  File get managedCmakeFile;

  /// Contains definitions for FLUTTER_ROOT, LOCAL_ENGINE, and more flags for
  /// the build.
  File get generatedCmakeConfigFile;

  /// Included CMake with rules and variables for plugin builds.
  File get generatedPluginCmakeFile;

  /// The directory to write plugin symlinks.
  Directory get pluginSymlinkDirectory;
}

/// The Windows sub project.
class WindowsProject extends FlutterProjectPlatform implements CmakeBasedProject {
  WindowsProject.fromFlutter(this.parent);

  @override
  final FlutterProject parent;

  @override
  String get pluginConfigKey => WindowsPlugin.kConfigKey;

  String get _childDirectory => 'windows';

  @override
  bool existsSync() => _editableDirectory.existsSync() && cmakeFile.existsSync();

  @override
  File get cmakeFile => _editableDirectory.childFile('CMakeLists.txt');

  @override
  File get managedCmakeFile => managedDirectory.childFile('CMakeLists.txt');

  @override
  File get generatedCmakeConfigFile => ephemeralDirectory.childFile('generated_config.cmake');

  @override
  File get generatedPluginCmakeFile => managedDirectory.childFile('generated_plugins.cmake');

  @override
  Directory get pluginSymlinkDirectory => ephemeralDirectory.childDirectory('.plugin_symlinks');

  Directory get _editableDirectory => parent.directory.childDirectory(_childDirectory);

  /// The directory in the project that is managed by Flutter. As much as
  /// possible, files that are edited by Flutter tooling after initial project
  /// creation should live here.
  Directory get managedDirectory => _editableDirectory.childDirectory('flutter');

  /// The subdirectory of [managedDirectory] that contains files that are
  /// generated on the fly. All generated files that are not intended to be
  /// checked in should live here.
  Directory get ephemeralDirectory => managedDirectory.childDirectory('ephemeral');

  Future<void> ensureReadyForPlatformSpecificTooling() async {}
}

/// The Windows UWP version of the Windows project.
class WindowsUwpProject extends WindowsProject {
  WindowsUwpProject.fromFlutter(FlutterProject parent) : super.fromFlutter(parent);

  @override
  String get _childDirectory => 'winuwp';

  File get runnerCmakeFile => _editableDirectory.childDirectory('runner_uwp').childFile('CMakeLists.txt');

  /// Eventually this will be used to check if the user's unstable project needs to be regenerated.
  int? get projectVersion => int.tryParse(_editableDirectory.childFile('project_version').readAsStringSync());

  /// Retrieve the GUID of the UWP package.
  late final String? packageGuid = getCmakePackageGuid(runnerCmakeFile);

  File get appManifest => _editableDirectory.childDirectory('runner_uwp').childFile('appxmanifest.in');

  late final String? packageVersion = parseAppVersion(this);
}

@visibleForTesting
String? parseAppVersion(WindowsUwpProject project) {
  final File appManifestFile = project.appManifest;
  if (!appManifestFile.existsSync()) {
    return null;
  }

  XmlDocument document;
  try {
    document = XmlDocument.parse(appManifestFile.readAsStringSync());
  } on XmlParserException {
    throwToolExit('Error parsing $appManifestFile. Please ensure that the appx manifest is a valid XML document and try again.');
  }
  for (final XmlElement metaData in document.findAllElements('Identity')) {
    return metaData.getAttribute('Version');
  }
  return null;
}

/// The Linux sub project.
class LinuxProject extends FlutterProjectPlatform implements CmakeBasedProject {
  LinuxProject.fromFlutter(this.parent);

  @override
  final FlutterProject parent;

  @override
  String get pluginConfigKey => LinuxPlugin.kConfigKey;

  static final RegExp _applicationIdPattern = RegExp(r'''^\s*set\s*\(\s*APPLICATION_ID\s*"(.*)"\s*\)\s*$''');

  Directory get _editableDirectory => parent.directory.childDirectory('linux');

  /// The directory in the project that is managed by Flutter. As much as
  /// possible, files that are edited by Flutter tooling after initial project
  /// creation should live here.
  Directory get managedDirectory => _editableDirectory.childDirectory('flutter');

  /// The subdirectory of [managedDirectory] that contains files that are
  /// generated on the fly. All generated files that are not intended to be
  /// checked in should live here.
  Directory get ephemeralDirectory => managedDirectory.childDirectory('ephemeral');

  @override
  bool existsSync() => _editableDirectory.existsSync();

  @override
  File get cmakeFile => _editableDirectory.childFile('CMakeLists.txt');

  @override
  File get managedCmakeFile => managedDirectory.childFile('CMakeLists.txt');

  @override
  File get generatedCmakeConfigFile => ephemeralDirectory.childFile('generated_config.cmake');

  @override
  File get generatedPluginCmakeFile => managedDirectory.childFile('generated_plugins.cmake');

  @override
  Directory get pluginSymlinkDirectory => ephemeralDirectory.childDirectory('.plugin_symlinks');

  Future<void> ensureReadyForPlatformSpecificTooling() async {}

  String? get applicationId {
    return firstMatchInFile(cmakeFile, _applicationIdPattern)?.group(1);
  }
}

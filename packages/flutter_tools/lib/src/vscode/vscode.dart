// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/platform.dart';
import '../base/version.dart';

// Include VS Code insiders (useful for debugging).
const bool _includeInsiders = false;

class VsCode {
  static const String extensionIdentifier = 'Dart-Code.dart-code';

  VsCode._(this.directory, this.extensionDirectory, { Version version })
      : this.version = version ?? Version.unknown {

    if (!fs.isDirectorySync(directory)) {
      _validationMessages.add('VS Code not found at $directory');
      return;
    }

    // If the extensions directory doesn't exist at all, the listSync()
    // below will fail, so just bail out early.
    if (!fs.isDirectorySync(extensionDirectory)) {
      return;
    }

    // Check for presence of extension.
    final Iterable<FileSystemEntity> extensionDirs = fs
        .directory(extensionDirectory)
        .listSync()
        .where((FileSystemEntity d) => d is Directory)
        .where(
            (FileSystemEntity d) => d.basename.startsWith(extensionIdentifier));

    if (extensionDirs.isNotEmpty) {
      final FileSystemEntity extensionDir = extensionDirs.first;

      _isValid = true;
      _extensionVersion = new Version.parse(
          extensionDir.basename.substring('$extensionIdentifier-'.length));
      _validationMessages.add('Dart Code extension version $_extensionVersion');
    }
  }

  final String directory;
  final String extensionDirectory;
  final Version version;

  bool _isValid = false;
  Version _extensionVersion;
  final List<String> _validationMessages = <String>[];

  factory VsCode.fromDirectory(String installPath, String extensionDirectory) {
    final String packageJsonPath =
        fs.path.join(installPath, 'resources', 'app', 'package.json');
    final String versionString = _getVersionFromPackageJson(packageJsonPath);
    Version version;
    if (versionString != null)
      version = new Version.parse(versionString);
    return new VsCode._(installPath, extensionDirectory, version: version);
  }

  bool get isValid => _isValid;

  Iterable<String> get validationMessages => _validationMessages;

  static List<VsCode> allInstalled() {
    if (platform.isMacOS)
      return _installedMacOS();
    else if (platform.isWindows)
      return _installedWindows();
    else if (platform.isLinux)
      return _installedLinux();
    else
      // VS Code isn't supported on the other platforms.
      return <VsCode>[];
  }

  // macOS:
  //   /Applications/Visual Studio Code.app/Contents/
  //   /Applications/Visual Studio Code - Insiders.app/Contents/
  //   $HOME/Applications/Visual Studio Code.app/Contents/
  //   $HOME/Applications/Visual Studio Code - Insiders.app/Contents/
  // macOS Extensions:
  //   $HOME/.vscode/extensions
  //   $HOME/.vscode-insiders/extensions
  static List<VsCode> _installedMacOS() {
    final Map<String, String> stable = <String, String>{
      fs.path.join('/Applications', 'Visual Studio Code.app', 'Contents'):
          '.vscode',
      fs.path.join(homeDirPath, 'Applications', 'Visual Studio Code.app',
          'Contents'): '.vscode'
    };
    final Map<String, String> insiders = <String, String>{
      fs.path.join(
              '/Applications', 'Visual Studio Code - Insiders.app', 'Contents'):
          '.vscode-insiders',
      fs.path.join(homeDirPath, 'Applications',
          'Visual Studio Code - Insiders.app', 'Contents'): '.vscode-insiders'
    };

    return _findInstalled(stable, insiders);
  }

  // Windows:
  //   $programfiles(x86)\Microsoft VS Code
  //   $programfiles(x86)\Microsoft VS Code Insiders
  // TODO: Confirm these are correct for 64bit
  //   $programfiles\Microsoft VS Code
  //   $programfiles\Microsoft VS Code Insiders
  // Windows Extensions:
  //   $HOME/.vscode/extensions
  //   $HOME/.vscode-insiders/extensions
  static List<VsCode> _installedWindows() {
    final String progFiles86 = platform.environment['programfiles(x86)'];
    final String progFiles = platform.environment['programfiles'];

    final Map<String, String> stable = <String, String>{
      fs.path.join(progFiles86, 'Microsoft VS Code'): '.vscode',
      fs.path.join(progFiles, 'Microsoft VS Code'): '.vscode'
    };
    final Map<String, String> insiders = <String, String>{
      fs.path.join(progFiles86, 'Microsoft VS Code Insiders'):
          '.vscode-insiders',
      fs.path.join(progFiles, 'Microsoft VS Code Insiders'): '.vscode-insiders'
    };

    return _findInstalled(stable, insiders);
  }

  // Linux:
  //   /usr/share/code/bin/code
  //   /usr/share/code-insiders/bin/code-insiders
  // Linux Extensions:
  //   $HOME/.vscode/extensions
  //   $HOME/.vscode-insiders/extensions
  static List<VsCode> _installedLinux() {
    return _findInstalled(
      <String, String>{'/usr/share/code': '.vscode'},
      <String, String>{'/usr/share/code-insiders': '.vscode-insiders'}
    );
  }

  static List<VsCode> _findInstalled(
      Map<String, String> stable, Map<String, String> insiders) {
    final Map<String, String> allPaths = <String, String>{};
    allPaths.addAll(stable);
    if (_includeInsiders)
      allPaths.addAll(insiders);

    final List<VsCode> results = <VsCode>[];

    for (String directory in allPaths.keys) {
      if (fs.directory(directory).existsSync()) {
        final String extensionDirectory =
            fs.path.join(homeDirPath, allPaths[directory], 'extensions');
        results.add(new VsCode.fromDirectory(directory, extensionDirectory));
      }
    }

    return results;
  }

  @override
  String toString() =>
      'VS Code ($version)${(_extensionVersion != Version.unknown ? ', Dart Code ($_extensionVersion)' : '')}';

  static String _getVersionFromPackageJson(String packageJsonPath) {
    if (!fs.isFileSync(packageJsonPath))
      return null;
    final String jsonString = fs.file(packageJsonPath).readAsStringSync();
    final Map<String, String> json = JSON.decode(jsonString);
    return json['version'];
  }
}

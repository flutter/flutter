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
  VsCode._(this.directory, this.extensionDirectory, { Version version, this.edition })
      : version = version ?? Version.unknown {

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
    final String extensionIdentifierLower = extensionIdentifier.toLowerCase();
    final Iterable<FileSystemEntity> extensionDirs = fs
        .directory(extensionDirectory)
        .listSync()
        .whereType<Directory>()
        .where((Directory d) => d.basename.toLowerCase().startsWith(extensionIdentifierLower));

    if (extensionDirs.isNotEmpty) {
      final FileSystemEntity extensionDir = extensionDirs.first;

      _isValid = true;
      _extensionVersion = Version.parse(
          extensionDir.basename.substring('$extensionIdentifier-'.length));
      _validationMessages.add('Flutter extension version $_extensionVersion');
    }
  }

  factory VsCode.fromDirectory(String installPath, String extensionDirectory,
      { String edition }) {
    final String packageJsonPath =
        fs.path.join(installPath, 'resources', 'app', 'package.json');
    final String versionString = _getVersionFromPackageJson(packageJsonPath);
    Version version;
    if (versionString != null)
      version = Version.parse(versionString);
    return VsCode._(installPath, extensionDirectory, version: version, edition: edition);
  }

  final String directory;
  final String extensionDirectory;
  final Version version;
  final String edition;

  static const String extensionIdentifier = 'Dart-Code.flutter';

  bool _isValid = false;
  Version _extensionVersion;
  final List<String> _validationMessages = <String>[];

  bool get isValid => _isValid;
  String get productName => 'VS Code' + (edition != null ? ', $edition' : '');

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
    return _findInstalled(<_VsCodeInstallLocation>[
      _VsCodeInstallLocation(
        fs.path.join('/Applications', 'Visual Studio Code.app', 'Contents'),
        '.vscode',
      ),
      _VsCodeInstallLocation(
        fs.path.join(homeDirPath, 'Applications', 'Visual Studio Code.app', 'Contents'),
        '.vscode',
      ),
      _VsCodeInstallLocation(
        fs.path.join('/Applications', 'Visual Studio Code - Insiders.app', 'Contents'),
        '.vscode-insiders',
        isInsiders: true,
      ),
      _VsCodeInstallLocation(
        fs.path.join(homeDirPath, 'Applications', 'Visual Studio Code - Insiders.app', 'Contents'),
        '.vscode-insiders',
        isInsiders: true,
      )
    ]);
  }

  // Windows:
  //   $programfiles(x86)\Microsoft VS Code
  //   $programfiles(x86)\Microsoft VS Code Insiders
  // User install:
  //   $localappdata\Programs\Microsoft VS Code
  //   $localappdata\Programs\Microsoft VS Code Insiders
  // TODO(dantup): Confirm these are correct for 64bit
  //   $programfiles\Microsoft VS Code
  //   $programfiles\Microsoft VS Code Insiders
  // Windows Extensions:
  //   $HOME/.vscode/extensions
  //   $HOME/.vscode-insiders/extensions
  static List<VsCode> _installedWindows() {
    final String progFiles86 = platform.environment['programfiles(x86)'];
    final String progFiles = platform.environment['programfiles'];
    final String localAppData = platform.environment['localappdata'];

    final List<_VsCodeInstallLocation> searchLocations =
        <_VsCodeInstallLocation>[];

    if (localAppData != null) {
      searchLocations.add(_VsCodeInstallLocation(
          fs.path.join(localAppData, 'Programs\\Microsoft VS Code'),
          '.vscode'));
    }
    searchLocations.add(_VsCodeInstallLocation(
        fs.path.join(progFiles86, 'Microsoft VS Code'), '.vscode',
        edition: '32-bit edition'));
    searchLocations.add(_VsCodeInstallLocation(
        fs.path.join(progFiles, 'Microsoft VS Code'), '.vscode',
        edition: '64-bit edition'));
    if (localAppData != null) {
      searchLocations.add(_VsCodeInstallLocation(
          fs.path.join(localAppData, 'Programs\\Microsoft VS Code Insiders'),
          '.vscode-insiders',
          isInsiders: true));
    }
    searchLocations.add(_VsCodeInstallLocation(
        fs.path.join(progFiles86, 'Microsoft VS Code Insiders'),
        '.vscode-insiders',
        edition: '32-bit edition',
        isInsiders: true));
    searchLocations.add(_VsCodeInstallLocation(
        fs.path.join(progFiles, 'Microsoft VS Code Insiders'),
        '.vscode-insiders',
        edition: '64-bit edition',
        isInsiders: true));

    return _findInstalled(searchLocations);
  }

  // Linux:
  //   /usr/share/code/bin/code
  //   /usr/share/code-insiders/bin/code-insiders
  // Linux Extensions:
  //   $HOME/.vscode/extensions
  //   $HOME/.vscode-insiders/extensions
  static List<VsCode> _installedLinux() {
    return _findInstalled(<_VsCodeInstallLocation>[
      const _VsCodeInstallLocation('/usr/share/code', '.vscode'),
      const _VsCodeInstallLocation('/usr/share/code-insiders', '.vscode-insiders', isInsiders: true),
    ]);
  }

  static List<VsCode> _findInstalled(
      List<_VsCodeInstallLocation> allLocations) {
    final Iterable<_VsCodeInstallLocation> searchLocations =
      _includeInsiders
        ? allLocations
        : allLocations.where((_VsCodeInstallLocation p) => p.isInsiders != true);

    final List<VsCode> results = <VsCode>[];

    for (_VsCodeInstallLocation searchLocation in searchLocations) {
      if (fs.isDirectorySync(searchLocation.installPath)) {
        final String extensionDirectory =
            fs.path.join(homeDirPath, searchLocation.extensionsFolder, 'extensions');
        results.add(VsCode.fromDirectory(searchLocation.installPath, extensionDirectory, edition: searchLocation.edition));
      }
    }

    return results;
  }

  @override
  String toString() =>
      'VS Code ($version)${_extensionVersion != Version.unknown ? ', Flutter ($_extensionVersion)' : ''}';

  static String _getVersionFromPackageJson(String packageJsonPath) {
    if (!fs.isFileSync(packageJsonPath))
      return null;
    final String jsonString = fs.file(packageJsonPath).readAsStringSync();
    final Map<String, dynamic> jsonObject = json.decode(jsonString);
    return jsonObject['version'];
  }
}

class _VsCodeInstallLocation {
  const _VsCodeInstallLocation(this.installPath, this.extensionsFolder, { this.edition, bool isInsiders })
    : isInsiders = isInsiders ?? false;
  final String installPath;
  final String extensionsFolder;
  final String edition;
  final bool isInsiders;
}

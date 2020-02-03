// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/utils.dart';
import '../base/version.dart';
import '../convert.dart';
import '../doctor.dart';
import '../globals.dart' as globals;

// Include VS Code insiders (useful for debugging).
const bool _includeInsiders = false;


const String extensionIdentifier = 'Dart-Code.flutter';
const String extensionMarketplaceUrl =
  'https://marketplace.visualstudio.com/items?itemName=$extensionIdentifier';

class VsCode {
  VsCode._(this.directory, this.extensionDirectory, { Version version, this.edition })
      : version = version ?? Version.unknown {

    if (!globals.fs.isDirectorySync(directory)) {
      _validationMessages.add(ValidationMessage.error('VS Code not found at $directory'));
      return;
    } else {
      _validationMessages.add(ValidationMessage('VS Code at $directory'));
    }

    // If the extensions directory doesn't exist at all, the listSync()
    // below will fail, so just bail out early.
    final ValidationMessage notInstalledMessage = ValidationMessage.error(
          'Flutter extension not installed; install from\n$extensionMarketplaceUrl');
    if (!globals.fs.isDirectorySync(extensionDirectory)) {
      _validationMessages.add(notInstalledMessage);
      return;
    }

    // Check for presence of extension.
    final String extensionIdentifierLower = extensionIdentifier.toLowerCase();
    final Iterable<FileSystemEntity> extensionDirs = globals.fs
        .directory(extensionDirectory)
        .listSync()
        .whereType<Directory>()
        .where((Directory d) => d.basename.toLowerCase().startsWith(extensionIdentifierLower));

    if (extensionDirs.isNotEmpty) {
      final FileSystemEntity extensionDir = extensionDirs.first;

      _isValid = true;
      _extensionVersion = Version.parse(
          extensionDir.basename.substring('$extensionIdentifier-'.length));
      _validationMessages.add(ValidationMessage('Flutter extension version $_extensionVersion'));
    } else {
      _validationMessages.add(notInstalledMessage);
    }
  }

  factory VsCode.fromDirectory(
    String installPath,
    String extensionDirectory, {
    String edition,
  }) {
    final String packageJsonPath =
        globals.fs.path.join(installPath, 'resources', 'app', 'package.json');
    final String versionString = _getVersionFromPackageJson(packageJsonPath);
    Version version;
    if (versionString != null) {
      version = Version.parse(versionString);
    }
    return VsCode._(installPath, extensionDirectory, version: version, edition: edition);
  }

  final String directory;
  final String extensionDirectory;
  final Version version;
  final String edition;

  bool _isValid = false;
  Version _extensionVersion;
  final List<ValidationMessage> _validationMessages = <ValidationMessage>[];

  bool get isValid => _isValid;
  String get productName => 'VS Code' + (edition != null ? ', $edition' : '');

  Iterable<ValidationMessage> get validationMessages => _validationMessages;

  static List<VsCode> allInstalled() {
    if (globals.platform.isMacOS) {
      return _installedMacOS();
    }
    if (globals.platform.isWindows) {
      return _installedWindows();
    }
    if (globals.platform.isLinux) {
      return _installedLinux();
    }
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
        globals.fs.path.join('/Applications', 'Visual Studio Code.app', 'Contents'),
        '.vscode',
      ),
      _VsCodeInstallLocation(
        globals.fs.path.join(
          globals.fsUtils.homeDirPath,
          'Applications',
          'Visual Studio Code.app',
          'Contents',
        ),
        '.vscode',
      ),
      _VsCodeInstallLocation(
        globals.fs.path.join('/Applications', 'Visual Studio Code - Insiders.app', 'Contents'),
        '.vscode-insiders',
        isInsiders: true,
      ),
      _VsCodeInstallLocation(
        globals.fs.path.join(
          globals.fsUtils.homeDirPath,
          'Applications',
          'Visual Studio Code - Insiders.app',
          'Contents',
        ),
        '.vscode-insiders',
        isInsiders: true,
      ),
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
    final String progFiles86 = globals.platform.environment['programfiles(x86)'];
    final String progFiles = globals.platform.environment['programfiles'];
    final String localAppData = globals.platform.environment['localappdata'];

    final List<_VsCodeInstallLocation> searchLocations =
        <_VsCodeInstallLocation>[];

    if (localAppData != null) {
      searchLocations.add(_VsCodeInstallLocation(
        globals.fs.path.join(localAppData, 'Programs\\Microsoft VS Code'),
        '.vscode',
      ));
    }
    searchLocations.add(_VsCodeInstallLocation(
      globals.fs.path.join(progFiles86, 'Microsoft VS Code'),
      '.vscode',
      edition: '32-bit edition',
    ));
    searchLocations.add(_VsCodeInstallLocation(
      globals.fs.path.join(progFiles, 'Microsoft VS Code'),
      '.vscode',
      edition: '64-bit edition',
    ));
    if (localAppData != null) {
      searchLocations.add(_VsCodeInstallLocation(
        globals.fs.path.join(localAppData, 'Programs\\Microsoft VS Code Insiders'),
        '.vscode-insiders',
        isInsiders: true,
      ));
    }
    searchLocations.add(_VsCodeInstallLocation(
      globals.fs.path.join(progFiles86, 'Microsoft VS Code Insiders'),
      '.vscode-insiders',
      edition: '32-bit edition',
      isInsiders: true,
    ));
    searchLocations.add(_VsCodeInstallLocation(
      globals.fs.path.join(progFiles, 'Microsoft VS Code Insiders'),
      '.vscode-insiders',
      edition: '64-bit edition',
      isInsiders: true,
    ));

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
      const _VsCodeInstallLocation(
        '/usr/share/code-insiders',
        '.vscode-insiders',
        isInsiders: true,
      ),
    ]);
  }

  static List<VsCode> _findInstalled(List<_VsCodeInstallLocation> allLocations) {
    final Iterable<_VsCodeInstallLocation> searchLocations =
      _includeInsiders
        ? allLocations
        : allLocations.where((_VsCodeInstallLocation p) => p.isInsiders != true);

    final List<VsCode> results = <VsCode>[];

    for (final _VsCodeInstallLocation searchLocation in searchLocations) {
      if (globals.fs.isDirectorySync(searchLocation.installPath)) {
        final String extensionDirectory = globals.fs.path.join(
          globals.fsUtils.homeDirPath,
          searchLocation.extensionsFolder,
          'extensions',
        );
        results.add(VsCode.fromDirectory(
          searchLocation.installPath,
          extensionDirectory,
          edition: searchLocation.edition,
        ));
      }
    }

    return results;
  }

  @override
  String toString() =>
      'VS Code ($version)${_extensionVersion != Version.unknown ? ', Flutter ($_extensionVersion)' : ''}';

  static String _getVersionFromPackageJson(String packageJsonPath) {
    if (!globals.fs.isFileSync(packageJsonPath)) {
      return null;
    }
    final String jsonString = globals.fs.file(packageJsonPath).readAsStringSync();
    try {
      final Map<String, dynamic> jsonObject = castStringKeyedMap(json.decode(jsonString));
      return jsonObject['version'] as String;
    } on FormatException catch (err) {
      globals.printTrace('Error parsing VSCode $packageJsonPath:\n$err');
      return null;
    }
  }
}

class _VsCodeInstallLocation {
  const _VsCodeInstallLocation(
    this.installPath,
    this.extensionsFolder, {
    this.edition,
    bool isInsiders
  }) : isInsiders = isInsiders ?? false;

  final String installPath;
  final String extensionsFolder;
  final String edition;
  final bool isInsiders;
}

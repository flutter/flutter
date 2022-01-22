// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../convert.dart';

/// Encapsulates information about the installed copy of Visual Studio, if any.
class VisualStudio {
  VisualStudio({
    required FileSystem fileSystem,
    required ProcessManager processManager,
    required Platform platform,
    required Logger logger,
  }) : _platform = platform,
       _fileSystem = fileSystem,
       _processUtils = ProcessUtils(processManager: processManager, logger: logger);

  final FileSystem _fileSystem;
  final Platform _platform;
  final ProcessUtils _processUtils;

  /// True if Visual Studio installation was found.
  ///
  /// Versions older than 2017 Update 2 won't be detected, so error messages to
  /// users should take into account that [false] may mean that the user may
  /// have an old version rather than no installation at all.
  bool get isInstalled => _bestVisualStudioDetails.isNotEmpty;

  bool get isAtLeastMinimumVersion {
    final int? installedMajorVersion = _majorVersion;
    return installedMajorVersion != null && installedMajorVersion >= _minimumSupportedVersion;
  }

  /// True if there is a version of Visual Studio with all the components
  /// necessary to build the project.
  bool get hasNecessaryComponents => _usableVisualStudioDetails.isNotEmpty;

  /// The name of the Visual Studio install.
  ///
  /// For instance: "Visual Studio Community 2019".
  String? get displayName => _bestVisualStudioDetails[_displayNameKey] as String?;

  /// The user-friendly version number of the Visual Studio install.
  ///
  /// For instance: "15.4.0".
  String? get displayVersion {
    if (_bestVisualStudioDetails[_catalogKey] == null) {
      return null;
    }
    return (_bestVisualStudioDetails[_catalogKey] as Map<String, dynamic>)[_catalogDisplayVersionKey] as String?;
  }

  /// The directory where Visual Studio is installed.
  String? get installLocation => _bestVisualStudioDetails[_installationPathKey] as String?;

  /// The full version of the Visual Studio install.
  ///
  /// For instance: "15.4.27004.2002".
  String? get fullVersion => _bestVisualStudioDetails[_fullVersionKey] as String?;

  // Properties that determine the status of the installation. There might be
  // Visual Studio versions that don't include them, so default to a "valid" value to
  // avoid false negatives.

  /// True if there is a complete installation of Visual Studio.
  ///
  /// False if installation is not found.
  bool get isComplete {
    if (_bestVisualStudioDetails.isEmpty) {
      return false;
    }
    return _bestVisualStudioDetails[_isCompleteKey] as bool? ?? true;
  }

  /// True if Visual Studio is launchable.
  ///
  /// False if installation is not found.
  bool get isLaunchable {
    if (_bestVisualStudioDetails.isEmpty) {
      return false;
    }
    return _bestVisualStudioDetails[_isLaunchableKey] as bool? ?? true;
  }

  /// True if the Visual Studio installation is as pre-release version.
  bool get isPrerelease => _bestVisualStudioDetails[_isPrereleaseKey] as bool? ?? false;

  /// True if a reboot is required to complete the Visual Studio installation.
  bool get isRebootRequired => _bestVisualStudioDetails[_isRebootRequiredKey] as bool? ?? false;

  /// The name of the recommended Visual Studio installer workload.
  String get workloadDescription => 'Desktop development with C++';

  /// Returns the highest installed Windows 10 SDK version, or null if none is
  /// found.
  ///
  /// For instance: 10.0.18362.0.
  String? getWindows10SDKVersion() {
    final String? sdkLocation = _getWindows10SdkLocation();
    if (sdkLocation == null) {
      return null;
    }
    final Directory sdkIncludeDirectory = _fileSystem.directory(sdkLocation).childDirectory('Include');
    if (!sdkIncludeDirectory.existsSync()) {
      return null;
    }
    // The directories in this folder are named by the SDK version.
    Version? highestVersion;
    for (final FileSystemEntity versionEntry in sdkIncludeDirectory.listSync()) {
      if (versionEntry.basename.startsWith('10.')) {
        // Version only handles 3 components; strip off the '10.' to leave three
        // components, since they all start with that.
        final Version? version = Version.parse(versionEntry.basename.substring(3));
        if (highestVersion == null || (version != null && version > highestVersion)) {
          highestVersion = version;
        }
      }
    }
    if (highestVersion == null) {
      return null;
    }
    return '10.$highestVersion';
  }

  /// The names of the components within the workload that must be installed.
  ///
  /// The descriptions of some components differ from version to version. When
  /// a supported version is present, the descriptions used will be for that
  /// version.
  List<String> necessaryComponentDescriptions() {
    return _requiredComponents().values.toList();
  }

  /// The consumer-facing version name of the minimum supported version.
  ///
  /// E.g., for Visual Studio 2019 this returns "2019" rather than "16".
  String get minimumVersionDescription {
    return '2019';
  }

  /// The path to CMake, or null if no Visual Studio installation has
  /// the components necessary to build.
  String? get cmakePath {
    final Map<String, dynamic> details = _usableVisualStudioDetails;
    if (details.isEmpty || _usableVisualStudioDetails[_installationPathKey] == null) {
      return null;
    }
    return _fileSystem.path.joinAll(<String>[
      _usableVisualStudioDetails[_installationPathKey] as String,
      'Common7',
      'IDE',
      'CommonExtensions',
      'Microsoft',
      'CMake',
      'CMake',
      'bin',
      'cmake.exe',
    ]);
  }

  /// The generator string to pass to CMake to select this Visual Studio
  /// version.
  String? get cmakeGenerator {
    // From https://cmake.org/cmake/help/v3.22/manual/cmake-generators.7.html#visual-studio-generators
    switch (_majorVersion) {
      case 17:
        return 'Visual Studio 17 2022';
      case 16:
      default:
        return 'Visual Studio 16 2019';
    }
  }

  /// The major version of the Visual Studio install, as an integer.
  int? get _majorVersion => fullVersion != null ? int.tryParse(fullVersion!.split('.')[0]) : null;

  /// The path to vswhere.exe.
  ///
  /// vswhere should be installed for VS 2017 Update 2 and later; if it's not
  /// present then there isn't a new enough installation of VS. This path is
  /// not user-controllable, unlike the install location of Visual Studio
  /// itself.
  String get _vswherePath {
    const String programFilesEnv = 'PROGRAMFILES(X86)';
    if (!_platform.environment.containsKey(programFilesEnv)) {
      throwToolExit('%$programFilesEnv% environment variable not found.');
    }
    return _fileSystem.path.join(
      _platform.environment[programFilesEnv]!,
      'Microsoft Visual Studio',
      'Installer',
      'vswhere.exe',
    );
  }

  /// Workload ID for use with vswhere requirements.
  ///
  /// Workload ID is different between Visual Studio IDE and Build Tools.
  /// See https://docs.microsoft.com/en-us/visualstudio/install/workload-and-component-ids
  static const List<String> _requiredWorkloads = <String>[
    'Microsoft.VisualStudio.Workload.NativeDesktop',
    'Microsoft.VisualStudio.Workload.VCTools'
  ];

  /// Components for use with vswhere requirements.
  ///
  /// Maps from component IDs to description in the installer UI.
  /// See https://docs.microsoft.com/en-us/visualstudio/install/workload-and-component-ids
  Map<String, String> _requiredComponents([int? majorVersion]) {
    // The description of the C++ toolchain required by the template. The
    // component name is significantly different in different versions.
    // When a new major version of VS is supported, its toolchain description
    // should be added below. It should also be made the default, so that when
    // there is no installation, the message shows the string that will be
    // relevant for the most likely fresh install case).
    String cppToolchainDescription;
    switch (majorVersion ?? _majorVersion) {
      case 16:
      default:
        cppToolchainDescription = 'MSVC v142 - VS 2019 C++ x64/x86 build tools';
    }
    // The 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64' ID is assigned to the latest
    // release of the toolchain, and there can be minor updates within a given version of
    // Visual Studio. Since it changes over time, listing a precise version would become
    // wrong after each VC++ toolchain update, so just instruct people to install the
    // latest version.
    cppToolchainDescription += '\n   - If there are multiple build tool versions available, install the latest';
    // Things which are required by the workload (e.g., MSBuild) don't need to
    // be included here.
    return <String, String>{
      // The C++ toolchain required by the template.
      'Microsoft.VisualStudio.Component.VC.Tools.x86.x64': cppToolchainDescription,
      // CMake
      'Microsoft.VisualStudio.Component.VC.CMake.Project': 'C++ CMake tools for Windows',
    };
  }

  /// The minimum supported major version.
  static const int _minimumSupportedVersion = 16;  // '16' is VS 2019.

  /// vswhere argument to specify the minimum version.
  static const String _vswhereMinVersionArgument = '-version';

  /// vswhere argument to allow prerelease versions.
  static const String _vswherePrereleaseArgument = '-prerelease';

  // Keys in a VS details dictionary returned from vswhere.

  /// The root directory of the Visual Studio installation.
  static const String _installationPathKey = 'installationPath';

  /// The user-friendly name of the installation.
  static const String _displayNameKey = 'displayName';

  /// The complete version.
  static const String _fullVersionKey = 'installationVersion';

  /// Keys for the status of the installation.
  static const String _isCompleteKey = 'isComplete';
  static const String _isLaunchableKey = 'isLaunchable';
  static const String _isRebootRequiredKey = 'isRebootRequired';

  /// The 'catalog' entry containing more details.
  static const String _catalogKey = 'catalog';

  /// The key for a pre-release version.
  static const String _isPrereleaseKey = 'isPrerelease';

  /// The user-friendly version.
  ///
  /// This key is under the 'catalog' entry.
  static const String _catalogDisplayVersionKey = 'productDisplayVersion';

  /// The registry path for Windows 10 SDK installation details.
  static const String _windows10SdkRegistryPath = r'HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v10.0';

  /// The registry key in _windows10SdkRegistryPath for the folder where the
  /// SDKs are installed.
  static const String _windows10SdkRegistryKey = 'InstallationFolder';

  /// Returns the details dictionary for the newest version of Visual Studio.
  /// If [validateRequirements] is set, the search will be limited to versions
  /// that have all of the required workloads and components.
  Map<String, dynamic>? _visualStudioDetails({
      bool validateRequirements = false,
      List<String>? additionalArguments,
      String? requiredWorkload
    }) {
    final List<String> requirementArguments = validateRequirements
        ? <String>[
            if (requiredWorkload != null) ...<String>[
              '-requires',
              requiredWorkload,
            ],
            ..._requiredComponents(_minimumSupportedVersion).keys
          ]
        : <String>[];
    try {
      final List<String> defaultArguments = <String>[
        '-format', 'json',
        '-products', '*',
        '-utf8',
        '-latest',
      ];
      final RunResult whereResult = _processUtils.runSync(<String>[
        _vswherePath,
        ...defaultArguments,
        ...?additionalArguments,
        ...requirementArguments,
      ], encoding: utf8);
      if (whereResult.exitCode == 0) {
        final List<Map<String, dynamic>> installations =
            (json.decode(whereResult.stdout) as List<dynamic>).cast<Map<String, dynamic>>();
        if (installations.isNotEmpty) {
          return installations[0];
        }
      }
    } on ArgumentError {
      // Thrown if vswhere doesn't exist; ignore and return null below.
    } on ProcessException {
      // Ignored, return null below.
    } on FormatException {
      // may be thrown if invalid JSON is returned.
    }
    return null;
  }

  /// Checks if the given installation has issues that the user must resolve.
  ///
  /// Returns false if the required information is missing since older versions
  /// of Visual Studio might not include them.
  bool installationHasIssues(Map<String, dynamic>installationDetails) {
    assert(installationDetails != null);
    if (installationDetails[_isCompleteKey] != null && !(installationDetails[_isCompleteKey] as bool)) {
      return true;
    }

    if (installationDetails[_isLaunchableKey] != null && !(installationDetails[_isLaunchableKey] as bool)) {
      return true;
    }

    if (installationDetails[_isRebootRequiredKey] != null && installationDetails[_isRebootRequiredKey] as bool) {
      return true;
    }

    return false;
  }

  /// Returns the details dictionary for the latest version of Visual Studio
  /// that has all required components and is a supported version, or {} if
  /// there is no such installation.
  ///
  /// If no installation is found, the cached VS details are set to an empty map
  /// to avoid repeating vswhere queries that have already not found an installation.
  late final Map<String, dynamic> _usableVisualStudioDetails = (){
    final List<String> minimumVersionArguments = <String>[
      _vswhereMinVersionArgument,
      _minimumSupportedVersion.toString(),
    ];
    Map<String, dynamic>? visualStudioDetails;
    // Check in the order of stable VS, stable BT, pre-release VS, pre-release BT
    for (final bool checkForPrerelease in <bool>[false, true]) {
      for (final String requiredWorkload in _requiredWorkloads) {
        visualStudioDetails ??= _visualStudioDetails(
          validateRequirements: true,
          additionalArguments: checkForPrerelease
              ? <String>[...minimumVersionArguments, _vswherePrereleaseArgument]
              : minimumVersionArguments,
          requiredWorkload: requiredWorkload);
      }
    }

    Map<String, dynamic>? usableVisualStudioDetails;
    if (visualStudioDetails != null) {
      if (installationHasIssues(visualStudioDetails)) {
        _cachedAnyVisualStudioDetails = visualStudioDetails;
      } else {
        usableVisualStudioDetails = visualStudioDetails;
      }
    }
    return usableVisualStudioDetails ?? <String, dynamic>{};
  }();

  /// Returns the details dictionary of the latest version of Visual Studio,
  /// regardless of components and version, or {} if no such installation is
  /// found.
  ///
  /// If no installation is found, the cached VS details are set to an empty map
  /// to avoid repeating vswhere queries that have already not found an
  /// installation.
  Map<String, dynamic>? _cachedAnyVisualStudioDetails;
  Map<String, dynamic> get _anyVisualStudioDetails {
    // Search for all types of installations.
    _cachedAnyVisualStudioDetails ??= _visualStudioDetails(
        additionalArguments: <String>[_vswherePrereleaseArgument, '-all']);
    // Add a sentinel empty value to avoid querying vswhere again.
    _cachedAnyVisualStudioDetails ??= <String, dynamic>{};
    return _cachedAnyVisualStudioDetails!;
  }

  /// Returns the details dictionary of the best available version of Visual
  /// Studio.
  ///
  /// If there's a version that has all the required components, that
  /// will be returned, otherwise returns the latest installed version (if any).
  Map<String, dynamic> get _bestVisualStudioDetails {
    if (_usableVisualStudioDetails.isNotEmpty) {
      return _usableVisualStudioDetails;
    }
    return _anyVisualStudioDetails;
  }

  /// Returns the installation location of the Windows 10 SDKs, or null if the
  /// registry doesn't contain that information.
  String? _getWindows10SdkLocation() {
    try {
      final RunResult result = _processUtils.runSync(<String>[
        'reg',
        'query',
        _windows10SdkRegistryPath,
        '/v',
        _windows10SdkRegistryKey,
      ]);
      if (result.exitCode == 0) {
        final RegExp pattern = RegExp(r'InstallationFolder\s+REG_SZ\s+(.+)');
        final RegExpMatch? match = pattern.firstMatch(result.stdout);
        if (match != null) {
          return match.group(1)!.trim();
        }
      }
    } on ArgumentError {
      // Thrown if reg somehow doesn't exist; ignore and return null below.
    } on ProcessException {
      // Ignored, return null below.
    }
    return null;
  }

  /// Returns the highest-numbered SDK version in [dir], which should be the
  /// Windows 10 SDK installation directory.
  ///
  /// Returns null if no Windows 10 SDKs are found.
  String? findHighestVersionInSdkDirectory(Directory dir) {
    // This contains subfolders that are named by the SDK version.
    final Directory includeDir = dir.childDirectory('Includes');
    if (!includeDir.existsSync()) {
      return null;
    }
    Version? highestVersion;
    for (final FileSystemEntity versionEntry in includeDir.listSync()) {
      if (!versionEntry.basename.startsWith('10.')) {
        continue;
      }
      // Version only handles 3 components; strip off the '10.' to leave three
      // components, since they all start with that.
      final Version? version = Version.parse(versionEntry.basename.substring(3));
      if (highestVersion == null || (version != null && version > highestVersion)) {
        highestVersion = version;
      }
    }
    // Re-add the leading '10.' that was removed for comparison.
    return highestVersion == null ? null : '10.$highestVersion';
  }
}

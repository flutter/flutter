// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../convert.dart';

VisualStudio get visualStudio => context.get<VisualStudio>();

/// Encapsulates information about the installed copy of Visual Studio, if any.
class VisualStudio {
  /// True if a sufficiently recent version of Visual Studio is installed.
  ///
  /// Versions older than 2017 Update 2 won't be detected, so error messages to
  /// users should take into account that [false] may mean that the user may
  /// have an old version rather than no installation at all.
  bool get isInstalled => _bestVisualStudioDetails != null;

  /// True if there is a version of Visual Studio with all the components
  /// necessary to build the project.
  bool get hasNecessaryComponents => _usableVisualStudioDetails != null;

  /// The name of the Visual Studio install.
  ///
  /// For instance: "Visual Studio Community 2017".
  String get displayName => _bestVisualStudioDetails[_displayNameKey];

  /// The user-friendly version number of the Visual Studio install.
  ///
  /// For instance: "15.4.0".
  String get displayVersion =>
      _bestVisualStudioDetails[_catalogKey][_catalogDisplayVersionKey];

  /// The directory where Visual Studio is installed.
  String get installLocation => _bestVisualStudioDetails[_installationPathKey];

  /// The full version of the Visual Studio install.
  ///
  /// For instance: "15.4.27004.2002".
  String get fullVersion => _bestVisualStudioDetails[_fullVersionKey];

  // Properties that determine the status of the installation. There might be
  // Visual Studio versions that don't include them, so default to a "valid" value to
  // avoid false negatives.

  /// True there is complete installation of Visual Studio.
  bool get isComplete => _bestVisualStudioDetails[_isCompleteKey] ?? false;

  /// True if Visual Studio is launchable.
  bool get isLaunchable => _bestVisualStudioDetails[_isLaunchableKey] ?? false;

    /// True if the Visual Studio installation is as pre-release version.
  bool get isPrerelease => _bestVisualStudioDetails[_isPrereleaseKey] ?? false;

  /// True if a reboot is required to complete the Visual Studio installation.
  bool get isRebootRequired => _bestVisualStudioDetails[_isRebootRequiredKey] ?? false;

  /// The name of the recommended Visual Studio installer workload.
  String get workloadDescription => 'Desktop development with C++';

  /// The names of the components within the workload that must be installed.
  ///
  /// If there is an existing Visual Studio installation, the major version
  /// should be provided here, as the descriptions of some componets differ
  /// from version to version.
  List<String> necessaryComponentDescriptions([int visualStudioMajorVersion]) {
    return _requiredComponents(visualStudioMajorVersion).values.toList();
  }

  /// The path to vcvars64.bat, or null if no Visual Studio installation has
  /// the components necessary to build.
  String get vcvarsPath {
    final Map<String, dynamic> details = _usableVisualStudioDetails;
    if (details == null) {
      return null;
    }
    return fs.path.join(
      _usableVisualStudioDetails[_installationPathKey],
      'VC',
      'Auxiliary',
      'Build',
      'vcvars64.bat',
    );
  }

  /// The path to vswhere.exe.
  ///
  /// vswhere should be installed for VS 2017 Update 2 and later; if it's not
  /// present then there isn't a new enough installation of VS. This path is
  /// not user-controllable, unlike the install location of Visual Studio
  /// itself.
  final String _vswherePath = fs.path.join(
    platform.environment['PROGRAMFILES(X86)'],
    'Microsoft Visual Studio',
    'Installer',
    'vswhere.exe',
  );

  /// Components for use with vswhere requriements.
  ///
  /// Maps from component IDs to description in the installer UI.
  /// See https://docs.microsoft.com/en-us/visualstudio/install/workload-and-component-ids
  Map<String, String> _requiredComponents([int visualStudioMajorVersion]) {
    // The description of the C++ toolchain required by the template. The
    // component name is significantly different in different versions.
    // Default to the latest known description, but use a specific string
    // if a known older version is requested.
    String cppToolchainDescription = 'MSVC v142 - VS 2019 C++ x64/x86 build tools (v14.21)';
    if (visualStudioMajorVersion == 15) {
      cppToolchainDescription = 'VC++ 2017 version 15.9 v14.16 latest v141 tools';
    }

    return <String, String>{
      // The MSBuild tool and related command-line toolchain.
      'Microsoft.Component.MSBuild': 'MSBuild',
      // The C++ toolchain required by the template.
      'Microsoft.VisualStudio.Component.VC.Tools.x86.x64': cppToolchainDescription,
      // The Windows SDK version used by the template.
      'Microsoft.VisualStudio.Component.Windows10SDK.17763':
          'Windows 10 SDK (10.0.17763.0)',
    };
  }

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

  /// vswhere argument keys
  static const String _prereleaseKey = '-prerelease';

  /// Returns the details dictionary for the newest version of Visual Studio
  /// that includes all of [requiredComponents], if there is one.
  Map<String, dynamic> _visualStudioDetails(
      {Iterable<String> requiredComponents, List<String> additionalArguments}) {
    final List<String> requirementArguments = requiredComponents == null
        ? <String>[]
        : <String>['-requires', ...requiredComponents];
    try {
      final List<String> defaultArguments = <String>[
        '-format', 'json',
        '-utf8',
        '-latest',
      ];
      final RunResult whereResult = processUtils.runSync(<String>[
        _vswherePath,
        ...defaultArguments,
        ...?additionalArguments,
        ...?requirementArguments,
      ]);
      if (whereResult.exitCode == 0) {
        final List<Map<String, dynamic>> installations =
            json.decode(whereResult.stdout).cast<Map<String, dynamic>>();
        if (installations.isNotEmpty) {
          return installations[0];
        }
      }
    } on ArgumentError {
      // Thrown if vswhere doesnt' exist; ignore and return null below.
    } on ProcessException {
      // Ignored, return null below.
    }
    return null;
  }

  /// Checks if the given installation has issues that the user must resolve.
  ///
  /// Returns false if the required information is missing since older versions
  /// of Visual Studio might not include them.
  bool installationHasIssues(Map<String, dynamic>installationDetails) {
    assert(installationDetails != null);
    if (installationDetails[_isCompleteKey] != null && !installationDetails[_isCompleteKey]) {
      return true;
    }

    if (installationDetails[_isLaunchableKey] != null && !installationDetails[_isLaunchableKey]) {
      return true;
    }

    if (installationDetails[_isRebootRequiredKey] != null && installationDetails[_isRebootRequiredKey]) {
      return true;
    }

    return false;
  }

  /// Returns the details dictionary for the latest version of Visual Studio
  /// that has all required components.
  Map<String, dynamic> _cachedUsableVisualStudioDetails;
  Map<String, dynamic> get _usableVisualStudioDetails {
    _cachedUsableVisualStudioDetails ??=
        _visualStudioDetails(requiredComponents: _requiredComponents().keys);
    // If a stable version is not found, try searching for a pre-release version.
    _cachedUsableVisualStudioDetails ??= _visualStudioDetails(
        requiredComponents: _requiredComponents().keys,
        additionalArguments: <String>[_prereleaseKey]);
    if (_cachedUsableVisualStudioDetails != null) {
      if (installationHasIssues(_cachedUsableVisualStudioDetails)) {
        _cachedAnyVisualStudioDetails = _cachedUsableVisualStudioDetails;
        return null;
      }
    }
    return _cachedUsableVisualStudioDetails;
  }

  /// Returns the details dictionary of the latest version of Visual Studio,
  /// regardless of components.
  Map<String, dynamic> _cachedAnyVisualStudioDetails;
  Map<String, dynamic> get _anyVisualStudioDetails {
    // Search for all types of installations.
    _cachedAnyVisualStudioDetails ??= _visualStudioDetails(
        additionalArguments: <String>[_prereleaseKey, '-all']);
    return _cachedAnyVisualStudioDetails;
  }

  /// Returns the details dictionary of the best available version of Visual
  /// Studio. If there's a version that has all the required components, that
  /// will be returned, otherwise returs the lastest installed version (if any).
  Map<String, dynamic> get _bestVisualStudioDetails {
    if (_usableVisualStudioDetails != null) {
      return _usableVisualStudioDetails;
    }
    return _anyVisualStudioDetails;
  }
}

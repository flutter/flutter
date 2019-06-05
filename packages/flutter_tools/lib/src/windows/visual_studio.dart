// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
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

  /// The 'catalog' entry containing more details.
  static const String _catalogKey = 'catalog';

  /// The user-friendly version.
  ///
  /// This key is under the 'catalog' entry.
  static const String _catalogDisplayVersionKey = 'productDisplayVersion';

  /// Returns the details dictionary for the newest version of Visual Studio
  /// that includes all of [requiredComponents], if there is one.
  Map<String, dynamic> _visualStudioDetails({Iterable<String> requiredComponents}) {
    final List<String> requirementArguments = requiredComponents == null
        ? <String>[]
        : <String>['-requires', ...requiredComponents];
    try {
      final ProcessResult whereResult = processManager.runSync(<String>[
        _vswherePath,
        '-format', 'json',
        '-utf8',
        '-latest',
        ...?requirementArguments,
      ]);
      if (whereResult.exitCode == 0) {
        final List<Map<String, dynamic>> installations = json.decode(whereResult.stdout)
            .cast<Map<String, dynamic>>();
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

  /// Returns the details dictionary for the latest version of Visual Studio
  /// that has all required components.
  Map<String, dynamic> _cachedUsableVisualStudioDetails;
  Map<String, dynamic> get _usableVisualStudioDetails {
    _cachedUsableVisualStudioDetails ??=
        _visualStudioDetails(requiredComponents: _requiredComponents().keys);
    return _cachedUsableVisualStudioDetails;
  }

  /// Returns the details dictionary of the latest version of Visual Studio,
  /// regardless of components.
  Map<String, dynamic> _cachedAnyVisualStudioDetails;
  Map<String, dynamic> get _anyVisualStudioDetails {
    _cachedAnyVisualStudioDetails ??= _visualStudioDetails();
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

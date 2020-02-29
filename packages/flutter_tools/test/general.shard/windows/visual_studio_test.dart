// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show ProcessException;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/windows/visual_studio.dart';

import '../../commands.shard/permeable/upgrade_test.dart';
import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  const String programFilesPath = r'C:\Program Files (x86)';
  const String visualStudioPath = programFilesPath + r'\Microsoft Visual Studio\2017\Community';
  const String vcvarsPath = visualStudioPath + r'\VC\Auxiliary\Build\vcvars64.bat';
  const String vswherePath = programFilesPath + r'\Microsoft Visual Studio\Installer\vswhere.exe';

  final Platform windowsPlatform = FakePlatform(
    operatingSystem: 'windows',
    environment: <String, String>{
      'PROGRAMFILES(X86)': r'C:\Program Files (x86)\',
    }
  );
  FakeProcessManager processManager;
  FileSystem fileSystem;
  Logger logger;

  // A minimum version of a response where a VS installation was found.
  const Map<String, dynamic> _defaultResponse = <String, dynamic>{
    'installationPath': visualStudioPath,
    'displayName': 'Visual Studio Community 2019',
    'installationVersion': '16.2.29306.81',
    'isRebootRequired': false,
    'isComplete': true,
    'isLaunchable': true,
    'isPrerelease': false,
    'catalog': <String, dynamic>{
      'productDisplayVersion': '16.2.5',
    },
  };

  // A response for a VS installation that's too old.
  const Map<String, dynamic> _tooOldResponse = <String, dynamic>{
    'installationPath': visualStudioPath,
    'displayName': 'Visual Studio Community 2017',
    'installationVersion': '15.9.28307.665',
    'isRebootRequired': false,
    'isComplete': true,
    'isLaunchable': true,
    'isPrerelease': false,
    'catalog': <String, dynamic>{
      'productDisplayVersion': '15.9.12',
    },
  };

  // A version of a response that doesn't include certain installation status
  // information that might be missing in older vswhere.
  const Map<String, dynamic> _missingStatusResponse = <String, dynamic>{
    'installationPath': visualStudioPath,
    'displayName': 'Visual Studio Community 2017',
    'installationVersion': '16.4.29609.76',
    'catalog': <String, dynamic>{
      'productDisplayVersion': '16.4.1',
    },
  };

  // Arguments for a vswhere query to search for an installation with the required components.
  const List<String> _requiredComponents = <String>[
    'Microsoft.Component.MSBuild',
    'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
    'Microsoft.VisualStudio.Component.Windows10SDK.17763',
  ];

  // Sets up the mock environment so that searching for Visual Studio with
  // exactly the given required components will provide a result. By default it
  // return a preset installation, but the response can be overridden.
  void setMockVswhereResponse([
    List<String> requiredComponents,
    List<String> additionalArguments,
    Map<String, dynamic> response,
    String responseOverride,
  ]) {
    fileSystem.file(vswherePath).createSync(recursive: true);
    fileSystem.file(vcvarsPath).createSync(recursive: true);
    final String finalResponse = responseOverride ??
        json.encode(<Map<String, dynamic>>[response]);
    final List<String> requirementArguments = requiredComponents == null
        ? <String>[]
        : <String>['-requires', ...requiredComponents];

    processManager.addCommand(FakeCommand(
      command: <String>[
        vswherePath,
        '-format',
        'json',
        '-utf8',
        '-latest',
        ...?additionalArguments,
        ...?requirementArguments,
      ],
      stdout: finalResponse,
    ));
  }

  // Sets whether or not a vswhere query with the required components will
  // return an installation.
  void setMockCompatibleVisualStudioInstallation(Map<String, dynamic> response) {
    setMockVswhereResponse(_requiredComponents, <String>['-version', '16'], response);
  }

  // Sets whether or not a vswhere query with the required components will
  // return a pre-release installation.
  void setMockPrereleaseVisualStudioInstallation(Map<String, dynamic> response) {
    setMockVswhereResponse(_requiredComponents, <String>['-version', '16', '-prerelease'], response);
  }

  // Sets whether or not a vswhere query searching for 'all' and 'prerelease'
  // versions will return an installation.
  void setMockAnyVisualStudioInstallation(Map<String, dynamic> response) {
    setMockVswhereResponse(null, <String>['-prerelease', '-all'], response);
  }

  // Set a pre-encoded query result.
  void setMockEncodedAnyVisualStudioInstallation(String response) {
    setMockVswhereResponse(null, <String>['-prerelease', '-all'], null, response);
  }

  group('Visual Studio', () {
    VisualStudio visualStudio;

    setUp(() {
      processManager = FakeProcessManager.list(<FakeCommand>[]);
      fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);
      logger = MockLogger();
      visualStudio = VisualStudio(
        fileSystem: fileSystem,
        platform: windowsPlatform,
        logger: logger,
        processManager: processManager,
      );
    });

    testWithoutContext('isInstalled returns false when vswhere is missing', () {
      final MockProcessManager mockProcessManager = MockProcessManager();
      when(mockProcessManager.runSync(
        any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenThrow(const ProcessException('vswhere', <String>[]));
      visualStudio = VisualStudio(
        logger: logger,
        fileSystem: fileSystem,
        platform: windowsPlatform,
        processManager: mockProcessManager,
      );

      expect(visualStudio.isInstalled, false);
    });

    testWithoutContext('vcvarsPath returns null when vswhere is missing', () {
      final MockProcessManager mockProcessManager = MockProcessManager();
      when(mockProcessManager.runSync(
        any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenThrow(const ProcessException('vswhere', <String>[]));
      visualStudio = VisualStudio(
        logger: logger,
        fileSystem: fileSystem,
        platform: windowsPlatform,
        processManager: mockProcessManager,
      );

      expect(visualStudio.vcvarsPath, isNull);
    });

    testWithoutContext('isInstalled returns false when vswhere returns non-zero', () {
      final MockProcessManager mockProcessManager = MockProcessManager();
      when(mockProcessManager.runSync(
        any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((Invocation invocation) {
        return FakeProcessResult()
        ..exitCode = 1
        ..stderr = ''
        ..stdout = '';
      });
      visualStudio = VisualStudio(
        logger: logger,
        fileSystem: fileSystem,
        platform: windowsPlatform,
        processManager: mockProcessManager,
      );

      expect(visualStudio.isInstalled, false);
      expect(visualStudio.isInstalled, false);
    });

    testWithoutContext('VisualStudio getters return the right values if no installation is found', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(null);

      expect(visualStudio.isInstalled, false);
      expect(visualStudio.isAtLeastMinimumVersion, false);
      expect(visualStudio.hasNecessaryComponents, false);
      expect(visualStudio.isComplete, false);
      expect(visualStudio.isRebootRequired, false);
      expect(visualStudio.isLaunchable, false);
      expect(visualStudio.displayName, null);
      expect(visualStudio.displayVersion, null);
      expect(visualStudio.installLocation, null);
      expect(visualStudio.fullVersion, null);
    });

    testWithoutContext('necessaryComponentDescriptions suggest the right VS tools on major version 16', () {
      setMockCompatibleVisualStudioInstallation(_defaultResponse);

      final String toolsString = visualStudio.necessaryComponentDescriptions()[1];

      expect(toolsString.contains('v142'), true);
    });

    testWithoutContext('necessaryComponentDescriptions suggest the right VS tools on an old version', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(_tooOldResponse);

      final String toolsString = visualStudio.necessaryComponentDescriptions()[1];

      expect(toolsString.contains('v142'), true);
    });

    testWithoutContext('isInstalled returns true even with missing status information', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(_missingStatusResponse);

      expect(visualStudio.isInstalled, true);
    });

    testWithoutContext('isInstalled returns true when VS is present but missing components', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(_defaultResponse);

      expect(visualStudio.isInstalled, true);
    });

    testWithoutContext('isInstalled returns true when VS is present but too old', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(_tooOldResponse);

      expect(visualStudio.isInstalled, true);
    });

    testWithoutContext('isInstalled returns true when a prerelease version of VS is present', () {
      final Map<String, dynamic> response = Map<String, dynamic>.from(_defaultResponse)
        ..['isPrerelease'] = true;
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(response);
      setMockAnyVisualStudioInstallation(null);

      expect(visualStudio.isInstalled, true);
      expect(visualStudio.isPrerelease, true);
    });

    testWithoutContext('isAtLeastMinimumVersion returns false when the version found is too old', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(_tooOldResponse);

      expect(visualStudio.isInstalled, true);
      expect(visualStudio.isAtLeastMinimumVersion, false);
    });

    testWithoutContext('isComplete returns false when an incomplete installation is found', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);

      final Map<String, dynamic> response = Map<String, dynamic>.from(_defaultResponse)
        ..['isComplete'] = false;
      setMockAnyVisualStudioInstallation(response);

      expect(visualStudio.isInstalled, true);
      expect(visualStudio.isComplete, false);
    });

    testWithoutContext("isLaunchable returns false if the installation can't be launched", () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);

      final Map<String, dynamic> response = Map<String, dynamic>.from(_defaultResponse)
        ..['isLaunchable'] = false;
      setMockAnyVisualStudioInstallation(response);

      expect(visualStudio.isInstalled, true);
      expect(visualStudio.isLaunchable, false);
    });

    testWithoutContext('isRebootRequired returns true if the installation needs a reboot', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);

      final Map<String, dynamic> response = Map<String, dynamic>.from(_defaultResponse)
        ..['isRebootRequired'] = true;
      setMockAnyVisualStudioInstallation(response);

      expect(visualStudio.isInstalled, true);
      expect(visualStudio.isRebootRequired, true);
    });


    testWithoutContext('hasNecessaryComponents returns false when VS is present but missing components', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(_defaultResponse);

      expect(visualStudio.hasNecessaryComponents, false);
    });

    testWithoutContext('vcvarsPath returns null when VS is present but missing components', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(_defaultResponse);

      expect(visualStudio.vcvarsPath, isNull);
    });

    testWithoutContext('vcvarsPath returns null when VS is present but with require components but installation is faulty', () {
      final Map<String, dynamic> response = Map<String, dynamic>.from(_defaultResponse)
        ..['isRebootRequired'] = true;
      setMockCompatibleVisualStudioInstallation(response);
      setMockPrereleaseVisualStudioInstallation(null);

      expect(visualStudio.vcvarsPath, isNull);
    });

    testWithoutContext('hasNecessaryComponents returns false when VS is present with required components but installation is faulty', () {
      final Map<String, dynamic> response = Map<String, dynamic>.from(_defaultResponse)
        ..['isRebootRequired'] = true;
      setMockCompatibleVisualStudioInstallation(response);
      setMockPrereleaseVisualStudioInstallation(null);

      expect(visualStudio.hasNecessaryComponents, false);
    });

    testWithoutContext('VS metadata is available when VS is present, even if missing components', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(_defaultResponse);

      expect(visualStudio.displayName, equals('Visual Studio Community 2019'));
      expect(visualStudio.displayVersion, equals('16.2.5'));
      expect(visualStudio.installLocation, equals(visualStudioPath));
      expect(visualStudio.fullVersion, equals('16.2.29306.81'));
    });

    testWithoutContext('vcvarsPath returns null when VS is present but when vswhere returns invalid JSON', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockEncodedAnyVisualStudioInstallation('{');

      expect(visualStudio.vcvarsPath, isNull);
    });

    testWithoutContext('Everything returns good values when VS is present with all components', () {
      setMockCompatibleVisualStudioInstallation(_defaultResponse);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(null);

      expect(visualStudio.isInstalled, true);
      expect(visualStudio.isAtLeastMinimumVersion, true);
      expect(visualStudio.hasNecessaryComponents, true);
      expect(visualStudio.vcvarsPath, equals(vcvarsPath));
    });

    testWithoutContext('Metadata is for compatible version when latest is missing components', () {
      // Return a different version for queries without the required packages.
      final Map<String, dynamic> olderButCompleteVersionResponse = <String, dynamic>{
        'installationPath': visualStudioPath,
        'displayName': 'Visual Studio Community 2017',
        'installationVersion': '15.9.28307.665',
        'catalog': <String, dynamic>{
          'productDisplayVersion': '15.9.12',
        },
      };

      setMockCompatibleVisualStudioInstallation(olderButCompleteVersionResponse);
      setMockPrereleaseVisualStudioInstallation(null);
      // Return a different version for queries without the required packages.
      final Map<String, dynamic> incompleteVersionResponse = <String, dynamic>{
        'installationPath': visualStudioPath,
        'displayName': 'Visual Studio Community 2019',
        'installationVersion': '16.1.1.1',
        'catalog': <String, String>{
          'productDisplayVersion': '16.1',
        },
      };
      setMockAnyVisualStudioInstallation(incompleteVersionResponse);

      expect(visualStudio.displayName, equals('Visual Studio Community 2017'));
      expect(visualStudio.displayVersion, equals('15.9.12'));
    });
  });
}

class MockLogger extends Mock implements Logger {}

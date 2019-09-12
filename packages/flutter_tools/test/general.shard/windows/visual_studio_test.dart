// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show ProcessException, ProcessResult;
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/windows/visual_studio.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> environment = <String, String>{};
}
class MockProcessManager extends Mock implements ProcessManager {}
class MockProcessResult extends Mock implements ProcessResult {}

void main() {
  const String programFilesPath = r'C:\Program Files (x86)';
  const String visualStudioPath = programFilesPath + r'\Microsoft Visual Studio\2017\Community';
  const String vcvarsPath = visualStudioPath + r'\VC\Auxiliary\Build\vcvars64.bat';
  const String vswherePath = programFilesPath + r'\Microsoft Visual Studio\Installer\vswhere.exe';

  final MockPlatform windowsPlatform = MockPlatform()
      ..environment['PROGRAMFILES(X86)'] = r'C:\Program Files (x86)\';
  MockProcessManager mockProcessManager;
  final MemoryFileSystem memoryFilesystem = MemoryFileSystem(style: FileSystemStyle.windows);

  // A minimum version of a response where a VS installation was found.
  const Map<String, dynamic> _defaultResponse = <String, dynamic>{
    'installationPath': visualStudioPath,
    'displayName': 'Visual Studio Community 2017',
    'installationVersion': '15.9.28307.665',
    'isRebootRequired': false,
    'isComplete': true,
    'isLaunchable': true,
    'isPrerelease': false,
    'catalog': <String, dynamic>{
      'productDisplayVersion': '15.9.12',
    }
  };

  // A version of a response that doesn't include certain installation status
  // information that might be missing in older Visual Studio versions.
  const Map<String, dynamic> _oldResponse = <String, dynamic>{
    'installationPath': visualStudioPath,
    'displayName': 'Visual Studio Community 2017',
    'installationVersion': '15.9.28307.665',
    'catalog': <String, dynamic>{
      'productDisplayVersion': '15.9.12',
    }
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
  void setMockVswhereResponse(
      [List<String> requiredComponents,
      List<String> additionalArguments,
      Map<String, dynamic> response]) {
    fs.file(vswherePath).createSync(recursive: true);
    fs.file(vcvarsPath).createSync(recursive: true);

    final MockProcessResult result = MockProcessResult();
    when(result.exitCode).thenReturn(0);

    final String finalResponse =
        json.encode(<Map<String, dynamic>>[response]);
    when<String>(result.stdout).thenReturn(finalResponse);
    when<String>(result.stderr).thenReturn('');
    final List<String> requirementArguments = requiredComponents == null
        ? <String>[]
        : <String>['-requires', ...requiredComponents];
    when(mockProcessManager.runSync(
      <String>[
        vswherePath,
          '-format',
          'json',
          '-utf8',
          '-latest',
          ...?additionalArguments,
          ...?requirementArguments,
      ],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenAnswer((Invocation invocation) {
      return result;
    });
  }

  // Sets whether or not a vswhere query with the required components will
  // return an installation.
  void setMockCompatibleVisualStudioInstallation(Map<String, dynamic>response) {
    setMockVswhereResponse(_requiredComponents, null, response);
  }

  // Sets whether or not a vswhere query with the required components will
  // return a pre-release installation.
  void setMockPrereleaseVisualStudioInstallation(Map<String, dynamic>response) {
    setMockVswhereResponse(_requiredComponents, <String>['-prerelease'], response);
  }

  // Sets whether or not a vswhere query searching for 'all' and 'prerelease'
  // versions will return an installation.
  void setMockAnyVisualStudioInstallation(Map<String, dynamic>response) {
    setMockVswhereResponse(null, <String>['-prerelease', '-all'], response);
  }

  group('Visual Studio', () {
    VisualStudio visualStudio;

    setUp(() {
      mockProcessManager = MockProcessManager();
    });

    testUsingContext('isInstalled returns false when vswhere is missing', () {
      when(mockProcessManager.runSync(
        any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenThrow(const ProcessException('vswhere', <String>[]));

      visualStudio = VisualStudio();
      expect(visualStudio.isInstalled, false);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('vcvarsPath returns null when vswhere is missing', () {
      when(mockProcessManager.runSync(
        any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenThrow(const ProcessException('vswhere', <String>[]));

      visualStudio = VisualStudio();
      expect(visualStudio.vcvarsPath, isNull);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('isInstalled returns false when vswhere returns non-zero', () {

      when(mockProcessManager.runSync(
        any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenThrow(const ProcessException('vswhere', <String>[]));

      final MockProcessResult result = MockProcessResult();
      when(result.exitCode).thenReturn(1);
      when(mockProcessManager.runSync(
        any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((Invocation invocation) {
        return result;
      });
      when<String>(result.stdout).thenReturn('');
      when<String>(result.stderr).thenReturn('');

      visualStudio = VisualStudio();
      expect(visualStudio.isInstalled, false);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('isInstalled returns true even with missing status information', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(_oldResponse);

      visualStudio = VisualStudio();
      expect(visualStudio.isInstalled, true);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('isInstalled returns true when VS is present but missing components', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(_defaultResponse);

      visualStudio = VisualStudio();
      expect(visualStudio.isInstalled, true);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('isInstalled returns true when a prerelease version of VS is present', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(null);

      final Map<String, dynamic> response = Map<String, dynamic>.from(_defaultResponse)
        ..['isPrerelease'] = true;
      setMockPrereleaseVisualStudioInstallation(response);

      visualStudio = VisualStudio();
      expect(visualStudio.isInstalled, true);
      expect(visualStudio.isPrerelease, true);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('isComplete returns false when an incomplete installation is found', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);

      final Map<String, dynamic> response = Map<String, dynamic>.from(_defaultResponse)
        ..['isComplete'] = false;
      setMockAnyVisualStudioInstallation(response);

      visualStudio = VisualStudio();
      expect(visualStudio.isInstalled, true);
      expect(visualStudio.isComplete, false);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('isLaunchable returns false if the installation can\'t be launched', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);

      final Map<String, dynamic> response = Map<String, dynamic>.from(_defaultResponse)
        ..['isLaunchable'] = false;
      setMockAnyVisualStudioInstallation(response);

      visualStudio = VisualStudio();
      expect(visualStudio.isInstalled, true);
      expect(visualStudio.isLaunchable, false);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('isRebootRequired returns true if the installation needs a reboot', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);

      final Map<String, dynamic> response = Map<String, dynamic>.from(_defaultResponse)
        ..['isRebootRequired'] = true;
      setMockAnyVisualStudioInstallation(response);

      visualStudio = VisualStudio();
      expect(visualStudio.isInstalled, true);
      expect(visualStudio.isRebootRequired, true);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });


    testUsingContext('hasNecessaryComponents returns false when VS is present but missing components', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(_defaultResponse);

      visualStudio = VisualStudio();
      expect(visualStudio.hasNecessaryComponents, false);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('vcvarsPath returns null when VS is present but missing components', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(_defaultResponse);

      visualStudio = VisualStudio();
      expect(visualStudio.vcvarsPath, isNull);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('vcvarsPath returns null when VS is present but with require components but installation is faulty', () {
      final Map<String, dynamic> response = Map<String, dynamic>.from(_defaultResponse)
        ..['isRebootRequired'] = true;
      setMockCompatibleVisualStudioInstallation(response);
      setMockPrereleaseVisualStudioInstallation(null);

      visualStudio = VisualStudio();
      expect(visualStudio.vcvarsPath, isNull);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('hasNecessaryComponents returns false when VS is present with required components but installation is faulty', () {
      final Map<String, dynamic> response = Map<String, dynamic>.from(_defaultResponse)
        ..['isRebootRequired'] = true;
      setMockCompatibleVisualStudioInstallation(response);
      setMockPrereleaseVisualStudioInstallation(null);

      visualStudio = VisualStudio();
      expect(visualStudio.hasNecessaryComponents, false);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('VS metadata is available when VS is present, even if missing components', () {
      setMockCompatibleVisualStudioInstallation(null);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(_defaultResponse);

      visualStudio = VisualStudio();
      expect(visualStudio.displayName, equals('Visual Studio Community 2017'));
      expect(visualStudio.displayVersion, equals('15.9.12'));
      expect(visualStudio.installLocation, equals(visualStudioPath));
      expect(visualStudio.fullVersion, equals('15.9.28307.665'));
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('Everything returns good values when VS is present with all components', () {
      setMockCompatibleVisualStudioInstallation(_defaultResponse);
      setMockPrereleaseVisualStudioInstallation(null);
      setMockAnyVisualStudioInstallation(null);

      visualStudio = VisualStudio();
      expect(visualStudio.isInstalled, true);
      expect(visualStudio.hasNecessaryComponents, true);
      expect(visualStudio.vcvarsPath, equals(vcvarsPath));
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('Metadata is for compatible version when latest is missing components', () {
      setMockCompatibleVisualStudioInstallation(_defaultResponse);
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

      visualStudio = VisualStudio();
      expect(visualStudio.displayName, equals('Visual Studio Community 2017'));
      expect(visualStudio.displayVersion, equals('15.9.12'));
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });
  });
}

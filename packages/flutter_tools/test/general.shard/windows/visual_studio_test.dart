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

  // Sets up the mock environment so that searching for Visual Studio with
  // exactly the given required components will provide a result. By default it
  // return a preset installation, but the response can be overridden.
  void setMockVswhereResponse([List<String> requiredComponents, String response]) {
    fs.file(vswherePath).createSync(recursive: true);
    fs.file(vcvarsPath).createSync(recursive: true);

    final MockProcessResult result = MockProcessResult();
    when(result.exitCode).thenReturn(0);
    when<String>(result.stdout).thenReturn(response ??
      json.encode(<Map<String, dynamic>>[
        <String, dynamic>{
          'installationPath': visualStudioPath,
          'displayName': 'Visual Studio Community 2017',
          'installationVersion': '15.9.28307.665',
          'catalog': <String, String>{
            'productDisplayVersion': '15.9.12',
          },
        },
      ]));

    final List<String> requirementArguments = requiredComponents == null
        ? <String>[]
        : <String>['-requires', ...requiredComponents];
    when(mockProcessManager.runSync(<String>[
      vswherePath,
        '-format', 'json',
        '-utf8',
        '-latest',
        ...?requirementArguments,
    ])).thenAnswer((Invocation invocation) {
      return result;
    });
  }

  // Sets whether or not a vswhere query without components will return an
  // installation.
  void setMockIncompleteVisualStudioExists(bool exists) {
    setMockVswhereResponse(null, exists ? null : '[]');
  }

  // Sets whether or not a vswhere query with the required components will
  // return an installation.
  void setMockCompatibleVisualStudioExists(bool exists) {
    setMockVswhereResponse(<String>[
      'Microsoft.Component.MSBuild',
      'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
      'Microsoft.VisualStudio.Component.Windows10SDK.17763',
    ], exists ? null : '[]');
  }

  group('Visual Studio', () {
    VisualStudio visualStudio;

    setUp(() {
      mockProcessManager = MockProcessManager();
    });

    testUsingContext('isInstalled returns false when vswhere is missing', () {
      when(mockProcessManager.runSync(any))
          .thenThrow(const ProcessException('vswhere', <String>[]));

      visualStudio = VisualStudio();
      expect(visualStudio.isInstalled, false);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('vcvarsPath returns null when vswhere is missing', () {
      when(mockProcessManager.runSync(any))
          .thenThrow(const ProcessException('vswhere', <String>[]));

      visualStudio = VisualStudio();
      expect(visualStudio.vcvarsPath, isNull);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('isInstalled returns false when vswhere returns non-zero', () {
      when(mockProcessManager.runSync(any))
          .thenThrow(const ProcessException('vswhere', <String>[]));
          final MockProcessResult result = MockProcessResult();
      when(result.exitCode).thenReturn(1);
      when(mockProcessManager.runSync(any)).thenAnswer((Invocation invocation) {
        return result;
      });

      visualStudio = VisualStudio();
      expect(visualStudio.isInstalled, false);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('isInstalled returns true when VS is present but missing components', () {
      setMockIncompleteVisualStudioExists(true);
      setMockCompatibleVisualStudioExists(false);

      visualStudio = VisualStudio();
      expect(visualStudio.isInstalled, true);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('hasNecessaryComponents returns false when VS is present but missing components', () {
      setMockIncompleteVisualStudioExists(true);
      setMockCompatibleVisualStudioExists(false);

      visualStudio = VisualStudio();
      expect(visualStudio.hasNecessaryComponents, false);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('vcvarsPath returns null when VS is present but missing components', () {
      setMockIncompleteVisualStudioExists(true);
      setMockCompatibleVisualStudioExists(false);

      visualStudio = VisualStudio();
      expect(visualStudio.vcvarsPath, isNull);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('VS metadata is available when VS is present, even if missing components', () {
      setMockIncompleteVisualStudioExists(true);
      setMockCompatibleVisualStudioExists(false);

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


    testUsingContext('isInstalled returns true when VS is present but missing components', () {
      setMockIncompleteVisualStudioExists(true);
      setMockCompatibleVisualStudioExists(false);

      visualStudio = VisualStudio();
      expect(visualStudio.isInstalled, true);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFilesystem,
      Platform: () => windowsPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('Everything returns good values when VS is present with all components', () {
      setMockCompatibleVisualStudioExists(true);

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
      setMockCompatibleVisualStudioExists(true);
      // Return a different version for queries without the required packages.
      final String incompleteVersionResponse = json.encode(<Map<String, dynamic>>[
          <String, dynamic>{
            'installationPath': visualStudioPath,
            'displayName': 'Visual Studio Community 2019',
            'installationVersion': '16.1.1.1',
            'catalog': <String, String>{
              'productDisplayVersion': '16.1',
            },
          }
      ]);
      setMockVswhereResponse(null, incompleteVersionResponse);

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

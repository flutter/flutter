// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';

const String kExampleManifest = r'''
<?xml version="1.0" encoding="utf-8"?>
<Package
  xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
  xmlns:mp="http://schemas.microsoft.com/appx/2014/phone/manifest"
  xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
  IgnorableNamespaces="uap mp">

  <Identity Name="@PACKAGE_GUID@" Publisher="CN=CMake Test Cert" Version="2.3.1.4" />
  <mp:PhoneIdentity PhoneProductId="@PACKAGE_GUID@" PhonePublisherId="00000000-0000-0000-0000-000000000000"/>

  <Properties>
    <DisplayName>@SHORT_NAME@</DisplayName>
    <PublisherDisplayName>CMake Test Cert</PublisherDisplayName>
    <Logo>Assets/StoreLogo.png</Logo>
  </Properties>

  <Dependencies>
    <TargetDeviceFamily Name="Windows.Universal" MinVersion="10.0.0.0" MaxVersionTested="10.0.65535.65535" />
  </Dependencies>

  <Resources>
    <Resource Language="x-generate" />
  </Resources>
  <Applications>
    <Application Id="App" Executable="$targetnametoken$.exe" EntryPoint="@SHORT_NAME@.App">
      <uap:VisualElements
        DisplayName="@SHORT_NAME@"
        Description="@SHORT_NAME@"
        BackgroundColor="#336699"
        Square150x150Logo="Assets/Square150x150Logo.png"
        Square44x44Logo="Assets/Square44x44Logo.png"
        >
        <uap:SplashScreen Image="Assets/SplashScreen.png" />
      </uap:VisualElements>
    </Application>
  </Applications>
   <Capabilities>
    <Capability Name="internetClientServer"/>
    <Capability Name="internetClient"/>
    <Capability Name="privateNetworkClientServer"/>
    <Capability Name="codeGeneration"/></Capabilities>
</Package>
''';

void main() {
  testWithoutContext('Project can parse the app version from the appx manifest', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.file('winuwp/runner_uwp/appxmanifest.in')
      ..createSync(recursive: true)
      ..writeAsStringSync(kExampleManifest);

    final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

    expect(flutterProject.windowsUwp.packageVersion, '2.3.1.4');
  });

  testWithoutContext('Project returns null if appx manifest does not exist', () {
    final FileSystem fileSystem = MemoryFileSystem.test();

    final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

    expect(flutterProject.windowsUwp.packageVersion, null);
  });

  testWithoutContext('Project throws a tool exit if appxmanifest is not valid xml', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.file('winuwp/runner_uwp/appxmanifest.in')
      ..createSync(recursive: true)
      ..writeAsStringSync('[');

    final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

    expect(() => flutterProject.windowsUwp.packageVersion, throwsToolExit());
  });

  testWithoutContext('Can parse the PACKAGE_GUID from the Cmake manifest', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.file('winuwp/runner_uwp/CMakeLists.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
cmake_minimum_required (VERSION 3.8)
set(CMAKE_SYSTEM_NAME WindowsStore)
set(CMAKE_SYSTEM_VERSION 10.0)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

include(CMakePrintHelpers)

project ("TestBedUWP")

set(APP_MANIFEST_NAME Package.appxmanifest)
set(APP_MANIFEST_TARGET_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/${APP_MANIFEST_NAME})
set(SHORT_NAME ${BINARY_NAME})
set(PACKAGE_GUID "F941A77F-8AE1-4E3E-9611-68FBD3C62AE8")

''');

    final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

    expect(flutterProject.windowsUwp.packageGuid, 'F941A77F-8AE1-4E3E-9611-68FBD3C62AE8');
  });

  testWithoutContext('Returns null if the PACKAGE_GUID cannot be found in the Cmake file', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.file('winuwp/runner_uwp/CMakeLists.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
cmake_minimum_required (VERSION 3.8)
set(CMAKE_SYSTEM_NAME WindowsStore)
set(CMAKE_SYSTEM_VERSION 10.0)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

include(CMakePrintHelpers)

project ("TestBedUWP")

set(APP_MANIFEST_NAME Package.appxmanifest)
set(APP_MANIFEST_TARGET_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/${APP_MANIFEST_NAME})
set(SHORT_NAME ${BINARY_NAME})
''');

    final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

    expect(flutterProject.windowsUwp.packageGuid, null);
  });
}

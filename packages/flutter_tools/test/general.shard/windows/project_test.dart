// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

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
    fileSystem.file('winuwp/appxmanifest.in')
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
    fileSystem.file('winuwp/appxmanifest.in')
      ..createSync(recursive: true)
      ..writeAsStringSync('[');

    final FlutterProject flutterProject = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

    expect(() => flutterProject.windowsUwp.packageVersion, throwsToolExit());
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/windows/visual_studio_project.dart';

import '../../src/common.dart';

void main() {
  group('Visual Studio Project', () {
    String generateProjectContents({String guid, String name}) {
      // A bare-bones project.
      return '''
<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" ToolsVersion="15.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ItemGroup Label="ProjectConfigurations">
    <ProjectConfiguration Include="Debug|x64">
      <Configuration>Debug</Configuration>
      <Platform>x64</Platform>
    </ProjectConfiguration>
    <ProjectConfiguration Include="Release|x64">
      <Configuration>Release</Configuration>
      <Platform>x64</Platform>
    </ProjectConfiguration>
  </ItemGroup>
  <PropertyGroup Label="Globals">
    <VCProjectVersion>15.0</VCProjectVersion>
    ${guid == null ? '' : '<ProjectGuid>{$guid}</ProjectGuid>'}
    ${name == null ? '' : '<ProjectName>$name</ProjectName>'}
    <WindowsTargetPlatformVersion>10.0</WindowsTargetPlatformVersion>
  </PropertyGroup>
  <Import Project="\$(VCTargetsPath)\\Microsoft.Cpp.Default.props" />
  <PropertyGroup Label="Configuration">
    <PlatformToolset>v142</PlatformToolset>
  </PropertyGroup>
  <Import Project="\$(VCTargetsPath)\\Microsoft.Cpp.props" />
  <ImportGroup Label="ExtensionSettings">
  </ImportGroup>
  <ImportGroup Label="Shared">
  </ImportGroup>
  <ImportGroup Label="PropertySheets" />
  <PropertyGroup Label="UserMacros" />
  <PropertyGroup />
  <ItemDefinitionGroup />
  <ItemGroup>
  </ItemGroup>
  <Import Project="\$(VCTargetsPath)\\Microsoft.Cpp.targets" />
  <ImportGroup Label="ExtensionTargets">
  </ImportGroup>
</Project>''';
    }

    test('Property extraction works on a simple vcxproj', () async {
      final FileSystem fileSystem = MemoryFileSystem();
      const String guid = '017C4BAC-FEBA-406D-8A2C-3099FFE9D811';
      const String name = 'Test';
      final File projectFile = fileSystem.file('aproject.vcxproj');
      projectFile.writeAsStringSync(generateProjectContents(guid: guid, name: name));

      final VisualStudioProject project = VisualStudioProject(projectFile, fileSystem: fileSystem);
      expect(project.formatUnderstood, true);
      expect(project.guid, guid);
      expect(project.name, name);
    });

    test('Missing GUID returns null', () async {
      final FileSystem fileSystem = MemoryFileSystem();
      final File projectFile = fileSystem.file('aproject.vcxproj');
      projectFile.writeAsStringSync(generateProjectContents());

      final VisualStudioProject project = VisualStudioProject(projectFile, fileSystem: fileSystem);
      expect(project.formatUnderstood, true);
      expect(project.guid, null);
    });

    test('Missing project name uses filename', () async {
      final FileSystem fileSystem = MemoryFileSystem();
      final File projectFile = fileSystem.file('aproject.vcxproj');
      projectFile.writeAsStringSync(generateProjectContents());

      final VisualStudioProject project = VisualStudioProject(projectFile, fileSystem: fileSystem);
      expect(project.formatUnderstood, true);
      expect(project.name, 'aproject');
    });

    test('Unknown file contents creates an object, and return false for formatUnderstood', () async {
      final FileSystem fileSystem = MemoryFileSystem();
      final File projectFile = fileSystem.file('aproject.vcxproj');
      projectFile.writeAsStringSync('This is not XML!');

      final VisualStudioProject project = VisualStudioProject(projectFile, fileSystem: fileSystem);
      expect(project.formatUnderstood, false);
    });

    test('Missing project file throws on creation', () async {
      final FileSystem fileSystem = MemoryFileSystem();
      final File projectFile = fileSystem.file('aproject.vcxproj');

      expect(() => VisualStudioProject(projectFile, fileSystem: fileSystem), throwsFileSystemException());
    });
  });
}

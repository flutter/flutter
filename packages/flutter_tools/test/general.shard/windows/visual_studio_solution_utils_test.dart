// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/windows/visual_studio_solution_utils.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';

void main() {
  group('Visual Studio Solution Utils', () {
    // Magic values; see visual_studio_solution_utils.dart.
    const String solutionTypeGuidFolder = '2150E333-8FDC-42A3-9474-1A3956D46DE8';
    const String solutionTypeGuidVcxproj = '8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942';
    const String flutterPluginSolutionFolderGuid = '5C2E738A-1DD3-445A-AAC8-EEB9648DD07C';

    // Arbitrary random GUIDs to use for fake plugins.
    const String pluginAGuid = '9F200BC4-A747-43D1-8B72-B778F2C4D048';
    const String pluginBGuid = '39AC79B8-28A6-4526-B5FF-9C83F59B3AF0';
    const String pluginCGuid = '8E010714-28FF-416A-BC6F-9CDE336A02A7';
    const String pluginDGuid = '304F1860-7E8B-4C99-8E1D-F5E55259F5C3';

    FileSystem fileSystem;
    MockWindowsProject project;

    setUp(() async {
      fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);

      project = MockWindowsProject();
      when(project.pluginConfigKey).thenReturn('windows');
      final Directory windowsManagedDirectory = fileSystem.directory('C:').childDirectory('windows').childDirectory('flutter');
      when(project.solutionFile).thenReturn(windowsManagedDirectory.parent.childFile('Runner.sln'));
      when(project.vcprojFile).thenReturn(windowsManagedDirectory.parent.childFile('Runner.vcxproj'));
      when(project.pluginSymlinkDirectory).thenReturn(windowsManagedDirectory.childDirectory('ephemeral').childDirectory('.plugin_symlinks'));
    });

    // Returns a solution file contents for a solution without any plugins.
    void writeSolutionWithoutPlugins() {
      project.solutionFile.createSync(recursive: true);
      project.solutionFile.writeAsStringSync('''
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio Version 16
VisualStudioVersion = 16.0.29709.97
MinimumVisualStudioVersion = 10.0.40219.1
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "Runner", "Runner.vcxproj", "{3842E94C-E348-463A-ADBE-625A2B69B628}"
	ProjectSection(ProjectDependencies) = postProject
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F} = {6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}
	EndProjectSection
EndProject
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "Flutter Build", "FlutterBuild.vcxproj", "{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}"
EndProject
Global
	GlobalSection(SolutionConfigurationPlatforms) = preSolution
		Debug|x64 = Debug|x64
		Profile|x64 = Profile|x64
		Release|x64 = Release|x64
	EndGlobalSection
	GlobalSection(ProjectConfigurationPlatforms) = postSolution
		{3842E94C-E348-463A-ADBE-625A2B69B628}.Debug|x64.ActiveCfg = Debug|x64
		{3842E94C-E348-463A-ADBE-625A2B69B628}.Debug|x64.Build.0 = Debug|x64
		{3842E94C-E348-463A-ADBE-625A2B69B628}.Profile|x64.ActiveCfg = Profile|x64
		{3842E94C-E348-463A-ADBE-625A2B69B628}.Profile|x64.Build.0 = Profile|x64
		{3842E94C-E348-463A-ADBE-625A2B69B628}.Release|x64.ActiveCfg = Release|x64
		{3842E94C-E348-463A-ADBE-625A2B69B628}.Release|x64.Build.0 = Release|x64
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}.Debug|x64.ActiveCfg = Debug|x64
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}.Debug|x64.Build.0 = Debug|x64
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}.Profile|x64.ActiveCfg = Profile|x64
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}.Profile|x64.Build.0 = Profile|x64
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}.Release|x64.ActiveCfg = Release|x64
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}.Release|x64.Build.0 = Release|x64
	EndGlobalSection
	GlobalSection(SolutionProperties) = preSolution
		HideSolutionNode = FALSE
	EndGlobalSection
	GlobalSection(ExtensibilityGlobals) = postSolution
		SolutionGuid = {B8A69CB0-A974-4774-9EBD-1E5EECACD186}
	EndGlobalSection
EndGlobal''');
    }

    // Returns a solution file contents for a solution with plugins A, B, and C
    // already added.
    void writeSolutionWithPlugins() {
      const String pluginSymlinkSubdirPath = r'Flutter\ephemeral\.plugin_symlinks';
      const String pluginProjectSubpath = r'windows\plugin.vcxproj';
      project.solutionFile.createSync(recursive: true);
      project.solutionFile.writeAsStringSync('''
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio Version 16
VisualStudioVersion = 16.0.29709.97
MinimumVisualStudioVersion = 10.0.40219.1
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "Runner", "Runner.vcxproj", "{5A827760-CF8B-408A-99A3-B6C0AD2271E7}"
	ProjectSection(ProjectDependencies) = postProject
		{$pluginAGuid} = {$pluginAGuid}
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F} = {6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}
		{$pluginBGuid} = {$pluginBGuid}
		{$pluginCGuid} = {$pluginCGuid}
	EndProjectSection
EndProject
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "plugin_a", "$pluginSymlinkSubdirPath\\plugin_a\\$pluginProjectSubpath", "{$pluginAGuid}"
	ProjectSection(ProjectDependencies) = postProject
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F} = {6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}
	EndProjectSection
EndProject
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "Flutter Build", "FlutterBuild.vcxproj", "{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}"
EndProject
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "plugin_b", "$pluginSymlinkSubdirPath\\plugin_b\\$pluginProjectSubpath", "{$pluginBGuid}"
	ProjectSection(ProjectDependencies) = postProject
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F} = {6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}
	EndProjectSection
EndProject
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "plugin_c", "$pluginSymlinkSubdirPath\\plugin_c\\$pluginProjectSubpath", "{$pluginCGuid}"
	ProjectSection(ProjectDependencies) = postProject
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F} = {6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}
	EndProjectSection
EndProject
Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "Flutter Plugins", "Flutter Plugins", "{5C2E738A-1DD3-445A-AAC8-EEB9648DD07C}"
EndProject
Global
	GlobalSection(SolutionConfigurationPlatforms) = preSolution
		Debug|x64 = Debug|x64
		Profile|x64 = Profile|x64
		Release|x64 = Release|x64
	EndGlobalSection
	GlobalSection(ProjectConfigurationPlatforms) = postSolution
		{5A827760-CF8B-408A-99A3-B6C0AD2271E7}.Debug|x64.ActiveCfg = Debug|x64
		{5A827760-CF8B-408A-99A3-B6C0AD2271E7}.Debug|x64.Build.0 = Debug|x64
		{5A827760-CF8B-408A-99A3-B6C0AD2271E7}.Profile|x64.ActiveCfg = Profile|x64
		{5A827760-CF8B-408A-99A3-B6C0AD2271E7}.Profile|x64.Build.0 = Profile|x64
		{5A827760-CF8B-408A-99A3-B6C0AD2271E7}.Release|x64.ActiveCfg = Release|x64
		{5A827760-CF8B-408A-99A3-B6C0AD2271E7}.Release|x64.Build.0 = Release|x64
		{$pluginAGuid}.Debug|x64.ActiveCfg = Debug|x64
		{$pluginAGuid}.Debug|x64.Build.0 = Debug|x64
		{$pluginAGuid}.Profile|x64.ActiveCfg = Profile|x64
		{$pluginAGuid}.Profile|x64.Build.0 = Profile|x64
		{$pluginAGuid}.Release|x64.ActiveCfg = Release|x64
		{$pluginAGuid}.Release|x64.Build.0 = Release|x64
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}.Debug|x64.ActiveCfg = Debug|x64
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}.Debug|x64.Build.0 = Debug|x64
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}.Profile|x64.ActiveCfg = Profile|x64
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}.Profile|x64.Build.0 = Profile|x64
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}.Release|x64.ActiveCfg = Release|x64
		{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}.Release|x64.Build.0 = Release|x64
		{$pluginBGuid}.Debug|x64.ActiveCfg = Debug|x64
		{$pluginBGuid}.Debug|x64.Build.0 = Debug|x64
		{$pluginBGuid}.Profile|x64.ActiveCfg = Profile|x64
		{$pluginBGuid}.Profile|x64.Build.0 = Profile|x64
		{$pluginBGuid}.Release|x64.ActiveCfg = Release|x64
		{$pluginBGuid}.Release|x64.Build.0 = Release|x64
		{$pluginCGuid}.Debug|x64.ActiveCfg = Debug|x64
		{$pluginCGuid}.Debug|x64.Build.0 = Debug|x64
		{$pluginCGuid}.Profile|x64.ActiveCfg = Profile|x64
		{$pluginCGuid}.Profile|x64.Build.0 = Profile|x64
		{$pluginCGuid}.Release|x64.ActiveCfg = Release|x64
		{$pluginCGuid}.Release|x64.Build.0 = Release|x64
	EndGlobalSection
	GlobalSection(SolutionProperties) = preSolution
		HideSolutionNode = FALSE
	EndGlobalSection
	GlobalSection(NestedProjects) = preSolution
		{$pluginCGuid} = {$flutterPluginSolutionFolderGuid}
		{$pluginBGuid} = {$flutterPluginSolutionFolderGuid}
		{$pluginAGuid} = {$flutterPluginSolutionFolderGuid}
	EndGlobalSection
	GlobalSection(ExtensibilityGlobals) = postSolution
		SolutionGuid = {6C8A8041-10D8-4BEB-B73D-C02BCE62120B}
	EndGlobalSection
EndGlobal''');
    }

    void writeDummyPluginProject(String pluginName, String guid) {
      final File pluginProjectFile = project.pluginSymlinkDirectory
          .childDirectory(pluginName)
          .childDirectory('windows')
          .childFile('plugin.vcxproj');
      pluginProjectFile.createSync(recursive: true);
      pluginProjectFile.writeAsStringSync('''
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
    <ProjectGuid>{$guid}</ProjectGuid>
    <ProjectName>$pluginName</ProjectName>
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
</Project>''');
    }

    // Configures and returns a mock plugin with the given name and GUID in the
    // project's plugin symlink directory.
    Plugin getMockPlugin(String name, String guid, {bool createProject = true}) {
      final MockPlugin plugin = MockPlugin();
      when(plugin.platforms).thenReturn(<String, PluginPlatform>{project.pluginConfigKey: null});
      when(plugin.name).thenReturn(name);
      when(plugin.path).thenReturn(project.pluginSymlinkDirectory.childDirectory(name).path);
      if (createProject) {
        writeDummyPluginProject(name, guid);
      }
      return plugin;
    }

    test('Adding the first plugin to a solution adds the expected references', () async {
      writeSolutionWithoutPlugins();

      final List<Plugin> plugins = <Plugin>[
        getMockPlugin('plugin_a', pluginAGuid),
      ];
      await VisualStudioSolutionUtils(project: project, fileSystem: fileSystem).updatePlugins(plugins);

      final String newSolutionContents = project.solutionFile.readAsStringSync();

      // Check for:
      // - Plugin project.
      final String pluginSubpath = fileSystem.path.join('Flutter', 'ephemeral', '.plugin_symlinks', 'plugin_a', 'windows', 'plugin.vcxproj');
      expect(newSolutionContents, contains('Project("{$solutionTypeGuidVcxproj}") = "plugin_a", "$pluginSubpath", "{$pluginAGuid}"'));
      // - A dependency on the plugin project (from the Runner).
      expect(newSolutionContents, contains('{$pluginAGuid} = {$pluginAGuid}'));
      // - Plugin project configurations.
      expect(newSolutionContents, contains('{$pluginAGuid}.Debug|x64.ActiveCfg = Debug|x64'));
      expect(newSolutionContents, contains('{$pluginAGuid}.Debug|x64.Build.0 = Debug|x64'));
      expect(newSolutionContents, contains('{$pluginAGuid}.Profile|x64.ActiveCfg = Profile|x64'));
      expect(newSolutionContents, contains('{$pluginAGuid}.Profile|x64.Build.0 = Profile|x64'));
      expect(newSolutionContents, contains('{$pluginAGuid}.Release|x64.ActiveCfg = Release|x64'));
      expect(newSolutionContents, contains('{$pluginAGuid}.Release|x64.Build.0 = Release|x64'));
      // - A plugin folder, and a child reference for the plugin.
      expect(newSolutionContents, contains('Project("{$solutionTypeGuidFolder}") = "Flutter Plugins", "Flutter Plugins", "{$flutterPluginSolutionFolderGuid}"'));
      expect(newSolutionContents, contains('{$pluginAGuid} = {$flutterPluginSolutionFolderGuid}'));
    });

    test('Removing a plugin removes entries as expected', () async {
      writeSolutionWithPlugins();

      final List<Plugin> plugins = <Plugin>[
        getMockPlugin('plugin_a', pluginAGuid),
        getMockPlugin('plugin_c', pluginCGuid),
      ];
      await VisualStudioSolutionUtils(project: project, fileSystem: fileSystem).updatePlugins(plugins);

      final String newSolutionContents = project.solutionFile.readAsStringSync();

      // There should be no references to plugin B anywhere.
      expect(newSolutionContents.contains(pluginBGuid), false);

      // All the plugin A & C references should still be present in modified
      // sections.
      for (final String guid in <String>[pluginAGuid, pluginCGuid]) {
        expect(newSolutionContents, contains('{$guid} = {$guid}'));
        expect(newSolutionContents, contains('{$guid}.Debug|x64.ActiveCfg = Debug|x64'));
        expect(newSolutionContents, contains('{$guid} = {$flutterPluginSolutionFolderGuid}'));
      }
    });

    test('Removing all plugins works', () async {
      writeSolutionWithPlugins();

      final List<Plugin> plugins = <Plugin>[
      ];
      await VisualStudioSolutionUtils(project: project, fileSystem: fileSystem).updatePlugins( plugins);

      final String newSolutionContents = project.solutionFile.readAsStringSync();

      // There should be no references to any of the plugins.
      expect(newSolutionContents.contains(pluginAGuid), false);
      expect(newSolutionContents.contains(pluginBGuid), false);
      expect(newSolutionContents.contains(pluginCGuid), false);
      // Nor any plugins in the Flutter Plugins folder.
      expect(newSolutionContents.contains('= {$flutterPluginSolutionFolderGuid}'), false);
    });

    test('Adjusting the plugin list by adding and removing adjusts entries as expected', () async {
      writeSolutionWithPlugins();

      final List<Plugin> plugins = <Plugin>[
        getMockPlugin('plugin_b', pluginBGuid),
        getMockPlugin('plugin_c', pluginCGuid),
        getMockPlugin('plugin_d', pluginDGuid),
      ];
      await VisualStudioSolutionUtils(project: project, fileSystem: fileSystem).updatePlugins(plugins);

      final String newSolutionContents = project.solutionFile.readAsStringSync();

      // There should be no references to plugin A anywhere.
      expect(newSolutionContents.contains(pluginAGuid), false);

      // All the plugin B & C references should still be present in modified
      // sections.
      for (final String guid in <String>[pluginBGuid, pluginCGuid]) {
        expect(newSolutionContents, contains('{$guid} = {$guid}'));
        expect(newSolutionContents, contains('{$guid}.Debug|x64.ActiveCfg = Debug|x64'));
        expect(newSolutionContents, contains('{$guid} = {$flutterPluginSolutionFolderGuid}'));
      }

      // All the plugin D values should be added:
      // - Plugin project.
      final String pluginSubpath = fileSystem.path.join('Flutter', 'ephemeral', '.plugin_symlinks', 'plugin_d', 'windows', 'plugin.vcxproj');
      expect(newSolutionContents, contains('Project("{$solutionTypeGuidVcxproj}") = "plugin_d", "$pluginSubpath", "{$pluginDGuid}"'));
      // - A dependency on the plugin project (from the Runner).
      expect(newSolutionContents, contains('{$pluginDGuid} = {$pluginDGuid}'));
      // - Plugin project configurations.
      expect(newSolutionContents, contains('{$pluginDGuid}.Debug|x64.ActiveCfg = Debug|x64'));
      expect(newSolutionContents, contains('{$pluginDGuid}.Debug|x64.Build.0 = Debug|x64'));
      expect(newSolutionContents, contains('{$pluginDGuid}.Profile|x64.ActiveCfg = Profile|x64'));
      expect(newSolutionContents, contains('{$pluginDGuid}.Profile|x64.Build.0 = Profile|x64'));
      expect(newSolutionContents, contains('{$pluginDGuid}.Release|x64.ActiveCfg = Release|x64'));
      expect(newSolutionContents, contains('{$pluginDGuid}.Release|x64.Build.0 = Release|x64'));
      // - A child reference for the plugin in the Flutter Plugins folder.
      expect(newSolutionContents, contains('{$pluginDGuid} = {$flutterPluginSolutionFolderGuid}'));
    });

    test('Adding plugins doesn\'t create duplicate entries', () async {
      writeSolutionWithPlugins();

      final List<Plugin> plugins = <Plugin>[
        getMockPlugin('plugin_a', pluginAGuid),
        getMockPlugin('plugin_b', pluginBGuid),
        getMockPlugin('plugin_c', pluginCGuid),
        getMockPlugin('plugin_d', pluginDGuid),
      ];
      await VisualStudioSolutionUtils(project: project, fileSystem: fileSystem).updatePlugins(plugins);

      final String newSolutionContents = project.solutionFile.readAsStringSync();
      // There should only be:
      // - one Flutter Plugins folder.
      expect('Project("{$solutionTypeGuidFolder}")'.allMatches(newSolutionContents).length, 1);
      // - one copy of plugin A's project.
      expect('Project("{$solutionTypeGuidVcxproj}") = "plugin_a"'.allMatches(newSolutionContents).length, 1);
      // - one copy of plugin A's configuration entries.
      expect('{$pluginAGuid}.Debug|x64.ActiveCfg = Debug|x64'.allMatches(newSolutionContents).length, 1);
      // - one dependency from the Runner to plugin A.
      expect('{$pluginAGuid} = {$pluginAGuid}'.allMatches(newSolutionContents).length, 1);
      // - one copy of plugin A in Flutter Plugins.
      expect('{$pluginAGuid} = {$flutterPluginSolutionFolderGuid}'.allMatches(newSolutionContents).length, 1);
    });

    test('Adding plugins doesn\'t change ordering', () async {
      writeSolutionWithPlugins();

      final List<Plugin> plugins = <Plugin>[
        getMockPlugin('plugin_a', pluginAGuid),
        getMockPlugin('plugin_b', pluginBGuid),
        getMockPlugin('plugin_c', pluginCGuid),
        getMockPlugin('plugin_d', pluginDGuid),
      ];
      await VisualStudioSolutionUtils(project: project, fileSystem: fileSystem).updatePlugins(plugins);

      final String newSolutionContents = project.solutionFile.readAsStringSync();
      // Plugin A should still be before Flutter Build in the Runner dependencies.
      expect(newSolutionContents.indexOf('{$pluginAGuid} = {$pluginAGuid}'),
          lessThan(newSolutionContents.indexOf('{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F} = {6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}')));
      // ... and in the build configuration list.
      expect(newSolutionContents.indexOf('{$pluginAGuid}.Debug|x64.ActiveCfg = Debug|x64'),
          lessThan(newSolutionContents.indexOf('{6419BF13-6ECD-4CD2-9E85-E566A1F03F8F}.Debug|x64.ActiveCfg = Debug|x64')));
      // And plugin C should still be before plugin A in the Flutter Plugins nesting list.
      expect(newSolutionContents.indexOf('{$pluginCGuid} = {$flutterPluginSolutionFolderGuid}'),
          lessThan(newSolutionContents.indexOf('{$pluginAGuid} = {$flutterPluginSolutionFolderGuid}')));
    });

    test('Updating solution preserves BOM', () async {
      writeSolutionWithPlugins();

      final List<Plugin> plugins = <Plugin>[];
      await VisualStudioSolutionUtils(project: project, fileSystem: fileSystem).updatePlugins(plugins);

      // Visual Studio expects sln files to start with a BOM.
      final List<int> solutionStartingBytes = project.solutionFile.readAsBytesSync().take(3).toList();
      final List<int> bomBytes = utf8.encode(String.fromCharCode(unicodeBomCharacterRune));
      expect(solutionStartingBytes, bomBytes);
    });

    test('Updating solution dosen\'t introduce unexpected whitespace', () async {
      writeSolutionWithPlugins();

      final List<Plugin> plugins = <Plugin>[
        getMockPlugin('plugin_a', pluginAGuid),
        getMockPlugin('plugin_b', pluginBGuid),
      ];
      await VisualStudioSolutionUtils(project: project, fileSystem: fileSystem).updatePlugins(plugins);

      final String newSolutionContents = project.solutionFile.readAsStringSync();
      // Project, EndProject, Global, and EndGlobal should be at the start of
      // lines.
      expect(RegExp(r'^[ \t]+Project\(', multiLine: true).hasMatch(newSolutionContents), false);
      expect(RegExp(r'^[ \t]+EndProject\s*$', multiLine: true).hasMatch(newSolutionContents), false);
      expect(RegExp(r'^[ \t]+Global\s*$', multiLine: true).hasMatch(newSolutionContents), false);
      expect(RegExp(r'^[ \t]+EndGlobal\s*$', multiLine: true).hasMatch(newSolutionContents), false);
      // ProjectSection, GlobalSection, and their ends should be indented
      // exactly one tab.
      expect(RegExp(r'^([ \t]+\t|\t[ \t]+)ProjectSection\(', multiLine: true).hasMatch(newSolutionContents), false);
      expect(RegExp(r'^([ \t]+\t|\t[ \t]+)EndProjectSection\s*$', multiLine: true).hasMatch(newSolutionContents), false);
      expect(RegExp(r'^([ \t]+\t|\t[ \t]+)GlobalSection\(\s*$', multiLine: true).hasMatch(newSolutionContents), false);
      expect(RegExp(r'^([ \t]+\t|\t[ \t]+)EndGlobalSection\s*$', multiLine: true).hasMatch(newSolutionContents), false);
    });

    test('A plugin without a project exits without crashing', () async {
      writeSolutionWithoutPlugins();

      final List<Plugin> plugins = <Plugin>[
        getMockPlugin('plugin_a', pluginAGuid, createProject: false),
      ];
      expect(() => VisualStudioSolutionUtils(project: project, fileSystem: fileSystem).updatePlugins(plugins),
        throwsToolExit());
    });

    test('A Windows project with a missing Runner.sln file throws a ToolExit', () async {
      final MockWindowsProject windowsProject = MockWindowsProject();
      final File file = fileSystem.file('does_not_exist');

      expect(file, isNot(exists));

      when(windowsProject.solutionFile).thenReturn(file);

      expect(() async => await VisualStudioSolutionUtils(project: project, fileSystem: fileSystem)
        .updatePlugins(<Plugin>[]), throwsToolExit());
    });
  });
}

class MockWindowsProject extends Mock implements WindowsProject {}
class MockPlugin extends Mock implements Plugin {}

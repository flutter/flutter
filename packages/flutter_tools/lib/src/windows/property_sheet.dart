// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:xml/xml.dart' as xml;

/// A utility class for building property sheet (.props) files for use
/// with MSBuild/Visual Studio projects.
class PropertySheet {
  /// Creates a PropertySheet with the given properties.
  const PropertySheet({
    this.environmentVariables,
    this.includePaths,
    this.libraryDependencies,
  });

  /// Variables to make available both as build macros and as environment
  /// variables for script steps.
  final Map<String, String> environmentVariables;

  /// Directories to search for headers.
  final List<String> includePaths;

  /// Libraries to link against.
  final List<String> libraryDependencies;

  @override
  String toString() {
    // See https://docs.microsoft.com/en-us/cpp/build/reference/vcxproj-file-structure#property-sheet-layout

    final xml.XmlBuilder builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="utf-8"');
    builder.element('Project', nest: () {
      builder.attribute('ToolsVersion', '4.0');
      builder.attribute(
          'xmlns', 'http://schemas.microsoft.com/developer/msbuild/2003');

      builder.element('ImportGroup', nest: () {
        builder.attribute('Label', 'PropertySheets');
      });
      builder.element('PropertyGroup', nest: () {
        builder.attribute('Label', 'UserMacros');

        _addEnviromentVariableUserMacros(builder);
      });
      builder.element('PropertyGroup');
      builder.element('ItemDefinitionGroup', nest: () {
        _addIncludePaths(builder);
        _addLibraryDependencies(builder);
      });
      builder.element('ItemGroup', nest: () {
        _addEnvironmentVariableBuildMacros(builder);
      });
    });

    return builder.build().toXmlString(pretty: true, indent: '  ');
  }

  /// Adds directories to the header search path.
  ///
  /// Must be called within the context of the ItemDefinitionGroup.
  void _addIncludePaths(xml.XmlBuilder builder) {
    if (includePaths == null || includePaths.isEmpty) {
      return;
    }
    builder.element('ClCompile', nest: () {
      builder.element('AdditionalIncludeDirectories', nest: () {
        builder.text('${includePaths.join(';')};%(AdditionalIncludeDirectories)');
      });
    });
  }

  /// Adds libraries to the link step.
  ///
  /// Must be called within the context of the ItemDefinitionGroup.
  void _addLibraryDependencies(xml.XmlBuilder builder) {
    if (libraryDependencies == null || libraryDependencies.isEmpty) {
      return;
    }
    builder.element('Link', nest: () {
      builder.element('AdditionalDependencies', nest: () {
        builder.text('${libraryDependencies.join(';')};%(AdditionalDependencies)');
      });
    });
  }

  /// Writes key/value pairs for any environment variables as user macros.
  ///
  /// Must be called within the context of the UserMacros PropertyGroup.
  void _addEnviromentVariableUserMacros(xml.XmlBuilder builder) {
    if (environmentVariables == null) {
      return;
    }
    for (final MapEntry<String, String> variable in environmentVariables.entries) {
      builder.element(variable.key, nest: () {
        builder.text(variable.value);
      });
    }
  }

  /// Writes the BuildMacros to expose environment variable UserMacros to the
  /// environment.
  ///
  /// Must be called within the context of the ItemGroup.
  void _addEnvironmentVariableBuildMacros(xml.XmlBuilder builder) {
    if (environmentVariables == null) {
      return;
    }
    for (final String name in environmentVariables.keys) {
      builder.element('BuildMacro', nest: () {
        builder.attribute('Include', name);
        builder.element('Value', nest: () {
          builder.text('\$($name)');
        });
        builder.element('EnvironmentVariable', nest: () {
          builder.text('true');
        });
      });
    }
  }
}

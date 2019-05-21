// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file

import 'package:xml/xml.dart' as xml;

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';

/// The supported versions of Visual Studio.
const List<String> _visualStudioVersions = <String>['2017', '2019'];

/// The supported flavors of Visual Studio.
const List<String> _visualStudioFlavors = <String>[
  'Community',
  'Professional',
  'Enterprise',
  'Preview'
];

/// Returns the path to an installed vcvars64.bat script if found, or null.
Future<String> findVcvars() async {
  final String programDir = platform.environment['PROGRAMFILES(X86)'];
  final String pathPrefix = fs.path.join(programDir, 'Microsoft Visual Studio');
  const String vcvarsScriptName = 'vcvars64.bat';
  final String pathSuffix =
      fs.path.join('VC', 'Auxiliary', 'Build', vcvarsScriptName);
  for (final String version in _visualStudioVersions) {
    for (final String flavor in _visualStudioFlavors) {
      final String testPath =
          fs.path.join(pathPrefix, version, flavor, pathSuffix);
      if (fs.file(testPath).existsSync()) {
        return testPath;
      }
    }
  }

  // If it can't be found manually, check the path.
  final ProcessResult whereResult = await processManager.run(<String>[
    'where.exe',
    vcvarsScriptName,
  ]);
  if (whereResult.exitCode == 0) {
    return whereResult.stdout.trim();
  }

  return null;
}

/// Writes a property sheet (.props) file to expose all of the key/value
/// pairs in [variables] as enivornment variables.
void writePropertySheet(File propertySheetFile, Map<String, String> variables) {
  final xml.XmlBuilder builder = xml.XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="utf-8"');
  builder.element('Project', nest: () {
    builder.attribute('ToolsVersion', '4.0');
    builder.attribute(
        'xmlns', 'http://schemas.microsoft.com/developer/msbuild/2003');
    builder.element('ImportGroup', nest: () {
      builder.attribute('Label', 'PropertySheets');
    });
    _addUserMacros(builder, variables);
    builder.element('PropertyGroup');
    builder.element('ItemDefinitionGroup');
    _addItemGroup(builder, variables);
  });

  propertySheetFile.createSync(recursive: true);
  propertySheetFile.writeAsStringSync(
      builder.build().toXmlString(pretty: true, indent: '  '));
}

/// Adds the UserMacros PropertyGroup that defines [variables] to [builder].
void _addUserMacros(xml.XmlBuilder builder, Map<String, String> variables) {
  builder.element('PropertyGroup', nest: () {
    builder.attribute('Label', 'UserMacros');
    for (final MapEntry<String, String> variable in variables.entries) {
      builder.element(variable.key, nest: () {
        builder.text(variable.value);
      });
    }
  });
}

/// Adds the ItemGroup to expose the given [variables] as environment variables
/// to [builder].
void _addItemGroup(xml.XmlBuilder builder, Map<String, String> variables) {
  builder.element('ItemGroup', nest: () {
    for (final String name in variables.keys) {
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
  });
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:xml/xml.dart' as xml;

import '../base/file_system.dart';

/// Writes a property sheet (.props) file to expose all of the key/value
/// pairs in [variables] as environment variables.
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

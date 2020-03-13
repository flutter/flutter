// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/windows/property_sheet.dart';

import '../../src/common.dart';

void main() {
  group('Property Sheet', () {
    test('Base file matches expected format', () async {
      const String baseFile = '''
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ImportGroup Label="PropertySheets"/>
  <PropertyGroup Label="UserMacros"/>
  <PropertyGroup/>
  <ItemDefinitionGroup/>
  <ItemGroup/>
</Project>''';
      const PropertySheet sheet = PropertySheet();
      expect(sheet.toString(), baseFile);
    });

    test('Environment variable generate the correct elements', () async {
      const Map<String, String> environment = <String, String>{'FOO': 'Bar'};
      const PropertySheet sheet = PropertySheet(environmentVariables: environment);
      final String propsContent = sheet.toString();
      expect(propsContent, contains('<FOO>Bar</FOO>'));
      expect(propsContent, contains('''
    <BuildMacro Include="FOO">
      <Value>\$(FOO)</Value>
      <EnvironmentVariable>true</EnvironmentVariable>
    </BuildMacro>'''));
    });

    test('Include paths generate the correct elements', () async {
      const PropertySheet sheet = PropertySheet(includePaths: <String>['foo/bar', 'baz']);
      final String propsContent = sheet.toString();
      expect(propsContent, contains('<AdditionalIncludeDirectories>foo/bar;baz;%(AdditionalIncludeDirectories)</AdditionalIncludeDirectories>'));
    });

    test('Library dependencies generate the correct elements', () async {
      const PropertySheet sheet = PropertySheet(libraryDependencies: <String>['foo.lib', 'bar.lib']);
      final String propsContent = sheet.toString();
      expect(propsContent, contains('<AdditionalDependencies>foo.lib;bar.lib;%(AdditionalDependencies)</AdditionalDependencies>'));
    });
  });
}

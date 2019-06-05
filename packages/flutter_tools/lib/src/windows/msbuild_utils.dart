// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file

import 'package:xml/xml.dart' as xml;

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../globals.dart';

/// Returns the path to an installed vcvars64.bat script if found, or null.
Future<String> findVcvars() async {
  final String vswherePath = fs.path.join(
    platform.environment['PROGRAMFILES(X86)'],
    'Microsoft Visual Studio',
    'Installer',
    'vswhere.exe',
  );
  // The "Desktop development with C++" workload. This is a coarse check, since
  // it doesn't validate that the specific pieces are available, but should be
  // a reasonable first-pass approximation.
  // In the future, a set of more targetted checks will be used to provide
  // clear validation feedback (e.g., VS is installed, but missing component X).
  const String requiredComponent = 'Microsoft.VisualStudio.Workload.NativeDesktop';

  const String visualStudioInstallMessage =
      'Ensure that you have Visual Studio 2017 or later installed, including '
      'the "Desktop development with C++" workload.';

  if (!fs.file(vswherePath).existsSync()) {
    printError(
      'Unable to locate Visual Studio: vswhere.exe not found\n'
      '$visualStudioInstallMessage',
      emphasis: true,
    );
    return null;
  }

  final ProcessResult whereResult = await processManager.run(<String>[
    vswherePath,
    '-latest',
    '-requires', requiredComponent,
    '-property', 'installationPath',
  ]);
  if (whereResult.exitCode != 0) {
    printError(
      'Unable to locate Visual Studio:\n'
      '${whereResult.stdout}\n'
      '$visualStudioInstallMessage',
      emphasis: true,
    );
    return null;
  }
  final String visualStudioPath = whereResult.stdout.trim();
  if (visualStudioPath.isEmpty) {
    printError(
      'No suitable Visual Studio found. $visualStudioInstallMessage\n',
      emphasis: true,
    );
    return null;
  }
  final String vcvarsPath =
      fs.path.join(visualStudioPath, 'VC', 'Auxiliary', 'Build', 'vcvars64.bat');
  if (!fs.file(vcvarsPath).existsSync()) {
    printError(
      'vcvars64.bat does not exist at $vcvarsPath.\n',
      emphasis: true,
    );
    return null;
  }

  return vcvarsPath;
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

// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as dart_io;

import 'package:file/file.dart';
import 'package:file/local.dart' as io;
import 'package:path/path.dart' as path;

import 'utils.dart';

const String _kProvisioningConfigFileEnvironmentVariable = 'FLUTTER_DEVICELAB_XCODE_PROVISIONING_CONFIG';
const String _kTestXcconfigFileName = 'TestConfig.xcconfig';
const FileSystem _fs = io.LocalFileSystem();

/// Patches the given Xcode project adding provisioning certificates and team
/// information required to build and run the project, if
/// FLUTTER_DEVICELAB_XCODE_PROVISIONING_CONFIG is set. If it is not set,
/// we rely on automatic signing by Xcode.
Future<void> prepareProvisioningCertificates(String flutterProjectPath) async {
  final String certificateConfig = await _readProvisioningConfigFile();
  if (certificateConfig == null) {
    // No cert config available, rely on automatic signing by Xcode.
    return;
  }

  await _patchXcconfigFilesIfNotPatched(flutterProjectPath);
  final File testXcconfig = _fs.file(path.join(flutterProjectPath, 'ios/Flutter/$_kTestXcconfigFileName'));
  await testXcconfig.writeAsString(certificateConfig);
}

Future<void> runPodInstallForCustomPodfile(String flutterProjectPath) async {
  final String iosPath = path.join(flutterProjectPath, 'ios');
  exec('pod', <String>['install', '--project-directory=$iosPath']);
}

Future<void> _patchXcconfigFilesIfNotPatched(String flutterProjectPath) async {
  final List<File> xcconfigFiles = <File>[
    _fs.file(path.join(flutterProjectPath, 'ios/Flutter/Flutter.xcconfig')),
    _fs.file(path.join(flutterProjectPath, 'ios/Flutter/Debug.xcconfig')),
    _fs.file(path.join(flutterProjectPath, 'ios/Flutter/Release.xcconfig'))
  ];

  bool xcconfigFileExists = false;

  for (final File file in xcconfigFiles) {
    if (await file.exists()) {
      xcconfigFileExists = true;
      const String include = '#include "$_kTestXcconfigFileName"';
      final String contents = await file.readAsString();
      final bool alreadyPatched = contents.contains(include);
      if (!alreadyPatched) {
        final IOSink patchOut = file.openWrite(mode: FileMode.append);
        patchOut.writeln(); // in case EOF is not preceded by line break
        patchOut.writeln(include);
        await patchOut.close();
      }
    }
  }

  if (!xcconfigFileExists) {
    final String candidatesFormatted = xcconfigFiles.map<String>((File f) => f.path).join(', ');
    throw 'Failed to locate a xcconfig file to patch with provisioning profile '
        'info. Tried: $candidatesFormatted';
  }
}

Future<String> _readProvisioningConfigFile() async {
  void throwUsageError(String specificMessage) {
    throw '''
================================================================================
You are attempting to build an XCode project, which requires a provisioning
certificate and team information. The test framework attempted to locate an
.xcconfig file whose path is defined by the environment variable
$_kProvisioningConfigFileEnvironmentVariable.

$specificMessage
================================================================================
'''.trim();
  }

  if (!dart_io.Platform.environment.containsKey(_kProvisioningConfigFileEnvironmentVariable)) {
    print('''
$_kProvisioningConfigFileEnvironmentVariable variable is not defined in your
environment. Relying on automatic signing by Xcode...
'''.trim());
    return null;
  }

  final String filePath = dart_io.Platform.environment[_kProvisioningConfigFileEnvironmentVariable];
  final File file = _fs.file(filePath);
  if (!(await file.exists())) {
    throwUsageError('''
File not found: $filePath

It is defined by environment variable $_kProvisioningConfigFileEnvironmentVariable
'''.trim());
  }

  return file.readAsString();
}

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/file_system.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../template.dart';
import '../version.dart';

const String flutterVersion = 'v1.1.9';

class FlutterWrapperCommand extends FlutterCommand {
  FlutterWrapperCommand() {
    requiresPubspecYaml();
  }

  @override
  String get description => 'Generate flutter wrapper.';

  @override
  String get name => 'wrapper';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Directory directory = fs.currentDirectory;
    await generateFlutterWrapper(directory, overwrite: true);
    printStatus("Generate flutter wrapper in '${directory.path}'.");
    return null;
  }
}

Future<int> generateFlutterWrapper(Directory directory,
    {bool overwrite = false}) async {
  String version = FlutterVersion.instance.frameworkVersion;
  if (version == null || version == 'unknown' || version.isEmpty) {
    version = flutterVersion;
  }

  if (!version.startsWith('v')) {
    version = 'v' + version;
  }

  return _initializeFlutterWrapper(
      directory,
      <String, dynamic>{
        'flutterVersion': version,
      },
      overwrite: overwrite);
}

Future<int> _initializeFlutterWrapper(
    Directory directory, Map<String, dynamic> templateContext,
    {bool overwrite = false}) async {
  int generatedCount = 0;

  final String flutterWrapper = _locateFlutterExecutable(directory);
  if (flutterWrapper == null || overwrite) {
    generatedCount += _renderTemplate('wrapper', directory, templateContext,
        overwrite: overwrite);
    _locateFlutterExecutable(directory);
  }
  return generatedCount;
}

String _locateFlutterExecutable(Directory directory) {
  final File flutter = directory.childFile(
    platform.isWindows ? 'flutterw.bat' : 'flutterw',
  );

  if (flutter.existsSync()) {
    os.makeExecutable(flutter);
    return flutter.absolute.path;
  } else {
    return null;
  }
}

int _renderTemplate(
    String templateName, Directory directory, Map<String, dynamic> context,
    {bool overwrite = false}) {
  final Template template = Template.fromName(templateName);
  return template.render(directory, context, overwriteExisting: overwrite);
}

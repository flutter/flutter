// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Regenerates the material icons file.
// See https://github.com/flutter/flutter/wiki/Updating-Material-Design-Fonts

import 'dart:convert' show LineSplitter;
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

const String kOptionCodepointsPath = 'codepoints';
const String kOptionIconsPath = 'icons';
const String kOptionDryRun = 'dry-run';

const String kDefaultCodepointsPath = 'bin/cache/artifacts/material_fonts/codepoints';
const String kDefaultIconsPath = 'packages/flutter/lib/src/material/icons.dart';

const String kBeginGeneratedMark = '// BEGIN GENERATED';
const String kEndGeneratedMark = '// END GENERATED';

const Map<String, String> kIdentifierRewrites = const <String, String>{
  '360': 'threesixty',
  '3d_rotation': 'threed_rotation',
  '4k': 'four_k',
  'class': 'class_',
};

void main(List<String> args) {
  // If we're run from the `tools` dir, set the cwd to the repo root.
  if (path.basename(Directory.current.path) == 'tools')
    Directory.current = Directory.current.parent.parent;

  final ArgParser argParser = new ArgParser();
  argParser.addOption(kOptionCodepointsPath, defaultsTo: kDefaultCodepointsPath);
  argParser.addOption(kOptionIconsPath, defaultsTo: kDefaultIconsPath);
  argParser.addFlag(kOptionDryRun, defaultsTo: false);
  final ArgResults argResults = argParser.parse(args);

  final File iconFile = new File(path.absolute(argResults[kOptionIconsPath]));
  if (!iconFile.existsSync()) {
    stderr.writeln('Icons file not found: ${iconFile.path}');
    exit(1);
  }
  final File codepointsFile = new File(path.absolute(argResults[kOptionCodepointsPath]));
  if (!codepointsFile.existsSync()) {
    stderr.writeln('Codepoints file not found: ${codepointsFile.path}');
    exit(1);
  }

  final String iconData = iconFile.readAsStringSync();
  final String codepointData = codepointsFile.readAsStringSync();
  final String newIconData = regenerateIconsFile(iconData, codepointData);

  if (argResults[kOptionDryRun])
    stdout.writeln(newIconData);
  else
    iconFile.writeAsStringSync(newIconData);
}

String regenerateIconsFile(String iconData, String codepointData) {
  final StringBuffer buf = new StringBuffer();
  bool generating = false;
  for (String line in LineSplitter.split(iconData)) {
    if (!generating)
      buf.writeln(line);
    if (line.contains(kBeginGeneratedMark)) {
      generating = true;
      final String iconDeclarations = generateIconDeclarations(codepointData);
      buf.write(iconDeclarations);
    } else if (line.contains(kEndGeneratedMark)) {
      generating = false;
      buf.writeln(line);
    }
  }
  return buf.toString();
}

String generateIconDeclarations(String codepointData) {
  return LineSplitter.split(codepointData)
      .map((String l) => l.trim())
      .where((String l) => l.isNotEmpty)
      .map(getIconDeclaration)
      .join();
}

String getIconDeclaration(String line) {
  final List<String> tokens = line.split(' ');
  if (tokens.length != 2)
    throw new FormatException('Unexpected codepoint data: $line');
  final String name = tokens[0];
  final String codepoint = tokens[1];
  final String identifier = kIdentifierRewrites[name] ?? name;
  final String description = name.replaceAll('_', ' ');
  return '''

  /// <p><i class="material-icons md-36">$name</i> &#x2014; material icon named "$description".</p>
  static const IconData $identifier = const IconData(0x$codepoint, fontFamily: 'MaterialIcons');
''';
}

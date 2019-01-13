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

const Map<String, String> kIdentifierRewrites = <String, String>{
  '360': 'threesixty',
  '3d_rotation': 'threed_rotation',
  '1k': 'one_k',
  '2k': 'two_k',
  '3k': 'three_k',
  '4k': 'four_k',
  '5k': 'five_k',
  '6k': 'six_k',
  '7k': 'seven_k',
  '8k': 'eight_k',
  '9k': 'nine_k',
  '10k': 'ten_k',
  '1k_plus': 'one_k_plus',
  '2k_plus': 'two_k_plus',
  '3k_plus': 'three_k_plus',
  '4k_plus': 'four_k_plus',
  '5k_plus': 'five_k_plus',
  '6k_plus': 'six_k_plus',
  '7k_plus': 'seven_k_plus',
  '8k_plus': 'eight_k_plus',
  '9k_plus': 'nine_k_plus',
  '1mp': 'one_mp',
  '2mp': 'two_mp',
  '3mp': 'three_mp',
  '4mp': 'four_mp',
  '5mp': 'five_mp',
  '6mp': 'six_mp',
  '7mp': 'seven_mp',
  '8mp': 'eight_mp',
  '9mp': 'nine_mp',
  '10mp': 'ten_mp',
  '11mp': 'eleven_mp',
  '12mp': 'twelve_mp',
  '13mp': 'thirteen_mp',
  '14mp': 'fourteen_mp',
  '15mp': 'fifteen_mp',
  '16mp': 'sixteen_mp',
  '17mp': 'seventeen_mp',
  '18mp': 'eighteen_mp',
  '19mp': 'nineteen_mp',
  '20mp': 'twenty_mp',
  '21mp': 'twenty_one_mp',
  '22mp': 'twenty_two_mp',
  '23mp': 'twenty_three_mp',
  '24mp': 'twenty_four_mp',
  'class': 'class_',

};

final Set<String> kMirroredIcons = Set<String>.from(<String>[
  // This list is obtained from:
  // http://google.github.io/material-design-icons/#icons-in-rtl
  'arrow_back',
  'arrow_back_ios',
  'arrow_forward',
  'arrow_forward_ios',
  'arrow_left',
  'arrow_right',
  'assignment',
  'assignment_return',
  'backspace',
  'battery_unknown',
  'call_made',
  'call_merge',
  'call_missed',
  'call_missed_outgoing',
  'call_received',
  'call_split',
  'chevron_left',
  'chevron_right',
  'chrome_reader_mode',
  'device_unknown',
  'dvr',
  'event_note',
  'featured_play_list',
  'featured_video',
  'first_page',
  'flight_land',
  'flight_takeoff',
  'format_indent_decrease',
  'format_indent_increase',
  'format_list_bulleted',
  'forward',
  'functions',
  'help',
  'help_outline',
  'input',
  'keyboard_backspace',
  'keyboard_tab',
  'label',
  'label_important',
  'label_outline',
  'last_page',
  'launch',
  'list',
  'live_help',
  'mobile_screen_share',
  'multiline_chart',
  'navigate_before',
  'navigate_next',
  'next_week',
  'note',
  'open_in_new',
  'playlist_add',
  'queue_music',
  'redo',
  'reply',
  'reply_all',
  'screen_share',
  'send',
  'short_text',
  'show_chart',
  'sort',
  'star_half',
  'subject',
  'trending_flat',
  'toc',
  'trending_down',
  'trending_up',
  'undo',
  'view_list',
  'view_quilt',
  'wrap_text',
]);

void main(List<String> args) {
  // If we're run from the `tools` dir, set the cwd to the repo root.
  if (path.basename(Directory.current.path) == 'tools')
    Directory.current = Directory.current.parent.parent;

  final ArgParser argParser = ArgParser();
  argParser.addOption(kOptionCodepointsPath, defaultsTo: kDefaultCodepointsPath);
  argParser.addOption(kOptionIconsPath, defaultsTo: kDefaultIconsPath);
  argParser.addFlag(kOptionDryRun, defaultsTo: false);
  final ArgResults argResults = argParser.parse(args);

  final File iconFile = File(path.absolute(argResults[kOptionIconsPath]));
  if (!iconFile.existsSync()) {
    stderr.writeln('Icons file not found: ${iconFile.path}');
    exit(1);
  }
  final File codepointsFile = File(path.absolute(argResults[kOptionCodepointsPath]));
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
  final StringBuffer buf = StringBuffer();
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
      .map<String>((String l) => l.trim())
      .where((String l) => l.isNotEmpty)
      .map<String>(getIconDeclaration)
      .join();
}

String getIconDeclaration(String line) {
  final List<String> tokens = line.split(' ');
  if (tokens.length != 2)
    throw FormatException('Unexpected codepoint data: $line');
  final String name = tokens[0];
  final String codepoint = tokens[1];
  final String identifier = kIdentifierRewrites[name] ?? name;
  final String description = name.replaceAll('_', ' ');
  final String rtl = kMirroredIcons.contains(name) ? ', matchTextDirection: true' : '';
  return '''

  /// <i class="material-icons md-36">$name</i> &#x2014; material icon named "$description".
  static const IconData $identifier = IconData(0x$codepoint, fontFamily: 'MaterialIcons'$rtl);
''';
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Regenerates the material icons file.
// See https://github.com/flutter/flutter/wiki/Updating-Material-Design-Fonts

import 'dart:convert' show LineSplitter;
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

const String _newCodepointsPathOption = 'new-codepoints';
const String _oldCodepointsPathOption = 'old-codepoints';
const String _iconsClassPathOption = 'icons';
const String _dryRunOption = 'dry-run';

const String _defaultNewCodepointsPath = 'codepoints';
const String _defaultOldCodepointsPath = 'bin/cache/artifacts/material_fonts/codepoints';
const String _defaultIconsPath = 'packages/flutter/lib/src/material/icons.dart';

const String _beginGeneratedMark = '// BEGIN GENERATED';
const String _endGeneratedMark = '// END GENERATED';

const Map<String, String> _identifierRewrites = <String, String>{
  '360': 'threesixty',
  '3d_rotation': 'threed_rotation',
  '6_ft': 'six_ft',
  '5g': 'five_g',
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

const Set<String> _mirroredIcons = <String>{
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
};

void main(List<String> args) {
  // If we're run from the `tools` dir, set the cwd to the repo root.
  if (path.basename(Directory.current.path) == 'tools')
    Directory.current = Directory.current.parent.parent;

  final ArgResults argResults = _handleArguments(args);

  final File iconClassFile = File(path.normalize(path.absolute(argResults[_iconsClassPathOption] as String)));
  if (!iconClassFile.existsSync()) {
    stderr.writeln('Error: Icons file not found: ${iconClassFile.path}');
    exit(1);
  }
  final File newCodepointsFile = File(path.absolute(path.normalize(argResults[_newCodepointsPathOption] as String)));
  if (!newCodepointsFile.existsSync()) {
    stderr.writeln('Error: New codepoints file not found: ${newCodepointsFile.path}');
    exit(1);
  }
  final File oldCodepointsFile = File(path.absolute(argResults[_oldCodepointsPathOption] as String));
  if (!oldCodepointsFile.existsSync()) {
    stderr.writeln('Error: Old codepoints file not found: ${oldCodepointsFile.path}');
    exit(1);
  }

  final String newCodepointsString = newCodepointsFile.readAsStringSync();
  final Map<String, String> newTokenPairMap = stringToTokenPairMap(newCodepointsString);

  final String oldCodepointsString = oldCodepointsFile.readAsStringSync();
  final Map<String, String> oldTokenPairMap = stringToTokenPairMap(oldCodepointsString);

  _testIsMapSuperset(newTokenPairMap, oldTokenPairMap);

  final String iconClassFileData = iconClassFile.readAsStringSync();

  stderr.writeln('Generating new token pairs.');
  final String newIconData = regenerateIconsFile(iconClassFileData, newTokenPairMap);

  if (argResults[_dryRunOption] as bool) {
    stdout.writeln(newIconData);
  } else {
    stderr.writeln('\nWriting to ${iconClassFile.path}.');
    iconClassFile.writeAsStringSync(newIconData);
    _cleanUpFiles(newCodepointsFile, oldCodepointsFile);
  }
}

ArgResults _handleArguments(List<String> args) {
  final ArgParser argParser = ArgParser()
    ..addOption(_newCodepointsPathOption, defaultsTo: _defaultNewCodepointsPath)
    ..addOption(_oldCodepointsPathOption, defaultsTo: _defaultOldCodepointsPath)
    ..addOption(_iconsClassPathOption, defaultsTo: _defaultIconsPath)
    ..addFlag(_dryRunOption, defaultsTo: false);
  return argParser.parse(args);
}

// Do not make this method private as it is used by g3 roll.
Map<String, String> stringToTokenPairMap(String codepointData) {
  final Iterable<String> cleanData = LineSplitter.split(codepointData)
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty);

  final Map<String, String> pairs = <String, String>{};

  for (final String line in cleanData) {
    final List<String> tokens = line.split(' ');
    if (tokens.length != 2) {
      throw FormatException('Unexpected codepoint data: $line');
    }
    pairs.putIfAbsent(tokens[0], () => tokens[1]);
  }

  return pairs;
}

// Do not make this method private as it is used by g3 roll.
String regenerateIconsFile(String iconData, Map<String, String> tokenPairMap) {
  final StringBuffer buf = StringBuffer();
  bool generating = false;
  for (final String line in LineSplitter.split(iconData)) {
    if (!generating) {
      buf.writeln(line);
    }
    if (line.contains(_beginGeneratedMark)) {
      generating = true;

      final String iconDeclarationsString = <String>[
        for (MapEntry<String, String> entry in tokenPairMap.entries)
          _generateDeclaration(entry)
      ].join();

      buf.write(iconDeclarationsString);
    } else if (line.contains(_endGeneratedMark)) {
      generating = false;
      buf.writeln(line);
    }
  }
  return buf.toString();
}

void _testIsMapSuperset(Map<String, String> newCodepoints, Map<String, String> oldCodepoints) {
  final Set<String> newCodepointsSet = newCodepoints.keys.toSet();
  final Set<String> oldCodepointsSet = oldCodepoints.keys.toSet();

  if (!newCodepointsSet.containsAll(oldCodepointsSet)) {
    stderr.writeln(
      '''Error: New codepoints file does not contain all the existing codepoints.\n
        Missing: ${oldCodepointsSet.difference(newCodepointsSet)}
        ''',
    );
    exit(1);
  }
}

String _generateDeclaration(MapEntry<String, String> tokenPair) {
  final String description = tokenPair.key.replaceAll('_', ' ');

  String styleSuffix = '';
  String webFontKey = tokenPair.key;

  // The first line of each generated declaration includes a comment of html.
  // DartDocs reads that to make the listings in our api docs that shows the
  // icon rendered next to its key name. Unfortunately, unlike Flutter, this
  // html needs to use a different web font for each style. We read the style's
  // suffix from the key for Flutter's icons font, add the corresponding style's
  // suffix to the class we pass into html, and then remove the suffix from the
  // icon key. The keys needed for the individual web fonts do not use a suffix
  // to denote style.
  if (webFontKey.endsWith('_outlined') && webFontKey!='insert_chart_outlined') {
    styleSuffix = '-outlined';
    webFontKey = webFontKey.replaceAll('_outlined', '');
  }
  if (webFontKey.endsWith('_rounded')) {
    styleSuffix = '-round';
    webFontKey = webFontKey.replaceAll('_rounded', '');
  }
  if (webFontKey.endsWith('_sharp')) {
    styleSuffix = '-sharp';
    webFontKey = webFontKey.replaceAll('_sharp', '');
  }

  final String identifier = _generateIdentifier(tokenPair.key);
  final String rtl = _mirroredIcons.contains(tokenPair.key)
      ? ', matchTextDirection: true'
      : '';

  return '''

  /// <i class="material-icons$styleSuffix md-36">$webFontKey</i> &#x2014; material icon named "$description".
  static const IconData $identifier = IconData(0x${tokenPair.value}, fontFamily: 'MaterialIcons'$rtl);
''';
}

String _generateIdentifier(String rawIdentifier) {
  for (final MapEntry<String, String> rewritePair in _identifierRewrites.entries) {
    if (rawIdentifier.startsWith(rewritePair.key)) {
      return rawIdentifier.replaceFirst(rewritePair.key, _identifierRewrites[rewritePair.key]);
    }
  }
  return rawIdentifier;
}

// Replace the old codepoints file with the new.
void _cleanUpFiles(File newCodepointsFile, File oldCodepointsFile) {
  stderr.writeln('\nMoving new codepoints file to ${oldCodepointsFile.path}.\n');
  newCodepointsFile.renameSync(oldCodepointsFile.path);
}

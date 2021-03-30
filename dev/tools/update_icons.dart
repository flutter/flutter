// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Regenerates the material icons file.
// See https://github.com/flutter/flutter/wiki/Updating-Material-Design-Fonts-&-Icons

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

const String _beginGeneratedMark = '// BEGIN GENERATED ICONS';
const String _endGeneratedMark = '// END GENERATED ICONS';
const String _beginPlatformAdaptiveGeneratedMark = '// BEGIN GENERATED PLATFORM ADAPTIVE ICONS';
const String _endPlatformAdaptiveGeneratedMark = '// END GENERATED PLATFORM ADAPTIVE ICONS';

const Map<String, List<String>> _platformAdaptiveIdentifiers = <String, List<String>>{
  // Mapping of Flutter IDs to an Android/agnostic ID and an iOS ID.
  // Flutter IDs can be anything, but should be chosen to be agnostic.
  'arrow_back': <String>['arrow_back', 'arrow_back_ios'],
  'arrow_forward': <String>['arrow_forward', 'arrow_forward_ios'],
  'flip_camera': <String>['flip_camera_android', 'flip_camera_ios'],
  'more': <String>['more_vert', 'more_horiz'],
  'share': <String>['share', 'ios_share'],
};

// Rewrite certain Flutter IDs (reserved keywords, numbers) using prefix matching.
const Map<String, String> identifierRewrites = <String, String>{
  '1x': 'one_x',
  '360': 'threesixty',
  '2d': 'twod',
  '3d': 'threed',
  '3p': 'three_p',
  '6_ft': 'six_ft',
  '3g': 'three_g',
  '4g': 'four_g',
  '5g': 'five_g',
  '30fps': 'thirty_fps',
  '60fps': 'sixty_fps',
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
  'try': 'try_sms_star',
};

const Set<String> _iconsMirroredWhenRTL = <String>{
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
  final File newCodepointsFile = File(argResults[_newCodepointsPathOption] as String);
  if (!newCodepointsFile.existsSync()) {
    stderr.writeln('Error: New codepoints file not found: ${newCodepointsFile.path}');
    exit(1);
  }
  final File oldCodepointsFile = File(argResults[_oldCodepointsPathOption] as String);
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

  stderr.writeln('Generating icons file...');
  final String newIconData = regenerateIconsFile(iconClassFileData, newTokenPairMap);

  if (argResults[_dryRunOption] as bool) {
    stdout.write(newIconData);
  } else {
    stderr.writeln('\nWriting to ${iconClassFile.path}.');
    iconClassFile.writeAsStringSync(newIconData);
    _overwriteOldCodepoints(newCodepointsFile, oldCodepointsFile);
  }
}

ArgResults _handleArguments(List<String> args) {
  final ArgParser argParser = ArgParser()
    ..addOption(_newCodepointsPathOption, defaultsTo: _defaultNewCodepointsPath, help: 'Location of the new codepoints directory')
    ..addOption(_oldCodepointsPathOption, defaultsTo: _defaultOldCodepointsPath, help: 'Location of the existing codepoints directory')
    ..addOption(_iconsClassPathOption, defaultsTo: _defaultIconsPath, help: 'Location of the material icons file')
    ..addFlag(_dryRunOption, defaultsTo: false);
  argParser.addFlag('help', abbr: 'h', negatable: false, callback: (bool help) {
    if (help) {
      print(argParser.usage);
      exit(1);
    }
  });
  return argParser.parse(args);
}

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

String regenerateIconsFile(String iconData, Map<String, String> tokenPairMap) {
  final List<_Icon> newIcons = tokenPairMap.entries.map((MapEntry<String, String> entry) => _Icon(entry)).toList();
  newIcons.sort((_Icon a, _Icon b) => a._compareTo(b));

  final StringBuffer buf = StringBuffer();
  bool generating = false;

  for (final String line in LineSplitter.split(iconData)) {
    if (!generating) {
      buf.writeln(line);
    }

    // Generate for _PlatformAdaptiveIcons
    if (line.contains(_beginPlatformAdaptiveGeneratedMark)) {
      generating = true;
      final List<String> platformAdaptiveDeclarations = <String>[];
      _platformAdaptiveIdentifiers.forEach((String flutterId, List<String> ids) {
        // Automatically finds and generates styled icon declarations.
        for (final String style in _Icon.styleSuffixes) {
          try {
            final _Icon agnosticIcon = newIcons.firstWhere(
                (_Icon icon) => icon.id == '${ids[0]}$style',
                orElse: () => throw ids[0]);
            final _Icon iOSIcon = newIcons.firstWhere(
                (_Icon icon) => icon.id == '${ids[1]}$style',
                orElse: () => throw ids[1]);

            platformAdaptiveDeclarations.add(_Icon.platformAdaptiveDeclaration('$flutterId$style', agnosticIcon, iOSIcon));
          } catch (e) {
            if (style == '') {
              // Throw an error for regular (unstyled) icons.
              stderr.writeln("Error while generating platformAdaptiveDeclarations: Icon '$e' not found.");
              exit(1);
            } else {
              // Ignore errors for styled icons since some don't exist.
            }
          }
        }
      });
      buf.write(platformAdaptiveDeclarations.join());
    } else if (line.contains(_endPlatformAdaptiveGeneratedMark)) {
      generating = false;
      buf.writeln(line);
    }

    // Generate for Icons
    if (line.contains(_beginGeneratedMark)) {
      generating = true;
      final String iconDeclarationsString = newIcons.map((_Icon icon) => icon.fullDeclaration).join('');
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
    stderr.writeln('''
Error: New codepoints file does not contain all the existing codepoints.\n
        Missing: ${oldCodepointsSet.difference(newCodepointsSet)}
        ''',
    );
    exit(1);
  } else {
    final int diff = newCodepointsSet.length - oldCodepointsSet.length;
    stderr.writeln('New codepoints file contains all ${oldCodepointsSet.length} existing codepoints.');
    if (diff > 0) {
      stderr.writeln('It also contains $diff new codepoints: ${newCodepointsSet.difference(oldCodepointsSet)}');
    }
  }
}

// Replace the old codepoints file with the new.
void _overwriteOldCodepoints(File newCodepointsFile, File oldCodepointsFile) {
  stderr.writeln('Copying new codepoints file to ${oldCodepointsFile.path}.\n');
  newCodepointsFile.copySync(oldCodepointsFile.path);
}

class _Icon {
  // Parse tokenPair (e.g. {"6_ft_apart_outlined": "e004"}).
  _Icon(MapEntry<String, String> tokenPair) {
    id = tokenPair.key;
    hexCodepoint = tokenPair.value;

    if (id.endsWith('_outlined') && id!='insert_chart_outlined') {
      shortId = _replaceLast(id, '_outlined');
      htmlSuffix = '-outlined';
    } else if (id.endsWith('_rounded')) {
      shortId = _replaceLast(id, '_rounded');
      htmlSuffix = '-round';
    } else if (id.endsWith('_sharp')) {
      shortId = _replaceLast(id, '_sharp');
      htmlSuffix = '-sharp';
    } else {
      shortId = id;
      htmlSuffix = '';
    }

    flutterId = id;
    for (final MapEntry<String, String> rewritePair in identifierRewrites.entries) {
      if (id.startsWith(rewritePair.key)) {
        flutterId = id.replaceFirst(rewritePair.key, identifierRewrites[rewritePair.key]);
      }
    }

    name = id.replaceAll('_', ' ');
  }

  static const List<String> styleSuffixes = <String>['', '_outlined', '_rounded', '_sharp'];

  String id;            // e.g. 5g, 5g_outlined, 5g_rounded, 5g_sharp
  String shortId;       // e.g. 5g
  String flutterId;     // e.g. five_g, five_g_outlined, five_g_rounded, five_g_sharp
  String name;          // e.g. five g, five g outlined, five g rounded, five g sharp
  String hexCodepoint;  // e.g. e547

  // The suffix for the 'material-icons' HTML class.
  String htmlSuffix;

  String get mirroredInRTL => _iconsMirroredWhenRTL.contains(shortId) ? ', matchTextDirection: true' : '';

  String get dartDoc => '<i class="material-icons$htmlSuffix md-36">$shortId</i> &#x2014; material icon named "$name"';

  String get declaration =>
      "static const IconData $flutterId = IconData(0x$hexCodepoint, fontFamily: 'MaterialIcons'$mirroredInRTL);";

  String get fullDeclaration => '''

  /// $dartDoc.
  $declaration
''';

  static String platformAdaptiveDeclaration(String fullFlutterId, _Icon agnosticIcon, _Icon iOSIcon) => '''

  /// Platform-adaptive icon for ${agnosticIcon.dartDoc} and ${iOSIcon.dartDoc}.;
  IconData get $fullFlutterId => !_isCupertino() ? Icons.${agnosticIcon.flutterId} : Icons.${iOSIcon.flutterId};
''';

  @override
  String toString() => id;

  /// Analogous to [String.compareTo]
  int _compareTo(_Icon b) {
    // Sort a regular icon before its variants.
    if (shortId == b.shortId) {
      return id.length - b.id.length;
    } else {
      return flutterId.compareTo(b.flutterId);
    }
  }

  String _replaceLast(String string, String toReplace) {
    return string.replaceAll(RegExp('$toReplace\$'), '');
  }
}

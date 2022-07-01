// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Regenerates the material icons file.
// See https://github.com/flutter/flutter/wiki/Updating-Material-Design-Fonts-&-Icons

import 'dart:collection';
import 'dart:convert' show LineSplitter;
import 'dart:io';

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

const String _iconsPathOption = 'icons';
const String _iconsTemplatePathOption = 'icons-template';
const String _newCodepointsPathOption = 'new-codepoints';
const String _oldCodepointsPathOption = 'old-codepoints';
const String _fontFamilyOption = 'font-family';
const String _enforceSafetyChecks = 'enforce-safety-checks';
const String _dryRunOption = 'dry-run';

const String _defaultIconsPath = 'packages/flutter/lib/src/material/icons.dart';
const String _defaultNewCodepointsPath = 'codepoints';
const String _defaultOldCodepointsPath = 'bin/cache/artifacts/material_fonts/codepoints';
const String _defaultFontFamily = 'MaterialIcons';
const String _defaultDemoFilePath = '/tmp/new_icons_demo.dart';

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

// Rewrite certain Flutter IDs (numbers) using prefix matching.
const Map<String, String> _identifierPrefixRewrites = <String, String>{
  '1': 'one_',
  '2': 'two_',
  '3': 'three_',
  '4': 'four_',
  '5': 'five_',
  '6': 'six_',
  '7': 'seven_',
  '8': 'eight_',
  '9': 'nine_',
  '10': 'ten_',
  '11': 'eleven_',
  '12': 'twelve_',
  '13': 'thirteen_',
  '14': 'fourteen_',
  '15': 'fifteen_',
  '16': 'sixteen_',
  '17': 'seventeen_',
  '18': 'eighteen_',
  '19': 'nineteen_',
  '20': 'twenty_',
  '21': 'twenty_one_',
  '22': 'twenty_two_',
  '23': 'twenty_three_',
  '24': 'twenty_four_',
  '30': 'thirty_',
  '60': 'sixty_',
  '123': 'onetwothree',
  '360': 'threesixty',
  '2d': 'twod',
  '3d': 'threed',
  '3d_rotation': 'threed_rotation',
};

// Rewrite certain Flutter IDs (reserved keywords) using exact matching.
const Map<String, String> _identifierExactRewrites = <String, String>{
  'class': 'class_',
  'new': 'new_',
  'switch': 'switch_',
  'try': 'try_sms_star',
  'door_back': 'door_back_door',
  'door_front': 'door_front_door',
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

  final File iconsFile = File(path.normalize(path.absolute(argResults[_iconsPathOption] as String)));
  if (!iconsFile.existsSync()) {
    stderr.writeln('Error: Icons file not found: ${iconsFile.path}');
    exit(1);
  }
  final File iconsTemplateFile = File(path.normalize(path.absolute(argResults[_iconsTemplatePathOption] as String)));
  if (!iconsTemplateFile.existsSync()) {
    stderr.writeln('Error: Icons template file not found: ${iconsTemplateFile.path}');
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

  stderr.writeln('Performing safety checks');
  final bool isSuperset = testIsSuperset(newTokenPairMap, oldTokenPairMap);
  final bool isStable = testIsStable(newTokenPairMap, oldTokenPairMap);
  if ((!isSuperset || !isStable) && argResults[_enforceSafetyChecks] as bool) {
    exit(1);
  }
  final String iconsTemplateContents = iconsTemplateFile.readAsStringSync();

  stderr.writeln("Generating icons ${argResults[_dryRunOption] as bool ? '' : 'to ${iconsFile.path}'}");
  final String newIconsContents = _regenerateIconsFile(
    iconsTemplateContents,
    newTokenPairMap,
    argResults[_fontFamilyOption] as String,
    argResults[_enforceSafetyChecks] as bool,
  );

  if (argResults[_dryRunOption] as bool) {
    stdout.write(newIconsContents);
  } else {
    iconsFile.writeAsStringSync(newIconsContents);

    final SplayTreeMap<String, String> sortedNewTokenPairMap = SplayTreeMap<String, String>.of(newTokenPairMap);
    _regenerateCodepointsFile(oldCodepointsFile, sortedNewTokenPairMap);

    sortedNewTokenPairMap.removeWhere((String key, String value) => oldTokenPairMap.containsKey(key));
    _generateIconDemo(File(_defaultDemoFilePath), sortedNewTokenPairMap);
  }
}

ArgResults _handleArguments(List<String> args) {
  final ArgParser argParser = ArgParser()
    ..addOption(_iconsPathOption,
        defaultsTo: _defaultIconsPath,
        help: 'Location of the material icons file')
    ..addOption(_iconsTemplatePathOption,
        defaultsTo: _defaultIconsPath,
        help:
            'Location of the material icons file template. Usually the same as --$_iconsPathOption')
    ..addOption(_newCodepointsPathOption,
        defaultsTo: _defaultNewCodepointsPath,
        help: 'Location of the new codepoints directory')
    ..addOption(_oldCodepointsPathOption,
        defaultsTo: _defaultOldCodepointsPath,
        help: 'Location of the existing codepoints directory')
    ..addOption(_fontFamilyOption,
        defaultsTo: _defaultFontFamily,
        help: 'The font family to use for the IconData constants')
    ..addFlag(_enforceSafetyChecks,
        defaultsTo: true,
        help: 'Whether to exit if safety checks fail (e.g. codepoints are missing or unstable')
    ..addFlag(_dryRunOption);
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

String _regenerateIconsFile(
    String templateFileContents,
    Map<String, String> tokenPairMap,
    String fontFamily,
    bool enforceSafetyChecks,
  ) {
  final List<Icon> newIcons = tokenPairMap.entries
      .map((MapEntry<String, String> entry) => Icon(entry, fontFamily: fontFamily))
      .toList();
  newIcons.sort((Icon a, Icon b) => a._compareTo(b));

  final StringBuffer buf = StringBuffer();
  bool generating = false;

  for (final String line in LineSplitter.split(templateFileContents)) {
    if (!generating) {
      buf.writeln(line);
    }

    // Generate for PlatformAdaptiveIcons
    if (line.contains(_beginPlatformAdaptiveGeneratedMark)) {
      generating = true;
      final List<String> platformAdaptiveDeclarations = <String>[];
      _platformAdaptiveIdentifiers.forEach((String flutterId, List<String> ids) {
        // Automatically finds and generates all icon declarations.
        for (final String style in <String>['', '_outlined', '_rounded', '_sharp']) {
          try {
            final Icon agnosticIcon = newIcons.firstWhere(
                (Icon icon) => icon.id == '${ids[0]}$style',
                orElse: () => throw ids[0]);
            final Icon iOSIcon = newIcons.firstWhere(
                (Icon icon) => icon.id == '${ids[1]}$style',
                orElse: () => throw ids[1]);
            platformAdaptiveDeclarations.add(Icon.platformAdaptiveDeclaration('$flutterId$style', agnosticIcon, iOSIcon),
            );
          } catch (e) {
            if (style == '') {
              // Throw an error for baseline icons.
              stderr.writeln("❌ Platform adaptive icon '$e' not found.");
              if (enforceSafetyChecks) {
                stderr.writeln('Safety checks failed');
                exit(1);
              }
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
      final String iconDeclarationsString = newIcons.map((Icon icon) => icon.fullDeclaration).join();
      buf.write(iconDeclarationsString);
    } else if (line.contains(_endGeneratedMark)) {
      generating = false;
      buf.writeln(line);
    }
  }
  return buf.toString();
}

@visibleForTesting
bool testIsSuperset(Map<String, String> newCodepoints, Map<String, String> oldCodepoints) {
  final Set<String> newCodepointsSet = newCodepoints.keys.toSet();
  final Set<String> oldCodepointsSet = oldCodepoints.keys.toSet();

  final int diff = newCodepointsSet.length - oldCodepointsSet.length;
  if (diff > 0) {
    stderr.writeln('🆕 $diff new codepoints: ${newCodepointsSet.difference(oldCodepointsSet)}');
  }
  if (!newCodepointsSet.containsAll(oldCodepointsSet)) {
    stderr.writeln(
        '❌ new codepoints file does not contain all ${oldCodepointsSet.length} '
        'existing codepoints. Missing: ${oldCodepointsSet.difference(newCodepointsSet)}');
    return false;
  } else {
    stderr.writeln('✅ new codepoints file contains all ${oldCodepointsSet.length} existing codepoints');
  }
  return true;
}

@visibleForTesting
bool testIsStable(Map<String, String> newCodepoints, Map<String, String> oldCodepoints) {
  final int oldCodepointsCount = oldCodepoints.length;
  final List<String> unstable = <String>[];

  oldCodepoints.forEach((String key, String value) {
    if (newCodepoints.containsKey(key)) {
      if (value != newCodepoints[key]) {
        unstable.add(key);
      }
    }
  });

  if (unstable.isNotEmpty) {
    stderr.writeln('❌ out of $oldCodepointsCount existing codepoints, ${unstable.length} were unstable: $unstable');
    return false;
  } else {
    stderr.writeln('✅ all existing $oldCodepointsCount codepoints are stable');
    return true;
  }
}

void _regenerateCodepointsFile(File oldCodepointsFile, Map<String, String> tokenPairMap) {
  stderr.writeln('Regenerating old codepoints file ${oldCodepointsFile.path}');

  final StringBuffer buf = StringBuffer();
  tokenPairMap.forEach((String key, String value) => buf.writeln('$key $value'));
  oldCodepointsFile.writeAsStringSync(buf.toString());
}

void _generateIconDemo(File demoFilePath, Map<String, String> tokenPairMap) {
  if (tokenPairMap.isEmpty) {
    stderr.writeln('No new icons, skipping generating icon demo');
    return;
  }
  stderr.writeln('Generating icon demo at $_defaultDemoFilePath');

  final StringBuffer newIconUsages = StringBuffer();
  for (final MapEntry<String, String> entry in tokenPairMap.entries) {
    newIconUsages.writeln(Icon(entry).usage);
  }
  final String demoFileContents = '''
    import 'package:flutter/material.dart';

    void main() => runApp(const IconDemo());

    class IconDemo extends StatelessWidget {
      const IconDemo({ Key? key }) : super(key: key);

      @override
      Widget build(BuildContext context) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Wrap(
              children: const [
                ${newIconUsages.toString()}
              ],
            ),
          ),
        );
      }
    }
    ''';
  demoFilePath.writeAsStringSync(demoFileContents);
}

class Icon {
  // Parse tokenPair (e.g. {"6_ft_apart_outlined": "e004"}).
  Icon(MapEntry<String, String> tokenPair, {this.fontFamily = _defaultFontFamily}) {
    id = tokenPair.key;
    hexCodepoint = tokenPair.value;

    // Determine family and htmlSuffix.
    if (id.endsWith('_gm_outlined')) {
      family = 'GM';
      htmlSuffix = '-outlined';
    } else if (id.endsWith('_gm_filled')) {
      family = 'GM';
      htmlSuffix = '-filled';
    } else if (id.endsWith('_monoline_outlined')) {
      family = 'Monoline';
      htmlSuffix = '-outlined';
    } else if (id.endsWith('_monoline_filled')) {
      family = 'Monoline';
      htmlSuffix = '-filled';
    } else {
      family = 'material';
      if (id.endsWith('_baseline')) {
        id = _removeLast(id, '_baseline');
        htmlSuffix = '';
      } else if (id.endsWith('_outlined')) {
        htmlSuffix = '-outlined';
      } else if (id.endsWith('_rounded')) {
        htmlSuffix = '-round';
      } else if (id.endsWith('_sharp')) {
        htmlSuffix = '-sharp';
      }
    }

    shortId = _generateShortId(id);
    flutterId = generateFlutterId(id);
  }

  static const List<String> _idSuffixes = <String>[
    '_gm_outlined',
    '_gm_filled',
    '_monoline_outlined',
    '_monoline_filled',
    '_outlined',
    '_rounded',
    '_sharp'
  ];

  late String id; // e.g. 5g, 5g_outlined, 5g_rounded, 5g_sharp
  late String shortId; // e.g. 5g
  late String flutterId; // e.g. five_g, five_g_outlined, five_g_rounded, five_g_sharp
  late String family; // e.g. material
  late String hexCodepoint; // e.g. e547
  late String htmlSuffix = ''; // The suffix for the 'material-icons' HTML class.
  String fontFamily; // The IconData font family.

  String get name => shortId.replaceAll('_', ' ').trim();

  String get style => htmlSuffix == '' ? '' : ' (${htmlSuffix.replaceFirst('-', '')})';

  String get dartDoc =>
      '<i class="material-icons$htmlSuffix md-36">$shortId</i> &#x2014; $family icon named "$name"$style';

  String get usage => 'Icon(Icons.$flutterId),';

  String get mirroredInRTL => _iconsMirroredWhenRTL.contains(shortId)
      ? ', matchTextDirection: true'
      : '';

  String get declaration =>
      "static const IconData $flutterId = IconData(0x$hexCodepoint, fontFamily: '$fontFamily'$mirroredInRTL);";

  String get fullDeclaration => '''

  /// $dartDoc.
  $declaration
''';

  static String platformAdaptiveDeclaration(String fullFlutterId, Icon agnosticIcon, Icon iOSIcon) => '''

  /// Platform-adaptive icon for ${agnosticIcon.dartDoc} and ${iOSIcon.dartDoc}.;
  IconData get $fullFlutterId => !_isCupertino() ? Icons.${agnosticIcon.flutterId} : Icons.${iOSIcon.flutterId};
''';

  @override
  String toString() => id;

  /// Analogous to [String.compareTo]
  int _compareTo(Icon b) {
    if (shortId == b.shortId) {
      // Sort a regular icon before its variants.
      return id.length - b.id.length;
    }
    return shortId.compareTo(b.shortId);
  }

  static String _removeLast(String string, String toReplace) {
    return string.replaceAll(RegExp('$toReplace\$'), '');
  }

  static String _generateShortId(String id) {
    String shortId = id;
    for (final String styleSuffix in _idSuffixes) {
      shortId = _removeLast(shortId, styleSuffix);
      if (shortId != id) {
        break;
      }
    }
    return shortId;
  }

  /// Given some icon's raw id, returns a valid Dart icon identifier
  static String generateFlutterId(String id) {
    String flutterId = id;
    // Exact identifier rewrites.
    for (final MapEntry<String, String> rewritePair in _identifierExactRewrites.entries) {
      final String shortId = Icon._generateShortId(id);
      if (shortId == rewritePair.key) {
        flutterId = id.replaceFirst(
          rewritePair.key,
          _identifierExactRewrites[rewritePair.key]!,
        );
      }
    }
    // Prefix identifier rewrites.
    for (final MapEntry<String, String> rewritePair in _identifierPrefixRewrites.entries) {
      if (id.startsWith(rewritePair.key)) {
        flutterId = id.replaceFirst(
          rewritePair.key,
          _identifierPrefixRewrites[rewritePair.key]!,
        );
      }
    }

    // Prevent double underscores.
    flutterId = flutterId.replaceAll('__', '_');

    return flutterId;
  }
}

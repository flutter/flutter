// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:mime/mime.dart' as mime;
import 'package:process/process.dart';
import 'package:record_use/record_use.dart';

import '../../artifacts.dart';
import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/logger.dart';
import '../../base/process.dart';
import '../../build_info.dart';
import '../../convert.dart';
import '../../devfs.dart';
import '../build_system.dart';

List<Map<String, Object?>> _getList(Object? object, String errorMessage) {
  if (object is List<Object?>) {
    return object.cast<Map<String, Object?>>();
  }
  throw IconTreeShakerException._(errorMessage);
}

/// A class that wraps the functionality of recorded uses and the
/// font subset utility to tree shake unused icons from fonts.
class IconTreeShaker {
  /// Creates a wrapper for icon font subsetting.
  ///
  /// If the `fontManifest` parameter is null, [enabled] will return false since
  /// there are no fonts to shake.
  ///
  /// The constructor will validate the environment and print a warning if
  /// font subsetting has been requested in a debug build mode.
  IconTreeShaker(
    this._environment,
    DevFSStringContent? fontManifest, {
    required ProcessManager processManager,
    required Logger logger,
    required FileSystem fileSystem,
    required Artifacts artifacts,
    required TargetPlatform targetPlatform,
  }) : _processManager = processManager,
       _logger = logger,
       _fs = fileSystem,
       _artifacts = artifacts,
       _fontManifest = fontManifest?.string,
       _targetPlatform = targetPlatform {
    if (_environment.defines[kIconTreeShakerFlag] == 'true' &&
        _environment.defines[kBuildMode] == 'debug') {
      logger.printError(
        'Font subsetting is not supported in debug mode. The '
        '--tree-shake-icons flag will be ignored.',
      );
    }
  }

  /// The MIME types for supported font sets.
  static const kTtfMimeTypes = <String>{
    'font/ttf', // based on internet search
    'font/opentype',
    'font/otf',
    'application/x-font-opentype',
    'application/x-font-otf',
    'application/x-font-ttf', // based on running locally.
  };

  /// The [Source] inputs that native targets using this should depend on.
  ///
  /// Web targets (such as `WebReleaseBundle`) do not use this field because
  /// their recorded uses inputs are dynamically provided via
  /// `Dart2WebTarget.buildPatternStems`.
  ///
  /// See [Target.inputs].
  static const inputs = <Source>[
    Source.pattern(
      '{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/icon_tree_shaker.dart',
    ),
    Source.pattern('{BUILD_DIR}/recorded_uses.json'),
    Source.artifact(Artifact.fontSubset),
  ];

  final Environment _environment;
  final String? _fontManifest;
  Future<void>? _iconDataProcessing;
  Map<String, _IconTreeShakerData>? _iconData;

  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fs;
  final Artifacts _artifacts;
  final TargetPlatform _targetPlatform;

  /// Whether font subsetting should be used for this [Environment].
  bool get enabled =>
      _fontManifest != null &&
      _environment.defines[kIconTreeShakerFlag] == 'true' &&
      _environment.defines[kBuildMode] != 'debug';

  // Fills the [_iconData] map.
  Future<void> _getIconData(Environment environment) async {
    if (!enabled) {
      return;
    }

    final candidates = <String>[
      'recorded_uses.json',
      'recorded_uses_js.json',
      'recorded_uses_wasm.json',
    ];
    final recordedUsesFiles = <File>[];
    for (final candidate in candidates) {
      final File file = environment.buildDir.childFile(candidate);
      if (file.existsSync() && file.lengthSync() > 0) {
        recordedUsesFiles.add(file);
      }
    }
    if (recordedUsesFiles.isEmpty) {
      final File defaultFile = environment.buildDir.childFile('recorded_uses.json');
      throw IconTreeShakerException._(
        'Expected to find recorded uses file at ${defaultFile.path}, but no file found.',
      );
    }

    Recordings? combinedRecordings;
    for (final file in recordedUsesFiles) {
      final Recordings recordings = await _readRecordings(file);
      combinedRecordings = combinedRecordings == null
          ? recordings
          : combinedRecordings + recordings;
    }

    final Map<String, List<int>> iconData = _parseRecordings(combinedRecordings!);
    final Set<String> familyKeys = iconData.keys.toSet();

    final Map<String, String> fonts = await _parseFontJson(
      _fontManifest!, // Guarded by `enabled`.
      familyKeys,
    );

    final Set<String> missingFonts = iconData.keys
        .where((String key) => !fonts.containsKey(key))
        .toSet();
    if (missingFonts.isNotEmpty) {
      environment.logger.printStatus(
        'Expected to find fonts for $missingFonts, but found '
        '${fonts.keys}. This usually means you are referring to '
        'font families in an IconData class but not including them '
        'in the assets section of your pubspec.yaml, are missing '
        'the package that would include them, or are missing '
        '"uses-material-design: true".',
      );
    }

    final result = <String, _IconTreeShakerData>{};
    const kSpacePoint = 32;
    for (final MapEntry(:key, :value) in fonts.entries) {
      final int? fallbackCodePoint = _kKnownIconFontFallbackCodePoints[key];
      final List<int>? codePoints =
          iconData[key] ?? (fallbackCodePoint != null ? <int>[fallbackCodePoint] : null);
      if (codePoints == null) {
        throw IconTreeShakerException._(
          'Expected to font code points for $key, but none were found.',
        );
      }

      // Add space as an optional code point, as web uses it to measure the font height.
      final optionalCodePoints = _targetPlatform == TargetPlatform.web_javascript
          ? <int>[kSpacePoint]
          : <int>[];
      result[value] = _IconTreeShakerData(
        family: key,
        relativePath: value,
        codePoints: codePoints,
        optionalCodePoints: optionalCodePoints,
      );
    }
    _iconData = result;
  }

  /// Calls font-subset, which transforms the [input] font file to a
  /// subsetted version at [outputPath].
  ///
  /// If [enabled] is false, or the relative path is not recognized as an icon
  /// font used in the Flutter application, this returns false.
  /// If the font-subset subprocess fails, it will [throwToolExit].
  /// Otherwise, it will return true.
  Future<bool> subsetFont({
    required File input,
    required String outputPath,
    required String relativePath,
    bool quiet = false,
  }) async {
    if (!enabled) {
      return false;
    }
    if (!input.existsSync() || input.lengthSync() < 12) {
      return false;
    }
    final String? mimeType = mime.lookupMimeType(
      input.path,
      headerBytes: await input.openRead(0, 12).first,
    );
    if (!kTtfMimeTypes.contains(mimeType)) {
      return false;
    }
    await (_iconDataProcessing ??= _getIconData(_environment));
    assert(_iconData != null);

    final _IconTreeShakerData? iconTreeShakerData = _iconData![relativePath];
    if (iconTreeShakerData == null) {
      return false;
    }

    final File fontSubset = _fs.file(_artifacts.getArtifactPath(Artifact.fontSubset));
    if (!fontSubset.existsSync()) {
      throw IconTreeShakerException._('The font-subset utility is missing. Run "flutter doctor".');
    }

    final cmd = <String>[fontSubset.path, outputPath, input.path];
    final Iterable<String> requiredCodePointStrings = iconTreeShakerData.codePoints.map(
      (int codePoint) => codePoint.toString(),
    );
    final Iterable<String> optionalCodePointStrings = iconTreeShakerData.optionalCodePoints.map(
      (int codePoint) => 'optional:$codePoint',
    );
    final String codePointsString = requiredCodePointStrings
        .followedBy(optionalCodePointStrings)
        .join(' ');
    _logger.printTrace(
      'Running font-subset: ${cmd.join(' ')}, '
      'using codepoints $codePointsString',
    );
    final Process fontSubsetProcess = await _processManager.start(cmd);
    try {
      await ProcessUtils.writelnToStdinUnsafe(
        stdin: fontSubsetProcess.stdin,
        line: codePointsString,
      );
      await fontSubsetProcess.stdin.flush();
      await fontSubsetProcess.stdin.close();
    } on Exception {
      // handled by checking the exit code.
    }

    final int code = await fontSubsetProcess.exitCode;
    if (code != 0) {
      _logger.printTrace(await utf8.decodeStream(fontSubsetProcess.stdout));
      _logger.printError(await utf8.decodeStream(fontSubsetProcess.stderr));
      throw IconTreeShakerException._('Font subsetting failed with exit code $code.');
    }
    final String message = getSubsetSummaryMessage(input, _fs.file(outputPath));
    if (quiet) {
      _logger.printTrace(message);
    } else {
      _logger.printStatus(message);
    }
    return true;
  }

  @visibleForTesting
  String getSubsetSummaryMessage(File inputFont, File outputFont) {
    final String fontName = inputFont.basename;
    final double inputSize = inputFont.lengthSync().toDouble();
    final double outputSize = outputFont.lengthSync().toDouble();
    final double reductionBytes = inputSize - outputSize;
    final String reductionPercentage = (reductionBytes / inputSize * 100).toStringAsFixed(1);
    return 'Font asset "$fontName" was tree-shaken, reducing it from '
        '${inputSize.ceil()} to ${outputSize.ceil()} bytes '
        '($reductionPercentage% reduction). Tree-shaking can be disabled '
        'by providing the --no-tree-shake-icons flag when building your app.';
  }

  /// Known icon font families that should be subsetted even if 0 icons are recorded.
  /// Subsetting unused icon fonts to a single dummy icon ensures that unused fonts
  /// are not bundled in their entirety.
  static const Map<String, int> _kKnownIconFontFallbackCodePoints = <String, int>{
    'MaterialIcons': 57415, // 0xe047, Icons.add
    'packages/cupertino_icons/CupertinoIcons': 62418, // 0xf3d2, CupertinoIcons.chevron_left
  };

  /// Returns a map of { fontFamily: relativePath } pairs.
  Future<Map<String, String>> _parseFontJson(String fontManifestData, Set<String> families) async {
    final result = <String, String>{};
    final List<Map<String, Object?>> fontList = _getList(
      json.decode(fontManifestData),
      'FontManifest.json invalid: expected top level to be a list of objects.',
    );

    for (final map in fontList) {
      final Object? familyKey = map['family'];
      if (familyKey is! String) {
        throw IconTreeShakerException._(
          'FontManifest.json invalid: expected the family value to be a string, '
          'got: ${map['family']}.',
        );
      }
      if (!families.contains(familyKey) &&
          !_kKnownIconFontFallbackCodePoints.containsKey(familyKey)) {
        continue;
      }
      final List<Map<String, Object?>> fonts = _getList(
        map['fonts'],
        'FontManifest.json invalid: expected "fonts" to be a list of objects.',
      );
      if (fonts.length != 1) {
        throw IconTreeShakerException._(
          'This tool cannot process icon fonts with multiple fonts in a '
          'single family.',
        );
      }
      final Object? asset = fonts.first['asset'];
      if (asset is! String) {
        throw IconTreeShakerException._(
          'FontManifest.json invalid: expected "asset" value to be a string, '
          'got: ${map['assets']}.',
        );
      }
      result[familyKey] = asset;
    }
    return result;
  }

  Future<Recordings> _readRecordings(File recordedUsesFile) async {
    final String content = await recordedUsesFile.readAsString();
    final Object? data;
    try {
      data = json.decode(content);
    } on FormatException catch (e) {
      throw IconTreeShakerException._('Failed to parse recorded uses file: $e');
    }
    if (data is! Map<String, Object?>) {
      throw IconTreeShakerException._(
        'Invalid recorded uses file: expected a top level JSON object.',
      );
    }

    try {
      return Recordings.fromJson(data);
    } on Exception catch (e) {
      throw IconTreeShakerException._('Failed to parse recorded uses file: $e');
    }
  }

  Map<String, List<int>> _parseRecordings(Recordings recordings) {
    final result = <String, List<int>>{};
    var hasNonConstant = false;

    for (final MapEntry(:key, :value) in recordings.instances.entries) {
      if (_isIconDataDefinition(key)) {
        for (final reference in value) {
          final _IconDataConstants? constants = _extractIconDataConstants(reference);
          if (constants == null) {
            hasNonConstant = true;
            continue;
          }

          if (constants.codePoint is IntConstant) {
            final int codePoint = (constants.codePoint! as IntConstant).value;
            if (constants.fontFamily is! StringConstant) {
              _logger.printTrace(
                'Expected to find fontFamily for constant IconData with codepoint: '
                '$codePoint, but found fontFamily: null. This usually means '
                'you are relying on the system font. Alternatively, font families in '
                'an IconData class can be provided in the assets section of your '
                'pubspec.yaml, or you are missing "uses-material-design: true".',
              );
              continue;
            }
            final String fontFamily = (constants.fontFamily! as StringConstant).value;
            final String? fontPackage = constants.fontPackage is StringConstant
                ? (constants.fontPackage! as StringConstant).value
                : null;
            final family = fontPackage == null ? fontFamily : 'packages/$fontPackage/$fontFamily';
            result[family] ??= <int>[];
            result[family]!.add(codePoint);
          }
        }
      }
    }
    if (hasNonConstant) {
      _logger.printError(
        'This application cannot tree shake icons fonts. '
        'It has non-constant instances of IconData.',
        emphasis: true,
      );
      throwToolExit(
        'Avoid non-constant invocations of IconData or try to '
        'build again with --no-tree-shake-icons.',
      );
    }
    return result;
  }

  static const String _iconDataClassName = 'IconData';
  static const String _codePointFieldName = 'codePoint';
  static const String _fontFamilyFieldName = 'fontFamily';
  static const String _fontPackageFieldName = 'fontPackage';

  bool _isIconDataDefinition(DefinitionWithInstances definition) {
    if (definition is Class) {
      return definition.name == _iconDataClassName &&
          definition.library.uri == 'package:flutter/src/widgets/icon_data.dart';
    }
    final str = definition.toString();
    return str == 'package:flutter/src/widgets/icon_data.dart::IconData' ||
        str.startsWith('package:flutter/src/widgets/icon_data.dart::IconData.');
  }

  _IconDataConstants? _extractIconDataConstants(InstanceReference reference) {
    if (reference case InstanceConstantReference(
      instanceConstant: InstanceConstant(:final fields),
    )) {
      return (
        codePoint: fields[_codePointFieldName],
        fontFamily: fields[_fontFamilyFieldName],
        fontPackage: fields[_fontPackageFieldName],
      );
    } else if (reference case InstanceCreationReference(
      positionalArguments: final positional,
      namedArguments: final named,
    )) {
      final bool hasNonConstantArg =
          positional.any((MaybeConstant arg) => arg is! Constant) ||
          named.values.any((MaybeConstant arg) => arg is! Constant);
      if (!hasNonConstantArg) {
        return (
          codePoint: positional.isNotEmpty ? positional[0] as Constant : null,
          fontFamily: named[_fontFamilyFieldName] as Constant?,
          fontPackage: named[_fontPackageFieldName] as Constant?,
        );
      }
    }
    return null;
  }
}

typedef _IconDataConstants = ({Constant? codePoint, Constant? fontFamily, Constant? fontPackage});

/// The font family name, relative path to font file, and list of code points
/// the application is using.
class _IconTreeShakerData {
  /// All parameters are required.
  const _IconTreeShakerData({
    required this.family,
    required this.relativePath,
    required this.codePoints,
    required this.optionalCodePoints,
  });

  /// The font family name, e.g. "MaterialIcons".
  final String family;

  /// The relative path to the font file.
  final String relativePath;

  /// The list of code points for the font.
  final List<int> codePoints;

  /// The list of code points to be optionally added, if they exist in the
  /// input font. Otherwise, the tool will silently omit them.
  final List<int> optionalCodePoints;

  @override
  String toString() => 'FontSubsetData($family, $relativePath, $codePoints)';
}

class IconTreeShakerException implements Exception {
  IconTreeShakerException._(this.message);

  final String message;

  @override
  String toString() =>
      'IconTreeShakerException: $message\n\n'
      'To disable icon tree shaking, pass --no-tree-shake-icons to the requested '
      'flutter build command';
}

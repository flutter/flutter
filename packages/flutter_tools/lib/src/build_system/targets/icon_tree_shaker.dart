// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:mime/mime.dart' as mime;

import '../../artifacts.dart';
import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/logger.dart';
import '../../convert.dart';
import '../../devfs.dart';
import '../build_system.dart';
import 'common.dart';

/// The build define controlling whether icon fonts should be stripped down to
/// only the glyphs used by the application.
const String kIconTreeShakerFlag = 'TreeShakeIcons';

/// Whether icon font subsetting is enabled by default.
const bool kIconTreeShakerEnabledDefault = true;

List<Map<String, dynamic>> _getList(dynamic object, String errorMessage) {
  if (object is List<dynamic>) {
    return object.cast<Map<String, dynamic>>();
  }
  throw IconTreeShakerException._(errorMessage);
}

/// A class that wraps the functionality of the const finder package and the
/// font subset utility to tree shake unused icons from fonts.
class IconTreeShaker {
  /// Creates a wrapper for icon font subsetting.
  ///
  /// The environment parameter must not be null.
  ///
  /// If the `fontManifest` parameter is null, [enabled] will return false since
  /// there are no fonts to shake.
  ///
  /// The constructor will validate the environment and print a warning if
  /// font subsetting has been requested in a debug build mode.
  IconTreeShaker(
    this._environment,
    DevFSStringContent fontManifest, {
    @required ProcessManager processManager,
    @required Logger logger,
    @required FileSystem fileSystem,
    @required Artifacts artifacts,
  }) : assert(_environment != null),
       assert(processManager != null),
       assert(logger != null),
       assert(fileSystem != null),
       assert(artifacts != null),
       _processManager = processManager,
       _logger = logger,
       _fs = fileSystem,
       _artifacts = artifacts,
       _fontManifest = fontManifest?.string {
    if (_environment.defines[kIconTreeShakerFlag] == 'true' &&
        _environment.defines[kBuildMode] == 'debug') {
      logger.printError('Font subetting is not supported in debug mode. The '
                         '--tree-shake-icons flag will be ignored.');
    }
  }

  /// The MIME types for supported font sets.
  static const Set<String> kTtfMimeTypes = <String>{
    'font/ttf', // based on internet search
    'font/opentype',
    'font/otf',
    'application/x-font-opentype',
    'application/x-font-otf',
    'application/x-font-ttf', // based on running locally.
  };

  /// The [Source] inputs that targets using this should depend on.
  ///
  /// See [Target.inputs].
  static const List<Source> inputs = <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/icon_tree_shaker.dart'),
    Source.artifact(Artifact.constFinder),
    Source.artifact(Artifact.fontSubset),
  ];

  final Environment _environment;
  final String _fontManifest;
  Future<void> _iconDataProcessing;
  Map<String, _IconTreeShakerData> _iconData;

  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fs;
  final Artifacts _artifacts;

  /// Whether font subsetting should be used for this [Environment].
  bool get enabled => _fontManifest != null
                   && _environment.defines[kIconTreeShakerFlag] == 'true'
                   && _environment.defines[kBuildMode] != 'debug';

  // Fills the [_iconData] map.
  Future<void> _getIconData(Environment environment) async {
    if (!enabled) {
      return;
    }

    final File appDill = environment.buildDir.childFile('app.dill');
    if (!appDill.existsSync()) {
      throw IconTreeShakerException._('Expected to find kernel file at ${appDill.path}, but no file found.');
    }
    final File constFinder = _fs.file(
      _artifacts.getArtifactPath(Artifact.constFinder),
    );
    final File dart = _fs.file(
      _artifacts.getArtifactPath(Artifact.engineDartBinary),
    );

    final Map<String, List<int>> iconData = await _findConstants(
      dart,
      constFinder,
      appDill,
    );
    final Set<String> familyKeys = iconData.keys.toSet();

    final Map<String, String> fonts = await _parseFontJson(
      _fontManifest,
      familyKeys,
    );

    if (fonts.length != iconData.length) {
      environment.logger.printStatus(
        'Expected to find fonts for ${iconData.keys}, but found '
        '${fonts.keys}. This usually means you are refering to '
        'font families in an IconData class but not including them '
        'in the assets section of your pubspec.yaml, are missing '
        'the package that would include them, or are missing '
        '"uses-material-design: true".',
      );
    }

    final Map<String, _IconTreeShakerData> result = <String, _IconTreeShakerData>{};
    for (final MapEntry<String, String> entry in fonts.entries) {
      result[entry.value] = _IconTreeShakerData(
        family: entry.key,
        relativePath: entry.value,
        codePoints: iconData[entry.key],
      );
    }
    _iconData = result;
  }

  /// Calls font-subset, which transforms the [input] font file to a
  /// subsetted version at [outputPath].
  ///
  /// All parameters are required.
  ///
  /// If [enabled] is false, or the relative path is not recognized as an icon
  /// font used in the Flutter application, this returns false.
  /// If the font-subset subprocess fails, it will [throwToolExit].
  /// Otherwise, it will return true.
  Future<bool> subsetFont({
    @required File input,
    @required String outputPath,
    @required String relativePath,
  }) async {
    if (!enabled) {
      return false;
    }
    if (input.lengthSync() < 12) {
      return false;
    }
    final String mimeType = mime.lookupMimeType(
      input.path,
      headerBytes: await input.openRead(0, 12).first,
    );
    if (!kTtfMimeTypes.contains(mimeType)) {
      return false;
    }
    await (_iconDataProcessing ??= _getIconData(_environment));
    assert(_iconData != null);

    final _IconTreeShakerData iconTreeShakerData = _iconData[relativePath];
    if (iconTreeShakerData == null) {
      return false;
    }

    final File fontSubset = _fs.file(
      _artifacts.getArtifactPath(Artifact.fontSubset),
    );
    if (!fontSubset.existsSync()) {
      throw IconTreeShakerException._('The font-subset utility is missing. Run "flutter doctor".');
    }

    final List<String> cmd = <String>[
      fontSubset.path,
      outputPath,
      input.path,
    ];
    final String codePoints = iconTreeShakerData.codePoints.join(' ');
    _logger.printTrace('Running font-subset: ${cmd.join(' ')}, '
                       'using codepoints $codePoints');
    final Process fontSubsetProcess = await _processManager.start(cmd);
    try {
      fontSubsetProcess.stdin.writeln(codePoints);
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
    return true;
  }

  /// Returns a map of { fontFamly: relativePath } pairs.
  Future<Map<String, String>> _parseFontJson(
    String fontManifestData,
    Set<String> families,
  ) async {
    final Map<String, String> result = <String, String>{};
    final List<Map<String, dynamic>> fontList = _getList(
      json.decode(fontManifestData),
      'FontManifest.json invalid: expected top level to be a list of objects.',
    );

    for (final Map<String, dynamic> map in fontList) {
      if (map['family'] is! String) {
        throw IconTreeShakerException._(
          'FontManifest.json invalid: expected the family value to be a string, '
          'got: ${map['family']}.');
      }
      final String familyKey = map['family'] as String;
      if (!families.contains(familyKey)) {
        continue;
      }
      final List<Map<String, dynamic>> fonts = _getList(
        map['fonts'],
        'FontManifest.json invalid: expected "fonts" to be a list of objects.',
      );
      if (fonts.length != 1) {
        throw IconTreeShakerException._(
          'This tool cannot process icon fonts with multiple fonts in a '
          'single family.');
      }
      if (fonts.first['asset'] is! String) {
        throw IconTreeShakerException._(
          'FontManifest.json invalid: expected "asset" value to be a string, '
          'got: ${map['assets']}.');
      }
      result[familyKey] = fonts.first['asset'] as String;
    }
    return result;
  }

  Future<Map<String, List<int>>> _findConstants(
    File dart,
    File constFinder,
    File appDill,
  ) async {
    final List<String> cmd = <String>[
      dart.path,
      '--disable-dart-dev',
      constFinder.path,
      '--kernel-file', appDill.path,
      '--class-library-uri', 'package:flutter/src/widgets/icon_data.dart',
      '--class-name', 'IconData',
    ];
    _logger.printTrace('Running command: ${cmd.join(' ')}');
    final ProcessResult constFinderProcessResult = await _processManager.run(cmd);

    if (constFinderProcessResult.exitCode != 0) {
      throw IconTreeShakerException._('ConstFinder failure: ${constFinderProcessResult.stderr}');
    }
    final dynamic jsonDecode = json.decode(constFinderProcessResult.stdout as String);
    if (jsonDecode is! Map<String, dynamic>) {
      throw IconTreeShakerException._(
        'Invalid ConstFinder output: expected a top level JSON object, '
        'got $jsonDecode.');
    }
    final Map<String, dynamic> constFinderMap = jsonDecode as Map<String, dynamic>;
    final _ConstFinderResult constFinderResult = _ConstFinderResult(constFinderMap);
    if (constFinderResult.hasNonConstantLocations) {
      _logger.printError('This application cannot tree shake icons fonts. '
                         'It has non-constant instances of IconData at the '
                         'following locations:', emphasis: true);
      for (final Map<String, dynamic> location in constFinderResult.nonConstantLocations) {
        _logger.printError(
          '- ${location['file']}:${location['line']}:${location['column']}',
          indent: 2,
          hangingIndent: 4,
        );
      }
      throwToolExit('Avoid non-constant invocations of IconData or try to '
                    'build again with --no-tree-shake-icons.');
    }
    return _parseConstFinderResult(constFinderResult);
  }

  Map<String, List<int>> _parseConstFinderResult(_ConstFinderResult consts) {
    final Map<String, List<int>> result = <String, List<int>>{};
    for (final Map<String, dynamic> iconDataMap in consts.constantInstances) {
      if ((iconDataMap['fontPackage'] ?? '') is! String || // Null is ok here.
           iconDataMap['fontFamily'] is! String ||
           iconDataMap['codePoint'] is! num) {
        throw IconTreeShakerException._(
          'Invalid ConstFinder result. Expected "fontPackage" to be a String, '
          '"fontFamily" to be a String, and "codePoint" to be an int, '
          'got: $iconDataMap.');
      }
      final String package = iconDataMap['fontPackage'] as String;
      final String family = iconDataMap['fontFamily'] as String;
      final String key = package == null
        ? family
        : 'packages/$package/$family';
      result[key] ??= <int>[];
      result[key].add((iconDataMap['codePoint'] as num).round());
    }
    return result;
  }
}

class _ConstFinderResult {
  _ConstFinderResult(this.result);

  final Map<String, dynamic> result;

  List<Map<String, dynamic>> _constantInstances;
  List<Map<String, dynamic>> get constantInstances {
    _constantInstances ??= _getList(
      result['constantInstances'],
      'Invalid ConstFinder output: Expected "constInstances" to be a list of objects.',
    );
    return _constantInstances;
  }

  List<Map<String, dynamic>> _nonConstantLocations;
  List<Map<String, dynamic>> get nonConstantLocations {
    _nonConstantLocations ??= _getList(
      result['nonConstantLocations'],
      'Invalid ConstFinder output: Expected "nonConstLocations" to be a list ofobjects',
    );
    return _nonConstantLocations;
  }

  bool get hasNonConstantLocations => nonConstantLocations.isNotEmpty;
}

/// The font family name, relative path to font file, and list of code points
/// the application is using.
class _IconTreeShakerData {
  /// All parameters are required.
  const _IconTreeShakerData({
    @required this.family,
    @required this.relativePath,
    @required this.codePoints,
  }) : assert(family != null),
       assert(relativePath != null),
       assert(codePoints != null);

  /// The font family name, e.g. "MaterialIcons".
  final String family;

  /// The relative path to the font file.
  final String relativePath;

  /// The list of code points for the font.
  final List<int> codePoints;

  @override
  String toString() => 'FontSubsetData($family, $relativePath, $codePoints)';
}

class IconTreeShakerException implements Exception {
  IconTreeShakerException._(this.message);

  final String message;

  @override
  String toString() => 'IconTreeShakerException: $message\n\n'
    'To disable icon tree shaking, pass --no-tree-shake-icons to the requested '
    'flutter build command';
}

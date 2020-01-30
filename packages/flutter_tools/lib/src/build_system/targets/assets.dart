// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:pool/pool.dart';

import '../../artifacts.dart';
import '../../asset.dart';
import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../convert.dart';
import '../../devfs.dart';
import '../../globals.dart' as globals;
import '../../plugins.dart';
import '../../project.dart';
import '../build_system.dart';
import '../depfile.dart';
import 'dart.dart';


/// The build define controlling whether icon fonts should be stripped down to
/// only the glyphs used by the application.
const String kFontSubsetFlag = 'FontSubset';

/// Whether icon font subsetting is enabled by default.
const bool kFontSubsetEnabledDefault = false;

/// A helper function to copy an asset bundle into an [environment]'s output
/// directory.
///
/// Returns a [Depfile] containing all assets used in the build.
Future<Depfile> copyAssets(Environment environment, Directory outputDirectory) async {
  if (environment.defines[kFontSubsetFlag] == 'true' && environment.defines[kBuildMode] == 'debug') {
    globals.printError('Font subetting is not supported in debug mode. The --font-subset flag will be ignored.');
  }
  final bool useFontSubset = environment.defines[kFontSubsetFlag] == 'true' && environment.defines[kBuildMode] != 'debug';
  final File pubspecFile =  environment.projectDir.childFile('pubspec.yaml');
  final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
  await assetBundle.build(
    manifestPath: pubspecFile.path,
    packagesPath: environment.projectDir.childFile('.packages').path,
  );
  final Pool pool = Pool(kMaxOpenFiles);
  final List<File> inputs = <File>[
    // An asset manifest with no assets would have zero inputs if not
    // for this pubspec file.
    pubspecFile,
  ];
  final List<File> outputs = <File>[];

  final Map<String, FontSubsetData> iconData = useFontSubset
    ? await _getIconData(
        environment,
        assetBundle.entries[kFontManifestJson] as DevFSStringContent,
      )
    : <String, FontSubsetData>{};

  await Future.wait<void>(
    assetBundle.entries.entries.map<Future<void>>((MapEntry<String, DevFSContent> entry) async {
      final PoolResource resource = await pool.request();
      try {
        // This will result in strange looking files, for example files with `/`
        // on Windows or files that end up getting URI encoded such as `#.ext`
        // to `%23.ext`.  However, we have to keep it this way since the
        // platform channels in the framework will URI encode these values,
        // and the native APIs will look for files this way.
        final File file = globals.fs.file(globals.fs.path.join(outputDirectory.path, entry.key));
        outputs.add(file);
        file.parent.createSync(recursive: true);
        final DevFSContent content = entry.value;
        if (content is DevFSFileContent && content.file is File) {
          inputs.add(globals.fs.file(content.file.path));
          final FontSubsetData fontSubsetData = iconData[entry.key];
          if (fontSubsetData != null) {
            assert(useFontSubset);
            await _subsetFont(
              environment: environment,
              inputPath: content.file.path,
              outputPath: file.path,
              fontSubsetData: fontSubsetData,
            );
          } else {
            await (content.file as File).copy(file.path);
          }
        } else {
          await file.writeAsBytes(await entry.value.contentsAsBytes());
        }
      } finally {
        resource.release();
      }
  }));
  return Depfile(inputs, outputs);
}

/// Returns a map of [FontSubsetData] keyed by relative path.
Future<Map<String, FontSubsetData>> _getIconData(Environment environment, DevFSStringContent fontManifest) async {
  final File appDill = environment.buildDir.childFile('app.dill');

  final File constFinder = globals.fs.file(globals.artifacts.getArtifactPath(Artifact.constFinder));
  final File dart = globals.fs.file(globals.artifacts.getArtifactPath(Artifact.engineDartBinary));

  final Map<String, List<int>> iconData = await _findConstants(dart, constFinder, appDill);
  final Set<String> familyKeys = iconData.keys.toSet();

  final Map<String, String> fonts = await _parseFontJson(fontManifest.string, familyKeys);

  if (fonts.length != iconData.length) {
    throwToolExit('Expected to find fonts for ${iconData.keys}, but found ${fonts.keys}.');
  }

  final Map<String, FontSubsetData> result = <String, FontSubsetData>{};
  for (final MapEntry<String, String> entry in fonts.entries) {
    result[entry.value] = FontSubsetData(
      family: entry.key,
      relativePath: entry.value,
      codePoints: iconData[entry.key],
    );
  }
  return result;
}

/// Calls font-subset, which transforms the [inputPath] font file to a subsetted
/// version containing only the [FontSubsetData.codePoints] at [outputPath].
Future<void> _subsetFont({
  @required Environment environment,
  @required String inputPath,
  @required String outputPath,
  @required FontSubsetData fontSubsetData,
}) async {
  final File fontSubset = globals.fs.file(globals.artifacts.getArtifactPath(Artifact.fontSubset));

  final List<String> cmd = <String>[
    fontSubset.path,
    outputPath,
    inputPath,
  ];
  final String codePoints = fontSubsetData.codePoints.join(' ');
  globals.printTrace('Running font-subset: ${cmd.join(' ')}, using codepoints $codePoints');
  final Process fontSubsetProcess = await globals.processManager.start(cmd);
  fontSubsetProcess.stdin.writeln(codePoints);
  await fontSubsetProcess.stdin.flush();
  await fontSubsetProcess.stdin.close();

  final int code = await fontSubsetProcess.exitCode;
  if (code != 0) {
    globals.printTrace(await utf8.decodeStream(fontSubsetProcess.stdout));
    globals.printError(await utf8.decodeStream(fontSubsetProcess.stderr));
    throwToolExit('Font subsetting failed with exit code $code.');
  }
}

List<Map<String, dynamic>> _getList(dynamic object) {
  assert(object is List<dynamic>);
  return (object as List<dynamic>).cast<Map<String, dynamic>>();
}

/// Returns a map of { fontFamly: relativePath } pairs.
Future<Map<String, String>> _parseFontJson(String fontManifestData, Set<String> families) async {
  final Map<String, String> result = <String, String>{};
  final List<Map<String, dynamic>> fontList = _getList(json.decode(fontManifestData));
  for (final Map<String, dynamic> map in fontList) {
    final String familyKey = map['family'] as String;
    if (families.contains(familyKey)) {
      final List<Map<String, dynamic>> fonts = _getList(map['fonts']);
      if (fonts.length != 1) {
        throwToolExit('This tool cannot process icon fonts with multiple fonts in a single family.');
      }
      result[familyKey] = fonts.first['asset'] as String;
    }
  }
  return result;
}

Future<Map<String, List<int>>> _findConstants(File dart, File constFinder, File appDill) async {
  final List<String> cmd = <String>[
    dart.path,
    constFinder.path,
    '--kernel-file', appDill.path,
    '--class-library-uri', 'package:flutter/src/widgets/icon_data.dart',
    '--class-name', 'IconData',
  ];
  globals.printTrace('Running command: ${cmd.join(' ')}');
  final ProcessResult constFinderProcessResult = await globals.processManager.run(cmd);

  if (constFinderProcessResult.exitCode != 0) {
    throwToolExit('ConstFinder failure: ${constFinderProcessResult.stderr}');
  }
  final Map<String, dynamic> constFinderMap = json.decode(constFinderProcessResult.stdout as String) as Map<String, dynamic>;
  final ConstFinderResult constFinderResult = ConstFinderResult(constFinderMap);
  if (constFinderResult.hasNonConstantLocations) {
    globals.printError('This application cannot tree shake icons fonts. It has non-constant instances of IconData at the following locations:', emphasis: true);
    for (final Map<String, dynamic> location in constFinderResult.nonConstantLocations) {
      globals.printError('- ${location['file']}:${location['line']}:${location['column']}', indent: 2, hangingIndent: 4);
    }
    throwToolExit('Avoid non-constant invocations of IconData or try to build again without --shake-icon-fonts.');
  }
  return _parseConstFinderResult(constFinderResult);
}

Map<String, List<int>> _parseConstFinderResult(ConstFinderResult consts) {
  final Map<String, List<int>> result = <String, List<int>>{};
  for (final Map<String, dynamic> iconDataMap in consts.constantInstances) {
    final String package = iconDataMap['fontPackage'] as String;
    final String family = iconDataMap['fontFamily'] as String;
    final String key = package == null
      ? family
      : 'packages/$package/$family';
    result[key] ??= <int>[];
    result[key].add(iconDataMap['codePoint'] as int);
  }
  return result;
}

/// Copy the assets defined in the flutter manifest into a build directory.
class CopyAssets extends Target {
  const CopyAssets();

  @override
  String get name => 'copy_assets';

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/assets.dart'),
  ];

  @override
  List<Source> get outputs => const <Source>[];

  @override
  List<String> get depfiles => const <String>[
    'flutter_assets.d'
  ];

  @override
  Future<void> build(Environment environment) async {
    final Directory output = environment
      .buildDir
      .childDirectory('flutter_assets');
    output.createSync(recursive: true);
    final Depfile depfile = await copyAssets(environment, output);
    depfile.writeToFile(environment.buildDir.childFile('flutter_assets.d'));
  }
}

/// Rewrites the `.flutter-plugins` file of [project] based on the plugin
/// dependencies declared in `pubspec.yaml`.
// TODO(jonahwiliams): this should be per platform and located in build
// outputs.
class FlutterPlugins extends Target {
  const FlutterPlugins();

  @override
  String get name => 'flutter_plugins';

  @override
  List<Target> get dependencies => const <Target>[];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/assets.dart'),
    Source.pattern('{PROJECT_DIR}/pubspec.yaml'),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{PROJECT_DIR}/.flutter-plugins'),
  ];

  @override
  Future<void> build(Environment environment) async {
    // The pubspec may change for reasons other than plugins changing, so we compare
    // the manifest before writing. Some hosting build systems use timestamps
    // so we need to be careful to avoid tricking them into doing more work than
    // necessary.
    final FlutterProject project = FlutterProject.fromDirectory(environment.projectDir);
    final List<Plugin> plugins = findPlugins(project);
    final String pluginManifest = plugins
      .map<String>((Plugin p) => '${p.name}=${fsUtils.escapePath(p.path)}')
      .join('\n');
    final File flutterPluginsFile = environment.projectDir.childFile('.flutter-plugins');
    if (!flutterPluginsFile.existsSync() || flutterPluginsFile.readAsStringSync() != pluginManifest) {
      flutterPluginsFile.writeAsStringSync(pluginManifest);
    }
  }
}

class ConstFinderResult {
  const ConstFinderResult(this.result);

  final Map<String, dynamic> result;
  List<Map<String, dynamic>> get constantInstances => _getList(result['constantInstances']);
  List<Map<String, dynamic>> get nonConstantLocations => _getList(result['nonConstantLocations']);

  bool get hasNonConstantLocations => nonConstantLocations.isNotEmpty;
}

class FontSubsetData {
  const FontSubsetData({
    @required this.family,
    @required this.relativePath,
    @required this.codePoints,
  }) : assert(family != null),
       assert(relativePath != null),
       assert(codePoints != null);

  final String family;
  final String relativePath;
  final List<int> codePoints;

  @override
  String toString() => 'FontSubsetData($family, $relativePath, $codePoints)';
}
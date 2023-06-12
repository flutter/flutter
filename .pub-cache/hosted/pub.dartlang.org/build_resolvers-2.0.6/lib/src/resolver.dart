// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';
import 'package:yaml/yaml.dart';

import 'analysis_driver.dart';
import 'build_asset_uri_resolver.dart';
import 'human_readable_duration.dart';

final _logger = Logger('build_resolvers');

Future<String> _packagePath(String package) async {
  var libRoot = await Isolate.resolvePackageUri(Uri.parse('package:$package/'));
  return p.dirname(p.fromUri(libRoot));
}

/// Implements [Resolver.libraries] and [Resolver.findLibraryByName] by crawling
/// down from entrypoints.
class PerActionResolver implements ReleasableResolver {
  final AnalyzerResolver _delegate;
  final BuildStep _step;

  final _entryPoints = <AssetId>{};

  PerActionResolver(this._delegate, this._step);

  @override
  Stream<LibraryElement> get libraries async* {
    await _resolveIfNecessary(_step.inputId, transitive: true);

    final seen = <LibraryElement>{};
    final toVisit = Queue<LibraryElement>();

    // keep a copy of entry points in case [_resolveIfNecessary] is called
    // before this stream is done.
    final entryPoints = _entryPoints.toList();
    for (final entryPoint in entryPoints) {
      if (!await _delegate.isLibrary(entryPoint)) continue;
      final library =
          await _delegate.libraryFor(entryPoint, allowSyntaxErrors: true);
      toVisit.add(library);
      seen.add(library);
    }
    while (toVisit.isNotEmpty) {
      final current = toVisit.removeFirst();
      // TODO - avoid crawling or returning libraries which are not visible via
      // `BuildStep.canRead`. They'd still be reachable by crawling the element
      // model manually.
      yield current;
      final toCrawl = current.importedLibraries
          .followedBy(current.exportedLibraries)
          .where((l) => !seen.contains(l))
          .toSet();
      toVisit.addAll(toCrawl);
      seen.addAll(toCrawl);
    }
  }

  @override
  Future<LibraryElement?> findLibraryByName(String libraryName) async {
    await for (final library in libraries) {
      if (library.name == libraryName) return library;
    }
  }

  @override
  Future<bool> isLibrary(AssetId assetId) async {
    if (!await _step.canRead(assetId)) return false;
    await _resolveIfNecessary(assetId, transitive: false);
    return _delegate.isLibrary(assetId);
  }

  @override
  Future<AstNode?> astNodeFor(Element element, {bool resolve = false}) =>
      _delegate.astNodeFor(element, resolve: resolve);

  @override
  Future<CompilationUnit> compilationUnitFor(AssetId assetId,
      {bool allowSyntaxErrors = false}) async {
    if (!await _step.canRead(assetId)) throw AssetNotFoundException(assetId);
    await _resolveIfNecessary(assetId, transitive: false);
    return _delegate.compilationUnitFor(assetId,
        allowSyntaxErrors: allowSyntaxErrors);
  }

  @override
  Future<LibraryElement> libraryFor(AssetId assetId,
      {bool allowSyntaxErrors = false}) async {
    if (!await _step.canRead(assetId)) throw AssetNotFoundException(assetId);
    await _resolveIfNecessary(assetId, transitive: true);
    return _delegate.libraryFor(assetId, allowSyntaxErrors: allowSyntaxErrors);
  }

  // Ensures that we finish resolving one thing before attempting to resolve
  // another, otherwise there are race conditions with `_entryPoints` being
  // updated before it is actually ready, or resolved more than once.
  final _resolvePool = Pool(1);
  Future<void> _resolveIfNecessary(AssetId id, {required bool transitive}) =>
      _resolvePool.withResource(() async {
        if (!_entryPoints.contains(id)) {
          // We only want transitively resolved ids in `_entrypoints`.
          if (transitive) _entryPoints.add(id);

          // the resolver will only visit assets that haven't been resolved in this
          // step yet
          await _delegate._uriResolver.performResolve(
              _step, [id], _delegate._driver,
              transitive: transitive);
        }
      });

  @override
  void release() {
    _delegate._uriResolver.notifyComplete(_step);
    _delegate.release();
  }

  @override
  Future<AssetId> assetIdForElement(Element element) =>
      _delegate.assetIdForElement(element);
}

class AnalyzerResolver implements ReleasableResolver {
  final BuildAssetUriResolver _uriResolver;
  final AnalysisDriverForPackageBuild _driver;

  AnalyzerResolver(this._driver, this._uriResolver);

  @override
  Future<bool> isLibrary(AssetId assetId) async {
    if (assetId.extension != '.dart') return false;
    if (!_driver.isUriOfExistingFile(assetId.uri)) return false;
    var result =
        _driver.currentSession.getFile(assetPath(assetId)) as FileResult;
    return !result.isPart;
  }

  @override
  Future<AstNode?> astNodeFor(Element element, {bool resolve = false}) async {
    var session = _driver.currentSession;
    final library = element.library;
    if (library == null) {
      // Invalid elements (e.g. an MultiplyDefinedElement) are not part of any
      // library and can't be resolved like this.
      return null;
    }
    var path = library.source.fullName;

    if (resolve) {
      return (await session.getResolvedLibrary(path) as ResolvedLibraryResult)
          .getElementDeclaration(element)
          ?.node;
    } else {
      return (session.getParsedLibrary(path) as ParsedLibraryResult)
          .getElementDeclaration(element)
          ?.node;
    }
  }

  @override
  Future<CompilationUnit> compilationUnitFor(AssetId assetId,
      {bool allowSyntaxErrors = false}) async {
    if (!_driver.isUriOfExistingFile(assetId.uri)) {
      throw AssetNotFoundException(assetId);
    }

    var path = assetPath(assetId);
    var parsedResult =
        _driver.currentSession.getParsedUnit(path) as ParsedUnitResult;
    if (!allowSyntaxErrors && parsedResult.errors.isNotEmpty) {
      throw SyntaxErrorInAssetException(assetId, [parsedResult]);
    }
    return parsedResult.unit;
  }

  @override
  Future<LibraryElement> libraryFor(AssetId assetId,
      {bool allowSyntaxErrors = false}) async {
    var uri = assetId.uri;
    if (!_driver.isUriOfExistingFile(uri)) {
      throw AssetNotFoundException(assetId);
    }

    var path = assetPath(assetId);
    var parsedResult = _driver.currentSession.getParsedUnit(path);
    if (parsedResult is! ParsedUnitResult || parsedResult.isPart) {
      throw NonLibraryAssetException(assetId);
    }

    final library = await _driver.currentSession.getLibraryByUri(uri.toString())
        as LibraryElementResult;
    if (!allowSyntaxErrors) {
      final errors = await _syntacticErrorsFor(library.element);
      if (errors.isNotEmpty) {
        throw SyntaxErrorInAssetException(assetId, errors);
      }
    }

    return library.element;
  }

  /// Finds syntax errors in files related to the [element].
  ///
  /// This includes the main library and existing part files.
  Future<List<ErrorsResult>> _syntacticErrorsFor(LibraryElement element) async {
    final existingElements = [
      element,
      for (final part in element.parts)
        // The source may be null if the part doesn't exist. That's not
        // important for us since we only care about syntax
        if (part.source.exists()) part,
    ];

    // Map from elements to absolute paths
    final paths = existingElements
        .map((part) => _uriResolver.lookupCachedAsset(part.source.uri))
        .whereType<AssetId>() // filter out nulls
        .map(assetPath);

    final relevantResults = <ErrorsResult>[];

    for (final path in paths) {
      final result =
          await _driver.currentSession.getErrors(path) as ErrorsResult;
      if (result.errors
          .any((error) => error.errorCode.type == ErrorType.SYNTACTIC_ERROR)) {
        relevantResults.add(result);
      }
    }

    return relevantResults;
  }

  @override
  // Do nothing
  void release() {}

  @override
  Stream<LibraryElement> get libraries {
    // We don't know what libraries to expose without leaking libraries written
    // by later phases.
    throw UnimplementedError();
  }

  @override
  Future<LibraryElement> findLibraryByName(String libraryName) {
    // We don't know what libraries to expose without leaking libraries written
    // by later phases.
    throw UnimplementedError();
  }

  @override
  Future<AssetId> assetIdForElement(Element element) async {
    final source = element.source;
    if (source == null) {
      throw UnresolvableAssetException(
          '${element.name} does not have a source');
    }

    final uri = source.uri;
    if (!uri.isScheme('package') && !uri.isScheme('asset')) {
      throw UnresolvableAssetException('${element.name} in ${source.uri}');
    }
    return AssetId.resolve(source.uri);
  }
}

class AnalyzerResolvers implements Resolvers {
  /// Nullable, the default analysis options are used if not provided.
  final AnalysisOptions _analysisOptions;

  /// A function that returns the path to the SDK summary when invoked.
  ///
  /// Defaults to [_defaultSdkSummaryGenerator].
  final Future<String> Function() _sdkSummaryGenerator;

  // Lazy, all access must be preceded by a call to `_ensureInitialized`.
  late final AnalyzerResolver _resolver;
  BuildAssetUriResolver? _uriResolver;

  /// Nullable, should not be accessed outside of [_ensureInitialized].
  Future<Result<void>>? _initialized;

  PackageConfig? _packageConfig;

  /// Lazily creates and manages a single [AnalysisDriverForPackageBuild],that
  /// can be shared across [BuildStep]s.
  ///
  /// If no [_analysisOptions] is provided, then an empty one is used.
  ///
  /// If no [sdkSummaryGenerator] is provided, a default one is used that only
  /// works for typical `pub` packages.
  ///
  /// If no [_packageConfig] is provided, then one is created from the current
  /// [Isolate.packageConfig].
  ///
  /// **NOTE**: The [_packageConfig] is not used for path resolution, it is
  /// primarily used to get the language versions. Any other data (including
  /// extra data), may be passed to the analyzer on an as needed basis.
  AnalyzerResolvers(
      [AnalysisOptions? analysisOptions,
      Future<String> Function()? sdkSummaryGenerator,
      this._packageConfig])
      : _analysisOptions = analysisOptions ??
            (AnalysisOptionsImpl()
              ..contextFeatures =
                  _featureSet(enableExperiments: enabledExperiments)),
        _sdkSummaryGenerator =
            sdkSummaryGenerator ?? _defaultSdkSummaryGenerator;

  /// Create a Resolvers backed by an `AnalysisContext` using options
  /// [_analysisOptions].
  Future<void> _ensureInitialized() {
    return Result.release(_initialized ??= Result.capture(() async {
      _warnOnLanguageVersionMismatch();
      final uriResolver = _uriResolver = BuildAssetUriResolver();
      final loadedConfig = _packageConfig ??=
          await loadPackageConfigUri((await Isolate.packageConfig)!);
      var driver = await analysisDriver(uriResolver, _analysisOptions,
          await _sdkSummaryGenerator(), loadedConfig);
      _resolver = AnalyzerResolver(driver, uriResolver);
    }()));
  }

  @override
  Future<ReleasableResolver> get(BuildStep buildStep) async {
    await _ensureInitialized();
    return PerActionResolver(_resolver, buildStep);
  }

  /// Must be called between each build.
  @override
  void reset() {
    _uriResolver?.reset();
  }
}

/// Lazily creates a summary of the users SDK and caches it under
/// `.dart_tool/build_resolvers`.
///
/// This is only intended for use in typical dart packages, which must
/// have an already existing `.dart_tool` directory (this is how we
/// validate we are running under a typical dart package and not a custom
/// environment).
Future<String> _defaultSdkSummaryGenerator() async {
  var dartToolPath = '.dart_tool';
  if (!await Directory(dartToolPath).exists()) {
    throw StateError(
        'The default analyzer resolver can only be used when the current '
        'working directory is a standard pub package.');
  }

  var cacheDir = p.join(dartToolPath, 'build_resolvers');
  var summaryPath = p.join(cacheDir, 'sdk.sum');
  var depsFile = File('$summaryPath.deps');
  var summaryFile = File(summaryPath);

  var currentDeps = {
    'sdk': Platform.version,
    for (var package in _packageDepsToCheck)
      package: await _packagePath(package),
  };

  // Invalidate existing summary/version/analyzer files if present.
  if (await depsFile.exists()) {
    if (!await _checkDeps(depsFile, currentDeps)) {
      await depsFile.delete();
      if (await summaryFile.exists()) await summaryFile.delete();
    }
  } else if (await summaryFile.exists()) {
    // Fallback for cases where we could not do a proper version check.
    await summaryFile.delete();
  }

  // Generate the summary and version files if necessary.
  if (!await summaryFile.exists()) {
    var watch = Stopwatch()..start();
    _logger.info('Generating SDK summary...');
    await summaryFile.create(recursive: true);
    final embedderYamlPath =
        isFlutter ? p.join(_dartUiPath, '_embedder.yaml') : null;
    await summaryFile.writeAsBytes(buildSdkSummary(
        sdkPath: _runningDartSdkPath,
        resourceProvider: PhysicalResourceProvider.INSTANCE,
        embedderYamlPath: embedderYamlPath));

    await _createDepsFile(depsFile, currentDeps);
    watch.stop();
    _logger.info('Generating SDK summary completed, took '
        '${humanReadable(watch.elapsed)}\n');
  }

  return p.absolute(summaryPath);
}

final _packageDepsToCheck = ['analyzer', 'build_resolvers'];

Future<bool> _checkDeps(
    File versionsFile, Map<String, Object?> currentDeps) async {
  var previous =
      jsonDecode(await versionsFile.readAsString()) as Map<String, Object?>;

  if (previous.keys.length != currentDeps.keys.length) return false;

  for (var entry in previous.entries) {
    if (entry.value != currentDeps[entry.key]) return false;
  }

  return true;
}

Future<void> _createDepsFile(
    File depsFile, Map<String, Object?> currentDeps) async {
  await depsFile.create(recursive: true);
  await depsFile.writeAsString(jsonEncode(currentDeps));
}

/// Checks that the current analyzer version supports the current language
/// version.
void _warnOnLanguageVersionMismatch() async {
  if (sdkLanguageVersion <= ExperimentStatus.currentVersion) return;

  try {
    var client = HttpClient();
    var request = await client
        .getUrl(Uri.https('pub.dartlang.org', 'api/packages/analyzer'));
    var response = await request.close();
    var content = StringBuffer();
    await response.transform(utf8.decoder).listen(content.write).asFuture();
    var json = jsonDecode(content.toString());
    var latestAnalyzer = json['latest']['version'];
    var analyzerPubspecPath =
        p.join(await _packagePath('analyzer'), 'pubspec.yaml');
    var currentAnalyzer =
        loadYaml(await File(analyzerPubspecPath).readAsString())['version'];

    if (latestAnalyzer == currentAnalyzer) {
      log.warning('''
The latest `analyzer` version may not fully support your current SDK version.

Analyzer language version: ${ExperimentStatus.currentVersion}
SDK language version: $sdkLanguageVersion

Check for an open issue at:
https://github.com/dart-lang/sdk/issues?q=is%3Aissue+is%3Aopen+No+published+analyzer+$sdkLanguageVersion
and thumbs up and/or subscribe to the existing issue, or file a new issue at
https://github.com/dart-lang/sdk/issues/new with the title
"No published analyzer available for language version $sdkLanguageVersion".
    ''');
    } else {
      var upgradeCommand =
          isFlutter ? 'flutter packages upgrade' : 'pub upgrade';
      log.warning('''
Your current `analyzer` version may not fully support your current SDK version.

Analyzer language version: ${ExperimentStatus.currentVersion}
SDK language version: $sdkLanguageVersion

Please update to the latest `analyzer` version ($latestAnalyzer) by running
`$upgradeCommand`.

If you are not getting the latest version by running the above command, you
can try adding a constraint like the following to your pubspec to start
diagnosing why you can't get the latest version:

dev_dependencies:
  analyzer: ^$latestAnalyzer
''');
    }
  } catch (_) {
    // Fall back on a basic message if we fail to detect the latest version for
    // any reason.
    log.warning('''
Your current `analyzer` version may not fully support your current SDK version.

Analyzer language version: ${ExperimentStatus.currentVersion}
SDK language version: $sdkLanguageVersion

Please ensure you are on the latest `analyzer` version, which can be seen at
https://pub.dev/packages/analyzer.
''');
  }
}

/// Path where the dart:ui package will be found, if executing via the dart
/// binary provided by the Flutter SDK.
final _dartUiPath =
    p.normalize(p.join(_runningDartSdkPath, '..', 'pkg', 'sky_engine', 'lib'));

/// The current feature set based on the current sdk version and enabled
/// experiments.
FeatureSet _featureSet({List<String> enableExperiments = const []}) {
  if (enableExperiments.isNotEmpty &&
      sdkLanguageVersion > ExperimentStatus.currentVersion) {
    log.warning('''
Attempting to enable experiments `$enableExperiments`, but the current SDK
language version does not match your `analyzer` package language version:

Analyzer language version: ${ExperimentStatus.currentVersion}
SDK language version: $sdkLanguageVersion

In order to use experiments you may need to upgrade or downgrade your
`analyzer` package dependency such that its language version matches that of
your current SDK, see https://github.com/dart-lang/build/issues/2685.

Note that you may or may not have a direct dependency on the `analyzer`
package in your `pubspec.yaml`, so you may have to add that. You can see your
current version by running `pub deps`.
''');
  }
  return FeatureSet.fromEnableFlags2(
      sdkLanguageVersion: sdkLanguageVersion, flags: enableExperiments);
}

/// Path to the running dart's SDK root.
final _runningDartSdkPath = p.dirname(p.dirname(Platform.resolvedExecutable));

/// `true` if the currently running dart was provided by the Flutter SDK.
final isFlutter =
    Platform.version.contains('flutter') || Directory(_dartUiPath).existsSync();

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_config/build_config.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../environment/build_environment.dart';
import '../package_graph/package_graph.dart';
import '../package_graph/target_graph.dart';
import '../util/hash.dart';
import 'exceptions.dart';

/// The default list of files visible for non-root packages.
///
/// This is also the default list of files for targets in non-root packages when
/// an explicit include is not provided.
const List<String> defaultNonRootVisibleAssets = [
  'CHANGELOG*',
  'lib/**',
  'bin/**',
  'LICENSE*',
  'pubspec.yaml',
  'README*',
];

/// The default list of files to include when an explicit include is not
/// provided.
///
/// This should be a superset of [defaultNonRootVisibleAssets].
const List<String> defaultRootPackageSources = [
  'assets/**',
  'benchmark/**',
  'bin/**',
  'CHANGELOG*',
  'example/**',
  'lib/**',
  'test/**',
  'tool/**',
  'web/**',
  'node/**',
  'LICENSE*',
  'pubspec.yaml',
  'pubspec.lock',
  'README*',
  r'$package$',
];

final _logger = Logger('BuildOptions');

class LogSubscription {
  factory LogSubscription(BuildEnvironment environment,
      {bool verbose, Level logLevel}) {
    // Set up logging
    verbose ??= false;
    logLevel ??= verbose ? Level.ALL : Level.INFO;

    // Severe logs can fail the build and should always be shown.
    if (logLevel == Level.OFF) logLevel = Level.SEVERE;

    Logger.root.level = logLevel;

    var logListener = Logger.root.onRecord.listen(environment.onLog);
    return LogSubscription._(logListener);
  }

  LogSubscription._(this.logListener);

  final StreamSubscription<LogRecord> logListener;
}

/// Describes a set of files that should be built.
class BuildFilter {
  /// The package name glob that files must live under in order to match.
  final Glob _package;

  /// A glob for files under [_package] that must match.
  final Glob _path;

  BuildFilter(this._package, this._path);

  /// Builds a [BuildFilter] from a command line argument.
  ///
  /// Both relative paths and package: uris are supported. Relative
  /// paths are treated as relative to the [rootPackage].
  ///
  /// Globs are supported in package names and paths.
  factory BuildFilter.fromArg(String arg, String rootPackage) {
    var uri = Uri.parse(arg);
    if (uri.scheme == 'package') {
      var package = uri.pathSegments.first;
      var glob = Glob(p.url.joinAll([
        'lib',
        ...uri.pathSegments.skip(1),
      ]));
      return BuildFilter(Glob(package), glob);
    } else if (uri.scheme.isEmpty) {
      return BuildFilter(Glob(rootPackage), Glob(uri.path));
    } else {
      throw FormatException('Unsupported scheme ${uri.scheme}', uri);
    }
  }

  /// Returns whether or not [id] mathes this filter.
  bool matches(AssetId id) =>
      _package.matches(id.package) && _path.matches(id.path);

  @override
  int get hashCode {
    var hash = 0;
    hash = hashCombine(hash, _package.context.hashCode);
    hash = hashCombine(hash, _package.pattern.hashCode);
    hash = hashCombine(hash, _package.recursive.hashCode);
    hash = hashCombine(hash, _path.context.hashCode);
    hash = hashCombine(hash, _path.pattern.hashCode);
    hash = hashCombine(hash, _path.recursive.hashCode);
    return hashComplete(hash);
  }

  @override
  bool operator ==(Object other) =>
      other is BuildFilter &&
      other._path.context == _path.context &&
      other._path.pattern == _path.pattern &&
      other._path.recursive == _path.recursive &&
      other._package.context == _package.context &&
      other._package.pattern == _package.pattern &&
      other._package.recursive == _package.recursive;
}

/// Manages setting up consistent defaults for all options and build modes.
class BuildOptions {
  final bool deleteFilesByDefault;
  final bool enableLowResourcesMode;
  final StreamSubscription logListener;

  /// If present, the path to a directory to write performance logs to.
  final String logPerformanceDir;

  final PackageGraph packageGraph;
  final Resolvers resolvers;
  final TargetGraph targetGraph;
  final bool trackPerformance;

  // Watch mode options.
  Duration debounceDelay;

  // For testing only, skips the build script updates check.
  bool skipBuildScriptCheck;

  BuildOptions._({
    @required this.debounceDelay,
    @required this.deleteFilesByDefault,
    @required this.enableLowResourcesMode,
    @required this.logListener,
    @required this.packageGraph,
    @required this.skipBuildScriptCheck,
    @required this.trackPerformance,
    @required this.targetGraph,
    @required this.logPerformanceDir,
    @required this.resolvers,
  });

  /// Creates a [BuildOptions] with sane defaults.
  ///
  /// NOTE: If a custom [resolvers] instance is passed it must ensure that it
  /// enables [enabledExperiments] on any analysis options it creates.
  static Future<BuildOptions> create(
    LogSubscription logSubscription, {
    Duration debounceDelay,
    bool deleteFilesByDefault,
    bool enableLowResourcesMode,
    @required PackageGraph packageGraph,
    Map<String, BuildConfig> overrideBuildConfig,
    bool skipBuildScriptCheck,
    bool trackPerformance,
    String logPerformanceDir,
    Resolvers resolvers,
  }) async {
    TargetGraph targetGraph;
    try {
      targetGraph = await TargetGraph.forPackageGraph(packageGraph,
          overrideBuildConfig: overrideBuildConfig,
          defaultRootPackageSources: defaultRootPackageSources,
          requiredSourcePaths: [r'lib/$lib$'],
          requiredRootSourcePaths: [r'$package$', r'lib/$lib$']);
    } on BuildConfigParseException catch (e, s) {
      _logger.severe('''
Failed to parse `build.yaml` for ${e.packageName}.

If you believe you have gotten this message in error, especially if using a new
feature, you may need to run `pub run build_runner clean` and then rebuild.
''', e.exception, s);
      throw CannotBuildException();
    }

    /// Set up other defaults.
    debounceDelay ??= const Duration(milliseconds: 250);
    deleteFilesByDefault ??= false;
    skipBuildScriptCheck ??= false;
    enableLowResourcesMode ??= false;
    trackPerformance ??= false;
    if (logPerformanceDir != null) {
      // Requiring this to be under the root package allows us to use an
      // `AssetWriter` to write logs.
      if (!p.isWithin(p.current, logPerformanceDir)) {
        _logger.severe('Performance logs may only be output under the root '
            'package, but got `$logPerformanceDir` which is not.');
        throw CannotBuildException();
      }
      trackPerformance = true;
    }
    resolvers ??= AnalyzerResolvers();

    return BuildOptions._(
      debounceDelay: debounceDelay,
      deleteFilesByDefault: deleteFilesByDefault,
      enableLowResourcesMode: enableLowResourcesMode,
      logListener: logSubscription.logListener,
      packageGraph: packageGraph,
      skipBuildScriptCheck: skipBuildScriptCheck,
      trackPerformance: trackPerformance,
      targetGraph: targetGraph,
      logPerformanceDir: logPerformanceDir,
      resolvers: resolvers,
    );
  }
}

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart' as file_system;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/context/builder.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/sdk/sdk.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/engine.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/java_io.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/source.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/source_io.dart'; // ignore: implementation_imports
import 'package:analyzer/src/task/options.dart'; // ignore: implementation_imports
import 'package:linter/src/rules.dart' as linter; // ignore: implementation_imports
import 'package:cli_util/cli_util.dart' as cli_util;
import 'package:package_config/packages.dart' show Packages;
import 'package:package_config/src/packages_impl.dart' show MapPackages; // ignore: implementation_imports
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';

import '../base/file_system.dart' hide IOSink;
import '../base/io.dart';

class AnalysisDriver {
  AnalysisDriver(this.options) {
    AnalysisEngine.instance.logger =
        new _StdLogger(outSink: options.outSink, errorSink: options.errorSink);
    _processPlugins();
  }

  final Set<Source> _analyzedSources = new HashSet<Source>();

  AnalysisOptionsProvider analysisOptionsProvider =
      new AnalysisOptionsProvider();

  file_system.ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

  AnalysisContext context;

  DriverOptions options;

  String get sdkDir {
    return options.dartSdkPath ?? fs.path.absolute(cli_util.getSdkDir().path);
  }

  List<AnalysisErrorDescription> analyze(Iterable<File> files) {
    final List<AnalysisErrorInfo> infos = _analyze(files);
    final List<AnalysisErrorDescription> errors = <AnalysisErrorDescription>[];
    for (AnalysisErrorInfo info in infos) {
      for (AnalysisError error in info.errors) {
        if (!_isFiltered(error))
          errors.add(new AnalysisErrorDescription(error, info.lineInfo));
      }
    }
    return errors;
  }

  List<AnalysisErrorInfo> _analyze(Iterable<File> files) {
    context = AnalysisEngine.instance.createAnalysisContext();
    _processAnalysisOptions();
    context.analysisOptions = options;
    final PackageInfo packageInfo = new PackageInfo(options.packageMap);
    final List<UriResolver> resolvers = _getResolvers(context, packageInfo.asMap());
    context.sourceFactory =
        new SourceFactory(resolvers, packageInfo.asPackages());

    final List<Source> sources = <Source>[];
    final ChangeSet changeSet = new ChangeSet();
    for (File file in files) {
      final JavaFile sourceFile = new JavaFile(fs.path.normalize(file.absolute.path));
      Source source = new FileBasedSource(sourceFile, sourceFile.toURI());
      final Uri uri = context.sourceFactory.restoreUri(source);
      if (uri != null) {
        source = new FileBasedSource(sourceFile, uri);
      }
      sources.add(source);
      changeSet.addedSource(source);
    }
    context.applyChanges(changeSet);

    final List<AnalysisErrorInfo> infos = <AnalysisErrorInfo>[];
    for (Source source in sources) {
      context.computeErrors(source);
      infos.add(context.getErrors(source));
      _analyzedSources.add(source);
    }

    return infos;
  }

  List<UriResolver> _getResolvers(InternalAnalysisContext context,
      Map<String, List<file_system.Folder>> packageMap) {

    // Create our list of resolvers.
    final List<UriResolver> resolvers = <UriResolver>[];

    // Look for an embedder.
    final EmbedderYamlLocator locator = new EmbedderYamlLocator(packageMap);
    if (locator.embedderYamls.isNotEmpty) {
      // Create and configure an embedded SDK.
      final EmbedderSdk sdk = new EmbedderSdk(PhysicalResourceProvider.INSTANCE, locator.embedderYamls);
      // Fail fast if no URI mappings are found.
      assert(sdk.libraryMap.size() > 0);
      sdk.analysisOptions = context.analysisOptions;

      resolvers.add(new DartUriResolver(sdk));
    } else {
      // Fall back to a standard SDK if no embedder is found.
      final FolderBasedDartSdk sdk = new FolderBasedDartSdk(resourceProvider,
          PhysicalResourceProvider.INSTANCE.getFolder(sdkDir));
      sdk.analysisOptions = context.analysisOptions;

      resolvers.add(new DartUriResolver(sdk));
    }

    if (options.packageRootPath != null) {
      final ContextBuilderOptions builderOptions = new ContextBuilderOptions();
      builderOptions.defaultPackagesDirectoryPath = options.packageRootPath;
      final ContextBuilder builder = new ContextBuilder(resourceProvider, null, null,
          options: builderOptions);
      final PackageMapUriResolver packageUriResolver = new PackageMapUriResolver(resourceProvider,
          builder.convertPackagesToMap(builder.createPackageMap('')));

      resolvers.add(packageUriResolver);
    }

    resolvers.add(new file_system.ResourceUriResolver(resourceProvider));
    return resolvers;
  }

  bool _isFiltered(AnalysisError error) {
    final ErrorProcessor processor = ErrorProcessor.getProcessor(context.analysisOptions, error);
    // Filtered errors are processed to a severity of null.
    return processor != null && processor.severity == null;
  }

  void _processAnalysisOptions() {
    final String optionsPath = options.analysisOptionsFile;
    if (optionsPath != null) {
      final file_system.File file =
           PhysicalResourceProvider.INSTANCE.getFile(optionsPath);
      final Map<Object, Object> optionMap =
          analysisOptionsProvider.getOptionsFromFile(file);
      if (optionMap != null)
        applyToAnalysisOptions(options, optionMap);
    }
  }

  void _processPlugins() {
    final List<Plugin> plugins = <Plugin>[];
    plugins.addAll(AnalysisEngine.instance.requiredPlugins);
    final ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(plugins);
    linter.registerLintRules();
  }
}

class AnalysisDriverException implements Exception {
  AnalysisDriverException([this.message]);

  final String message;

  @override
  String toString() => message == null ? 'Exception' : 'Exception: $message';
}

class AnalysisErrorDescription {
  AnalysisErrorDescription(this.error, this.line);

  static Directory cwd = fs.currentDirectory.absolute;

  final AnalysisError error;
  final LineInfo line;

  ErrorCode get errorCode => error.errorCode;

  String get errorType {
    final ErrorSeverity severity = errorCode.errorSeverity;
    if (severity == ErrorSeverity.INFO) {
      if (errorCode.type == ErrorType.HINT || errorCode.type == ErrorType.LINT)
        return errorCode.type.displayName;
    }
    return severity.displayName;
  }

  LineInfo_Location get location => line.getLocation(error.offset);

  String get path => _shorten(cwd.path, error.source.fullName);

  Source get source => error.source;

  String asString() => '[$errorType] ${error.message} ($path, '
      'line ${location.lineNumber}, col ${location.columnNumber})';

  static String _shorten(String root, String path) =>
      path.startsWith(root) ? path.substring(root.length + 1) : path;
}

class DriverOptions extends AnalysisOptionsImpl {
  DriverOptions() {
    // Set defaults.
    lint = true;
    generateSdkErrors = false;
    trackCacheDependencies = false;
  }

  /// The path to the dart SDK.
  String dartSdkPath;

  /// Map of packages to folder paths.
  Map<String, String> packageMap;

  /// The path to the package root.
  String packageRootPath;

  /// The path to analysis options.
  String analysisOptionsFile;

  /// Out sink for logging.
  IOSink outSink = stdout;

  /// Error sink for logging.
  IOSink errorSink = stderr;
}

class PackageInfo {
  PackageInfo(Map<String, String> packageMap) {
    final Map<String, Uri> packages = new HashMap<String, Uri>();
    for (String package in packageMap.keys) {
      final String path = packageMap[package];
      packages[package] = new Uri.directory(path);
      _map[package] = <file_system.Folder>[
        PhysicalResourceProvider.INSTANCE.getFolder(path)
      ];
    }
    _packages = new MapPackages(packages);
  }

  Packages _packages;

  Map<String, List<file_system.Folder>> asMap() => _map;
  final HashMap<String, List<file_system.Folder>> _map =
      new HashMap<String, List<file_system.Folder>>();

  Packages asPackages() => _packages;
}

class _StdLogger extends Logger {
  _StdLogger({this.outSink, this.errorSink});

  final IOSink outSink;
  final IOSink errorSink;

  @override
  void logError(String message, [Exception exception]) =>
      errorSink.writeln(message);

  @override
  void logInformation(String message, [Exception exception]) {
    // TODO(pq): remove once addressed in analyzer (http://dartbug.com/28285)
    if (message != 'No definition of type FutureOr')
      outSink.writeln(message);
  }
}

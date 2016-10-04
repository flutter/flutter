// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart' as file_system;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/plugin/options.dart';
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
import 'package:cli_util/cli_util.dart' as cli_util;
import 'package:linter/src/plugin/linter_plugin.dart'; // ignore: implementation_imports
import 'package:package_config/packages.dart' show Packages;
import 'package:package_config/src/packages_impl.dart' show MapPackages; // ignore: implementation_imports
import 'package:path/path.dart' as path;
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';

class AnalysisDriver {
  Set<Source> _analyzedSources = new HashSet<Source>();

  AnalysisOptionsProvider analysisOptionsProvider =
      new AnalysisOptionsProvider();

  file_system.ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

  AnalysisContext context;

  DriverOptions options;
  AnalysisDriver(this.options) {
    AnalysisEngine.instance.logger =
        new _StdLogger(outSink: options.outSink, errorSink: options.errorSink);
    _processPlugins();
  }

  String get sdkDir => options.dartSdkPath ?? cli_util.getSdkDir().path;

  List<AnalysisErrorDescription> analyze(Iterable<File> files) {
    List<AnalysisErrorInfo> infos = _analyze(files);
    List<AnalysisErrorDescription> errors = <AnalysisErrorDescription>[];
    for (AnalysisErrorInfo info in infos) {
      for (AnalysisError error in info.errors) {
        if (!_isFiltered(error)) {
          errors.add(new AnalysisErrorDescription(error, info.lineInfo));
        }
      }
    }
    return errors;
  }

  List<AnalysisErrorInfo> _analyze(Iterable<File> files) {
    context = AnalysisEngine.instance.createAnalysisContext();
    _processAnalysisOptions(context, options);
    PackageInfo packageInfo = new PackageInfo(options.packageMap);
    List<UriResolver> resolvers = _getResolvers(context, packageInfo.asMap());
    context.sourceFactory =
        new SourceFactory(resolvers, packageInfo.asPackages());

    List<Source> sources = <Source>[];
    ChangeSet changeSet = new ChangeSet();
    for (File file in files) {
      JavaFile sourceFile = new JavaFile(path.normalize(file.absolute.path));
      Source source = new FileBasedSource(sourceFile, sourceFile.toURI());
      Uri uri = context.sourceFactory.restoreUri(source);
      if (uri != null) {
        source = new FileBasedSource(sourceFile, uri);
      }
      sources.add(source);
      changeSet.addedSource(source);
    }
    context.applyChanges(changeSet);

    List<AnalysisErrorInfo> infos = <AnalysisErrorInfo>[];
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
    List<UriResolver> resolvers = <UriResolver>[];
    
    // Look for an embedder.
    EmbedderYamlLocator locator = new EmbedderYamlLocator(packageMap);
    if (locator.embedderYamls.isNotEmpty) {
      // Create and configure an embedded SDK.
      EmbedderSdk sdk = new EmbedderSdk(PhysicalResourceProvider.INSTANCE, locator.embedderYamls);
      // Fail fast if no URI mappings are found.
      assert(sdk.libraryMap.size() > 0);
      sdk.analysisOptions = context.analysisOptions;
      // TODO(pq): re-enable once we have a proper story for SDK summaries
      // in the presence of embedders (https://github.com/dart-lang/sdk/issues/26467).
      sdk.useSummary = false;

      resolvers.add(new DartUriResolver(sdk));
    } else {
      // Fall back to a standard SDK if no embedder is found.
      FolderBasedDartSdk sdk = new FolderBasedDartSdk(resourceProvider,
          PhysicalResourceProvider.INSTANCE.getFolder(sdkDir));
      sdk.analysisOptions = context.analysisOptions;

      resolvers.add(new DartUriResolver(sdk));
    }

    if (options.packageRootPath != null) {
      ContextBuilder builder = new ContextBuilder(resourceProvider, null, null);
      builder.defaultPackagesDirectoryPath = options.packageRootPath;
      PackageMapUriResolver packageUriResolver = new PackageMapUriResolver(resourceProvider,
          builder.convertPackagesToMap(builder.createPackageMap('')));

      resolvers.add(packageUriResolver);
    }

    resolvers.add(new file_system.ResourceUriResolver(resourceProvider));
    return resolvers;
  }

  bool _isFiltered(AnalysisError error) {
    ErrorProcessor processor = ErrorProcessor.getProcessor(context, error);
    // Filtered errors are processed to a severity of `null`.
    return processor != null && processor.severity == null;
  }

  void _processAnalysisOptions(
      AnalysisContext context, AnalysisOptions analysisOptions) {
    List<OptionsProcessor> optionsProcessors =
        AnalysisEngine.instance.optionsPlugin.optionsProcessors;
    try {
      String optionsPath = options.analysisOptionsFile;
      if (optionsPath != null) {
        file_system.File file =
            PhysicalResourceProvider.INSTANCE.getFile(optionsPath);
        Map<Object, Object> optionMap =
            analysisOptionsProvider.getOptionsFromFile(file);
        optionsProcessors.forEach(
            (OptionsProcessor p) => p.optionsProcessed(context, optionMap));
        if (optionMap != null) {
          configureContextOptions(context, optionMap);
        }
      }
    } on Exception catch (e) {
      optionsProcessors.forEach((OptionsProcessor p) => p.onError(e));
    }
  }

  void _processPlugins() {
    List<Plugin> plugins = <Plugin>[];
    plugins.addAll(AnalysisEngine.instance.requiredPlugins);
    plugins.add(AnalysisEngine.instance.commandLinePlugin);
    plugins.add(AnalysisEngine.instance.optionsPlugin);
    plugins.add(linterPlugin);
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(plugins);
  }
}

class AnalysisDriverException implements Exception {
  final String message;
  AnalysisDriverException([this.message]);

  @override
  String toString() => message == null ? 'Exception' : 'Exception: $message';
}

class AnalysisErrorDescription {
  static Directory cwd = Directory.current.absolute;

  final AnalysisError error;
  final LineInfo line;
  AnalysisErrorDescription(this.error, this.line);

  ErrorCode get errorCode => error.errorCode;

  String get errorType {
    ErrorSeverity severity = errorCode.errorSeverity;
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
    cacheSize = 512;
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

  /// Analysis options map.
  Map<Object, Object> analysisOptions;

  /// Out sink for logging.
  IOSink outSink = stdout;

  /// Error sink for logging.
  IOSink errorSink = stderr;
}

class PackageInfo {
  PackageInfo(Map<String, String> packageMap) {
    Map<String, Uri> packages = new HashMap<String, Uri>();
    for (String package in packageMap.keys) {
      String path = packageMap[package];
      packages[package] = new Uri.directory(path);
      _map[package] = <file_system.Folder>[
        PhysicalResourceProvider.INSTANCE.getFolder(path)
      ];
    }
    _packages = new MapPackages(packages);
  }

  Packages _packages;
  HashMap<String, List<file_system.Folder>> _map =
      new HashMap<String, List<file_system.Folder>>();

  Map<String, List<file_system.Folder>> asMap() => _map;

  Packages asPackages() => _packages;
}

class _StdLogger extends Logger {
  final IOSink outSink;
  final IOSink errorSink;
  _StdLogger({this.outSink, this.errorSink});

  @override
  void logError(String message, [Exception exception]) =>
      errorSink.writeln(message);
  @override
  void logInformation(String message, [Exception exception]) =>
      outSink.writeln(message);
}

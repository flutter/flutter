// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:io';

import 'package:analyzer/file_system/file_system.dart' as file_system;
import 'package:analyzer/file_system/file_system.dart' show Folder;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/embedder.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:cli_util/cli_util.dart' as cli_util;
import 'package:linter/src/plugin/linter_plugin.dart';
import 'package:package_config/packages.dart' show Packages;
import 'package:package_config/packages_file.dart' as pkgfile show parse;
import 'package:package_config/src/packages_impl.dart' show MapPackages;
import 'package:path/path.dart' as path;
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';

class AnalysisDriver {
  Set<Source> _analyzedSources = new HashSet<Source>();

  AnalysisOptionsProvider analysisOptionsProvider =
      new AnalysisOptionsProvider();

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
    Packages packages = _getPackageConfig();
    context.sourceFactory =
        new SourceFactory(_getResolvers(context, packages), packages);

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

  Packages _getPackageConfig() {
    if (options.packageConfigPath != null) {
      String packageConfigPath = options.packageConfigPath;
      Uri fileUri = new Uri.file(packageConfigPath);
      try {
        File configFile = new File.fromUri(fileUri).absolute;
        List<int> bytes = configFile.readAsBytesSync();
        Map<String, Uri> map = pkgfile.parse(bytes, configFile.uri);
        return new MapPackages(map);
      } catch (e) {
        throw new AnalysisDriverException('Unable to create package map.');
      }
    }
    return null;
  }

  Map<String, List<file_system.Folder>> _getPackageMap(Packages packages) {
    if (packages == null) return null;

    Map<String, List<file_system.Folder>> folderMap =
        new Map<String, List<file_system.Folder>>();
    packages.asMap().forEach((String packagePath, Uri uri) {
      folderMap[packagePath] = <file_system.Folder>[
        PhysicalResourceProvider.INSTANCE.getFolder(path.fromUri(uri))
      ];
    });
    return folderMap;
  }

  List<UriResolver> _getResolvers(
      InternalAnalysisContext context, Packages packages) {
    DartSdk sdk = new DirectoryBasedDartSdk(new JavaFile(sdkDir));
    List<UriResolver> resolvers = <UriResolver>[];
    Map<String, List<file_system.Folder>> packageMap = _getPackageMap(packages);

    EmbedderYamlLocator yamlLocator = context.embedderYamlLocator;
    yamlLocator.refresh(packageMap);

    EmbedderUriResolver embedderUriResolver =
        new EmbedderUriResolver(yamlLocator.embedderYamls);
    if (embedderUriResolver.length == 0) {
      resolvers.add(new DartUriResolver(sdk));
    } else {
      resolvers.add(embedderUriResolver);
    }

    if (options.packageRootPath != null) {
      JavaFile packageDirectory = new JavaFile(options.packageRootPath);
      resolvers.add(new PackageUriResolver(<JavaFile>[packageDirectory]));
    } else {
      PubPackageMapProvider pubPackageMapProvider =
          new PubPackageMapProvider(PhysicalResourceProvider.INSTANCE, sdk);
      PackageMapInfo packageMapInfo = pubPackageMapProvider.computePackageMap(
          PhysicalResourceProvider.INSTANCE.getResource('.'));
      Map<String, List<Folder>> packageMap = packageMapInfo.packageMap;
      if (packageMap != null) {
        resolvers.add(new PackageMapUriResolver(
            PhysicalResourceProvider.INSTANCE, packageMap));
      }
    }

    resolvers.add(new FileUriResolver());
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

  String get errorType => error.errorCode.type.displayName;

  LineInfo_Location get location => line.getLocation(error.offset);

  String get path => _shorten(cwd.path, error.source.fullName);

  Source get source => error.source;

  String asString() => '[$errorType] ${error.message} ($path, '
      'line ${location.lineNumber}, col ${location.columnNumber})';

  static String _shorten(String root, String path) =>
      path.startsWith(root) ? path.substring(root.length + 1) : path;
}

class DriverOptions extends AnalysisOptionsImpl {
  @override
  int cacheSize = 512;

  /// The path to the dart SDK.
  String dartSdkPath;

  /// The path to a `.packages` configuration file
  String packageConfigPath;

  /// The path to the package root.
  String packageRootPath;

  /// The path to analysis options.
  String analysisOptionsFile;

  @override
  bool generateSdkErrors = false;

  /// Analysis options map.
  Map<Object, Object> analysisOptions;

  @override
  bool lint = true;

  /// Out sink for logging.
  IOSink outSink = stdout;

  /// Error sink for logging.
  IOSink errorSink = stderr;
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

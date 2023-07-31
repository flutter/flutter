// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:boolean_selector/boolean_selector.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart';
import 'package:test_api/scaffolding.dart' // ignore: deprecated_member_use
    show
        Timeout;
import 'package:test_api/src/backend/platform_selector.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/runtime.dart'; // ignore: implementation_imports

import '../util/io.dart';
import 'configuration/args.dart' as args;
import 'configuration/custom_runtime.dart';
import 'configuration/load.dart';
import 'configuration/reporters.dart';
import 'configuration/runtime_settings.dart';
import 'configuration/utils.dart';
import 'configuration/values.dart';
import 'runtime_selection.dart';
import 'suite.dart';

/// The key used to look up [Configuration.current] in a zone.
final _currentKey = Object();

/// Encapsulates a file/directory path and filter options specific to this path.
class PathConfiguration {
  const PathConfiguration({
    required this.testPath,
    this.testPatterns,
    this.line,
    this.col,
  });

  /// The explicit path to a test suite.
  final String testPath;

  /// Name filters specific to [testPath].
  final List<Pattern>? testPatterns;

  /// Only run tests that originate from this line in the test suite.
  final int? line;

  /// Only run tests that originate from this column in the test suite.
  final int? col;
}

/// A class that encapsulates the command-line configuration of the test runner.
class Configuration {
  /// An empty configuration with only default values.
  ///
  /// Using this is slightly more efficient than manually constructing a new
  /// configuration with no arguments.
  static final empty = Configuration._unsafe();

  /// The usage string for the command-line arguments.
  static String get usage => args.usage;

  /// Whether `--help` was passed.
  bool get help => _help ?? false;
  final bool? _help;

  /// Custom HTML template file.
  final String? customHtmlTemplatePath;

  /// Whether `--version` was passed.
  bool get version => _version ?? false;
  final bool? _version;

  /// Whether to pause for debugging after loading each test suite.
  bool get pauseAfterLoad => _pauseAfterLoad ?? false;
  final bool? _pauseAfterLoad;

  /// Whether to run browsers in their respective debug modes
  bool get debug => pauseAfterLoad || (_debug ?? false) || coverage != null;
  final bool? _debug;

  /// The output folder for coverage gathering
  final String? coverage;

  /// The path to the file from which to load more configuration information.
  ///
  /// This is *not* resolved automatically.
  String get configurationPath => _configurationPath ?? 'dart_test.yaml';
  final String? _configurationPath;

  /// The name of the reporter to use to display results.
  String get reporter => _reporter ?? defaultReporter;
  final String? _reporter;

  /// The map of file reporters where the key is the name of the reporter and
  /// the value is the filepath to which its output should be written.
  final Map<String, String> fileReporters;

  /// Whether to disable retries of tests.
  bool get noRetry => _noRetry ?? false;
  final bool? _noRetry;

  /// The URL for the `pub serve` instance from which to load tests, or `null`
  /// if tests should be loaded from the filesystem.
  final Uri? pubServeUrl;

  /// Whether to use command-line color escapes.
  bool get color => _color ?? canUseSpecialChars;
  final bool? _color;

  /// How many tests to run concurrently.
  int get concurrency =>
      pauseAfterLoad ? 1 : (_concurrency ?? defaultConcurrency);
  final int? _concurrency;

  /// The index of the current shard, if sharding is in use, or `null` if it's
  /// not.
  ///
  /// Sharding is a technique that allows the Google internal test framework to
  /// easily split a test run across multiple workers without requiring the
  /// tests to be modified by the user. When sharding is in use, the runner gets
  /// a shard index (this field) and a total number of shards, and is expected
  /// to provide the following guarantees:
  ///
  /// * Running the same invocation of the runner, with the same shard index and
  ///   total shards, will run the same set of tests.
  /// * Across all shards, each test must be run exactly once.
  ///
  /// In addition, tests should be balanced across shards as much as possible.
  final int? shardIndex;

  /// The total number of shards, if sharding is in use, or `null` if it's not.
  ///
  /// See [shardIndex] for details.
  final int? totalShards;

  /// The list of packages to fold when producing [StackTrace]s.
  Set<String> get foldTraceExcept => _foldTraceExcept ?? {};
  final Set<String>? _foldTraceExcept;

  /// If non-empty, all packages not in this list will be folded when producing
  /// [StackTrace]s.
  Set<String> get foldTraceOnly => _foldTraceOnly ?? {};
  final Set<String>? _foldTraceOnly;

  /// The paths from which to load tests.
  List<PathConfiguration> get paths =>
      _paths ?? const [PathConfiguration(testPath: 'test')];
  final List<PathConfiguration>? _paths;

  /// Whether the load paths were passed explicitly or the default was used.
  bool get explicitPaths => _paths != null;

  /// The glob matching the basename of tests to run.
  ///
  /// This is used to find tests within a directory.
  Glob get filename => _filename ?? defaultFilename;
  final Glob? _filename;

  /// The set of presets to use.
  ///
  /// Any chosen presets for the parent configuration are added to the chosen
  /// preset sets for child configurations as well.
  ///
  /// Note that the order of this set matters.
  final Set<String> chosenPresets;

  /// The set of tags that have been declared in any way in this configuration.
  late final Set<String> knownTags = UnmodifiableSetView({
    ...suiteDefaults.knownTags,
    for (var configuration in presets.values) ...configuration.knownTags
  });

  /// Configuration presets.
  ///
  /// These are configurations that can be explicitly selected by the user via
  /// the command line. Preset configuration takes precedence over the base
  /// configuration.
  ///
  /// This is guaranteed not to have any keys that match [chosenPresets]; those
  /// are resolved when the configuration is constructed.
  final Map<String, Configuration> presets;

  /// All preset names that are known to be valid.
  ///
  /// This includes presets that have already been resolved.
  Set<String> get knownPresets => _knownPresets ??= UnmodifiableSetView({
        ...presets.keys,
        for (var configuration in presets.values) ...configuration.knownPresets
      });
  Set<String>? _knownPresets;

  /// Whether to use the original `data:` URI isolate spawning strategy for VM
  /// tests.
  ///
  /// This can make more sense than the default strategy in systems such as
  /// `bazel` where only a single test suite is ran at a time.
  bool get useDataIsolateStrategy => _useDataIsolateStrategy ?? false;
  final bool? _useDataIsolateStrategy;

  /// Built-in runtimes whose settings are overridden by the user.
  final Map<String, RuntimeSettings> overrideRuntimes;

  /// Runtimes defined by the user in terms of existing runtimes.
  final Map<String, CustomRuntime> defineRuntimes;

  /// The default suite-level configuration.
  final SuiteConfiguration suiteDefaults;

  /// The seed used to generate randomness for test case shuffling.
  ///
  /// If null or zero no shuffling will occur.
  /// The same seed will shuffle the tests in the same way every time.
  final int? testRandomizeOrderingSeed;

  /// Returns the current configuration, or a default configuration if no
  /// current configuration is set.
  ///
  /// The current configuration is set using [asCurrent].
  static Configuration get current =>
      Zone.current[_currentKey] as Configuration? ?? Configuration._unsafe();

  /// Parses the configuration from [args].
  ///
  /// Throws a [FormatException] if [args] are invalid.
  factory Configuration.parse(List<String> arguments) => args.parse(arguments);

  /// Loads configuration from [path].
  ///
  /// If [global] is `true`, this restricts the configuration to rules that are
  /// supported globally.
  ///
  /// Throws an [IOException] if [path] does not exist or cannot be read. Throws
  /// a [FormatException] if the file contents are invalid.
  factory Configuration.load(String path, {bool global = false}) {
    final content = File(path).readAsStringSync();
    final sourceUrl = p.toUri(path);
    return parse(content, global: global, sourceUrl: sourceUrl);
  }

  /// Parses configuration from YAML formatted [content].
  ///
  /// If [global] is `true`, this restricts the configuration to rules that are
  /// supported globally.
  ///
  /// If [sourceUrl] is provided it will be set as the source url for the yaml
  /// document.
  ///
  /// Throws a [FormatException] if the content is invalid.
  factory Configuration.loadFromString(String content,
          {bool global = false, Uri? sourceUrl}) =>
      parse(content, global: global, sourceUrl: sourceUrl);

  factory Configuration(
      {required bool? help,
      required String? customHtmlTemplatePath,
      required bool? version,
      required bool? pauseAfterLoad,
      required bool? debug,
      required bool? color,
      required String? configurationPath,
      required String? reporter,
      required Map<String, String>? fileReporters,
      required String? coverage,
      required int? pubServePort,
      required int? concurrency,
      required int? shardIndex,
      required int? totalShards,
      required Iterable<PathConfiguration>? paths,
      required Iterable<String>? foldTraceExcept,
      required Iterable<String>? foldTraceOnly,
      required Glob? filename,
      required Iterable<String>? chosenPresets,
      required Map<String, Configuration>? presets,
      required Map<String, RuntimeSettings>? overrideRuntimes,
      required Map<String, CustomRuntime>? defineRuntimes,
      required bool? noRetry,
      required bool? useDataIsolateStrategy,
      required int? testRandomizeOrderingSeed,

      // Suite-level configuration
      required bool? allowDuplicateTestNames,
      required bool? allowTestRandomization,
      required bool? jsTrace,
      required bool? runSkipped,
      required Iterable<String>? dart2jsArgs,
      required String? precompiledPath,
      required Iterable<Pattern>? patterns,
      required Iterable<RuntimeSelection>? runtimes,
      required BooleanSelector? includeTags,
      required BooleanSelector? excludeTags,
      required Map<BooleanSelector, SuiteConfiguration>? tags,
      required Map<PlatformSelector, SuiteConfiguration>? onPlatform,
      required bool? ignoreTimeouts,

      // Test-level configuration
      required Timeout? timeout,
      required bool? verboseTrace,
      required bool? chainStackTraces,
      required bool? skip,
      required int? retry,
      required String? skipReason,
      required PlatformSelector? testOn,
      required Iterable<String>? addTags}) {
    var chosenPresetSet = chosenPresets?.toSet();
    var configuration = Configuration._(
        help: help,
        customHtmlTemplatePath: customHtmlTemplatePath,
        version: version,
        pauseAfterLoad: pauseAfterLoad,
        debug: debug,
        color: color,
        configurationPath: configurationPath,
        reporter: reporter,
        fileReporters: fileReporters,
        coverage: coverage,
        pubServePort: pubServePort,
        concurrency: concurrency,
        shardIndex: shardIndex,
        totalShards: totalShards,
        paths: paths,
        foldTraceExcept: foldTraceExcept,
        foldTraceOnly: foldTraceOnly,
        filename: filename,
        chosenPresets: chosenPresetSet,
        presets: _withChosenPresets(presets, chosenPresetSet),
        overrideRuntimes: overrideRuntimes,
        defineRuntimes: defineRuntimes,
        noRetry: noRetry,
        useDataIsolateStrategy: useDataIsolateStrategy,
        testRandomizeOrderingSeed: testRandomizeOrderingSeed,
        suiteDefaults: SuiteConfiguration(
            allowDuplicateTestNames: allowDuplicateTestNames,
            allowTestRandomization: allowTestRandomization,
            jsTrace: jsTrace,
            runSkipped: runSkipped,
            dart2jsArgs: dart2jsArgs,
            precompiledPath: precompiledPath,
            patterns: patterns,
            runtimes: runtimes,
            includeTags: includeTags,
            excludeTags: excludeTags,
            tags: tags,
            onPlatform: onPlatform,
            line: null, // Only configurable from the command line
            col: null, // Only configurable from the command line
            ignoreTimeouts: ignoreTimeouts,

            // Test-level configuration
            timeout: timeout,
            verboseTrace: verboseTrace,
            chainStackTraces: chainStackTraces,
            skip: skip,
            retry: retry,
            skipReason: skipReason,
            testOn: testOn,
            addTags: addTags));
    return configuration._resolvePresets();
  }

  /// A constructor that doesn't require all of its options to be passed.
  ///
  /// This should only be used in situations where you really only want to
  /// configure a specific restricted set of options.
  factory Configuration._unsafe(
          {bool? help,
          String? customHtmlTemplatePath,
          bool? version,
          bool? pauseAfterLoad,
          bool? debug,
          bool? color,
          String? configurationPath,
          String? reporter,
          Map<String, String>? fileReporters,
          String? coverage,
          int? pubServePort,
          int? concurrency,
          int? shardIndex,
          int? totalShards,
          Iterable<PathConfiguration>? paths,
          Iterable<String>? foldTraceExcept,
          Iterable<String>? foldTraceOnly,
          Glob? filename,
          Iterable<String>? chosenPresets,
          Map<String, Configuration>? presets,
          Map<String, RuntimeSettings>? overrideRuntimes,
          Map<String, CustomRuntime>? defineRuntimes,
          bool? noRetry,
          bool? useDataIsolateStrategy,
          int? testRandomizeOrderingSeed,

          // Suite-level configuration
          bool? allowDuplicateTestNames,
          bool? allowTestRandomization,
          bool? jsTrace,
          bool? runSkipped,
          Iterable<String>? dart2jsArgs,
          String? precompiledPath,
          Iterable<Pattern>? patterns,
          Iterable<RuntimeSelection>? runtimes,
          BooleanSelector? includeTags,
          BooleanSelector? excludeTags,
          Map<BooleanSelector, SuiteConfiguration>? tags,
          Map<PlatformSelector, SuiteConfiguration>? onPlatform,
          bool? ignoreTimeouts,

          // Test-level configuration
          Timeout? timeout,
          bool? verboseTrace,
          bool? chainStackTraces,
          bool? skip,
          int? retry,
          String? skipReason,
          PlatformSelector? testOn,
          Iterable<String>? addTags}) =>
      Configuration(
          help: help,
          customHtmlTemplatePath: customHtmlTemplatePath,
          version: version,
          pauseAfterLoad: pauseAfterLoad,
          debug: debug,
          color: color,
          configurationPath: configurationPath,
          reporter: reporter,
          fileReporters: fileReporters,
          coverage: coverage,
          pubServePort: pubServePort,
          concurrency: concurrency,
          shardIndex: shardIndex,
          totalShards: totalShards,
          paths: paths,
          foldTraceExcept: foldTraceExcept,
          foldTraceOnly: foldTraceOnly,
          filename: filename,
          chosenPresets: chosenPresets,
          presets: presets,
          overrideRuntimes: overrideRuntimes,
          defineRuntimes: defineRuntimes,
          noRetry: noRetry,
          useDataIsolateStrategy: useDataIsolateStrategy,
          testRandomizeOrderingSeed: testRandomizeOrderingSeed,
          allowDuplicateTestNames: allowDuplicateTestNames,
          allowTestRandomization: allowTestRandomization,
          jsTrace: jsTrace,
          runSkipped: runSkipped,
          dart2jsArgs: dart2jsArgs,
          precompiledPath: precompiledPath,
          patterns: patterns,
          runtimes: runtimes,
          includeTags: includeTags,
          excludeTags: excludeTags,
          tags: tags,
          onPlatform: onPlatform,
          ignoreTimeouts: ignoreTimeouts,
          timeout: timeout,
          verboseTrace: verboseTrace,
          chainStackTraces: chainStackTraces,
          skip: skip,
          retry: retry,
          skipReason: skipReason,
          testOn: testOn,
          addTags: addTags);

  /// Suite level configuration allowed in the global test config file.
  ///
  /// This is per-user configuration and should be limited as such, it should
  /// not contain options that would change the pass/fail result of any given
  /// test, or change which tests would run.
  factory Configuration.globalTest({
    required bool? verboseTrace,
    required bool? jsTrace,
    required Timeout? timeout,
    required Map<String, Configuration>? presets,
    required bool? chainStackTraces,
    required Iterable<String>? foldTraceExcept,
    required Iterable<String>? foldTraceOnly,
  }) =>
      Configuration(
        foldTraceExcept: foldTraceExcept,
        foldTraceOnly: foldTraceOnly,
        jsTrace: jsTrace,
        timeout: timeout,
        verboseTrace: verboseTrace,
        chainStackTraces: chainStackTraces,
        help: null,
        customHtmlTemplatePath: null,
        version: null,
        pauseAfterLoad: null,
        debug: null,
        color: null,
        configurationPath: null,
        reporter: null,
        fileReporters: null,
        coverage: null,
        pubServePort: null,
        concurrency: null,
        shardIndex: null,
        totalShards: null,
        paths: null,
        filename: null,
        chosenPresets: null,
        presets: presets,
        overrideRuntimes: null,
        defineRuntimes: null,
        noRetry: null,
        useDataIsolateStrategy: null,
        testRandomizeOrderingSeed: null,
        ignoreTimeouts: null,
        allowDuplicateTestNames: null,
        allowTestRandomization: null,
        runSkipped: null,
        dart2jsArgs: null,
        precompiledPath: null,
        patterns: null,
        runtimes: null,
        includeTags: null,
        excludeTags: null,
        tags: null,
        onPlatform: null,
        skip: null,
        retry: null,
        skipReason: null,
        testOn: null,
        addTags: null,
      );

  /// Suite level configuration that is not allowed in the global test
  /// config file.
  ///
  /// This configuration may alter the pass/fail result of a test run, and thus
  /// should only be configured per package and not at the global level (global
  /// config is user specific).
  factory Configuration.localTest({
    required bool? skip,
    required int? retry,
    required String? skipReason,
    required PlatformSelector? testOn,
    required Iterable<String>? addTags,
    required bool? allowDuplicateTestNames,
    required bool? allowTestRandomization,
  }) =>
      Configuration(
        allowDuplicateTestNames: allowDuplicateTestNames,
        allowTestRandomization: allowTestRandomization,
        skip: skip,
        retry: retry,
        skipReason: skipReason,
        testOn: testOn,
        addTags: addTags,
        help: null,
        customHtmlTemplatePath: null,
        version: null,
        pauseAfterLoad: null,
        debug: null,
        color: null,
        configurationPath: null,
        reporter: null,
        fileReporters: null,
        coverage: null,
        pubServePort: null,
        concurrency: null,
        shardIndex: null,
        totalShards: null,
        paths: null,
        foldTraceExcept: null,
        foldTraceOnly: null,
        filename: null,
        chosenPresets: null,
        presets: null,
        overrideRuntimes: null,
        defineRuntimes: null,
        noRetry: null,
        useDataIsolateStrategy: null,
        testRandomizeOrderingSeed: null,
        jsTrace: null,
        runSkipped: null,
        dart2jsArgs: null,
        precompiledPath: null,
        patterns: null,
        runtimes: null,
        includeTags: null,
        excludeTags: null,
        tags: null,
        onPlatform: null,
        ignoreTimeouts: null,
        timeout: null,
        verboseTrace: null,
        chainStackTraces: null,
      );

  /// Runner configuration that is allowed in the global test config file.
  ///
  /// This is per-user configuration and should be limited as such, it should
  /// not contain options that would change the pass/fail result of any given
  /// test, or change which tests would run.
  ///
  /// Note that [customHtmlTemplatePath] violates this rule, and really should
  /// not be configurable globally.
  factory Configuration.globalRunner(
          {required bool? pauseAfterLoad,
          required String? customHtmlTemplatePath,
          required bool? runSkipped,
          required String? reporter,
          required Map<String, String>? fileReporters,
          required int? concurrency,
          required Iterable<RuntimeSelection>? runtimes,
          required Iterable<String>? chosenPresets,
          required Map<String, RuntimeSettings>? overrideRuntimes}) =>
      Configuration(
        customHtmlTemplatePath: customHtmlTemplatePath,
        pauseAfterLoad: pauseAfterLoad,
        runSkipped: runSkipped,
        reporter: reporter,
        fileReporters: fileReporters,
        concurrency: concurrency,
        runtimes: runtimes,
        chosenPresets: chosenPresets,
        overrideRuntimes: overrideRuntimes,
        help: null,
        version: null,
        debug: null,
        color: null,
        configurationPath: null,
        coverage: null,
        pubServePort: null,
        shardIndex: null,
        totalShards: null,
        paths: null,
        foldTraceExcept: null,
        foldTraceOnly: null,
        filename: null,
        presets: null,
        defineRuntimes: null,
        noRetry: null,
        useDataIsolateStrategy: null,
        testRandomizeOrderingSeed: null,
        allowDuplicateTestNames: null,
        allowTestRandomization: null,
        jsTrace: null,
        dart2jsArgs: null,
        precompiledPath: null,
        patterns: null,
        includeTags: null,
        excludeTags: null,
        tags: null,
        onPlatform: null,
        ignoreTimeouts: null,
        timeout: null,
        verboseTrace: null,
        chainStackTraces: null,
        skip: null,
        retry: null,
        skipReason: null,
        testOn: null,
        addTags: null,
      );

  /// Runner configuration that is not allowed in the global test config file.
  ///
  /// This configuration may alter the pass/fail result of a test run, and thus
  /// should only be configured per package and not at the global level (global
  /// config is user specific).
  factory Configuration.localRunner(
          {required int? pubServePort,
          required Iterable<Pattern>? patterns,
          required Iterable<PathConfiguration>? paths,
          required Glob? filename,
          required BooleanSelector? includeTags,
          required BooleanSelector? excludeTags,
          required Map<String, CustomRuntime>? defineRuntimes}) =>
      Configuration(
          pubServePort: pubServePort,
          patterns: patterns,
          paths: paths,
          filename: filename,
          includeTags: includeTags,
          excludeTags: excludeTags,
          defineRuntimes: defineRuntimes,
          help: null,
          customHtmlTemplatePath: null,
          version: null,
          pauseAfterLoad: null,
          debug: null,
          color: null,
          configurationPath: null,
          reporter: null,
          fileReporters: null,
          coverage: null,
          concurrency: null,
          shardIndex: null,
          totalShards: null,
          foldTraceExcept: null,
          foldTraceOnly: null,
          chosenPresets: null,
          presets: null,
          overrideRuntimes: null,
          noRetry: null,
          useDataIsolateStrategy: null,
          testRandomizeOrderingSeed: null,
          allowDuplicateTestNames: null,
          allowTestRandomization: null,
          jsTrace: null,
          runSkipped: null,
          dart2jsArgs: null,
          precompiledPath: null,
          runtimes: null,
          tags: null,
          onPlatform: null,
          ignoreTimeouts: null,
          timeout: null,
          verboseTrace: null,
          chainStackTraces: null,
          skip: null,
          retry: null,
          skipReason: null,
          testOn: null,
          addTags: null);

  /// A specialized constructor for configuring only `onPlatform`.
  factory Configuration.onPlatform(
          Map<PlatformSelector, SuiteConfiguration> onPlatform) =>
      Configuration._unsafe(onPlatform: onPlatform);

  factory Configuration.tags(Map<BooleanSelector, SuiteConfiguration> tags) =>
      Configuration._unsafe(tags: tags);

  static Map<String, Configuration>? _withChosenPresets(
      Map<String, Configuration>? map, Set<String>? chosenPresets) {
    if (map == null || chosenPresets == null) return map;
    return map.map((key, config) => MapEntry(
        key,
        config.change(
            chosenPresets: config.chosenPresets.union(chosenPresets))));
  }

  /// Creates new Configuration.
  ///
  /// Unlike [Configuration.new], this assumes [presets] is already resolved.
  Configuration._(
      {required bool? help,
      required this.customHtmlTemplatePath,
      required bool? version,
      required bool? pauseAfterLoad,
      required bool? debug,
      required bool? color,
      required String? configurationPath,
      required String? reporter,
      required Map<String, String>? fileReporters,
      required this.coverage,
      required int? pubServePort,
      required int? concurrency,
      required this.shardIndex,
      required this.totalShards,
      required Iterable<PathConfiguration>? paths,
      required Iterable<String>? foldTraceExcept,
      required Iterable<String>? foldTraceOnly,
      required Glob? filename,
      required Iterable<String>? chosenPresets,
      required Map<String, Configuration>? presets,
      required Map<String, RuntimeSettings>? overrideRuntimes,
      required Map<String, CustomRuntime>? defineRuntimes,
      required bool? noRetry,
      required bool? useDataIsolateStrategy,
      required this.testRandomizeOrderingSeed,
      required SuiteConfiguration? suiteDefaults})
      : _help = help,
        _version = version,
        _pauseAfterLoad = pauseAfterLoad,
        _debug = debug,
        _color = color,
        _configurationPath = configurationPath,
        _reporter = reporter,
        fileReporters = fileReporters ?? {},
        pubServeUrl = pubServePort == null
            ? null
            : Uri.parse('http://localhost:$pubServePort'),
        _concurrency = concurrency,
        _paths = _list(paths),
        _foldTraceExcept = _set(foldTraceExcept),
        _foldTraceOnly = _set(foldTraceOnly),
        _filename = filename,
        chosenPresets = UnmodifiableSetView(chosenPresets?.toSet() ?? {}),
        presets = _map(presets),
        overrideRuntimes = _map(overrideRuntimes),
        defineRuntimes = _map(defineRuntimes),
        _noRetry = noRetry,
        _useDataIsolateStrategy = useDataIsolateStrategy,
        suiteDefaults = (() {
          var config = suiteDefaults ?? SuiteConfiguration.empty;
          if (pauseAfterLoad == true) {
            return config.change(ignoreTimeouts: true);
          }
          return config;
        }()) {
    if (_filename != null && _filename!.context.style != p.style) {
      throw ArgumentError(
          "filename's context must match the current operating system, was "
          '${_filename!.context.style}.');
    }

    if ((shardIndex == null) != (totalShards == null)) {
      throw ArgumentError(
          'shardIndex and totalShards may only be passed together.');
    } else if (shardIndex != null) {
      RangeError.checkValueInInterval(
          shardIndex!, 0, totalShards! - 1, 'shardIndex');
    }
  }

  /// Creates a new [Configuration] that takes its configuration from
  /// [SuiteConfiguration].
  factory Configuration.fromSuiteConfiguration(
          SuiteConfiguration suiteConfig) =>
      Configuration._(
        suiteDefaults: suiteConfig,
        help: null,
        customHtmlTemplatePath: null,
        version: null,
        pauseAfterLoad: null,
        debug: null,
        color: null,
        configurationPath: null,
        reporter: null,
        fileReporters: null,
        coverage: null,
        pubServePort: null,
        concurrency: null,
        shardIndex: null,
        totalShards: null,
        paths: null,
        foldTraceExcept: null,
        foldTraceOnly: null,
        filename: null,
        chosenPresets: null,
        presets: null,
        overrideRuntimes: null,
        defineRuntimes: null,
        noRetry: null,
        useDataIsolateStrategy: null,
        testRandomizeOrderingSeed: null,
      );

  /// Returns an unmodifiable copy of [input].
  ///
  /// If [input] is `null` or empty, this returns `null`.
  static List<T>? _list<T>(Iterable<T>? input) {
    if (input == null) return null;
    var list = List<T>.unmodifiable(input);
    if (list.isEmpty) return null;
    return list;
  }

  /// Returns a set from [input].
  ///
  /// If [input] is `null` or empty, this returns `null`.
  static Set<T>? _set<T>(Iterable<T>? input) {
    if (input == null) return null;
    var set = Set<T>.from(input);
    if (set.isEmpty) return null;
    return set;
  }

  /// Returns an unmodifiable copy of [input] or an empty unmodifiable map.
  static Map<K, V> _map<K, V>(Map<K, V>? input) {
    input ??= {};
    return Map.unmodifiable(input);
  }

  /// Runs [body] with this as [Configuration.current].
  ///
  /// This is zone-scoped, so this will be the current configuration in any
  /// asynchronous callbacks transitively created by [body].
  T asCurrent<T>(T Function() body) =>
      runZoned(body, zoneValues: {_currentKey: this});

  /// Throws a [FormatException] if this refers to any undefined runtimes.
  void validateRuntimes(List<Runtime> allRuntimes) {
    // We don't need to verify [customRuntimes] here because those runtimes
    // already need to be verified and resolved to create [allRuntimes].

    for (var settings in overrideRuntimes.values) {
      if (!allRuntimes
          .any((runtime) => runtime.identifier == settings.identifier)) {
        throw SourceSpanFormatException(
            'Unknown platform "${settings.identifier}".',
            settings.identifierSpan);
      }
    }

    suiteDefaults.validateRuntimes(allRuntimes);
    for (var config in presets.values) {
      config.validateRuntimes(allRuntimes);
    }
  }

  /// Merges this with [other].
  ///
  /// For most fields, if both configurations have values set, [other]'s value
  /// takes precedence. However, certain fields are merged together instead.
  /// This is indicated in those fields' documentation.
  Configuration merge(Configuration other) {
    if (this == Configuration.empty) return other;
    if (other == Configuration.empty) return this;

    var foldTraceOnly = other._foldTraceOnly ?? _foldTraceOnly;
    var foldTraceExcept = other._foldTraceExcept ?? _foldTraceExcept;
    if (_foldTraceOnly != null) {
      if (other._foldTraceExcept != null) {
        foldTraceOnly = _foldTraceOnly!.difference(other._foldTraceExcept!);
      } else if (other._foldTraceOnly != null) {
        foldTraceOnly = other._foldTraceOnly!.intersection(_foldTraceOnly!);
      }
    } else if (_foldTraceExcept != null) {
      if (other._foldTraceOnly != null) {
        foldTraceOnly = other._foldTraceOnly!.difference(_foldTraceExcept!);
      } else if (other._foldTraceExcept != null) {
        foldTraceExcept = other._foldTraceExcept!.union(_foldTraceExcept!);
      }
    }

    var result = Configuration._(
        help: other._help ?? _help,
        customHtmlTemplatePath:
            other.customHtmlTemplatePath ?? customHtmlTemplatePath,
        version: other._version ?? _version,
        pauseAfterLoad: other._pauseAfterLoad ?? _pauseAfterLoad,
        debug: other._debug ?? _debug,
        color: other._color ?? _color,
        configurationPath: other._configurationPath ?? _configurationPath,
        reporter: other._reporter ?? _reporter,
        fileReporters: mergeMaps(fileReporters, other.fileReporters),
        coverage: other.coverage ?? coverage,
        pubServePort: (other.pubServeUrl ?? pubServeUrl)?.port,
        concurrency: other._concurrency ?? _concurrency,
        shardIndex: other.shardIndex ?? shardIndex,
        totalShards: other.totalShards ?? totalShards,
        paths: other._paths ?? _paths,
        foldTraceExcept: foldTraceExcept,
        foldTraceOnly: foldTraceOnly,
        filename: other._filename ?? _filename,
        chosenPresets: chosenPresets.union(other.chosenPresets),
        presets: _mergeConfigMaps(presets, other.presets),
        overrideRuntimes: mergeUnmodifiableMaps(
            overrideRuntimes, other.overrideRuntimes,
            value: (settings1, settings2) => RuntimeSettings(
                settings1.identifier,
                settings1.identifierSpan,
                [...settings1.settings, ...settings2.settings])),
        defineRuntimes:
            mergeUnmodifiableMaps(defineRuntimes, other.defineRuntimes),
        noRetry: other._noRetry ?? _noRetry,
        useDataIsolateStrategy:
            other._useDataIsolateStrategy ?? _useDataIsolateStrategy,
        testRandomizeOrderingSeed:
            other.testRandomizeOrderingSeed ?? testRandomizeOrderingSeed,
        suiteDefaults: suiteDefaults.merge(other.suiteDefaults));
    result = result._resolvePresets();

    // Make sure the merged config preserves any presets that were chosen and
    // discarded.
    result._knownPresets = knownPresets.union(other.knownPresets);
    return result;
  }

  /// Returns a copy of this configuration with the given fields updated.
  ///
  /// Note that unlike [merge], this has no merging behavior—the old value is
  /// always replaced by the new one.
  Configuration change(
      {bool? help,
      String? customHtmlTemplatePath,
      bool? version,
      bool? pauseAfterLoad,
      bool? debug,
      bool? color,
      String? configurationPath,
      String? reporter,
      Map<String, String>? fileReporters,
      String? coverage,
      int? pubServePort,
      int? concurrency,
      int? shardIndex,
      int? totalShards,
      Iterable<PathConfiguration>? paths,
      Iterable<String>? exceptPackages,
      Iterable<String>? onlyPackages,
      Glob? filename,
      Iterable<String>? chosenPresets,
      Map<String, Configuration>? presets,
      Map<String, RuntimeSettings>? overrideRuntimes,
      Map<String, CustomRuntime>? defineRuntimes,
      bool? noRetry,
      bool? useDataIsolateStrategy,
      int? testRandomizeOrderingSeed,
      bool? ignoreTimeouts,

      // Suite-level configuration
      bool? allowDuplicateTestNames,
      bool? jsTrace,
      bool? runSkipped,
      Iterable<String>? dart2jsArgs,
      String? precompiledPath,
      Iterable<Pattern>? patterns,
      Iterable<RuntimeSelection>? runtimes,
      BooleanSelector? includeTags,
      BooleanSelector? excludeTags,
      Map<BooleanSelector, SuiteConfiguration>? tags,
      Map<PlatformSelector, SuiteConfiguration>? onPlatform,

      // Test-level configuration
      Timeout? timeout,
      bool? verboseTrace,
      bool? chainStackTraces,
      bool? skip,
      String? skipReason,
      PlatformSelector? testOn,
      Iterable<String>? addTags}) {
    var config = Configuration._(
        help: help ?? _help,
        customHtmlTemplatePath:
            customHtmlTemplatePath ?? this.customHtmlTemplatePath,
        version: version ?? _version,
        pauseAfterLoad: pauseAfterLoad ?? _pauseAfterLoad,
        debug: debug ?? _debug,
        color: color ?? _color,
        configurationPath: configurationPath ?? _configurationPath,
        reporter: reporter ?? _reporter,
        fileReporters: fileReporters ?? this.fileReporters,
        coverage: coverage ?? this.coverage,
        pubServePort: pubServePort ?? pubServeUrl?.port,
        concurrency: concurrency ?? _concurrency,
        shardIndex: shardIndex ?? this.shardIndex,
        totalShards: totalShards ?? this.totalShards,
        paths: paths ?? _paths,
        foldTraceExcept: exceptPackages ?? _foldTraceExcept,
        foldTraceOnly: onlyPackages ?? _foldTraceOnly,
        filename: filename ?? _filename,
        chosenPresets: chosenPresets ?? this.chosenPresets,
        presets: presets ?? this.presets,
        overrideRuntimes: overrideRuntimes ?? this.overrideRuntimes,
        defineRuntimes: defineRuntimes ?? this.defineRuntimes,
        noRetry: noRetry ?? _noRetry,
        useDataIsolateStrategy:
            useDataIsolateStrategy ?? _useDataIsolateStrategy,
        testRandomizeOrderingSeed:
            testRandomizeOrderingSeed ?? this.testRandomizeOrderingSeed,
        suiteDefaults: suiteDefaults.change(
          allowDuplicateTestNames: allowDuplicateTestNames,
          jsTrace: jsTrace,
          runSkipped: runSkipped,
          dart2jsArgs: dart2jsArgs,
          precompiledPath: precompiledPath,
          patterns: patterns,
          runtimes: runtimes,
          includeTags: includeTags,
          excludeTags: excludeTags,
          tags: tags,
          onPlatform: onPlatform,
          timeout: timeout,
          verboseTrace: verboseTrace,
          chainStackTraces: chainStackTraces,
          skip: skip,
          skipReason: skipReason,
          testOn: testOn,
          addTags: addTags,
          ignoreTimeouts: ignoreTimeouts,
        ));
    return config._resolvePresets();
  }

  /// Merges two maps whose values are [Configuration]s.
  ///
  /// Any overlapping keys in the maps have their configurations merged in the
  /// returned map.
  Map<String, Configuration> _mergeConfigMaps(
          Map<String, Configuration> map1, Map<String, Configuration> map2) =>
      mergeMaps(map1, map2,
          value: (config1, config2) => config1.merge(config2));

  /// Returns a copy of this [Configuration] with all [chosenPresets] resolved
  /// against [presets].
  Configuration _resolvePresets() {
    if (chosenPresets.isEmpty || presets.isEmpty) return this;

    var newPresets = Map<String, Configuration>.from(presets);
    var merged = chosenPresets.fold(
        empty,
        (Configuration merged, preset) =>
            merged.merge(newPresets.remove(preset) ?? Configuration.empty));

    if (merged == empty) return this;
    var result = change(presets: newPresets).merge(merged);

    // Make sure the configuration knows about presets that were selected and
    // thus removed from [newPresets].
    result._knownPresets =
        UnmodifiableSetView({...result.knownPresets, ...presets.keys});

    return result;
  }
}

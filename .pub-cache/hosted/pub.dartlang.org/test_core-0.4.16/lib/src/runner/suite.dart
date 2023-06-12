// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:boolean_selector/boolean_selector.dart';
import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';
import 'package:test_api/scaffolding.dart' // ignore: deprecated_member_use
    show
        Timeout;
import 'package:test_api/src/backend/metadata.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/platform_selector.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/runtime.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/suite_platform.dart'; // ignore: implementation_imports

import 'runtime_selection.dart';

/// Suite-level configuration.
///
/// This tracks configuration that can differ from suite to suite.
class SuiteConfiguration {
  /// Empty configuration with only default values.
  ///
  /// Using this is slightly more efficient than manually constructing a new
  /// configuration with no arguments.
  static final empty = SuiteConfiguration._(
      allowDuplicateTestNames: null,
      allowTestRandomization: null,
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
      metadata: null,
      line: null,
      col: null,
      ignoreTimeouts: null);

  /// Whether or not duplicate test (or group) names are allowed within the same
  /// test suite.
  //
  // TODO: Change the default https://github.com/dart-lang/test/issues/1571
  bool get allowDuplicateTestNames => _allowDuplicateTestNames ?? true;
  final bool? _allowDuplicateTestNames;

  /// Whether test randomization should be allowed for this test.
  bool get allowTestRandomization => _allowTestRandomization ?? true;
  final bool? _allowTestRandomization;

  /// Whether JavaScript stack traces should be left as-is or converted to
  /// Dart-like traces.
  bool get jsTrace => _jsTrace ?? false;
  final bool? _jsTrace;

  /// Whether skipped tests should be run.
  bool get runSkipped => _runSkipped ?? false;
  final bool? _runSkipped;

  /// The path to a mirror of this package containing HTML that points to
  /// precompiled JS.
  ///
  /// This is used by the internal Google test runner so that test compilation
  /// can more effectively make use of Google's build tools.
  final String? precompiledPath;

  /// Additional arguments to pass to dart2js.
  ///
  /// Note that this if multiple suites run the same JavaScript on different
  /// runtimes, and they have different [dart2jsArgs], only one (undefined)
  /// suite's arguments will be used.
  final List<String> dart2jsArgs;

  /// The patterns to match against test names to decide which to run.
  ///
  /// All patterns must match in order for a test to be run.
  ///
  /// If empty, all tests should be run.
  final Set<Pattern> patterns;

  /// The set of runtimes on which to run tests.
  List<String> get runtimes => _runtimes == null
      ? const ['vm']
      : List.unmodifiable(_runtimes!.map((runtime) => runtime.name));
  final List<RuntimeSelection>? _runtimes;

  /// Only run tests whose tags match this selector.
  ///
  /// When [merge]d, this is intersected with the other configuration's included
  /// tags.
  final BooleanSelector includeTags;

  /// Do not run tests whose tags match this selector.
  ///
  /// When [merge]d, this is unioned with the other configuration's
  /// excluded tags.
  final BooleanSelector excludeTags;

  /// Configuration for particular tags.
  ///
  /// The keys are tag selectors, and the values are configurations for tests
  /// whose tags match those selectors.
  final Map<BooleanSelector, SuiteConfiguration> tags;

  /// Configuration for particular platforms.
  ///
  /// The keys are platform selectors, and the values are configurations for
  /// those platforms. These configuration should only contain test-level
  /// configuration fields, but that isn't enforced.
  final Map<PlatformSelector, SuiteConfiguration> onPlatform;

  /// The global test metadata derived from this configuration.
  Metadata get metadata {
    if (tags.isEmpty && onPlatform.isEmpty) return _metadata;
    return _metadata.change(
        forTag: tags.map((key, config) => MapEntry(key, config.metadata)),
        onPlatform:
            onPlatform.map((key, config) => MapEntry(key, config.metadata)));
  }

  final Metadata _metadata;

  /// The set of tags that have been declared in any way in this configuration.
  late final Set<String> knownTags = UnmodifiableSetView({
    ...includeTags.variables,
    ...excludeTags.variables,
    ..._metadata.tags,
    for (var selector in tags.keys) ...selector.variables,
    for (var configuration in tags.values) ...configuration.knownTags,
    for (var configuration in onPlatform.values) ...configuration.knownTags,
  });

  /// Only run tests that originate from this line in a test file.
  final int? line;

  /// Only run tests that original from this column in a test file.
  final int? col;

  /// Whether or not timeouts should be ignored.
  final bool? _ignoreTimeouts;
  bool get ignoreTimeouts => _ignoreTimeouts ?? false;

  factory SuiteConfiguration(
      {required bool? allowDuplicateTestNames,
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
      required int? line,
      required int? col,
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
    var config = SuiteConfiguration._(
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
        line: line,
        col: col,
        ignoreTimeouts: ignoreTimeouts,
        metadata: Metadata(
            timeout: timeout,
            verboseTrace: verboseTrace,
            chainStackTraces: chainStackTraces,
            skip: skip,
            retry: retry,
            skipReason: skipReason,
            testOn: testOn,
            tags: addTags));
    return config._resolveTags();
  }

  /// A constructor that doesn't require all of its options to be passed.
  ///
  /// This should only be used in situations where you really only want to
  /// configure a specific restricted set of options.
  factory SuiteConfiguration._unsafe(
          {bool? allowDuplicateTestNames,
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
          int? line,
          int? col,
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
      SuiteConfiguration(
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
          line: line,
          col: col,
          ignoreTimeouts: ignoreTimeouts,
          timeout: timeout,
          verboseTrace: verboseTrace,
          chainStackTraces: chainStackTraces,
          skip: skip,
          retry: retry,
          skipReason: skipReason,
          testOn: testOn,
          addTags: addTags);

  /// A specialized constructor for only configuring the runtimes.
  factory SuiteConfiguration.runtimes(Iterable<RuntimeSelection> runtimes) =>
      SuiteConfiguration._unsafe(runtimes: runtimes);

  /// A specialized constructor for only configuring runSkipped.
  factory SuiteConfiguration.runSkipped(bool runSkipped) =>
      SuiteConfiguration._unsafe(runSkipped: runSkipped);

  /// A specialized constructor for only configuring the timeout.
  factory SuiteConfiguration.timeout(Timeout timeout) =>
      SuiteConfiguration._unsafe(timeout: timeout);

  /// Creates new SuiteConfiguration.
  ///
  /// Unlike [SuiteConfiguration.new], this assumes [tags] is already
  /// resolved.
  SuiteConfiguration._({
    required bool? allowDuplicateTestNames,
    required bool? allowTestRandomization,
    required bool? jsTrace,
    required bool? runSkipped,
    required Iterable<String>? dart2jsArgs,
    required this.precompiledPath,
    required Iterable<Pattern>? patterns,
    required Iterable<RuntimeSelection>? runtimes,
    required BooleanSelector? includeTags,
    required BooleanSelector? excludeTags,
    required Map<BooleanSelector, SuiteConfiguration>? tags,
    required Map<PlatformSelector, SuiteConfiguration>? onPlatform,
    required Metadata? metadata,
    required this.line,
    required this.col,
    required bool? ignoreTimeouts,
  })  : _allowDuplicateTestNames = allowDuplicateTestNames,
        _allowTestRandomization = allowTestRandomization,
        _jsTrace = jsTrace,
        _runSkipped = runSkipped,
        dart2jsArgs = _list(dart2jsArgs) ?? const [],
        patterns = UnmodifiableSetView(patterns?.toSet() ?? {}),
        _runtimes = _list(runtimes),
        includeTags = includeTags ?? BooleanSelector.all,
        excludeTags = excludeTags ?? BooleanSelector.none,
        tags = _map(tags),
        onPlatform = _map(onPlatform),
        _ignoreTimeouts = ignoreTimeouts,
        _metadata = metadata ?? Metadata.empty;

  /// Creates a new [SuiteConfiguration] that takes its configuration from
  /// [metadata].
  factory SuiteConfiguration.fromMetadata(Metadata metadata) =>
      SuiteConfiguration._(
        tags: metadata.forTag.map((key, child) =>
            MapEntry(key, SuiteConfiguration.fromMetadata(child))),
        onPlatform: metadata.onPlatform.map((key, child) =>
            MapEntry(key, SuiteConfiguration.fromMetadata(child))),
        metadata: metadata.change(forTag: {}, onPlatform: {}),
        allowDuplicateTestNames: null,
        allowTestRandomization: null,
        jsTrace: null,
        runSkipped: null,
        dart2jsArgs: null,
        precompiledPath: null,
        patterns: null,
        runtimes: null,
        includeTags: null,
        excludeTags: null,
        line: null,
        col: null,
        ignoreTimeouts: null,
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

  /// Returns an unmodifiable copy of [input] or an empty unmodifiable map.
  static Map<K, V> _map<K, V>(Map<K, V>? input) {
    if (input == null || input.isEmpty) return const <Never, Never>{};
    return Map.unmodifiable(input);
  }

  /// Merges this with [other].
  ///
  /// For most fields, if both configurations have values set, [other]'s value
  /// takes precedence. However, certain fields are merged together instead.
  /// This is indicated in those fields' documentation.
  SuiteConfiguration merge(SuiteConfiguration other) {
    if (this == SuiteConfiguration.empty) return other;
    if (other == SuiteConfiguration.empty) return this;

    var config = SuiteConfiguration._(
        allowDuplicateTestNames:
            other._allowDuplicateTestNames ?? _allowDuplicateTestNames,
        allowTestRandomization:
            other._allowTestRandomization ?? _allowTestRandomization,
        jsTrace: other._jsTrace ?? _jsTrace,
        runSkipped: other._runSkipped ?? _runSkipped,
        dart2jsArgs: dart2jsArgs.toList()..addAll(other.dart2jsArgs),
        precompiledPath: other.precompiledPath ?? precompiledPath,
        patterns: patterns.union(other.patterns),
        runtimes: other._runtimes ?? _runtimes,
        includeTags: includeTags.intersection(other.includeTags),
        excludeTags: excludeTags.union(other.excludeTags),
        tags: _mergeConfigMaps(tags, other.tags),
        onPlatform: _mergeConfigMaps(onPlatform, other.onPlatform),
        line: other.line ?? line,
        col: other.col ?? col,
        ignoreTimeouts: other._ignoreTimeouts ?? _ignoreTimeouts,
        metadata: metadata.merge(other.metadata));
    return config._resolveTags();
  }

  /// Returns a copy of this configuration with the given fields updated.
  ///
  /// Note that unlike [merge], this has no merging behavior—the old value is
  /// always replaced by the new one.
  SuiteConfiguration change(
      {bool? allowDuplicateTestNames,
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
      int? line,
      int? col,
      bool? ignoreTimeouts,

      // Test-level configuration
      Timeout? timeout,
      bool? verboseTrace,
      bool? chainStackTraces,
      bool? skip,
      int? retry,
      String? skipReason,
      PlatformSelector? testOn,
      Iterable<String>? addTags}) {
    var config = SuiteConfiguration._(
        allowDuplicateTestNames:
            allowDuplicateTestNames ?? _allowDuplicateTestNames,
        allowTestRandomization:
            allowTestRandomization ?? _allowTestRandomization,
        jsTrace: jsTrace ?? _jsTrace,
        runSkipped: runSkipped ?? _runSkipped,
        dart2jsArgs: dart2jsArgs?.toList() ?? this.dart2jsArgs,
        precompiledPath: precompiledPath ?? this.precompiledPath,
        patterns: patterns ?? this.patterns,
        runtimes: runtimes ?? _runtimes,
        includeTags: includeTags ?? this.includeTags,
        excludeTags: excludeTags ?? this.excludeTags,
        tags: tags ?? this.tags,
        onPlatform: onPlatform ?? this.onPlatform,
        line: line ?? this.line,
        col: col ?? this.col,
        ignoreTimeouts: ignoreTimeouts ?? _ignoreTimeouts,
        metadata: _metadata.change(
            timeout: timeout,
            verboseTrace: verboseTrace,
            chainStackTraces: chainStackTraces,
            skip: skip,
            retry: retry,
            skipReason: skipReason,
            testOn: testOn,
            tags: addTags?.toSet()));
    return config._resolveTags();
  }

  /// Throws a [FormatException] if this refers to any undefined runtimes.
  void validateRuntimes(List<Runtime> allRuntimes) {
    var validVariables =
        allRuntimes.map((runtime) => runtime.identifier).toSet();
    _metadata.validatePlatformSelectors(validVariables);

    var runtimes = _runtimes;
    if (runtimes != null) {
      for (var selection in runtimes) {
        if (!allRuntimes
            .any((runtime) => runtime.identifier == selection.name)) {
          if (selection.span != null) {
            throw SourceSpanFormatException(
                'Unknown platform "${selection.name}".', selection.span);
          } else {
            throw FormatException('Unknown platform "${selection.name}".');
          }
        }
      }
    }

    onPlatform.forEach((selector, config) {
      selector.validate(validVariables);
      config.validateRuntimes(allRuntimes);
    });
  }

  /// Returns a copy of this with all platform-specific configuration from
  /// [onPlatform] resolved.
  SuiteConfiguration forPlatform(SuitePlatform platform) {
    if (onPlatform.isEmpty) return this;

    var config = this;
    onPlatform.forEach((platformSelector, platformConfig) {
      if (!platformSelector.evaluate(platform)) return;
      config = config.merge(platformConfig);
    });
    return config.change(onPlatform: {});
  }

  /// Merges two maps whose values are [SuiteConfiguration]s.
  ///
  /// Any overlapping keys in the maps have their configurations merged in the
  /// returned map.
  Map<T, SuiteConfiguration> _mergeConfigMaps<T>(
          Map<T, SuiteConfiguration> map1, Map<T, SuiteConfiguration> map2) =>
      mergeMaps(map1, map2,
          value: (config1, config2) => config1.merge(config2));

  SuiteConfiguration _resolveTags() {
    // If there's no tag-specific configuration, or if none of it applies, just
    // return the configuration as-is.
    if (_metadata.tags.isEmpty || tags.isEmpty) return this;

    // Otherwise, resolve the tag-specific components.
    var newTags = Map<BooleanSelector, SuiteConfiguration>.from(tags);
    var merged = tags.keys.fold(empty, (SuiteConfiguration merged, selector) {
      if (!selector.evaluate(_metadata.tags.contains)) return merged;
      return merged.merge(newTags.remove(selector)!);
    });

    if (merged == empty) return this;
    return change(tags: newTags).merge(merged);
  }
}

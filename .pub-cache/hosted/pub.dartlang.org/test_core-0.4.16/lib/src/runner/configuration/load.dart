// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:boolean_selector/boolean_selector.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart';
import 'package:test_api/scaffolding.dart' // ignore: deprecated_member_use
    show
        Timeout;
import 'package:test_api/src/backend/operating_system.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/platform_selector.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/util/identifier_regex.dart'; // ignore: implementation_imports
import 'package:yaml/yaml.dart';

import '../../util/errors.dart';
import '../../util/io.dart';
import '../../util/pretty_print.dart';
import '../configuration.dart';
import '../runtime_selection.dart';
import '../suite.dart';
import 'custom_runtime.dart';
import 'reporters.dart';
import 'runtime_settings.dart';

/// A regular expression matching a Dart identifier.
///
/// This also matches a package name, since they must be Dart identifiers.
final _identifierRegExp = RegExp(r'[a-zA-Z_]\w*');

/// A regular expression matching allowed package names.
///
/// This allows dot-separated valid Dart identifiers. The dots are there for
/// compatibility with Google's internal Dart packages, but they may not be used
/// when publishing a package to pub.dev.
final _packageName =
    RegExp('^${_identifierRegExp.pattern}(\\.${_identifierRegExp.pattern})*\$');

/// Parses configuration from YAML formatted [content].
///
/// If [global] is `true`, this restricts the configuration file to only rules
/// that are supported globally.
///
/// If [sourceUrl] is provided then that will be set as the source url for
/// the yaml document.
///
/// Throws a [FormatException] if the configuration is invalid.
Configuration parse(String content, {Uri? sourceUrl, bool global = false}) {
  var document = loadYamlNode(content, sourceUrl: sourceUrl);

  if (document.value == null) return Configuration.empty;

  if (document is! Map) {
    throw SourceSpanFormatException(
        'The configuration must be a YAML map.', document.span, content);
  }

  var loader =
      _ConfigurationLoader(document as YamlMap, content, global: global);
  return loader.load();
}

/// A helper for [load] that tracks the YAML document.
class _ConfigurationLoader {
  /// The parsed configuration document.
  final YamlMap _document;

  /// The source string for [_document].
  ///
  /// Used for error reporting.
  final String _source;

  /// Whether this is parsing the global configuration file.
  final bool _global;

  /// Whether runner configuration is allowed at this level.
  final bool _runnerConfig;

  _ConfigurationLoader(this._document, this._source,
      {bool global = false, bool runnerConfig = true})
      : _global = global,
        _runnerConfig = runnerConfig;

  /// Loads the configuration in [_document].
  Configuration load() => _loadIncludeConfig()
      .merge(_loadGlobalTestConfig())
      .merge(_loadLocalTestConfig())
      .merge(_loadGlobalRunnerConfig())
      .merge(_loadLocalRunnerConfig());

  /// If an `include` node is contained in [node], merges and returns [config].
  Configuration _loadIncludeConfig() {
    if (!_runnerConfig) {
      _disallow('include');
      return Configuration.empty;
    }

    var includeNode = _document.nodes['include'];
    if (includeNode == null) return Configuration.empty;

    var includePath = _parseNode(includeNode, 'include path', p.fromUri);
    var basePath =
        p.join(p.dirname(p.fromUri(_document.span.sourceUrl)), includePath);
    try {
      return Configuration.load(basePath);
    } on FileSystemException catch (error) {
      throw SourceSpanFormatException(
          getErrorMessage(error), includeNode.span, _source);
    }
  }

  /// Loads test configuration that's allowed in the global configuration file.
  Configuration _loadGlobalTestConfig() {
    var verboseTrace = _getBool('verbose_trace');
    var chainStackTraces = _getBool('chain_stack_traces');
    var foldStackFrames = _loadFoldedStackFrames();
    var jsTrace = _getBool('js_trace');

    var timeout = _parseValue('timeout', (value) => Timeout.parse(value));

    var onPlatform = _getMap('on_platform',
        key: (keyNode) => _parseNode(keyNode, 'on_platform key',
            (value) => PlatformSelector.parse(value, keyNode.span)),
        value: (valueNode) =>
            _nestedConfig(valueNode, 'on_platform value', runnerConfig: false));

    var onOS = _getMap('on_os',
        key: (keyNode) {
          _validate(keyNode, 'on_os key must be a string.',
              (value) => value is String);

          var os = OperatingSystem.find(keyNode.value as String);
          if (os != OperatingSystem.none) return os;

          throw SourceSpanFormatException(
              'Invalid on_os key: No such operating system.',
              keyNode.span,
              _source);
        },
        value: (valueNode) => _nestedConfig(valueNode, 'on_os value'));

    var presets = _getMap('presets',
        key: (keyNode) => _parseIdentifierLike(keyNode, 'presets key'),
        value: (valueNode) => _nestedConfig(valueNode, 'presets value'));

    var config = Configuration.globalTest(
            verboseTrace: verboseTrace,
            jsTrace: jsTrace,
            timeout: timeout,
            presets: presets,
            chainStackTraces: chainStackTraces,
            foldTraceExcept: foldStackFrames['except'],
            foldTraceOnly: foldStackFrames['only'])
        .merge(_extractPresets<PlatformSelector>(
            onPlatform, (map) => Configuration.onPlatform(map)));

    var osConfig = onOS[currentOS];
    return osConfig == null ? config : config.merge(osConfig);
  }

  /// Loads test configuration that's not allowed in the global configuration
  /// file.
  ///
  /// If [_global] is `true`, this will error if there are any local test-level
  /// configuration fields.
  Configuration _loadLocalTestConfig() {
    if (_global) {
      _disallow('skip');
      _disallow('retry');
      _disallow('test_on');
      _disallow('add_tags');
      _disallow('tags');
      _disallow('allow_test_randomization');
      _disallow('allow_duplicate_test_names');
      return Configuration.empty;
    }

    var skipRaw = _getValue('skip', 'boolean or string',
        (value) => (value is bool?) || value is String?);
    String? skipReason;
    bool? skip;
    if (skipRaw is String) {
      skipReason = skipRaw;
      skip = true;
    } else {
      skip = skipRaw as bool?;
    }

    var testOn = _parsePlatformSelector('test_on');

    var addTags = _getList(
        'add_tags', (tagNode) => _parseIdentifierLike(tagNode, 'Tag name'));

    var tags = _getMap('tags',
        key: (keyNode) => _parseNode(
            keyNode, 'tags key', (value) => BooleanSelector.parse(value)),
        value: (valueNode) =>
            _nestedConfig(valueNode, 'tag value', runnerConfig: false));

    var retry = _getNonNegativeInt('retry');

    var allowTestRandomization = _getBool('allow_test_randomization');

    var allowDuplicateTestNames = _getBool('allow_duplicate_test_names');

    return Configuration.localTest(
            skip: skip,
            retry: retry,
            skipReason: skipReason,
            testOn: testOn,
            addTags: addTags,
            allowTestRandomization: allowTestRandomization,
            allowDuplicateTestNames: allowDuplicateTestNames)
        .merge(_extractPresets<BooleanSelector>(
            tags, (map) => Configuration.tags(map)));
  }

  /// Loads runner configuration that's allowed in the global configuration
  /// file.
  ///
  /// If [_runnerConfig] is `false`, this will error if there are any
  /// runner-level configuration fields.
  Configuration _loadGlobalRunnerConfig() {
    if (!_runnerConfig) {
      _disallow('pause_after_load');
      _disallow('reporter');
      _disallow('file_reporters');
      _disallow('concurrency');
      _disallow('names');
      _disallow('plain_names');
      _disallow('platforms');
      _disallow('add_presets');
      _disallow('override_platforms');
      _disallow('include');
      return Configuration.empty;
    }

    var pauseAfterLoad = _getBool('pause_after_load');
    var runSkipped = _getBool('run_skipped');

    var reporter = _getString('reporter');
    if (reporter != null && !allReporters.keys.contains(reporter)) {
      _error('Unknown reporter "$reporter".', 'reporter');
    }

    var fileReporters = _getMap('file_reporters', key: (keyNode) {
      _validate(keyNode, 'file_reporters key must be a string',
          (value) => value is String);
      final reporter = keyNode.value as String;
      if (!allReporters.keys.contains(reporter)) {
        _error('Unknown reporter "$reporter".', 'file_reporters');
      }
      return reporter;
    }, value: (valueNode) {
      _validate(valueNode, 'file_reporters value must be a string',
          (value) => value is String);
      return valueNode.value as String;
    });

    var concurrency = _getInt('concurrency');

    // The UI term "platform" corresponds with the implementation term
    // "runtime". The [Runtime] class used to be called [TestPlatform], but it
    // was changed to avoid conflicting with [SuitePlatform]. We decided not to
    // also change the UI to avoid a painful migration.
    var runtimes = _getList(
        'platforms',
        (runtimeNode) => RuntimeSelection(
            _parseIdentifierLike(runtimeNode, 'Platform name'),
            runtimeNode.span));

    var chosenPresets = _getList('add_presets',
        (presetNode) => _parseIdentifierLike(presetNode, 'Preset name'));

    var overrideRuntimes = _loadOverrideRuntimes();

    var customHtmlTemplatePath = _getString('custom_html_template_path');

    return Configuration.globalRunner(
        pauseAfterLoad: pauseAfterLoad,
        customHtmlTemplatePath: customHtmlTemplatePath,
        runSkipped: runSkipped,
        reporter: reporter,
        fileReporters: fileReporters,
        concurrency: concurrency,
        runtimes: runtimes,
        chosenPresets: chosenPresets,
        overrideRuntimes: overrideRuntimes);
  }

  /// Loads the `override_platforms` field.
  Map<String, RuntimeSettings> _loadOverrideRuntimes() {
    var runtimesNode =
        _getNode('override_platforms', 'map', (value) => value is Map)
            as YamlMap?;
    if (runtimesNode == null) return const {};

    var runtimes = <String, RuntimeSettings>{};
    runtimesNode.nodes.forEach((identifierNode, valueNode) {
      var yamlNode = identifierNode as YamlNode;
      var identifier = _parseIdentifierLike(yamlNode, 'Platform identifier');

      _validate(valueNode, 'Platform definition must be a map.',
          (value) => value is Map);
      var map = valueNode as YamlMap;

      var settings = _expect(map, 'settings');
      _validate(settings, 'Must be a map.', (value) => value is Map);

      runtimes[identifier] =
          RuntimeSettings(identifier, yamlNode.span, [settings as YamlMap]);
    });
    return runtimes;
  }

  /// Loads runner configuration that's not allowed in the global configuration
  /// file.
  ///
  /// If [_runnerConfig] is `false` or if [_global] is `true`, this will error
  /// if there are any local test-level configuration fields.
  Configuration _loadLocalRunnerConfig() {
    if (!_runnerConfig || _global) {
      _disallow('pub_serve');
      _disallow('names');
      _disallow('plain_names');
      _disallow('paths');
      _disallow('filename');
      _disallow('include_tags');
      _disallow('exclude_tags');
      _disallow('define_platforms');
      return Configuration.empty;
    }

    var pubServePort = _getInt('pub_serve');

    var patterns = _getList('names', (nameNode) {
      _validate(nameNode, 'Names must be strings.', (value) => value is String);
      return _parseNode(nameNode, 'name', (value) => RegExp(value));
    })
      ..addAll(_getList('plain_names', (nameNode) {
        _validate(
            nameNode, 'Names must be strings.', (value) => value is String);
        return _parseNode(nameNode, 'name', (value) => RegExp(value));
      }));

    var paths = _getList('paths', (pathNode) {
      _validate(pathNode, 'Paths must be strings.', (value) => value is String);
      _validate(pathNode, 'Paths must be relative.',
          (value) => p.url.isRelative(value as String));

      return PathConfiguration(
        testPath: _parseNode(pathNode, 'path', p.fromUri),
      );
    });

    var filename = _parseValue('filename', (value) => Glob(value));

    var includeTags = _parseBooleanSelector('include_tags');
    var excludeTags = _parseBooleanSelector('exclude_tags');

    var defineRuntimes = _loadDefineRuntimes();

    return Configuration.localRunner(
        pubServePort: pubServePort,
        patterns: patterns,
        paths: paths,
        filename: filename,
        includeTags: includeTags,
        excludeTags: excludeTags,
        defineRuntimes: defineRuntimes);
  }

  /// Returns a map representation of the `fold_stack_frames` configuration.
  ///
  /// The key `except` will correspond to the list of packages to fold.
  /// The key `only` will correspond to the list of packages to keep in a
  /// test [Chain].
  Map<String, List<String>> _loadFoldedStackFrames() {
    var foldOptionSet = false;
    return _getMap('fold_stack_frames', key: (keyNode) {
      _validate(keyNode, 'Must be a string', (value) => value is String);
      _validate(keyNode, 'Must be "only" or "except".',
          (value) => value == 'only' || value == 'except');

      if (foldOptionSet) {
        throw SourceSpanFormatException(
            'Can only contain one of "only" or "except".',
            keyNode.span,
            _source);
      }
      foldOptionSet = true;
      return keyNode.value as String;
    }, value: (valueNode) {
      _validate(
          valueNode,
          'Folded packages must be strings.',
          (valueList) =>
              valueList is YamlList &&
              valueList.every((value) => value is String));

      _validate(
          valueNode,
          'Invalid package name.',
          (valueList) => (valueList as Iterable)
              .every((value) => _packageName.hasMatch(value as String)));

      return List<String>.from(valueNode.value as Iterable);
    });
  }

  /// Loads the `define_platforms` field.
  Map<String, CustomRuntime> _loadDefineRuntimes() {
    var runtimesNode =
        _getNode('define_platforms', 'map', (value) => value is Map)
            as YamlMap?;
    if (runtimesNode == null) return const {};

    var runtimes = <String, CustomRuntime>{};
    runtimesNode.nodes.forEach((identifierNode, valueNode) {
      var yamlNode = identifierNode as YamlNode;
      var identifier = _parseIdentifierLike(yamlNode, 'Platform identifier');

      _validate(valueNode, 'Platform definition must be a map.',
          (value) => value is Map);
      var map = valueNode as YamlMap;

      var nameNode = _expect(map, 'name');
      _validate(nameNode, 'Must be a string.', (value) => value is String);
      var name = nameNode.value as String;

      var parentNode = _expect(map, 'extends');
      var parent = _parseIdentifierLike(parentNode, 'Platform parent');

      var settings = _expect(map, 'settings');
      _validate(settings, 'Must be a map.', (value) => value is Map);

      runtimes[identifier] = CustomRuntime(name, nameNode.span, identifier,
          yamlNode.span, parent, parentNode.span, settings as YamlMap);
    });
    return runtimes;
  }

  /// Throws an exception with [message] if [test] returns `false` when passed
  /// [node]'s value.
  void _validate(YamlNode node, String message, bool Function(dynamic) test) {
    if (test(node.value)) return;
    throw SourceSpanFormatException(message, node.span, _source);
  }

  /// Returns the value of the node at [field].
  ///
  /// If [typeTest] returns `false` for that value, instead throws an error
  /// complaining that the field is not a [typeName].
  Object? _getValue(
      String field, String typeName, bool Function(dynamic) typeTest) {
    var value = _document[field];
    if (value == null || typeTest(value)) return value;
    _error('$field must be ${a(typeName)}.', field);
  }

  /// Returns the YAML node at [field].
  ///
  /// If [typeTest] returns `false` for that node's value, instead throws an
  /// error complaining that the field is not a [typeName].
  ///
  /// Returns `null` if [field] does not have a node in [_document].
  YamlNode? _getNode(
      String field, String typeName, bool Function(dynamic) typeTest) {
    var node = _document.nodes[field];
    if (node == null) return null;
    _validate(node, '$field must be ${a(typeName)}.', typeTest);
    return node;
  }

  /// Asserts that [field] is an int and returns its value.
  int? _getInt(String field) =>
      _getValue(field, 'int', (value) => value is int?) as int?;

  /// Asserts that [field] is a non-negative int and returns its value.
  int? _getNonNegativeInt(String field) =>
      _getValue(field, 'non-negative int', (value) {
        if (value == null) return true;
        return value is int && value >= 0;
      }) as int?;

  /// Asserts that [field] is a boolean and returns its value.
  bool? _getBool(String field) =>
      _getValue(field, 'boolean', (value) => value is bool?) as bool?;

  /// Asserts that [field] is a string and returns its value.
  String? _getString(String field) =>
      _getValue(field, 'string', (value) => value is String?) as String?;

  /// Asserts that [field] is a list and runs [forElement] for each element it
  /// contains.
  ///
  /// Returns a list of values returned by [forElement].
  List<T> _getList<T>(String field, T Function(YamlNode) forElement) {
    var node = _getNode(field, 'list', (value) => value is List) as YamlList?;
    if (node == null) return [];
    return node.nodes.map(forElement).toList();
  }

  /// Asserts that [field] is a map and runs [key] and [value] for each pair.
  ///
  /// Returns a map with the keys and values returned by [key] and [value]. Each
  /// of these defaults to asserting that the value is a string.
  Map<K, V> _getMap<K, V>(String field,
      {K Function(YamlNode)? key, V Function(YamlNode)? value}) {
    var node = _getNode(field, 'map', (value) => value is Map) as YamlMap?;
    if (node == null) return {};

    key ??= (keyNode) {
      _validate(
          keyNode, '$field keys must be strings.', (value) => value is String);

      return keyNode.value as K;
    };

    value ??= (valueNode) {
      _validate(valueNode, '$field values must be strings.',
          (value) => value is String);

      return valueNode.value as V;
    };

    return node.nodes.map((keyNode, valueNode) =>
        MapEntry(key!(keyNode as YamlNode), value!(valueNode)));
  }

  /// Verifies that [node]'s value is an optionally hyphenated Dart identifier,
  /// and returns it
  String _parseIdentifierLike(YamlNode node, String name) {
    _validate(node, '$name must be a string.', (value) => value is String);
    _validate(node, '$name must be an (optionally hyphenated) Dart identifier.',
        (value) => (value as String).contains(anchoredHyphenatedIdentifier));
    return node.value as String;
  }

  /// Parses [node]'s value as a boolean selector.
  BooleanSelector? _parseBooleanSelector(String name) =>
      _parseValue(name, (value) => BooleanSelector.parse(value));

  /// Parses [node]'s value as a platform selector.
  PlatformSelector? _parsePlatformSelector(String field) {
    var node = _document.nodes[field];
    if (node == null) return null;
    return _parseNode(
        node, field, (value) => PlatformSelector.parse(value, node.span));
  }

  /// Asserts that [node] is a string, passes its value to [parse], and returns
  /// the result.
  ///
  /// If [parse] throws a [FormatException], it's wrapped to include [node]'s
  /// span.
  T _parseNode<T>(YamlNode node, String name, T Function(String) parse) {
    _validate(node, '$name must be a string.', (value) => value is String);

    try {
      return parse(node.value as String);
    } on FormatException catch (error) {
      throw SourceSpanFormatException(
          'Invalid $name: ${error.message}', node.span, _source);
    }
  }

  /// Asserts that [field] is a string, passes it to [parse], and returns the
  /// result.
  ///
  /// If [parse] throws a [FormatException], it's wrapped to include [field]'s
  /// span.
  T? _parseValue<T>(String field, T Function(String) parse) {
    var node = _document.nodes[field];
    if (node == null) return null;
    return _parseNode(node, field, parse);
  }

  /// Parses a nested configuration document.
  ///
  /// [name] is the name of the field, which is used for error-handling.
  /// [runnerConfig] controls whether runner configuration is allowed in the
  /// nested configuration. It defaults to [_runnerConfig].
  Configuration _nestedConfig(YamlNode? node, String name,
      {bool? runnerConfig}) {
    if (node == null || node.value == null) return Configuration.empty;

    _validate(node, '$name must be a map.', (value) => value is Map);
    var loader = _ConfigurationLoader(node as YamlMap, _source,
        global: _global, runnerConfig: runnerConfig ?? _runnerConfig);
    return loader.load();
  }

  /// Takes a map that contains [Configuration]s and extracts any
  /// preset-specific configuration into a parent [Configuration].
  ///
  /// This is needed because parameters to [Configuration.new] such as
  /// `onPlatform` take maps to [SuiteConfiguration]s. [SuiteConfiguration]
  /// doesn't support preset-specific configuration, so this extracts the preset
  /// logic into a parent [Configuration], leaving only maps to
  /// [SuiteConfiguration]s. The [create] function is used to construct
  /// [Configuration]s from the resolved maps.
  Configuration _extractPresets<T>(Map<T, Configuration> map,
      Configuration Function(Map<T, SuiteConfiguration>) create) {
    if (map.isEmpty) return Configuration.empty;

    var base = <T, SuiteConfiguration>{};
    var presets = <String, Map<T, SuiteConfiguration>>{};
    map.forEach((key, config) {
      base[key] = config.suiteDefaults;
      config.presets.forEach((preset, presetConfig) {
        presets.putIfAbsent(preset, () => {})[key] = presetConfig.suiteDefaults;
      });
    });

    if (presets.isEmpty) {
      return base.isEmpty ? Configuration.empty : create(base);
    } else {
      var newPresets = presets.map((key, map) => MapEntry(key, create(map)));
      return create(base).change(presets: newPresets);
    }
  }

  /// Asserts that [map] has a field named [field] and returns it.
  YamlNode _expect(YamlMap map, String field) {
    var node = map.nodes[field];
    if (node != null) return node;

    throw SourceSpanFormatException(
        'Missing required field "$field".', map.span, _source);
  }

  /// Throws an error if a field named [field] exists at this level.
  void _disallow(String field) {
    if (!_document.containsKey(field)) return;

    throw SourceSpanFormatException(
        "$field isn't supported here.",
        // We need the key as a [YamlNode] to get its span.
        (_document.nodes.keys.firstWhere((key) => key.value == field)
                as YamlNode)
            .span,
        _source);
  }

  /// Throws a [SourceSpanFormatException] with [message] about [field].
  Never _error(String message, String field) {
    throw SourceSpanFormatException(
        message, _document.nodes[field]!.span, _source);
  }
}

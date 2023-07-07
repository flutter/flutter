// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/yaml.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

/// Provide the options found in the analysis options file.
class AnalysisOptionsProvider {
  /// The source factory used to resolve include declarations
  /// in analysis options files or `null` if include is not supported.
  SourceFactory? sourceFactory;

  AnalysisOptionsProvider([this.sourceFactory]);

  /// Provide the options found in
  /// [root]/[file_paths.analysisOptionsYaml].
  /// Recursively merge options referenced by an include directive
  /// and remove the include directive from the resulting options map.
  /// Return an empty options map if the file does not exist.
  YamlMap getOptions(Folder root) {
    File? optionsFile = getOptionsFile(root);
    if (optionsFile == null) {
      return YamlMap();
    }
    return getOptionsFromFile(optionsFile);
  }

  /// Return the analysis options file from which options should be read, or
  /// `null` if there is no analysis options file for code in the given [root].
  ///
  /// The given [root] directory will be searched first. If no file is found,
  /// then enclosing directories will be searched.
  File? getOptionsFile(Folder root) {
    for (var current in root.withAncestors) {
      var file = current.getChildAssumingFile(file_paths.analysisOptionsYaml);
      if (file.exists) {
        return file;
      }
    }
    return null;
  }

  /// Provide the options found in [file].
  /// Recursively merge options referenced by an include directive
  /// and remove the include directive from the resulting options map.
  /// Return an empty options map if the file does not exist.
  YamlMap getOptionsFromFile(File file) {
    return getOptionsFromSource(FileSource(file));
  }

  /// Provide the options found in [source].
  /// Recursively merge options referenced by an include directive
  /// and remove the include directive from the resulting options map.
  /// Return an empty options map if the file does not exist.
  YamlMap getOptionsFromSource(Source source) {
    YamlMap options = getOptionsFromString(_readAnalysisOptions(source));
    var node = options.valueAt(AnalyzerOptions.include);
    final sourceFactory = this.sourceFactory;
    if (sourceFactory != null && node is YamlScalar) {
      var path = node.value;
      if (path is String) {
        var parent = sourceFactory.resolveUri(source, path);
        if (parent != null) {
          options = merge(getOptionsFromSource(parent), options);
        }
      }
    }
    return options;
  }

  /// Provide the options found in [optionsSource].
  /// An include directive, if present, will be left as-is,
  /// and the referenced options will NOT be merged into the result.
  /// Return an empty options map if the source is null.
  YamlMap getOptionsFromString(String? optionsSource) {
    if (optionsSource == null) {
      return YamlMap();
    }
    try {
      YamlNode doc = loadYamlNode(optionsSource);
      if (doc is YamlMap) {
        return doc;
      }
      return YamlMap();
    } on YamlException catch (e) {
      throw OptionsFormatException(e.message, e.span);
    } catch (e) {
      throw OptionsFormatException('Unable to parse YAML document.');
    }
  }

  /// Merge the given options contents where the values in [defaults] may be
  /// overridden by [overrides].
  ///
  /// Some notes about merge semantics:
  ///
  ///   * lists are merged (without duplicates).
  ///   * lists of scalar values can be promoted to simple maps when merged with
  ///     maps of strings to booleans (e.g., ['opt1', 'opt2'] becomes
  ///     {'opt1': true, 'opt2': true}.
  ///   * maps are merged recursively.
  ///   * if map values cannot be merged, the overriding value is taken.
  ///
  YamlMap merge(YamlMap defaults, YamlMap overrides) =>
      Merger().mergeMap(defaults, overrides);

  /// Read the contents of [source] as a string.
  /// Returns null if source is null or does not exist.
  String? _readAnalysisOptions(Source source) {
    try {
      return source.contents.data;
    } catch (e) {
      // Source can't be read.
      return null;
    }
  }
}

/// Thrown on options format exceptions.
class OptionsFormatException implements Exception {
  final String message;
  final SourceSpan? span;
  OptionsFormatException(this.message, [this.span]);

  @override
  String toString() =>
      'OptionsFormatException: ${message.toString()}, ${span?.toString()}';
}

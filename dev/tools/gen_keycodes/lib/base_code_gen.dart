// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:gen_keycodes/logical_key_data.dart';

import 'physical_key_data.dart';

String _injectDictionary(String template, Map<String, String> dictionary) {
  String result = template;
  for (final String key in dictionary.keys) {
    result = result.replaceAll('@@@$key@@@', dictionary[key] ?? '@@@$key@@@');
  }
  return result;
}

/// Generates a file based on the information in the key data structure given to
/// it.
///
/// [BaseCodeGenerator] finds tokens in the template file that has the form of
/// `@@@TOKEN@@@`, and replace them by looking up the key `TOKEN` from the map
/// returned by [mappings].
///
/// Subclasses must implement [templatePath] and [mappings].
abstract class BaseCodeGenerator {
  /// Create a code generator while providing [keyData] to be used in [mappings].
  BaseCodeGenerator(this.keyData, this.logicalData);

  /// Absolute path to the template file that this file is generated on.
  String get templatePath;

  /// A mapping from tokens to be replaced in the template to the result string.
  Map<String, String> mappings();

  /// Substitutes the various platform specific maps into the template file for
  /// keyboard_maps.dart.
  String generate() {
    final String template = File(templatePath).readAsStringSync();
    return _injectDictionary(template, mappings());
  }

  /// The database of keys loaded from disk.
  final PhysicalKeyData keyData;

  final LogicalKeyData logicalData;
}

/// A code generator which also defines platform-based behavior.
abstract class PlatformCodeGenerator extends BaseCodeGenerator {
  PlatformCodeGenerator(PhysicalKeyData keyData, LogicalKeyData logicalData)
    : super(keyData, logicalData);

  /// Absolute path to the output file.
  ///
  /// How this value will be used is based on the callee.
  String outputPath(String platform);

  static String engineRoot = '';
}

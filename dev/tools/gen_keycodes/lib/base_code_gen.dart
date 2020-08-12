// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as path;

import 'key_data.dart';
import 'utils.dart';

String _injectDictionary(String template, Map<String, String> dictionary) {
  String result = template;
  for (final String key in dictionary.keys) {
    result = result.replaceAll('@@@$key@@@', dictionary[key]);
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
  BaseCodeGenerator(this.keyData);

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
  final KeyData keyData;
}

/// A code generator which also defines platform-based behavior.
abstract class PlatformCodeGenerator extends BaseCodeGenerator {
  PlatformCodeGenerator(KeyData keyData) : super(keyData);

  // Used by platform code generators.
  List<Key> get numpadKeyData {
    return keyData.data.where((Key entry) {
      return entry.constantName.startsWith('numpad') && entry.keyLabel != null;
    }).toList();
  }

  // Used by platform code generators.
  List<Key> get functionKeyData {
    final RegExp functionKeyRe = RegExp(r'^f[0-9]+$');
    return keyData.data.where((Key entry) {
      return functionKeyRe.hasMatch(entry.constantName);
    }).toList();
  }

  /// Absolute path to the output file.
  ///
  /// How this value will be used is based on the callee.
  String outputPath(String platform) => path.join(flutterRoot.path, '..', path.join('engine', 'src', 'flutter', 'shell', 'platform', platform, 'keycodes', 'keyboard_map_$platform.h'));
}

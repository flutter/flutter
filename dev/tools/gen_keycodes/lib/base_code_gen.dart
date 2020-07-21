// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as path;

import 'key_data.dart';
import 'utils.dart';


/// Generates the keyboard_keys.dart and keyboard_maps.dart files, based on the
/// information in the key data structure given to it.
abstract class BaseCodeGenerator {
  BaseCodeGenerator(this.keyData);

  List<Key> get numpadKeyData {
    return keyData.data.where((Key entry) {
      return entry.constantName.startsWith('numpad') && entry.keyLabel != null;
    }).toList();
  }

  List<Key> get functionKeyData {
    final RegExp functionKeyRe = RegExp(r'^f[0-9]+$');
    return keyData.data.where((Key entry) {
      return functionKeyRe.hasMatch(entry.constantName);
    }).toList();
  }

  String get templatePath;

  Map<String, String> mappings();

  String outputPath(String platform) => path.join(flutterRoot.path, '..', path.join('engine', 'src', 'flutter', 'shell', 'platform', platform, 'keycodes', 'keyboard_map_$platform.h'));

  /// Substitutes the various platform specific maps into the template file for
  /// keyboard_maps.dart.
  String generateKeyboardMaps(String platform) {
    final String template = File(templatePath).readAsStringSync();
    return injectDictionary(template, mappings());
  }

  /// The database of keys loaded from disk.
  final KeyData keyData;
}

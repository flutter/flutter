// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'base_code_gen.dart';
import 'key_data.dart';
import 'utils.dart';

/// Generates the event_simulation_keylabels.dart based on the information in the
/// key data structure given to it.
class KeyLabelsCodeGenerator extends BaseCodeGenerator {
  KeyLabelsCodeGenerator(KeyData keyData) : super(keyData);

  /// Gets the generated definitions of logicalKeyLabels.
  String get _logicalKeyLabels {
    String escapeLabel(String label) => label.contains("'") ? 'r"$label"' : "r'$label'";
    final StringBuffer result = StringBuffer();
    void printKey(int flutterId, String keyLabel) {
      if (keyLabel != null)
        result.write('''
  ${toHex(flutterId, digits: 11)}: ${escapeLabel(keyLabel)},
''');
    }

    for (final Key entry in keyData.data) {
      printKey(entry.flutterId, entry.keyLabel);
    }
    for (final String name in Key.synonyms.keys) {
      // Use the first item in the synonyms as a template for the ID to use.
      // It won't end up being the same value because it'll be in the pseudo-key
      // plane.
      final Key entry = keyData.data.firstWhere((Key item) => item.name == Key.synonyms[name][0]);
      printKey(Key.synonymPlane | entry.flutterId, entry.keyLabel);
    }
    return result.toString();
  }

  @override
  String get templatePath => path.join(flutterRoot.path, 'dev', 'tools', 'gen_keycodes', 'data', 'key_labels.tmpl');

  @override
  Map<String, String> mappings() {
    return <String, String>{
      'LOGICAL_KEY_LABELS': _logicalKeyLabels,
    };
  }
}

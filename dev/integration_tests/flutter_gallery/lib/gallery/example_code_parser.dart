// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

const String _kStartTag = '// START ';
const String _kEndTag = '// END';

Map<String?, String>? _exampleCode;

Future<String?> getExampleCode(final String? tag, final AssetBundle bundle) async {
  if (_exampleCode == null) {
    await _parseExampleCode(bundle);
  }
  return _exampleCode![tag];
}

Future<void> _parseExampleCode(final AssetBundle bundle) async {
  final String code = await bundle.loadString('lib/gallery/example_code.dart');
  _exampleCode = <String?, String>{};

  final List<String> lines = code.split('\n');

  List<String>? codeBlock;
  String? codeTag;

  for (final String line in lines) {
    if (codeBlock == null) {
      // Outside a block.
      if (line.startsWith(_kStartTag)) {
        // Starting a new code block.
        codeBlock = <String>[];
        codeTag = line.substring(_kStartTag.length).trim();
      } else {
        // Just skipping the line.
      }
    } else {
      // Inside a block.
      if (line.startsWith(_kEndTag)) {
        // Add the block.
        _exampleCode![codeTag] = codeBlock.join('\n');
        codeBlock = null;
        codeTag = null;
      } else {
        // Add to the current block
        // trimRight() to remove any \r on Windows
        // without removing any useful indentation
        codeBlock.add(line.trimRight());
      }
    }
  }
}

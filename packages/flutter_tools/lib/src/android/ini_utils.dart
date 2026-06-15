// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Parses INI file lines into a Map of key-value pairs.
///
/// INI is a configuration file format that consists of key-value pairs
/// separated by an equals sign (=). Comments start with a hash (#) or
/// semicolon (;) and are ignored.
Map<String, String> parseIniLines(List<String> contents) {
  final results = <String, String>{};

  final Iterable<List<String>> properties = contents
      .map<String>((String l) => l.trim())
      // Strip blank lines/comments
      .where((String l) => l != '' && !l.startsWith('#'))
      // Discard anything that isn't simple name=value
      .where((String l) => l.contains('='))
      // Split into name/value by first '='
      .map<List<String>>((String l) {
        final int equalsIndex = l.indexOf('=');
        return <String>[l.substring(0, equalsIndex), l.substring(equalsIndex + 1)];
      });

  for (final property in properties) {
    results[property[0].trim()] = property[1].trim();
  }

  return results;
}

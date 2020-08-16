// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'base/file_system.dart';
import 'features.dart';

/// The widget cache determines if the body of a single widget was modified since
/// the last scan of the token stream.
class WidgetCache {
  WidgetCache({
    @required FeatureFlags featureFlags,
    @required FileSystem fileSystem,
  }) : _featureFlags = featureFlags,
       _fileSystem = fileSystem;

  static const int _kCacheSize = 5;

  final FeatureFlags _featureFlags;
  final FileSystem _fileSystem;
  final Map<Uri, List<String>> _cache = <Uri, List<String>>{};

  /// If the build method of a single widget was modified, return the widget name.
  ///
  /// If any other changes were made, or there is an error scanning the file,
  /// return `null`.
  Future<String> validateLibrary(Uri uri) async {
    if (!_featureFlags.isSingleWidgetReloadEnabled) {
      return null;
    }
    final File file = _fileSystem.file(uri);
    final List<String> lines = file.readAsLinesSync();


    final List<String> oldLines = _cache.remove(uri);
    if (oldLines == null) {
       // Ensure that the cache does not grow beyond `_kCacheSize`.
      while (_cache.length + 1 > _kCacheSize) {
        final Uri keyToRemove = _cache.keys.first;
        _cache.remove(keyToRemove);
      }
      _cache[uri] = lines;
      return null;
    } else {
      // preserve LRU behavior.
      _cache[uri] = oldLines;
    }
    String className;
    try {
      className = scan(lines, oldLines);
      _cache[uri] = lines;
    } on Exception {
      _cache.remove(uri);
    }
    return className;
  }
}

String scan(List<String> newSource, List<String> oldSource) {
  final List<_ClassOutline> newOutlines = _scanClasses(newSource);
  final List<_ClassOutline> oldOutlines = _scanClasses(oldSource);
  int i = 0;
  int j = 0;
  while (i < newSource.length && j < oldSource.length) {
    if (newSource[i] != oldSource[j]) {
      break;
    }
    i += 1;
    j += 1;
  }
  int x = newSource.length - 1;
  int y = oldSource.length - 1;
  while (x >= i && y >= j) {
    if (newSource[x] != oldSource[y]) {
      break;
    }
    x -= 1;
    y -= 1;
  }
  _ClassOutline newOutline;
  _ClassOutline oldOutline;
  for (final _ClassOutline outline in newOutlines) {
    if (i > outline.start && x < outline.end) {
      newOutline = outline;
    }
  }
  for (final _ClassOutline outline in oldOutlines) {
    if (j > outline.start && y < outline.end) {
      oldOutline = outline;
    }
  }
  if (newOutline == null ||
    oldOutline == null ||
    newOutline.declaration != oldOutline.declaration) {
    return null;
  }
  return newOutline.getWidgetName();
}

List<_ClassOutline> _scanClasses(List<String> source) {
  final List<_ClassOutline> outlines = <_ClassOutline>[];
  _ClassOutline classOutline;

  int braces = 0;
  for (int i = 0; i < source.length; i++) {
    final String line = source[i].trim();
    if (line.startsWith('class')) {
      if (classOutline != null) {
        throw Exception('Error parsing class outline');
      }
      classOutline = _ClassOutline()
        ..start = i
        ..declaration = line;
      braces = _countBraceDelta(line);
      continue;
    }
    if (classOutline != null) {
      braces += _countBraceDelta(line);
      if (braces == 0) {
        classOutline.end = i;
        outlines.add(classOutline);
        classOutline = null;
        braces = 0;
      }
    }
  }

  return outlines;
}

// `{`
const int _openBrace = 0x7B;

// `}`
const int _closeBrace = 0x7D;

// `'`
const int _singleQuote = 0x27;

// `"`
const int _doubleQuote = 0x22;

int _countBraceDelta(String line) {
  bool inQuote = false;
  int quoteChar;
  int total = 0;
  for (final int char in line.codeUnits) {
    if (inQuote) {
      if (char == quoteChar) {
        inQuote = false;
        quoteChar = null;
      }
      continue;
    }
    if (char == _singleQuote || char == _doubleQuote) {
      inQuote = true;
      quoteChar = char;
      continue;
    }
    if (char == _closeBrace) {
      total -= 1;
    } else if (char == _openBrace) {
      total += 1;
    }
  }
  return total;
}

class _ClassOutline {
  String declaration;
  int start;
  int end;

  static final RegExp _whitespace = RegExp(r'\s+');

  String getWidgetName() {
    if (declaration.contains('State<')) {
      List<String> segments = declaration.split('State<');
      if (segments.length != 2) {
        return null;
      }
      final String genericName = segments[1];
      segments = genericName.split('>');
      if (segments.length != 2) {
        return null;
      }
      return segments[0].trim();
    }
    if (declaration.contains('StatelessWidget')) {
      List<String> segments = declaration.split('class');
      if (segments.length != 2) {
        return null;
      }
      final String className = segments[1].trim();
      segments = className.trim().split(_whitespace);
      if (segments.length < 2) {
        return null;
      }
      return segments[0].trim();
    }
    return null;
  }
}

// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility methods requiring dart:io and used by more than one library in the
/// package.
library package_config.util_io;

import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> defaultLoader(Uri uri) async {
  if (uri.isScheme('file')) {
    var file = File.fromUri(uri);
    try {
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }
  if (uri.isScheme('http') || uri.isScheme('https')) {
    return _httpGet(uri);
  }
  throw UnsupportedError('Default URI unsupported scheme: $uri');
}

Future<Uint8List?> _httpGet(Uri uri) async {
  assert(uri.isScheme('http') || uri.isScheme('https'));
  var client = HttpClient();
  var request = await client.getUrl(uri);
  var response = await request.close();
  if (response.statusCode != HttpStatus.ok) {
    return null;
  }
  var splitContent = await response.toList();
  var totalLength = 0;
  if (splitContent.length == 1) {
    var part = splitContent[0];
    if (part is Uint8List) {
      return part;
    }
  }
  for (var list in splitContent) {
    totalLength += list.length;
  }
  var result = Uint8List(totalLength);
  var offset = 0;
  for (var contentPart in splitContent as Iterable<Uint8List>) {
    result.setRange(offset, offset + contentPart.length, contentPart);
    offset += contentPart.length;
  }
  return result;
}

/// The file name of a path.
///
/// The file name is everything after the last occurrence of
/// [Platform.pathSeparator], or the entire string if no
/// path separator occurs in the string.
String fileName(String path) {
  var separator = Platform.pathSeparator;
  var lastSeparator = path.lastIndexOf(separator);
  if (lastSeparator < 0) return path;
  return path.substring(lastSeparator + separator.length);
}

/// The directory name of a path.
///
/// The directory name is everything before the last occurrence of
/// [Platform.pathSeparator], or the empty string if no
/// path separator occurs in the string.
String dirName(String path) {
  var separator = Platform.pathSeparator;
  var lastSeparator = path.lastIndexOf(separator);
  if (lastSeparator < 0) return '';
  return path.substring(0, lastSeparator);
}

/// Join path parts with the [Platform.pathSeparator].
///
/// If a part ends with a path separator, then no extra separator is
/// inserted.
String pathJoin(String part1, String part2, [String? part3]) {
  var separator = Platform.pathSeparator;
  var separator1 = part1.endsWith(separator) ? '' : separator;
  if (part3 == null) {
    return '$part1$separator1$part2';
  }
  var separator2 = part2.endsWith(separator) ? '' : separator;
  return '$part1$separator1$part2$separator2$part3';
}

/// Join an unknown number of path parts with [Platform.pathSeparator].
///
/// If a part ends with a path separator, then no extra separator is
/// inserted.
String pathJoinAll(Iterable<String> parts) {
  var buffer = StringBuffer();
  var separator = '';
  for (var part in parts) {
    buffer
      ..write(separator)
      ..write(part);
    separator =
        part.endsWith(Platform.pathSeparator) ? '' : Platform.pathSeparator;
  }
  return buffer.toString();
}

// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Screenshot {
  final String description;
  final String path;

  Screenshot(this.description, this.path);
}

List<Screenshot> parseScreenshots(List? input) {
  final res = <Screenshot>[];
  if (input == null) {
    return res;
  }

  for (final e in input) {
    if (e is! Map) continue;

    final description = e['description'];
    if (description == null) {
      throw CheckedFromJsonException(
        e,
        'description',
        'Screenshot',
        'Missing required key `description`',
      );
    }

    if (description is! String) {
      throw CheckedFromJsonException(
        e,
        'description',
        'Screenshot',
        '`$description` is not a String',
      );
    }

    final path = e['path'];
    if (path == null) {
      throw CheckedFromJsonException(
        e,
        'path',
        'Screenshot',
        'Missing required key `path`',
      );
    }

    if (path is! String) {
      throw CheckedFromJsonException(
        e,
        'path',
        'Screenshot',
        '`$path` is not a String',
      );
    }

    res.add(Screenshot(description, path));
  }
  return res;
}

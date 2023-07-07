// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';

/// Follows https://mimesniff.spec.whatwg.org/#json-mime-type
@internal
bool isJson(String? contentType) {
  if (contentType == null) return false;
  final mediaType = MediaType.parse(contentType);
  if (mediaType.mimeType == 'application/json') return true;
  if (mediaType.mimeType == 'text/json') return true;
  return mediaType.subtype.endsWith('+json');
}

String escapeVariable(String name) =>
    Uri.encodeQueryComponent(name).replaceAll('+', '%20');

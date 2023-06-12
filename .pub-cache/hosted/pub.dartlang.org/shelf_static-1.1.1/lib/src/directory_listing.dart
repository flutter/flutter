// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';

String _getHeader(String sanitizedHeading) => '''<!DOCTYPE html>
<html>
<head>
  <title>Directory listing for $sanitizedHeading</title>
  <style>
  html, body {
    margin: 0;
    padding: 0;
  }
  body {
    font-family: sans-serif;
  }
  h1 {
    background-color: #4078c0;
    color: white;
    font-weight: normal;
    margin: 0 0 10px 0;
    padding: 16px 32px;
    white-space: nowrap;
  }
  ul {
    margin: 0;
  }
  li {
    padding: 0;
  }
  a {
    line-height: 1.4em;
  }
  </style>
</head>
<body>
  <h1>$sanitizedHeading</h1>
  <ul>
''';

const String _trailer = '''  </ul>
</body>
</html>
''';

Response listDirectory(String fileSystemPath, String dirPath) {
  final controller = StreamController<List<int>>();
  const encoding = Utf8Codec();
  const sanitizer = HtmlEscape();

  void add(String string) {
    controller.add(encoding.encode(string));
  }

  var heading = path.relative(dirPath, from: fileSystemPath);
  if (heading == '.') {
    heading = '/';
  } else {
    heading = '/$heading/';
  }

  add(_getHeader(sanitizer.convert(heading)));

  // Return a sorted listing of the directory contents asynchronously.
  Directory(dirPath).list().toList().then((entities) {
    entities.sort((e1, e2) {
      if (e1 is Directory && e2 is! Directory) {
        return -1;
      }
      if (e1 is! Directory && e2 is Directory) {
        return 1;
      }
      return e1.path.compareTo(e2.path);
    });

    for (var entity in entities) {
      var name = path.relative(entity.path, from: dirPath);
      if (entity is Directory) name += '/';
      final sanitizedName = sanitizer.convert(name);
      add('    <li><a href="$sanitizedName">$sanitizedName</a></li>\n');
    }

    add(_trailer);
    controller.close();
  });

  return Response.ok(
    controller.stream,
    encoding: encoding,
    headers: {HttpHeaders.contentTypeHeader: 'text/html'},
  );
}

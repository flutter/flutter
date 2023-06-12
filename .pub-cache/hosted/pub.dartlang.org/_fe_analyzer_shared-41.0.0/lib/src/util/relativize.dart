// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.util.relativize;

import 'dart:math';

/// Detect if we're on Windows without importing `dart:io`.
bool isWindows = new Uri.directory("C:\\").path ==
    new Uri.directory("C:\\", windows: true).path;

String relativizeUri(Uri base, Uri uri, bool isWindows) {
  bool equalsNCS(String a, String b) {
    return a.toLowerCase() == b.toLowerCase();
  }

  if (!equalsNCS(base.scheme, uri.scheme) ||
      equalsNCS(base.scheme, 'dart') ||
      equalsNCS(base.scheme, 'package')) {
    return uri.toString();
  }

  if (!equalsNCS(base.scheme, 'file')) {
    isWindows = false;
  }

  String normalize(String path) {
    if (isWindows) {
      return path.toLowerCase();
    } else {
      return path;
    }
  }

  if (base.userInfo == uri.userInfo &&
      equalsNCS(base.host, uri.host) &&
      base.port == uri.port &&
      uri.query == "" &&
      uri.fragment == "") {
    if (normalize(uri.path).startsWith(normalize(base.path))) {
      return uri.path.substring(base.path.lastIndexOf('/') + 1);
    }

    if (!base.path.startsWith('/') || !uri.path.startsWith('/')) {
      return uri.toString();
    }

    List<String> uriParts = uri.path.split('/');
    List<String> baseParts = base.path.split('/');
    int common = 0;
    int length = min(uriParts.length, baseParts.length);
    while (common < length &&
        normalize(uriParts[common]) == normalize(baseParts[common])) {
      common++;
    }
    if (common == 1 || (isWindows && common == 2)) {
      // The first part will always be an empty string because the
      // paths are absolute. On Windows, we must also consider drive
      // letters or hostnames.
      if (baseParts.length > common + 1) {
        // Avoid using '..' to go to the root, unless we are already there.
        return uri.path;
      }
    }
    StringBuffer sb = new StringBuffer();
    for (int i = common + 1; i < baseParts.length; i++) {
      sb.write('../');
    }
    for (int i = common; i < uriParts.length - 1; i++) {
      sb.write('${uriParts[i]}/');
    }
    sb.write('${uriParts.last}');
    return sb.toString();
  }
  return uri.toString();
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library filenames;

import 'relativize.dart' show isWindows;

// For information about how to convert Windows file names to URIs:
// http://blogs.msdn.com/b/ie/archive/2006/12/06/file-uris-in-windows.aspx

String nativeToUriPath(String filename) {
  // TODO(ahe): It would be nice to use a Dart library instead.
  if (!isWindows) return filename;
  filename = filename.replaceAll('\\', '/');
  if (filename.length > 2 && filename[1] == ':') {
    filename = "/$filename";
  }
  return filename;
}

String uriPathToNative(String path) {
  // TODO(ahe): It would be nice to use a Dart library instead.
  if (!isWindows) return path;
  if (path.length > 3 && path[0] == '/' && path[2] == ':') {
    return path.substring(1).replaceAll('/', '\\');
  } else {
    return path.replaceAll('/', '\\');
  }
}

Uri nativeToUri(String filename) => Uri.base.resolve(nativeToUriPath(filename));

String appendSlash(String path) => path.endsWith('/') ? path : '$path/';

// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:path/path.dart';

String fileUriToNormalizedPath(Context context, Uri fileUri) {
  assert(fileUri.isScheme('file'));
  var path = context.fromUri(fileUri);
  path = context.normalize(path);
  return path;
}

/// If the [absoluteUri] is a `file` URI that has corresponding `package` URI,
/// return it. If the URI is not valid, e.g. has empty path segments, so
/// does not represent a valid file path, return `null`.
Uri? rewriteFileToPackageUri(SourceFactory sourceFactory, Uri absoluteUri) {
  // Only file URIs get rewritten into package URIs.
  if (!absoluteUri.isScheme('file')) {
    return absoluteUri;
  }

  // It must be a valid URI, e.g. `file:///home/` is not.
  var pathSegments = absoluteUri.pathSegments;
  if (pathSegments.isEmpty || pathSegments.last.isEmpty) {
    return null;
  }

  // We ask for Source only because `restoreUri` needs it.
  // TODO(scheglov) Add more direct way to convert a path to URI.
  var source = sourceFactory.forUri2(absoluteUri);
  if (source == null) {
    return null;
  }

  if (source is InSummarySource) {
    return source.uri;
  }

  return sourceFactory.pathToUri(source.fullName);
}

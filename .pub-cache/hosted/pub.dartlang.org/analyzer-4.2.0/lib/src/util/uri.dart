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

/// Return the canonical URI for the given [absoluteUri], for example a `file`
/// URI to the corresponding `package` URI. If the URI is not valid, so does
/// not represent a valid file path, return `null`.
Uri? rewriteToCanonicalUri(SourceFactory sourceFactory, Uri absoluteUri) {
  var source = sourceFactory.forUri2(absoluteUri);
  if (source == null) {
    return null;
  }

  if (source is InSummarySource) {
    return source.uri;
  }

  return sourceFactory.pathToUri(source.fullName);
}

// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/uri.dart';

class CustomUriResolver extends UriResolver {
  final ResourceProvider resourceProvider;
  final Map<String, String> _urlMappings;

  CustomUriResolver(this.resourceProvider, this._urlMappings);

  @override
  Source? resolveAbsolute(Uri uri) {
    var mapping = _urlMappings[uri.toString()];
    if (mapping == null) {
      return null;
    }
    Uri fileUri = Uri.file(mapping);
    if (!fileUri.isAbsolute) {
      return null;
    }
    var pathContext = resourceProvider.pathContext;
    var path = fileUriToNormalizedPath(pathContext, fileUri);
    return resourceProvider.getFile(path).createSource(uri);
  }
}

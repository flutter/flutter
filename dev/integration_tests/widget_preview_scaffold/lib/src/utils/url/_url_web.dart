// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// NOTE: originally from package:devtools_app_shared

import 'package:web/web.dart';

Map<String, String> loadQueryParams({String Function(String)? urlModifier}) {
  var url = getWebUrl()!;
  url = urlModifier?.call(url) ?? url;
  return Uri.parse(url).queryParameters;
}

String? getWebUrl() => window.location.toString();

void webRedirect(String url) {
  window.location.replace(url);
}

void updateQueryParameter(String key, String? value, {bool reload = false}) {
  final newQueryParams = Map.of(loadQueryParams());
  if (value == null) {
    newQueryParams.remove(key);
  } else {
    newQueryParams[key] = value;
  }
  final newUri = Uri.parse(
    window.location.toString(),
  ).replace(queryParameters: newQueryParams);
  window.history.replaceState(window.history.state, '', newUri.toString());

  if (reload) {
    window.location.reload();
  }
}

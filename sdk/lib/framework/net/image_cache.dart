// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';
import 'dart:collection';
import 'fetch.dart';
import 'package:mojom/mojo/url_response.mojom.dart';

final HashMap<String, List<ImageDecoderCallback>> _pendingRequests =
  new HashMap<String, List<ImageDecoderCallback>>();

final HashMap<String, Image> _completedRequests =
  new HashMap<String, Image>();

void _loadComplete(url, image) {
  _completedRequests[url] = image;
  _pendingRequests[url].forEach((c) => c(image));
  _pendingRequests.remove(url);
}

void load(String url, ImageDecoderCallback callback) {
  Image result = _completedRequests[url];
  if (result != null) {
    callback(_completedRequests[url]);
    return;
  }

  bool newRequest = false;
  _pendingRequests.putIfAbsent(url, () {
    newRequest = true;
    return new List<ImageDecoderCallback>();
  }).add(callback);
  if (newRequest) {
    fetchUrl(url).then((UrlResponse response) {
      if (response.statusCode >= 400) {
        _loadComplete(url, null);
        return;
      }
      new ImageDecoder(response.body.handle.h,
          (image) => _loadComplete(url, image));
    });
  }
}

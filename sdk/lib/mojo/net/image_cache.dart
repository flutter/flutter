// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;
import 'dart:collection';

import 'package:mojom/mojo/url_response.mojom.dart';

import 'fetch.dart';

final HashMap<String, List<sky.ImageDecoderCallback>> _pendingRequests =
  new HashMap<String, List<sky.ImageDecoderCallback>>();

final HashMap<String, sky.Image> _completedRequests =
  new HashMap<String, sky.Image>();

void _loadComplete(String url, sky.Image image) {
  _completedRequests[url] = image;
  _pendingRequests[url].forEach((c) => c(image));
  _pendingRequests.remove(url);
}

void _load(String url, sky.ImageDecoderCallback callback) {
  sky.Image result = _completedRequests[url];
  if (result != null) {
    callback(_completedRequests[url]);
    return;
  }

  bool newRequest = false;
  _pendingRequests.putIfAbsent(url, () {
    newRequest = true;
    return new List<sky.ImageDecoderCallback>();
  }).add(callback);
  if (newRequest) {
    fetchUrl(url).then((UrlResponse response) {
      if (response.statusCode >= 400) {
        _loadComplete(url, null);
        return;
      }
      new sky.ImageDecoder(response.body.handle.h, (image) {
        _loadComplete(url, image);
      });
    });
  }
}

Future<sky.Image> load(String url) {
  Completer<sky.Image> completer = new Completer<sky.Image>();
  _load(url, completer.complete);
  return completer.future;
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'dart:collection';

final HashMap<String, List<sky.ImageLoaderCallback>> _pendingRequests =
  new HashMap<String, List<sky.ImageLoaderCallback>>();

final HashMap<String, sky.Image> _completedRequests =
  new HashMap<String, sky.Image>();

void load(String url, sky.ImageLoaderCallback callback) {
  sky.Image result = _completedRequests[url];
  if (result != null) {
    callback(_completedRequests[url]);
    return;
  }

  bool newRequest = false;
  _pendingRequests.putIfAbsent(url, () {
    newRequest = true;
    return new List<sky.ImageLoaderCallback>();
  }).add(callback);
  if (newRequest) {
    new sky.ImageLoader(url, (image) {
      _completedRequests[url] = image;
      _pendingRequests[url].forEach((c) => c(image));
      _pendingRequests.remove(url);
    });
  }
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(new NetworkImage(
    src: "http://38.media.tumblr.com/avatar_497c78dc767d_128.png",
    fit: ImageFit.contain,
    centerSlice: new Rect.fromLTRB(40.0, 40.0, 88.0, 88.0)
  ));
}

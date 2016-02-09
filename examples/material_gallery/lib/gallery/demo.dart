// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

typedef Widget GalleryDemoBuilder();

class GalleryDemo {
  GalleryDemo({ this.title, this.builder }) {
    assert(title != null);
    assert(builder != null);
  }

  final String title;
  final GalleryDemoBuilder builder;
}

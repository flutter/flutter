// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class LargeImagesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ImageCache imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = 30;
    imageCache.maximumSizeBytes = 50 << 20;
    return GridView.builder(
      itemCount: 1000,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemBuilder: (BuildContext context, int index) {
        return Image.network(
            'http://via.placeholder.com/'
                '${500 + index}x1000',
            key: ValueKey<int>(index));
      },
    ).build(context);
  }
}

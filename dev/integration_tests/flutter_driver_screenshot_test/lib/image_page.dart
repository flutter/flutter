// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import './page.dart';

/// The page that shows an image.
class ImagePage extends PageWidget {

  /// Constructs the ImagePage object.
  const ImagePage()
      : super(title: 'ImagePage', key: const ValueKey<String>('image_page'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Image.asset(
            'assets/red_square.png',
            key: const ValueKey<String>('red_square_image'),
            width: 100,
            height: 100,
            fit: BoxFit.fill,
          ),
        ));
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

/// Displays a new (from image cache's perspective) large image every 500ms.
class LargeImageChangerPage extends StatefulWidget {
  @override
  _LargeImageChangerState createState() => _LargeImageChangerState();
}

class _LargeImageChangerState extends State<LargeImageChangerPage> {
  Timer _timer;
  int imageIndex = 0;
  ImageProvider currentImage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    currentImage = ResizeImage(
      const ExactAssetImage('assets/999x1000.png'),
      width: (MediaQuery.of(context).size.width * 2).toInt() + imageIndex,
      height: (MediaQuery.of(context).size.height * 2).toInt() + imageIndex,
      allowUpscaling: true,
    );
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      currentImage.evict().then((_) {
        setState(() {
          imageIndex = (imageIndex + 1) % 6;
          currentImage = ResizeImage(
            const ExactAssetImage('assets/999x1000.png'),
            width: (MediaQuery.of(context).size.width * 2).toInt() + imageIndex,
            height: (MediaQuery.of(context).size.height * 2).toInt() + imageIndex,
            allowUpscaling: true,
          );
        });
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image(image: currentImage);
  }
}

// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class VideoDemo extends StatelessWidget {
  const VideoDemo({Key key}) : super(key: key);

  static const String routeName = '/video';

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('video_player is not currently supported on the web.'),
    );
  }
}

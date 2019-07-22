// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/cupertino.dart';

const String kViewType = 'simple_view';

/// A simple platform view widget used in this test app.
///
/// Only supports Android and iOS. It returns null on other platforms.
class SimplePlatformView extends StatelessWidget {

  const SimplePlatformView({Key key, this.onPlatformViewCreated}):super(key: key);

  final Function onPlatformViewCreated;
  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return AndroidView(
        key: key,
        viewType: kViewType,
        onPlatformViewCreated: onPlatformViewCreated,
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        key: key,
        viewType: kViewType,
        onPlatformViewCreated: onPlatformViewCreated,
      );
    }

    return null;
  }
}

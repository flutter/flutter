// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A platform view that displays a blue fill.
class SimplePlatformView extends StatelessWidget {
  const SimplePlatformView({super.key});

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // TODO: Implement. https://github.com/flutter/flutter/issues/164130
        return Container();
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: 'simple-platform-view',
          onPlatformViewCreated: (int id) {
            print('iOS platform view created with id: $id');
          },
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
       throw UnimplementedError();
    }
  }
}

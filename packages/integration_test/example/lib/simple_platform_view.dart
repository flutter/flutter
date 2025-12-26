// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A platform view that displays a blue fill.
class SimplePlatformView extends StatelessWidget {
  /// Creates a platform view that displays a blue fill.
  const SimplePlatformView({super.key});

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // TODO(cbracken): Implement. https://github.com/flutter/flutter/issues/164130
        return Container();
      case TargetPlatform.iOS:
        return const UiKitView(viewType: 'simple-platform-view');
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        throw UnimplementedError();
    }
  }
}

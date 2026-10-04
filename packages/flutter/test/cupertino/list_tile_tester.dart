// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// A minimal CupertinoListTile widget for testing purposes.
class TestListTile extends StatelessWidget {
  /// Creates a minimal list tile for testing.
  const TestListTile({super.key, this.title, this.onTap});

  /// The primary content of the list tile.
  final Widget? title;

  /// Called when the user taps this list tile.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      constraints: const BoxConstraints(minHeight: 56.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: title,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: content);
    }

    return content;
  }
}

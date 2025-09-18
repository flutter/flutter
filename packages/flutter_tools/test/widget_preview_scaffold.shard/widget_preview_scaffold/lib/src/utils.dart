// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Returns a [TextStyle] with [FontFeature.proportionalFigures] applied to
/// fix blurry text.
TextStyle fixBlurryText(TextStyle style) {
  return style.copyWith(
    fontFeatures: [const FontFeature.proportionalFigures()],
  );
}

final TextStyle linkTextStyle = fixBlurryText(
  TextStyle(
    decoration: TextDecoration.underline,
    // TODO(bkonyi): this color scheme is from DevTools and should be responsive
    // to changes in the previewer theme.
    color: const Color(0xFF1976D2),
  ),
);

/// A basic vertical spacer.
class VerticalSpacer extends StatelessWidget {
  /// Creates a basic vertical spacer.
  const VerticalSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 10);
  }
}

/// A basic horizontal spacer.
class HorizontalSpacer extends StatelessWidget {
  /// Creates a basic vertical spacer.
  const HorizontalSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 10);
  }
}

/// A widget that explicitly responds to hot reload events.
///
/// Hot reload will always result in [reassemble] being called.
class HotReloadListener extends StatefulWidget {
  const HotReloadListener({
    super.key,
    required this.onHotReload,
    required this.child,
  });

  final VoidCallback onHotReload;
  final Widget child;

  @override
  HotReloadListenerState createState() => HotReloadListenerState();
}

class HotReloadListenerState extends State<HotReloadListener> {
  @override
  void reassemble() {
    super.reassemble();
    widget.onHotReload();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

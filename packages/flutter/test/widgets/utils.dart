// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file defines basic widgets for use in tests for Widgets in `flutter/widgets`.

import 'package:flutter/widgets.dart';

/// Get a color for use in a widget test.
///
/// The returned color will be fully opaque,
/// but the [Color.r], [Color.g], and [Color.b] channels
/// will vary sequentially based on index, cycling every sixth integer.
Color getTestColor(int index) {
  const colors = [
    Color(0xFFFF0000),
    Color(0xFF00FF00),
    Color(0xFF0000FF),
    Color(0xFFFFFF00),
    Color(0xFFFF00FF),
    Color(0xFF00FFFF),
  ];

  return colors[index % colors.length];
}

// TODO(justinmc): replace with `RawButton` or equivalent when available.
/// A very basic button for use in widget tests.
class TestButton extends StatelessWidget {
  const TestButton({
    required this.child,
    this.focusNode,
    this.autofocus = false,
    this.onPressed,
    super.key,
  });

  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onPressed;
  final Widget child;

  void _onFocus() => focusNode?.requestFocus();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'button',
      button: true,
      enabled: onPressed != null,
      onTap: onPressed,
      onFocus: _onFocus,
      focusable: true,
      child: FocusableActionDetector(
        enabled: onPressed != null,
        focusNode: focusNode,
        autofocus: autofocus,
        child: GestureDetector(onTap: onPressed, child: child),
      ),
    );
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

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

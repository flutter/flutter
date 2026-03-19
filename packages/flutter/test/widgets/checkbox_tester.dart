// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file defines a basic checkbox widget for use in tests for Widgets in `flutter/widgets`.

import 'package:flutter/widgets.dart';

/// A very basic checkbox for use in widget tests.
///
/// This widget provides minimal checkbox functionality without depending on
/// Material Design components. It only handles semantic actions for testing
/// purposes and does not render any visual elements.
class TestCheckbox extends StatelessWidget {
  const TestCheckbox({required this.value, required this.onChanged, super.key});

  final bool? value;
  final ValueChanged<bool?>? onChanged;

  void _handleTap() {
    onChanged?.call(value != true);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value ?? false,
      enabled: onChanged != null,
      onTap: onChanged != null ? _handleTap : null,
      child: GestureDetector(
        onTap: onChanged != null ? _handleTap : null,
        child: const SizedBox(width: 48.0, height: 48.0),
      ),
    );
  }
}
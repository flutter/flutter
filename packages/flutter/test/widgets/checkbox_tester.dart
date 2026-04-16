// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// A minimal checkbox widget for testing purposes to avoid relying on
/// widgets from material.dart.
///
/// This provides semantics (checked/unchecked state, enabled/disabled) and
/// tap interaction, matching the behavior that tests expect from a checkbox.
///
/// See https://github.com/flutter/flutter/issues/177415.
class TestCheckbox extends StatelessWidget {
  /// Creates a test checkbox.
  ///
  /// The [value] parameter is required and determines whether the checkbox
  /// is checked.
  const TestCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tristate = false,
  }) : assert(tristate || value != null);

  /// Whether this checkbox is checked.
  ///
  /// When [tristate] is true, a value of null corresponds to the mixed state.
  /// When [tristate] is false, this value must not be null.
  final bool? value;

  /// Called when the value of the checkbox should change.
  ///
  /// When null, the checkbox is disabled.
  final ValueChanged<bool?>? onChanged;

  /// If true, the checkbox's [value] can be true, false, or null.
  ///
  /// When false, the checkbox's [value] must be true or false.
  final bool tristate;

  bool get _enabled => onChanged != null;

  void _handleTap() {
    if (!_enabled) {
      return;
    }
    switch (value) {
      case false:
        onChanged!(true);
      case true:
        onChanged!(tristate ? null : false);
      case null:
        onChanged!(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _enabled ? _handleTap : null,
      child: Semantics(
        checked: value ?? false,
        mixed: tristate && value == null,
        enabled: _enabled,
        child: SizedBox(
          width: 18.0,
          height: 18.0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(),
              color: value ?? false ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}

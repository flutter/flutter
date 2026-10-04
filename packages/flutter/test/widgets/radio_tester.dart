// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// A minimal radio button for widget tests that registers with a [RadioGroup]
/// ancestor, avoiding a dependency on the Material library.
///
/// See https://github.com/flutter/flutter/issues/177028.
class TestRadio<T> extends StatefulWidget {
  const TestRadio({super.key, required this.value, this.focusNode, this.enabled = true});

  /// The value represented by this radio button.
  final T value;

  /// An optional focus node to control focus behavior.
  final FocusNode? focusNode;

  /// Whether this radio button is interactive.
  ///
  /// When false, the radio button does not register with the [RadioGroup]
  /// and cannot be selected.
  final bool enabled;

  @override
  State<TestRadio<T>> createState() => TestRadioState<T>();
}

class TestRadioState<T> extends State<TestRadio<T>> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawRadio<T>(
      value: widget.value,
      mouseCursor: WidgetStateProperty.all<MouseCursor>(SystemMouseCursors.click),
      toggleable: false,
      focusNode: _effectiveFocusNode,
      autofocus: false,
      groupRegistry: widget.enabled ? RadioGroup.maybeOf<T>(context) : null,
      enabled: widget.enabled,
      builder: (BuildContext context, ToggleableStateMixin state) {
        return SizedBox(
          width: 18,
          height: 18,
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.value ?? false ? const Color(0xFF000000) : const Color(0x00000000),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A minimal implementation of [RadioGroupRegistry] for widget tests.
///
/// Useful when testing [RawRadio] in isolation, outside of a [RadioGroup].
class TestRadioGroupRegistry<T> extends RadioGroupRegistry<T> {
  final Set<RadioClient<T>> clients = <RadioClient<T>>{};

  @override
  T? groupValue;

  @override
  ValueChanged<T?> get onChanged =>
      (T? newValue) => groupValue = newValue;

  @override
  void registerClient(RadioClient<T> radio) => clients.add(radio);

  @override
  void unregisterClient(RadioClient<T> radio) => clients.remove(radio);
}

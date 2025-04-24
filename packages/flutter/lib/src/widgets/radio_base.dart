// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'focus_manager.dart';
import 'framework.dart';
import 'ticker_provider.dart';
import 'toggleable.dart';
import 'widget_state.dart';

/// Signature for [RadioBase.painterGetter]
///
/// The getter can use `state` to configure the painter before returning.
typedef RadioPainterGetter = CustomPainter Function(ToggleableStateMixin state);

/// A base class for Radio button that provides basic radio functionalities.
///
/// This widget uses painter returned from `painterGetter` to draw the radio.
/// Consider using [ToggleablePainter] as a base class to implement the painter.
///
/// This widget allows selection between a number of mutually exclusive values.
/// When one radio button in a group is selected, the other radio buttons in the
/// group cease to be selected. The values are of type `T`, the type parameter
/// of the radio class. Enums are commonly used for this purpose.
///
/// The radio button itself does not maintain any state. Instead, selecting the
/// radio invokes the [onChanged] callback, passing [value] as a parameter. If
/// [groupValue] and [value] match, this radio will be selected. Most widgets
/// will respond to [onChanged] by calling [State.setState] to update the
/// radio button's [groupValue].
///
/// See also:
///
///  * [Radio], which uses this widget to build a material styled radio button.
///  * [CupertinoRadio], which uses this widget to build a iOS styled radio button.
class RadioBase<T> extends StatefulWidget {
  /// Creates a radio button.
  ///
  /// The radio button itself does not maintain any state. Instead, when the
  /// radio button is selected, the widget calls the [onChanged] callback. Most
  /// widgets that use a radio button will listen for the [onChanged] callback
  /// and rebuild the radio button with a new [groupValue] to update the visual
  /// appearance of the radio button.
  ///
  /// The all arguments except `key` are required:
  const RadioBase({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.mouseCursor,
    required this.size,
    required this.toggleable,
    required this.focusNode,
    required this.autofocus,
    required this.painterGetter,
  });

  /// {@template flutter.widget.RadioBase.value}
  /// The value represented by this radio button.
  /// {@endtemplate}
  final T value;

  /// {@template flutter.widget.RadioBase.groupValue}
  /// The currently selected value for a group of radio buttons.
  ///
  /// This radio button is considered selected if its [value] matches the
  /// [groupValue].
  /// {@endtemplate}
  final T? groupValue;

  /// {@template flutter.widget.RadioBase.onChanged}
  /// Called when the user selects this radio button.
  ///
  /// The radio button passes [value] as a parameter to this callback. The radio
  /// button does not actually change state until the parent widget rebuilds the
  /// radio button with the new [groupValue].
  ///
  /// If null, the radio button will be displayed as disabled.
  ///
  /// The provided callback will not be invoked if this radio button is already
  /// selected.
  ///
  /// The callback provided to [onChanged] should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt.
  /// {@endtemplate}
  final ValueChanged<T?>? onChanged;

  /// {@template flutter.widget.RadioBase.mouseCursor}
  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// If [mouseCursor] is a [WidgetStateMouseCursor],
  /// [WidgetStateProperty.resolve] is used for the following [WidgetState]s:
  ///
  ///  * [WidgetState.selected].
  ///  * [WidgetState.hovered].
  ///  * [WidgetState.focused].
  ///  * [WidgetState.disabled].
  /// {@endtemplate}
  ///
  /// If null, then the value of [RadioThemeData.mouseCursor] is used.
  /// If that is also null, then [WidgetStateMouseCursor.clickable] is used.
  final WidgetStateProperty<MouseCursor> mouseCursor;

  /// {@template flutter.widget.RadioBase.toggleable}
  /// Set to true if this radio button is allowed to be returned to an
  /// indeterminate state by selecting it again when selected.
  ///
  /// To indicate returning to an indeterminate state, [onChanged] will be
  /// called with null.
  ///
  /// If true, [onChanged] can be called with [value] when selected while
  /// [groupValue] != [value], or with null when selected again while
  /// [groupValue] == [value].
  ///
  /// If false, [onChanged] will be called with [value] when it is selected
  /// while [groupValue] != [value], and only by selecting another radio button
  /// in the group (i.e. changing the value of [groupValue]) can this radio
  /// button be unselected.
  ///
  /// The default is false.
  /// {@endtemplate}
  final bool toggleable;

  /// The size of canvas for painter returned from [painterGetter] to paint.
  final Size size;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// The getter for the painter that used for painting the radio button.
  ///
  /// This getter is used when the build method is called. One is expected
  /// to use the input `state` to update the painter before returning.
  final RadioPainterGetter painterGetter;

  bool get _selected => value == groupValue;

  @override
  State<RadioBase<T>> createState() => _RadioBaseState<T>();
}

class _RadioBaseState<T> extends State<RadioBase<T>>
    with TickerProviderStateMixin, ToggleableStateMixin {
  void _handleChanged(bool? selected) {
    if (selected == null) {
      widget.onChanged!(null);
      return;
    }
    if (selected) {
      widget.onChanged!(widget.value);
    }
  }

  @override
  void didUpdateWidget(RadioBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._selected != oldWidget._selected) {
      animateToValue();
    }
  }

  @override
  ValueChanged<bool?>? get onChanged => widget.onChanged != null ? _handleChanged : null;

  @override
  bool get tristate => widget.toggleable;

  @override
  bool? get value => widget._selected;

  @override
  Widget build(BuildContext context) {
    final bool? accessibilitySelected;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        accessibilitySelected = null;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        accessibilitySelected = widget._selected;
    }

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: widget._selected,
      selected: accessibilitySelected,
      child: buildToggleable(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: widget.mouseCursor,
        size: widget.size,
        painter: widget.painterGetter(this),
      ),
    );
  }
}

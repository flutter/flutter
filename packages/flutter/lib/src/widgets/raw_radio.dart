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

/// Signature for [RawRadio.builder].
///
/// The builder can use `state` to determine the state of the radio and build
/// the visual.
///
/// {@macro flutter.widgets.ToggleableStateMixin.buildToggleableWithChild}
typedef RadioBuilder = Widget Function(BuildContext context, ToggleableStateMixin state);

/// A Radio button that provides basic radio functionalities.
///
/// Provide the `builder` to draw UI for radio.
///
/// {@macro flutter.widgets.ToggleableStateMixin.buildToggleableWithChild}
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
///  * [Radio], which uses this widget to build a Material styled radio button.
///  * [CupertinoRadio], which uses this widget to build a Cupertino styled
///    radio button.
class RawRadio<T> extends StatefulWidget {
  /// Creates a radio button.
  ///
  /// The radio button itself does not maintain any state. Instead, when the
  /// radio button is selected, the widget calls the [onChanged] callback. Most
  /// widgets that use a radio button will listen for the [onChanged] callback
  /// and rebuild the radio button with a new [groupValue] to update the visual
  /// appearance of the radio button.
  const RawRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.mouseCursor,
    required this.toggleable,
    required this.focusNode,
    required this.autofocus,
    required this.builder,
  });

  /// {@template flutter.widget.RawRadio.value}
  /// The value represented by this radio button.
  /// {@endtemplate}
  final T value;

  /// {@template flutter.widget.RawRadio.groupValue}
  /// The currently selected value for a group of radio buttons.
  ///
  /// This radio button is considered selected if its [value] matches the
  /// [groupValue].
  /// {@endtemplate}
  final T? groupValue;

  /// {@template flutter.widget.RawRadio.onChanged}
  /// Called when the user selects this radio button.
  ///
  /// The radio button passes [value] as a parameter to this callback. The radio
  /// button does not actually change state until the parent widget rebuilds the
  /// radio button with the new [groupValue].
  ///
  /// If null, the radio button will be displayed as disabled.
  ///
  /// The provided callback will not be invoked if this radio button is already
  /// selected and [toggleable] is not set to true.
  ///
  /// If the [toggleable] is set to true, tapping a already selected radio will
  /// invoke this callback with `null` as value.
  ///
  /// The callback provided to [onChanged] should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt.
  /// {@endtemplate}
  final ValueChanged<T?>? onChanged;

  /// {@template flutter.widget.RawRadio.mouseCursor}
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
  final WidgetStateProperty<MouseCursor> mouseCursor;

  /// {@template flutter.widget.RawRadio.toggleable}
  /// Set to true if this radio button is allowed to be returned to an
  /// indeterminate state by selecting it again when selected.
  ///
  /// To indicate returning to an indeterminate state, [onChanged] will be
  /// called with null.
  ///
  /// If true, [onChanged] is called with [value] when selected while
  /// [groupValue] != [value], and with null when selected again while
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

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// The builder for the radio button visual.
  ///
  /// Use the input `state` to determine the current state of the radio.
  ///
  /// {@macro flutter.widgets.ToggleableStateMixin.buildToggleableWithChild}
  final RadioBuilder builder;

  bool get _selected => value == groupValue;

  @override
  State<RawRadio<T>> createState() => _RawRadioState<T>();
}

class _RawRadioState<T> extends State<RawRadio<T>>
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
  void didUpdateWidget(RawRadio<T> oldWidget) {
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
      child: buildToggleableWithChild(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: widget.mouseCursor,
        child: widget.builder(context, this),
      ),
    );
  }
}

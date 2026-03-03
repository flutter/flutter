// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'focus_manager.dart';
import 'framework.dart';
import 'localizations.dart';
import 'radio_group.dart';
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
/// {@macro flutter.widget.RawRadio.groupValue}
///
/// If [enabled] is false, the radio will not be interactive.
///
/// See also:
///
///  * [Radio], which uses this widget to build a Material styled radio button.
///  * [CupertinoRadio], which uses this widget to build a Cupertino styled
///    radio button.
class RawRadio<T> extends StatefulWidget {
  /// Creates a radio button.
  ///
  /// If [enabled] is true, the [groupRegistry] must not be null.
  const RawRadio({
    super.key,
    required this.value,
    required this.mouseCursor,
    required this.toggleable,
    required this.focusNode,
    required this.autofocus,
    required this.groupRegistry,
    required this.enabled,
    required this.builder,
  }) : assert(!enabled || groupRegistry != null, 'an enabled raw radio must have a registry');

  /// {@template flutter.widget.RawRadio.value}
  /// The value represented by this radio button.
  /// {@endtemplate}
  final T value;

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
  /// To indicate returning to an indeterminate state, [RadioGroup.onChanged]
  /// of the [RadioGroup] above the widget tree will be called with null.
  ///
  /// If true, [RadioGroup.onChanged] is called with [value] when selected while
  /// [RadioGroup.groupValue] != [value], and with null when selected again while
  /// [RadioGroup.groupValue] == [value].
  ///
  /// If false, [RadioGroup.onChanged] will be called with [value] when it is
  /// selected while [RadioGroup.groupValue] != [value], and only by selecting
  /// another radio button in the group (i.e. changing the value of
  /// [RadioGroup.groupValue]) can this radio button be unselected.
  ///
  /// The default is false.
  /// {@endtemplate}
  final bool toggleable;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// The builder for the radio button visual.
  ///
  /// Use the input `state` to determine the current state of the radio.
  ///
  /// {@macro flutter.widgets.ToggleableStateMixin.buildToggleableWithChild}
  final RadioBuilder builder;

  /// Whether this widget is enabled.
  final bool enabled;

  /// {@template flutter.widget.RawRadio.groupRegistry}
  /// The registry this radio registers to.
  /// {@endtemplate}
  ///
  /// {@template flutter.widget.RawRadio.groupValue}
  /// The radio relies on [groupRegistry] to maintains the state for selection.
  /// If use in conjunction with a [RadioGroup] widget, use [RadioGroup.maybeOf]
  /// to get the group registry from the context.
  /// {@endtemplate}
  final RadioGroupRegistry<T>? groupRegistry;

  @override
  State<RawRadio<T>> createState() => _RawRadioState<T>();
}

class _RawRadioState<T> extends State<RawRadio<T>>
    with TickerProviderStateMixin, ToggleableStateMixin, RadioClient<T> {
  @override
  FocusNode get focusNode => widget.focusNode;

  @override
  bool get enabled => isInteractive;

  @override
  T get radioValue => widget.value;

  @override
  void initState() {
    // This has to be before the init state because the [ToggleableStateMixin]
    // expect the [value] is up-to-date when init its state.
    registry = widget.groupRegistry;
    super.initState();
  }

  /// Handle selection status changed.
  ///
  /// if `selected` is false, nothing happens.
  ///
  /// if `selected` is true, select this radio. i.e. [Radio.onChanged] is called
  /// with [Radio.value]. This also updates the group value in [RadioGroup] if it
  /// is in use.
  ///
  /// if `selected` is null, unselect this radio. Same as `selected` is true
  /// except group value is set to null.
  void _handleChanged(bool? selected) {
    assert(registry != null);
    if (!(selected ?? true)) {
      return;
    }
    if (selected ?? false) {
      registry!.onChanged(widget.value);
    } else {
      registry!.onChanged(null);
    }
  }

  @override
  void didUpdateWidget(RawRadio<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    registry = widget.groupRegistry;
    animateToValue(); // The registry's group value may have changed
  }

  @override
  void dispose() {
    super.dispose();
    registry = null;
  }

  @override
  ValueChanged<bool?>? get onChanged => registry != null ? _handleChanged : null;

  @override
  bool get tristate => widget.toggleable;

  @override
  bool? get value => widget.value == registry?.groupValue;

  @override
  bool get isInteractive => widget.enabled;

  @override
  Widget build(BuildContext context) {
    final bool? accessibilitySelected;
    String? semanticsHint;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        accessibilitySelected = null;
        semanticsHint = null;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        accessibilitySelected = value;
        // Only provide hint for unselected radio buttons to avoid duplication
        // of the selected state announcement.
        // Selected state is already announced by iOS via the 'selected' property.
        if (!(value ?? false)) {
          final WidgetsLocalizations localizations = WidgetsLocalizations.of(context);
          semanticsHint = localizations.radioButtonUnselectedLabel;
        }
    }

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: value,
      selected: accessibilitySelected,
      hint: semanticsHint,
      child: buildToggleableWithChild(
        focusNode: focusNode,
        autofocus: widget.autofocus,
        mouseCursor: widget.mouseCursor,
        child: widget.builder(context, this),
      ),
    );
  }
}

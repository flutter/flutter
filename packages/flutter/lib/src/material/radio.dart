// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'checkbox.dart';
/// @docImport 'list_tile.dart';
/// @docImport 'material.dart';
/// @docImport 'radio_list_tile.dart';
/// @docImport 'slider.dart';
/// @docImport 'switch.dart';
library;

import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'color_scheme.dart';
import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'material_state.dart';
import 'radio_theme.dart';
import 'theme.dart';
import 'theme_data.dart';

// Examples can assume:
// late BuildContext context;
// enum SingingCharacter { lafayette }
// late SingingCharacter? _character;
// late StateSetter setState;

enum _RadioType { material, adaptive }

const double _kOuterRadius = 8.0;
const double _kInnerRadius = 4.5;

/// A group for [Radio]s.
///
/// This widget treats all [Radio]s in the sub tree with the same type T as a
/// group.
///
/// This widget handles the group value for the [Radio]s in the subtree with the
/// same value type. To use this widget, the [Radio.groupValue] must leave as
/// null. Otherwise, an assertion error is thrown.
///
/// Using this widget also provides keyboard navigation and semantics for the
/// radio buttons that matches [APG](https://www.w3.org/WAI/ARIA/apg/patterns/radio/)
///
/// The keyboard behaviors are:
/// * Tab and Shift+Tab: moves focus into and out of radio group. When focus
///   moves into a radio group and a radio button is select, focus is set on
///   selected button. Otherwise, it focus the first radio button in reading
///   order
/// * Space: toggle the selection on the focused radio button
/// * Right and down arrow key: move selection to next radio button in the group
///   in reading order.
/// * Left and up arrow key: move selection to previous radio button in the
///   group in reading order.
///
/// Arrow keys will wrap around if it reach the first or last radio in the
/// group.
///
/// {@tool dartpad}
/// Here is an example of RadioGroup widget.
///
/// Try using tab, arrow keys, and space to see how the widget responds.
///
/// ** See code in examples/api/lib/material/radio/radio_group.0.dart **
/// {@end-tool}
class RadioGroup<T> extends StatefulWidget {
  /// creates a radio group
  ///
  /// The `groupValue` set the selection on a subtree [Radio] with the same
  /// [Radio.value].
  ///
  /// The `onChanged` is called when the selection has changed in the subtree
  /// [Radio]s.
  const RadioGroup({super.key, this.groupValue, required this.onChanged, required this.child})
    : super();

  /// The selected value under this radio group.
  ///
  /// [Radio] under this radio group where its [Radio.value] equals to this
  /// value will be selected.
  final T? groupValue;

  /// Called when selection has changed.
  ///
  /// The value can be null if when unselect the [Radio] with [Radio.toggleable]
  /// set to true.
  final ValueChanged<T?> onChanged;

  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<StatefulWidget> createState() => _RadioGroupState<T>();
}

class _RadioGroupState<T> extends State<RadioGroup<T>> {
  late final Map<ShortcutActivator, Intent> _radioGroupShortcuts = <ShortcutActivator, Intent>{
    const SingleActivator(LogicalKeyboardKey.arrowLeft): VoidCallbackIntent(_selectPreviousRadio),
    const SingleActivator(LogicalKeyboardKey.arrowRight): VoidCallbackIntent(_selectNextRadio),
    const SingleActivator(LogicalKeyboardKey.arrowDown): VoidCallbackIntent(_selectNextRadio),
    const SingleActivator(LogicalKeyboardKey.arrowUp): VoidCallbackIntent(_selectPreviousRadio),
    const SingleActivator(LogicalKeyboardKey.space): VoidCallbackIntent(_toggleFocusedRadio),
  };

  final Set<_RadioState<T>> _radios = <_RadioState<T>>{};

  bool _debugCheckOnlySingleSelection() {
    return _radios.where((_RadioState<T> radio) => radio.value!).length < 2;
  }

  void registerRadio(_RadioState<T> radio) {
    _radios.add(radio);
    assert(
      _debugCheckOnlySingleSelection(),
      "RadioGroupPolicy can't be used for a radio group that allows multiple selection",
    );
  }

  void unregisterRadio(_RadioState<T> radio) => _radios.remove(radio);

  void _toggleFocusedRadio() {
    final _RadioState<T>? radio = _radios.firstWhereOrNull(
      (_RadioState<T> radio) => radio.isInteractive && radio.focusNode.hasFocus,
    );
    if (radio == null) {
      return;
    }
    radio.handleChanged(radio.value! ? null : true);
  }

  void _selectNextRadio() => _selectRadioInDirection(true);

  void _selectPreviousRadio() => _selectRadioInDirection(false);

  void _selectRadioInDirection(bool forward) {
    final Iterable<_RadioState<T>> enabledRadios = _radios.where(
      (_RadioState<T> radio) => radio.isInteractive,
    );
    if (enabledRadios.length < 2) {
      return;
    }
    final FocusNode? currentFocus =
        enabledRadios
            .firstWhereOrNull((_RadioState<T> radio) => radio.focusNode.hasFocus)
            ?.focusNode;
    if (currentFocus == null) {
      // The focused node is either a non interactive radio or other controls.
      return;
    }
    final List<FocusNode> sorted =
        ReadingOrderTraversalPolicy.sort(
          enabledRadios.map<FocusNode>((_RadioState<T> radio) => radio.focusNode),
        ).toList();
    final Iterable<FocusNode> nodesInEffectiveOrder = forward ? sorted : sorted.reversed;

    final Iterator<FocusNode> iterator = nodesInEffectiveOrder.iterator;
    FocusNode? nextFocus;
    while (iterator.moveNext()) {
      if (iterator.current == currentFocus) {
        if (iterator.moveNext()) {
          nextFocus = iterator.current;
        }
        break;
      }
    }
    // Current focus is at the end, the next focus should wrap around.
    nextFocus ??= nodesInEffectiveOrder.first;
    final _RadioState<T> radioToSelect = enabledRadios.firstWhere(
      (_RadioState<T> radio) => radio.focusNode == nextFocus,
    );
    radioToSelect.handleChanged(true);
    nextFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      role: SemanticsRole.radioGroup,
      child: Shortcuts(
        shortcuts: _radioGroupShortcuts,
        child: FocusTraversalGroup(
          policy: _SkipUnselectedRadioPolicy<T>(_radios),
          child: _RadioGroupStateScope<T>(
            state: this,
            groupValue: widget.groupValue,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _RadioGroupStateScope<T> extends InheritedWidget {
  const _RadioGroupStateScope({required this.state, required this.groupValue, required super.child})
    : super();
  final _RadioGroupState<T> state;
  // Needs this to notify listener when group value changes.
  final T? groupValue;

  @override
  bool updateShouldNotify(covariant _RadioGroupStateScope<T> oldWidget) {
    return state != oldWidget.state || groupValue != oldWidget.groupValue;
  }
}

/// A traversal policy that is the same as [ReadingOrderTraversalPolicy] except
/// it skips nodes of unselected radio button if there is one selected radio
/// button.
///
/// If none of the radio is selected, this defaults to
/// [ReadingOrderTraversalPolicy] for all nodes.
///
/// This policy is to ensure when tab into a radio group, it will only focus
/// the current selected radio button and prevent focus to reach unselected one
class _SkipUnselectedRadioPolicy<T> extends ReadingOrderTraversalPolicy {
  _SkipUnselectedRadioPolicy(this.radios);
  final Set<_RadioState<T>> radios;
  @override
  Iterable<FocusNode> sortDescendants(Iterable<FocusNode> descendants, FocusNode currentNode) {
    if (radios.every((_RadioState<T> radio) => !radio.value!)) {
      // None of the radio are selected. Defaults to ReadingOrderTraversalPolicy.
      return super.sortDescendants(descendants, currentNode);
    }
    // Nodes that are not selected AND not currently focused, since we can't
    // remove the focused node from the sorted result.
    final Set<FocusNode> nodeToSkip =
        radios
            .where((_RadioState<T> radio) => !radio.value! && radio.focusNode != currentNode)
            .map<FocusNode>((_RadioState<T> radio) => radio.focusNode)
            .toSet();
    final Iterable<FocusNode> skipsNonSelected = descendants.where(
      (FocusNode node) => !nodeToSkip.contains(node),
    );
    return super.sortDescendants(skipsNonSelected, currentNode);
  }
}

/// A Material Design radio button.
///
/// Used to select between a number of mutually exclusive values. When one radio
/// button in a group is selected, the other radio buttons in the group cease to
/// be selected. The values are of type `T`, the type parameter of the [Radio]
/// class. Enums are commonly used for this purpose.
///
/// {@template flutter.material.Radio.groupValue}
/// The radio button itself does not maintain any state. This is typically used
/// under a [RadioGroup] which provides the group value and thus selection to
/// radio. When using under [RadioGroup], one should assign a [Radio.value] to
/// each radio and leave [Radio.groupValue] null or unassigned.
///
/// If one wants to customize how radio is selected, they can provide both
/// [groupValue] and [value] as parameters. If [groupValue] and [value] match,
/// this radio will be selected. Most widgets will respond to [onChanged]
/// by calling [State.setState] to update the radio button's [groupValue]. If in
/// such case, consider also use [RadioGroupPolicy] to provide better user
/// experience.
/// {@endtemplate}
///
/// {@tool dartpad}
/// Here is an example of Radio widgets wrapped in ListTiles, which is similar
/// to what you could get with the RadioListTile widget.
///
/// The currently selected character is passed into `groupValue`, which is
/// maintained by the example's `State`. In this case, the first [Radio]
/// will start off selected because `_character` is initialized to
/// `SingingCharacter.lafayette`.
///
/// If the second radio button is pressed, the example's state is updated
/// with `setState`, updating `_character` to `SingingCharacter.jefferson`.
/// This causes the buttons to rebuild with the updated `groupValue`, and
/// therefore the selection of the second button.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// ** See code in examples/api/lib/material/radio/radio.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [RadioListTile], which combines this widget with a [ListTile] so that
///    you can give the radio button a label.
///  * [Slider], for selecting a value in a range.
///  * [Checkbox] and [Switch], for toggling a particular value on or off.
///  * <https://material.io/design/components/selection-controls.html#radio-buttons>
class Radio<T> extends StatefulWidget {
  /// Creates a Material Design radio button.
  ///
  /// {@macro flutter.material.Radio.groupValue}
  ///
  /// The following arguments are required:
  ///
  /// * [value] is used to identify this radio
  /// * [onChanged] is called when the user selects this radio button.
  const Radio({
    super.key,
    required this.value,
    @Deprecated(
      'Use RadioGroup to manage group value instead. '
      'This feature was deprecated after v3.32.0-0.0.pre.',
    )
    this.groupValue,
    @Deprecated(
      'Use RadioGroup to handle value change instead. '
      'This feature was deprecated after v3.32.0-0.0.pre.',
    )
    this.onChanged,
    this.mouseCursor,
    this.toggleable = false,
    this.activeColor,
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.focusNode,
    this.autofocus = false,
  }) : _radioType = _RadioType.material,
       useCupertinoCheckmarkStyle = false;

  /// Creates an adaptive [Radio] based on whether the target platform is iOS
  /// or macOS, following Material design's
  /// [Cross-platform guidelines](https://material.io/design/platform-guidance/cross-platform-adaptation.html).
  ///
  /// On iOS and macOS, this constructor creates a [CupertinoRadio], which has
  /// matching functionality and presentation as Material checkboxes, and are the
  /// graphics expected on iOS. On other platforms, this creates a Material
  /// design [Radio].
  ///
  /// If a [CupertinoRadio] is created, the following parameters are ignored:
  /// [mouseCursor], [fillColor], [hoverColor], [overlayColor], [splashRadius],
  /// [materialTapTargetSize], [visualDensity].
  ///
  /// [useCupertinoCheckmarkStyle] is used only if a [CupertinoRadio] is created.
  ///
  /// The target platform is based on the current [Theme]: [ThemeData.platform].
  const Radio.adaptive({
    super.key,
    required this.value,
    @Deprecated(
      'Use RadioGroup to manage group value instead. '
      'This feature was deprecated after v3.32.0-0.0.pre.',
    )
    this.groupValue,
    @Deprecated(
      'Use RadioGroup to handle value change instead. '
      'This feature was deprecated after v3.32.0-0.0.pre.',
    )
    this.onChanged,
    this.mouseCursor,
    this.toggleable = false,
    this.activeColor,
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.focusNode,
    this.autofocus = false,
    this.useCupertinoCheckmarkStyle = false,
  }) : _radioType = _RadioType.adaptive;

  /// The value represented by this radio button.
  final T value;

  /// The currently selected value for a group of radio buttons.
  ///
  /// This radio button is considered selected if its [value] matches the
  /// [groupValue].
  ///
  /// leave this unassigned or null if building this widget under [RadioGroup].
  @Deprecated(
    'Use RadioGroup to manage group value instead. '
    'This feature was deprecated after v3.32.0-0.0.pre.',
  )
  final T? groupValue;

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
  /// gets rebuilt; for example:
  ///
  /// ```dart
  /// Radio<SingingCharacter>(
  ///   value: SingingCharacter.lafayette,
  ///   groupValue: _character,
  ///   onChanged: (SingingCharacter? newValue) {
  ///     setState(() {
  ///       _character = newValue;
  ///     });
  ///   },
  /// )
  /// ```
  @Deprecated(
    'Use RadioGroup to handle value change instead. '
    'This feature was deprecated after v3.32.0-0.0.pre.',
  )
  final ValueChanged<T?>? onChanged;

  /// {@template flutter.material.radio.mouseCursor}
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
  final MouseCursor? mouseCursor;

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
  ///
  /// {@tool dartpad}
  /// This example shows how to enable deselecting a radio button by setting the
  /// [toggleable] attribute.
  ///
  /// ** See code in examples/api/lib/material/radio/radio.toggleable.0.dart **
  /// {@end-tool}
  final bool toggleable;

  /// The color to use when this radio button is selected.
  ///
  /// Defaults to [ColorScheme.secondary].
  ///
  /// If [fillColor] returns a non-null color in the [WidgetState.selected]
  /// state, it will be used instead of this color.
  final Color? activeColor;

  /// {@template flutter.material.radio.fillColor}
  /// The color that fills the radio button, in all [WidgetState]s.
  ///
  /// Resolves in the following states:
  ///  * [WidgetState.selected].
  ///  * [WidgetState.hovered].
  ///  * [WidgetState.focused].
  ///  * [WidgetState.disabled].
  ///
  /// {@tool snippet}
  /// This example resolves the [fillColor] based on the current [WidgetState]
  /// of the [Radio], providing a different [Color] when it is
  /// [WidgetState.disabled].
  ///
  /// ```dart
  /// Radio<int>(
  ///   value: 1,
  ///   groupValue: 1,
  ///   onChanged: (_){},
  ///   fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
  ///     if (states.contains(WidgetState.disabled)) {
  ///       return Colors.orange.withOpacity(.32);
  ///     }
  ///     return Colors.orange;
  ///   })
  /// )
  /// ```
  /// {@end-tool}
  /// {@endtemplate}
  ///
  /// If null, then the value of [activeColor] is used in the selected state. If
  /// that is also null, then the value of [RadioThemeData.fillColor] is used.
  /// If that is also null and [ThemeData.useMaterial3] is false, then
  /// [ThemeData.disabledColor] is used in the disabled state, [ColorScheme.secondary]
  /// is used in the selected state, and [ThemeData.unselectedWidgetColor] is used in the
  /// default state; if [ThemeData.useMaterial3] is true, then [ColorScheme.onSurface]
  /// is used in the disabled state, [ColorScheme.primary] is used in the
  /// selected state and [ColorScheme.onSurfaceVariant] is used in the default state.
  final MaterialStateProperty<Color?>? fillColor;

  /// {@template flutter.material.radio.materialTapTargetSize}
  /// Configures the minimum size of the tap target.
  /// {@endtemplate}
  ///
  /// If null, then the value of [RadioThemeData.materialTapTargetSize] is used.
  /// If that is also null, then the value of [ThemeData.materialTapTargetSize]
  /// is used.
  ///
  /// See also:
  ///
  ///  * [MaterialTapTargetSize], for a description of how this affects tap targets.
  final MaterialTapTargetSize? materialTapTargetSize;

  /// {@template flutter.material.radio.visualDensity}
  /// Defines how compact the radio's layout will be.
  /// {@endtemplate}
  ///
  /// {@macro flutter.material.themedata.visualDensity}
  ///
  /// If null, then the value of [RadioThemeData.visualDensity] is used. If that
  /// is also null, then the value of [ThemeData.visualDensity] is used.
  ///
  /// See also:
  ///
  ///  * [ThemeData.visualDensity], which specifies the [visualDensity] for all
  ///    widgets within a [Theme].
  final VisualDensity? visualDensity;

  /// The color for the radio's [Material] when it has the input focus.
  ///
  /// If [overlayColor] returns a non-null color in the [WidgetState.focused]
  /// state, it will be used instead.
  ///
  /// If null, then the value of [RadioThemeData.overlayColor] is used in the
  /// focused state. If that is also null, then the value of
  /// [ThemeData.focusColor] is used.
  final Color? focusColor;

  /// {@template flutter.material.radio.hoverColor}
  /// The color for the radio's [Material] when a pointer is hovering over it.
  ///
  /// If [overlayColor] returns a non-null color in the [WidgetState.hovered]
  /// state, it will be used instead.
  /// {@endtemplate}
  ///
  /// If null, then the value of [RadioThemeData.overlayColor] is used in the
  /// hovered state. If that is also null, then the value of
  /// [ThemeData.hoverColor] is used.
  final Color? hoverColor;

  /// {@template flutter.material.radio.overlayColor}
  /// The color for the radio's [Material].
  ///
  /// Resolves in the following states:
  ///  * [WidgetState.pressed].
  ///  * [WidgetState.selected].
  ///  * [WidgetState.hovered].
  ///  * [WidgetState.focused].
  /// {@endtemplate}
  ///
  /// If null, then the value of [activeColor] with alpha
  /// [kRadialReactionAlpha], [focusColor] and [hoverColor] is used in the
  /// pressed, focused and hovered state. If that is also null,
  /// the value of [RadioThemeData.overlayColor] is used. If that is also null,
  /// then in Material 2, the value of [ColorScheme.secondary] with alpha
  /// [kRadialReactionAlpha], [ThemeData.focusColor] and [ThemeData.hoverColor]
  /// is used in the pressed, focused and hovered state. In Material3, the default
  /// values are:
  ///   * selected
  ///     * pressed - Theme.colorScheme.onSurface(0.1)
  ///     * hovered - Theme.colorScheme.primary(0.08)
  ///     * focused - Theme.colorScheme.primary(0.1)
  ///   * pressed - Theme.colorScheme.primary(0.1)
  ///   * hovered - Theme.colorScheme.onSurface(0.08)
  ///   * focused - Theme.colorScheme.onSurface(0.1)
  final MaterialStateProperty<Color?>? overlayColor;

  /// {@template flutter.material.radio.splashRadius}
  /// The splash radius of the circular [Material] ink response.
  /// {@endtemplate}
  ///
  /// If null, then the value of [RadioThemeData.splashRadius] is used. If that
  /// is also null, then [kRadialReactionRadius] is used.
  final double? splashRadius;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// Controls whether the checkmark style is used in an iOS-style radio.
  ///
  /// Only usable under the [Radio.adaptive] constructor. If set to true, on
  /// Apple platforms the radio button will appear as an iOS styled checkmark.
  /// Controls the [CupertinoRadio] through [CupertinoRadio.useCheckmarkStyle].
  ///
  /// Defaults to false.
  final bool useCupertinoCheckmarkStyle;

  final _RadioType _radioType;

  @override
  State<Radio<T>> createState() => _RadioState<T>();
}

class _RadioState<T> extends State<Radio<T>> with TickerProviderStateMixin, ToggleableStateMixin {
  final _RadioPainter _painter = _RadioPainter();
  _RadioGroupState<T>? _group;

  FocusNode? _internalFocusNode;

  /// The focus node for this radio state.
  @protected
  FocusNode get focusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  bool get _usesRadioGroup => _group != null;
  bool get _handlesChanges => widget.onChanged != null || _usesRadioGroup;

  T? get _effectiveGroupValue => _group?.widget.groupValue ?? widget.groupValue;

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
  @protected
  void handleChanged(bool? selected) {
    assert(_handlesChanges);
    if (!(selected ?? true)) {
      return;
    }
    _handleGroupValueChanged(selected ?? false ? widget.value : null);
  }

  void _handleGroupValueChanged(T? newGroupValue) {
    if (_usesRadioGroup) {
      _group!.widget.onChanged(newGroupValue);
    }
    if (widget.onChanged != null) {
      widget.onChanged!(newGroupValue);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _RadioGroupState<T>? newGroup =
        context.dependOnInheritedWidgetOfExactType<_RadioGroupStateScope<T>>()?.state;
    if (newGroup != _group) {
      _group?.unregisterRadio(this);
      newGroup?.registerRadio(this);
      _group = newGroup;
    }
    assert(
      _group == null || widget.groupValue == null,
      'A RadioGroup can not wrap Radio widget with a non null groupValue. '
      'Either unassign groupValue or use RadioGroupPolicy instead',
    );
    animateToValue();
  }

  @override
  void didUpdateWidget(Radio<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.groupValue != oldWidget.groupValue) {
      animateToValue();
    }
    assert(
      _group == null || widget.groupValue == null,
      'A RadioGroup can not wrap Radio widget with a non null groupValue. '
      'Either unassign groupValue or use RadioGroupPolicy instead',
    );
  }

  @override
  void dispose() {
    _painter.dispose();
    _internalFocusNode?.dispose();
    _group?.unregisterRadio(this);
    super.dispose();
  }

  @override
  ValueChanged<bool?>? get onChanged => _handlesChanges ? handleChanged : null;

  @override
  bool get tristate => widget.toggleable;

  @override
  bool? get value => widget.value == _effectiveGroupValue;

  @override
  Duration? get reactionAnimationDuration => kRadialReactionDuration;

  MaterialStateProperty<Color?> get _widgetFillColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return null;
      }
      if (states.contains(MaterialState.selected)) {
        return widget.activeColor;
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    switch (widget._radioType) {
      case _RadioType.material:
        break;

      case _RadioType.adaptive:
        final ThemeData theme = Theme.of(context);
        switch (theme.platform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            break;
          case TargetPlatform.iOS:
          case TargetPlatform.macOS:
            return CupertinoRadio<T>(
              value: widget.value,
              groupValue: _effectiveGroupValue,
              onChanged: onChanged != null ? _handleGroupValueChanged : null,
              mouseCursor: widget.mouseCursor,
              toggleable: widget.toggleable,
              activeColor: widget.activeColor,
              focusColor: widget.focusColor,
              focusNode: focusNode,
              autofocus: widget.autofocus,
              useCheckmarkStyle: widget.useCupertinoCheckmarkStyle,
            );
        }
    }

    final RadioThemeData radioTheme = RadioTheme.of(context);
    final RadioThemeData defaults =
        Theme.of(context).useMaterial3 ? _RadioDefaultsM3(context) : _RadioDefaultsM2(context);
    final MaterialTapTargetSize effectiveMaterialTapTargetSize =
        widget.materialTapTargetSize ??
        radioTheme.materialTapTargetSize ??
        defaults.materialTapTargetSize!;
    final VisualDensity effectiveVisualDensity =
        widget.visualDensity ?? radioTheme.visualDensity ?? defaults.visualDensity!;
    Size size = switch (effectiveMaterialTapTargetSize) {
      MaterialTapTargetSize.padded => const Size(
        kMinInteractiveDimension,
        kMinInteractiveDimension,
      ),
      MaterialTapTargetSize.shrinkWrap => const Size(
        kMinInteractiveDimension - 8.0,
        kMinInteractiveDimension - 8.0,
      ),
    };
    size += effectiveVisualDensity.baseSizeAdjustment;

    final MaterialStateProperty<MouseCursor> effectiveMouseCursor =
        MaterialStateProperty.resolveWith<MouseCursor>((Set<MaterialState> states) {
          return MaterialStateProperty.resolveAs<MouseCursor?>(widget.mouseCursor, states) ??
              radioTheme.mouseCursor?.resolve(states) ??
              MaterialStateProperty.resolveAs<MouseCursor>(
                MaterialStateMouseCursor.clickable,
                states,
              );
        });

    // Colors need to be resolved in selected and non selected states separately
    // so that they can be lerped between.
    final Set<MaterialState> activeStates = states..add(MaterialState.selected);
    final Set<MaterialState> inactiveStates = states..remove(MaterialState.selected);
    final Color? activeColor =
        widget.fillColor?.resolve(activeStates) ??
        _widgetFillColor.resolve(activeStates) ??
        radioTheme.fillColor?.resolve(activeStates);
    final Color effectiveActiveColor = activeColor ?? defaults.fillColor!.resolve(activeStates)!;
    final Color? inactiveColor =
        widget.fillColor?.resolve(inactiveStates) ??
        _widgetFillColor.resolve(inactiveStates) ??
        radioTheme.fillColor?.resolve(inactiveStates);
    final Color effectiveInactiveColor =
        inactiveColor ?? defaults.fillColor!.resolve(inactiveStates)!;

    final Set<MaterialState> focusedStates = states..add(MaterialState.focused);
    Color effectiveFocusOverlayColor =
        widget.overlayColor?.resolve(focusedStates) ??
        widget.focusColor ??
        radioTheme.overlayColor?.resolve(focusedStates) ??
        defaults.overlayColor!.resolve(focusedStates)!;

    final Set<MaterialState> hoveredStates = states..add(MaterialState.hovered);
    Color effectiveHoverOverlayColor =
        widget.overlayColor?.resolve(hoveredStates) ??
        widget.hoverColor ??
        radioTheme.overlayColor?.resolve(hoveredStates) ??
        defaults.overlayColor!.resolve(hoveredStates)!;

    final Set<MaterialState> activePressedStates = activeStates..add(MaterialState.pressed);
    final Color effectiveActivePressedOverlayColor =
        widget.overlayColor?.resolve(activePressedStates) ??
        radioTheme.overlayColor?.resolve(activePressedStates) ??
        activeColor?.withAlpha(kRadialReactionAlpha) ??
        defaults.overlayColor!.resolve(activePressedStates)!;

    final Set<MaterialState> inactivePressedStates = inactiveStates..add(MaterialState.pressed);
    final Color effectiveInactivePressedOverlayColor =
        widget.overlayColor?.resolve(inactivePressedStates) ??
        radioTheme.overlayColor?.resolve(inactivePressedStates) ??
        inactiveColor?.withAlpha(kRadialReactionAlpha) ??
        defaults.overlayColor!.resolve(inactivePressedStates)!;

    if (downPosition != null) {
      effectiveHoverOverlayColor =
          states.contains(MaterialState.selected)
              ? effectiveActivePressedOverlayColor
              : effectiveInactivePressedOverlayColor;
      effectiveFocusOverlayColor =
          states.contains(MaterialState.selected)
              ? effectiveActivePressedOverlayColor
              : effectiveInactivePressedOverlayColor;
    }
    final bool? accessibilitySelected;
    // Apple devices also use `selected` to annotate radio button's semantics
    // state.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        accessibilitySelected = null;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        accessibilitySelected = value;
    }

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: value,
      selected: accessibilitySelected,
      child: buildToggleable(
        focusNode: focusNode,
        autofocus: widget.autofocus,
        mouseCursor: effectiveMouseCursor,
        size: size,
        painter:
            _painter
              ..position = position
              ..reaction = reaction
              ..reactionFocusFade = reactionFocusFade
              ..reactionHoverFade = reactionHoverFade
              ..inactiveReactionColor = effectiveInactivePressedOverlayColor
              ..reactionColor = effectiveActivePressedOverlayColor
              ..hoverColor = effectiveHoverOverlayColor
              ..focusColor = effectiveFocusOverlayColor
              ..splashRadius =
                  widget.splashRadius ?? radioTheme.splashRadius ?? kRadialReactionRadius
              ..downPosition = downPosition
              ..isFocused = states.contains(MaterialState.focused)
              ..isHovered = states.contains(MaterialState.hovered)
              ..activeColor = effectiveActiveColor
              ..inactiveColor = effectiveInactiveColor,
      ),
    );
  }
}

class _RadioPainter extends ToggleablePainter {
  @override
  void paint(Canvas canvas, Size size) {
    paintRadialReaction(canvas: canvas, origin: size.center(Offset.zero));

    final Offset center = (Offset.zero & size).center;

    // Outer circle
    final Paint paint =
        Paint()
          ..color = Color.lerp(inactiveColor, activeColor, position.value)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
    canvas.drawCircle(center, _kOuterRadius, paint);

    // Inner circle
    if (!position.isDismissed) {
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(center, _kInnerRadius * position.value, paint);
    }
  }
}

// Hand coded defaults based on Material Design 2.
class _RadioDefaultsM2 extends RadioThemeData {
  _RadioDefaultsM2(this.context);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;

  @override
  MaterialStateProperty<Color> get fillColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return _theme.disabledColor;
      }
      if (states.contains(MaterialState.selected)) {
        return _colors.secondary;
      }
      return _theme.unselectedWidgetColor;
    });
  }

  @override
  MaterialStateProperty<Color> get overlayColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return fillColor.resolve(states).withAlpha(kRadialReactionAlpha);
      }
      if (states.contains(MaterialState.hovered)) {
        return _theme.hoverColor;
      }
      if (states.contains(MaterialState.focused)) {
        return _theme.focusColor;
      }
      return Colors.transparent;
    });
  }

  @override
  MaterialTapTargetSize get materialTapTargetSize => _theme.materialTapTargetSize;

  @override
  VisualDensity get visualDensity => _theme.visualDensity;
}

// BEGIN GENERATED TOKEN PROPERTIES - Radio<T>

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// dart format off
class _RadioDefaultsM3 extends RadioThemeData {
  _RadioDefaultsM3(this.context);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;

  @override
  MaterialStateProperty<Color> get fillColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.disabled)) {
          return _colors.onSurface.withOpacity(0.38);
        }
        if (states.contains(MaterialState.pressed)) {
          return _colors.primary;
        }
        if (states.contains(MaterialState.hovered)) {
          return _colors.primary;
        }
        if (states.contains(MaterialState.focused)) {
          return _colors.primary;
        }
        return _colors.primary;
      }
      if (states.contains(MaterialState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      if (states.contains(MaterialState.pressed)) {
        return _colors.onSurface;
      }
      if (states.contains(MaterialState.hovered)) {
        return _colors.onSurface;
      }
      if (states.contains(MaterialState.focused)) {
        return _colors.onSurface;
      }
      return _colors.onSurfaceVariant;
    });
  }

  @override
  MaterialStateProperty<Color> get overlayColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.pressed)) {
          return _colors.onSurface.withOpacity(0.1);
        }
        if (states.contains(MaterialState.hovered)) {
          return _colors.primary.withOpacity(0.08);
        }
        if (states.contains(MaterialState.focused)) {
          return _colors.primary.withOpacity(0.1);
        }
        return Colors.transparent;
      }
      if (states.contains(MaterialState.pressed)) {
        return _colors.primary.withOpacity(0.1);
      }
      if (states.contains(MaterialState.hovered)) {
        return _colors.onSurface.withOpacity(0.08);
      }
      if (states.contains(MaterialState.focused)) {
        return _colors.onSurface.withOpacity(0.1);
      }
      return Colors.transparent;
    });
  }

  @override
  MaterialTapTargetSize get materialTapTargetSize => _theme.materialTapTargetSize;

  @override
  VisualDensity get visualDensity => _theme.visualDensity;
}
// dart format on

// END GENERATED TOKEN PROPERTIES - Radio<T>

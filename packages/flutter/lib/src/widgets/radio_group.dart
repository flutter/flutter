// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show SemanticsRole;

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'basic.dart';
import 'binding.dart';
import 'focus_manager.dart';
import 'focus_traversal.dart';
import 'framework.dart';
import 'shortcuts.dart';

/// A group for radios.
///
/// This widget treats all radios, such as [RawRadio], [Radio], [CupertinoRadio]
/// in the sub tree with the same type T as a group. Radios with different types
/// are not included in the group.
///
/// This widget handles the group value for the radios in the subtree with the
/// same value type.
///
/// Using this widget also provides keyboard navigation and semantics for the
/// radio buttons that matches [APG](https://www.w3.org/WAI/ARIA/apg/patterns/radio/).
///
/// The keyboard behaviors are:
/// * Tab and Shift+Tab: moves focus into and out of radio group. When focus
///   moves into a radio group and a radio button is select, focus is set on
///   selected button. Otherwise, it focus the first radio button in reading
///   order.
/// * Space: toggle the selection on the focused radio button.
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
/// ** See code in examples/api/lib/widgets/radio_group/radio_group.0.dart **
/// {@end-tool}
class RadioGroup<T> extends StatefulWidget {
  /// Creates a radio group.
  ///
  /// The `groupValue` set the selection on a subtree radio with the same
  /// [RawRadio.value].
  ///
  /// The `onChanged` is called when the selection has changed in the subtree
  /// radios.
  const RadioGroup({super.key, this.groupValue, required this.onChanged, required this.child});

  /// The selected value under this radio group.
  ///
  /// [RawRadio] under this radio group where its [RawRadio.value] equals to this
  /// value will be selected.
  final T? groupValue;

  /// Called when selection has changed.
  ///
  /// The value can be null when unselect the [RawRadio] with
  /// [RawRadio.toggleable] set to true.
  final ValueChanged<T?> onChanged;

  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// Gets the [RadioGroupRegistry] from the above the context.
  ///
  /// This registers a dependencies on the context that it causes rebuild
  /// if [RadioGroupRegistry] has changed or its
  /// [RadioGroupRegistry.groupValue] has changed.
  static RadioGroupRegistry<T>? maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_RadioGroupStateScope<T>>()?.state;
  }

  @override
  State<StatefulWidget> createState() => _RadioGroupState<T>();
}

class _RadioGroupState<T> extends State<RadioGroup<T>> implements RadioGroupRegistry<T> {
  late final Map<ShortcutActivator, Intent> _radioGroupShortcuts = <ShortcutActivator, Intent>{
    const SingleActivator(LogicalKeyboardKey.arrowLeft): VoidCallbackIntent(_selectPreviousRadio),
    const SingleActivator(LogicalKeyboardKey.arrowRight): VoidCallbackIntent(_selectNextRadio),
    const SingleActivator(LogicalKeyboardKey.arrowDown): VoidCallbackIntent(_selectNextRadio),
    const SingleActivator(LogicalKeyboardKey.arrowUp): VoidCallbackIntent(_selectPreviousRadio),
    const SingleActivator(LogicalKeyboardKey.space): VoidCallbackIntent(_toggleFocusedRadio),
  };

  late final _RadioGroupShortcutManager<T> _radioGroupShortcutManager =
      _RadioGroupShortcutManager<T>(shortcuts: _radioGroupShortcuts, state: this);

  final Set<RadioClient<T>> _radios = <RadioClient<T>>{};

  bool _debugHasScheduledSingleSelectionCheck = false;

  /// Schedules a check for the next frame to verify that there is only one
  /// radio with the group value.
  bool _debugScheduleSingleSelectionCheck() {
    if (_debugHasScheduledSingleSelectionCheck) {
      return true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugHasScheduledSingleSelectionCheck = false;
      if (!mounted || _debugCheckOnlySingleSelection()) {
        return;
      }
      throw FlutterError(
        "RadioGroupPolicy can't be used for a radio group that allows multiple selection.",
      );
    }, debugLabel: 'RadioGroup.singleSelectionCheck');
    _debugHasScheduledSingleSelectionCheck = true;
    return true;
  }

  bool _debugCheckOnlySingleSelection() {
    return _radios.where((RadioClient<T> radio) => radio.radioValue == groupValue).length < 2;
  }

  @override
  T? get groupValue => widget.groupValue;

  @override
  void dispose() {
    _radioGroupShortcutManager.dispose();
    super.dispose();
  }

  @override
  void registerClient(RadioClient<T> radio) {
    _radios.add(radio);
    assert(_debugScheduleSingleSelectionCheck());
  }

  @override
  void unregisterClient(RadioClient<T> radio) => _radios.remove(radio);

  void _toggleFocusedRadio() {
    final RadioClient<T>? radio = _radios.firstWhereOrNull(
      (RadioClient<T> radio) => radio.focusNode.hasFocus,
    );
    if (radio == null) {
      return;
    }
    if (radio.radioValue != widget.groupValue) {
      onChanged(radio.radioValue);
      return;
    }

    if (radio.tristate) {
      onChanged(null);
    }
  }

  @override
  ValueChanged<T?> get onChanged => widget.onChanged;

  void _selectNextRadio() => _selectRadioInDirection(true);

  void _selectPreviousRadio() => _selectRadioInDirection(false);

  void _selectRadioInDirection(bool forward) {
    if (_radios.length < 2) {
      return;
    }
    final FocusNode? currentFocus = _radios
        .firstWhereOrNull((RadioClient<T> radio) => radio.focusNode.hasFocus)
        ?.focusNode;
    if (currentFocus == null) {
      // The focused node is either a non interactive radio or other controls.
      return;
    }
    final List<FocusNode> sorted = ReadingOrderTraversalPolicy.sort(
      _radios
          .where((RadioClient<T> radio) => radio.enabled)
          .map<FocusNode>((RadioClient<T> radio) => radio.focusNode),
    ).toList();
    assert(sorted.isNotEmpty);
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
    final RadioClient<T> radioToSelect = _radios.firstWhere(
      (RadioClient<T> radio) => radio.focusNode == nextFocus,
    );
    onChanged(radioToSelect.radioValue);
    nextFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    assert(_debugScheduleSingleSelectionCheck());

    return Semantics(
      container: true,
      role: SemanticsRole.radioGroup,
      child: Shortcuts.manager(
        manager: _radioGroupShortcutManager,
        child: FocusTraversalGroup(
          policy: _SkipUnselectedRadioPolicy<T>(_radios, widget.groupValue),
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

class _RadioGroupShortcutManager<T> extends ShortcutManager {
  _RadioGroupShortcutManager({required super.shortcuts, required this.state});

  final _RadioGroupState<T> state;

  @override
  KeyEventResult handleKeypress(BuildContext context, KeyEvent event) {
    final bool radioHasFocus = state._radios.any(
      (RadioClient<T> radio) => radio.focusNode.hasFocus,
    );
    if (!radioHasFocus) {
      // Ignore the event if no radio is focused. This prevents this handler
      // from unintentionally consuming an event meant for a non-radio widget
      // that currently has focus.
      return KeyEventResult.ignored;
    }
    return super.handleKeypress(context, event);
  }
}

class _RadioGroupStateScope<T> extends InheritedWidget {
  const _RadioGroupStateScope({required this.state, required this.groupValue, required super.child})
    : super();
  final _RadioGroupState<T> state;
  // Need to include group value to notify listener when group value changes.
  final T? groupValue;

  @override
  bool updateShouldNotify(covariant _RadioGroupStateScope<T> oldWidget) {
    return state != oldWidget.state || groupValue != oldWidget.groupValue;
  }
}

/// An abstract interface for registering a group of radios.
///
/// Use [registerClient] or [unregisterClient] to handle registrations of radios.
///
/// The registry manages the group value for the radios. The radio needs to call
/// [onChanged] to notify the group value needs to be changed.
abstract class RadioGroupRegistry<T> {
  /// The group value for the group.
  T? get groupValue;

  /// Registers a radio client.
  ///
  /// The subclass provides additional features, such as keyboard navigation
  /// for the registered clients.
  void registerClient(RadioClient<T> radio);

  /// Unregisters a radio client.
  void unregisterClient(RadioClient<T> radio);

  /// Notifies the registry that the a radio is selected or unselected.
  ValueChanged<T?> get onChanged;
}

/// A client for a [RadioGroupRegistry].
///
/// This is typically mixed with a [State].
///
/// To register to a [RadioGroupRegistry], assign the registry to [registry].
///
/// To unregister from previous [RadioGroupRegistry], either assign a different
/// value to [registry] or set it to null.
mixin RadioClient<T> {
  /// Whether this radio support toggles.
  ///
  /// Used by registry to provide additional feature such as keyboard support.
  bool get tristate;

  /// This value this radio represents.
  ///
  /// Used by registry to provide additional feature such as keyboard support.
  T get radioValue;

  /// Whether this radio is enabled.
  ///
  /// If false, the registry skips this client when handling keyboard
  /// navigation.
  bool get enabled;

  /// Focus node for this radio.
  ///
  /// Used by registry to provide additional feature such as keyboard support.
  FocusNode get focusNode;

  /// The [RadioGroupRegistry] this client register to.
  ///
  /// Setting this property automatically register to the new value and
  /// unregister the old value.
  ///
  /// This should set to null when dispose.
  RadioGroupRegistry<T>? get registry => _registry;
  RadioGroupRegistry<T>? _registry;
  set registry(RadioGroupRegistry<T>? newRegistry) {
    if (_registry != newRegistry) {
      _registry?.unregisterClient(this);
    }
    _registry = newRegistry;
    _registry?.registerClient(this);
  }
}

/// A traversal policy that is the same as [ReadingOrderTraversalPolicy] except
/// it skips nodes of unselected radio button if there is one selected radio
/// button.
///
/// If none of the radio is selected, this defaults to
/// [ReadingOrderTraversalPolicy] for all nodes.
///
/// This policy is to ensure when tabbing into a radio group, it will only focus
/// the current selected radio button and prevent focus from reaching unselected
/// ones.
class _SkipUnselectedRadioPolicy<T> extends ReadingOrderTraversalPolicy {
  _SkipUnselectedRadioPolicy(this.radios, this.groupValue);
  final Set<RadioClient<T>> radios;
  final T? groupValue;

  bool _radioSelected(RadioClient<T> radio) => radio.radioValue == groupValue;

  @override
  Iterable<FocusNode> sortDescendants(Iterable<FocusNode> descendants, FocusNode currentNode) {
    final Iterable<FocusNode> nodesInReadOrder = super.sortDescendants(descendants, currentNode);
    RadioClient<T>? selected = radios.firstWhereOrNull(_radioSelected);

    if (selected == null) {
      // None of the radio are selected. Select the first radio in read order.
      final Map<FocusNode, RadioClient<T>> radioFocusNodes = <FocusNode, RadioClient<T>>{};
      for (final RadioClient<T> radio in radios) {
        radioFocusNodes[radio.focusNode] = radio;
      }

      for (final FocusNode node in nodesInReadOrder) {
        selected = radioFocusNodes[node];
        if (selected != null) {
          break;
        }
      }
    }

    if (selected == null) {
      // None of the radio is selected or focusable, defaults to reading order
      return nodesInReadOrder;
    }

    // Nodes that are not selected AND not currently focused, since we can't
    // remove the focused node from the sorted result.
    final Set<FocusNode> nodeToSkip = radios
        .where((RadioClient<T> radio) => selected != radio && radio.focusNode != currentNode)
        .map<FocusNode>((RadioClient<T> radio) => radio.focusNode)
        .toSet();
    final Iterable<FocusNode> skipsNonSelected = descendants.where(
      (FocusNode node) => !nodeToSkip.contains(node),
    );
    return super.sortDescendants(skipsNonSelected, currentNode);
  }
}

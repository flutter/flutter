// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'ink_well.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Mixin for [State] classes that require knowledge of changing [WidgetState]
/// values for their child widgets.
///
/// This mixin does nothing by mere application to a [State] class, but is
/// helpful when writing `build` methods that include child [InkWell],
/// [GestureDetector], [MouseRegion], or [Focus] widgets. Instead of manually
/// creating handlers for each type of user interaction, such [State] classes can
/// instead provide a `ValueChanged<bool>` function and allow [MaterialStateMixin]
/// to manage the set of active [WidgetState]s, and the calling of [setState]
/// as necessary.
///
/// {@tool snippet}
/// This example shows how to write a [StatefulWidget] that uses the
/// [MaterialStateMixin] class to watch [WidgetState] values.
///
/// ```dart
/// class MyWidget extends StatefulWidget {
///   const MyWidget({super.key, required this.color, required this.child});
///
///   final WidgetStateColor color;
///   final Widget child;
///
///   @override
///   State<MyWidget> createState() => MyWidgetState();
/// }
///
/// class MyWidgetState extends State<MyWidget> with MaterialStateMixin<MyWidget> {
///   @override
///   Widget build(BuildContext context) {
///     return InkWell(
///       onFocusChange: updateMaterialState(WidgetState.focused),
///       child: ColoredBox(
///         color: widget.color.resolve(materialStates),
///         child: widget.child,
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
@optionalTypeArgs
mixin MaterialStateMixin<T extends StatefulWidget> on State<T> {
  /// Managed set of active [WidgetState] values; designed to be passed to
  /// [WidgetStateProperty.resolve] methods.
  ///
  /// To mutate and have [setState] called automatically for you, use
  /// [setMaterialState], [addMaterialState], or [removeMaterialState]. Directly
  /// mutating the set is possible, and may be necessary if you need to alter its
  /// list without calling [setState] (and thus triggering a re-render).
  ///
  /// To check for a single condition, convenience getters [isPressed], [isHovered],
  /// [isFocused], etc, are available for each [WidgetState] value.
  @protected
  Set<WidgetState> materialStates = <WidgetState>{};

  /// Callback factory which accepts a [WidgetState] value and returns a
  /// closure to mutate [materialStates] and call [setState].
  ///
  /// Accepts an optional second named parameter, `onChanged`, which allows
  /// arbitrary functionality to be wired through the [MaterialStateMixin].
  /// If supplied, the [onChanged] function is only called when child widgets
  /// report events that make changes to the current set of [WidgetState]s.
  ///
  /// {@tool snippet}
  /// This example shows how to use the [updateMaterialState] callback factory
  /// in other widgets, including the optional [onChanged] callback.
  ///
  /// ```dart
  /// class MyWidget extends StatefulWidget {
  ///   const MyWidget({super.key, this.onPressed});
  ///
  ///   /// Something important this widget must do when pressed.
  ///   final VoidCallback? onPressed;
  ///
  ///   @override
  ///   State<MyWidget> createState() => MyWidgetState();
  /// }
  ///
  /// class MyWidgetState extends State<MyWidget> with MaterialStateMixin<MyWidget> {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return ColoredBox(
  ///       color: isPressed ? Colors.black : Colors.white,
  ///       child: InkWell(
  ///         onHighlightChanged: updateMaterialState(
  ///           WidgetState.pressed,
  ///           onChanged: (bool val) {
  ///             if (val) {
  ///               widget.onPressed?.call();
  ///             }
  ///           },
  ///         ),
  ///       ),
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  @protected
  ValueChanged<bool> updateMaterialState(WidgetState key, {ValueChanged<bool>? onChanged}) {
    return (bool value) {
      if (materialStates.contains(key) == value) {
        return;
      }
      setMaterialState(key, value);
      onChanged?.call(value);
    };
  }

  /// Mutator to mark a [WidgetState] value as either active or inactive.
  @protected
  void setMaterialState(WidgetState state, bool isSet) {
    return isSet ? addMaterialState(state) : removeMaterialState(state);
  }

  /// Mutator to mark a [WidgetState] value as active.
  @protected
  void addMaterialState(WidgetState state) {
    if (materialStates.add(state)) {
      setState(() {});
    }
  }

  /// Mutator to mark a [WidgetState] value as inactive.
  @protected
  void removeMaterialState(WidgetState state) {
    if (materialStates.remove(state)) {
      setState(() {});
    }
  }

  /// Getter for whether this class considers [WidgetState.disabled] to be active.
  bool get isDisabled => materialStates.contains(WidgetState.disabled);

  /// Getter for whether this class considers [WidgetState.dragged] to be active.
  bool get isDragged => materialStates.contains(WidgetState.dragged);

  /// Getter for whether this class considers [WidgetState.error] to be active.
  bool get isErrored => materialStates.contains(WidgetState.error);

  /// Getter for whether this class considers [WidgetState.focused] to be active.
  bool get isFocused => materialStates.contains(WidgetState.focused);

  /// Getter for whether this class considers [WidgetState.hovered] to be active.
  bool get isHovered => materialStates.contains(WidgetState.hovered);

  /// Getter for whether this class considers [WidgetState.pressed] to be active.
  bool get isPressed => materialStates.contains(WidgetState.pressed);

  /// Getter for whether this class considers [WidgetState.scrolledUnder] to be active.
  bool get isScrolledUnder => materialStates.contains(WidgetState.scrolledUnder);

  /// Getter for whether this class considers [WidgetState.selected] to be active.
  bool get isSelected => materialStates.contains(WidgetState.selected);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Set<WidgetState>>(
        'materialStates',
        materialStates,
        defaultValue: <WidgetState>{},
      ),
    );
  }
}

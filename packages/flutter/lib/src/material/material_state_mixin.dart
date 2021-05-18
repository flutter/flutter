// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/material.dart';

/// Provides a flexible callback and consistent API for [State] objects to track
/// which [MaterialState] values are in effect for their portion of the user
/// interface.
///
/// This mixin does nothing by merely applying it to a [State] class, but is
/// helpful when writing `build` methods that include child [InkWell],
/// [GestureDetector], [MouseRegion], or [Focus] widgets. Instead of manually
/// creating handlers for each type of user interaction, such [State] classes can
/// instead provide a `ValueChanged<bool>` function and allow [MaterialStateMixin]
/// to manage the set of active [MaterialState]s, and the calling of `setState()`
/// as necessary.
///
/// Use of this mixin changes the implementation below, in Example 1, into the
/// ensuing, much shorter implementation in Example 2. The two code samples are
/// functionally equivalent.
///
/// Example 1: Tracking MaterialState values without MaterialStateMixin.
/// ```
/// class MyWidgetState extends State<MyWidget> {
///
///   final Set<MaterialState> materialStates;
///
///   bool get _focused => materialStates.contains(MaterialState.focused);
///
///   void _handleFocusChanged(bool value) {
///     if (value != _focused) {
///       materialStates.add(MaterialState.focused);
///     } else {
///       materialStates.remove(MaterialState.focused);
///     }
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return InkWell(
///       onFocusChange: () => _handleFocusChanged,
///       child: Container(
///         color: widget.color.resolve(materialStates),
///         child: widget.child,
///       ),
///     );
///   }
/// }
/// ```
///
/// Example 2: Tracking MaterialState values WITH MaterialStateMixin.
/// ```
/// class MyWidgetState extends State<MyWidget> extends MaterialStateMixin<MyWidget> {
///
///   @override
///   Widget build(BuildContext context) {
///     return InkWell(
///       onFocusChange: () => updateMaterialState(MaterialState.focused),
///       child: Container(
///         color: widget.color.resolve(materialStates),
///         child: widget.child,
///       ),
///     );
///   }
/// }
/// ```
mixin MaterialStateMixin<T extends StatefulWidget> on State<T> {

  /// Managed set of active [MaterialState] values.
  Set<MaterialState> materialStates = <MaterialState>{};

  /// Callback factory which accepts a [MaterialState] value and returns a
  /// closure to mutate `self.materialStates` and call `setState()`.
  ValueChanged<bool> updateMaterialState(MaterialState key, {ValueChanged<bool>? callback}) {
    return (bool value) {
      if (materialStates.contains(key) == value)
        return;
      setMaterialState(key, value);
      callback?.call(value);
    };
  }

  /// Mutator to mark a [MaterialState] value as either active or inactive.
  void setMaterialState(MaterialState _state, bool isSet) =>
    isSet ?  addMaterialState(_state) : removeMaterialState(_state);


  /// Mutator to mark a [MaterialState] value as active.
  void addMaterialState(MaterialState _state) => setState((){
      materialStates.add(_state);
    });

  /// Mutator to mark a [MaterialState] value as inactive.
  void removeMaterialState(MaterialState _state) => setState((){
      materialStates.remove(_state);
    });


  /// Getter for whether this class considers [MaterialState.disabled] to be active.
  bool get isDisabled => materialStates.contains(MaterialState.disabled);

  /// Getter for whether this class considers [MaterialState.dragged] to be active.
  bool get isDragged => materialStates.contains(MaterialState.dragged);

  /// Getter for whether this class considers [MaterialState.error] to be active.
  bool get isErrored => materialStates.contains(MaterialState.error);

  /// Getter for whether this class considers [MaterialState.focused] to be active.
  bool get isFocused => materialStates.contains(MaterialState.focused);

  /// Getter for whether this class considers [MaterialState.hovered] to be active.
  bool get isHovered => materialStates.contains(MaterialState.hovered);

  /// Getter for whether this class considers [MaterialState.pressed] to be active.
  bool get isPressed => materialStates.contains(MaterialState.pressed);

  /// Getter for whether this class considers [MaterialState.scrolledUnder] to be active.
  bool get isScrolledUnder => materialStates.contains(MaterialState.scrolledUnder);

  /// Getter for whether this class considers [MaterialState.selected] to be active.
  bool get isSelected => materialStates.contains(MaterialState.selected);
}

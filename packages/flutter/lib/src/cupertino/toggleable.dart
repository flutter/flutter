// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A mixin for [StatefulWidget]s that implements iOS-themed toggleable
/// controls (e.g.[CupertinoCheckbox]es).
///
/// This mixin implements the logic for toggling the control when tapped.
/// It does not have any opinion about the visual representation of the
/// toggleable widget. The visuals are defined by a [CustomPainter] passed to
/// the [buildToggleable]. [State] objects using this mixin should call that
/// method from their [build] method.
///
/// This mixin is used to implement the Cupertino components for
/// [CupertinoCheckbox] controls.
@optionalTypeArgs
mixin ToggleableStateMixin<S extends StatefulWidget> on TickerProviderStateMixin<S> {

  /// Whether the [value] of this control can be changed by user interaction.
  ///
  /// The control is considered interactive if the [onChanged] callback is
  /// non-null. If the callback is null, then the control is disabled and
  /// non-interactive. A disabled checkbox, for example, is displayed using a
  /// grey color and its value cannot be changed.
  bool get isInteractive => onChanged != null;

  /// Called when the control changes value.
  ///
  /// If the control is tapped, [onChanged] is called immediately with the new
  /// value.
  ///
  /// The control is considered interactive (see [isInteractive]) if this
  /// callback is non-null. If the callback is null, then the control is
  /// disabled and non-interactive. A disabled checkbox, for example, is
  /// displayed using a grey color and its value cannot be changed.
  ValueChanged<bool?>? get onChanged;

  /// The [value] accessor returns false if this control is "inactive" (not
  /// checked, off, or unselected).
  ///
  /// If [value] is true then the control "active" (checked, on, or selected). If
  /// tristate is true and value is null, then the control is considered to be
  /// in its third or "indeterminate" state..
  bool? get value;

  /// If true, [value] can be true, false, or null, otherwise [value] must
  /// be true or false.
  ///
  /// When [tristate] is true and [value] is null, then the control is
  /// considered to be in its third or "indeterminate" state.
  bool get tristate;

  /// The most recent [Offset] at which a pointer touched the Toggleable.
  ///
  /// This is null if currently no pointer is touching the Toggleable or if
  /// [isInteractive] is false.
  Offset? get downPosition => _downPosition;
  Offset? _downPosition;

  void _handleTapDown(TapDownDetails details) {
    if (isInteractive) {
      setState(() {
        _downPosition = details.localPosition;
      });
    }
  }

  void _handleTap([Intent? _]) {
    if (!isInteractive) {
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
    context.findRenderObject()!.sendSemanticsEvent(const TapSemanticEvent());
  }

  void _handleTapEnd([TapUpDetails? _]) {
    if (_downPosition != null) {
      setState(() { _downPosition = null; });
    }
  }

  bool _focused = false;
  void _handleFocusHighlightChanged(bool focused) {
    if (focused != _focused) {
      setState(() { _focused = focused; });
    }
  }

  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _handleTap),
  };

  /// Typically wraps a `painter` that draws the actual visuals of the
  /// Toggleable with logic to toggle it.
  ///
  /// Consider providing a subclass of [ToggleablePainter] as a `painter`.
  ///
  /// This method must be called from the [build] method of the [State] class
  /// that uses this mixin. The returned [Widget] must be returned from the
  /// build method - potentially after wrapping it in other widgets.
  Widget buildToggleable({
    FocusNode? focusNode,
    ValueChanged<bool>? onFocusChange,
    bool autofocus = false,
    required Size size,
    required CustomPainter painter,
  }) {
    return FocusableActionDetector(
      focusNode: focusNode,
      autofocus: autofocus,
      onFocusChange: onFocusChange,
      enabled: isInteractive,
      actions: _actionMap,
      onShowFocusHighlight: _handleFocusHighlightChanged,
      child: GestureDetector(
        excludeFromSemantics: !isInteractive,
        onTapDown: isInteractive ? _handleTapDown : null,
        onTap: isInteractive ? _handleTap : null,
        onTapUp: isInteractive ? _handleTapEnd : null,
        onTapCancel: isInteractive ? _handleTapEnd : null,
        child: Semantics(
          enabled: isInteractive,
          child: CustomPaint(
            size: size,
            painter: painter,
          ),
        ),
      ),
    );
  }
}

/// A base class for a [CustomPainter] that may be passed to
/// [ToggleableStateMixin.buildToggleable] to draw the visual representation of
/// a Toggleable.
///
/// Subclasses must implement the [paint] method to draw the actual visuals of
/// the Toggleable.
abstract class ToggleablePainter extends ChangeNotifier implements CustomPainter {
  /// The color that should be used in the active state (i.e., when
  /// [ToggleableStateMixin.value] is true).
  ///
  /// For example, a checkbox should use this color when checked.
  Color get activeColor => _activeColor!;
  Color? _activeColor;
  set activeColor(Color value) {
    if (_activeColor == value) {
      return;
    }
    _activeColor = value;
    notifyListeners();
  }

  /// The color that should be used in the inactive state (i.e., when
  /// [ToggleableStateMixin.value] is false).
  ///
  /// For example, a checkbox should use this color when unchecked.
  Color get inactiveColor => _inactiveColor!;
  Color? _inactiveColor;
  set inactiveColor(Color value) {
    if (_inactiveColor == value) {
      return;
    }
    _inactiveColor = value;
    notifyListeners();
  }

  /// The color that should be used for the reaction when [isFocused] is true.
  ///
  /// Used when the toggleable needs to change the reaction color/transparency,
  /// when it has focus.
  Color get focusColor => _focusColor!;
  Color? _focusColor;
  set focusColor(Color value) {
    if (value == _focusColor) {
      return;
    }
    _focusColor = value;
    notifyListeners();
  }

  /// The [Offset] within the Toggleable at which a pointer touched the Toggleable.
  ///
  /// This is null if currently no pointer is touching the Toggleable.
  ///
  /// Usually set to [ToggleableStateMixin.downPosition].
  Offset? get downPosition => _downPosition;
  Offset? _downPosition;
  set downPosition(Offset? value) {
    if (value == _downPosition) {
      return;
    }
    _downPosition = value;
    notifyListeners();
  }

  /// True if this toggleable has the input focus.
  bool get isFocused => _isFocused!;
  bool? _isFocused;
  set isFocused(bool? value) {
    if (value == _isFocused) {
      return;
    }
    _isFocused = value;
    notifyListeners();
  }

  /// Determines whether the toggleable shows as active.
  bool get isActive => _isActive!;
  bool? _isActive;
  set isActive(bool? value) {
    if (value == _isActive) {
      return;
    }
    _isActive = value;
    notifyListeners();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  @override
  bool? hitTest(Offset position) => null;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;

  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;

  @override
  String toString() => describeIdentity(this);
}

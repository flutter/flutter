// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Interactive states that some of the Material widgets can take on when
/// receiving input from the user.
///
/// States are defined by https://material.io/design/interaction/states.html#usage.
///
/// Some Material widgets track their current state in a `Set<MaterialState>`.
///
/// See also:
///
///  * [MaterialStateProperty], an interface for objects that "resolve" to
///    different values depending on a widget's material state.
///  * [MaterialStateColor], a [Color] that implements `MaterialStateProperty`
///    which is used in APIs that need to accept either a [Color] or a
///    `MaterialStateProperty<Color>`.
///  * [MaterialStateMouseCursor], a [MouseCursor] that implements `MaterialStateProperty`.
///    which is used in APIs that need to accept either a [MouseCursor] or a
///    [MaterialStateProperty<MouseCursor>].

enum MaterialState {
  /// The state when the user drags their mouse cursor over the given widget.
  ///
  /// See: https://material.io/design/interaction/states.html#hover.
  hovered,

  /// The state when the user navigates with the keyboard to a given widget.
  ///
  /// This can also sometimes be triggered when a widget is tapped. For example,
  /// when a [TextField] is tapped, it becomes [focused].
  ///
  /// See: https://material.io/design/interaction/states.html#focus.
  focused,

  /// The state when the user is actively pressing down on the given widget.
  ///
  /// See: https://material.io/design/interaction/states.html#pressed.
  pressed,

  /// The state when this widget is being dragged from one place to another by
  /// the user.
  ///
  /// https://material.io/design/interaction/states.html#dragged.
  dragged,

  /// The state when this item has been selected.
  ///
  /// This applies to things that can be toggled (such as chips and checkboxes)
  /// and things that are selected from a set of options (such as tabs and radio buttons).
  ///
  /// See: https://material.io/design/interaction/states.html#selected.
  selected,

  /// The state when this widget disabled and can not be interacted with.
  ///
  /// Disabled widgets should not respond to hover, focus, press, or drag
  /// interactions.
  ///
  /// See: https://material.io/design/interaction/states.html#disabled.
  disabled,

  /// The state when the widget has entered some form of invalid state.
  ///
  /// See https://material.io/design/interaction/states.html#usage.
  error,
}

/// Signature for the function that returns a value of type `T` based on a given
/// set of states.
typedef MaterialPropertyResolver<T> = T Function(Set<MaterialState> states);

/// Defines a [Color] that is also a [MaterialStateProperty].
///
/// This class exists to enable widgets with [Color] valued properties
/// to also accept [MaterialStateProperty<Color>] values. A material
/// state color property represents a color which depends on
/// a widget's "interactive state". This state is represented as a
/// [Set] of [MaterialState]s, like [MaterialState.pressed],
/// [MaterialState.focused] and [MaterialState.hovered].
///
/// To use a [MaterialStateColor], you can either:
///   1. Create a subclass of [MaterialStateColor] and implement the abstract `resolve` method.
///   2. Use [MaterialStateColor.resolveWith] and pass in a callback that
///      will be used to resolve the color in the given states.
///
/// If a [MaterialStateColor] is used for a property or a parameter that doesn't
/// support resolving [MaterialStateProperty<Color>]s, then its default color
/// value will be used for all states.
///
/// To define a `const` [MaterialStateColor], you'll need to extend
/// [MaterialStateColor] and override its [resolve] method. You'll also need
/// to provide a `defaultValue` to the super constructor, so that we can know
/// at compile-time what its default color is.
///
/// {@tool snippet}
///
/// This example defines a `MaterialStateColor` with a const constructor.
///
/// ```dart
/// class MyColor extends MaterialStateColor {
///   static const int _defaultColor = 0xcafefeed;
///   static const int _pressedColor = 0xdeadbeef;
///
///   const MyColor() : super(_defaultColor);
///
///   @override
///   Color resolve(Set<MaterialState> states) {
///     if (states.contains(MaterialState.pressed)) {
///       return const Color(_pressedColor);
///     }
///     return const Color(_defaultColor);
///   }
/// }
/// ```
/// {@end-tool}
abstract class MaterialStateColor extends Color implements MaterialStateProperty<Color> {
  /// Creates a [MaterialStateColor].
  const MaterialStateColor(int defaultValue) : super(defaultValue);

  /// Creates a [MaterialStateColor] from a [MaterialPropertyResolver<Color>]
  /// callback function.
  ///
  /// If used as a regular color, the color resolved in the default state (the
  /// empty set of states) will be used.
  ///
  /// The given callback parameter must return a non-null color in the default
  /// state.
  static MaterialStateColor resolveWith(MaterialPropertyResolver<Color> callback) => _MaterialStateColor(callback);

  /// Returns a [Color] that's to be used when a Material component is in the
  /// specified state.
  @override
  Color resolve(Set<MaterialState> states);
}

/// A [MaterialStateColor] created from a [MaterialPropertyResolver<Color>]
/// callback alone.
///
/// If used as a regular color, the color resolved in the default state will
/// be used.
///
/// Used by [MaterialStateColor.resolveWith].
class _MaterialStateColor extends MaterialStateColor {
  _MaterialStateColor(this._resolve) : super(_resolve(_defaultStates).value);

  final MaterialPropertyResolver<Color> _resolve;

  /// The default state for a Material component, the empty set of interaction states.
  static const Set<MaterialState> _defaultStates = <MaterialState>{};

  @override
  Color resolve(Set<MaterialState> states) => _resolve(states);
}

/// Defines a [MouseCursor] whose value depends on a set of [MaterialState]s which
/// represent the interactive state of a component.
///
/// This kind of [MouseCursor] is useful when the set of interactive
/// actions a widget supports varies with its state. For example, a
/// mouse pointer hovering over a disabled [ListTile] should not
/// display [SystemMouseCursors.click], since a disabled list tile
/// doesn't respond to mouse clicks. [ListTile]'s default mouse cursor
/// is a [MaterialStateMouseCursor.clickable], which resolves to
/// [SystemMouseCursors.basic] when the button is disabled.
///
/// To use a [MaterialStateMouseCursor], you should create a subclass of
/// [MaterialStateMouseCursor] and implement the abstract `resolve` method.
///
/// {@tool dartpad --template=stateless_widget_scaffold_center}
///
/// This example defines a mouse cursor that resolves to
/// [SystemMouseCursors.forbidden] when its widget is disabled.
///
/// ```dart imports
/// import 'package:flutter/rendering.dart';
/// ```
///
/// ```dart preamble
/// class ListTileCursor extends MaterialStateMouseCursor {
///   @override
///   MouseCursor resolve(Set<MaterialState> states) {
///     if (states.contains(MaterialState.disabled)) {
///       return SystemMouseCursors.forbidden;
///     }
///     return SystemMouseCursors.click;
///   }
///   @override
///   String get debugDescription => 'ListTileCursor()';
/// }
/// ```
///
/// ```dart
/// Widget build(BuildContext context) {
///   return ListTile(
///     title: Text('Disabled ListTile'),
///     enabled: false,
///     mouseCursor: ListTileCursor(),
///   );
/// }
/// ```
/// {@end-tool}
///
/// This class should only be used for parameters which are documented to take
/// [MaterialStateMouseCursor], otherwise only the default state will be used.
///
/// See also:
///
///  * [MouseCursor] for introduction on the mouse cursor system.
///  * [SystemMouseCursors], which defines cursors that are supported by
///    native platforms.
abstract class MaterialStateMouseCursor extends MouseCursor implements MaterialStateProperty<MouseCursor> {
  /// Creates a [MaterialStateMouseCursor].
  const MaterialStateMouseCursor();

  @protected
  @override
  MouseCursorSession createSession(int device) {
    return resolve(<MaterialState>{}).createSession(device);
  }

  /// Returns a [MouseCursor] that's to be used when a Material component is in
  /// the specified state.
  ///
  /// This method should never return null.
  @override
  MouseCursor resolve(Set<MaterialState> states);

  /// A mouse cursor for clickable material widgets, which resolves differently
  /// when the widget is disabled.
  ///
  /// By default this cursor resolves to [SystemMouseCursors.click]. If the widget is
  /// disabled, the cursor resolves to [SystemMouseCursors.basic].
  ///
  /// This cursor is the default for many Material widgets.
  static const MaterialStateMouseCursor clickable = _EnabledAndDisabledMouseCursor(
    enabledCursor: SystemMouseCursors.click,
    disabledCursor: SystemMouseCursors.basic,
    name: 'clickable',
  );

  /// A mouse cursor for material widgets related to text, which resolves differently
  /// when the widget is disabled.
  ///
  /// By default this cursor resolves to [SystemMouseCursors.text]. If the widget is
  /// disabled, the cursor resolves to [SystemMouseCursors.basic].
  ///
  /// This cursor is the default for many Material widgets.
  static const MaterialStateMouseCursor textable = _EnabledAndDisabledMouseCursor(
    enabledCursor: SystemMouseCursors.text,
    disabledCursor: SystemMouseCursors.basic,
    name: 'textable',
  );
}

class _EnabledAndDisabledMouseCursor extends MaterialStateMouseCursor {
  const _EnabledAndDisabledMouseCursor({
    this.enabledCursor,
    this.disabledCursor,
    this.name,
  });

  final MouseCursor enabledCursor;
  final MouseCursor disabledCursor;
  final String name;

  @override
  MouseCursor resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.disabled)) {
      return disabledCursor;
    }
    return enabledCursor;
  }

  @override
  String get debugDescription => 'MaterialStateMouseCursor($name)';
}

/// Interface for classes that [resolve] to a value of type `T` based
/// on a widget's interactive "state", which is defined as a set
/// of [MaterialState]s.
///
/// Material state properties represent values that depend on a widget's material
/// "state".  The state is encoded as a set of [MaterialState] values, like
/// [MaterialState.focused], [MaterialState.hovered], [MaterialState.pressed].  For
/// example the [InkWell.overlayColor] defines the color that fills the ink well
/// when it's pressed (the "splash color"), focused, or hovered. The [InkWell]
/// uses the overlay color's [resolve] method to compute the color for the
/// ink well's current state.
///
/// [ButtonStyle], which is used to configure the appearance of
/// buttons like [TextButton], [ElevatedButton], and [OutlinedButton],
/// has many material state properties.  The button widgets keep track
/// of their current material state and [resolve] the button style's
/// material state properties when their value is needed.
///
/// {@tool dartpad --template=stateless_widget_scaffold_center}
///
/// This example shows how you can override the default text and icon
/// color (the "foreground color") of a [TextButton] with a
/// [MaterialStateProperty]. In this example, the button's text color
/// will be `Colors.blue` when the button is being pressed, hovered,
/// or focused. Otherwise, the text color will be `Colors.red`.
///
/// ```dart
/// Widget build(BuildContext context) {
///   Color getColor(Set<MaterialState> states) {
///     const Set<MaterialState> interactiveStates = <MaterialState>{
///       MaterialState.pressed,
///       MaterialState.hovered,
///       MaterialState.focused,
///     };
///     if (states.any(interactiveStates.contains)) {
///       return Colors.blue;
///     }
///     return Colors.red;
///   }
///   return TextButton(
///     style: ButtonStyle(
///       foregroundColor: MaterialStateProperty.resolveWith(getColor),
///     ),
///     onPressed: () {},
///     child: Text('TextButton'),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [MaterialStateColor], a [Color] that implements `MaterialStateProperty`
///    which is used in APIs that need to accept either a [Color] or a
///    `MaterialStateProperty<Color>`.
///  * [MaterialStateMouseCursor], a [MouseCursor] that implements `MaterialStateProperty`.
///    which is used in APIs that need to accept either a [MouseCursor] or a
///    [MaterialStateProperty<MouseCursor>].
abstract class MaterialStateProperty<T> {

  /// Returns a value of type `T` that depends on [states].
  ///
  /// Widgets like [TextButton] and [ElevatedButton] apply this method to their
  /// current [MaterialState]s to compute colors and other visual parameters
  /// at build time.
  T resolve(Set<MaterialState> states);

  /// Resolves the value for the given set of states if `value` is a
  /// [MaterialStateProperty], otherwise returns the value itself.
  ///
  /// This is useful for widgets that have parameters which can optionally be a
  /// [MaterialStateProperty]. For example, [InkWell.mouseCursor] can be a
  /// [MouseCursor] or a [MaterialStateProperty<MouseCursor>].
  static T resolveAs<T>(T value, Set<MaterialState> states) {
    if (value is MaterialStateProperty<T>) {
      final MaterialStateProperty<T> property = value;
      return property.resolve(states);
    }
    return value;
  }

  /// Convenience method for creating a [MaterialStateProperty] from a
  /// [MaterialPropertyResolver] function alone.
  static MaterialStateProperty<T> resolveWith<T>(MaterialPropertyResolver<T> callback) => _MaterialStatePropertyWith<T>(callback);

  /// Convenience method for creating a [MaterialStateProperty] that resolves
  /// to a single value for all states.
  static MaterialStateProperty<T> all<T>(T value) => _MaterialStatePropertyAll<T>(value);
}

class _MaterialStatePropertyWith<T> implements MaterialStateProperty<T> {
  _MaterialStatePropertyWith(this._resolve);

  final MaterialPropertyResolver<T> _resolve;

  @override
  T resolve(Set<MaterialState> states) => _resolve(states);
}

class _MaterialStatePropertyAll<T> implements MaterialStateProperty<T> {
  _MaterialStatePropertyAll(this.value);

  final T value;

  @override
  T resolve(Set<MaterialState> states) => value;

  @override
  String toString() => 'MaterialStateProperty.all($value)';
}

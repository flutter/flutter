// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color;

/// Interactive states that some of the Material widgets can take on when
/// receiving input from the user.
///
/// States are defined by https://material.io/design/interaction/states.html#usage.
///
/// Some Material widgets track their current state in a `Set<MaterialState>`.
///
/// See also:
///
///  * [MaterialStateColor], a color that has a `resolve` method that can
///    return a different color depending on the state of the widget that it
///    is used in.
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

/// Defines a [Color] whose value depends on a set of [MaterialState]s which
/// represent the interactive state of a component.
///
/// This is useful for improving the accessibility of text in different states
/// of a component. For example, in a [FlatButton] with blue text, the text will
/// become more difficult to read when the button is hovered, focused, or pressed,
/// because the contrast ratio between the button and the text will decrease. To
/// solve this, you can use [MaterialStateColor] to make the text darker when the
/// [FlatButton] is hovered, focused, or pressed.
///
/// To use a [MaterialStateColor], you can either:
///   1. Create a subclass of [MaterialStateColor] and implement the abstract `resolve` method.
///   2. Use [MaterialStateColor.resolveWith] and pass in a callback that
///      will be used to resolve the color in the given states.
///
/// This should only be used as parameters when they are documented to take
/// [MaterialStateColor], otherwise only the default state will be used.
///
/// {@tool snippet}
///
/// This example shows how you could pass a `MaterialStateColor` to `FlatButton.textColor`.
/// Here, the text color will be `Colors.blue[900]` when the button is being
/// pressed, hovered, or focused. Otherwise, the text color will be `Colors.blue[600]`.
///
/// ```dart
/// Color getTextColor(Set<MaterialState> states) {
///   const Set<MaterialState> interactiveStates = <MaterialState>{
///     MaterialState.pressed,
///     MaterialState.hovered,
///     MaterialState.focused,
///   };
///   if (states.any(interactiveStates.contains)) {
///     return Colors.blue[900];
///   }
///   return Colors.blue[600];
/// }
///
/// FlatButton(
///   child: Text('FlatButton'),
///   onPressed: () {},
///   textColor: MaterialStateColor.resolveWith(getTextColor),
/// ),
/// ```
/// {@end-tool}
abstract class MaterialStateColor extends Color implements MaterialStateProperty<Color> {
  /// Creates a [MaterialStateColor].
  ///
  /// If you want a `const` [MaterialStateColor], you'll need to extend
  /// [MaterialStateColor] and override the [resolve] method. You'll also need
  /// to provide a `defaultValue` to the super constructor, so that we can know
  /// at compile-time what the value of the default [Color] is.
  ///
  /// {@tool snippet}
  ///
  /// In this next example, we see how you can create a `MaterialStateColor` by
  /// extending the abstract class and overriding the `resolve` method.
  ///
  /// ```dart
  /// class TextColor extends MaterialStateColor {
  ///   static const int _defaultColor = 0xcafefeed;
  ///   static const int _pressedColor = 0xdeadbeef;
  ///
  ///   const TextColor() : super(_defaultColor);
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

/// Interface for classes that can return a value of type `T` based on a set of
/// [MaterialState]s.
///
/// For example, [MaterialStateColor] implements `MaterialStateProperty<Color>`
/// because it has a `resolve` method that returns a different [Color] depending
/// on the given set of [MaterialState]s.
abstract class MaterialStateProperty<T> {

  /// Returns a different value of type `T` depending on the given `states`.
  ///
  /// Some widgets (such as [RawMaterialButton]) keep track of their set of
  /// [MaterialState]s, and will call `resolve` with the current states at build
  /// time for specified properties (such as [RawMaterialButton.textStyle]'s color).
  T resolve(Set<MaterialState> states);

  /// Returns the value resolved in the given set of states if `value` is a
  /// [MaterialStateProperty], otherwise returns the value itself.
  ///
  /// This is useful for widgets that have parameters which can optionally be a
  /// [MaterialStateProperty]. For example, [RaisedButton.textColor] can be a
  /// [Color] or a [MaterialStateProperty<Color>].
  static T resolveAs<T>(T value, Set<MaterialState> states) {
    if (value is MaterialStateProperty<T>) {
      final MaterialStateProperty<T> property = value;
      return property.resolve(states);
    }
    return value;
  }

  /// Convenience method for creating a [MaterialStateProperty] from a
  /// [MaterialPropertyResolver] function alone.
  static MaterialStateProperty<T> resolveWith<T>(MaterialPropertyResolver<T> callback) => _MaterialStateProperty<T>(callback);
}

class _MaterialStateProperty<T> implements MaterialStateProperty<T> {
  _MaterialStateProperty(this._resolve);

  final MaterialPropertyResolver<T> _resolve;

  @override
  T resolve(Set<MaterialState> states) => _resolve(states);
}

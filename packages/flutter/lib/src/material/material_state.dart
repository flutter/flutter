// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'input_border.dart';

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
/// {@template flutter.material.MaterialStateProperty.implementations}
///  * [MaterialStateColor], a [Color] that implements `MaterialStateProperty`
///    which is used in APIs that need to accept either a [Color] or a
///    `MaterialStateProperty<Color>`.
///  * [MaterialStateMouseCursor], a [MouseCursor] that implements
///    `MaterialStateProperty` which is used in APIs that need to accept either
///    a [MouseCursor] or a [MaterialStateProperty<MouseCursor>].
///  * [MaterialStateOutlinedBorder], an [OutlinedBorder] that implements
///    `MaterialStateProperty` which is used in APIs that need to accept either
///    an [OutlinedBorder] or a [MaterialStateProperty<OutlinedBorder>].
///  * [MaterialStateOutlineInputBorder], an [OutlineInputBorder] that implements
///    `MaterialStateProperty` which is used in APIs that need to accept either
///    an [OutlineInputBorder] or a [MaterialStateProperty<OutlineInputBorder>].
///  * [MaterialStateUnderlineInputBorder], an [UnderlineInputBorder] that implements
///    `MaterialStateProperty` which is used in APIs that need to accept either
///    an [UnderlineInputBorder] or a [MaterialStateProperty<UnderlineInputBorder>].
///  * [MaterialStateBorderSide], a [BorderSide] that implements
///    `MaterialStateProperty` which is used in APIs that need to accept either
///    a [BorderSide] or a [MaterialStateProperty<BorderSide>].
///  * [MaterialStateTextStyle], a [TextStyle] that implements
///    `MaterialStateProperty` which is used in APIs that need to accept either
///    a [TextStyle] or a [MaterialStateProperty<TextStyle>].
/// {@endtemplate}
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

  /// The state when this widget overlaps the content of a scrollable below.
  ///
  /// Used by [AppBar] to indicate that the primary scrollable's
  /// content has scrolled up and behind the app bar.
  scrolledUnder,

  /// The state when this widget is disabled and cannot be interacted with.
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
/// [MaterialStateColor] should only be used with widgets that document
/// their support, like [TimePickerThemeData.dayPeriodColor].
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
///   const MyColor() : super(_defaultColor);
///
///   static const int _defaultColor = 0xcafefeed;
///   static const int _pressedColor = 0xdeadbeef;
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
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const MaterialStateColor(super.defaultValue);

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
/// {@tool dartpad}
/// This example defines a mouse cursor that resolves to
/// [SystemMouseCursors.forbidden] when its widget is disabled.
///
/// ** See code in examples/api/lib/material/material_state/material_state_mouse_cursor.0.dart **
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
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
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
    required this.enabledCursor,
    required this.disabledCursor,
    required this.name,
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

/// Defines a [BorderSide] whose value depends on a set of [MaterialState]s
/// which represent the interactive state of a component.
///
/// To use a [MaterialStateBorderSide], you should create a subclass of a
/// [MaterialStateBorderSide] and override the abstract `resolve` method.
///
/// This class enables existing widget implementations with [BorderSide]
/// properties to be extended to also effectively support `MaterialStateProperty<BorderSide>`
/// property values. [MaterialStateBorderSide] should only be used with widgets that document
/// their support, like [ActionChip.side].
///
/// {@tool dartpad}
/// This example defines a subclass of [MaterialStateBorderSide], that resolves
/// to a red border side when its widget is selected.
///
/// ** See code in examples/api/lib/material/material_state/material_state_border_side.0.dart **
/// {@end-tool}
///
/// This class should only be used for parameters which are documented to take
/// [MaterialStateBorderSide], otherwise only the default state will be used.
abstract class MaterialStateBorderSide extends BorderSide implements MaterialStateProperty<BorderSide?> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const MaterialStateBorderSide();

  /// Returns a [BorderSide] that's to be used when a Material component is
  /// in the specified state. Return null to defer to the default value of the
  /// widget or theme.
  @override
  BorderSide? resolve(Set<MaterialState> states);

  /// Creates a [MaterialStateBorderSide] from a
  /// [MaterialPropertyResolver<BorderSide?>] callback function.
  ///
  /// If used as a regular [BorderSide], the border resolved in the default state
  /// (the empty set of states) will be used.
  ///
  /// Usage:
  /// ```dart
  /// ChipTheme(
  ///   data: Theme.of(context).chipTheme.copyWith(
  ///     side: MaterialStateBorderSide.resolveWith((Set<MaterialState> states) {
  ///       if (states.contains(MaterialState.selected)) {
  ///         return const BorderSide(width: 1, color: Colors.red);
  ///       }
  ///       return null;  // Defer to default value on the theme or widget.
  ///     }),
  ///   ),
  ///   child: Chip(),
  /// )
  ///
  /// // OR
  ///
  /// Chip(
  ///   ...
  ///   side: MaterialStateBorderSide.resolveWith((Set<MaterialState> states) {
  ///     if (states.contains(MaterialState.selected)) {
  ///       return const BorderSide(width: 1, color: Colors.red);
  ///     }
  ///     return null;  // Defer to default value on the theme or widget.
  ///   }),
  /// )
  /// ```
  static MaterialStateBorderSide resolveWith(MaterialPropertyResolver<BorderSide?> callback) =>
      _MaterialStateBorderSide(callback);
}

/// A [MaterialStateBorderSide] created from a
/// [MaterialPropertyResolver<BorderSide>] callback alone.
///
/// If used as a regular side, the side resolved in the default state will
/// be used.
///
/// Used by [MaterialStateBorderSide.resolveWith].
class _MaterialStateBorderSide extends MaterialStateBorderSide {
  const _MaterialStateBorderSide(this._resolve);

  final MaterialPropertyResolver<BorderSide?> _resolve;

  @override
  BorderSide? resolve(Set<MaterialState> states) {
    return _resolve(states);
  }
}

/// Defines an [OutlinedBorder] whose value depends on a set of [MaterialState]s
/// which represent the interactive state of a component.
///
/// To use a [MaterialStateOutlinedBorder], you should create a subclass of an
/// [OutlinedBorder] and implement [MaterialStateOutlinedBorder]'s abstract
/// `resolve` method.
///
/// {@tool dartpad}
/// This example defines a subclass of [RoundedRectangleBorder] and an
/// implementation of [MaterialStateOutlinedBorder], that resolves to
/// [RoundedRectangleBorder] when its widget is selected.
///
/// ** See code in examples/api/lib/material/material_state/material_state_outlined_border.0.dart **
/// {@end-tool}
///
/// This class should only be used for parameters which are documented to take
/// [MaterialStateOutlinedBorder], otherwise only the default state will be used.
///
/// See also:
///
///  * [ShapeBorder] the base class for shape outlines.
abstract class MaterialStateOutlinedBorder extends OutlinedBorder implements MaterialStateProperty<OutlinedBorder?> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const MaterialStateOutlinedBorder();

  /// Returns an [OutlinedBorder] that's to be used when a Material component is
  /// in the specified state. Return null to defer to the default value of the
  /// widget or theme.
  @override
  OutlinedBorder? resolve(Set<MaterialState> states);
}


/// Defines a [TextStyle] that is also a [MaterialStateProperty].
///
/// This class exists to enable widgets with [TextStyle] valued properties
/// to also accept [MaterialStateProperty<TextStyle>] values. A material
/// state text style property represents a text style which depends on
/// a widget's "interactive state". This state is represented as a
/// [Set] of [MaterialState]s, like [MaterialState.pressed],
/// [MaterialState.focused] and [MaterialState.hovered].
///
/// [MaterialStateTextStyle] should only be used with widgets that document
/// their support, like [InputDecoration.labelStyle].
///
/// To use a [MaterialStateTextStyle], you can either:
///   1. Create a subclass of [MaterialStateTextStyle] and implement the abstract `resolve` method.
///   2. Use [MaterialStateTextStyle.resolveWith] and pass in a callback that
///      will be used to resolve the color in the given states.
///
/// If a [MaterialStateTextStyle] is used for a property or a parameter that doesn't
/// support resolving [MaterialStateProperty<TextStyle>]s, then its default color
/// value will be used for all states.
///
/// To define a `const` [MaterialStateTextStyle], you'll need to extend
/// [MaterialStateTextStyle] and override its [resolve] method. You'll also need
/// to provide a `defaultValue` to the super constructor, so that we can know
/// at compile-time what its default color is.
abstract class MaterialStateTextStyle extends TextStyle implements MaterialStateProperty<TextStyle> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const MaterialStateTextStyle();

  /// Creates a [MaterialStateTextStyle] from a [MaterialPropertyResolver<TextStyle>]
  /// callback function.
  ///
  /// If used as a regular text style, the style resolved in the default state (the
  /// empty set of states) will be used.
  ///
  /// The given callback parameter must return a non-null text style in the default
  /// state.
  static MaterialStateTextStyle resolveWith(MaterialPropertyResolver<TextStyle> callback) =>
      _MaterialStateTextStyle(callback);

  /// Returns a [TextStyle] that's to be used when a Material component is in the
  /// specified state.
  @override
  TextStyle resolve(Set<MaterialState> states);
}

/// A [MaterialStateTextStyle] created from a [MaterialPropertyResolver<TextStyle>]
/// callback alone.
///
/// If used as a regular text style, the style resolved in the default state will
/// be used.
///
/// Used by [MaterialStateTextStyle.resolveWith].
class _MaterialStateTextStyle extends MaterialStateTextStyle {
  const _MaterialStateTextStyle(this._resolve);

  final MaterialPropertyResolver<TextStyle> _resolve;

  @override
  TextStyle resolve(Set<MaterialState> states) => _resolve(states);
}

/// Defines a [OutlineInputBorder] that is also a [MaterialStateProperty].
///
/// This class exists to enable widgets with [OutlineInputBorder] valued properties
/// to also accept [MaterialStateProperty<OutlineInputBorder>] values. A material
/// state input border property represents a text style which depends on
/// a widget's "interactive state". This state is represented as a
/// [Set] of [MaterialState]s, like [MaterialState.pressed],
/// [MaterialState.focused] and [MaterialState.hovered].
///
/// [MaterialStateOutlineInputBorder] should only be used with widgets that document
/// their support, like [InputDecoration.border].
///
/// To use a [MaterialStateOutlineInputBorder], you can either:
///   1. Create a subclass of [MaterialStateOutlineInputBorder] and implement the abstract `resolve` method.
///   2. Use [MaterialStateOutlineInputBorder.resolveWith] and pass in a callback that
///      will be used to resolve the color in the given states.
///
/// If a [MaterialStateOutlineInputBorder] is used for a property or a parameter that doesn't
/// support resolving [MaterialStateProperty<OutlineInputBorder>]s, then its default color
/// value will be used for all states.
///
/// To define a `const` [MaterialStateOutlineInputBorder], you'll need to extend
/// [MaterialStateOutlineInputBorder] and override its [resolve] method. You'll also need
/// to provide a `defaultValue` to the super constructor, so that we can know
/// at compile-time what its default color is.
abstract class MaterialStateOutlineInputBorder extends OutlineInputBorder implements MaterialStateProperty<InputBorder> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const MaterialStateOutlineInputBorder();

  /// Creates a [MaterialStateOutlineInputBorder] from a [MaterialPropertyResolver<InputBorder>]
  /// callback function.
  ///
  /// If used as a regular input border, the border resolved in the default state (the
  /// empty set of states) will be used.
  ///
  /// The given callback parameter must return a non-null text style in the default
  /// state.
  static MaterialStateOutlineInputBorder resolveWith(MaterialPropertyResolver<InputBorder> callback) =>
      _MaterialStateOutlineInputBorder(callback);

  /// Returns a [InputBorder] that's to be used when a Material component is in the
  /// specified state.
  @override
  InputBorder resolve(Set<MaterialState> states);
}

/// A [MaterialStateOutlineInputBorder] created from a [MaterialPropertyResolver<OutlineInputBorder>]
/// callback alone.
///
/// If used as a regular input border, the border resolved in the default state will
/// be used.
///
/// Used by [MaterialStateTextStyle.resolveWith].
class _MaterialStateOutlineInputBorder extends MaterialStateOutlineInputBorder {
  const _MaterialStateOutlineInputBorder(this._resolve);

  final MaterialPropertyResolver<InputBorder> _resolve;

  @override
  InputBorder resolve(Set<MaterialState> states) => _resolve(states);
}

/// Defines a [UnderlineInputBorder] that is also a [MaterialStateProperty].
///
/// This class exists to enable widgets with [UnderlineInputBorder] valued properties
/// to also accept [MaterialStateProperty<UnderlineInputBorder>] values. A material
/// state input border property represents a text style which depends on
/// a widget's "interactive state". This state is represented as a
/// [Set] of [MaterialState]s, like [MaterialState.pressed],
/// [MaterialState.focused] and [MaterialState.hovered].
///
/// [MaterialStateUnderlineInputBorder] should only be used with widgets that document
/// their support, like [InputDecoration.border].
///
/// To use a [MaterialStateUnderlineInputBorder], you can either:
///   1. Create a subclass of [MaterialStateUnderlineInputBorder] and implement the abstract `resolve` method.
///   2. Use [MaterialStateUnderlineInputBorder.resolveWith] and pass in a callback that
///      will be used to resolve the color in the given states.
///
/// If a [MaterialStateUnderlineInputBorder] is used for a property or a parameter that doesn't
/// support resolving [MaterialStateProperty<UnderlineInputBorder>]s, then its default color
/// value will be used for all states.
///
/// To define a `const` [MaterialStateUnderlineInputBorder], you'll need to extend
/// [MaterialStateUnderlineInputBorder] and override its [resolve] method. You'll also need
/// to provide a `defaultValue` to the super constructor, so that we can know
/// at compile-time what its default color is.
abstract class MaterialStateUnderlineInputBorder extends UnderlineInputBorder implements MaterialStateProperty<InputBorder> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const MaterialStateUnderlineInputBorder();

  /// Creates a [MaterialStateUnderlineInputBorder] from a [MaterialPropertyResolver<InputBorder>]
  /// callback function.
  ///
  /// If used as a regular input border, the border resolved in the default state (the
  /// empty set of states) will be used.
  ///
  /// The given callback parameter must return a non-null text style in the default
  /// state.
  static MaterialStateUnderlineInputBorder resolveWith(MaterialPropertyResolver<InputBorder> callback) =>
      _MaterialStateUnderlineInputBorder(callback);

  /// Returns a [InputBorder] that's to be used when a Material component is in the
  /// specified state.
  @override
  InputBorder resolve(Set<MaterialState> states);
}

/// A [MaterialStateUnderlineInputBorder] created from a [MaterialPropertyResolver<UnderlineInputBorder>]
/// callback alone.
///
/// If used as a regular input border, the border resolved in the default state will
/// be used.
///
/// Used by [MaterialStateTextStyle.resolveWith].
class _MaterialStateUnderlineInputBorder extends MaterialStateUnderlineInputBorder {
  const _MaterialStateUnderlineInputBorder(this._resolve);

  final MaterialPropertyResolver<InputBorder> _resolve;

  @override
  InputBorder resolve(Set<MaterialState> states) => _resolve(states);
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
/// {@tool dartpad}
/// This example shows how you can override the default text and icon
/// color (the "foreground color") of a [TextButton] with a
/// [MaterialStateProperty]. In this example, the button's text color
/// will be `Colors.blue` when the button is being pressed, hovered,
/// or focused. Otherwise, the text color will be `Colors.red`.
///
/// ** See code in examples/api/lib/material/material_state/material_state_property.0.dart **
/// {@end-tool}
///
/// See also:
///
/// {@macro flutter.material.MaterialStateProperty.implementations}
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
  ///
  /// If you need a const value, use [MaterialStatePropertyAll] directly.
  ///
  // TODO(darrenaustin): Deprecate this when we have the ability to create
  // a dart fix that will replace this with MaterialStatePropertyAll:
  // https://github.com/dart-lang/sdk/issues/49056.
  static MaterialStateProperty<T> all<T>(T value) => MaterialStatePropertyAll<T>(value);

  /// Linearly interpolate between two [MaterialStateProperty]s.
  static MaterialStateProperty<T?>? lerp<T>(
    MaterialStateProperty<T>? a,
    MaterialStateProperty<T>? b,
    double t,
    T? Function(T?, T?, double) lerpFunction,
  ) {
    // Avoid creating a _LerpProperties object for a common case.
    if (a == null && b == null) {
      return null;
    }
    return _LerpProperties<T>(a, b, t, lerpFunction);
  }
}

class _LerpProperties<T> implements MaterialStateProperty<T?> {
  const _LerpProperties(this.a, this.b, this.t, this.lerpFunction);

  final MaterialStateProperty<T>? a;
  final MaterialStateProperty<T>? b;
  final double t;
  final T? Function(T?, T?, double) lerpFunction;

  @override
  T? resolve(Set<MaterialState> states) {
    final T? resolvedA = a?.resolve(states);
    final T? resolvedB = b?.resolve(states);
    return lerpFunction(resolvedA, resolvedB, t);
  }
}

class _MaterialStatePropertyWith<T> implements MaterialStateProperty<T> {
  _MaterialStatePropertyWith(this._resolve);

  final MaterialPropertyResolver<T> _resolve;

  @override
  T resolve(Set<MaterialState> states) => _resolve(states);
}

/// Convenience class for creating a [MaterialStateProperty] that
/// resolves to the given value for all states.
class MaterialStatePropertyAll<T> implements MaterialStateProperty<T> {

  /// Constructs a [MaterialStateProperty] that always resolves to the given
  /// value.
  const MaterialStatePropertyAll(this.value);

  /// The value of the property that will be used for all states.
  final T value;

  @override
  T resolve(Set<MaterialState> states) => value;

  @override
  String toString() => 'MaterialStatePropertyAll($value)';
}

/// Manages a set of [MaterialState]s and notifies listeners of changes.
///
/// Used by widgets that expose their internal state for the sake of
/// extensions that add support for additional states. See
/// [TextButton.statesController] for example.
///
/// The controller's [value] is its current set of states. Listeners
/// are notified whenever the [value] changes. The [value] should only be
/// changed with [update]; it should not be modified directly.
class MaterialStatesController extends ValueNotifier<Set<MaterialState>> {
  /// Creates a MaterialStatesController.
  MaterialStatesController([Set<MaterialState>? value]) : super(<MaterialState>{...?value});

  /// Adds [state] to [value] if [add] is true, and removes it otherwise,
  /// and notifies listeners if [value] has changed.
  void update(MaterialState state, bool add) {
    final bool valueChanged = add ? value.add(state) : value.remove(state);
    if (valueChanged) {
      notifyListeners();
    }
  }
}

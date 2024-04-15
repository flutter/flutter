// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// Examples can assume:
// late BuildContext context;

/// Interactive states that some of the widgets can take on when receiving input
/// from the user.
///
/// States are defined by https://material.io/design/interaction/states.html#usage,
/// but are not limited to the Material design system or library.
///
/// Some widgets track their current state in a `Set<WidgetState>`.
///
/// See also:
///
///  * [MaterialState], the Material specific version of `WidgetState`.
///  * [WidgetStateProperty], an interface for objects that "resolve" to
///    different values depending on a widget's state.
/// {@template flutter.widgets.WidgetStateProperty.implementations}
///  * [WidgetStateColor], a [Color] that implements `WidgetStateProperty`
///    which is used in APIs that need to accept either a [Color] or a
///    `WidgetStateProperty<Color>`.
///  * [WidgetStateMouseCursor], a [MouseCursor] that implements
///    `WidgetStateProperty` which is used in APIs that need to accept either
///    a [MouseCursor] or a [WidgetStateProperty<MouseCursor>].
///  * [WidgetStateOutlinedBorder], an [OutlinedBorder] that implements
///    `WidgetStateProperty` which is used in APIs that need to accept either
///    an [OutlinedBorder] or a [WidgetStateProperty<OutlinedBorder>].
///  * [WidgetStateBorderSide], a [BorderSide] that implements
///    `WidgetStateProperty` which is used in APIs that need to accept either
///    a [BorderSide] or a [WidgetStateProperty<BorderSide>].
///  * [WidgetStateTextStyle], a [TextStyle] that implements
///    `WidgetStateProperty` which is used in APIs that need to accept either
///    a [TextStyle] or a [WidgetStateProperty<TextStyle>].
/// {@endtemplate}
enum WidgetState {
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
typedef WidgetPropertyResolver<T> = T Function(Set<WidgetState> states);

/// Defines a [Color] that is also a [WidgetStateProperty].
///
/// This class exists to enable widgets with [Color] valued properties
/// to also accept [WidgetStateProperty<Color>] values. A widget
/// state color property represents a color which depends on
/// a widget's "interactive state". This state is represented as a
/// [Set] of [WidgetState]s, like [WidgetState.pressed],
/// [WidgetState.focused] and [WidgetState.hovered].
///
/// [WidgetStateColor] should only be used with widgets that document
/// their support, like [TimePickerThemeData.dayPeriodColor].
///
/// To use a [WidgetStateColor], you can either:
///   1. Create a subclass of [WidgetStateColor] and implement the abstract `resolve` method.
///   2. Use [WidgetStateColor.resolveWith] and pass in a callback that
///      will be used to resolve the color in the given states.
///
/// If a [WidgetStateColor] is used for a property or a parameter that doesn't
/// support resolving [WidgetStateProperty<Color>]s, then its default color
/// value will be used for all states.
///
/// To define a `const` [WidgetStateColor], you'll need to extend
/// [WidgetStateColor] and override its [resolve] method. You'll also need
/// to provide a `defaultValue` to the super constructor, so that we can know
/// at compile-time what its default color is.
///
/// {@tool snippet}
///
/// This example defines a [WidgetStateColor] with a const constructor.
///
/// ```dart
/// class MyColor extends WidgetStateColor {
///   const MyColor() : super(_defaultColor);
///
///   static const int _defaultColor = 0xcafefeed;
///   static const int _pressedColor = 0xdeadbeef;
///
///   @override
///   Color resolve(Set<WidgetState> states) {
///     if (states.contains(WidgetState.pressed)) {
///       return const Color(_pressedColor);
///     }
///     return const Color(_defaultColor);
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [MaterialStateColor], the Material specific version of `WidgetStateColor`.
abstract class WidgetStateColor extends Color implements WidgetStateProperty<Color> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const WidgetStateColor(super.defaultValue);

  /// Creates a [WidgetStateColor] from a [WidgetPropertyResolver<Color>]
  /// callback function.
  ///
  /// If used as a regular color, the color resolved in the default state (the
  /// empty set of states) will be used.
  ///
  /// The given callback parameter must return a non-null color in the default
  /// state.
  static WidgetStateColor resolveWith(WidgetPropertyResolver<Color> callback) => _WidgetStateColor(callback);

  /// Returns a [Color] that's to be used when a component is in the specified
  /// state.
  @override
  Color resolve(Set<WidgetState> states);

  /// A constant whose value is transparent for all states.
  static const WidgetStateColor transparent = _WidgetStateColorTransparent();
}

class _WidgetStateColor extends WidgetStateColor {
  _WidgetStateColor(this._resolve) : super(_resolve(_defaultStates).value);

  final WidgetPropertyResolver<Color> _resolve;

  static const Set<WidgetState> _defaultStates = <WidgetState>{};

  @override
  Color resolve(Set<WidgetState> states) => _resolve(states);
}

class _WidgetStateColorTransparent extends WidgetStateColor {
  const _WidgetStateColorTransparent() : super(0x00000000);

  @override
  Color resolve(Set<WidgetState> states) => const Color(0x00000000);
}

/// Defines a [MouseCursor] whose value depends on a set of [WidgetState]s which
/// represent the interactive state of a component.
///
/// This kind of [MouseCursor] is useful when the set of interactive
/// actions a widget supports varies with its state. For example, a
/// mouse pointer hovering over a disabled [ListTile] should not
/// display [SystemMouseCursors.click], since a disabled list tile
/// doesn't respond to mouse clicks. [ListTile]'s default mouse cursor
/// is a [WidgetStateMouseCursor.clickable], which resolves to
/// [SystemMouseCursors.basic] when the button is disabled.
///
/// To use a [WidgetStateMouseCursor], you should create a subclass of
/// [WidgetStateMouseCursor] and implement the abstract `resolve` method.
///
/// {@tool dartpad}
/// This example defines a mouse cursor that resolves to
/// [SystemMouseCursors.forbidden] when its widget is disabled.
///
/// ** See code in examples/api/lib/material/material_state/material_state_mouse_cursor.0.dart **
/// {@end-tool}
///
/// This class should only be used for parameters which are documented to take
/// [WidgetStateMouseCursor], otherwise only the default state will be used.
///
/// See also:
///
///  * [MaterialStateMouseCursor], the Material specific version of
///    `WidgetStateMouseCursor`.
///  * [MouseCursor] for introduction on the mouse cursor system.
///  * [SystemMouseCursors], which defines cursors that are supported by
///    native platforms.
abstract class WidgetStateMouseCursor extends MouseCursor implements WidgetStateProperty<MouseCursor> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const WidgetStateMouseCursor();

  @protected
  @override
  MouseCursorSession createSession(int device) {
    return resolve(<WidgetState>{}).createSession(device);
  }

  /// Returns a [MouseCursor] that's to be used when a component is in the
  /// specified state.
  @override
  MouseCursor resolve(Set<WidgetState> states);

  /// A mouse cursor for clickable widgets, which resolves differently when the
  /// widget is disabled.
  ///
  /// By default this cursor resolves to [SystemMouseCursors.click]. If the widget is
  /// disabled, the cursor resolves to [SystemMouseCursors.basic].
  ///
  /// This cursor is the default for many widgets.
  static const WidgetStateMouseCursor clickable = _EnabledAndDisabledMouseCursor(
    enabledCursor: SystemMouseCursors.click,
    disabledCursor: SystemMouseCursors.basic,
    name: 'clickable',
  );

  /// A mouse cursor for widgets related to text, which resolves differently
  /// when the widget is disabled.
  ///
  /// By default this cursor resolves to [SystemMouseCursors.text]. If the widget is
  /// disabled, the cursor resolves to [SystemMouseCursors.basic].
  ///
  /// This cursor is the default for many widgets.
  static const WidgetStateMouseCursor textable = _EnabledAndDisabledMouseCursor(
    enabledCursor: SystemMouseCursors.text,
    disabledCursor: SystemMouseCursors.basic,
    name: 'textable',
  );
}

class _EnabledAndDisabledMouseCursor extends WidgetStateMouseCursor {
  const _EnabledAndDisabledMouseCursor({
    required this.enabledCursor,
    required this.disabledCursor,
    required this.name,
  });

  final MouseCursor enabledCursor;
  final MouseCursor disabledCursor;
  final String name;

  @override
  MouseCursor resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return disabledCursor;
    }
    return enabledCursor;
  }

  @override
  String get debugDescription => 'WidgetStateMouseCursor($name)';
}

/// Defines a [BorderSide] whose value depends on a set of [WidgetState]s
/// which represent the interactive state of a component.
///
/// To use a [WidgetStateBorderSide], you should create a subclass of a
/// [WidgetStateBorderSide] and override the abstract `resolve` method.
///
/// This class enables existing widget implementations with [BorderSide]
/// properties to be extended to also effectively support `WidgetStateProperty<BorderSide>`
/// property values. [WidgetStateBorderSide] should only be used with widgets that document
/// their support, like [ActionChip.side].
///
/// This class should only be used for parameters which are documented to take
/// [WidgetStateBorderSide], otherwise only the default state will be used.
///
/// See also:
///
///  * [MaterialStateBorderSide], the Material specific version of
///    `WidgetStateBorderSide`.
abstract class WidgetStateBorderSide extends BorderSide implements WidgetStateProperty<BorderSide?> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const WidgetStateBorderSide();

  /// Creates a [WidgetStateBorderSide] from a
  /// [WidgetPropertyResolver<BorderSide?>] callback function.
  ///
  /// If used as a regular [BorderSide], the border resolved in the default state
  /// (the empty set of states) will be used.
  ///
  /// Usage:
  ///
  /// ```dart
  /// ChipTheme(
  ///   data: Theme.of(context).chipTheme.copyWith(
  ///     side: WidgetStateBorderSide.resolveWith((Set<WidgetState> states) {
  ///       if (states.contains(WidgetState.selected)) {
  ///         return const BorderSide(color: Colors.red);
  ///       }
  ///       return null;  // Defer to default value on the theme or widget.
  ///     }),
  ///   ),
  ///   child: const Chip(
  ///     label: Text('Transceiver'),
  ///   ),
  /// ),
  /// ```
  ///
  /// Alternatively:
  ///
  /// ```dart
  /// Chip(
  ///   label: const Text('Transceiver'),
  ///   side: WidgetStateBorderSide.resolveWith((Set<WidgetState> states) {
  ///     if (states.contains(WidgetState.selected)) {
  ///       return const BorderSide(color: Colors.red);
  ///     }
  ///     return null;  // Defer to default value on the theme or widget.
  ///   }),
  /// ),
  /// ```
  const factory WidgetStateBorderSide.resolveWith(WidgetPropertyResolver<BorderSide?> callback) = _WidgetStateBorderSide;

  /// Returns a [BorderSide] that's to be used when a Material component is
  /// in the specified state. Return null to defer to the default value of the
  /// widget or theme.
  @override
  BorderSide? resolve(Set<WidgetState> states);
}

class _WidgetStateBorderSide extends WidgetStateBorderSide {
  const _WidgetStateBorderSide(this._resolve);

  final WidgetPropertyResolver<BorderSide?> _resolve;

  @override
  BorderSide? resolve(Set<WidgetState> states) => _resolve(states);
}

/// Defines an [OutlinedBorder] whose value depends on a set of [WidgetState]s
/// which represent the interactive state of a component.
///
/// To use a [WidgetStateOutlinedBorder], you should create a subclass of an
/// [OutlinedBorder] and implement [WidgetStateOutlinedBorder]'s abstract
/// `resolve` method.
///
/// {@tool dartpad}
/// This example defines a subclass of [RoundedRectangleBorder] and an
/// implementation of [WidgetStateOutlinedBorder], that resolves to
/// [RoundedRectangleBorder] when its widget is selected.
///
/// ** See code in examples/api/lib/material/material_state/material_state_outlined_border.0.dart **
/// {@end-tool}
///
/// This class should only be used for parameters which are documented to take
/// [WidgetStateOutlinedBorder], otherwise only the default state will be used.
///
/// See also:
///
///  * [ShapeBorder] the base class for shape outlines.
///  * [MaterialStateOutlinedBorder], the Material specific version of
///    `WidgetStateOutlinedBorder`.
abstract class WidgetStateOutlinedBorder extends OutlinedBorder implements WidgetStateProperty<OutlinedBorder?> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const WidgetStateOutlinedBorder();

  /// Returns an [OutlinedBorder] that's to be used when a component is in the
  /// specified state. Return null to defer to the default value of the widget
  /// or theme.
  @override
  OutlinedBorder? resolve(Set<WidgetState> states);
}

/// Defines a [TextStyle] that is also a [WidgetStateProperty].
///
/// This class exists to enable widgets with [TextStyle] valued properties
/// to also accept [WidgetStateProperty<TextStyle>] values. A widget
/// state text style property represents a text style which depends on
/// a widget's "interactive state". This state is represented as a
/// [Set] of [WidgetState]s, like [WidgetState.pressed],
/// [WidgetState.focused] and [WidgetState.hovered].
///
/// [WidgetStateTextStyle] should only be used with widgets that document
/// their support, like [InputDecoration.labelStyle].
///
/// To use a [WidgetStateTextStyle], you can either:
///   1. Create a subclass of [WidgetStateTextStyle] and implement the abstract `resolve` method.
///   2. Use [WidgetStateTextStyle.resolveWith] and pass in a callback that
///      will be used to resolve the color in the given states.
///
/// If a [WidgetStateTextStyle] is used for a property or a parameter that doesn't
/// support resolving [WidgetStateProperty<TextStyle>]s, then its default color
/// value will be used for all states.
///
/// To define a `const` [WidgetStateTextStyle], you'll need to extend
/// [WidgetStateTextStyle] and override its [resolve] method. You'll also need
/// to provide a `defaultValue` to the super constructor, so that we can know
/// at compile-time what its default color is.
/// See also:
///
///  * [MaterialStateTextStyle], the Material specific version of
///    `WidgetStateTextStyle`.
abstract class WidgetStateTextStyle extends TextStyle implements WidgetStateProperty<TextStyle> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const WidgetStateTextStyle();

  /// Creates a [WidgetStateTextStyle] from a [WidgetPropertyResolver<TextStyle>]
  /// callback function.
  ///
  /// If used as a regular text style, the style resolved in the default state (the
  /// empty set of states) will be used.
  ///
  /// The given callback parameter must return a non-null text style in the default
  /// state.
  const factory WidgetStateTextStyle.resolveWith(WidgetPropertyResolver<TextStyle> callback) = _WidgetStateTextStyle;

  /// Returns a [TextStyle] that's to be used when a component is in the
  /// specified state.
  @override
  TextStyle resolve(Set<WidgetState> states);
}

class _WidgetStateTextStyle extends WidgetStateTextStyle {
  const _WidgetStateTextStyle(this._resolve);

  final WidgetPropertyResolver<TextStyle> _resolve;

  @override
  TextStyle resolve(Set<WidgetState> states) => _resolve(states);
}

/// Interface for classes that [resolve] to a value of type `T` based
/// on a widget's interactive "state", which is defined as a set
/// of [WidgetState]s.
///
/// Widget state properties represent values that depend on a widget's "state".
/// The state is encoded as a set of [WidgetState] values, like
/// [WidgetState.focused], [WidgetState.hovered], [WidgetState.pressed]. For
/// example the [InkWell.overlayColor] defines the color that fills the ink well
/// when it's pressed (the "splash color"), focused, or hovered. The [InkWell]
/// uses the overlay color's [resolve] method to compute the color for the
/// ink well's current state.
///
/// [ButtonStyle], which is used to configure the appearance of
/// buttons like [TextButton], [ElevatedButton], and [OutlinedButton],
/// has many material state properties. The button widgets keep track
/// of their current material state and [resolve] the button style's
/// material state properties when their value is needed.
///
/// See also:
///
///  * [MaterialStateProperty], the Material specific version of
///    `WidgetStateProperty`.
/// {@macro flutter.widgets.WidgetStateProperty.implementations}
abstract class WidgetStateProperty<T> {
  /// Returns a value of type `T` that depends on [states].
  ///
  /// Widgets like [TextButton] and [ElevatedButton] apply this method to their
  /// current [WidgetState]s to compute colors and other visual parameters
  /// at build time.
  T resolve(Set<WidgetState> states);

  /// Resolves the value for the given set of states if `value` is a
  /// [WidgetStateProperty], otherwise returns the value itself.
  ///
  /// This is useful for widgets that have parameters which can optionally be a
  /// [WidgetStateProperty]. For example, [InkWell.mouseCursor] can be a
  /// [MouseCursor] or a [WidgetStateProperty<MouseCursor>].
  static T resolveAs<T>(T value, Set<WidgetState> states) {
    if (value is WidgetStateProperty<T>) {
      final WidgetStateProperty<T> property = value;
      return property.resolve(states);
    }
    return value;
  }

  /// Convenience method for creating a [WidgetStateProperty] from a
  /// [WidgetPropertyResolver] function alone.
  static WidgetStateProperty<T> resolveWith<T>(WidgetPropertyResolver<T> callback) => _WidgetStatePropertyWith<T>(callback);

  /// Convenience method for creating a [WidgetStateProperty] that resolves
  /// to a single value for all states.
  ///
  /// If you need a const value, use [WidgetStatePropertyAll] directly.
  ///
  // TODO(darrenaustin): Deprecate this when we have the ability to create
  // a dart fix that will replace this with WidgetStatePropertyAll:
  // https://github.com/dart-lang/sdk/issues/49056.
  static WidgetStateProperty<T> all<T>(T value) => WidgetStatePropertyAll<T>(value);

  /// Linearly interpolate between two [WidgetStateProperty]s.
  static WidgetStateProperty<T?>? lerp<T>(
    WidgetStateProperty<T>? a,
    WidgetStateProperty<T>? b,
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

class _LerpProperties<T> implements WidgetStateProperty<T?> {
  const _LerpProperties(this.a, this.b, this.t, this.lerpFunction);

  final WidgetStateProperty<T>? a;
  final WidgetStateProperty<T>? b;
  final double t;
  final T? Function(T?, T?, double) lerpFunction;

  @override
  T? resolve(Set<WidgetState> states) {
    final T? resolvedA = a?.resolve(states);
    final T? resolvedB = b?.resolve(states);
    return lerpFunction(resolvedA, resolvedB, t);
  }
}

class _WidgetStatePropertyWith<T> implements WidgetStateProperty<T> {
  _WidgetStatePropertyWith(this._resolve);

  final WidgetPropertyResolver<T> _resolve;

  @override
  T resolve(Set<WidgetState> states) => _resolve(states);
}

/// Convenience class for creating a [WidgetStateProperty] that
/// resolves to the given value for all states.
///
/// See also:
///
///  * [MaterialStatePropertyAll], the Material specific version of
///    `WidgetStatePropertyAll`.
class WidgetStatePropertyAll<T> implements WidgetStateProperty<T> {

  /// Constructs a [WidgetStateProperty] that always resolves to the given
  /// value.
  const WidgetStatePropertyAll(this.value);

  /// The value of the property that will be used for all states.
  final T value;

  @override
  T resolve(Set<WidgetState> states) => value;

  @override
  String toString() {
    if (value is double) {
      return 'WidgetStatePropertyAll(${debugFormatDouble(value as double)})';
    } else {
      return 'WidgetStatePropertyAll($value)';
    }
  }
}

/// Manages a set of [WidgetState]s and notifies listeners of changes.
///
/// Used by widgets that expose their internal state for the sake of
/// extensions that add support for additional states. See
/// [TextButton] for an example.
///
/// The controller's [value] is its current set of states. Listeners
/// are notified whenever the [value] changes. The [value] should only be
/// changed with [update]; it should not be modified directly.
///
/// The controller's [value] represents the set of states that a
/// widget's visual properties, typically [WidgetStateProperty]
/// values, are resolved against. It is _not_ the intrinsic state of
/// the widget. The widget is responsible for ensuring that the
/// controller's [value] tracks its intrinsic state. For example one
/// cannot request the keyboard focus for a widget by adding
/// [WidgetState.focused] to its controller. When the widget gains the
/// or loses the focus it will [update] its controller's [value] and
/// notify listeners of the change.
///
/// When calling `setState` in a [MaterialStatesController] listener, use the
/// [SchedulerBinding.addPostFrameCallback] to delay the call to `setState` after
/// the frame has been rendered. It's generally prudent to use the
/// [SchedulerBinding.addPostFrameCallback] because some of the widgets that
/// depend on [MaterialStatesController] may call [update] in their build method.
/// In such cases, listener's that call `setState` - during the build phase - will cause
/// an error.
///
/// See also:
///
///  * [MaterialStatesController], the Material specific version of
///    `WidgetStatesController`.
class WidgetStatesController extends ValueNotifier<Set<WidgetState>> {
  /// Creates a WidgetStatesController.
  WidgetStatesController([Set<WidgetState>? value]) : super(<WidgetState>{...?value});

  /// Adds [state] to [value] if [add] is true, and removes it otherwise,
  /// and notifies listeners if [value] has changed.
  void update(WidgetState state, bool add) {
    final bool valueChanged = add ? value.add(state) : value.remove(state);
    if (valueChanged) {
      notifyListeners();
    }
  }
}

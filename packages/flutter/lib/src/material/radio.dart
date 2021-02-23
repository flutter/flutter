// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'debug.dart';
import 'material_state.dart';
import 'theme.dart';
import 'theme_data.dart';
import 'toggleable.dart';

const double _kOuterRadius = 8.0;
const double _kInnerRadius = 4.5;

/// A material design radio button.
///
/// Used to select between a number of mutually exclusive values. When one radio
/// button in a group is selected, the other radio buttons in the group cease to
/// be selected. The values are of type `T`, the type parameter of the [Radio]
/// class. Enums are commonly used for this purpose.
///
/// The radio button itself does not maintain any state. Instead, selecting the
/// radio invokes the [onChanged] callback, passing [value] as a parameter. If
/// [groupValue] and [value] match, this radio will be selected. Most widgets
/// will respond to [onChanged] by calling [State.setState] to update the
/// radio button's [groupValue].
///
/// {@tool dartpad --template=stateful_widget_scaffold_center}
///
/// Here is an example of Radio widgets wrapped in ListTiles, which is similar
/// to what you could get with the RadioListTile widget.
///
/// The currently selected character is passed into `groupValue`, which is
/// maintained by the example's `State`. In this case, the first `Radio`
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
/// ```dart preamble
/// enum SingingCharacter { lafayette, jefferson }
/// ```
///
/// ```dart
/// SingingCharacter? _character = SingingCharacter.lafayette;
///
/// Widget build(BuildContext context) {
///   return Column(
///     children: <Widget>[
///       ListTile(
///         title: const Text('Lafayette'),
///         leading: Radio(
///           value: SingingCharacter.lafayette,
///           groupValue: _character,
///           onChanged: (SingingCharacter? value) {
///             setState(() { _character = value; });
///           },
///         ),
///       ),
///       ListTile(
///         title: const Text('Thomas Jefferson'),
///         leading: Radio(
///           value: SingingCharacter.jefferson,
///           groupValue: _character,
///           onChanged: (SingingCharacter? value) {
///             setState(() { _character = value; });
///           },
///         ),
///       ),
///     ],
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [RadioListTile], which combines this widget with a [ListTile] so that
///    you can give the radio button a label.
///  * [Slider], for selecting a value in a range.
///  * [Checkbox] and [Switch], for toggling a particular value on or off.
///  * <https://material.io/design/components/selection-controls.html#radio-buttons>
class Radio<T> extends StatelessWidget {
  /// Creates a material design radio button.
  ///
  /// The radio button itself does not maintain any state. Instead, when the
  /// radio button is selected, the widget calls the [onChanged] callback. Most
  /// widgets that use a radio button will listen for the [onChanged] callback
  /// and rebuild the radio button with a new [groupValue] to update the visual
  /// appearance of the radio button.
  ///
  /// The following arguments are required:
  ///
  /// * [value] and [groupValue] together determine whether the radio button is
  ///   selected.
  /// * [onChanged] is called when the user selects this radio button.
  const Radio({
    Key? key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
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
  }) : assert(autofocus != null),
       assert(toggleable != null),
       super(key: key);

  /// The value represented by this radio button.
  final T value;

  /// The currently selected value for a group of radio buttons.
  ///
  /// This radio button is considered selected if its [value] matches the
  /// [groupValue].
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
  ///   onChanged: (SingingCharacter newValue) {
  ///     setState(() {
  ///       _character = newValue;
  ///     });
  ///   },
  /// )
  /// ```
  final ValueChanged<T?>? onChanged;

  /// {@template flutter.material.radio.mouseCursor}
  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// If [mouseCursor] is a [MaterialStateProperty<MouseCursor>],
  /// [MaterialStateProperty.resolve] is used for the following [MaterialState]s:
  ///
  ///  * [MaterialState.selected].
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  ///  * [MaterialState.disabled].
  /// {@endtemplate}
  ///
  /// If null, then the value of [RadioThemeData.mouseCursor] is used.
  /// If that is also null, then [MaterialStateMouseCursor.clickable] is used.
  ///
  /// See also:
  ///
  ///  * [MaterialStateMouseCursor], a [MouseCursor] that implements
  ///    `MaterialStateProperty` which is used in APIs that need to accept
  ///    either a [MouseCursor] or a [MaterialStateProperty<MouseCursor>].
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
  /// {@tool dartpad --template=stateful_widget_scaffold}
  /// This example shows how to enable deselecting a radio button by setting the
  /// [toggleable] attribute.
  ///
  /// ```dart
  /// int? groupValue;
  /// static const List<String> selections = <String>[
  ///   'Hercules Mulligan',
  ///   'Eliza Hamilton',
  ///   'Philip Schuyler',
  ///   'Maria Reynolds',
  ///   'Samuel Seabury',
  /// ];
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///   return Scaffold(
  ///     body: ListView.builder(
  ///       itemBuilder: (context, index) {
  ///         return Row(
  ///           mainAxisSize: MainAxisSize.min,
  ///           crossAxisAlignment: CrossAxisAlignment.center,
  ///           children: <Widget>[
  ///             Radio<int>(
  ///                 value: index,
  ///                 groupValue: groupValue,
  ///                 // TRY THIS: Try setting the toggleable value to false and
  ///                 // see how that changes the behavior of the widget.
  ///                 toggleable: true,
  ///                 onChanged: (int? value) {
  ///                   setState(() {
  ///                     groupValue = value;
  ///                   });
  ///                 }),
  ///             Text(selections[index]),
  ///           ],
  ///         );
  ///       },
  ///       itemCount: selections.length,
  ///     ),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  final bool toggleable;

  /// The color to use when this radio button is selected.
  ///
  /// Defaults to [ThemeData.toggleableActiveColor].
  ///
  /// If [fillColor] returns a non-null color in the [MaterialState.selected]
  /// state, it will be used instead of this color.
  final Color? activeColor;

  /// {@template flutter.material.radio.fillColor}
  /// The color that fills the radio button, in all [MaterialState]s.
  ///
  /// Resolves in the following states:
  ///  * [MaterialState.selected].
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  ///  * [MaterialState.disabled].
  /// {@endtemplate}
  ///
  /// If null, then the value of [activeColor] is used in the selected state. If
  /// that is also null, then the value of [RadioThemeData.fillColor] is used.
  /// If that is also null, then [ThemeData.disabledColor] is used in
  /// the disabled state, [ThemeData.toggleableActiveColor] is used in the
  /// selected state, and [ThemeData.unselectedWidgetColor] is used in the
  /// default state.
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
  /// If [overlayColor] returns a non-null color in the [MaterialState.focused]
  /// state, it will be used instead.
  ///
  /// If null, then the value of [RadioThemeData.overlayColor] is used in the
  /// focused state. If that is also null, then the value of
  /// [ThemeData.focusColor] is used.
  final Color? focusColor;

  /// The color for the radio's [Material] when a pointer is hovering over it.
  ///
  /// If [overlayColor] returns a non-null color in the [MaterialState.hovered]
  /// state, it will be used instead.
  ///
  /// If null, then the value of [RadioThemeData.overlayColor] is used in the
  /// hovered state. If that is also null, then the value of
  /// [ThemeData.hoverColor] is used.
  final Color? hoverColor;

  /// {@template flutter.material.radio.overlayColor}
  /// The color for the checkbox's [Material].
  ///
  /// Resolves in the following states:
  ///  * [MaterialState.pressed].
  ///  * [MaterialState.selected].
  ///  * [MaterialState.hovered].
  ///  * [MaterialState.focused].
  /// {@endtemplate}
  ///
  /// If null, then the value of [activeColor] with alpha
  /// [kRadialReactionAlpha], [focusColor] and [hoverColor] is used in the
  /// pressed, focused and hovered state. If that is also null,
  /// the value of [RadioThemeData.overlayColor] is used. If that is also null,
  /// then the value of [ThemeData.toggleableActiveColor] with alpha
  /// [kRadialReactionAlpha], [ThemeData.focusColor] and [ThemeData.hoverColor]
  /// is used in the pressed, focused and hovered state.
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

  bool get _enabled => onChanged != null;

  void _handleChanged(bool? selected) {
    if (selected == null) {
      onChanged!(null);
      return;
    }
    if (selected) {
      onChanged!(value);
    }
  }

  bool get _selected => value == groupValue;

  MaterialStateProperty<Color?> get _widgetFillColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return null;
      }
      if (states.contains(MaterialState.selected)) {
        return activeColor;
      }
      return null;
    });
  }

  MaterialStateProperty<Color> _defaultFillColor(ThemeData themeData) {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return themeData.disabledColor;
      }
      if (states.contains(MaterialState.selected)) {
        return themeData.toggleableActiveColor;
      }
      return themeData.unselectedWidgetColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData themeData = Theme.of(context);
    final MaterialTapTargetSize effectiveMaterialTapTargetSize = materialTapTargetSize
      ?? themeData.radioTheme.materialTapTargetSize
      ?? themeData.materialTapTargetSize;
    final VisualDensity effectiveVisualDensity = visualDensity
      ?? themeData.radioTheme.visualDensity
      ?? themeData.visualDensity;
    Size size;
    switch (effectiveMaterialTapTargetSize) {
      case MaterialTapTargetSize.padded:
        size = const Size(kMinInteractiveDimension, kMinInteractiveDimension);
        break;
      case MaterialTapTargetSize.shrinkWrap:
        size = const Size(kMinInteractiveDimension - 8.0, kMinInteractiveDimension - 8.0);
        break;
    }
    size += effectiveVisualDensity.baseSizeAdjustment;
    final MaterialStateProperty<MouseCursor> effectiveMouseCursor = MaterialStateProperty.resolveWith<MouseCursor>((Set<MaterialState> states) {
      return MaterialStateProperty.resolveAs<MouseCursor?>(mouseCursor, states)
          ?? themeData.radioTheme.mouseCursor?.resolve(states)
          ?? MaterialStateProperty.resolveAs<MouseCursor>(MaterialStateMouseCursor.clickable, states);
    });

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: _selected,
        child: Toggleable(
        size: size,
        value: _selected,
        tristate: toggleable,
        onChanged: _enabled ? _handleChanged : null,
        focusNode: focusNode,
        autofocus: autofocus,
        mouseCursor: effectiveMouseCursor,
        painterBuilder: (BuildContext context, ToggleableDetails data) {
          // Colors need to be resolved in selected and non selected states separately
          // so that they can be lerped between.
          final Set<MaterialState> activeStates = data.states..add(MaterialState.selected);
          final Set<MaterialState> inactiveStates = data.states..remove(MaterialState.selected);
          final Color effectiveActiveColor = fillColor?.resolve(activeStates)
              ?? _widgetFillColor.resolve(activeStates)
              ?? themeData.radioTheme.fillColor?.resolve(activeStates)
              ?? _defaultFillColor(themeData).resolve(activeStates);
          final Color effectiveInactiveColor = fillColor?.resolve(inactiveStates)
              ?? _widgetFillColor.resolve(inactiveStates)
              ?? themeData.radioTheme.fillColor?.resolve(inactiveStates)
              ?? _defaultFillColor(themeData).resolve(inactiveStates);

          final Set<MaterialState> focusedStates = data.states..add(MaterialState.focused);
          final Color effectiveFocusOverlayColor = overlayColor?.resolve(focusedStates)
              ?? focusColor
              ?? themeData.radioTheme.overlayColor?.resolve(focusedStates)
              ?? themeData.focusColor;

          final Set<MaterialState> hoveredStates = data.states..add(MaterialState.hovered);
          final Color effectiveHoverOverlayColor = overlayColor?.resolve(hoveredStates)
              ?? hoverColor
              ?? themeData.radioTheme.overlayColor?.resolve(hoveredStates)
              ?? themeData.hoverColor;

          final Set<MaterialState> activePressedStates = activeStates..add(MaterialState.pressed);
          final Color effectiveActivePressedOverlayColor = overlayColor?.resolve(activePressedStates)
              ?? themeData.radioTheme.overlayColor?.resolve(activePressedStates)
              ?? effectiveActiveColor.withAlpha(kRadialReactionAlpha);

          final Set<MaterialState> inactivePressedStates = inactiveStates..add(MaterialState.pressed);
          final Color effectiveInactivePressedOverlayColor = overlayColor?.resolve(inactivePressedStates)
              ?? themeData.radioTheme.overlayColor?.resolve(inactivePressedStates)
              ?? effectiveActiveColor.withAlpha(kRadialReactionAlpha);

          return _RadioPainter(
            data: data,
            activeColor: effectiveActiveColor,
            inactiveColor: effectiveInactiveColor,
            focusColor: effectiveFocusOverlayColor,
            hoverColor: effectiveHoverOverlayColor,
            reactionColor: effectiveActivePressedOverlayColor,
            inactiveReactionColor: effectiveInactivePressedOverlayColor,
            splashRadius: splashRadius ?? themeData.radioTheme.splashRadius ?? kRadialReactionRadius,
          );
        },
      ),
    );
  }
}

class _RadioPainter extends ToggleablePainter {
  _RadioPainter({
    required ToggleableDetails data,
    required Color activeColor,
    required Color inactiveColor,
    required Color focusColor,
    required Color hoverColor,
    required Color reactionColor,
    required Color inactiveReactionColor,
    required double splashRadius,
  }) : super(
         data: data,
         activeColor: activeColor,
         inactiveColor: inactiveColor,
         focusColor: focusColor,
         hoverColor: hoverColor,
         reactionColor: reactionColor,
         inactiveReactionColor: inactiveReactionColor,
         splashRadius: splashRadius,
       );

  @override
  void paint(Canvas canvas, Size size) {
    paintRadialReaction(canvas, size.center(Offset.zero));

    final Offset center = (Offset.zero & size).center;

    // Outer circle
    final Paint paint = Paint()
      ..color = Color.lerp(inactiveColor, activeColor, data.position.value)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, _kOuterRadius, paint);

    // Inner circle
    if (!data.position.isDismissed) {
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(center, _kInnerRadius * data.position.value, paint);
    }
  }
}

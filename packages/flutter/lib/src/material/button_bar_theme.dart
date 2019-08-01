import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ButtonBarThemeData extends Diagnosticable {
  const ButtonBarThemeData({
    this.alignment = MainAxisAlignment.end,
    this.mainAxisSize = MainAxisSize.max,
    this.buttonTextTheme = ButtonTextTheme.primary,
    this.buttonMinWidth = 64.0,
    this.buttonHeight = 36.0,
    this.buttonPadding = const EdgeInsets.symmetric(horizontal: 8.0),
    this.buttonAlignedDropdown = false,
    this.layoutBehavior = ButtonBarLayoutBehavior.padded,
  });

  /// How the children should be placed along the horizontal axis.
  final MainAxisAlignment alignment;

  /// How much horizontal space is available. See [Row.mainAxisSize].
  final MainAxisSize mainAxisSize;

  final ButtonTextTheme buttonTextTheme;
  final double buttonMinWidth;
  final double buttonHeight;
  final EdgeInsetsGeometry buttonPadding;
  final bool buttonAlignedDropdown;
  final ButtonBarLayoutBehavior layoutBehavior;

  ButtonBarThemeData copyWith({
    MainAxisAlignment alignment,
    MainAxisSize mainAxisSize,
    ButtonTextTheme buttonTextTheme,
    double buttonMinWidth,
    double buttonHeight,
    EdgeInsetsGeometry buttonPadding,
    bool buttonAlignedDropdown,
    ButtonBarLayoutBehavior layoutBehavior,
  }) {
    return ButtonBarThemeData(
      alignment: alignment ?? this.alignment,
      mainAxisSize: mainAxisSize ?? this.mainAxisSize,
      buttonTextTheme: buttonTextTheme ?? this.buttonTextTheme,
      buttonMinWidth: buttonMinWidth ?? this.buttonMinWidth,
      buttonHeight: buttonHeight ?? this.buttonHeight,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      buttonAlignedDropdown: buttonAlignedDropdown ?? this.buttonAlignedDropdown,
      layoutBehavior: layoutBehavior ?? this.layoutBehavior,
    );
  }

  static ButtonBarThemeData lerp(ButtonBarThemeData a, ButtonBarThemeData b, double t) {
    assert(t != null);
    if (a == null && b == null)
      return null;
    return ButtonBarThemeData(
      alignment: t < 0.5 ? a.alignment : b.alignment,
      mainAxisSize: t < 0.5 ? a.mainAxisSize : b.mainAxisSize,
      buttonTextTheme: t < 0.5 ? a.buttonTextTheme : b.buttonTextTheme,
      buttonMinWidth: lerpDouble(a?.buttonMinWidth, b?.buttonMinWidth, t),
      buttonHeight: lerpDouble(a?.buttonHeight, b?.buttonHeight, t),
      buttonPadding: EdgeInsets.lerp(a?.buttonPadding, b?.buttonPadding, t),
      buttonAlignedDropdown: t < 0.5 ? a.buttonAlignedDropdown : b.buttonAlignedDropdown,
      layoutBehavior: t < 0.5 ? a.layoutBehavior : b.layoutBehavior,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      alignment,
      mainAxisSize,
      buttonTextTheme,
      buttonMinWidth,
      buttonHeight,
      buttonPadding,
      buttonAlignedDropdown,
      layoutBehavior,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final ButtonBarThemeData typedOther = other;
    return typedOther.alignment == alignment
        && typedOther.mainAxisSize == mainAxisSize
        && typedOther.buttonTextTheme == buttonTextTheme
        && typedOther.buttonMinWidth == buttonMinWidth
        && typedOther.buttonHeight == buttonHeight
        && typedOther.buttonPadding == buttonPadding
        && typedOther.buttonAlignedDropdown == buttonAlignedDropdown
        && typedOther.layoutBehavior == layoutBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MainAxisAlignment>('alignment', alignment, defaultValue: null));
    properties.add(DiagnosticsProperty<MainAxisSize>('mainAxisSize', mainAxisSize, defaultValue: null));
    properties.add(DiagnosticsProperty<ButtonTextTheme>('textTheme', buttonTextTheme, defaultValue: null));
    properties.add(DoubleProperty('minWidth', buttonMinWidth, defaultValue: null));
    properties.add(DoubleProperty('height', buttonHeight, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', buttonPadding, defaultValue: null));
    properties.add(FlagProperty('buttonAlignedDropdown', value: buttonAlignedDropdown, defaultValue: null));
    properties.add(DiagnosticsProperty<ButtonBarLayoutBehavior>('layoutBehavior', layoutBehavior, defaultValue: null));
  }
}

class ButtonBarTheme extends InheritedWidget {
  const ButtonBarTheme({
    Key key,
    @required this.data,
    Widget child,
  }) : assert(data != null), super(key: key, child: child);

  final ButtonBarThemeData data;

  static ButtonBarThemeData of(BuildContext context) {
    final ButtonBarTheme buttonBarTheme = context.inheritFromWidgetOfExactType(ButtonBarTheme);
    return buttonBarTheme?.data ?? Theme.of(context).buttonBarTheme;
  }

  @override
  bool updateShouldNotify(ButtonBarTheme oldWidget) => data != oldWidget.data;
}

import 'package:flutter/widgets.dart';

class CupertinoDialogTheme {
  const CupertinoDialogTheme({
    this.color,
    this.pressedColor,
    this.buttonDividerColor,
  });

  final Color color;
  final Color pressedColor;
  final Color buttonDividerColor;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final CupertinoDialogTheme typedOther = other;
    return typedOther.color == color
        && typedOther.pressedColor == pressedColor
        && typedOther.buttonDividerColor == buttonDividerColor;
  }

  @override
  int get hashCode => hashValues(color, pressedColor, buttonDividerColor);

  static CupertinoDialogTheme lerp(CupertinoDialogTheme a, CupertinoDialogTheme b, double t) {
    assert(t != null);
    return CupertinoDialogTheme(
      color: Color.lerp(a?.color, b?.color, t),
      pressedColor: Color.lerp(a?.pressedColor, b?.pressedColor, t),
      buttonDividerColor: Color.lerp(a?.buttonDividerColor, b?.buttonDividerColor, t),
    );
  }
}

class CupertinoThemeData {
  const CupertinoThemeData({
    this.dialogTheme = const CupertinoDialogTheme(),
  });

  final CupertinoDialogTheme dialogTheme;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final CupertinoThemeData typedOther = other;
    return typedOther.dialogTheme == dialogTheme;
  }

  @override
  int get hashCode => dialogTheme.hashCode;

  static CupertinoThemeData lerp(CupertinoThemeData a, CupertinoThemeData b, double t) {
    assert(a != null);
    assert(b != null);
    assert(t != null);
    return CupertinoThemeData(
      dialogTheme: CupertinoDialogTheme.lerp(a.dialogTheme, b.dialogTheme, t),
    );
  }
}

class CupertinoTheme extends InheritedModel<Type> {
  const CupertinoTheme({
    Key key,
    this.data = const CupertinoThemeData(),
    Widget child,
  }) : super(key: key, child: child);

  final CupertinoThemeData data;

  @override
  bool updateShouldNotify(CupertinoTheme oldWidget) {
    return data != oldWidget.data;
  }

  @override
  bool updateShouldNotifyDependent(CupertinoTheme oldWidget, Set<Type> dependencies) {
    return dependencies.contains(CupertinoDialogTheme) && data.dialogTheme != oldWidget.data.dialogTheme;
  }

  static CupertinoDialogTheme dialogThemeOf(BuildContext context) {
    final CupertinoTheme theme = InheritedModel.inheritFrom<CupertinoTheme>(context, aspect: CupertinoDialogTheme);
    return theme.data.dialogTheme;
  }
}

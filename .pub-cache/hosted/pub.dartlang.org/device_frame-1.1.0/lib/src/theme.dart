import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme.freezed.dart';

/// The theme gives a [style] to all its descentant device frames.
///
/// The only customizable visuals are the keyboard style.
class DeviceFrameTheme extends InheritedWidget {
  /// Give a [style] to all descentant in [child] device frames.
  const DeviceFrameTheme({
    Key? key,
    required this.style,
    required Widget child,
  }) : super(
          key: key,
          child: child,
        );

  /// The style of the device frame.
  final DeviceFrameStyle style;

  /// The data from the closest instance of this class that encloses the given
  /// [context].
  static DeviceFrameStyle of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<DeviceFrameTheme>();

    return widget?.style ?? DeviceFrameStyle.dark();
  }

  @override
  bool updateShouldNotify(DeviceFrameTheme oldWidget) {
    return oldWidget.style != style;
  }
}

/// The device frame style only allows to update the [keyboardStyle] for now.
///
/// See also:
///
/// * [DeviceKeyboardStyle] to customize the virtual on screen keyboard.
@freezed
abstract class DeviceFrameStyle with _$DeviceFrameStyle {
  /// Create a [DeviceFrameStyle] with the given [keyboardStyle].
  const factory DeviceFrameStyle({
    required DeviceKeyboardStyle keyboardStyle,
  }) = _DeviceFrameStyle;

  /// A default dark theme.
  factory DeviceFrameStyle.dark({DeviceKeyboardStyle? keyboardStyle}) =>
      DeviceFrameStyle(
        keyboardStyle: keyboardStyle ?? DeviceKeyboardStyle.dark(),
      );
}

/// The keyboard style allows to customize the virtual onscreen keyboard visuals.
@freezed
abstract class DeviceKeyboardStyle with _$DeviceKeyboardStyle {
  /// Creates a new style for the virtual keyboard.
  const factory DeviceKeyboardStyle({
    required Color backgroundColor,
    required Color button1BackgroundColor,
    required Color button1ForegroundColor,
    required Color button2BackgroundColor,
    required Color button2ForegroundColor,
  }) = _DeviceKeyboardStyle;

  /// A default dark theme for the virtual keyboard.
  factory DeviceKeyboardStyle.dark() => const DeviceKeyboardStyle(
        backgroundColor: Color(0xDD2B2B2D),
        button1BackgroundColor: Color(0xFF6D6D6E),
        button1ForegroundColor: Colors.white,
        button2BackgroundColor: Color(0xFF4A4A4B),
        button2ForegroundColor: Colors.white,
      );
}

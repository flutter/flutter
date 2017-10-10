// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';
import 'icon_data.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';


/// A graphical icon widget drawn with a glyph from a font described in
/// an [IconData] such as material's predefined [IconData]s in [Icons].
///
/// Icons are not interactive. For an interactive icon, consider material's
/// [IconButton].
///
/// There must be an ambient [Directionality] widget when using [Icon].
/// Typically this is introduced automatically by the [WidgetsApp] or
/// [MaterialApp].
///
/// See also:
///
///  * [IconButton], for interactive icons.
///  * [Icons], for the list of available icons for use with this class.
///  * [IconTheme], which provides ambient configuration for icons.
///  * [ImageIcon], for showing icons from [AssetImage]s or other [ImageProvider]s.
class Icon extends StatelessWidget {
  /// Creates an icon.
  ///
  /// The [size] and [color] default to the value given by the current [IconTheme].
  const Icon(this.icon, {
    Key key,
    this.size,
    this.color,
    this.semanticLabel,
  }) : super(key: key);

  /// The icon to display. The available icons are described in [Icons].
  ///
  /// The icon can be null, in which case the widget will render as an empty
  /// space of the specified [size].
  final IconData icon;

  /// The size of the icon in logical pixels.
  ///
  /// Icons occupy a square with width and height equal to size.
  ///
  /// Defaults to the current [IconTheme] size, if any. If there is no
  /// [IconTheme], or it does not specify an explicit size, then it defaults to
  /// 24.0.
  ///
  /// If this [Icon] is being placed inside an [IconButton], then use
  /// [IconButton.iconSize] instead, so that the [IconButton] can make the splash
  /// area the appropriate size as well. The [IconButton] uses an [IconTheme] to
  /// pass down the size to the [Icon].
  final double size;

  /// The color to use when drawing the icon.
  ///
  /// Defaults to the current [IconTheme] color, if any.
  ///
  /// The given color will be adjusted by the opacity of the current
  /// [IconTheme], if any.
  ///
  /// If no [IconTheme]s are specified, icons will default to black.
  ///
  /// In material apps, if there is a [Theme] without any [IconTheme]s
  /// specified, icon colors default to white if the theme is dark
  /// and black if the theme is light.
  /// See [Theme] to set the current theme and [ThemeData.brightness]
  /// for setting the current theme's brightness.
  ///
  /// Typically, a material design color will be used, as follows:
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.blue.shade400,
  ///  ),
  /// ```
  final Color color;

  /// Semantic label for the icon.
  ///
  /// This would be read out in accessibility modes (e.g TalkBack/VoiceOver).
  /// This label does not show in the UI.
  ///
  /// See [Semantics.label];
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final TextDirection textDirection = Directionality.of(context);

    final IconThemeData iconTheme = IconTheme.of(context);

    final double iconSize = size ?? iconTheme.size;

    if (icon == null)
      return _wrapWithSemantics(new SizedBox(width: iconSize, height: iconSize));

    final double iconOpacity = iconTheme.opacity;
    Color iconColor = color ?? iconTheme.color;
    if (iconOpacity != 1.0)
      iconColor = iconColor.withOpacity(iconColor.opacity * iconOpacity);

    return _wrapWithSemantics(
      new ExcludeSemantics(
        child: new SizedBox(
          width: iconSize,
          height: iconSize,
          child: new Center(
            child: new RichText(
              textDirection: textDirection, // Since we already fetched it for the assert...
              text: new TextSpan(
                text: new String.fromCharCode(icon.codePoint),
                style: new TextStyle(
                  inherit: false,
                  color: iconColor,
                  fontSize: iconSize,
                  fontFamily: icon.fontFamily,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Wraps the widget with a Semantics widget if [semanticLabel] is set.
  Widget _wrapWithSemantics(Widget widget) {
    if (semanticLabel == null)
      return widget;

    return new Semantics(
      child: widget,
      label: semanticLabel,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DiagnosticsProperty<IconData>('icon', icon, ifNull: '<empty>', showName: false));
    description.add(new DoubleProperty('size', size, defaultValue: null));
    description.add(new DiagnosticsProperty<Color>('color', color, defaultValue: null));
  }
}

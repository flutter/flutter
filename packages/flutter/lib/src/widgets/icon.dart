// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';
import 'icon_data.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';

// TODO(plg): Update documentation about Symbols where [Icons] are mentioned

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
/// This widget assumes that the rendered icon is squared. Non-squared icons may
/// render incorrectly.
///
/// {@tool snippet}
///
/// This example shows how to create a [Row] of [Icon]s in different colors and
/// sizes. The first [Icon] uses a [semanticLabel] to announce in accessibility
/// modes like TalkBack and VoiceOver.
///
/// ![The following code snippet would generate a row of icons consisting of a pink heart, a green musical note, and a blue umbrella, each progressively bigger than the last.](https://flutter.github.io/assets-for-api-docs/assets/widgets/icon.png)
///
/// ```dart
/// Row(
///   mainAxisAlignment: MainAxisAlignment.spaceAround,
///   children: const <Widget>[
///     Icon(
///       Icons.favorite,
///       color: Colors.pink,
///       size: 24.0,
///       semanticLabel: 'Text to announce in accessibility modes',
///     ),
///     Icon(
///       Icons.audiotrack,
///       color: Colors.green,
///       size: 30.0,
///     ),
///     Icon(
///       Icons.beach_access,
///       color: Colors.blue,
///       size: 36.0,
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [IconButton], for interactive icons.
///  * [Icons], for the list of available Material Icons for use with this class.
///  * [IconTheme], which provides ambient configuration for icons.
///  * [ImageIcon], for showing icons from [AssetImage]s or other [ImageProvider]s.
class Icon extends StatelessWidget {
  /// Creates an icon.
  ///
  /// The [size] and [color] default to the value given by the current [IconTheme].
  const Icon(
    this.icon, {
    super.key,
    this.size,
    this.fill,
    this.weight,
    this.grade,
    this.opticalSize,
    this.color,
    this.shadows,
    this.semanticLabel,
    this.textDirection,
  });

  /// The icon to display. The available icons are described in [Icons].
  ///
  /// The icon can be null, in which case the widget will render as an empty
  /// space of the specified [size].
  final IconData? icon;

  /// The size of the icon in logical pixels.
  ///
  /// Icons occupy a square with width and height equal to size.
  ///
  /// Defaults to the nearest [IconTheme]'s [IconThemeData.size].
  ///
  /// If this [Icon] is being placed inside an [IconButton], then use
  /// [IconButton.iconSize] instead, so that the [IconButton] can make the splash
  /// area the appropriate size as well. The [IconButton] uses an [IconTheme] to
  /// pass down the size to the [Icon].
  final double? size;

  /// [FontVariation] which specifies an icon's fill.
  ///
  /// TODO(guidezpl): remove Ranges from 0 for unfilled to 1 for completely filled.
  ///
  /// Can be used to convey a state transition for animation or interaction.
  ///
  /// Requires the underlying icon font to support the `FILL` [FontVariation]
  /// axis, otherwise has no effect.
  ///
  /// Defaults to nearest [IconTheme]'s [IconThemeData.fill].
  ///
  /// See also:
  ///  * [weight], a [FontVariation] for controlling stroke weight.
  ///  * [grade], a [FontVariation] for controlling stroke grade.
  ///  * [opticalSize], a [FontVariation] for controlling optical size.
  final double? fill;

  /// [FontVariation] which specifies an icon's stroke weight.
  ///
  /// TODO(guidezpl): remove Ranges from 100 (thin) to 700 (bold).
  ///
  /// Requires the underlying icon font to support the `wght` [FontVariation]
  /// axis, otherwise has no effect.
  ///
  /// Defaults to nearest [IconTheme]'s [IconThemeData.weight].
  ///
  /// See also:
  ///  * [fill], a [FontVariation] for controlling fill.
  ///  * [grade], a [FontVariation] for controlling stroke grade.
  ///  * [opticalSize], a [FontVariation] for controlling optical size.
  ///  * https://fonts.google.com/knowledge/glossary/weight_axis
  final double? weight;

  /// [FontVariation] which specifies an icon's stroke weight in a more granular way.
  ///
  /// TODO(guidezpl): remove => Ranges from -25 to 200.
  ///
  /// Grade and [weight] both affect a symbol's stroke weight (thickness), but
  /// grade has a smaller impact on the size of the symbol.
  ///
  /// Grade is also available in some text fonts. One can match grade levels
  /// between text and symbols for a harmonious visual effect. For example, if
  /// the text font has a -25 grade value, the symbols can match it with a
  /// suitable value, say -25.
  ///
  /// Grade for different needs:
  /// - Low emphasis (e.g. -25 grade): To reduce glare for a light symbol on a
  /// dark background, use a low grade.
  /// - High emphasis (e.g. 200 grade): To highlight a symbol, increase the
  /// positive grade.
  ///
  /// Requires the underlying icon font to support the `GRAD` [FontVariation]
  /// axis, otherwise has no effect.
  ///
  /// Defaults to nearest [IconTheme]'s [IconThemeData.grade].
  ///
  /// See also:
  ///  * [fill], a [FontVariation] for controlling fill.
  ///  * [weight], a [FontVariation] for controlling stroke weight.
  ///  * [opticalSize], a [FontVariation] for controlling optical size.
  ///  * https://fonts.google.com/knowledge/glossary/grade_axis
  final double? grade;

  /// [FontVariation] which specifies an icon's optical size.
  ///
  /// TODO(guidezpl): remove Ranges from 20dp to 48dp.
  ///
  /// For an icon to look the same at different sizes, the stroke weight
  /// (thickness) must change as the icon size scales. Optical size offers a way
  /// to automatically adjust the stroke weight as icon size changes.
  ///
  /// Requires the underlying icon font to support the `opsz` [FontVariation]
  /// axis, otherwise has no effect.
  ///
  /// Defaults to nearest [IconTheme]'s [IconThemeData.opticalSize].
  ///
  /// See also:
  ///  * [fill], a [FontVariation] for controlling fill.
  ///  * [weight], a [FontVariation] for controlling stroke weight.
  ///  * [grade], a [FontVariation] for controlling stroke grade.
  ///  * https://fonts.google.com/knowledge/glossary/optical_size_axis
  final double? opticalSize;

  /// The color to use when drawing the icon.
  ///
  /// Defaults to the nearest [IconTheme]'s [IconThemeData.color].
  ///
  /// The color (whether specified explicitly here or obtained from the
  /// [IconTheme]) will be further adjusted by the nearest [IconTheme]'s
  /// [IconThemeData.opacity].
  ///
  /// {@tool snippet}
  /// Typically, a Material Design color will be used, as follows:
  ///
  /// ```dart
  /// Icon(
  ///   Icons.widgets,
  ///   color: Colors.blue.shade400,
  /// )
  /// ```
  /// {@end-tool}
  final Color? color;

  /// A list of [Shadow]s that will be painted underneath the icon.
  ///
  /// Multiple shadows are supported to replicate lighting from multiple light
  /// sources.
  ///
  /// Shadows must be in the same order for [Icon] to be considered as
  /// equivalent as order produces differing transparency.
  ///
  /// Defaults to the nearest [IconTheme]'s [IconThemeData.shadows].
  final List<Shadow>? shadows;

  /// Semantic label for the icon.
  ///
  /// Announced in accessibility modes (e.g TalkBack/VoiceOver).
  /// This label does not show in the UI.
  ///
  ///  * [SemanticsProperties.label], which is set to [semanticLabel] in the
  ///    underlying	 [Semantics] widget.
  final String? semanticLabel;

  /// The text direction to use for rendering the icon.
  ///
  /// If this is null, the ambient [Directionality] is used instead.
  ///
  /// Some icons follow the reading direction. For example, "back" buttons point
  /// left in left-to-right environments and right in right-to-left
  /// environments. Such icons have their [IconData.matchTextDirection] field
  /// set to true, and the [Icon] widget uses the [textDirection] to determine
  /// the orientation in which to draw the icon.
  ///
  /// This property has no effect if the [icon]'s [IconData.matchTextDirection]
  /// field is false, but for consistency a text direction value must always be
  /// specified, either directly using this property or using [Directionality].
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    assert(this.textDirection != null || debugCheckHasDirectionality(context));
    final TextDirection textDirection = this.textDirection ?? Directionality.of(context);

    final IconThemeData iconTheme = IconTheme.of(context);

    final double? iconSize = size ?? iconTheme.size;

    final List<Shadow>? iconShadows = shadows ?? iconTheme.shadows;

    if (icon == null) {
      return Semantics(
        label: semanticLabel,
        child: SizedBox(width: iconSize, height: iconSize),
      );
    }

    final double iconOpacity = iconTheme.opacity ?? 1.0;
    Color iconColor = color ?? iconTheme.color!;
    if (iconOpacity != 1.0) {
      iconColor = iconColor.withOpacity(iconColor.opacity * iconOpacity);
    }

    Widget iconWidget = RichText(
      overflow: TextOverflow.visible, // Never clip.
      textDirection: textDirection, // Since we already fetched it for the assert...
      text: TextSpan(
        text: String.fromCharCode(icon!.codePoint),
        style: TextStyle(
          fontVariations: [
            if (fill != null) FontVariation('FILL', fill!),
            if (weight != null) FontVariation('wght', weight!),
            if (grade != null) FontVariation('GRAD', grade!),
            if (opticalSize != null) FontVariation('opsz', opticalSize!),
          ],
          inherit: false,
          color: iconColor,
          fontSize: iconSize,
          fontFamily: icon!.fontFamily,
          package: icon!.fontPackage,
          shadows: iconShadows,
        ),
      ),
    );

    if (icon!.matchTextDirection) {
      switch (textDirection) {
        case TextDirection.rtl:
          iconWidget = Transform(
            transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
            alignment: Alignment.center,
            transformHitTests: false,
            child: iconWidget,
          );
          break;
        case TextDirection.ltr:
          break;
      }
    }

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: iconSize,
          height: iconSize,
          child: Center(
            child: iconWidget,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IconDataProperty('icon', icon, ifNull: '<empty>', showName: false));
    properties.add(DoubleProperty('size', size, defaultValue: null));
    properties.add(DoubleProperty('fill', fill, defaultValue: null));
    properties.add(DoubleProperty('weight', weight, defaultValue: null));
    properties.add(DoubleProperty('grade', grade, defaultValue: null));
    properties.add(DoubleProperty('opticalSize', opticalSize, defaultValue: null));
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(IterableProperty<Shadow>('shadows', shadows, defaultValue: null));
    properties.add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
  }
}

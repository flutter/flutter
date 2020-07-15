// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/widgets.dart';

import '../color_scheme.dart';
import '../icon_button.dart';
import '../material.dart';
import '../text_theme.dart';
import '../theme.dart';

// This is an internal implementation file. Even though there are public
// classes and functions defined here, they are only meant to be used by the
// date picker implementation and are not exported as part of the Material library.
// See pickers.dart for exactly what is considered part of the public API.

const double _datePickerHeaderLandscapeWidth = 152.0;
const double _datePickerHeaderPortraitHeight = 120.0;
const double _headerPaddingLandscape = 16.0;

/// Re-usable widget that displays the selected date (in large font) and the
/// help text above it.
///
/// These types include:
///
/// * Single Date picker with calendar mode.
/// * Single Date picker with manual input mode.
/// * Date Range picker with manual input mode.
///
/// [helpText], [orientation], [icon], [onIconPressed] are required and must be
/// non-null.
class DatePickerHeader extends StatelessWidget {
  /// Creates a header for use in a date picker dialog.
  const DatePickerHeader({
    Key key,
    @required this.helpText,
    @required this.titleText,
    this.titleSemanticsLabel,
    @required this.titleStyle,
    @required this.orientation,
    this.isShort = false,
    @required this.icon,
    @required this.iconTooltip,
    @required this.onIconPressed,
  }) : assert(helpText != null),
       assert(orientation != null),
       assert(isShort != null),
       super(key: key);

  /// The text that is displayed at the top of the header.
  ///
  /// This is used to indicate to the user what they are selecting a date for.
  final String helpText;

  /// The text that is displayed at the center of the header.
  final String titleText;

  /// The semantic label associated with the [titleText].
  final String titleSemanticsLabel;

  /// The [TextStyle] that the title text is displayed with.
  final TextStyle titleStyle;

  /// The orientation is used to decide how to layout its children.
  final Orientation orientation;

  /// Indicates the header is being displayed in a shorter/narrower context.
  ///
  /// This will be used to tighten up the space between the help text and date
  /// text if `true`. Additionally, it will use a smaller typography style if
  /// `true`.
  ///
  /// This is necessary for displaying the manual input mode in
  /// landscape orientation, in order to account for the keyboard height.
  final bool isShort;

  /// The mode-switching icon that will be displayed in the lower right
  /// in portrait, and lower left in landscape.
  ///
  /// The available icons are described in [Icons].
  final IconData icon;

  /// The text that is displayed for the tooltip of the icon.
  final String iconTooltip;

  /// Callback when the user taps the icon in the header.
  ///
  /// The picker will use this to toggle between entry modes.
  final VoidCallback onIconPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    // The header should use the primary color in light themes and surface color in dark
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final Color primarySurfaceColor = isDark ? colorScheme.surface : colorScheme.primary;
    final Color onPrimarySurfaceColor = isDark ? colorScheme.onSurface : colorScheme.onPrimary;

    final TextStyle helpStyle = textTheme.overline?.copyWith(
      color: onPrimarySurfaceColor,
    );

    final Text help = Text(
      helpText,
      style: helpStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final Text title = Text(
      titleText,
      semanticsLabel: titleSemanticsLabel ?? titleText,
      style: titleStyle,
      maxLines: orientation == Orientation.portrait ? 1 : 2,
      overflow: TextOverflow.ellipsis,
    );
    final IconButton icon = IconButton(
      icon: Icon(this.icon),
      color: onPrimarySurfaceColor,
      tooltip: iconTooltip,
      onPressed: onIconPressed,
    );

    switch (orientation) {
      case Orientation.portrait:
         return SizedBox(
           height: _datePickerHeaderPortraitHeight,
           child: Material(
             color: primarySurfaceColor,
             child: Padding(
               padding: const EdgeInsetsDirectional.only(
                 start: 24,
                 end: 12,
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: <Widget>[
                   const SizedBox(height: 16),
                   Flexible(child: help),
                   const SizedBox(height: 38),
                   Row(
                     children: <Widget>[
                       Expanded(child: title),
                       icon,
                     ],
                   ),
                 ],
               ),
             ),
           ),
         );
      case Orientation.landscape:
        return SizedBox(
          width: _datePickerHeaderLandscapeWidth,
          child: Material(
            color: primarySurfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _headerPaddingLandscape,
                  ),
                  child: help,
                ),
                SizedBox(height: isShort ? 16 : 56),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _headerPaddingLandscape,
                    ),
                    child: title,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  child: icon,
                ),
              ],
            ),
          ),
        );
    }
    return null;
  }
}

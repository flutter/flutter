// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

const double _kScrollbarThickness = 6.0;
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

/// A material design scrollbar.
///
/// To add a scrollbar thumb to a [ScrollView], simply wrap the scroll view
/// widget in a [Scrollbar] widget.
///
/// {@macro flutter.widgets.Scrollbar}
///
/// A scrollbar track can been drawn when triggered by a hover event, which is
/// controlled by [showTrackOnHover]. The thickness of the track and scrollbar
/// thumb will become larger when hovering, unless overridden by [thickness].
///
// TODO(Piinks): Add code sample
///
/// See also:
///
///  * [RawScrollbar], the simple base class this extends.
///  * [CupertinoScrollbar], an iOS style scrollbar.
///  * [ListView], which display a linear, scrollable list of children.
///  * [GridView], which display a 2 dimensional, scrollable array of children.
class Scrollbar extends RawScrollbar {
  /// Creates a material design scrollbar that wraps the given [child].
  ///
  /// The [child] should be a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  const Scrollbar({
    Key? key,
    required Widget child,
    ScrollController? controller,
    bool isAlwaysShown = false,
    double? thickness,
    Radius? radius,
  }) : super(
         key: key,
         child: child,
         controller: controller,
         isAlwaysShown: isAlwaysShown,
         thickness: thickness,
         radius: radius,
         fadeDuration: _kScrollbarFadeDuration,
         timeToFade: _kScrollbarTimeToFade,
         pressDuration: Duration.zero,
       );

  @override
  _ScrollbarState createState() => _ScrollbarState();
}

class _ScrollbarState extends RawScrollbarState<Scrollbar> {
  late TextDirection _textDirection;
  late Color _themeColor;

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    _textDirection = Directionality.of(context);
    _themeColor = theme.highlightColor.withOpacity(1.0);
    painter = _buildMaterialScrollbarPainter();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(Scrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    painter!
      ..thickness = widget.thickness ?? _kScrollbarThickness
      ..radius = widget.radius;
  }

  ScrollbarPainter _buildMaterialScrollbarPainter() {
    return ScrollbarPainter(
      color: _themeColor,
      textDirection: _textDirection,
      thickness: widget.thickness ?? _kScrollbarThickness,
      radius: widget.radius,
      fadeoutOpacityAnimation: fadeoutOpacityAnimation,
      padding: MediaQuery.of(context).padding,
    );
  }
}

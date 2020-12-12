// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'color_scheme.dart';
import 'material_state.dart';
import 'theme.dart';

const double _kScrollbarThickness = 8.0;
const double _kScrollbarThicknessWithTrack = 12.0;
const double _kScrollbarMargin = 2.0;
const double _kScrollbarMinLength = 48.0;
const Radius _kScrollbarRadius = Radius.circular(8.0);
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

/// A material design scrollbar.
///
/// To add a scrollbar thumb to a [ScrollView], simply wrap the scroll view
/// widget in a [Scrollbar] widget.
///
/// {@macro flutter.widgets.Scrollbar}
///
/// The color of the Scrollbar will change when dragged, as well as when
/// hovered over. A scrollbar track can also been drawn when triggered by a
/// hover event, which is controlled by [showTrackOnHover]. The thickness of the
/// track and scrollbar thumb will become larger when hovering, unless
/// overridden by [hoverThickness].
///
// TODO(Piinks): Add code sample
///
/// See also:
///
///  * [RawScrollbar], a basic scrollbar that fades in and out, extended
///    by this class to add more animations and behaviors.
///  * [CupertinoScrollbar], an iOS style scrollbar.
///  * [ListView], which displays a linear, scrollable list of children.
///  * [GridView], which displays a 2 dimensional, scrollable array of children.
class Scrollbar extends RawScrollbar {
  /// Creates a material design scrollbar that by default will connect to the
  /// closest Scrollable descendant of [child].
  ///
  /// The [child] should be a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  ///
  /// If the [controller] is null, the default behavior is to
  /// enable scrollbar dragging using the [PrimaryScrollController].
  ///
  /// When null, [thickness] and [radius] defaults will result in a rounded
  /// rectangular thumb that is 8.0 dp wide with a radius of 8.0 pixels.
  const Scrollbar({
    Key? key,
    required Widget child,
    ScrollController? controller,
    bool isAlwaysShown = false,
    this.showTrackOnHover = false,
    this.hoverThickness,
    double? thickness,
    Radius? radius,
  }) : super(
         key: key,
         child: child,
         controller: controller,
         isAlwaysShown: isAlwaysShown,
         thickness: thickness ?? _kScrollbarThickness,
         radius: radius,
         fadeDuration: _kScrollbarFadeDuration,
         timeToFade: _kScrollbarTimeToFade,
         pressDuration: Duration.zero,
       );

  /// Controls if the track will show on hover and remain, including during drag.
  ///
  /// Defaults to false, cannot be null.
  final bool showTrackOnHover;

  /// The thickness of the scrollbar when a hover state is active and
  /// [showTrackOnHover] is true.
  ///
  /// Defaults to 12.0 dp when null.
  final double? hoverThickness;

  @override
  _ScrollbarState createState() => _ScrollbarState();
}

class _ScrollbarState extends RawScrollbarState<Scrollbar> {
  late AnimationController _hoverAnimationController;
  bool _dragIsActive = false;
  bool _hoverIsActive = false;
  late ColorScheme _colorScheme;

  Set<MaterialState> get _states => <MaterialState>{
    if (_dragIsActive) MaterialState.dragged,
    if (_hoverIsActive) MaterialState.hovered,
  };

  MaterialStateProperty<Color> get _thumbColor {
    final Color onSurface = _colorScheme.onSurface;
    final Brightness brightness = _colorScheme.brightness;
    late Color dragColor;
    late Color hoverColor;
    late Color idleColor;
    switch (brightness) {
      case Brightness.light:
        dragColor = onSurface.withOpacity(0.6);
        hoverColor = onSurface.withOpacity(0.5);
        idleColor = onSurface.withOpacity(0.1);
        break;
      case Brightness.dark:
        dragColor = onSurface.withOpacity(0.75);
        hoverColor = onSurface.withOpacity(0.65);
        idleColor = onSurface.withOpacity(0.3);
        break;
    }

    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.dragged))
        return dragColor;

      // If the track is visible, the thumb color hover animation is ignored and
      // changes immediately.
      if (states.contains(MaterialState.hovered) && widget.showTrackOnHover)
        return hoverColor;

      return Color.lerp(
        idleColor,
        hoverColor,
        _hoverAnimationController.value,
      )!;
    });
  }

  MaterialStateProperty<Color> get _trackColor {
    final Color onSurface = _colorScheme.onSurface;
    final Brightness brightness = _colorScheme.brightness;
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.hovered) && widget.showTrackOnHover) {
        return brightness == Brightness.light
          ? onSurface.withOpacity(0.03)
          : onSurface.withOpacity(0.05);
      }
      return const Color(0x00000000);
    });
  }

  MaterialStateProperty<Color> get _trackBorderColor {
    final Color onSurface = _colorScheme.onSurface;
    final Brightness brightness = _colorScheme.brightness;
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.hovered) && widget.showTrackOnHover) {
        return brightness == Brightness.light
          ? onSurface.withOpacity(0.1)
          : onSurface.withOpacity(0.25);
      }
      return const Color(0x00000000);
    });
  }

  MaterialStateProperty<double> get _thickness {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.hovered) && widget.showTrackOnHover)
        return widget.hoverThickness ?? _kScrollbarThicknessWithTrack;
      return widget.thickness ?? _kScrollbarThickness;
    });
  }

  @override
  void initState() {
    super.initState();
    _hoverAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _hoverAnimationController.addListener(() {
      updateScrollbarPainter();
    });
  }

  @override
  void updateScrollbarPainter() {
    _colorScheme = Theme.of(context).colorScheme;
    scrollbarPainter
      ..color = _thumbColor.resolve(_states)
      ..trackColor = _trackColor.resolve(_states)
      ..trackBorderColor = _trackBorderColor.resolve(_states)
      ..textDirection = Directionality.of(context)
      ..thickness = _thickness.resolve(_states)
      ..radius = widget.radius ?? _kScrollbarRadius
      ..crossAxisMargin = _kScrollbarMargin
      ..minLength = _kScrollbarMinLength
      ..padding = MediaQuery.of(context).padding;
  }

  @override
  void handleThumbPressStart(Offset localPosition) {
    super.handleThumbPressStart(localPosition);
    setState(() { _dragIsActive = true; });
  }

  @override
  void handleThumbPressEnd(Offset localPosition, Velocity velocity) {
    super.handleThumbPressEnd(localPosition, velocity);
    setState(() { _dragIsActive = false; });
  }

  @override
  void handleHover(PointerHoverEvent event) {
    super.handleHover(event);
    // Check if the position of the pointer falls over the painted scrollbar
    if (isPointerOverScrollbar(event.position)) {
      // Pointer is hovering over the scrollbar
      setState(() { _hoverIsActive = true; });
      _hoverAnimationController.forward();
    } else if (_hoverIsActive) {
      // Pointer was, but is no longer over painted scrollbar.
      setState(() { _hoverIsActive = false; });
      _hoverAnimationController.reverse();
    }
  }

  @override
  void handleHoverExit(PointerExitEvent event) {
    super.handleHoverExit(event);
    setState(() { _hoverIsActive = false; });
    _hoverAnimationController.reverse();
  }

  @override
  void dispose() {
    _hoverAnimationController.dispose();
    super.dispose();
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'material_state.dart';

const double _kScrollbarThickness = 8.0;
const double _kScrollbarHoverThickness = 12.0;
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
/// A scrollbar track can been drawn when triggered by a hover event, which is
/// controlled by [showTrackOnHover]. The thickness of the track and scrollbar
/// thumb will become larger when hovering, unless overridden by [thickness].
///
// TODO(Piinks): Add code sample
///
/// See also:
///
///  * [RawScrollbar], a basic scrollbar that fade in and out that is extended
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
  /// When null, [thickness] and [radius] defaults will result in a rectangular
  /// painted thumb that is 6.0 pixels wide.
  const Scrollbar({
    Key? key,
    required Widget child,
    ScrollController? controller,
    bool isAlwaysShown = false,
    this.showTrackOnHover = false,
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

  @override
  _ScrollbarState createState() => _ScrollbarState();
}

class _ScrollbarState extends RawScrollbarState<Scrollbar> {
  late AnimationController _hoverAnimationController;
  late TextDirection _textDirection;
  bool _dragIsActive = false;
  bool _hoverIsActive = false;

  Set<MaterialState> get _states => <MaterialState>{
    if (_dragIsActive) MaterialState.dragged,
    if (_hoverIsActive) MaterialState.hovered,
  };

  MaterialStateProperty<Color> get _thumbColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.dragged))
        return const Color(0xFF616161);

      // If the track is visible, the thumb color animation is ignored.
      if (states.contains(MaterialState.hovered) && widget.showTrackOnHover && _hoverIsActive)
        return const Color(0xFF757575);

      return Color.lerp(
        const Color(0xFFE0E0E0),
        const Color(0xFF757575),
        _hoverAnimationController.value,
      )!;
    });
  }

  MaterialStateProperty<Color> get _trackColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.hovered) && widget.showTrackOnHover)
        return const Color(0xFF424242).withOpacity(0.04);
      return const Color(0x00000000);
    });
  }

  MaterialStateProperty<Color> get _trackBorderColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.hovered) && widget.showTrackOnHover)
        return const Color(0xFFE0E0E0);
      return const Color(0x00000000);
    });
  }

  MaterialStateProperty<double> get _thickness {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (widget.thickness != null)
        return widget.thickness;
      if (states.contains(MaterialState.hovered) && widget.showTrackOnHover)
        return _kScrollbarHoverThickness;
      return _kScrollbarThickness;
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
      scrollbarPainter!.updateColors(
        _thumbColor.resolve(_states),
        _trackColor.resolve(_states),
        _trackBorderColor.resolve(_states),
      );
      scrollbarPainter!.updateThickness(
        _thickness.resolve(_states),
        widget.radius ?? _kScrollbarRadius,
      );
    });
  }

  @override
  void didChangeDependencies() {
    _textDirection = Directionality.of(context);
    scrollbarPainter = _buildMaterialScrollbarPainter();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(Scrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    scrollbarPainter!
      ..thickness = _thickness.resolve(_states)
      ..radius = widget.radius ?? _kScrollbarRadius;
  }

  ScrollbarPainter _buildMaterialScrollbarPainter() {
    return ScrollbarPainter(
      color: _thumbColor.resolve(_states),
      trackColor: _trackColor.resolve(_states),
      trackBorderColor: _trackBorderColor.resolve(_states),
      textDirection: _textDirection,
      thickness: widget.thickness,
      radius: widget.radius ?? _kScrollbarRadius,
      crossAxisMargin: _kScrollbarMargin,
      minLength: _kScrollbarMinLength,
      fadeoutOpacityAnimation: fadeoutOpacityAnimation,
      padding: MediaQuery.of(context).padding,
    );
  }

  @override
  void handleThumbPressStart(LongPressStartDetails details) {
    super.handleThumbPressStart(details);
    setState(() { _dragIsActive = true; });
    scrollbarPainter!.updateColors(
      _thumbColor.resolve(_states),
      _trackColor.resolve(_states),
      _trackBorderColor.resolve(_states),
    );
  }

  @override
  void handleThumbPressEnd(LongPressEndDetails details) {
    super.handleThumbPressEnd(details);
    setState(() { _dragIsActive = false; });
    scrollbarPainter!.updateColors(
      _thumbColor.resolve(_states),
      _trackColor.resolve(_states),
      _trackBorderColor.resolve(_states),
    );
  }

  void maybeHovering(PointerHoverEvent event) {
    if (scrollbarPainterKey.currentContext == null) {
      return;
    }

    final CustomPaint customPaint = scrollbarPainterKey.currentContext!.widget as CustomPaint;
    final ScrollbarPainter painter = customPaint.foregroundPainter! as ScrollbarPainter;
    final RenderBox renderBox = scrollbarPainterKey.currentContext!.findRenderObject()! as RenderBox;
    final Offset localOffset = renderBox.globalToLocal(event.position);
    final bool onScrollbar = painter.hitTestInteractive(localOffset);

    // Check is the position of the pointer falls over the painted scrollbar
    if (onScrollbar) {
      // Pointer exited hovering the scrollbar
      setState(() { _hoverIsActive = true; });
      _hoverAnimationController.forward();
    } else {
      // Pointer entered the area of the painted scrollbar
      setState(() { _hoverIsActive = false; });
      _hoverAnimationController.reverse();
    }
  }

  void maybeHoverExit(PointerExitEvent event) {
    setState(() { _hoverIsActive = false; });
    _hoverAnimationController.reverse();
  }

  @override
  void dispose() {
    _hoverAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: handleScrollNotification,
      child: RepaintBoundary(
        child: RawGestureDetector(
          gestures: gestures,
          child: MouseRegion(
            onExit: maybeHoverExit,
            onHover: maybeHovering,
            child: CustomPaint(
              key: scrollbarPainterKey,
              foregroundPainter: scrollbarPainter,
              child: RepaintBoundary(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

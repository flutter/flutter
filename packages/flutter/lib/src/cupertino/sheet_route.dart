// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'interface_level.dart';

/// Value extracted from the official sketch iOS UI kit
/// It is the top offset that will be displayed from the bottom route
const double _kPreviousRouteVisibleOffset = 10.0;

/// Value extracted from the official sketch iOS UI kit
const Radius _kCupertinoSheetTopRadius = Radius.circular(10.0);

/// Estimated Round corners for iPhone X, XR, 11, 11 Pro
/// https://kylebashour.com/posts/finding-the-real-iphone-x-corner-radius
/// It used to animate the bottom route with a top radius that matches
/// the frame radius. If the device doesn't have round corners it will use
/// Radius.zero
const Radius _kRoundedDeviceRadius = Radius.circular(38.5);

/// Minimal distance from the top of the screen to the top of the previous route
/// It will be used ff the top safearea is less than this value.
/// In iPhones the top SafeArea is more or equal to this distance.
const double _kSheetMinimalOffset = 10;

/// Value extracted from the official sketch iOS UI kit for iPhone X, XR, 11, 11 Pro
/// The status bar height is bigger for devices with rounded corners, this is
/// used to detect if an iPhone has round corners or not
const double _kRoundedDeviceStatusBarHeight = 20;

const Color _kBarrierColor = Color.fromRGBO(0, 0, 0, 0.20);

const Curve _kCupertinoSheetCurve = Curves.easeOut;

/// Wraps the child into a cupertino modal sheet appareance. This is used to
/// create a [SheetRoute].
///
/// Clip the child widget to rectangle with top rounded corners and adds
/// top padding and top safe area.
class _CupertinoSheetDecorationBuilder extends StatelessWidget {
  const _CupertinoSheetDecorationBuilder({
    Key? key,
    required this.child,
    required this.topRadius,
    this.backgroundColor,
  }) : super(key: key);

  /// The child contained by the modal sheet
  final Widget child;

  /// The color to paint behind the child
  final Color? backgroundColor;

  /// The top corners of this modal sheet are rounded by this Radius
  final Radius topRadius;

  @override
  Widget build(BuildContext context) {
    // TODO(jamesblasco): Implement landscape mode
    final double paddingTop = math.max(10, MediaQuery.of(context)?.padding.top ?? 0);
    return CupertinoUserInterfaceLevel(
      data: CupertinoUserInterfaceLevelData.elevated,
      child: Builder(
        builder: (BuildContext context) => Padding(
          padding: EdgeInsets.only(top: _kPreviousRouteVisibleOffset + paddingTop),
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: topRadius),
              color: backgroundColor ??
                  CupertinoColors.systemBackground.resolveFrom(
                    context,
                    nullOk: true,
                  ),
            ),
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class CupertinoSheetRoute<T> extends SheetRoute<T> {
  CupertinoSheetRoute({
    required WidgetBuilder builder,
    List<double>? stops,
    double initialStop = 1,
    RouteSettings? settings,
    Color? backgroundColor,
  }) : super(
          builder: (BuildContext context) {
            return _CupertinoSheetDecorationBuilder(
              child: Builder(
                builder: (BuildContext context) {
                  return builder(context);
                },
              ),
              backgroundColor: backgroundColor,
              topRadius: _kCupertinoSheetTopRadius,
            );
          },
          settings: settings,
          animationCurve: _kCupertinoSheetCurve,
          stops: stops,
          initialStop: initialStop,
        );

  @override
  bool get bounceAtTop => true;

  @override
  bool get draggable => true;

  @override
  bool get expanded => true;

  @override
  Color? get barrierColor => _kBarrierColor;

  @override
  bool get barrierDismissible => false;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final double topPadding = MediaQuery.of(context)!.padding.top;
    final double topOffset = math.max(_kSheetMinimalOffset, topPadding);
    return AnimatedBuilder(
      animation: secondaryAnimation,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double progress = secondaryAnimation.value;
        final double scale = 1 - progress / 10;
        final double distanceWithScale = (topOffset + _kPreviousRouteVisibleOffset) * 0.9;
        final Offset offset = Offset(0, progress * (topOffset - distanceWithScale));
        return Transform.translate(
          offset: offset,
          child: Transform.scale(
            scale: scale,
            child: child,
            alignment: Alignment.topCenter,
          ),
        );
      },
    );
  }

  @override
  Widget getBottomRouteTransition(
      BuildContext context, Animation<double> secondAnimation, Widget child) {
    final Animation<double> delayAnimation = initialStop == 1
        ? secondAnimation
        : CurvedAnimation(
            parent: sheetAnimation!,
            curve: const Interval(0.5, 1, curve: Curves.linear),
          );

    return _CupertinoSheetBottomRouteTransition(
      body: child,
      secondaryAnimation: delayAnimation,
    );
  }
}

/// Animation for previous route when a [CupertinoSheetRoute] enters/exits
class _CupertinoSheetBottomRouteTransition extends StatelessWidget {
  
  const _CupertinoSheetBottomRouteTransition({
    Key? key,
    required this.secondaryAnimation,
    required this.body,
  }) : super(key: key);

  final Widget body;

  final Animation<double> secondaryAnimation;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context)!.padding.top;
    final double topOffset = math.max(_kSheetMinimalOffset, topPadding);

    final bool isRoundedDevice =
        defaultTargetPlatform == TargetPlatform.iOS && topPadding > _kRoundedDeviceStatusBarHeight;
    final Radius deviceCorner = isRoundedDevice ? _kRoundedDeviceRadius : Radius.zero;

    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: _kCupertinoSheetCurve,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AnimatedBuilder(
        animation: curvedAnimation,
        child: body,
        builder: (BuildContext context, Widget? child) {
          final double progress = curvedAnimation.value;
          final double scale = 1 - progress / 10;
          final Radius radius = progress == 0
              ? Radius.zero
              : Radius.lerp(deviceCorner, _kCupertinoSheetTopRadius, progress)!;
          return Stack(
            children: <Widget>[
              Container(color: CupertinoColors.black),
              // TODO(jamesblasco): Add ColorFilter based on CupertinoUserInterfaceLevelData
              // https://github.com/jamesblasco/modal_bottom_sheet/pull/44/files
              Transform.translate(
                offset: Offset(0, progress * topOffset),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: radius),
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Copied from widgets/sheet_route.dart as is a private method/
/// Re-maps a number from one range to another.
///
/// A value of fromLow would get mapped to toLow, a value of
/// fromHigh to toHigh, values in-between to values in-between, etc
double _mapDoubleInRange(
    double value, double fromLow, double fromHigh, double toLow, double toHigh) {
  final double offset = toLow;
  final double ratio = (toHigh - toLow) / (fromHigh - fromLow);
  return ratio * (value - fromLow) + offset;
}

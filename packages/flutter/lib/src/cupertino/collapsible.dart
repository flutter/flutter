// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

///
library;

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icons.dart';
import 'list_tile.dart';

/// The curve of the animation used to expand or collapse the [CupertinoCollapsible].
///
/// The same curve is used for both expansion and collapse animations.
///
/// Based on iOS 17 manual testing.
const Curve _kAnimationCurve = Curves.easeInOut;

/// The height of the header of the collapsible, which is a [CupertinoListTile].
const double _kHeaderHeight = 44.0;

///
enum CollapsibleTransitionMode {
  ///
  fadeTransition,

  ///
  scrollTransition,
}

///
class CupertinoCollapsible extends StatefulWidget {
  ///
  const CupertinoCollapsible({
    super.key,
    required this.title,
    required this.child,
    this.controller,
    this.transitionMode = CollapsibleTransitionMode.fadeTransition,
  });

  /// A [title] is used to convey the central information. Usually a [Text].
  final Widget title;

  /// If provided, the controller can be used to expand and collapse tiles.
  ///
  /// In cases were control over the tile's state is needed from a callback triggered
  /// by a widget within the tile, [ExpansibleController.of] may be more convenient
  /// than supplying a controller.
  final ExpansibleController? controller;

  /// The body of the collapsible.
  final Widget child;

  ///
  final CollapsibleTransitionMode transitionMode;

  @override
  State<CupertinoCollapsible> createState() => _CupertinoCollapsibleState();
}

class _CupertinoCollapsibleState extends State<CupertinoCollapsible> {
  static final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _quarterTween = Tween<double>(begin: 0.0, end: 0.25);
  final OverlayPortalController _fadeController = OverlayPortalController();
  final GlobalKey _headerKey = GlobalKey();
  late Offset headerOffset;

  late Animation<double> _iconTurns;
  late ExpansibleController _tileController;

  @override
  void initState() {
    super.initState();
    _tileController = widget.controller ?? ExpansibleController();
  }

  Widget? _buildIcon(BuildContext context, Animation<double> animation) {
    _iconTurns = animation.drive(_quarterTween.chain(_easeInTween));
    // Replicate the Icon logic here to get a slightly bolder icon.
    return RotationTransition(
      turns: _iconTurns,
      child: Text.rich(
        TextSpan(
          text: String.fromCharCode(CupertinoIcons.right_chevron.codePoint),
          style: TextStyle(
            inherit: false,
            color: CupertinoColors.activeBlue,
            fontSize: 15.0,
            fontWeight: FontWeight.w900,
            fontFamily: CupertinoIcons.right_chevron.fontFamily,
            package: CupertinoIcons.right_chevron.fontPackage,
          ),
        ),
      ),
    );
  }

  void _onHeaderTap() {
    final RenderBox headerBox = _headerKey.currentContext!.findRenderObject()! as RenderBox;
    headerOffset = headerBox.localToGlobal(Offset.zero);
    _fadeController.show();

    if (_tileController.isExpanded) {
      _tileController.collapse();
    } else {
      _tileController.expand();
    }
  }

  Widget _buildHeader(BuildContext context, Animation<double> animation) {
    return CupertinoListTile(
      key: _headerKey,
      onTap: _onHeaderTap,
      title: widget.title,
      trailing: _buildIcon(context, animation),
      padding: const EdgeInsets.only(right: 20.0),
      backgroundColorActivated: CupertinoColors.transparent,
    );
  }

  Widget _buildCollapsible(
    BuildContext context,
    Widget header,
    Widget body,
    Animation<double> animation,
  ) {
    final Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        header,
        Opacity(
          opacity:
              animation.isAnimating &&
                      widget.transitionMode == CollapsibleTransitionMode.fadeTransition
                  ? 0.0
                  : 1.0,
          child: body,
        ),
      ],
    );

    if (widget.transitionMode == CollapsibleTransitionMode.scrollTransition) {
      return child;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return OverlayPortal(
          controller: _fadeController,
          overlayChildBuilder: (BuildContext context) {
            return Positioned(
              top: headerOffset.dy + _kHeaderHeight,
              left: headerOffset.dx,
              child: ConstrainedBox(
                constraints: constraints,
                child: Visibility(
                  visible: animation.isAnimating,
                  child: FadeTransition(opacity: animation, child: widget.child),
                ),
              ),
            );
          },
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expansible(
      controller: _tileController,
      curve: _kAnimationCurve,
      headerBuilder: _buildHeader,
      bodyBuilder: (BuildContext context, Animation<double> animation) => widget.child,
      expansibleBuilder: _buildCollapsible,
    );
  }
}

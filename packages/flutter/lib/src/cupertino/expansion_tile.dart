// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
///
/// @docImport 'list_section.dart';
library;

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icons.dart';
import 'list_tile.dart';
import 'theme.dart';

/// The curve of the animation used to expand or collapse the
/// [CupertinoExpansionTile].
///
/// Eyeballed from an iPhone 15 simulator running iOS 17.5.
const Curve _kAnimationCurve = Curves.easeInOut;

/// The duration of the animation used to expand or collapse the
/// [CupertinoExpansionTile].
///
/// Eyeballed from an iPhone 15 simulator running iOS 17.5.
const Duration _kAnimationDuration = Duration(milliseconds: 300);

/// The font size of the rotating trailing icon in the header of a
/// [CupertinoExpansionTile].
///
/// Eyeballed from an iPhone 15 simulator running iOS 17.5.
const double _kIconFontSize = 15.0;

/// The height of the header in a [CupertinoExpansionTile], which is the default
/// [CupertinoListTile].
const double _kHeaderHeight = 44.0;

/// Defines how a [CupertinoExpansionTile] should transition its child between
/// its collapsed state and its expanded state.
enum ExpansionTileTransitionMode {
  /// Transition by fading a fully extended [CupertinoExpansionTile.child].
  ///
  /// When the [CupertinoExpansionTile] expands, the child appears fully extended
  /// and fades into view. When the [CupertinoExpansionTile] collapses, the child
  /// remains fully extended and fades out of view.
  fade,

  /// Transition by scrolling [CupertinoExpansionTile.child] under the header.
  ///
  /// When the [CupertinoExpansionTile] expands, the child scrolls from under the
  /// header until it becomes fully extended. When the [CupertinoExpansionTile]
  /// collapses, the child scrolls under the header until it is fully collapsed.
  scroll,
}

/// A single-line [CupertinoListTile] with an expansion arrow icon that expands
/// or collapses the tile to reveal or hide the [child].
///
/// See also:
///
///  * [ExpansionTile], the Material Design equivalent.
///  * [CupertinoListSection], useful for creating an expansion tile [child].
///  * [CupertinoListTile], the header of a [CupertinoExpansionTile].
class CupertinoExpansionTile extends StatefulWidget {
  /// Creates a single-line [CupertinoListTile] with an expansion arrow icon
  /// that expands or collapses the tile to reveal or hide the [child].
  const CupertinoExpansionTile({
    super.key,
    required this.title,
    required this.child,
    this.controller,
    this.transitionMode = ExpansionTileTransitionMode.fade,
  });

  /// A [title] is used to convey the central information. Usually a [Text].
  final Widget title;

  /// Programmatically expands and collapses the [CupertinoExpansionTile].
  ///
  /// In cases where control over the tile's state is needed from a
  /// callback triggered by a widget within the tile, [ExpansibleController.of]
  /// may be more convenient than supplying a controller.
  final ExpansibleController? controller;

  /// The body of the [CupertinoExpansionTile].
  final Widget child;

  /// How the [CupertinoExpansionTile] should transition its child between its
  /// collapsed state and its expanded state.
  ///
  /// Defaults to [ExpansionTileTransitionMode.fade].
  final ExpansionTileTransitionMode transitionMode;

  @override
  State<CupertinoExpansionTile> createState() => _CupertinoExpansionTileState();
}

class _CupertinoExpansionTileState extends State<CupertinoExpansionTile> {
  final GlobalKey _headerKey = GlobalKey();
  final OverlayPortalController _fadeController = OverlayPortalController();
  static final Animatable<double> _quarterTween = Tween<double>(begin: 0.0, end: 0.25);

  late ExpansibleController _tileController;
  late Animation<double> _iconTurns;
  late Offset _headerOffset;

  @override
  void initState() {
    super.initState();
    _tileController = widget.controller ?? ExpansibleController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _tileController.dispose();
    }
    super.dispose();
  }

  Widget? _buildIcon(BuildContext context, Animation<double> animation) {
    _iconTurns = animation.drive(_quarterTween.chain(CurveTween(curve: _kAnimationCurve)));
    final double? size = CupertinoTheme.of(context).textTheme.textStyle.fontSize;
    // Replicate the Icon logic here to get a slightly bolder icon.
    return RotationTransition(
      turns: _iconTurns,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text.rich(
            TextSpan(
              text: String.fromCharCode(CupertinoIcons.right_chevron.codePoint),
              style: TextStyle(
                inherit: false,
                color: CupertinoColors.activeBlue,
                fontSize: _kIconFontSize,
                fontWeight: FontWeight.w900,
                fontFamily: CupertinoIcons.right_chevron.fontFamily,
                package: CupertinoIcons.right_chevron.fontPackage,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onHeaderTap() {
    final RenderBox headerBox = _headerKey.currentContext!.findRenderObject()! as RenderBox;
    _headerOffset = headerBox.localToGlobal(Offset.zero);
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
      backgroundColorActivated: CupertinoColors.transparent,
    );
  }

  Widget _buildExpansible(
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
              animation.isAnimating && widget.transitionMode == ExpansionTileTransitionMode.fade
                  ? 0.0
                  : 1.0,
          child: body,
        ),
      ],
    );

    if (widget.transitionMode == ExpansionTileTransitionMode.scroll) {
      return child;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return OverlayPortal(
          controller: _fadeController,
          overlayChildBuilder: (BuildContext context) {
            return Positioned(
              top: _headerOffset.dy + _kHeaderHeight,
              left: _headerOffset.dx,
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
      duration: _kAnimationDuration,
      curve: _kAnimationCurve,
      headerBuilder: _buildHeader,
      bodyBuilder: (BuildContext context, Animation<double> animation) => widget.child,
      expansibleBuilder: _buildExpansible,
    );
  }
}

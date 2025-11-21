// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
///
/// @docImport 'list_section.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icons.dart';
import 'list_tile.dart';
import 'localizations.dart';
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
const Duration _kAnimationDuration = Duration(milliseconds: 250);

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
/// {@tool dartpad}
/// This example shows how to use [CupertinoExpansionTile] with different transition modes.
///
/// ** See code in examples/api/lib/cupertino/expansion_tile/cupertino_expansion_tile.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [ExpansionTile], the Material Design equivalent.
///  * [CupertinoListSection], useful for creating an expansion tile [child].
///  * [CupertinoListTile], the header of a [CupertinoExpansionTile].
///  * <https://developer.apple.com/design/human-interface-guidelines/disclosure-controls/>
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

  /// Used to convey the central information.
  ///
  /// Usually a [Text].
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

  @override
  void initState() {
    super.initState();
    _tileController = widget.controller ?? ExpansibleController();
  }

  @override
  void didUpdateWidget(CupertinoExpansionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller == null) {
        _tileController.dispose();
      }
      _tileController = widget.controller ?? ExpansibleController();
    }
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
    return RotationTransition(
      turns: _iconTurns,
      child: SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Icon(
            CupertinoIcons.right_chevron,
            color: CupertinoColors.activeBlue,
            size: _kIconFontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  void _onHeaderTap() {
    if (_tileController.isExpanded) {
      _tileController.collapse();
    } else {
      _tileController.expand();
    }
    _fadeController.show();
  }

  Widget _buildHeader(BuildContext context, Animation<double> animation) {
    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);
    final String onTapHint = _tileController.isExpanded
        ? localizations.expansionTileExpandedTapHint
        : localizations.expansionTileCollapsedTapHint;
    String? semanticsHint;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        semanticsHint = _tileController.isExpanded
            ? '${localizations.collapsedHint}\n ${localizations.expansionTileExpandedHint}'
            : '${localizations.expandedHint}\n ${localizations.expansionTileCollapsedHint}';
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        break;
    }
    return Semantics(
      hint: semanticsHint,
      onTapHint: onTapHint,
      child: CupertinoListTile(
        key: _headerKey,
        onTap: _onHeaderTap,
        title: widget.title,
        trailing: _buildIcon(context, animation),
        backgroundColorActivated: CupertinoColors.transparent,
      ),
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
        if (animation.isAnimating && widget.transitionMode == ExpansionTileTransitionMode.fade)
          Opacity(opacity: 0.0, child: body)
        else
          body,
      ],
    );
    if (widget.transitionMode == ExpansionTileTransitionMode.scroll) {
      return child;
    }
    assert(widget.transitionMode == ExpansionTileTransitionMode.fade);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return OverlayPortal(
          controller: _fadeController,
          overlayChildBuilder: (BuildContext context) {
            final BuildContext headerContext = _headerKey.currentContext!;
            final RenderBox overlay =
                Overlay.of(headerContext).context.findRenderObject()! as RenderBox;
            final RenderBox headerBox = headerContext.findRenderObject()! as RenderBox;
            final Offset headerOffset = headerBox.localToGlobal(Offset.zero, ancestor: overlay);
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
      duration: _kAnimationDuration,
      curve: _kAnimationCurve,
      headerBuilder: _buildHeader,
      bodyBuilder: (BuildContext context, Animation<double> animation) => widget.child,
      expansibleBuilder: _buildExpansible,
    );
  }
}

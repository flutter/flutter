// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

///
library;

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'list_tile.dart';

/// The curve of the animation used to expand or collapse the [CupertinoCollapsible].
///
/// The same curve is used for both expansion and collapse animations.
///
/// Based on iOS 17 manual testing.
const Curve _kCupertinoCollapsibleAnimationCurve = Curves.easeInOut;

///
class CupertinoCollapsible extends StatefulWidget {
  ///
  const CupertinoCollapsible({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.additionalInfo,
    this.leading,
    this.trailing,
    this.controller,
    this.backgroundColor,
    this.backgroundColorActivated,
    this.padding,
  });

  /// A [title] is used to convey the central information. Usually a [Text].
  final Widget title;

  /// A [subtitle] is used to display additional information. It is located
  /// below [title]. Usually a [Text] widget.
  final Widget? subtitle;

  /// Similar to [subtitle], an [additionalInfo] is used to display additional
  /// information. However, instead of being displayed below [title], it is
  /// displayed on the right, before [trailing]. Usually a [Text] widget.
  final Widget? additionalInfo;

  /// A widget displayed at the start of the [CupertinoListTile]. This is
  /// typically an `Icon` or an `Image`.
  final Widget? leading;

  /// A widget displayed at the end of the [CupertinoListTile]. This is usually
  /// a right chevron icon (e.g. `CupertinoListTileChevron`), or an `Icon`.
  final Widget? trailing;

  /// The [backgroundColor] of the tile in normal state. Once the tile is
  /// tapped, the background color switches to [backgroundColorActivated]. It is
  /// set to match the iOS look by default.
  final Color? backgroundColor;

  /// The [backgroundColorActivated] is the background color of the tile after
  /// the tile was tapped. It is set to match the iOS look by default.
  final Color? backgroundColorActivated;

  /// Padding of the content inside [CupertinoListTile].
  final EdgeInsetsGeometry? padding;

  /// If provided, the controller can be used to expand and collapse tiles.
  ///
  /// In cases were control over the tile's state is needed from a callback triggered
  /// by a widget within the tile, [ExpansibleController.of] may be more convenient
  /// than supplying a controller.
  final ExpansibleController? controller;

  /// The body of the collapsible.
  final Widget child;

  @override
  State<CupertinoCollapsible> createState() => _CupertinoCollapsibleState();
}

class _CupertinoCollapsibleState extends State<CupertinoCollapsible> {
  static final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _quarterTween = Tween<double>(begin: 0.0, end: 0.25);

  late Animation<double> _iconTurns;

  late ExpansibleController _tileController;

  @override
  void initState() {
    super.initState();
    _tileController = widget.controller ?? ExpansibleController();
  }

  Widget? _buildIcon(BuildContext context, Animation<double> animation) {
    _iconTurns = animation.drive(_quarterTween.chain(_easeInTween));
    return RotationTransition(
      turns: _iconTurns,
      child: const CupertinoListTileChevron(color: CupertinoColors.activeBlue),
    );
  }

  Widget _buildHeader(BuildContext context, Animation<double> animation) {
    return CupertinoListTile(
      onTap: _tileController.isExpanded ? _tileController.collapse : _tileController.expand,
      leading: widget.leading,
      title: widget.title,
      subtitle: widget.subtitle,
      additionalInfo: widget.additionalInfo,
      trailing: widget.trailing ?? _buildIcon(context, animation),
      padding: widget.padding,
      backgroundColor: widget.backgroundColor,
      backgroundColorActivated: widget.backgroundColorActivated,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expansible(
      controller: _tileController,
      curve: _kCupertinoCollapsibleAnimationCurve,
      headerBuilder: _buildHeader,
      bodyBuilder: (BuildContext context, Animation<double> animation) => widget.child,
    );
  }
}

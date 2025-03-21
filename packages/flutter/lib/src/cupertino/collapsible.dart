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
const Curve _kCupertinoCollapsibleAnimationCurve = Curves.easeInOut;

///
class CupertinoCollapsible extends StatefulWidget {
  ///
  const CupertinoCollapsible({
    super.key,
    required this.title,
    required this.child,
    this.controller,
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

  Widget _buildHeader(BuildContext context, Animation<double> animation) {
    return CupertinoListTile(
      onTap: _tileController.isExpanded ? _tileController.collapse : _tileController.expand,
      title: widget.title,
      trailing: _buildIcon(context, animation),
      padding: const EdgeInsets.only(right: 20.0),
      backgroundColorActivated: CupertinoColors.transparent,
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

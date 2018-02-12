// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'scrollbar.dart';

// TODO(abarth): These constants probably belong somewhere more general.

const TextStyle _kCupertinoDialogTitleStyle = const TextStyle(
  fontFamily: '.SF UI Display',
  inherit: false,
  fontSize: 17.5,
  fontWeight: FontWeight.w600,
  color: CupertinoColors.black,
  height: 1.25,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kCupertinoDialogContentStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 12.4,
  fontWeight: FontWeight.w500,
  color: CupertinoColors.black,
  height: 1.35,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kCupertinoDialogActionStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 16.8,
  fontWeight: FontWeight.w400,
  color: CupertinoColors.activeBlue,
  textBaseline: TextBaseline.alphabetic,
);

const double _kCupertinoDialogWidth = 270.0;
const BoxDecoration _kCupertinoDialogFrontFillDecoration = const BoxDecoration(
  color: const Color(0xCCFFFFFF),
);
const BoxDecoration _kCupertinoDialogBackFill = const BoxDecoration(
  color: const Color(0x77FFFFFFF),
);

/// An iOS-style dialog.
///
/// This dialog widget does not have any opinion about the contents of the
/// dialog. Rather than using this widget directly, consider using
/// [CupertinoAlertDialog], which implement a specific kind of dialog.
///
/// Push with `Navigator.of(..., rootNavigator: true)` when using with
/// [CupertinoTabScaffold] to ensure that the dialog appears above the tabs.
///
/// See also:
///
///  * [CupertinoAlertDialog], which is a dialog with title, contents, and
///    actions.
///  * <https://developer.apple.com/ios/human-interface-guidelines/views/alerts/>
class CupertinoDialog extends StatelessWidget {
  /// Creates an iOS-style dialog.
  const CupertinoDialog({
    Key key,
    this.child,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new ClipRRect(
        borderRadius: const BorderRadius.all(const Radius.circular(12.0)),
        child: new DecoratedBox(
          // To get the effect, 2 white fills are needed. One blended with the
          // background before applying the blur and one overlaid on top of
          // the blur.
          decoration: _kCupertinoDialogBackFill,
          child: new BackdropFilter(
            filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: new Container(
              width: _kCupertinoDialogWidth,
              decoration: _kCupertinoDialogFrontFillDecoration,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// An iOS-style alert dialog.
///
/// An alert dialog informs the user about situations that require
/// acknowledgement. An alert dialog has an optional title and an optional list
/// of actions. The title is displayed above the content and the actions are
/// displayed below the content.
///
/// Typically passed as the child widget to [showDialog], which displays the
/// dialog.
///
/// See also:
///
///  * [CupertinoDialog], which is a generic iOS-style dialog.
///  * <https://developer.apple.com/ios/human-interface-guidelines/views/alerts/>
class CupertinoAlertDialog extends StatelessWidget {
  /// Creates an iOS-style alert dialog.
  const CupertinoAlertDialog({
    Key key,
    this.title,
    this.content,
    this.actions,
    this.scrollController,
  }) : super(key: key);

  /// The (optional) title of the dialog is displayed in a large font at the top
  /// of the dialog.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// The (optional) content of the dialog is displayed in the center of the
  /// dialog in a lighter font.
  ///
  /// Typically a [Text] widget.
  final Widget content;

  /// The (optional) set of actions that are displayed at the bottom of the
  /// dialog.
  ///
  /// Typically this is a list of [CupertinoDialogAction] widgets.
  final List<Widget> actions;

  /// A scroll controller that can be used to control the scrolling of the message
  /// in the dialog.
  ///
  /// Defaults to null, and is typically not needed, since most alert messages are short.
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    const double edgePadding = 20.0;
    final List<Widget> titleContentGroup = <Widget>[];
    if (title != null) {
      titleContentGroup.add(new Padding(
        padding: new EdgeInsets.only(
          left: edgePadding,
          right: edgePadding,
          bottom: content == null ? edgePadding : 1.0,
          top: edgePadding,
        ),
        child: new DefaultTextStyle(
          style: _kCupertinoDialogTitleStyle,
          textAlign: TextAlign.center,
          child: title,
        ),
      ));
    }

    if (content != null) {
      titleContentGroup.add(
        new Padding(
          padding: new EdgeInsets.only(
            left: edgePadding,
            right: edgePadding,
            bottom: edgePadding,
            top: title == null ? edgePadding : 1.0,
          ),
          child: new DefaultTextStyle(
            style: _kCupertinoDialogContentStyle,
            textAlign: TextAlign.center,
            child: content,
          ),
        ),
      );
    }

    final List<Widget> children = <Widget>[];
    if (titleContentGroup.isNotEmpty) {
      children.add(
        new Flexible(
          child: new CupertinoScrollbar(
            child: new ListView(
              controller: scrollController,
              shrinkWrap: true,
              children: titleContentGroup,
            ),
          ),
        ),
      );
    }

    if (actions != null) {
      children.add(new _CupertinoButtonBar(
        children: actions,
      ));
    }

    return new Padding(
      padding: const EdgeInsets.symmetric(vertical: edgePadding),
      child: new CupertinoDialog(
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// A button typically used in a [CupertinoAlertDialog].
///
/// See also:
///
///  * [CupertinoAlertDialog], a dialog that informs the user about situations
///    that require acknowledgement
class CupertinoDialogAction extends StatelessWidget {
  /// Creates an action for an iOS-style dialog.
  const CupertinoDialogAction({
    this.onPressed,
    this.isDefaultAction: false,
    this.isDestructiveAction: false,
    @required this.child,
  }) : assert(child != null);

  /// The callback that is called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback onPressed;

  /// Set to true if button is the default choice in the dialog.
  ///
  /// Default buttons are bold.
  final bool isDefaultAction;

  /// Whether this action destroys an object.
  ///
  /// For example, an action that deletes an email is destructive.
  final bool isDestructiveAction;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget.
  final Widget child;

  /// Whether the button is enabled or disabled. Buttons are disabled by default. To
  /// enable a button, set its [onPressed] property to a non-null value.
  bool get enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    TextStyle style = _kCupertinoDialogActionStyle;

    if (isDefaultAction) {
      style = style.copyWith(fontWeight: FontWeight.w600);
    }

    if (isDestructiveAction) {
      style = style.copyWith(color: CupertinoColors.destructiveRed);
    }

    if (!enabled) {
      style = style.copyWith(color: style.color.withOpacity(0.5));
    }

    final double textScaleFactor = MediaQuery.of(context, nullOk: true)?.textScaleFactor ?? 1.0;
    return new GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: new Container(
        alignment: Alignment.center,
        padding: new EdgeInsets.all(10.0 * textScaleFactor),
        child: new DefaultTextStyle(
          style: style,
          child: child,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

const double _kButtonBarHeight = 45.0;

// This color isn't correct. Instead, we should carve a hole in the dialog and
// show more of the background.
const Color _kButtonDividerColor = const Color(0xFFD5D5D5);

class _CupertinoButtonBar extends StatelessWidget {
  const _CupertinoButtonBar({
    Key key,
    this.children,
  }) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = <Widget>[];

    for (Widget child in children) {
      // TODO(abarth): Listen for the buttons being highlighted.
      // TODO(gspencer): These buttons don't lay out in the same way as iOS.
      // When they get wide, they should stack vertically instead of in a row.
      // When they get really big, the vertically-stacked buttons should scroll
      // (separately from the top message).
      buttons.add(new Expanded(child: child));
    }

    return new CustomPaint(
      painter: new _CupertinoButtonBarPainter(children.length),
      child: new UnconstrainedBox(
        constrainedAxis: Axis.horizontal,
        child: new ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _kButtonBarHeight),
          child: new Row(children: buttons),
        ),
      ),
    );
  }
}

class _CupertinoButtonBarPainter extends CustomPainter {
  _CupertinoButtonBarPainter(this.count);

  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()
      ..color = _kButtonDividerColor;

    canvas.drawLine(Offset.zero, new Offset(size.width, 0.0), paint);
    for (int i = 1; i < count; ++i) {
      // TODO(abarth): Hide the divider when one of the adjacent buttons is
      // highlighted.
      final double x = size.width * i / count;
      canvas.drawLine(new Offset(x, 0.0), new Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_CupertinoButtonBarPainter other) => count != other.count;
}

// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// TODO(abarth): These constants probably belong somewhere more general.

const TextStyle _kCupertinoDialogTitleStyle = const TextStyle(
  fontFamily: '.SF UI Display',
  inherit: false,
  fontSize:  17.0,
  fontWeight: FontWeight.w600,
  color: const Color(0xFF000000),
  height: 1.35,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kCupertinoDialogContentStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize:  12.0,
  fontWeight: FontWeight.w400,
  color: const Color(0xFF000000),
  height: 1.35,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kCupertinoDialogActionStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize:  16.0,
  fontWeight: FontWeight.w400,
  color: const Color(0xFF027AFF),
  textBaseline: TextBaseline.alphabetic,
);

const double _kCupertinoDialogWidth = 270.0;
const BoxDecoration _kCupertinoDialogDecoration = const BoxDecoration(
  // TODO(abarth): Rather than being opaque, this decoration should actually be
  // partially transparent and have a subtle background blur effect.
  backgroundColor: const Color(0xFFF8F8F8),
  borderRadius: const BorderRadius.all(const Radius.circular(15.0)),
);

/// An iOS-style dialog.
///
/// This dialog widget does not have any opinion about the contents of the
/// dialog. Rather than using this widget directly, consider using
/// [CupertinoAlertDialog], which implement a specific kind of dialog.
///
/// See also:
///
///  * [CupertinoAlertDialog], which is a dialog with title, contents, and
///    actions.
///  * <https://developer.apple.com/ios/human-interface-guidelines/ui-views/alerts/>
class CupertinoDialog extends StatelessWidget {
  /// Creates an iOS-style dialog.
  CupertinoDialog({
    Key key,
    this.child,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Container(
        margin: const EdgeInsets.all(10.0),
        width: _kCupertinoDialogWidth,
        decoration: _kCupertinoDialogDecoration,
        child: child,
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
///  * <https://developer.apple.com/ios/human-interface-guidelines/ui-views/alerts/>
class CupertinoAlertDialog extends StatelessWidget {
  /// Creates an iOS-style alert dialog.
  CupertinoAlertDialog({
    Key key,
    this.title,
    this.content,
    this.actions,
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];

    children.add(const SizedBox(height: 20.0));

    if (title != null) {
      children.add(new Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 12.0),
        child: new DefaultTextStyle(
          style: _kCupertinoDialogTitleStyle,
          textAlign: TextAlign.center,
          child: title,
        ),
      ));
    }

    if (content != null) {
      children.add(new Flexible(
        fit: FlexFit.loose,
        child: new Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: new DefaultTextStyle(
            style: _kCupertinoDialogContentStyle,
            textAlign: TextAlign.center,
            child: content,
          ),
        ),
      ));
    }

    children.add(const SizedBox(height: 20.0));

    if (actions != null) {
      children.add(new _CupertinoButtonBar(
        children: actions,
      ));
    }

    return new CupertinoDialog(
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

const Color _kDestructiveActionColor = const Color(0xFFFF3B30);

/// A button typically used in a [CupertinoAlertDialog].
///
/// See also:
///
///  * [CupertinoAlertDialog]
class CupertinoDialogAction extends StatelessWidget {
  /// Creates an action for an iOS-style dialog.
  CupertinoDialogAction({
    this.onPressed,
    this.isDestructive: false,
    @required this.child,
  }) {
    assert(child != null);
  }

  /// The callback that is called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback onPressed;

  /// Whether this action destroys an object.
  ///
  /// For example, an action that deletes an email is destructive.
  final bool isDestructive;

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

    if (isDestructive)
      style = style.copyWith(color: _kDestructiveActionColor);

    if (!enabled)
      style = style.copyWith(color: style.color.withOpacity(0.5));

    return new GestureDetector(
      onTap: onPressed,
      child: new Center(
        child: new DefaultTextStyle(
          style: style,
          child: child,
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
  _CupertinoButtonBar({
    Key key,
    this.children,
  }) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = <Widget>[];

    for (Widget child in children) {
      // TODO(abarth): Listen for the buttons being highlighted.
      buttons.add(new Expanded(child: child));
    }

    return new CustomPaint(
      painter: new _CupertinoButtonBarPainter(children.length),
      child: new SizedBox(
        height: _kButtonBarHeight,
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buttons
        ),
      )
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

    canvas.drawLine(Point.origin, new Point(size.width, 0.0), paint);
    for (int i = 1; i < count; ++i) {
      // TODO(abarth): Hide the divider when one of the adjacent buttons is
      // highlighted.
      final double x = size.width * i / count;
      canvas.drawLine(new Point(x, 0.0), new Point(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_CupertinoButtonBarPainter other) => count != other.count;
}

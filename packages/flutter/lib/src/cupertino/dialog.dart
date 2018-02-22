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

const double _edgePadding = 20.0;

const double _kButtonBarHeight = 45.0;

// This color isn't correct. Instead, we should carve a hole in the dialog and
// show more of the background.
const Color _kButtonDividerColor = const Color(0xFFD5D5D5);

bool _shouldLayoutActionsVertical(int count) {
  return (count > 2);
}


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

    final Widget titleSection = new _CupertinoAlertTitleSection(title: title, content: content);
    if (titleSection != null) {
      children.add(titleSection);
    }
    
    //add padding between the sections
    children.add(const Padding(padding: const EdgeInsets.only(top: 8.0)));
    
    final Widget actionSection = new _CupertinoAlertActionSection(children: actions);
    if (actionSection != null) {
      children.add(actionSection);
    }

    return new Padding(
      padding: const EdgeInsets.symmetric(vertical: _edgePadding),
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

/// Constructs a text content section typically used in a [CupertinoAlertDialog].
///
/// If Title is missing, then only message is added.  If Message is
/// missing, then only Title is added. If both are missing, then it returns
/// null.
class _CupertinoAlertTitleSection extends StatelessWidget {
  const _CupertinoAlertTitleSection({
    Key key,
    this.title,
    this.content,
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

  /// A scroll controller that can be used to control the scrolling of the message
  /// in the dialog.
  ///
  /// Defaults to null, and is typically not needed, since most alert messages are short.
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final List<Widget> titleContentGroup = <Widget>[];
    if (title != null) {
      titleContentGroup.add(new Padding(
        padding: new EdgeInsets.only(
          left: _edgePadding,
          right: _edgePadding,
          bottom: content == null ? _edgePadding : 1.0,
          top: _edgePadding,
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
            left: _edgePadding,
            right: _edgePadding,
            bottom: _edgePadding,
            top: title == null ? _edgePadding : 1.0,
          ),
          child: new DefaultTextStyle(
            style: _kCupertinoDialogContentStyle,
            textAlign: TextAlign.center,
            child: content,
          ),
        ),
      );
    }

    if (titleContentGroup.isEmpty) {
      return null;
    }

    return new Flexible(flex: 3,
      child: new CupertinoScrollbar(
        child: new ListView(
          controller: scrollController,
          shrinkWrap: true,
          children: titleContentGroup,
        ),
      ),
    );
  }
}


/// A Action Items section typically used in a [CupertinoAlertDialog].
///
/// If only two or less action are present, they are laid out horizontally. If
/// more than two actions are present, they are laid out vertically in a single
/// column. If there isn't enough room to show all the buttons, they are
/// wrapped in a [CupertinoScrollbar] widget. If children is null or empty,
/// it returns null.
class _CupertinoAlertActionSection extends StatelessWidget {
  const _CupertinoAlertActionSection({
    Key key,
    this.children,
    this.scrollController,
  }) : super(key: key);

  final List<Widget> children;

  /// A scroll controller that can be used to control the scrolling of the message
  /// in the dialog.
  ///
  /// Defaults to null, and is typically not needed, since most alert messages are short.
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (children == null || children.isEmpty) {
      return null;
    }

    final List<Widget> buttons = <Widget>[];

    for (Widget child in children) {
      // TODO(abarth): Listen for the buttons being highlighted.
      buttons.add(new Expanded(child: child));
    }

    if (_shouldLayoutActionsVertical(children.length)) {
      return new Flexible (flex: 1,
          child: new CupertinoScrollbar(
            child: new ListView(
              controller: scrollController, //TODO(ekbiker): disable scroll when all content is shown
              shrinkWrap: true,
              children: <Widget>[
                new CustomPaint(
                  painter: new _CupertinoVerticalActionPainter(buttons.length),
                  child: new ConstrainedBox(
                    constraints: new BoxConstraints(maxHeight: _kButtonBarHeight * buttons.length),
                    child: new Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: buttons
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } else {
      return new CustomPaint(
        painter: new _CupertinoHorizontalActionPainter(children.length),
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
}

/// A CustomPainter to draw the divider lines.
///
/// Draws the divider lines, used when the layout is horizontal.
class _CupertinoHorizontalActionPainter extends CustomPainter {
  _CupertinoHorizontalActionPainter(this.count);

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
  bool shouldRepaint(_CupertinoHorizontalActionPainter other) => count != other.count;
}

/// A CustomPainter to draw the divider lines.
///
/// Draws the divider lines, used when the layout is vertical.
class _CupertinoVerticalActionPainter extends CustomPainter {
  _CupertinoVerticalActionPainter(this.count);

  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()
      ..color = _kButtonDividerColor;

    //skip the last one so there's no divider at the very top of the list
    for (int i = 1; i < count; ++i) {
      final double y = size.height * i / count;
      canvas.drawLine(new Offset(0.0, y), new Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_CupertinoVerticalActionPainter other) => count != other.count;
}
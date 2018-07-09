// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show ImageFilter;
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'scrollbar.dart';

const TextStyle _kCupertinoActionSheetActionTextStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 20.0,
  fontWeight: FontWeight.w400,
  color: CupertinoColors.activeBlue,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kCupertinoActionSheetMessageTextStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 13.0,
  fontWeight: FontWeight.w600,
  color: CupertinoColors.black,
  //color: _kCupertinoActionSheetContentTextColor,
  textBaseline: TextBaseline.alphabetic,
);

//Figure out what this should actually be!
const TextStyle _kCupertinoActionSheetTitleTextStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 13.0,
  fontWeight: FontWeight.w800,
  color: CupertinoColors.black,
  //color: _kCupertinoActionSheetContentTextColor,
  textBaseline: TextBaseline.alphabetic,
);

const Color _kCupertinoActionSheetContentTextColor = const Color(0x8F8F8F);
const Color _kSelectedColor = const Color(0x8F8F8F);

const double _kEdgePadding = 14.0;
const double _kButtonHeight = 56.0;

const BoxDecoration _kCupertinoDialogFrontFillDecoration = const BoxDecoration(
  //color: CupertinoColors.white,
  color: const Color(0xccffffff),
);
const BoxDecoration _kCupertinoDialogBackFill = const BoxDecoration(
  color: const Color(0x77ffffff),
);

/// An iOS-style action sheet. ADD MORE DOC HERE
class ActionSheet extends StatelessWidget {
  /// Creates an iOS-style action sheet; ADD MORE DOC HERE
  ActionSheet({
    Key key,
    this.title,
    this.message,
    @required this.actions,
    this.messageScrollController,
    this.actionScrollController,
    this.cancelCallback,
  })  : assert(actions != null),
        assert(actions.length >= 2),
        super(key: key);

  /// The optional title of the action sheet, which is displayed in a larger
  /// font at the top of the action sheet.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// The optional descriptive message that provides more details about the
  /// reason for the alert.
  ///
  /// Typically a [Text] widget.
  final Widget message;

  /// The set of actions that are displayed for the user to select.
  ///
  /// Typically this is a list of [ActionSheetAction] widgets. This attribute
  /// must not be null and must have more than one entry. Only one
  /// [ActionSheetAction] widget in this entry can have [isCancelAction]
  /// set to true.
  final List<Widget> actions;

  /// A scroll controller that can be used to control the scrolling of the
  /// [message] in the action sheet.
  ///
  /// This attribute is typically not needed, as alert messages should be
  /// short.
  final ScrollController messageScrollController;

  /// A scroll controller that can be used to control the scrolling of the
  /// [actions] in the action sheet.
  ///
  /// This attribute is typically not needed.
  final ScrollController actionScrollController;

  ///NEEDS DOC
  final VoidCallback cancelCallback;

  @override
  Widget build(BuildContext context) {
    final List<Widget> content = <Widget>[];

    if (title != null || message != null) {
      final Widget titleSection = new _CupertinoActionSheetTitleSection(
        title: title,
        message: message,
        messageScrollController: messageScrollController,
      );
      content.add(new Flexible(child: titleSection));
    }

    content.add(new Flexible(child: new _CupertinoActionSheetActionSection(
      children: actions,
      actionScrollController: actionScrollController,
    )));

    final List<Widget> columnContents = <Widget>[];

    columnContents.add(
      new ConstrainedBox(
        constraints: new BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
        child: new ClipRRect(
          borderRadius: const BorderRadius.all(const Radius.circular(12.0)),
          child: new DecoratedBox(
            decoration: _kCupertinoDialogBackFill,
            child: new BackdropFilter(
              filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: new Container(
                decoration: _kCupertinoDialogFrontFillDecoration,
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (cancelCallback != null) {
      columnContents.add(const Padding(
        padding: const EdgeInsets.only(top: 8.0),
      ));
      columnContents.add(
        new ClipRRect(
          borderRadius: const BorderRadius.all(const Radius.circular(12.0)),
          child: new DecoratedBox(
            decoration: _kCupertinoDialogBackFill,
            child: new BackdropFilter(
              filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: new Container(
                height: _kButtonHeight,
                decoration: _kCupertinoDialogFrontFillDecoration,
                child: new ActionSheetAction(
                  child: const Text('Cancel'),
                  onPressed: cancelCallback,
                  isDefaultAction: true,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return new ConstrainedBox(
      constraints: new BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: columnContents,
          ),
        ),
      ),
    );
  }
}

class _CupertinoActionSheetTitleSection extends StatelessWidget {
  const _CupertinoActionSheetTitleSection({
    Key key,
    this.title,
    this.message,
    this.messageScrollController,
  }) : super(key: key);

  final Widget title;

  final Widget message;

  final ScrollController messageScrollController;

  @override
  Widget build(BuildContext context) {
    final List<Widget> titleSection = <Widget>[];
    if (title != null) {
      titleSection.add(new Padding(
          padding: new EdgeInsets.only(
            top: message == null ? 14.0 : 10.0,
            bottom: message == null ? 14.0 : 0.0, //play with 10.0 value
            left: 40.0,
            right: 40.0,
          ),
          child: new DefaultTextStyle(
            style: message == null ? _kCupertinoActionSheetMessageTextStyle : _kCupertinoActionSheetTitleTextStyle,
            textAlign: TextAlign.center,
            child: title,
          )));
    }

    if (message != null) {
      titleSection.add(new Padding(
          padding: new EdgeInsets.only(
            top: title == null ? 14.0 : 0.0,
            bottom: 14.0, //play with 10.0 value
            left: 40.0,
            right: 40.0,
          ),
          child: new DefaultTextStyle(
            style: _kCupertinoActionSheetMessageTextStyle,
            textAlign: TextAlign.center,
            child: message,
          )));
    }

    if (titleSection.isEmpty) {
      return new SingleChildScrollView(
        controller: messageScrollController,
        child: new Container(
          width: 0.0,
          height: 0.0,
        ),
      );
    }

    if (titleSection.length > 1) {
      titleSection.insert(1, const Padding(padding: const EdgeInsets.only(top: 10.0)));
    }

    return new Container(
      decoration: const BoxDecoration(
          color: CupertinoColors.white,
          border: const Border(
            bottom: const BorderSide(
              width: 1.0,
              color: CupertinoColors.lightBackgroundGray, //CHANGE TO ACTUALLY BE RIGHT
            ),
          )),
      child: new CupertinoScrollbar(
        child: new SingleChildScrollView(
          controller: messageScrollController,
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: titleSection,
          ),
        ),
      ),
    );
  }
}

class _CupertinoActionSheetActionSection extends StatelessWidget {
  const _CupertinoActionSheetActionSection({
    Key key,
    @required this.children,
    this.actionScrollController,
  })  : assert(children != null),
        super(key: key);

  final List<Widget> children;

  final ScrollController actionScrollController;

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = <Widget>[];
    buttons.addAll(
      children.map<Widget>(
        (Widget child) {
          return new ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: _kButtonHeight,
              maxHeight: _kButtonHeight,
            ),
            child: new CustomPaint(
              painter: new _CupertinoVerticalDividerPainter(),
              child: child,
            ),
          );
        },
      ),
    );

    return new CupertinoScrollbar(
      child: new SingleChildScrollView(
        controller: actionScrollController,
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buttons,
        ),
      ),
    );
  }
}

/// A button typically used in an [ActionSheet]. ADD MORE DOC HERE
///
/// See also:
///
///  * [ActionSheet], an alert that presents the user with a set of two or
///    more choices related to the current context.
class ActionSheetAction extends StatefulWidget {
  ///Creates an action for an iOS-style action sheet. ADD MORE DOC HERE
  const ActionSheetAction({
    @required this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    @required this.child,
  })  : assert(child != null),
        assert(onPressed != null);

  /// The callback that is called when the button is tapped.
  ///
  /// This attribute must not be null.
  final VoidCallback onPressed;

  /// Whether this action is the default choice in the action sheet.
  ///
  /// Default buttons have bold text.
  final bool isDefaultAction;

  /// Whether this action might change or delete data.
  ///
  /// Destructive buttons have red text.
  final bool isDestructiveAction;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget.
  final Widget child;

  @override
  _ActionSheetActionState createState() => _ActionSheetActionState();
}

class _ActionSheetActionState extends State<ActionSheetAction> {
  Color _backgroundColor = CupertinoColors.white;

  @override
  Widget build(BuildContext context) {
    TextStyle style = _kCupertinoActionSheetActionTextStyle;

    if (widget.isDefaultAction) {
      style = style.copyWith(fontWeight: FontWeight.w600);
    }

    if (widget.isDestructiveAction) {
      style = style.copyWith(color: CupertinoColors.destructiveRed);
    }

    void _onTapDown(TapDownDetails event) {
      setState(() {
        _backgroundColor = _kSelectedColor;
      });
    }

    void _onTapUp(TapUpDetails event) {
      setState(() {
        _backgroundColor = CupertinoColors.white;
      });
    }

    void _onTapCancel() {
      setState(() {
        _backgroundColor = CupertinoColors.white;
      });
    }

    void _onTap() {
      widget.onPressed;
      Navigator.pop(context); //SHOULD THE ACTION SHEET BE HANDLING THIS?
    }

    return new GestureDetector(
      onTap: _onTap,
      onTapDown: _onTapDown,
      onTapCancel: _onTapCancel,
      onTapUp: _onTapUp,
      behavior: HitTestBehavior.opaque,
      child: new Container(
          color: _backgroundColor,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
          child: new DefaultTextStyle(
            style: style,
            child: widget.child,
            textAlign: TextAlign.center,
          )),
    );
  }
}

// A CustomPainter to draw the divider lines.
//
// Draws the cross-axis divider lines, used when the layout is vertical.
class _CupertinoVerticalDividerPainter extends CustomPainter {
  _CupertinoVerticalDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()..color = CupertinoColors.black; //const Color(0x707070);
    canvas.drawLine(const Offset(0.0, 0.0), new Offset(size.width, 0.0), paint);
  }

  @override
  bool shouldRepaint(_CupertinoVerticalDividerPainter other) => false;
}

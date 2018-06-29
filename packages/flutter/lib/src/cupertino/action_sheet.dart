// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'colors.dart';

const TextStyle _kCupertinoDialogTitleStyle = const TextStyle(
  fontFamily: '.SF UI Display',
  inherit: false,
  fontSize: 18.0,
  fontWeight: FontWeight.w500,
  color: CupertinoColors.black,
  height: 1.06,
  letterSpacing: 0.48,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kCupertinoDialogContentStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 13.4,
  fontWeight: FontWeight.w300,
  color: CupertinoColors.black,
  height: 1.036,
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

/// An iOS-style action sheet.
class ActionSheet extends StatelessWidget {

  /// Creates an iOS-style action sheet;
  const ActionSheet({
    Key key,
    this.title,
    this.message,
    @required this.actions,
  }) : assert(actions != null),
       super(key : key);

  final Widget title;

  final Widget message;

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

/// A button typically used in an [ActionSheet].
///
/// See also:
///
///  * [ActionSheet], an alert that presents the user with a set of two or
///    more choices related to the current context.
class ActionSheetAction extends StatelessWidget {

  ///Creates an action for an iOS-style action sheet.
  const ActionSheetAction({
    this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.isCancelAction = false,
    @required this.child,
  }) : assert(child != null);

  final VoidCallback onPressed;

  final bool isDefaultAction;

  final bool isDestructiveAction;

  final bool isCancelAction;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    TextStyle style = _kCupertinoDialogActionStyle;

    if(isDefaultAction) {
      style = style.copyWith(fontWeight: FontWeight.w600);
    }

    if(isDestructiveAction) {
      style = style.copyWith(color: CupertinoColors.destructiveRed);
    }

    return new GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: new Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8.0),
        child: new DefaultTextStyle(
          style: style,
          child: child,
          textAlign: TextAlign.center,
        )
      ),
    );
  }
}



/*
* It seems like each layer had some Material related logic that are small enough it may not be worth extracting.
* We can take a similar approach but we can recreate them in Cupertino.

We can create a showCupertinoBottomSheet type function that also pushes a PopupRoute type that follows iOS animation speeds.

We don't have to handle the dragging functions in BottomSheet since iOS action sheets are not draggable.

Let's take the transparency logic from the Cupertino dialog classes @matthew-carroll just made.

@xster: Okay, so to confirm, we would no longer be doing any extracting, and would instead be creating a Cupertino
 class modeled after the Material version, looking to the Cupertino dialog classes to find the transparency aspect?

Indeed, let's model the Cupertino version after the Material one (with PopupRoute, animations etc) but the Material code doesn't
have enough non Material code to extract.

Also, let's make the pop-up mechanism non-specific to action sheets since pickers should pop up the same way.
Only the content of the pop-up should be action sheets specific.*/


/*
* Ideas:
*
* Have a ActionSheetAction class that represents one of the "buttons" in the action sheet.
* -action can be destructive: text is red
* -action can be default: text is bold
* -action can be cancel: "separate" action below the other buttons
* -action can be disabled: appears gray and unclickable
*
* Action Sheet consists of:
*
* Title (optional)
* List of buttons/actions
* ^^ this is grouped in a rounded rectangle which is partially transparent
*
* Cancel (optional)
* ^^ if included, this appears as a separate rounded rect below the other rect
*
* An action sheet by definition allows users a choice between two or more options, so users
* must provide at least two ActionSheetAction objects
* */
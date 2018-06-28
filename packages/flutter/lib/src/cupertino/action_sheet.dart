// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

class ActionSheet extends StatelessWidget {

  const ActionSheet({
    Key key,
    this.actions,
  }) : assert(actions != null),
       super(key : key);

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container();
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
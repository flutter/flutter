// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

const String _dialogText =
  "Use dialogs sparingly because they are interruptive. Their sudden appearance "
  "forces users to stop their current task and focus on the dialog content. "
  "Alternatives to dialogs include menus or inline expansion, both of which "
  "maintain the current context.";

class DialogDemo extends StatelessComponent {
  DialogDemo({ Key key }) : super(key: key);

  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return new Dialog(
      title: new Text("This is a Dialog"),
      content: new Text(
        _dialogText,
        style: theme.text.subhead.copyWith(color: theme.text.caption.color)
      ),
      actions: <Widget>[
        new FlatButton(
          child: new Text("CANCEL"),
          onPressed: () { Navigator.pop(context, "CANCEL"); }
        ),
        new FlatButton(
          child: new Text("OK"),
          onPressed: () { Navigator.pop(context, "OK"); }
        )
      ]
    );
  }
}

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'full_screen_dialog_demo.dart';

enum DialogDemoAction {
  cancel,
  discard,
  disagree,
  agree,
}

const String _introText =
  "Use dialogs sparingly because their sudden appearance forces users to stop their "
  "current task and focus on the dialog's content. Alternatives to dialogs include "
  "menus or inline expansion, both of which maintain the current context.";

const String _alertWithoutTitleText = "Discard draft?";

const String _alertWithTitleText =
  "Let Google help apps determine location. This means sending anyonmous location "
  "data to Google, even when no apps are running.";

class DialogDemoItem extends StatelessComponent {
  DialogDemoItem({ Key key, this.icon, this.color, this.text, this.onPressed }) : super(key: key);

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onPressed;

  Widget build(BuildContext context) {
    return new InkWell(
      onTap: onPressed,
      child: new Padding(
        padding: const EdgeDims.symmetric(vertical: 8.0),
        child: new Row(
          justifyContent: FlexJustifyContent.start,
          alignItems: FlexAlignItems.center,
          children: <Widget>[
            new Icon(
              size: 36.0,
              icon: icon,
              color: color
            ),
            new Padding(
              padding: const EdgeDims.only(left: 16.0),
              child: new Text(text)
            )
          ]
        )
      )
    );
  }
}

class DialogDemo extends StatefulComponent {
  DialogDemoState createState() => new DialogDemoState();
}

class DialogDemoState extends State<DialogDemo> {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  void showDemoDialog({ BuildContext context, Dialog dialog }) {
    showDialog(
      context: context,
      child: dialog
    )
    .then((dynamic value) { // The value passed to Navigator.pop() or null.
      if (value != null) {
        scaffoldKey.currentState.showSnackBar(new SnackBar(
          content: new Text('You selected: $value')
        ));
      }
    });
  }

  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle = theme.text.subhead.copyWith(color: theme.text.caption.color);

    return new Scaffold(
      key: scaffoldKey,
      toolBar: new ToolBar(
        center: new Text('Dialogs')
      ),
      body: new ButtonTheme(
        color: ButtonColor.accent,
        child: new Padding(
          padding: const EdgeDims.all(24.0),
          child: new ScrollableViewport(
            child: new Column(
              alignItems: FlexAlignItems.stretch,
              children: <Widget>[
                new Container(
                  child: new Text(
                    _introText,
                    style: dialogTextStyle
                  ),
                  padding: const EdgeDims.only(top: 8.0, bottom: 24.0),
                  margin: const EdgeDims.only(bottom:16.0),
                  decoration: new BoxDecoration(
                    border: new Border(bottom: new BorderSide(color: theme.dividerColor))
                  )
                ),
                new FlatButton(
                  child: new Text('Alert without a title'),
                  onPressed: () {
                    showDemoDialog(
                      context: context,
                      dialog: new Dialog(
                        content: new Text(
                          _alertWithoutTitleText,
                          style: dialogTextStyle
                        ),
                        actions: <Widget>[
                          new FlatButton(
                            child: new Text('CANCEL'),
                            onPressed: () { Navigator.pop(context, DialogDemoAction.cancel); }
                          ),
                          new FlatButton(
                            child: new Text('DISCARD'),
                            onPressed: () { Navigator.pop(context, DialogDemoAction.discard); }
                          )
                        ]
                      )
                    );
                  }
                ),
                new FlatButton(
                  child: new Text('Alert with a title'),
                  onPressed: () {
                    showDemoDialog(
                      context: context,
                      dialog: new Dialog(
                        title: new Text("Use Google's location service?"),
                        content: new Text(
                          _alertWithTitleText,
                          style: dialogTextStyle
                        ),
                        actions: <Widget>[
                          new FlatButton(
                            child: new Text('DISAGREE'),
                            onPressed: () { Navigator.pop(context, DialogDemoAction.disagree); }
                          ),
                          new FlatButton(
                            child: new Text('AGREE'),
                            onPressed: () { Navigator.pop(context, DialogDemoAction.agree); }
                          )
                        ]
                      )
                    );
                  }
                ),
                new FlatButton(
                  child: new Text('Simple Dialog'),
                  onPressed: () {
                    showDemoDialog(
                      context: context,
                      dialog: new Dialog(
                        title: new Text('Set backup account'),
                        content: new Column(
                          children: <Widget>[
                            new DialogDemoItem(
                              icon: Icons.account_circle,
                              color: theme.primaryColor,
                              text: 'username@gmail.com',
                              onPressed: () { Navigator.pop(context, 'username@gmail.com'); }
                            ),
                            new DialogDemoItem(
                              icon: Icons.account_circle,
                              color: theme.primaryColor,
                              text: 'user02@gmail.com',
                              onPressed: () { Navigator.pop(context, 'user02@gmail.com'); }
                            ),
                            new DialogDemoItem(
                              icon: Icons.add_circle,
                              text: 'add account',
                              color: theme.disabledColor
                            )
                          ]
                        )
                      )
                    );
                  }
                ),
                new FlatButton(
                  child: new Text('Confirmation Dialog'),
                  onPressed: () {
                    showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 15, minute: 30)
                    )
                    .then((value) { // The value passed to Navigator.pop() or null.
                      if (value != null) {
                        scaffoldKey.currentState.showSnackBar(new SnackBar(
                          content: new Text('You selected: $value')
                        ));
                      }
                    });
                  }
                ),
                new FlatButton(
                  child: new Text('Fullscreen Dialog'),
                  onPressed: () {
                    Navigator.push(context, new MaterialPageRoute(
                      builder: (BuildContext context) => new FullScreenDialogDemo()
                    ));
                  }
                )
              ]
            )
          )
        )
      )
    );
  }
}

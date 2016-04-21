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

const String _alertWithoutTitleText = "Discard draft?";

const String _alertWithTitleText =
  "Let Google help apps determine location. This means sending anyonmous location "
  "data to Google, even when no apps are running.";

class DialogDemoItem extends StatelessWidget {
  DialogDemoItem({ Key key, this.icon, this.color, this.text, this.onPressed }) : super(key: key);

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return new InkWell(
      onTap: onPressed,
      child: new Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new Icon(
              size: 36.0,
              icon: icon,
              color: color
            ),
            new Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: new Text(text)
            )
          ]
        )
      )
    );
  }
}

class DialogDemo extends StatefulWidget {
  static const String routeName = '/dialog';

  @override
  DialogDemoState createState() => new DialogDemoState();
}

class DialogDemoState extends State<DialogDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void showDemoDialog/*<T>*/({ BuildContext context, Dialog dialog }) {
    showDialog/*<T>*/(
      context: context,
      child: dialog
    )
    .then((dynamic/*=T*/ value) { // The value passed to Navigator.pop() or null.
      if (value != null) {
        _scaffoldKey.currentState.showSnackBar(new SnackBar(
          content: new Text('You selected: $value')
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle = theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text('Dialogs')
      ),
      body: new Block(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 72.0),
        children: <Widget>[
          new RaisedButton(
            child: new Text('ALERT'),
            onPressed: () {
              showDemoDialog/*<DialogDemoAction>*/(
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
          new RaisedButton(
            child: new Text('ALERT WITH TITLE'),
            onPressed: () {
              showDemoDialog/*<DialogDemoAction>*/(
                context: context,
                dialog: new Dialog(
                  title: new Text('Use Google\'s location service?'),
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
          new RaisedButton(
            child: new Text('SIMPLE'),
            onPressed: () {
              showDemoDialog/*<String>*/(
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
          new RaisedButton(
            child: new Text('CONFIRMATION'),
            onPressed: () {
              showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 15, minute: 30)
              )
              .then((TimeOfDay value) { // The value passed to Navigator.pop() or null.
                if (value != null) {
                  _scaffoldKey.currentState.showSnackBar(new SnackBar(
                    content: new Text('You selected: $value')
                  ));
                }
              });
            }
          ),
          new RaisedButton(
            child: new Text('FULLSCREEN'),
            onPressed: () {
              Navigator.push(context, new MaterialPageRoute<DismissDialogAction>(
                builder: (BuildContext context) => new FullScreenDialogDemo()
              ));
            }
          )
        ]
      )
    );
  }
}

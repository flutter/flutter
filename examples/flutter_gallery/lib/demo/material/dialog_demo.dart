// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'full_screen_dialog_demo.dart';

enum DialogDemoAction {
  cancel,
  discard,
  disagree,
  agree,
}

const String _alertWithoutTitleText = 'Discard draft?';

const String _alertWithTitleText =
  'Let Google help apps determine location. This means sending anonymous location '
  'data to Google, even when no apps are running.';

class DialogDemoItem extends StatelessWidget {
  const DialogDemoItem({ Key key, this.icon, this.color, this.text, this.onPressed }) : super(key: key);

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return new SimpleDialogOption(
      onPressed: onPressed,
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Icon(icon, size: 36.0, color: color),
          new Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: new Text(text),
          ),
        ],
      ),
    );
  }
}

class DialogDemo extends StatefulWidget {
  static const String routeName = '/material/dialog';

  @override
  DialogDemoState createState() => new DialogDemoState();
}

class DialogDemoState extends State<DialogDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    final DateTime now = new DateTime.now();
    _selectedTime = new TimeOfDay(hour: now.hour, minute: now.minute);
  }

  void showDemoDialog<T>({ BuildContext context, Widget child }) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    )
    .then<Null>((T value) { // The value passed to Navigator.pop() or null.
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
        title: const Text('Dialogs')
      ),
      body: new ListView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 72.0),
        children: <Widget>[
          new RaisedButton(
            child: const Text('ALERT'),
            onPressed: () {
              showDemoDialog<DialogDemoAction>(
                context: context,
                child: new AlertDialog(
                  content: new Text(
                    _alertWithoutTitleText,
                    style: dialogTextStyle
                  ),
                  actions: <Widget>[
                    new FlatButton(
                      child: const Text('CANCEL'),
                      onPressed: () { Navigator.pop(context, DialogDemoAction.cancel); }
                    ),
                    new FlatButton(
                      child: const Text('DISCARD'),
                      onPressed: () { Navigator.pop(context, DialogDemoAction.discard); }
                    )
                  ]
                )
              );
            }
          ),
          new RaisedButton(
            child: const Text('ALERT WITH TITLE'),
            onPressed: () {
              showDemoDialog<DialogDemoAction>(
                context: context,
                child: new AlertDialog(
                  title: const Text('Use Google\'s location service?'),
                  content: new Text(
                    _alertWithTitleText,
                    style: dialogTextStyle
                  ),
                  actions: <Widget>[
                    new FlatButton(
                      child: const Text('DISAGREE'),
                      onPressed: () { Navigator.pop(context, DialogDemoAction.disagree); }
                    ),
                    new FlatButton(
                      child: const Text('AGREE'),
                      onPressed: () { Navigator.pop(context, DialogDemoAction.agree); }
                    )
                  ]
                )
              );
            }
          ),
          new RaisedButton(
            child: const Text('SIMPLE'),
            onPressed: () {
              showDemoDialog<String>(
                context: context,
                child: new SimpleDialog(
                  title: const Text('Set backup account'),
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
              );
            }
          ),
          new RaisedButton(
            child: const Text('CONFIRMATION'),
            onPressed: () {
              showTimePicker(
                context: context,
                initialTime: _selectedTime
              )
              .then<Null>((TimeOfDay value) {
                if (value != null && value != _selectedTime) {
                  _selectedTime = value;
                  _scaffoldKey.currentState.showSnackBar(new SnackBar(
                    content: new Text('You selected: ${value.format(context)}')
                  ));
                }
              });
            }
          ),
          new RaisedButton(
            child: const Text('FULLSCREEN'),
            onPressed: () {
              Navigator.push(context, new MaterialPageRoute<DismissDialogAction>(
                builder: (BuildContext context) => new FullScreenDialogDemo(),
                fullscreenDialog: true,
              ));
            }
          ),
        ]
        // Add a little space between the buttons
        .map((Widget button) {
          return new Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: button
          );
        })
        .toList()
      )
    );
  }
}

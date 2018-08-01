// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoDialogDemo extends StatefulWidget {
  static const String routeName = '/cupertino/dialog';

  @override
  _CupertinoDialogDemoState createState() => new _CupertinoDialogDemoState();
}

class _CupertinoDialogDemoState extends State<CupertinoDialogDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void showDemoDialog<T>({BuildContext context, Widget child}) {
    showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => child,
    ).then<void>((T value) {
      // The value passed to Navigator.pop() or null.
      if (value != null) {
        _scaffoldKey.currentState.showSnackBar(
          new SnackBar(
            content: new Text('You selected: $value'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: const Text('Cupertino Dialogs'),
      ),
      body: new ListView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 72.0),
        children: <Widget>[
          new CupertinoButton(
            child: const Text('Alert'),
            color: CupertinoColors.activeBlue,
            onPressed: () {
              showDemoDialog<String>(
                context: context,
                child: new CupertinoAlertDialog(
                  title: const Text('Discard draft?'),
                  actions: <Widget>[
                    new CupertinoDialogAction(
                      child: const Text('Discard'),
                      isDestructiveAction: true,
                      onPressed: () {
                        Navigator.pop(context, 'Discard');
                      },
                    ),
                    new CupertinoDialogAction(
                      child: const Text('Cancel'),
                      isDefaultAction: true,
                      onPressed: () {
                        Navigator.pop(context, 'Cancel');
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const Padding(padding: const EdgeInsets.all(8.0)),
          new CupertinoButton(
            child: const Text('Alert with Title'),
            color: CupertinoColors.activeBlue,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 36.0),
            onPressed: () {
              showDemoDialog<String>(
                context: context,
                child: new CupertinoAlertDialog(
                  title: const Text('Allow "Maps" to access your location while you are using the app?'),
                  content: const Text('Your current location will be displayed on the map and used '
                      'for directions, nearby search results, and estimated travel times.'),
                  actions: <Widget>[
                    new CupertinoDialogAction(
                      child: const Text('Don\'t Allow'),
                      onPressed: () {
                        Navigator.pop(context, 'Disallow');
                      },
                    ),
                    new CupertinoDialogAction(
                      child: const Text('Allow'),
                      onPressed: () {
                        Navigator.pop(context, 'Allow');
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const Padding(padding: const EdgeInsets.all(8.0)),
          new CupertinoButton(
            child: const Text('Alert with Buttons'),
            color: CupertinoColors.activeBlue,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 36.0),
            onPressed: () {
              showDemoDialog<String>(
                context: context,
                child: const CupertinoDessertDialog(
                  title: const Text('Select Favorite Dessert'),
                  content: const Text('Please select your favorite type of dessert from the '
                      'list below. Your selection will be used to customize the suggested '
                      'list of eateries in your area.'),
                ),
              );
            },
          ),
          const Padding(padding: const EdgeInsets.all(8.0)),
          new CupertinoButton(
            child: const Text('Alert Buttons Only'),
            color: CupertinoColors.activeBlue,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 36.0),
            onPressed: () {
              showDemoDialog<String>(
                context: context,
                child: const CupertinoDessertDialog(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CupertinoDessertDialog extends StatelessWidget {
  const CupertinoDessertDialog({Key key, this.title, this.content}) : super(key: key);

  final Widget title;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return new CupertinoAlertDialog(
      title: title,
      content: content,
      actions: <Widget>[
        new CupertinoDialogAction(
          child: const Text('Cheesecake'),
          onPressed: () {
            Navigator.pop(context, 'Cheesecake');
          },
        ),
        new CupertinoDialogAction(
          child: const Text('Tiramisu'),
          onPressed: () {
            Navigator.pop(context, 'Tiramisu');
          },
        ),
        new CupertinoDialogAction(
          child: const Text('Apple Pie'),
          onPressed: () {
            Navigator.pop(context, 'Apple Pie');
          },
        ),
        new CupertinoDialogAction(
          child: const Text("Devil's food cake"),
          onPressed: () {
            Navigator.pop(context, "Devil's food cake");
          },
        ),
        new CupertinoDialogAction(
          child: const Text('Banana Split'),
          onPressed: () {
            Navigator.pop(context, 'Banana Split');
          },
        ),
        new CupertinoDialogAction(
          child: const Text('Oatmeal Cookie'),
          onPressed: () {
            Navigator.pop(context, 'Oatmeal Cookies');
          },
        ),
        new CupertinoDialogAction(
          child: const Text('Chocolate Brownie'),
          onPressed: () {
            Navigator.pop(context, 'Chocolate Brownies');
          },
        ),
        new CupertinoDialogAction(
          child: const Text('Cancel'),
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context, 'Cancel');
          },
        ),
      ],
    );
  }
}

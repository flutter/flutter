// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../gallery/demo.dart';

class CupertinoAlertDemo extends StatefulWidget {
  static const String routeName = '/cupertino/alert';

  @override
  _CupertinoAlertDemoState createState() => _CupertinoAlertDemoState();
}

class _CupertinoAlertDemoState extends State<CupertinoAlertDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void showDemoDialog<T>({BuildContext context, Widget child}) {
    showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => child,
    ).then<void>((T value) {
      // The value passed to Navigator.pop() or null.
      if (value != null) {
        _scaffoldKey.currentState.showSnackBar(
          SnackBar(
            content: Text('You selected: $value'),
          ),
        );
      }
    });
  }

  void showDemoActionSheet<T>({BuildContext context, Widget child}) {
    showCupertinoModalPopup<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T value) {
      if (value != null) {
        _scaffoldKey.currentState.showSnackBar(
          SnackBar(
            content: Text('You selected: $value'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Cupertino Alerts'),
        actions: <Widget>[MaterialDemoDocumentationButton(CupertinoAlertDemo.routeName)],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 72.0),
        children: <Widget>[
          CupertinoButton(
            child: const Text('Alert'),
            color: CupertinoColors.activeBlue,
            onPressed: () {
              showDemoDialog<String>(
                context: context,
                child: CupertinoAlertDialog(
                  title: const Text('Discard draft?'),
                  actions: <Widget>[
                    CupertinoDialogAction(
                      child: const Text('Discard'),
                      isDestructiveAction: true,
                      onPressed: () {
                        Navigator.pop(context, 'Discard');
                      },
                    ),
                    CupertinoDialogAction(
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
          const Padding(padding: EdgeInsets.all(8.0)),
          CupertinoButton(
            child: const Text('Alert with Title'),
            color: CupertinoColors.activeBlue,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 36.0),
            onPressed: () {
              showDemoDialog<String>(
                context: context,
                child: CupertinoAlertDialog(
                  title: const Text('Allow "Maps" to access your location while you are using the app?'),
                  content: const Text('Your current location will be displayed on the map and used '
                      'for directions, nearby search results, and estimated travel times.'),
                  actions: <Widget>[
                    CupertinoDialogAction(
                      child: const Text('Don\'t Allow'),
                      onPressed: () {
                        Navigator.pop(context, 'Disallow');
                      },
                    ),
                    CupertinoDialogAction(
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
          const Padding(padding: EdgeInsets.all(8.0)),
          CupertinoButton(
            child: const Text('Alert with Buttons'),
            color: CupertinoColors.activeBlue,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 36.0),
            onPressed: () {
              showDemoDialog<String>(
                context: context,
                child: const CupertinoDessertDialog(
                  title: Text('Select Favorite Dessert'),
                  content: Text('Please select your favorite type of dessert from the '
                      'list below. Your selection will be used to customize the suggested '
                      'list of eateries in your area.'),
                ),
              );
            },
          ),
          const Padding(padding: EdgeInsets.all(8.0)),
          CupertinoButton(
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
          const Padding(padding: EdgeInsets.all(8.0)),
          CupertinoButton(
            child: const Text('Action Sheet'),
            color: CupertinoColors.activeBlue,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 36.0),
            onPressed: () {
              showDemoActionSheet<String>(
                context: context,
                child: CupertinoActionSheet(
                  title: const Text('Favorite Dessert'),
                  message: const Text('Please select the best dessert from the options below.'),
                  actions: <Widget>[
                    CupertinoActionSheetAction(
                      child: const Text('Profiteroles'),
                      onPressed: () {
                        Navigator.pop(context, 'Profiteroles');
                      },
                    ),
                    CupertinoActionSheetAction(
                      child: const Text('Cannolis'),
                      onPressed: () {
                        Navigator.pop(context, 'Cannolis');
                      },
                    ),
                    CupertinoActionSheetAction(
                      child: const Text('Trifle'),
                      onPressed: () {
                        Navigator.pop(context, 'Trifle');
                      },
                    ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    child: const Text('Cancel'),
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.pop(context, 'Cancel');
                    },
                  )
                ),
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
    return CupertinoAlertDialog(
      title: title,
      content: content,
      actions: <Widget>[
        CupertinoDialogAction(
          child: const Text('Cheesecake'),
          onPressed: () {
            Navigator.pop(context, 'Cheesecake');
          },
        ),
        CupertinoDialogAction(
          child: const Text('Tiramisu'),
          onPressed: () {
            Navigator.pop(context, 'Tiramisu');
          },
        ),
        CupertinoDialogAction(
          child: const Text('Apple Pie'),
          onPressed: () {
            Navigator.pop(context, 'Apple Pie');
          },
        ),
        CupertinoDialogAction(
          child: const Text("Devil's food cake"),
          onPressed: () {
            Navigator.pop(context, "Devil's food cake");
          },
        ),
        CupertinoDialogAction(
          child: const Text('Banana Split'),
          onPressed: () {
            Navigator.pop(context, 'Banana Split');
          },
        ),
        CupertinoDialogAction(
          child: const Text('Oatmeal Cookie'),
          onPressed: () {
            Navigator.pop(context, 'Oatmeal Cookies');
          },
        ),
        CupertinoDialogAction(
          child: const Text('Chocolate Brownie'),
          onPressed: () {
            Navigator.pop(context, 'Chocolate Brownies');
          },
        ),
        CupertinoDialogAction(
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

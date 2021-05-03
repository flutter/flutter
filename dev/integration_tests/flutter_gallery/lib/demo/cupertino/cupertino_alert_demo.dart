// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

import '../../gallery/demo.dart';

class CupertinoAlertDemo extends StatefulWidget {
  const CupertinoAlertDemo({Key? key}) : super(key: key);

  static const String routeName = '/cupertino/alert';

  @override
  _CupertinoAlertDemoState createState() => _CupertinoAlertDemoState();
}

class _CupertinoAlertDemoState extends State<CupertinoAlertDemo> {
  String? lastSelectedValue;

  void showDemoDialog({required BuildContext context, Widget? child}) {
    showCupertinoDialog<String>(
      context: context,
      builder: (BuildContext context) => child!,
    ).then((String? value) {
      if (value != null) {
        setState(() { lastSelectedValue = value; });
      }
    });
  }

  void showDemoActionSheet({required BuildContext context, Widget? child}) {
    showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext context) => child!,
    ).then((String? value) {
      if (value != null) {
        setState(() { lastSelectedValue = value; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Alerts'),
        // We're specifying a back label here because the previous page is a
        // Material page. CupertinoPageRoutes could auto-populate these back
        // labels.
        previousPageTitle: 'Cupertino',
        trailing: CupertinoDemoDocumentationButton(CupertinoAlertDemo.routeName),
      ),
      child: DefaultTextStyle(
        style: CupertinoTheme.of(context).textTheme.textStyle,
        child: Builder(
          builder: (BuildContext context) {
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CupertinoScrollbar(
                  child: ListView(
                    // Add more padding to the normal safe area.
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 72.0)
                        + MediaQuery.of(context).padding,
                    children: <Widget>[
                      CupertinoButton.filled(
                        onPressed: () => _onAlertPress(context),
                        child: const Text('Alert'),
                      ),
                      const Padding(padding: EdgeInsets.all(8.0)),
                      CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 36.0),
                        onPressed: () => _onAlertWithTitlePress(context),
                        child: const Text('Alert with Title'),
                      ),
                      const Padding(padding: EdgeInsets.all(8.0)),
                      CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 36.0),
                        onPressed: () => _onAlertWithButtonsPress(context),
                        child: const Text('Alert with Buttons'),
                      ),
                      const Padding(padding: EdgeInsets.all(8.0)),
                      CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 36.0),
                        onPressed: () {
                          showDemoDialog(
                            context: context,
                            child: const CupertinoDessertDialog(),
                          );
                        },
                        child: const Text('Alert Buttons Only'),
                      ),
                      const Padding(padding: EdgeInsets.all(8.0)),
                      CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 36.0),
                        onPressed: () => _onActionSheetPress(context),
                        child: const Text('Action Sheet'),
                      ),
                    ],
                  ),
                ),
                if (lastSelectedValue != null)
                  Positioned(
                    bottom: 32.0,
                    child: Text('You selected: $lastSelectedValue'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onAlertPress(BuildContext context) {
    showDemoDialog(
      context: context,
      child: CupertinoAlertDialog(
        title: const Text('Discard draft?'),
        actions: <Widget>[
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, 'Discard'),
            child: const Text('Discard'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _onAlertWithTitlePress(BuildContext context) {
    showDemoDialog(
      context: context,
      child: CupertinoAlertDialog(
        title: const Text('Allow "Maps" to access your location while you are using the app?'),
        content: const Text('Your current location will be displayed on the map and used '
          'for directions, nearby search results, and estimated travel times.'),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, 'Disallow'),
            child: const Text("Don't Allow"),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, 'Allow'),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  void _onAlertWithButtonsPress(BuildContext context) {
    showDemoDialog(
      context: context,
      child: const CupertinoDessertDialog(
        title: Text('Select Favorite Dessert'),
        content: Text('Please select your favorite type of dessert from the '
          'list below. Your selection will be used to customize the suggested '
          'list of eateries in your area.'),
      ),
    );
  }

  void _onActionSheetPress(BuildContext context)  {
    showDemoActionSheet(
      context: context,
      child: CupertinoActionSheet(
        title: const Text('Favorite Dessert'),
        message: const Text('Please select the best dessert from the options below.'),
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'Profiteroles'),
            child: const Text('Profiteroles'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'Cannolis'),
            child: const Text('Cannolis'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'Trifle'),
            child: const Text('Trifle'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class CupertinoDessertDialog extends StatelessWidget {
  const CupertinoDessertDialog({Key? key, this.title, this.content}) : super(key: key);

  final Widget? title;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: title,
      content: content,
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: () {
            Navigator.pop(context, 'Cheesecake');
          },
          child: const Text('Cheesecake'),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.pop(context, 'Tiramisu');
          },
          child: const Text('Tiramisu'),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.pop(context, 'Apple Pie');
          },
          child: const Text('Apple Pie'),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.pop(context, "Devil's food cake");
          },
          child: const Text("Devil's food cake"),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.pop(context, 'Banana Split');
          },
          child: const Text('Banana Split'),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.pop(context, 'Oatmeal Cookies');
          },
          child: const Text('Oatmeal Cookie'),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.pop(context, 'Chocolate Brownies');
          },
          child: const Text('Chocolate Brownie'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context, 'Cancel');
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

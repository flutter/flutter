// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../gallery/demo.dart';

enum BannerDemoAction {
  reset,
  showMultipleActions,
  showLeading,
}

class BannerDemo extends StatefulWidget {
  const BannerDemo({ Key key }) : super(key: key);

  static const String routeName = '/material/banner';

  @override
  _BannerDemoState createState() => _BannerDemoState();
}

class _BannerDemoState extends State<BannerDemo> {
  bool displayBanner = true;
  bool showMultipleActions = true;
  bool showLeading = true;

  @override
  void initState() {
    super.initState();
    initBanner();
  }

  void initBanner() {
    displayBanner = true;
    showMultipleActions = true;
    showLeading = true;
  }

  void handleDemoAction(BannerDemoAction action) {
    setState(() {
      switch (action) {
        case BannerDemoAction.reset:
          initBanner();
          break;
        case BannerDemoAction.showMultipleActions:
          showMultipleActions = !showMultipleActions;
          break;
        case BannerDemoAction.showLeading:
          showLeading = !showLeading;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget banner = MaterialBannerTheme(child: MaterialBanner(
      content: const Text('Your password was updated on your other device. Please sign in again.'),
      leading: showLeading ? CircleAvatar(child: Icon(Icons.access_alarm)) : null,
      actions: <Widget>[
        FlatButton(
          child: const Text('SIGN IN'),
          onPressed: () =>
            setState(() {
              displayBanner = false;
            })
        ),
        if (showMultipleActions)
          FlatButton(
            child: const Text('DISMISS'),
            onPressed: () =>
              setState(() {
                displayBanner = false;
              })
          ),
      ],
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banner'),
        actions: <Widget>[
          MaterialDemoDocumentationButton(BannerDemo.routeName),
          PopupMenuButton<BannerDemoAction>(
            onSelected: handleDemoAction,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<BannerDemoAction>>[
              const PopupMenuItem<BannerDemoAction>(
                value: BannerDemoAction.reset,
                child: Text('Reset the banner'),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem<BannerDemoAction>(
                value: BannerDemoAction.showMultipleActions,
                checked: showMultipleActions,
                child: const Text('Multiple actions'),
              ),
              CheckedPopupMenuItem<BannerDemoAction>(
                value: BannerDemoAction.showLeading,
                checked: showLeading,
                child: const Text('Leading icon'),
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(itemCount: displayBanner ? 21 : 20, itemBuilder: (BuildContext context, int index) {
        if (index == 0 && displayBanner) {
          return banner;
        } else {
          return ListTile(title: Text('Item ${displayBanner ? index : index + 1}'),);
        }
      }),
    );
  }
}

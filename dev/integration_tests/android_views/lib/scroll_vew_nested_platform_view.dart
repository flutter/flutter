// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'page.dart';
import 'simple_platform_view.dart';

/// A page that containing the widget to be tested.
///
/// The widget is a platform view with certain mutations and a scrolling widget.
/// This testing case is generated due to an issue that was filed which says the platform view
/// on iOS in not visible using this particular composition in the test.
/// https://github.com/flutter/flutter/issues/35840
class ScrollViewNestedPlatformView extends Page {
  const ScrollViewNestedPlatformView()
      : super('ScrollViewNestedPlatformView Tests',
            const ValueKey<String>('ScrollViewNestedPlatformViewListTile'));

  @override
  Widget build(BuildContext context) {
    return const ScrollViewNestedPlatformViewBody();
  }
}

/// The widget composited with a scrolling widget, some mutation widgets and a platform view.
class ScrollViewNestedPlatformViewBody extends StatefulWidget {

  const ScrollViewNestedPlatformViewBody():super(key: const ValueKey<String>('ScrollViewNestedPlatformView'));

  @override
  State createState() => ScrollViewNestedPlatformViewBodyState();
}

class ScrollViewNestedPlatformViewBodyState extends State<ScrollViewNestedPlatformViewBody> {

  @override
  Widget build(BuildContext context) {
    return Column(
          children: <Widget>[ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 100.0),
                child: const SimplePlatformView(key: ValueKey<String>('PlatformView')),
              ),
            ),
        ),
         Center(child:FlatButton(key: const ValueKey<String>('back'), child: const Text('back'), onPressed: (){
            Navigator.of(context).pop();
          },)) ]);
  }
}
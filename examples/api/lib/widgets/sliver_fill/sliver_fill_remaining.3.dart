// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/stateless_widget_scaffold.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for SliverFillRemaining
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// In this sample the [SliverFillRemaining]'s child stretches to fill the
// overscroll area when [fillOverscroll] is true. This sample also features a
// button that is pinned to the bottom of the sliver, regardless of size or
// overscroll behavior. Try switching [fillOverscroll] to see the difference.
//
// This sample only shows the overscroll behavior on devices that support
// overscroll.

//* ▲▲▲▲▲▲▲▲ description ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//***************************************************************************

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

/// This is the main application widget.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const MyStatelessWidget(),
      ),
    );
  }
}

/// This is the stateless widget that the main application instantiates.
class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({Key? key}) : super(key: key);

  @override
//********************************************************************
//* ▼▼▼▼▼▼▼▼ code ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

  Widget build(BuildContext context) {
    return CustomScrollView(
      // The ScrollPhysics are overridden here to illustrate the functionality
      // of fillOverscroll on all devices this sample may be run on.
      // fillOverscroll only changes the behavior of your layout when applied
      // to Scrollables that allow for overscroll. BouncingScrollPhysics are
      // one example, which are provided by default on the iOS platform.
      // BouncingScrollPhysics is combined with AlwaysScrollableScrollPhysics
      // to allow for the overscroll, regardless of the depth of the
      // scrollable.
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Container(
            color: Colors.tealAccent[700],
            height: 150.0,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          // Switch for different overscroll behavior in your layout.
          // If your ScrollPhysics do not allow for overscroll, setting
          // fillOverscroll to true will have no effect.
          fillOverscroll: true,
          child: Container(
            color: Colors.teal[100],
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    /* Place your onPressed code here! */
                  },
                  child: const Text('Bottom Pinned Button!'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

//* ▲▲▲▲▲▲▲▲ code ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************

}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/stateless_widget_material.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for NestedScrollView
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// This simple example shows a [NestedScrollView] whose header contains a
// floating [SliverAppBar]. By using the [floatHeaderSlivers] property, the
// floating behavior is coordinated between the outer and inner [Scrollable]s,
// so it behaves as it would in a single scrollable.

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
    return const MaterialApp(
      title: _title,
      home: MyStatelessWidget(),
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
    return Scaffold(
        body: NestedScrollView(
            // Setting floatHeaderSlivers to true is required in order to float
            // the outer slivers over the inner scrollable.
            floatHeaderSlivers: true,
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  title: const Text('Floating Nested SliverAppBar'),
                  floating: true,
                  expandedHeight: 200.0,
                  forceElevated: innerBoxIsScrolled,
                ),
              ];
            },
            body: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: 30,
                itemBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    height: 50,
                    child: Center(child: Text('Item $index')),
                  );
                })));
  }

//* ▲▲▲▲▲▲▲▲ code ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************

}

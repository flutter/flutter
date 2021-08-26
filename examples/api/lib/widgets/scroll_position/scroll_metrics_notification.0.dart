// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/freeform.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for ScrollMetricsNotification
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// This sample shows how a [ScrollMetricsNotification] is dispatched when
// the `windowSize` is changed. Press the floating action button to increase
// the scrollable window's size.

//* ▲▲▲▲▲▲▲▲ description ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//***************************************************************************

//*************************************************************************
//* ▼▼▼▼▼▼▼▼ code-main ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

import 'package:flutter/material.dart';

void main() => runApp(const ScrollMetricsDemo());

class ScrollMetricsDemo extends StatefulWidget {
  const ScrollMetricsDemo({Key? key}) : super(key: key);

  @override
  State<ScrollMetricsDemo> createState() => ScrollMetricsDemoState();
}

class ScrollMetricsDemoState extends State<ScrollMetricsDemo> {
  double windowSize = 200.0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ScrollMetrics Demo'),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => setState(() {
            windowSize += 10.0;
          }),
        ),
        body: NotificationListener<ScrollMetricsNotification>(
          onNotification: (ScrollMetricsNotification notification) {
            ScaffoldMessenger.of(notification.context).showSnackBar(
              const SnackBar(
                content: Text('Scroll metrics changed!'),
              ),
            );
            return false;
          },
          child: Scrollbar(
            isAlwaysShown: true,
            child: SizedBox(
              height: windowSize,
              width: double.infinity,
              child: const SingleChildScrollView(
                child: FlutterLogo(
                  size: 300.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//* ▲▲▲▲▲▲▲▲ code-main ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//*************************************************************************

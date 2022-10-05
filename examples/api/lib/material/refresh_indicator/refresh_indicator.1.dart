// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for RefreshIndicator

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RefreshIndicatorExample(),
    );
  }
}

class RefreshIndicatorExample extends StatelessWidget {
  const RefreshIndicatorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RefreshIndicator Sample'),
      ),
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.blue,
        onRefresh: () async {
          // Replace this delay with the code to be executed during refresh
          // and return asynchronous code
          return Future<void>.delayed(const Duration(seconds: 3));
        },
        // This check is used to customize listening to scroll notifications
        // from the widget's children.
        //
        // By default this is set to `notification.depth == 0`, which ensures
        // the only the scroll notifications from the first child are listened to.
        //
        // Here setting `notification.depth == 1` triggers the refresh indicator
        // when overscrolling the nested scroll view.
        notificationPredicate: (ScrollNotification notification) {
          return notification.depth == 1;
        },
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                height: 100,
                alignment: Alignment.center,
                color: Colors.pink[100],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Pull down here',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Text("RefreshIndicator won't trigger"),
                  ],
                ),
              ),
              Container(
                color: Colors.green[100],
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: 25,
                  itemBuilder: (BuildContext context, int index) {
                    return const ListTile(
                      title: Text('Pull down here'),
                      subtitle: Text('RefreshIndicator will trigger'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

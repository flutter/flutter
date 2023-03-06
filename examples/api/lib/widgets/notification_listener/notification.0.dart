// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [Notification].

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: MyStatelessWidget(),
    );
  }
}

class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({super.key});

  static const List<String> _tabs = <String>['Months', 'Days'];
  static const List<String> _months = <String>[
    'January',
    'February',
    'March',
  ];
  static const List<String> _days = <String>[
    'Sunday',
    'Monday',
    'Tuesday',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        // Listens to the scroll events and returns the current position.
        body: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollNotification) {
            if (scrollNotification is ScrollStartNotification) {
              debugPrint('Scrolling has started');
            } else if (scrollNotification is ScrollEndNotification) {
              debugPrint('Scrolling has ended');
            }
            // Return true to cancel the notification bubbling.
            return true;
          },
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  title: const Text('Flutter Code Sample'),
                  pinned: true,
                  floating: true,
                  bottom: TabBar(
                    tabs: _tabs.map((String name) => Tab(text: name)).toList(),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: <Widget>[
                ListView.builder(
                  itemCount: _months.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(title: Text(_months[index]));
                  },
                ),
                ListView.builder(
                  itemCount: _days.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(title: Text(_days[index]));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'motion_events_page.dart';
import 'page.dart';

final List<PageWidget> _allPages = <PageWidget>[
  const MotionEventsPage(),
];

void main() {
  enableFlutterDriverExtension(handler: driverDataHandler.handleMessage);
  runApp(MaterialApp(home: Home()));
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _allPages.length,
        itemBuilder: (_, int index) => ListTile(
          title: Text(_allPages[index].title),
          key: _allPages[index].tileKey,
          onTap: () => _pushPage(context, _allPages[index]),
        ),
      ),
    );
  }

  void _pushPage(BuildContext context, PageWidget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
              body: page,
            )));
  }
}

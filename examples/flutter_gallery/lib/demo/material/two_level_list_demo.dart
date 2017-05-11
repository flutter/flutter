// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class TwoLevelListDemo extends StatelessWidget {
  static const String routeName = '/material/two-level-list';

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: const Text('Expand/collapse list control')),
      body: new ListView(
        children: <Widget>[
          const ListTile(title: const Text('Top')),
          new ExpansionTile(
             title: const Text('Sublist'),
             backgroundColor: Theme.of(context).accentColor.withOpacity(0.025),
             children: <Widget>[
               const ListTile(title: const Text('One')),
               const ListTile(title: const Text('Two')),
               // https://en.wikipedia.org/wiki/Free_Four
               const ListTile(title: const Text('Free')),
               const ListTile(title: const Text('Four'))
             ]
          ),
           const ListTile(title: const Text('Bottom'))
        ]
      )
    );
  }
}

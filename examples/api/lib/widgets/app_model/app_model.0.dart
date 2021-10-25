// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for AppModel

import 'package:flutter/material.dart';

// Demonstrates that changes to the AppModel _only_ cause the dependent widgets
// to be rebuilt.

class Home extends StatefulWidget {
  const Home({ Key? key }) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _fooCount = 0;
  int _barCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Builder(
              builder: (BuildContext context) {
                // The AppModel.get() call here causes this widget to depend
                // on the value of the AppModel's 'foo' key. If it's changed, with
                // AppModel.set() (see below), then this widget will be rebuilt.
                final String? value = AppModel.get<String, String>(context, 'foo');
                return Text('foo: $value [$_fooCount]');
              },
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (BuildContext context) {
                final String? value = AppModel.get<String, String>(context, 'bar');
                return Text('bar: $value [$_barCount]');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('change foo'),
              onPressed: () {
                _fooCount += 1;
                // Changing the AppModel's value for 'foo' causes the widgets that
                // depend on 'foo' to be rebuilt (see above).
                AppModel.set<String, String?>(context, 'foo', 'FOO $_fooCount'); // note: no setState()
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('change bar'),
              onPressed: () {
                _barCount += 1;
                AppModel.set<String, String?>(context, 'bar', 'BAR $_barCount');  // note: no setState()
              },
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: Home()));
}

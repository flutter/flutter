// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for SharedAppData

import 'package:flutter/material.dart';

class ShowSharedValue extends StatelessWidget {
  const ShowSharedValue({ Key? key, required this.appDataKey }) : super(key: key);

  final String appDataKey;

  @override
  Widget build(BuildContext context) {
    // The SharedAppData.getValue() call here causes this widget to depend
    // on the value of the SharedAppData's 'foo' key. If it's changed, with
    // SharedAppData.setValue(), then this widget will be rebuilt.
    final String value = SharedAppData.getValue<String, String>(context, appDataKey, () => 'initial');
    return Text('$appDataKey: $value');
  }
}

// Demonstrates that changes to the SharedAppData _only_ cause the dependent widgets
// to be rebuilt. In this case that's the ShowSharedValue widget that's
// displaying the value of a key whose value has been updated.
class Home extends StatefulWidget {
  const Home({ Key? key }) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _fooVersion = 0;
  int _barVersion = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const ShowSharedValue(appDataKey: 'foo'),
            const SizedBox(height: 16),
            const ShowSharedValue(appDataKey: 'bar'),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('change foo'),
              onPressed: () {
                _fooVersion += 1;
                // Changing the SharedAppData's value for 'foo' causes the widgets that
                // depend on 'foo' to be rebuilt.
                SharedAppData.setValue<String, String?>(context, 'foo', 'FOO $_fooVersion'); // note: no setState()
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('change bar'),
              onPressed: () {
                _barVersion += 1;
                SharedAppData.setValue<String, String?>(context, 'bar', 'BAR $_barVersion');  // note: no setState()
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

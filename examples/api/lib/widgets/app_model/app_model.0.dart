// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for AppModel

import 'package:flutter/material.dart';

class ShowAppModelValue extends StatelessWidget {
  const ShowAppModelValue({ Key? key, required this.appModelKey }) : super(key: key);

  final String appModelKey;

  @override
  Widget build(BuildContext context) {
    // The AppModel.getValue() call here causes this widget to depend
    // on the value of the AppModel's 'foo' key. If it's changed, with
    // AppModel.setValue(), then this widget will be rebuilt.
    final String value = AppModel.getValue<String, String>(context, appModelKey, () => 'initial');
    return Text('$appModelKey: $value');
  }
}

// Demonstrates that changes to the AppModel _only_ cause the dependent widgets
// to be rebuilt. In this case that's the ShowAppModelValue widget that's
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
            const ShowAppModelValue(appModelKey: 'foo'),
            const SizedBox(height: 16),
            const ShowAppModelValue(appModelKey: 'bar'),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('change foo'),
              onPressed: () {
                _fooVersion += 1;
                // Changing the AppModel's value for 'foo' causes the widgets that
                // depend on 'foo' to be rebuilt.
                AppModel.setValue<String, String?>(context, 'foo', 'FOO $_fooVersion'); // note: no setState()
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('change bar'),
              onPressed: () {
                _barVersion += 1;
                AppModel.setValue<String, String?>(context, 'bar', 'BAR $_barVersion');  // note: no setState()
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

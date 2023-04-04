// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [WillPopScope].

void main() => runApp(const WillPopScopeExampleApp());

class WillPopScopeExampleApp extends StatelessWidget {
  const WillPopScopeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WillPopScopeExample(),
    );
  }
}

class WillPopScopeExample extends StatefulWidget {
  const WillPopScopeExample({super.key});

  @override
  State<WillPopScopeExample> createState() => _WillPopScopeExampleState();
}

class _WillPopScopeExampleState extends State<WillPopScopeExample> {
  bool shouldPop = true;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return shouldPop;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter WillPopScope demo'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              OutlinedButton(
                child: const Text('Push'),
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return const WillPopScopeExample();
                      },
                    ),
                  );
                },
              ),
              OutlinedButton(
                child: Text('shouldPop: $shouldPop'),
                onPressed: () {
                  setState(
                    () {
                      shouldPop = !shouldPop;
                    },
                  );
                },
              ),
              const Text('Push to a new screen, then tap on shouldPop '
                  'button to toggle its value. Press the back '
                  'button in the appBar to check its behavior '
                  'for different values of shouldPop'),
            ],
          ),
        ),
      ),
    );
  }
}

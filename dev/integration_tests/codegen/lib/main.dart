// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'coffee_app.dart';
import 'src/coffee.dart';

Future<void> main() async {
  enableFlutterDriverExtension();
  coffeeApp = await CoffeeApp.create(PourOverCoffeeModule());
  runApp(ExampleWidget());
}

CoffeeApp coffeeApp;

class ExampleWidget extends StatefulWidget {
  @override
  _ExampleWidgetState createState() => _ExampleWidgetState();
}

class _ExampleWidgetState extends State<ExampleWidget> {
  String _message = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              child: const Text('Press Button, Get Coffee'),
              onPressed: () async {
                final CoffeeMaker coffeeMaker = coffeeApp.getCoffeeMaker();
                setState(() {
                  _message = coffeeMaker.brew();
                });
              },
            ),
            Text(_message),
          ],
        ),
      ),
    );
  }
}

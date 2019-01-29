// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'coffee_app.dart';
import 'src/coffee.dart';

Future<void> main() async {
  runApp(ExampleWidget());
}

class ExampleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: RaisedButton(
            child: const Text('Press Button, Get Coffee'),
            onPressed: () async {
              final CoffeeApp coffeeApp = await CoffeeApp.create(PourOverCoffeeModule());
              final CoffeeMaker coffeeMaker = coffeeApp.getCoffeeMaker();
              coffeeMaker.brew();
            },
          ),
        ),
      ),
    );
  }
}

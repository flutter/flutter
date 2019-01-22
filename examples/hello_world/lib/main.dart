// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'coffee.dart';

void main() => runApp(Example());

class Example extends StatefulWidget {
  @override
  _ExampleState createState() => _ExampleState();
}



class _ExampleState extends State<Example> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
      color: Colors.red,
      child: RaisedButton(
        child: const Text('Make Coffee'),
        onPressed: () async {
          final Coffee coffee = await Coffee.create(DripCoffeeModule());
          final CoffeeMaker maker = coffee.getCoffeeMaker();
          maker.brew();
        },
      )
      ),
    );
  }
}
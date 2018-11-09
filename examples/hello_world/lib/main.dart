// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
//void main() => runApp(const Center(child: Text('Hello, world!', textDirection: TextDirection.ltr)));
void main() {
  runApp(
    MaterialApp(
      home: MyHomePage(),
    ),
  );
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  AnimationController animationDouble;

  @override
  void initState() {
    super.initState();
    animationDouble = AnimationController(
        vsync: this, value: 1.0, duration: Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('this is the title'),
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (UserScrollNotification t) {
          if (t is UserScrollNotification) {
            if (t.direction == ScrollDirection.reverse) {
              animationDouble.reverse();
            } else if (t.direction == ScrollDirection.forward) {
              animationDouble.forward();
            }
          }
        },
        child: ListView(
          children: const <Widget>[
            ListTile(
              title: Text("Test 1"),
            ),
            ListTile(
              title: Text("Test 2"),
            ),
            ListTile(
              title: Text("Test 3"),
            ),
            ListTile(
              title: Text("Test 4"),
            ),
            ListTile(
              title: Text("Test 5"),
            ),
            ListTile(
              title: Text("Test 6"),
            ),
            ListTile(
              title: Text("Test 7"),
            ),
            ListTile(
              title: Text("Test 8"),
            ),
            ListTile(
              title: Text("Test 9"),
            ),
            ListTile(
              title: Text("Test 1"),
            ),
            ListTile(
              title: Text("Test 2"),
            ),
            ListTile(
              title: Text("Test 3"),
            ),
            ListTile(
              title: Text("Test 4"),
            ),
            ListTile(
              title: Text("Test 5"),
            ),
            ListTile(
              title: Text("Test 6"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizeTransition(
        sizeFactor: animationDouble,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: Colors.blueAccent,
          child: Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  print('open menu');
                },
                color: Colors.white,
              )
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }
}
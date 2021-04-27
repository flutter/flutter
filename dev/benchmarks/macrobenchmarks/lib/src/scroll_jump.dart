// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ScrollJumpPage extends StatefulWidget {
  const ScrollJumpPage({Key key}) : super(key: key);

  @override
  State<ScrollJumpPage> createState() => _ScrollJumpPageState();
}

class _ScrollJumpPageState extends State<ScrollJumpPage> {
  final ScrollController controller = ScrollController(initialScrollOffset: 1000);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        body: ListView.builder(
          controller: controller,
          itemExtent: 15,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              tileColor: index.isOdd ? Colors.lightBlueAccent : Colors.lime,
              title: Text(
                '$index Hello world',
              ),
            );
          },
        ),
        floatingActionButton: GestureDetector(
          key: const ValueKey<String>('jump'),
          onTap: () {
            controller.jumpTo(controller.offset > 20000 ? controller.offset - 20000 : controller.offset + 20000);
          },
          child: Container(
            height: 50,
            width: 50,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}

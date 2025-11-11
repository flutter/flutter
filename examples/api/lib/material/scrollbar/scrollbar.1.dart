// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Scrollbar].

void main() => runApp(const ScrollbarExampleApp());

class ScrollbarExampleApp extends StatelessWidget {
  const ScrollbarExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController controllerOne = ScrollController();

    return MaterialApp(
      scrollBehavior: CustomScrollbarBehavior(controllerOne),
      home: Scaffold(
        appBar: AppBar(title: const Text('Scrollbar Sample')),
        body: ScrollbarExample(controllerOne),
      ),
    );
  }
}

class ScrollbarExample extends StatefulWidget {
  const ScrollbarExample(this.controller, {super.key});

  final ScrollController controller;

  @override
  State<ScrollbarExample> createState() => _ScrollbarExampleState();
}

class _ScrollbarExampleState extends State<ScrollbarExample> {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: widget.controller,
      itemCount: 120,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemBuilder: (BuildContext context, int index) {
        return Center(child: Text('item $index'));
      },
    );
  }
}

class CustomScrollbarBehavior extends MaterialScrollBehavior {
  const CustomScrollbarBehavior(this.scrollController);

  final ScrollController scrollController;

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return Scrollbar(controller: scrollController, thumbVisibility: true, child: child);
  }
}

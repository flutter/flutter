// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Flutter code sample for [ScrollEndNotification].

void main() {
  runApp(const ScrollEndNotificationApp());
}

class ScrollEndNotificationApp extends StatelessWidget {
  const ScrollEndNotificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    return MaterialApp(
      scrollBehavior: CustomScrollbarBehavior(scrollController),
      home: ScrollEndNotificationExample(scrollController),
    );
  }
}

class ScrollEndNotificationExample extends StatefulWidget {
  const ScrollEndNotificationExample(this.scrollController, {super.key});

  final ScrollController scrollController;

  @override
  State<ScrollEndNotificationExample> createState() => _ScrollEndNotificationExampleState();
}

class _ScrollEndNotificationExampleState extends State<ScrollEndNotificationExample> {
  static const int itemCount = 25;
  static const double itemExtent = 100;

  late double lastScrollOffset;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    widget.scrollController.dispose();
  }

  // After an interactive scroll "ends", auto-scroll so that last item in the
  // viewport is completely visible. To accommodate mouse-wheel scrolls, other small
  // adjustments, and scrolling to the top, scrolls that put the scroll offset at
  // zero or change the scroll offset by less than itemExtent don't trigger
  // an auto-scroll. This also prevents the auto-scroll from triggering itself,
  // since the alignedScrollOffset is guaranteed to be less than itemExtent.
  bool handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      lastScrollOffset = widget.scrollController.position.pixels;
    }
    if (notification is ScrollEndNotification) {
      final ScrollMetrics m = notification.metrics;
      final int lastIndex = ((m.extentBefore + m.extentInside) ~/ itemExtent).clamp(
        0,
        itemCount - 1,
      );
      final double alignedScrollOffset = itemExtent * (lastIndex + 1) - m.extentInside;
      final double scrollOffset = widget.scrollController.position.pixels;
      if (scrollOffset > 0 && (scrollOffset - lastScrollOffset).abs() > itemExtent) {
        SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
          widget.scrollController.animateTo(
            alignedScrollOffset,
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
          );
        });
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: NotificationListener<ScrollNotification>(
            onNotification: handleScrollNotification,
            child: CustomScrollView(
              controller: widget.scrollController,
              slivers: <Widget>[
                SliverFixedExtentList.builder(
                  itemExtent: itemExtent,
                  itemCount: itemCount,
                  itemBuilder: (BuildContext context, int index) {
                    return Item(
                      title: 'Item $index',
                      color: Color.lerp(Colors.red, Colors.blue, index / itemCount)!,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Item extends StatelessWidget {
  const Item({super.key, required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: ListTile(textColor: Colors.white, title: Text(title)),
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

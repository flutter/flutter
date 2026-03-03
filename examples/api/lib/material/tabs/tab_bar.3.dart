// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for a [TabBar] that displays custom effects on top of
/// the tab bar itself when there are more tabs in the scroll direction.

void main() => runApp(const TabBarApp());

class TabBarApp extends StatelessWidget {
  const TabBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TabBarExample());
  }
}

class TabBarExample extends StatefulWidget {
  const TabBarExample({super.key});

  @override
  State<TabBarExample> createState() => _TabBarExampleState();
}

class _TabBarExampleState extends State<TabBarExample> {
  double scrollOffset = 0;
  double maxScrollExtent = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 20,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TabBar with scroll notifications'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56.0),
            child: NotificationListener<Notification>(
              onNotification: (Notification notification) {
                // ScrollMetricsNotification is for initial layout.
                // ScrollNotification is for real-time scroll updates.
                final ScrollMetrics? metrics = switch (notification) {
                  ScrollMetricsNotification(:final metrics) => metrics,
                  ScrollNotification(:final metrics) => metrics,
                  _ => null,
                };
                if (metrics != null) {
                  setState(() {
                    scrollOffset = metrics.pixels;
                    maxScrollExtent = metrics.maxScrollExtent;
                  });
                }
                return false;
              },
              child: Stack(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabs: List<Widget>.generate(
                      20,
                      (int index) => Tab(text: 'Tab $index'),
                    ),
                  ),
                  // When the selected tab is not at the beginning or end
                  // (indicating TabBar is scrollable), add a gradient mask
                  // to left or right.
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GradientMasks(
                      scrollOffset: scrollOffset,
                      maxScrollExtent: maxScrollExtent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientMasks extends StatelessWidget {
  final double scrollOffset;
  final double maxScrollExtent;

  const GradientMasks({
    super.key,
    required this.scrollOffset,
    required this.maxScrollExtent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (scrollOffset > 0) const LeftMask(),
        const Spacer(),
        if (scrollOffset < maxScrollExtent) const RightMask(),
      ],
    );
  }
}

/// This mask shows when the selected tab is not at the beginning.
class LeftMask extends StatelessWidget {
  const LeftMask({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: BackdropFilter(
          filter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.2),
            BlendMode.srcOver,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0.8),
                  Colors.white.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.chevron_left,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// This mask shows when the selected tab is not at the end.
class RightMask extends StatelessWidget {
  const RightMask({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: BackdropFilter(
          filter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.2),
            BlendMode.srcOver,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.white.withValues(alpha: 0.8),
                  Colors.white.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

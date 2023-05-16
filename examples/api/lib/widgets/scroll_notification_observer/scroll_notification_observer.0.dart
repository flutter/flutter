// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [ScrollNotificationObserver].

void main() => runApp(const ScrollNotificationObserverApp());

class ScrollNotificationObserverApp extends StatelessWidget {
  const ScrollNotificationObserverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      // For demonstration purposes, this sample excludes
      // the Scaffold as it has its own ScrollNotificationObserver.
      home: Material(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'ScrollNotificationObserver Sample',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const Expanded(
              child: ScrollNotificationObserver(
                child: ScrollNotificationObserverExample(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScrollNotificationObserverExample extends StatefulWidget {
  const ScrollNotificationObserverExample({super.key});

  @override
  State<ScrollNotificationObserverExample> createState() => _ScrollNotificationObserverExampleState();
}

class _ScrollNotificationObserverExampleState extends State<ScrollNotificationObserverExample> {
  ScrollNotificationObserverState? _scrollNotificationObserver;
  ScrollController controller = ScrollController();
  bool _scrolledDown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Remove any previous listener.
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    // Add a new listener.
    _scrollNotificationObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollNotificationObserver?.addListener(_handleScrollNotification);
  }

  @override
  void dispose() {
    if (_scrollNotificationObserver != null) {
      _scrollNotificationObserver!.removeListener(_handleScrollNotification);
      _scrollNotificationObserver = null;
    }
    controller.dispose();
    super.dispose();
  }

  void _handleScrollNotification(ScrollNotification notification) {
    // Check if the notification is a scroll update notification and if the
    // `notification.depth` is 0. This way we only listen to the scroll
    // notifications from the inner scrollable.
    if (notification is ScrollUpdateNotification && defaultScrollNotificationPredicate(notification)) {
      final bool oldScrolledDown = _scrolledDown;
      final ScrollMetrics metrics = notification.metrics;
      // `_scrolledDown` will be true if the user is scrolling down.
      _scrolledDown = metrics.extentBefore > 0;
      // Only update the state if the scrolled down value changed.
      if (_scrolledDown != oldScrolledDown) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SampleList(controller: controller),
        // Show the button only if the user scrolled down.
        if (_scrolledDown)
          Positioned(
            right: 25,
            bottom: 20,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Scroll to the top when the user taps the button.
                  controller.animateTo(0, duration: const Duration(milliseconds: 200), curve:Curves.fastOutSlowIn);
                },
                child: const Card(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      children: <Widget>[
                        Icon(Icons.arrow_upward_rounded),
                        Text('Scroll to top')
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SampleList extends StatelessWidget {
  const SampleList({super.key, required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: 30,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(title: Text('Item $index'));
      },
    );
  }
}

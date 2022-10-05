// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';


import 'recorder.dart';

/// Creates an infinite list of Link widgets and scrolls it.
class BenchLinkInfiniteScroll extends WidgetRecorder {
  BenchLinkInfiniteScroll.forward()
    : initialOffset = 0.0,
      finalOffset = 30000.0,
      super(name: benchmarkName);

  BenchLinkInfiniteScroll.backward()
    : initialOffset = 30000.0,
      finalOffset = 0.0,
      super(name: benchmarkNameBackward);

  static const String benchmarkName = 'bench_link_infinite_scroll';
  static const String benchmarkNameBackward = 'bench_link_infinite_scroll_backward';

  final double initialOffset;
  final double finalOffset;

  @override
  Widget createWidget() => MaterialApp(
    title: 'Infinite Link Scroll Benchmark',
    home: _InfiniteScrollLinks(initialOffset, finalOffset),
  );
}

class _InfiniteScrollLinks extends StatefulWidget {
  const _InfiniteScrollLinks(this.initialOffset, this.finalOffset);

  final double initialOffset;
  final double finalOffset;

  @override
  State<_InfiniteScrollLinks> createState() => _InfiniteScrollLinksState();
}

class _InfiniteScrollLinksState extends State<_InfiniteScrollLinks> {
  static const Duration stepDuration = Duration(seconds: 20);

  late ScrollController scrollController;
  late double offset;

  @override
  void initState() {
    super.initState();

    offset = widget.initialOffset;

    scrollController = ScrollController(
      initialScrollOffset: offset,
    );

    // Without the timer the animation doesn't begin.
    Timer.run(() async {
      await scrollController.animateTo(
        widget.finalOffset,
        curve: Curves.linear,
        duration: stepDuration,
      );
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemExtent: 100.0,
      itemBuilder: (BuildContext context, int index) {
        return SizedBox(
          height: 100.0,
          child: Link(
            uri: Uri.parse('https://www.google.com'),
            builder: (BuildContext context, FollowLink? followLink) => ElevatedButton(
              onPressed: followLink,
              child: const Text('Google'),
            ),
          ),
        );
      },
    );
  }
}

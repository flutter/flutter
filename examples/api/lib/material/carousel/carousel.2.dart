// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Flutter code sample for [CarouselView] with auto-play.

void main() => runApp(const CarouselAutoPlayExampleApp());

enum CarouselType { unweighted, weighted }

class CarouselAutoPlayExampleApp extends StatelessWidget {
  const CarouselAutoPlayExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Sample - Auto-play'),
        ),
        body: const CarouselAutoPlayExample(),
      ),
    );
  }
}

class CarouselAutoPlayExample extends StatefulWidget {
  const CarouselAutoPlayExample({super.key});

  @override
  State<CarouselAutoPlayExample> createState() =>
      _CarouselAutoPlayExampleState();
}

class _CarouselAutoPlayExampleState extends State<CarouselAutoPlayExample> {
  static const int _itemCount = 10;
  final CarouselController _controller = CarouselController(initialItem: 1);
  Timer? _timer;
  int _targetIndex = 1; // Since initialItem is 1
  int _lastReportedIndex = 1;
  bool _infinite = false;
  bool _isHovering = false;
  bool _isScrolling = false;
  CarouselType _carouselType = CarouselType.unweighted;

  @override
  void initState() {
    super.initState();
    _updateTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _updateTimer() {
    if (_isHovering || _isScrolling) {
      _timer?.cancel();
      _timer = null;
    } else {
      if (_timer == null) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      if (_controller.hasClients) {
        int nextIndex = (_targetIndex + 1) % _itemCount;
        if (!_infinite &&
            _controller.offset >= _controller.position.maxScrollExtent) {
          nextIndex = 0;
        }
        _targetIndex = nextIndex;
        _controller.animateToItem(
          _targetIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.sizeOf(context).height;
    final List<Widget> children = List<Widget>.generate(_itemCount, (
      int index,
    ) {
      return Card(
        color: Colors.primaries[index % Colors.primaries.length],
        child: Center(
          child: Text('Item $index', style: const TextStyle(fontSize: 24)),
        ),
      );
    });

    return Column(
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height / 2),
          child: MouseRegion(
            onEnter: (_) {
              _isHovering = true;
              _updateTimer();
            },
            onExit: (_) {
              _isHovering = false;
              _updateTimer();
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification.depth == 0 &&
                    notification is UserScrollNotification) {
                  final bool isScrollingNow =
                      notification.direction != ScrollDirection.idle;
                  if (_isScrolling && !isScrollingNow) {
                    _targetIndex = _lastReportedIndex;
                  }
                  _isScrolling = isScrollingNow;
                  _updateTimer();
                }
                return false;
              },
              child: _carouselType == CarouselType.unweighted
                  ? CarouselView(
                      key: ValueKey<CarouselType>(_carouselType),
                      controller: _controller,
                      itemExtent: 330,
                      shrinkExtent: 200,
                      itemSnapping: true,
                      infinite: _infinite,
                      onIndexChanged: (int index) {
                        _lastReportedIndex = index;
                      },
                      children: children,
                    )
                  : CarouselView.weighted(
                      key: ValueKey<CarouselType>(_carouselType),
                      controller: _controller,
                      itemSnapping: true,
                      infinite: _infinite,
                      flexWeights: const <int>[1, 7, 1],
                      onIndexChanged: (int index) {
                        _lastReportedIndex = index;
                      },
                      children: children,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SegmentedButton<CarouselType>(
          segments: const <ButtonSegment<CarouselType>>[
            ButtonSegment<CarouselType>(
              value: CarouselType.unweighted,
              label: Text('Unweighted'),
            ),
            ButtonSegment<CarouselType>(
              value: CarouselType.weighted,
              label: Text('Weighted'),
            ),
          ],
          selected: <CarouselType>{_carouselType},
          onSelectionChanged: (Set<CarouselType> newSelection) {
            setState(() {
              _carouselType = newSelection.first;
            });
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Infinite Scrolling'),
            Switch(
              value: _infinite,
              onChanged: (bool value) {
                setState(() {
                  _infinite = value;
                  if (!_infinite &&
                      _controller.offset >=
                          _controller.position.maxScrollExtent) {
                    _targetIndex = 0;
                    _lastReportedIndex = 0;
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

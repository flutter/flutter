// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Flutter code sample for [CarouselView] with auto-play.

void main() => runApp(const CarouselAutoPlayExampleApp());

class CarouselAutoPlayExampleApp extends StatelessWidget {
  const CarouselAutoPlayExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          leading: const Icon(Icons.cast),
          title: const Text('Flutter TV - Auto-play'),
          actions: const <Widget>[
            Padding(
              padding: EdgeInsetsDirectional.only(end: 16.0),
              child: CircleAvatar(child: Icon(Icons.account_circle)),
            ),
          ],
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
  final CarouselController _controller = CarouselController(initialItem: 1);
  Timer? _timer;
  int _targetIndex = 1; // Since initialItem is 1
  int _lastReportedIndex = 1;
  bool _infinite = false;
  bool _isHovering = false;
  bool _isScrolling = false;

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
        int nextIndex = (_targetIndex + 1) % ImageInfo.values.length;
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
              child: CarouselView(
                controller: _controller,
                itemExtent: 330,
                shrinkExtent: 200,
                itemSnapping: true,
                infinite: _infinite,
                onIndexChanged: (int index) {
                  _lastReportedIndex = index;
                },
                children: ImageInfo.values.map((ImageInfo image) {
                  return HeroLayoutCard(imageInfo: image);
                }).toList(),
              ),
            ),
          ),
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

class HeroLayoutCard extends StatelessWidget {
  const HeroLayoutCard({super.key, required this.imageInfo});

  final ImageInfo imageInfo;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: <Widget>[
        ClipRect(
          child: OverflowBox(
            maxWidth: width * 7 / 8,
            minWidth: width * 7 / 8,
            child: Image(
              fit: BoxFit.cover,
              image: NetworkImage(
                'https://flutter.github.io/assets-for-api-docs/assets/material/${imageInfo.url}',
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                imageInfo.title,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                imageInfo.subtitle,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum ImageInfo {
  image0(
    'The Flow',
    'Sponsored | Season 1 Now Streaming',
    'content_based_color_scheme_1.png',
  ),
  image1(
    'Through the Pane',
    'Sponsored | Season 1 Now Streaming',
    'content_based_color_scheme_2.png',
  ),
  image2(
    'Iridescence',
    'Sponsored | Season 1 Now Streaming',
    'content_based_color_scheme_3.png',
  ),
  image3(
    'Sea Change',
    'Sponsored | Season 1 Now Streaming',
    'content_based_color_scheme_4.png',
  ),
  image4(
    'Blue Symphony',
    'Sponsored | Season 1 Now Streaming',
    'content_based_color_scheme_5.png',
  ),
  image5(
    'When It Rains',
    'Sponsored | Season 1 Now Streaming',
    'content_based_color_scheme_6.png',
  );

  const ImageInfo(this.title, this.subtitle, this.url);
  final String title;
  final String subtitle;
  final String url;
}

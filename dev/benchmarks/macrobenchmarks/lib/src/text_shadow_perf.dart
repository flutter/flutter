// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Macrobenchmark page reproducing the text shadow scrolling workload from
/// https://github.com/flutter/flutter/issues/190395.
class TextShadowPerfPage extends StatefulWidget {
  const TextShadowPerfPage({super.key});

  @override
  State<TextShadowPerfPage> createState() => _TextShadowPerfPageState();
}

class _TextShadowPerfPageState extends State<TextShadowPerfPage>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);
    _animationController.addListener(_onAnimationTick);
  }

  void _onAnimationTick() {
    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
      _scrollController.jumpTo(
        _animationController.value * _scrollController.position.maxScrollExtent,
      );
    }
  }

  @override
  void dispose() {
    _animationController.removeListener(_onAnimationTick);
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const columnCount = 7;
    const groupsPerColumn = 28;

    return Scaffold(
      backgroundColor: const Color(0xff080808),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(columnCount, (int column) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List<Widget>.generate(groupsPerColumn, (int row) {
                      return _TextShadowGroup(index: column * groupsPerColumn + row);
                    }),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TextShadowGroup extends StatelessWidget {
  const _TextShadowGroup({required this.index});

  final int index;

  static const List<Shadow> _shadows = <Shadow>[Shadow(blurRadius: 1.0)];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Synthetic text item $index',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  shadows: _shadows,
                ),
              ),
              Row(
                children: <Widget>[
                  Text(
                    '${8 + index % 14}:30',
                    style: const TextStyle(
                      color: Color(0xff43ddff),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      shadows: _shadows,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Ep ${1 + index % 24}',
                    style: const TextStyle(color: Colors.white70, fontSize: 9, shadows: _shadows),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

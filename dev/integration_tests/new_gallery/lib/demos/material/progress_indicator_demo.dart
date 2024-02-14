// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:gallery/demos/material/material_demo_types.dart';

// BEGIN progressIndicatorsDemo

class ProgressIndicatorDemo extends StatefulWidget {
  const ProgressIndicatorDemo({super.key, required this.type});

  final ProgressIndicatorDemoType type;

  @override
  State<ProgressIndicatorDemo> createState() => _ProgressIndicatorDemoState();
}

class _ProgressIndicatorDemoState extends State<ProgressIndicatorDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
      animationBehavior: AnimationBehavior.preserve,
    )..forward();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.9, curve: Curves.fastOutSlowIn),
      reverseCurve: Curves.fastOutSlowIn,
    )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          _controller.forward();
        } else if (status == AnimationStatus.completed) {
          _controller.reverse();
        }
      });
  }

  @override
  void dispose() {
    _controller.stop();
    super.dispose();
  }

  String get _title {
    switch (widget.type) {
      case ProgressIndicatorDemoType.circular:
        return GalleryLocalizations.of(context)!
            .demoCircularProgressIndicatorTitle;
      case ProgressIndicatorDemoType.linear:
        return GalleryLocalizations.of(context)!
            .demoLinearProgressIndicatorTitle;
    }
  }

  Widget _buildIndicators(BuildContext context, Widget? child) {
    switch (widget.type) {
      case ProgressIndicatorDemoType.circular:
        return Column(
          children: [
            CircularProgressIndicator(
              semanticsLabel: GalleryLocalizations.of(context)!.loading,
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(value: _animation.value),
          ],
        );
      case ProgressIndicatorDemoType.linear:
        return Column(
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 32),
            LinearProgressIndicator(value: _animation.value),
          ],
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(8),
            child: AnimatedBuilder(
              animation: _animation,
              builder: _buildIndicators,
            ),
          ),
        ),
      ),
    );
  }
}

// END

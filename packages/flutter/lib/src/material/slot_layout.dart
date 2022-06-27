// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'slot_layout_config.dart';

/// A Widget that takes a mapping of [SlotLayoutConfig]s to breakpoints and returns a chosen
/// Widget based on the current screen size.
///
/// Commonly used with [AdaptiveLayout] but also functional on its own.

// ignore: must_be_immutable
class SlotLayout extends StatefulWidget {

  /// Creates a [SlotLayout].
  ///
  /// Returns a chosen [SlotLayoutConfig] based on the breakpoints defined in
  /// the [config]
  SlotLayout({
    required this.config,
    required super.key
    });

  /// Whether this slot has a Widget currently chosen.
  bool isActive = false;

  /// The mapping that is used to determine what Widget to display at what point.
  ///
  /// The int represents screen width.
  final Map<int, SlotLayoutConfig> config;
  @override
  State<SlotLayout> createState() => _SlotLayoutState();
}

class _SlotLayoutState extends State<SlotLayout> with SingleTickerProviderStateMixin{
  late AnimationController _controller;
  late SlotLayoutConfig chosenWidget;
  ValueNotifier<Key> changedWidget = ValueNotifier<Key>(const Key(''));

  @override
  void initState() {
    changedWidget.addListener(() {
      _controller.reset();
      _controller.forward();
    });

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    chosenWidget = SlotLayoutConfig(key: const Key(''), child: const SizedBox(width: 0, height: 0));
    widget.isActive = false;
    widget.config.forEach((int key, SlotLayoutConfig value) {
      pickWidget(context, key, value);
    });
    chosenWidget.controller = _controller;
    changedWidget.value = chosenWidget.key!;
    return chosenWidget;
  }

  void pickWidget(BuildContext context, int key, SlotLayoutConfig value) {
    if(MediaQuery.of(context).size.width > key) {
        widget.isActive = true;
        chosenWidget = value;
    }
  }
}

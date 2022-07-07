// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'animated_switcher.dart';
import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';
import 'slot_layout_config.dart';
import 'ticker_provider.dart';

/// A Widget that takes a mapping of [SlotLayoutConfig]s to breakpoints and returns a chosen
/// Widget based on the current screen size.
///
/// Commonly used with [AdaptiveLayout] but also functional on its own.

class SlotLayout extends StatefulWidget {
  /// Creates a [SlotLayout] widget.
  const SlotLayout({
    required this.config,
    super.key
    });

  /// Given a context and a config, it returns the [SlotLayoutConfig] that will
  /// be chosen from the config under the context's conditions
  static SlotLayoutConfig? pickWidget (BuildContext context,  Map<int, SlotLayoutConfig?> config){
    SlotLayoutConfig? chosenWidget;
    config.forEach((int key, SlotLayoutConfig? value) {
      if(MediaQuery.of(context).size.width > key){
        chosenWidget = value;
      }
    });
    return chosenWidget;
  }

  /// The mapping that is used to determine what Widget to display at what point.
  ///
  /// The int represents screen width.
  final Map<int, SlotLayoutConfig?> config;
  @override
  State<SlotLayout> createState() => _SlotLayoutState();
}

class _SlotLayoutState extends State<SlotLayout> with SingleTickerProviderStateMixin{
  late AnimationController _controller;
  SlotLayoutConfig? chosenWidget;
  ValueNotifier<Key> changedWidget = ValueNotifier<Key>(const Key(''));
  List<Key> animatingWidgets = <Key>[];

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
    chosenWidget = SlotLayout.pickWidget(context, widget.config);
    if(chosenWidget!=null){
      changedWidget.value = chosenWidget!.key!;
    }
    return AnimatedSwitcher(
      duration:const Duration(milliseconds:1000),
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        final Stack elements = Stack(
          children: <Widget>[
            if (chosenWidget?.overtakeAnimation!=null && !previousChildren.contains(currentChild)) ...previousChildren.where((Widget element) => element.key!=currentChild!.key),
            if (currentChild != null) currentChild,
          ],
        );
        return elements;
      },

      transitionBuilder: (Widget child, Animation<double> animation){
        if(child.key == chosenWidget?.key){
          return (chosenWidget?.inAnimation!=null)? chosenWidget?.inAnimation!(child, _controller)?? child : child;
        }else{
          return (chosenWidget?.overtakeAnimation!=null)? chosenWidget?.overtakeAnimation!(child, _controller)?? child : child;
        }
      },
      child:chosenWidget ?? const SlotLayoutConfig(key: Key(''), child: SizedBox(width: 0, height: 0)),
    );
  }
}

import 'breakpoint.dart';
import 'package:flutter/material.dart';

import 'slot_widget.dart';

class Slot extends StatefulWidget {
  Map<Breakpoint, SlotWidget>? breakpointWidgets;

  Slot({
    this.breakpointWidgets,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _SlotState();
}

class _SlotState extends State<Slot> with SingleTickerProviderStateMixin {
  late final ValueNotifier<Key> _animationTracker =
      ValueNotifier<Key>(const Key(' '));
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 1000),
    vsync: this,
  );

  @override
  void initState() {
    _animationTracker.addListener(() {
      _controller.reset();
      _controller.forward();
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SlotWidget? thisWidget = SlotWidget();
    bool exited = false;
    for (Breakpoint breakpoint in widget.breakpointWidgets!.keys) {
      if (breakpoint.isActive(context)) {
        thisWidget = widget.breakpointWidgets![breakpoint];
      }
    }

    if (thisWidget != null) _animationTracker.value = thisWidget.key!;

    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          final Stack elements = Stack(
            children: <Widget>[
              if (exited)
                ...previousChildren
                    .where((element) => element.key != currentChild!.key),
              if (currentChild != null) currentChild,
            ],
          );
          return elements;
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          final SlotWidget slotWidget = child as SlotWidget;

          if (slotWidget.enterAnimation == null &&
              slotWidget.exitAnimation == null) {
            return child;
          } else if (child.key != slotWidget.key) {
            exited = true;
            return child.exitAnimation!(child, _controller);
          }
          return child.enterAnimation!(child, _controller);
        },
        child: thisWidget);
  }
}

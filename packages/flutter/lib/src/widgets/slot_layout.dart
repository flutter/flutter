import 'package:flutter/material.dart';
import 'slot_layout_config.dart';


/// The [SlotLayout] Widget is reponsible for picking a widget to display on the
/// screen based on the breakpoints given in the config parameter.

// ignore: must_be_immutable
class SlotLayout extends StatefulWidget {
  SlotLayout({
    required this.config,
    super.key
    });

  bool isActive = false;
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

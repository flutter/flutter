import 'dart:collection';

import 'package:flutter/widgets.dart';

class Spaced with ListMixin<Widget> {
  Spaced.vertical({
    required double space,
    required List<Widget> children,
  }) : _children = createSpacedList(
          direction: Axis.vertical,
          space: space,
          children: children,
        );

  Spaced.horizontal({
    required double space,
    required List<Widget> children,
  }) : _children = createSpacedList(
          direction: Axis.horizontal,
          space: space,
          children: children,
        );

  @override
  int get length => _children.length;

  @override
  set length(int newLength) {
    throw StateError('The length of the spaced list can not be modified');
  }

  final List<Widget> _children;

  @visibleForTesting
  static List<Widget> createSpacedList({
    required List<Widget> children,
    required double space,
    required Axis direction,
  }) {
    final SizedBox sizedBox = direction == Axis.vertical
        ? SizedBox(height: space)
        : SizedBox(width: space);

    return children
        .expand((Widget widget) => [sizedBox, widget])
        .skip(1)
        .toList();
  }

  @override
  Widget operator [](int index) => _children[index];

  @override
  void operator []=(int index, Widget value) {
    throw StateError('The spaced list can not be modified');
  }

  @override
  void add(Widget element) {
    throw StateError('The spaced list can not be modified');
  }
}

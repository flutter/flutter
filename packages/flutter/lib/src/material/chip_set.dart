// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

///Builds a custom chip widget for a given item of type T
///- BuildContext context: The build context in which the widget is being built.
///- T item: An item of type T from the list of items provided to the ChipSet.
///- bool selected: A boolean flag indicating whether the current item is selected or not.
///- void Function(bool value) onSelected: A callback function that is triggered when a chip is selected or deselected. It accepts a boolean value to indicate the selection state.
typedef ChipBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  bool selected,
  void Function(bool value) onSelected,
);

///A Material Design widget that displays a set of chips
///based on a list of items of type [T].
///
///The type T is the type of the value that each chip item represents.
///All the entries in a given set must represent values
///with consistent types. Each item in items must be specialized
///with that same type argument. The chips can be created
///using a custom [ChipBuilder] function or the default
///implementation using [RawChip].
///
///[ChipSet] supports customizing the appearance and layout of each chip.
///The chips render in a [Wrap] and render horiontally by default.
///
///The onSelected callback should update a state list
///that defines the selected value. It should also call [State.setState]
///to rebuild the set with the new values.
class ChipSet<T> extends StatefulWidget {
  /// Creates a [ChipSet].
  ///
  /// The [items] must have distinct values.
  ///
  /// The [onSelected] callback must update a state selected list
  ///
  /// The [isSelected] callback must return a boolean value
  /// based on the state selected list
  const ChipSet({
    required this.items,
    required this.onSelected,
    required this.isSelected,
    this.chipBuilder,
    this.spacing,
    this.runSpacing,
    this.constraints,
    this.direction,
    super.key,
  });

  /// An optional custom ChipBuilder function to build the chips.
  /// If not provided, the default implementation using RawChip will be used.
  /// and the chips will display a [toString] of the item.
  final ChipBuilder<T>? chipBuilder;

  ///A function that returns true if the item is selected, otherwise false.
  final bool Function(T item) isSelected;

  ///A list of items of type [T] that the chips will be built from.
  final List<T> items;

  ///An optional set of constraints to apply to the size of the chips
  ///in the ChipSet.
  final BoxConstraints? constraints;

  ///How much space to place between chips in a run in the main axis.
  final double? spacing;

  ///How much space to place between the runs themselves in the cross axis.
  final double? runSpacing;

  ///The direction to use as the main axis.
  final Axis? direction;

  ///A callback function that is triggered when a chip is selected or deselected.
  final void Function(T item, bool value) onSelected;

  @override
  State<ChipSet<T>> createState() => _ChipSetState<T>();
}

class _ChipSetState<T> extends State<ChipSet<T>> {
  @override
  Widget build(BuildContext context) => Wrap(
        direction: widget.direction ?? Axis.horizontal,
        spacing: widget.spacing ?? 0,
        runSpacing: widget.runSpacing ?? 0,
        children:
            widget.items.map((T item) => _buildItem(context, item)).toList(),
      );

  Widget _rawChip(
    BuildContext context,
    T item,
    bool selected,
    void Function(bool value) onSelected,
  ) =>
      RawChip(
        selected: selected,
        label: Text(item.toString()),
        onSelected: (bool value) => setState(() {
          onSelected(value);
        }),
      );

  Widget _buildItem(
    BuildContext context,
    T item,
  ) {
    final ChipBuilder<T> builder = widget.chipBuilder ?? _rawChip;

    final Widget child = builder(
      context,
      item,
      widget.isSelected(item),
      (bool value) => widget.onSelected(item, value),
    );

    if (widget.constraints != null) {
      return ConstrainedBox(
        constraints: widget.constraints!,
        child: child,
      );
    }

    return child;
  }
}

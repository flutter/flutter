import 'package:flutter/material.dart';
import 'breakpoint.dart';
import 'breakpoints.dart';
import 'package:masonry_grid/masonry_grid.dart';

const double materialGutterValue = 8;
const double materialCompactMinMargin = 8;
const double materialMediumMinMargin = 8;
const double materialExpandedMinMargin = 8;

class SlotWidget extends StatefulWidget {
  List<Widget>? slotWidgets;

  AnimatedWidget Function(Widget widget, AnimationController controller)?
      enterAnimation;

  AnimatedWidget Function(Widget widget, AnimationController controller)?
      exitAnimation;

  bool? useMaterialBody = false;

  double? margin = 20;

  int? itemColumns = 1;

  List<Breakpoint>? breakpoints;

  SlotWidget({
    this.slotWidgets,
    this.enterAnimation,
    this.exitAnimation,
    this.useMaterialBody,
    this.margin,
    this.itemColumns,
    this.breakpoints,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _SlotWidgetState();
}

class _SlotWidgetState extends State<SlotWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.slotWidgets != null) {
      if (widget.slotWidgets!.length == 1) {
        return widget.slotWidgets![0];
      } else if (widget.slotWidgets!.length > 1 &&
          widget.useMaterialBody == true) {
        return ResponsiveColumnGrid(
          thisWidgets: widget.slotWidgets!,
          itemColumns: widget.itemColumns!,
          margin: widget.margin!,
          breakpoints: widget.breakpoints!,
        );
      }
    }
    return const SizedBox(
      width: 0,
      height: 0,
    );
  }
}

class ResponsiveColumnGrid extends StatefulWidget {
  List<Widget> thisWidgets;

  int itemColumns;

  double margin;

  List<Breakpoint> breakpoints;

  ResponsiveColumnGrid({
    Key? key,
    required this.thisWidgets,
    required this.itemColumns,
    required this.margin,
    required this.breakpoints,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ResponsiveColumnGridState();
}

class _ResponsiveColumnGridState extends State<ResponsiveColumnGrid> {
  @override
  Widget build(BuildContext context) {
    Breakpoint currentBreakpoint = CompactBreakpoint();
    for (Breakpoint breakpoint in widget.breakpoints) {
      if (breakpoint.isActive(context)) {
        currentBreakpoint = breakpoint;
      }
    }
    double? thisMargin = widget.margin;

    if (currentBreakpoint == CompactBreakpoint()) {
      if (thisMargin < materialCompactMinMargin) {
        thisMargin = materialCompactMinMargin;
      }
    } else if (currentBreakpoint == const MediumBreakpoint()) {
      if (thisMargin < materialMediumMinMargin) {
        thisMargin = materialMediumMinMargin;
      }
    } else if (currentBreakpoint == const ExpandedBreakpoint()) {
      if (thisMargin < materialExpandedMinMargin) {
        thisMargin = materialExpandedMinMargin;
      }
    }

    return CustomScrollView(
      primary: false,
      controller: ScrollController(),
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(thisMargin),
            child: MasonryGrid(
              column: widget.itemColumns,
              crossAxisSpacing: materialGutterValue,
              mainAxisSpacing: materialGutterValue,
              children: widget.thisWidgets,
            ),
          ),
        ),
      ],
    );
  }
}

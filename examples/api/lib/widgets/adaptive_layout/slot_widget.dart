import 'package:flutter/material.dart';
import 'breakpoint.dart';
import 'breakpoints.dart';
import 'package:masonry_grid/masonry_grid.dart';

const double materialPaddingBetweenItems = 8;

Map<Breakpoint, double> materialMinMargin = {
  CompactBreakpoint(): 8,
  MediumBreakpoint(): 12,
  ExpandedBreakpoint(): 32
};

class SlotWidget extends StatefulWidget {
  List<Widget>? slotWidgets;

  AnimatedWidget Function(Widget widget, AnimationController controller)?
      enterAnimation;

  AnimatedWidget Function(Widget widget, AnimationController controller)?
      exitAnimation;

  bool? isBody = false;

  double? margin = 20;

  double? gutter = 8;

  int? itemColumns = 1;

  List<Breakpoint>? breakpoints;

  SlotWidget({
    this.slotWidgets,
    this.enterAnimation,
    this.exitAnimation,
    this.isBody,
    this.margin,
    this.gutter,
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
      } else if (widget.slotWidgets!.length > 1 && widget.isBody == true) {
        return ResponsiveColumnGrid(
          thisWidgets: widget.slotWidgets!,
          itemColumns: widget.itemColumns!,
          margin: widget.margin!,
          gutter: (widget.gutter != null) ? widget.gutter! : 8,
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

  double gutter;

  List<Breakpoint> breakpoints;

  ResponsiveColumnGrid({
    Key? key,
    required this.thisWidgets,
    required this.itemColumns,
    required this.margin,
    required this.gutter,
    required this.breakpoints,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ResponsiveColumnGridState();
}

class _ResponsiveColumnGridState extends State<ResponsiveColumnGrid> {
  @override
  Widget build(BuildContext context) {
    if (widget.itemColumns <= 1) {
      return Container(
          child: CustomScrollView(
        primary: false,
        controller: ScrollController(),
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(widget.margin),
              child: MasonryGrid(
                column: widget.itemColumns,
                mainAxisSpacing: materialPaddingBetweenItems,
                children: widget.thisWidgets,
              ),
            ),
          ),
        ],
      ));
    } else {
      Breakpoint currentBreakpoint = CompactBreakpoint();
      for (Breakpoint breakpoint in widget.breakpoints) {
        if (breakpoint.isActive(context)) {
          currentBreakpoint = breakpoint;
        }
      }
      double? thisMargin = widget.margin;
      double? thisGutter = widget.gutter;

      if (materialMinMargin[currentBreakpoint]! > thisMargin) {
        thisMargin = materialMinMargin[currentBreakpoint]!;
      }

      return Container(
          child: CustomScrollView(
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
                crossAxisSpacing: widget.gutter,
                mainAxisSpacing: materialPaddingBetweenItems,
                children: widget.thisWidgets,
              ),
            ),
          ),
        ],
      ));
    }
  }
}

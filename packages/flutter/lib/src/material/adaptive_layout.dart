// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'slot_layout.dart';
import 'slot_layout_config.dart';

/// A parent Widget takes in multiple [SlotLayout] components and places them
/// into their appropriate positions on the screen.

class AdaptiveLayout extends StatefulWidget {

  /// Creates an [AdaptiveLayout] widget.
  const AdaptiveLayout({
    this.primaryNavigation,
    this.secondaryNavigation,
    this.topNavigation,
    this.bottomNavigation,
    this.body,
    this.secondaryBody,
    this.bodyRatio,
    this.bodyAnimated = true,
    this.horizontalBody = true,
    super.key,
  });

  /// The slot placed on the beginning side of the screen
  ///
  /// Note: if using flexibly sized Widgets like [Container], wrap the Widget in a
  /// [SizedBox] or limit its size by any other method.
  final SlotLayout? primaryNavigation;

  /// The slot placed on the end side of the screen
  ///
  /// Note: if using flexibly sized Widgets like [Container], wrap the Widget in a
  /// [SizedBox] or limit its size by any other method.
  final SlotLayout? secondaryNavigation;

  /// The slot placed on the top part of the screen
  ///
  /// Note: if using flexibly sized Widgets like [Container], wrap the Widget in a
  /// [SizedBox] or limit its size by any other method.
  final SlotLayout? topNavigation;

  /// The slot placed on the bottom part of the screen
  ///
  /// Note: if using flexibly sized Widgets like [Container], wrap the Widget in a
  /// [SizedBox] or limit its size by any other method.
  final SlotLayout? bottomNavigation;

  /// The slot that fills the rest of the space in the center.
  final SlotLayout? body;

  /// A supporting slot for body. Has a sliding entrance animation by default.
  /// The default ratio for the split between body and secondaryBody is so that
  /// the split axis is in the center of the screen.
  final SlotLayout? secondaryBody;

  /// Defines the fractional ratio of body to body left.
  ///
  /// For example 1 / 3 would mean body takes up 1/3 of the available space and
  /// secondaryBody takes up the rest.
  ///
  /// If this value is null, the ratio is defined so that the split axis is in
  /// the center of the screen.
  final double? bodyRatio;

  /// Whether or not the developer wants the smooth entering slide transition on
  /// secondaryBody.
  ///
  /// Defaults to true.
  final bool bodyAnimated;

  /// Whether to orient the body and secondaryBody in horizontal order (true) or
  /// in vertical order (false).
  ///
  /// Defaults to true.
  final bool horizontalBody;

  @override
  State<AdaptiveLayout> createState() => _AdaptiveLayoutState();
}

class _AdaptiveLayoutState extends State<AdaptiveLayout> with TickerProviderStateMixin {
  late AnimationController _controller;
  ValueNotifier<bool?> bodyNotifier = ValueNotifier<bool?>(false);
  late Map<String, SlotLayoutConfig?> chosenWidgets = <String, SlotLayoutConfig?>{};

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();
    bodyNotifier.value = chosenWidgets['secondaryBody'] != null;
    bodyNotifier.addListener(() {
      if (bodyNotifier.value ?? true) {
        _controller.reset();
        _controller.forward();
      }
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
    final Map<String, SlotLayout?> slots = <String, SlotLayout?>{
      'primaryNavigation': widget.primaryNavigation,
      'secondaryNavigation': widget.secondaryNavigation,
      'topNavigation': widget.topNavigation,
      'bottomNavigation': widget.bottomNavigation,
      'body': widget.body,
      'secondaryBody': widget.secondaryBody,
    };
    chosenWidgets = <String, SlotLayoutConfig?>{};

    slots.forEach((String key, SlotLayout? value) {
      slots.update(
        key,
        (SlotLayout? val) => val,
        ifAbsent: () => value,
      );
      chosenWidgets.update(
        key,
        (SlotLayoutConfig? val) => val,
        ifAbsent: () => SlotLayout.pickWidget(context, value?.config ?? <int, SlotLayoutConfig>{}),
      );
    });
    final List<Widget> entries = slots.entries
        .map((MapEntry<String, SlotLayout?> entry) {
          if (entry.value != null) {
            return LayoutId(id: entry.key, child: entry.value ?? Container());
          }
        })
        .whereType<Widget>()
        .toList();
    bodyNotifier.value = chosenWidgets['secondaryBody'] != null;
    return CustomMultiChildLayout(
      delegate: _AdaptiveLayoutDelegate(
        notifier: bodyNotifier,
        controller: _controller,
        slots: slots,
        bodyRatio: widget.bodyRatio,
        bodyAnimated: widget.bodyAnimated,
        horizontalBody: widget.horizontalBody,
        chosenWidgets: chosenWidgets,
        textDirection: Directionality.of(context) == TextDirection.ltr,
      ),
      children: entries,
    );
  }
}

/// The delegate responsible for laying out the slots in their correct positions.
class _AdaptiveLayoutDelegate extends MultiChildLayoutDelegate {
  _AdaptiveLayoutDelegate({
    required this.slots,
    required this.bodyRatio,
    required this.controller,
    required this.notifier,
    required this.bodyAnimated,
    required this.horizontalBody,
    required this.chosenWidgets,
    required this.textDirection,
  }) : super(relayout: controller);

  final Map<String, SlotLayout?> slots;
  final double? bodyRatio;
  final AnimationController controller;
  final ValueNotifier<bool?> notifier;
  final bool bodyAnimated;
  final bool horizontalBody;
  final bool textDirection;
  final Map<String, SlotLayoutConfig?> chosenWidgets;

  @override
  void performLayout(Size size) {
    Offset bodyOffsetLT = Offset.zero;
    Offset bodyOffsetRB = Offset.zero;

    double animatedSize(double begin, double end) {
      return bodyAnimated
          ? Tween<double>(begin: begin, end: end)
              .animate(CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic))
              .value
          : end;
    }

    if (hasChild('primaryNavigation')) {
      final Size currentSize = layoutChild('primaryNavigation', BoxConstraints.loose(size));
      if (textDirection) {
        positionChild('primaryNavigation', Offset.zero);
        bodyOffsetLT += Offset(currentSize.width, 0);
      } else {
        positionChild('primaryNavigation', Offset(size.width - currentSize.width, 0));
        bodyOffsetRB += Offset(currentSize.width, 0);
      }
    }
    if (hasChild('secondaryNavigation')) {
      final Size currentSize = layoutChild('secondaryNavigation', BoxConstraints.loose(size));
      if (textDirection) {
        positionChild('secondaryNavigation', Offset(size.width - currentSize.width, 0));
        bodyOffsetRB += Offset(currentSize.width, 0);
      } else {
        positionChild('secondaryNavigation', Offset.zero);
        bodyOffsetLT += Offset(currentSize.width, 0);
      }
    }
    if (hasChild('topNavigation')) {
      final Size currentSize = layoutChild('topNavigation', BoxConstraints.loose(size));
      positionChild('topNavigation', Offset.zero);
      bodyOffsetLT += Offset(0, currentSize.height);
    }
    if (hasChild('bottomNavigation')) {
      final Size currentSize = layoutChild('bottomNavigation', BoxConstraints.loose(size));
      positionChild('bottomNavigation', Offset(0, size.height - currentSize.height));
      bodyOffsetRB += Offset(0, currentSize.height);
    }

    if (hasChild('body') && hasChild('secondaryBody')) {
      Size currentSize;
      if (chosenWidgets['secondaryBody'] == null) {
        currentSize = layoutChild(
            'body',
            BoxConstraints.tight(
                Size(size.width - bodyOffsetRB.dx - bodyOffsetLT.dx, size.height - bodyOffsetRB.dy - bodyOffsetLT.dy)));
        layoutChild('secondaryBody', BoxConstraints.loose(size));
      } else {
        if (horizontalBody) {
          if (textDirection) {
            currentSize = layoutChild(
              'body',
              BoxConstraints.tight(
                Size(
                  animatedSize(
                      size.width - bodyOffsetRB.dx - bodyOffsetLT.dx,
                      bodyRatio == null
                          ? size.width / 2 - bodyOffsetRB.dx - bodyOffsetLT.dx
                          : (size.width - bodyOffsetRB.dx - bodyOffsetLT.dx) * bodyRatio!),
                  size.height - bodyOffsetRB.dy - bodyOffsetLT.dy,
                ),
              ),
            );
            layoutChild(
                'secondaryBody',
                BoxConstraints.tight(Size(
                    bodyRatio == null
                        ? size.width / 2
                        : (size.width - bodyOffsetRB.dx - bodyOffsetLT.dx) * (1 - bodyRatio!),
                    size.height - bodyOffsetRB.dy - bodyOffsetLT.dy)));
          } else {
            // RTL
            currentSize = layoutChild(
              'secondaryBody',
              BoxConstraints.tight(
                Size(
                  animatedSize(
                      0,
                      bodyRatio == null
                          ? size.width / 2
                          : size.width * (1 - bodyRatio!) - bodyOffsetRB.dx - bodyOffsetLT.dx),
                  size.height - bodyOffsetRB.dy - bodyOffsetLT.dy,
                ),
              ),
            );
            layoutChild(
                'body',
                BoxConstraints.tight(Size(
                    bodyRatio == null ? size.width / 2 - bodyOffsetRB.dx - bodyOffsetLT.dx : size.width * bodyRatio!,
                    size.height - bodyOffsetRB.dy - bodyOffsetLT.dy)));
          }
        } else {
          currentSize = layoutChild(
              'body',
              BoxConstraints.tight(Size(
                size.width - bodyOffsetRB.dx - bodyOffsetLT.dx,
                animatedSize(
                    size.height - bodyOffsetRB.dy - bodyOffsetLT.dy,
                    bodyRatio == null
                        ? size.height / 2
                        : (size.height - bodyOffsetRB.dy - bodyOffsetLT.dy) * bodyRatio!),
              )));
          layoutChild(
              'secondaryBody',
              BoxConstraints.tight(bodyRatio == null
                  ? Size(size.width - bodyOffsetRB.dx - bodyOffsetLT.dx, size.height / 2)
                  : Size((size.width - bodyOffsetRB.dx - bodyOffsetLT.dx) * (1 - bodyRatio!),
                      size.height - bodyOffsetRB.dy - bodyOffsetLT.dy)));
        }
      }
      if (horizontalBody && !textDirection && chosenWidgets['secondaryBody'] != null) {
        positionChild('body', Offset(bodyOffsetLT.dx + currentSize.width, bodyOffsetLT.dy));
        positionChild('secondaryBody', bodyOffsetLT);
      } else {
        positionChild('body', bodyOffsetLT);
        if (horizontalBody) {
          positionChild('secondaryBody', Offset(bodyOffsetLT.dx + currentSize.width, bodyOffsetLT.dy));
        } else {
          positionChild('secondaryBody', Offset(bodyOffsetLT.dx, bodyOffsetLT.dy + currentSize.height));
        }
      }
    } else if (hasChild('body')) {
      layoutChild(
        'body',
        BoxConstraints.tight(
            Size(size.width - bodyOffsetRB.dx - bodyOffsetLT.dx, size.height - bodyOffsetRB.dy - bodyOffsetLT.dy)),
      );
      positionChild('body', bodyOffsetLT);
    } else if (hasChild('secondaryBody')) {
      layoutChild(
        'secondaryBody',
        BoxConstraints.tight(
            Size(size.width - bodyOffsetRB.dx - bodyOffsetLT.dx, size.height - bodyOffsetRB.dy - bodyOffsetLT.dy)),
      );
    }
  }

  @override
  bool shouldRelayout(_AdaptiveLayoutDelegate oldDelegate) {
    return oldDelegate.slots != slots;
  }
}

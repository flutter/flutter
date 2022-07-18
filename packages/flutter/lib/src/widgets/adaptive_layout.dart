// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';
import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';
import 'slot_layout.dart';
import 'slot_layout_config.dart';
import 'ticker_provider.dart';


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
    this.internalAnimations = true,
    this.horizontalBody = true,
    super.key,
  });

  /// The slot placed on the beginning side of the screen.
  ///
  /// Note: if using flexibly sized Widgets like [Container], wrap the Widget in a
  /// [SizedBox] or limit its size by any other method.
  final SlotLayout? primaryNavigation;

  /// The slot placed on the end side of the screen.
  ///
  /// Note: if using flexibly sized Widgets like [Container], wrap the Widget in a
  /// [SizedBox] or limit its size by any other method.
  final SlotLayout? secondaryNavigation;

  /// The slot placed on the top part of the screen.
  ///
  /// Note: if using flexibly sized Widgets like [Container], wrap the Widget in a
  /// [SizedBox] or limit its size by any other method.
  final SlotLayout? topNavigation;

  /// The slot placed on the bottom part of the screen.
  ///
  /// Note: if using flexibly sized Widgets like [Container], wrap the Widget in a
  /// [SizedBox] or limit its size by any other method.
  final SlotLayout? bottomNavigation;

  /// The slot that fills the rest of the space in the center.
  final SlotLayout? body;

  /// A supporting slot for [body]. Has a sliding entrance animation by default.
  /// The default ratio for the split between [body] and [secondaryBody] is so
  /// that the split axis is in the center of the screen.
  final SlotLayout? secondaryBody;

  /// Defines the fractional ratio of [body] to the [secondaryBody].
  ///
  /// For example 1 / 3 would mean [body] takes up 1/3 of the available space
  /// and[secondaryBody] takes up the rest.
  ///
  /// If this value is null, the ratio is defined so that the split axis is in
  /// the center of the screen.
  final double? bodyRatio;

  /// Whether or not the developer wants the smooth entering slide transition on
  /// [secondaryBody].
  ///
  /// Defaults to true.
  final bool internalAnimations;

  /// Whether to orient the body and secondaryBody in horizontal order (true) or
  /// in vertical order (false).
  ///
  /// Defaults to true.
  final bool horizontalBody;

  @override
  State<AdaptiveLayout> createState() => _AdaptiveLayoutState();
}
const String _primaryNavigationID = 'primaryNavigation';
const String _secondaryNavigationID = 'secondaryNavigation';
const String _topNavigationID = 'topNavigation';
const String _bottomNavigationID = 'bottomNavigation ';
const String _bodyID = 'body';
const String _secondaryBodyID = 'secondaryBody';

class _AdaptiveLayoutState extends State<AdaptiveLayout> with TickerProviderStateMixin {
  late AnimationController _controller;

  late Map<String, SlotLayoutConfig?> chosenWidgets = <String, SlotLayoutConfig?>{};
  Map<String, Size?> slotSizes = <String, Size?>{
      _primaryNavigationID: Size.zero,
      _secondaryNavigationID: Size.zero,
      _topNavigationID: Size.zero,
      _bottomNavigationID: Size.zero,
  };

  Map<String, ValueNotifier<Key?>> notifiers = <String, ValueNotifier<Key?>>{
    _primaryNavigationID: ValueNotifier<Key?>(null),
    _secondaryNavigationID: ValueNotifier<Key?>(null),
    _topNavigationID: ValueNotifier<Key?>(null),
    _bottomNavigationID: ValueNotifier<Key?>(null),
    _bodyID: ValueNotifier<Key?>(null),
    _secondaryBodyID: ValueNotifier<Key?>(null),
  };

  Map<String, bool> isAnimating = <String, bool>{
    _primaryNavigationID: false,
    _secondaryNavigationID: false,
    _topNavigationID: false,
    _bottomNavigationID: false,
    _bodyID: false,
    _secondaryBodyID: false,
  };


  @override
  void initState() {
    if (widget.internalAnimations) {
      _controller = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      )..forward();
    } else {
      _controller = AnimationController(
        duration: Duration.zero,
        vsync: this,
      );
    }

    notifiers.forEach((String key, ValueNotifier<Key?> notifier) {
      notifier.addListener(() {
        isAnimating[key] = true;
        _controller.reset();
        _controller.forward();
      });
    });

     _controller.addStatusListener((AnimationStatus status) {
        if(status == AnimationStatus.completed){
          isAnimating.updateAll((_,__) => false);
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
      _primaryNavigationID: widget.primaryNavigation,
      _secondaryNavigationID: widget.secondaryNavigation,
      _topNavigationID: widget.topNavigation,
      _bottomNavigationID: widget.bottomNavigation,
      _bodyID: widget.body,
      _secondaryBodyID: widget.secondaryBody,
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
        ifAbsent: () => SlotLayout.pickWidget(context, value?.config ?? <int, SlotLayoutConfig?>{}),
      );
    });
    final List<Widget> entries = slots.entries
        .map((MapEntry<String, SlotLayout?> entry) {
          if (entry.value != null) {
            return LayoutId(id: entry.key, child: entry.value ?? const SizedBox());
          }
        })
        .whereType<Widget>()
        .toList();
    notifiers.forEach((String key, ValueNotifier<Key?> notifier) {
      notifier.value = chosenWidgets[key]?.key;
    });


    Rect? hinge;
    for (final DisplayFeature e in MediaQuery.of(context).displayFeatures) {
      if (e.type == DisplayFeatureType.hinge || e.type == DisplayFeatureType.fold){
        if(e.bounds.left!=0){
          hinge = e.bounds;
        }
      }
    }

    return CustomMultiChildLayout(
      delegate: _AdaptiveLayoutDelegate(
        slots: slots,
        chosenWidgets: chosenWidgets,
        slotSizes: slotSizes,
        controller: _controller,
        bodyRatio: widget.bodyRatio,
        isAnimating: isAnimating,
        internalAnimations: widget.internalAnimations,
        horizontalBody: widget.horizontalBody,
        textDirection: Directionality.of(context) == TextDirection.ltr,
        hinge: hinge,
      ),
      children: entries,
    );
  }
}

/// The delegate responsible for laying out the slots in their correct positions.
class _AdaptiveLayoutDelegate extends MultiChildLayoutDelegate {
  _AdaptiveLayoutDelegate({
    required this.slots,
    required this.chosenWidgets,
    required this.slotSizes,
    required this.controller,
    required this.bodyRatio,
    required this.isAnimating,
    required this.internalAnimations,
    required this.horizontalBody,
    required this.textDirection,
    this.hinge,
  }) : super(relayout: controller);

  final Map<String, SlotLayout?> slots;
  final Map<String, SlotLayoutConfig?> chosenWidgets;
  final Map<String, Size?> slotSizes;
  final Map<String, bool> isAnimating;
  final AnimationController controller;
  final double? bodyRatio;
  final bool internalAnimations;
  final bool horizontalBody;
  final bool textDirection;
  final Rect? hinge;

  @override
  void performLayout(Size size) {

    double leftMargin = 0;
    double topMargin = 0;
    double rightMargin = 0;
    double bottomMargin = 0;

    double animatedSize(double begin, double end) {
      if(isAnimating[_secondaryBodyID]!){
        return internalAnimations
            ? Tween<double>(begin: begin, end: end)
                .animate(CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic))
                .value
            : end;
      }
      return end;
    }

    if (hasChild(_topNavigationID)) {
      final Size childSize = layoutChild(_topNavigationID, BoxConstraints.loose(size));
      updateSize(_topNavigationID, childSize);
      final Size currentSize = Tween<Size>(begin:slotSizes[_topNavigationID], end:childSize).animate(controller).value;
      positionChild(_topNavigationID, Offset.zero);
      topMargin += currentSize.height;
    }
    if (hasChild(_bottomNavigationID)) {
      final Size childSize = layoutChild(_bottomNavigationID, BoxConstraints.loose(size));
      updateSize(_bottomNavigationID, childSize);
      final Size currentSize = Tween<Size>(begin:slotSizes[_bottomNavigationID], end:childSize).animate(controller).value;
      positionChild(_bottomNavigationID, Offset(0, size.height - currentSize.height));
      bottomMargin += currentSize.height;
    }
    if (hasChild(_primaryNavigationID)) {
      final Size childSize = layoutChild(_primaryNavigationID, BoxConstraints.loose(size));
      updateSize(_primaryNavigationID, childSize);
      final Size currentSize = Tween<Size>(begin:slotSizes[_primaryNavigationID], end:childSize).animate(controller).value;
      if (textDirection) {
        positionChild(_primaryNavigationID, Offset(leftMargin, topMargin));
        leftMargin += currentSize.width;
      } else {
        positionChild(_primaryNavigationID, Offset(size.width - currentSize.width, topMargin));
        rightMargin += currentSize.width;
      }
    }
    if (hasChild(_secondaryNavigationID)) {
      final Size childSize = layoutChild(_secondaryNavigationID, BoxConstraints.loose(size));
      updateSize(_secondaryNavigationID, childSize);
      final Size currentSize = Tween<Size>(begin:slotSizes[_secondaryNavigationID], end:childSize).animate(controller).value;
      if (textDirection) {
        positionChild(_secondaryNavigationID, Offset(size.width - currentSize.width, topMargin));
        rightMargin += currentSize.width;
      } else {
        positionChild(_secondaryNavigationID, Offset(0, topMargin));
        leftMargin += currentSize.width;
      }
    }

    final double remainingWidth = size.width - rightMargin - leftMargin;
    final double remainingHeight = size.height - bottomMargin - topMargin;
    final double halfWidth = size.width / 2;
    final double halfHeight = size.height / 2;
    final double hingeWidth = hinge != null ? hinge!.right - hinge!.left : 0;

    if (hasChild(_bodyID) && hasChild(_secondaryBodyID)) {
      Size currentBodySize = Size.zero;
      Size currentSBodySize = Size.zero;
      if (chosenWidgets[_secondaryBodyID] == null || chosenWidgets[_secondaryBodyID]!.builder==null) {
        if(!textDirection) {
          currentBodySize = layoutChild(_bodyID, BoxConstraints.tight(Size(remainingWidth, remainingHeight)));
        } else if(horizontalBody){
          double beginWidth;
          if(bodyRatio==null){
            beginWidth = halfWidth-leftMargin;
          }else{
            beginWidth = remainingWidth*bodyRatio!;
          }
          currentBodySize = layoutChild(_bodyID, BoxConstraints.tight(Size(animatedSize(beginWidth, remainingWidth), remainingHeight)));
        } else {
          double beginHeight;
          if(bodyRatio==null){
            beginHeight = halfHeight-topMargin;
          }else{
            beginHeight = remainingHeight*bodyRatio!;
          }
          currentBodySize = layoutChild(_bodyID, BoxConstraints.tight(Size(remainingWidth, animatedSize(beginHeight, remainingHeight))));
        }
        layoutChild(_secondaryBodyID, BoxConstraints.loose(size));
      } else {
        if (horizontalBody) {
          // If body and secondaryBody laid out horizontally
          if (textDirection) {
            // If textDirection is LTR

            double finalBodySize;
            double finalSBodySize;
            if(hinge!=null){
              finalBodySize = hinge!.left - leftMargin;
              finalSBodySize = size.width-(hinge!.left+hingeWidth)-rightMargin;
            }else if(bodyRatio!=null){
              finalBodySize = remainingWidth * bodyRatio!;
              finalSBodySize = remainingWidth * (1 - bodyRatio!);
            } else {
              finalBodySize = halfWidth - leftMargin;
              finalSBodySize = halfWidth - rightMargin;
            }

            currentBodySize = layoutChild(
              _bodyID,
              BoxConstraints.tight(
                Size(
                  animatedSize(
                    remainingWidth,
                    finalBodySize,
                  ),
                  remainingHeight,
                ),
              ),
            );
            layoutChild(
              _secondaryBodyID,
              BoxConstraints.tight(
                Size(
                  finalSBodySize,
                  remainingHeight,
                ),
              ),
            );
          } else {
            // If textDirection is RTL

            double finalBodySize;
            double finalSBodySize;
            if(hinge!=null){
              finalBodySize = size.width-(hinge!.left+hingeWidth)-rightMargin;
              finalSBodySize = hinge!.left - leftMargin;
            }else if(bodyRatio!=null){
              finalBodySize = remainingWidth * bodyRatio!;
              finalSBodySize = remainingWidth * (1 - bodyRatio!);
            } else {
              finalBodySize = halfWidth - rightMargin;
              finalSBodySize = halfWidth - leftMargin;
            }

            currentSBodySize = layoutChild(
              _secondaryBodyID,
              BoxConstraints.tight(
                Size(
                  animatedSize(
                    0,
                    finalSBodySize,
                  ),
                  remainingHeight,
                ),
              ),
            );
            layoutChild(
              _bodyID,
              BoxConstraints.tight(
                Size(
                  finalBodySize,
                  remainingHeight,
                ),
              ),
            );
          }
        } else {
          // If body and secondaryBody laid out vertically
          currentBodySize = layoutChild(
            _bodyID,
            BoxConstraints.tight(
              Size(
                remainingWidth,
                animatedSize(
                  remainingHeight,
                  bodyRatio == null ? halfHeight - topMargin : remainingHeight * bodyRatio!,
                ),
              ),
            ),
          );
          layoutChild(
            _secondaryBodyID,
            BoxConstraints.tight(
              Size(
                remainingWidth,
                bodyRatio == null ? halfHeight - bottomMargin : remainingHeight * (1 - bodyRatio!),
              ),
            ),
          );
        }
      }
      // Handling all positioning for body and secondaryBody
      if (horizontalBody && !textDirection && chosenWidgets[_secondaryBodyID] != null) {
        if(hinge!=null){
          positionChild(_bodyID, Offset(currentSBodySize.width + leftMargin + hingeWidth, topMargin));
          positionChild(_secondaryBodyID, Offset(leftMargin, topMargin));
        } else {
          positionChild(_bodyID, Offset(currentSBodySize.width + leftMargin, topMargin));
          positionChild(_secondaryBodyID, Offset(leftMargin, topMargin));
        }
      } else {
        positionChild(_bodyID, Offset(leftMargin, topMargin));
        if (horizontalBody) {
          if(hinge!=null){
            positionChild(_secondaryBodyID, Offset(currentBodySize.width + leftMargin + hingeWidth, topMargin));
          } else {
            positionChild(_secondaryBodyID, Offset(currentBodySize.width + leftMargin, topMargin));
          }
        } else {
          positionChild(_secondaryBodyID, Offset(leftMargin, topMargin + currentBodySize.height));
        }
      }
    } else if (hasChild(_bodyID)) {
      layoutChild(_bodyID, BoxConstraints.tight(Size(remainingWidth, remainingHeight)));
      positionChild(_bodyID, Offset(leftMargin, topMargin));
    } else if (hasChild(_secondaryBodyID)) {
      layoutChild(_secondaryBodyID, BoxConstraints.tight(Size(remainingWidth, remainingHeight)));
    }
  }

  void updateSize(String id, Size childSize) {
    if(slotSizes[id] != childSize){
      void listener(AnimationStatus status) {
        if((status == AnimationStatus.completed || status == AnimationStatus.dismissed) && slotSizes[id] != childSize){
          slotSizes.update(id, (Size? value) => childSize);
        }
        controller.removeStatusListener(listener);
      }
      controller.addStatusListener(listener);
    }
  }

  @override
  bool shouldRelayout(_AdaptiveLayoutDelegate oldDelegate) {
    return oldDelegate.slots != slots;
  }
}

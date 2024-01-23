// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Flutter code sample for [SearchBar].

// 假设最大width = 200, 中等width = 120，最小width = 50
double maxItemWidth = 200.0;
double midItemWidth = 120.0;
double minItemWidth = 50.0;

void main() => runApp(const CarouselExample());

class CarouselExample extends StatefulWidget {
  const CarouselExample({super.key});

  @override
  State<CarouselExample> createState() => _CarouselExampleState();
}

class _CarouselExampleState extends State<CarouselExample> {
  final List<ImageProvider> images = <NetworkImage>[
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_1.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_2.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_3.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_4.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_5.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_6.png'),
  ];

  late List<GlobalKey> itemKeys;
  double scrollOffset = 0;
  int nextItem = 0;
  bool? isScrolling;
  ScrollDirection? scrollDirection;
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    // scrollOffset = scrollController.offset;
    scrollController = ScrollController(
        onAttach: (ScrollPosition position) {
          position.isScrollingNotifier.addListener(() {
            if (isScrolling != scrollController.position.isScrollingNotifier.value) {
              setState(() {
                if (scrollController.position.userScrollDirection == ScrollDirection.idle) {

                }
                scrollDirection = scrollController.position.userScrollDirection;
                isScrolling = scrollController.position.isScrollingNotifier.value;
              });
            }
          });
          // scrollDirection = position.userScrollDirection;
        }
    );
    itemKeys = List<GlobalKey>.generate(6, (int index) => GlobalKey());
    scrollController.addListener(() {
      final double delta = (scrollController.offset - scrollOffset).abs();
      nextItem = (delta / maxItemWidth).ceil();
    });
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   scrollController.addListener(swipeToRight);
    //   scrollOffset = scrollController.offset;
    // });
  }

  // bool swipeToRight() {
  //   // setState(() {
  //   //
  //   // });
  //   double currentOffset = scrollController.offset;
  //   double delta = currentOffset - scrollOffset;
  //   ScrollDirection direction = scrollController.position.userScrollDirection;
  //   if (direction == ScrollDirection.forward) {
  //     // scrollController.animateTo(scrollOffset, duration: Duration(milliseconds: 100), curve: Curves.linear);
  //     // scrollOffset += 200.0;
  //     return true;
  //   }
  //   if (direction == ScrollDirection.reverse) {
  //
  //     return false;
  //   }
  //   return false;
  // }

  // bool showLargeSize(int index) {
  //   double screenWidth = MediaQuery.of(context).size.width;
  //   double maxWidthForLargeItems = screenWidth - midItemWidth - minItemWidth;
  //   final BuildContext? keyContext = itemKeys[index].currentContext;
  //   if (keyContext != null) {
  //     final RenderBox searchBarBox = keyContext.findRenderObject()! as RenderBox;
  //     final Size boxSize = searchBarBox.size;
  //     final Offset boxLocation = searchBarBox.localToGlobal(Offset.zero);
  //     // print('-----------------');
  //     // print('screen width: ${MediaQuery.of(context).size.width}');
  //     // print('current index: $index');
  //     // print('Is visible? ${(boxLocation.dx + boxSize.width < maxWidthForLargeItems) && boxLocation.dx >= 0}');
  //     // print(boxSize);
  //     // print(boxLocation);
  //     // print('-----------------');
  //     return (boxLocation.dx + boxSize.width < maxWidthForLargeItems) && boxLocation.dx >= 0;
  //   }
  //   return true;
  // }

  @override
  Widget build(BuildContext context) {
    // print(isScrolling);
    // int largeItemsCount = (maxWidthForLargeItems / maxItemWidth).floor();
    // print(largeItemsCount);
    // if (isScrolling ?? false) {
    //   // scrollController.animateTo(scrollOffset + nextItem * 200, duration: Duration(milliseconds: 100), curve: Curves.linear);
    //   nextItem += 1;
    // }
    if (scrollDirection == ScrollDirection.reverse) { // To the right
      scrollController.animateTo(scrollOffset + nextItem * maxItemWidth, duration: Duration(milliseconds: 100), curve: Curves.linear);
      scrollOffset = scrollOffset + nextItem * maxItemWidth;
    }
    if (scrollDirection == ScrollDirection.forward && scrollOffset > 0) { // To the left
      scrollController.animateTo(scrollOffset - nextItem * maxItemWidth, duration: Duration(milliseconds: 100), curve: Curves.linear);
      scrollOffset = scrollOffset - nextItem * maxItemWidth;
    }

    // if (scrollTriggered == false) {
    //   scrollController.animateTo(scrollOffset - nextItem * 200, duration: Duration(milliseconds: 100), curve: Curves.linear);
    // }
    // scrollTriggered = null;

    // List<Widget> carouselItems = List<Widget>.generate(6, (int index) {
    //   double itemWidth;
    //   if (index < largeItemsCount) {
    //     itemWidth = maxItemWidth;
    //   } else {
    //     itemWidth = midItemWidth;
    //   }
    //   return Center(
    //     key: itemKeys[index],
    //     child: AnimatedContainer(
    //       color: Colors.orange,
    //       padding: const EdgeInsets.all(4.0),
    //       constraints: BoxConstraints.tight(Size(itemWidth, 200.0)),
    //       duration: const Duration(seconds: 1),
    //       child: Material(
    //         clipBehavior: Clip.antiAlias,
    //         color: Theme.of(context).colorScheme.surface,
    //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
    //         child: Image(
    //           fit: BoxFit.cover,
    //           image: images[index],
    //         ),
    //       ),
    //     ),
    //   );
    // });

    return MaterialApp(
      home: Scaffold(
          body: Center(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: scrollController,
              itemCount: images.length,
              itemBuilder: (BuildContext context, int index) {
                // bool isLarge = index == 0 || showLargeSize(index);
                // print('//////////// SHOW LARGE SIZE? $isLarge');
                // bool? isMid = index > 0 && !isLarge && showLargeSize(index - 1);
                // double itemWidth = 200.0;
                // if (isLarge) {
                //   itemWidth = maxItemWidth;
                // } else if (isMid) {
                //   itemWidth = midItemWidth;
                // } else {
                //   itemWidth = minItemWidth;
                // }
                return Center(
                  key: itemKeys[index],
                  child: AnimatedContainer(
                    color: Colors.orange,
                    padding: const EdgeInsets.all(4.0),
                    constraints: BoxConstraints.tight(Size(maxItemWidth, 200.0)),
                    duration: const Duration(seconds: 1),
                    child: Material(
                      clipBehavior: Clip.antiAlias,
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      child: Image(
                        fit: BoxFit.cover,
                        image: images[index],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
      ),
    );
  }
}

class CarouselItem extends StatefulWidget {
  const CarouselItem({super.key, required this.child});

  final Widget child;

  @override
  State<CarouselItem> createState() => _CarouselItemState();
}

class _CarouselItemState extends State<CarouselItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: widget.child,
      ),
    );
  }
}

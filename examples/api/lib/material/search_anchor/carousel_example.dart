// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

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
  late double screenWidth;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    itemKeys = List<GlobalKey>.generate(6, (int index) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pageController.addListener(() {
        setState(() {});
      });
    });
  }

  @override
  void didChangeDependencies() {
    screenWidth = MediaQuery.of(context).size.width;
    // Min # of items: 3
    final double minItems = max(3, screenWidth / maxItemWidth);
    pageController = PageController(
      viewportFraction: 1 / (screenWidth / maxItemWidth),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pageController.addListener(() {
        setState(() {});
      });
    });

    super.didChangeDependencies();
  }

  Rect? getRect(int index) {
    final BuildContext? keyContext = itemKeys[index].currentContext;
    if (keyContext != null) {
      final RenderBox box = keyContext.findRenderObject()! as RenderBox;
      final Size boxSize = box.size;
      final Offset boxLocation = box.localToGlobal(Offset.zero);
      return boxLocation & boxSize;
    }
    return null;
  }

  Widget buildCarouselItem(
      {required int index,
      required double itemWidth,
      AlignmentDirectional? alignment}) {
    return Align(
      key: itemKeys[index],
      alignment: alignment ?? Alignment.center,
      child: Container(
        color: Colors.orange,
        padding: const EdgeInsets.all(4.0),
        constraints: BoxConstraints.tight(Size(itemWidth, 200.0)),
        child: Material(
          clipBehavior: Clip.antiAlias,
          color: Theme.of(context).colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Image(
            fit: BoxFit.cover,
            image: images[index],
          ),
        ),
      ),
    );
  }

  final List<int> data = List<int>.generate(20, (int index) => index);
  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          scrollDirection: Axis.horizontal,
          controller: controller,
          slivers: <Widget>[
            SliverCarousel(
              maxChildExtent: 200,
              minChildExtent: 10,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                      color:
                        Colors.primaries[index % Colors.primaries.length],
                      child: Center(
                        child: Text(
                          'Item ${data[index]}',
                          style: const TextStyle(color: Colors.white, fontSize: 20),
                          overflow: TextOverflow.clip,
                          softWrap: false,
                        ),
                      ),
                    ),
                  );
                },
                childCount: data.length,
              ),
            ),
          ]),
        //     body: PageView.builder(
        //       padEnds: false,
        //       controller: pageController,
        //       itemCount: images.length,
        //       itemBuilder: (BuildContext context, int index) {
        //         final Rect? boxRect = getRect(index);
        //         if (boxRect != null && boxRect.left < 0) {
        //           print('first item: ${boxRect.left}');
        //           final double firstItemWidth = clampDouble(boxRect.right, minItemWidth, maxItemWidth);
        //           return CarouselItem(
        //             itemKey: itemKeys[index],
        //             itemWidth: firstItemWidth,
        //             image: images[index],
        //             alignment: AlignmentDirectional.centerEnd,
        //           );
        //         }

        //         // current index is second last item
        //         // double bufferForNext = 0;
        //         // if (index + 1 < images.length) {
        //         //   final Rect? lastBoxRect = getRect(index + 1);
        //         //   if (lastBoxRect != null && screenWidth - lastBoxRect.left < minItemWidth) {
        //         //     print('$index th box');
        //         //     bufferForNext = minItemWidth - screenWidth + lastBoxRect.left;
        //         //     double secondLastItemWidth = clampDouble(maxItemWidth - bufferForNext, midItemWidth, maxItemWidth);
        //         //     print('$secondLastItemWidth ${getRect(index)?.right} ${getRect(index + 1)?.left}');
        //         //     return CarouselItem(
        //         //       itemKey: itemKeys[index],
        //         //       itemWidth: secondLastItemWidth,
        //         //       image: images[index],
        //         //       alignment: AlignmentDirectional.centerStart
        //         //     );
        //         //   }
        //         // }

        //         double lastItemWidth = minItemWidth;
        //         if (boxRect != null && boxRect.right >= screenWidth) {
        //           // print('last visible index: $index $boxRect');
        //           lastItemWidth = clampDouble(screenWidth - boxRect.left, minItemWidth, maxItemWidth);
        //           return CarouselItem(
        //             itemKey: itemKeys[index],
        //             itemWidth: lastItemWidth,
        //             image: images[index],
        //             alignment: AlignmentDirectional.centerStart,
        //           );
        //         }
        //         return CarouselItem(
        //           itemKey: itemKeys[index],
        //           itemWidth: maxItemWidth,
        //           image: images[index],
        //           alignment: AlignmentDirectional.centerStart,
        //         );
        //       },
        //     )
      ),
    );
  }
}

class CarouselItem extends StatefulWidget {
  const CarouselItem(
      {super.key,
      required this.itemKey,
      required this.itemWidth,
      required this.image,
      this.alignment});

  final GlobalKey itemKey;
  final double itemWidth;
  final ImageProvider image;
  final AlignmentDirectional? alignment;

  @override
  State<CarouselItem> createState() => _CarouselItemState();
}

class _CarouselItemState extends State<CarouselItem> {
  @override
  Widget build(BuildContext context) {
    return Align(
      key: widget.itemKey,
      alignment: widget.alignment ?? Alignment.center,
      child: Container(
        // duration: const Duration(milliseconds: 50),
        color: Colors.orange,
        padding: const EdgeInsets.all(4.0),
        constraints: BoxConstraints.tight(Size(widget.itemWidth, 200.0)),
        child: Material(
          clipBehavior: Clip.antiAlias,
          color: Theme.of(context).colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Image(
            fit: BoxFit.cover,
            image: widget.image,
          ),
        ),
      ),
    );
  }
}

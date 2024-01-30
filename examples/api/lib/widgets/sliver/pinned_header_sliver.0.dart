// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(const AppBarPartsApp());
}

class AppBarPartsApp extends StatelessWidget {
  const AppBarPartsApp({ super.key });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const AppBarParts(),
    );
  }
}

class AppBarParts extends StatefulWidget {
  const AppBarParts({ super.key });

  @override
  State<AppBarParts> createState() => _AppBarPartsState();
}

class _AppBarPartsState extends State<AppBarParts> {
  late final ScrollController scrollController;
  late CoordinatedSliver titleBar;
  late CoordinatedSliver titleItem;
  double titleBarOpacity = 0;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 8);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SliverCoordinator(
            callback: (ScrollNotification notification, SliverCoordinatorData data) {
              final SliverLayoutInfo? titleBarInfo = titleBar.getLayoutInfo(data);
              final SliverLayoutInfo? titleItemInfo = titleItem.getLayoutInfo(data);
              if (titleBarInfo == null || titleItemInfo == null) {
                return;
              }
              final double scrollOffset = titleBarInfo.constraints.scrollOffset;
              final double titleItemExtent = titleItemInfo.geometry.scrollExtent;
              if (notification is ScrollEndNotification) {
                if (scrollOffset > 0 && scrollOffset < titleItemExtent) {
                  scrollController.position.animateTo(
                    scrollOffset >= titleItemExtent / 2 ? titleItemExtent : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut
                  );
                }
              }
              final double opacity = scrollOffset >= titleItemExtent ? 1 : 0;
              if (opacity != titleBarOpacity) {
                setState(() {
                  titleBarOpacity = opacity;
                });
              }
            },
            child: CustomScrollView(
              controller: scrollController,
              slivers: <Widget>[
                titleBar = CoordinatedSliver(
                  child: PinnedHeaderSliver(
                    child: TitleBar(
                      opacity: titleBarOpacity,
                      child: Text('Settings', style: textTheme.titleMedium),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: horizontalPadding,
                  sliver: titleItem = CoordinatedSliver(
                    child: SliverToBoxAdapter(
                      child: ColoredBox(
                        color: Colors.yellow,
                        child: TitleItem(
                          child: Text('Settings', style: textTheme.displayLarge!.copyWith(fontSize: 72)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: horizontalPadding,
                  sliver: ItemList(
                    startColor: Colors.blue,
                    endColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// The pinned item at the top of the list. This is an implicitly
// animated widget: when the opacity changes the title and divider
// fade in or out.
class TitleBar extends StatelessWidget {
  const TitleBar({ super.key, required this.opacity, required this.child });

  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: ShapeDecoration(
        color: colorScheme.background,
        shape: LinearBorder.bottom(
          side: BorderSide(
            color: opacity == 0 ? colorScheme.background : colorScheme.outline,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 1000),
        child: child,
      ),
    );
  }
}

// The second item in the list. It scrolls normally. When it has scrolled
// out of view behind the first, pinned, TitleBar item, the TitleBar fades in.
class TitleItem extends StatelessWidget {
  const TitleItem({ super.key, required this.child });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.bottomStart,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: child,
    );
  }
}

// A placeholder SliverList of 50 items.
class ItemList extends StatelessWidget {
  const ItemList({
    super.key,
    required this.startColor,
    required this.endColor,
    this.itemCount = 50,
  });

  final Color startColor;
  final Color endColor;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Card(
            color: Color.lerp(startColor, endColor, index / itemCount),
            child: ListTile(
              textColor: Colors.white,
              title: Text('Item $index'),
            ),
          );
        },
        childCount: itemCount,
      ),
    );
  }
}

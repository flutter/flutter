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
  late final ResizingHeaderSliver appBar;

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

  void maybeAutoScroll(
    double extent, // the header's current height
    double minExtent, // the height of the header's minExtentPrototype
    double maxExtent // the height of the header's maxExtentPrototype
  ) {
    if (extent > minExtent && extent < maxExtent) {
      scrollController.animateTo(
        extent > (minExtent + maxExtent) / 2 ? 0 : maxExtent - minExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SliverCoordinator(
            callback: (ScrollNotification notification, SliverCoordinatorData data) {
              ResizingHeaderSliverLayoutInfo? info = appBar.getLayoutInfo(data);
              if (notification is ScrollEndNotification && info != null) {
                maybeAutoScroll(info.geometry.paintExtent, info.minExtent, info.maxExtent);
              }
            },
            child: CustomScrollView(
              controller: scrollController,
              slivers: <Widget>[
                appBar = ResizingHeaderSliver(
                  minExtentPrototype: ContactBar.prototype(fontSize: 16),
                  maxExtentPrototype: ContactBar.prototype(fontSize: 72),
                  child: const ContactBar(
                    name: 'John Appleseed',
                    initials: 'JA',
                  ),
                ),
                ItemList(
                  startColor: colorScheme.primary,
                  endColor: colorScheme.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactBarButton extends StatelessWidget {
  const _ContactBarButton(this.icon, this.label);

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () { },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon),
          Text(label),
        ],
      ),
    );
  }
}

class ContactBar extends StatelessWidget {
  const ContactBar({
    super.key,
    required this.name,
    required this.initials,
    this.fontSize = 16,
    this.isPrototype = false,
  });

  factory ContactBar.prototype({ required double fontSize }) {
    return ContactBar(
      name: 'John Appleseed',
      initials: 'JA',
      fontSize: fontSize,
      isPrototype: true,
    );
  }

  final String name;
  final String initials;
  final double fontSize;
  final bool isPrototype;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Widget nameAndInitials = Column(
      children: <Widget>[
        CircleAvatar(
          backgroundColor: colorScheme.secondary,
          child: Text(
            initials,
            style: TextStyle(fontSize: fontSize, color: colorScheme.onSecondary)
          ),
        ),
        Text(
          name,
          style: TextStyle(fontSize: fontSize * 0.75),
          softWrap: false
        ),
      ],
    );

    return ColoredBox(
      color: colorScheme.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isPrototype)
            nameAndInitials
          else
            Expanded(child: FittedBox(child: nameAndInitials)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              const _ContactBarButton(Icons.call, 'call'),
              const _ContactBarButton(Icons.mms, 'message'),
              const _ContactBarButton(Icons.mail, 'mail'),
            ].map((Widget child) {
              return Expanded(child: Padding(padding: const EdgeInsets.all(8), child: child));
              }).toList(),
          ),
        ],
      ),
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
            color: Color.lerp(startColor, endColor, index / itemCount)!,
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

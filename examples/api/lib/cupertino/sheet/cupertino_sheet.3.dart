// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

/// Flutter code sample for [CupertinoSheetRoute].

void main() {
  runApp(const CupertinoSheetApp());
}

class CupertinoSheetApp extends StatelessWidget {
  const CupertinoSheetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(title: 'Scrollable Cupertino Sheet', home: HomePage());
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Scrollable Cupertino Sheet Example'),
        automaticBackgroundVisibility: false,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CupertinoButton.filled(
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoSheetRoute<void>.scrollable(
                    scrollableBuilder: (BuildContext context, ScrollController controller) =>
                        _ScrollableSheetBody(scrollController: controller),
                  ),
                );
              },
              child: const Text('Open Bottom Sheet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrollableSheetBody extends StatelessWidget {
  const _ScrollableSheetBody({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoSheetNavbar<void>(
        child: CupertinoNavigationBar(
          backgroundColor: CupertinoColors.systemGrey3,
          middle: Text('Scrollable Sheet'),
          automaticBackgroundVisibility: false,
        ),
      ),
      child: CustomScrollView(
        controller: scrollController,
        primary: false,
        slivers: <Widget>[
          SliverList(
            delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
              return Container(
                alignment: Alignment.center,
                height: 100,
                child: const Text('Scroll Me'),
              );
            }, childCount: 20),
          ),
        ],
      ),
    );
  }
}

class CupertinoSheetNavbar<T> extends StatelessWidget implements ObstructingPreferredSizeWidget {
  const CupertinoSheetNavbar({super.key, required this.child});

  final CupertinoNavigationBar child;

  @override
  bool shouldFullyObstruct(BuildContext context) {
    return child.shouldFullyObstruct(context);
  }

  @override
  Size get preferredSize {
    return child.preferredSize;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoSheetDragArea<T>(
      route: ModalRoute.of(context)! as CupertinoSheetRoute<T>,
      child: child,
    );
  }
}

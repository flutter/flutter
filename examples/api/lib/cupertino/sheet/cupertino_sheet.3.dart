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
    return const CupertinoApp(
      title: 'Scrollable Cupertino Sheet',
      home: HomePage(),
    );
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
                  CupertinoSheetRoute<void>(
                    scrollableBuilder:
                        (BuildContext context, ScrollController controller) =>
                            _ScrollableSheetBody(scrollController: controller),
                  ),
                );
              },
              child: const Text('Open Sheet'),
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
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGrey3,
        middle: const Text('Scrollable Sheet'),
        automaticBackgroundVisibility: false,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Close'),
          onPressed: () {
            CupertinoSheetRoute.popSheet(context);
          },
        ),
      ),
      child: CustomScrollView(
        controller: scrollController,
        primary: false,
        slivers: <Widget>[
          SliverList(
            delegate: SliverChildBuilderDelegate((
              BuildContext context,
              int index,
            ) {
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

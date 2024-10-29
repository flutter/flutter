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
      title: 'Cupertino Sheet',
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
        middle: Text('Sheet Example'),
        automaticBackgroundVisibility: false,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CupertinoButton.filled(
              onPressed: () {
                showCupertinoSheet<void>(
                  context: context,
                  useNestedNavigation: true,
                  pageBuilder: (BuildContext context) => const SheetScaffold(),
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

class SheetScaffold extends StatelessWidget {
  const SheetScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('The sheet'),
            CupertinoButton.filled(
              onPressed: () {
                Navigator.of(context).maybePop();
              },
              child: const Text('Go back'),
            ),
            CupertinoButton.filled(
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(builder: (BuildContext context) => const SheetNextPage())
                );
              },
              child: const Text('Push Page'),
            ),
            CupertinoButton.filled(
              onPressed: () {
                showCupertinoSheet<void>(
                  context: context,
                  useNestedNavigation: true,
                  pageBuilder: (BuildContext context) => const SheetScaffold(),
                );
              },
              child: const Text('Push Sheet'),
            ),
          ],
        ),
      )
    );
  }
}

class SheetNextPage extends StatelessWidget {
  const SheetNextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.activeOrange,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Second Page'),
            CupertinoButton.filled(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Go back'),
            ),
            CupertinoButton.filled(
              onPressed: () {
                CupertinoSheetRoute.of(context).popSheet();
              },
              child: const Text('Pop whole sheet'),
            ),
            CupertinoButton.filled(
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(builder: (BuildContext context) => const SheetNextPage())
                );
              },
              child: const Text('Push Page'),
            ),
            CupertinoButton.filled(
              onPressed: () {
                showCupertinoSheet<void>(
                  context: context,
                  useNestedNavigation: true,
                  pageBuilder: (BuildContext context) => const SheetScaffold(),
                );
              },
              child: const Text('Push Sheet'),
            ),
          ],
        ),
      )
    );
  }
}

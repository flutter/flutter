// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for showCupertinoDialog

import 'package:flutter/cupertino.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      restorationScopeId: 'app',
      title: _title,
      home: MyStatelessWidget(),
    );
  }
}

class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Home'),
      ),
      child: Center(
          child: CupertinoButton(
        onPressed: () {
          Navigator.of(context).restorablePush(_dialogBuilder);
        },
        child: const Text('Open Dialog'),
      )),
    );
  }

  static Route<Object?> _dialogBuilder(
      BuildContext context, Object? arguments) {
    return CupertinoDialogRoute<void>(
      context: context,
      builder: (BuildContext context) {
        return const CupertinoAlertDialog(
          title: Text('Title'),
          content: Text('Content'),
          actions: <Widget>[
            CupertinoDialogAction(child: Text('Yes')),
            CupertinoDialogAction(child: Text('No')),
          ],
        );
      },
    );
  }
}

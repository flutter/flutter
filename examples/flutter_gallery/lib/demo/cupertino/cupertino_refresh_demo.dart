// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/cupertino.dart';

class CupertinoRefreshControlDemo extends StatefulWidget {
  static const String routeName = '/cupertino/refresh';

  @override
  _CupertinoRefreshControlDemoState createState() => new _CupertinoRefreshControlDemoState();
}

class _CupertinoRefreshControlDemoState extends State<CupertinoRefreshControlDemo> {

  @override
  Widget build(BuildContext context) {
    return new CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: const Text('Cupertino Refresh Control'),
      ),
      child: new DecoratedBox(
        decoration: const BoxDecoration(color: const Color(0xFFEFEFF4)),
        child: new CustomScrollView(
          slivers: <Widget>[
            new CupertinoRefreshControl(),
            new SliverList(
              delegate: new SliverChildListDelegate(
                <Widget>[
                  const Padding(padding: const EdgeInsets.only(top: 32.0)),
                  new GestureDetector(
                    onTap: () {
                    },
                    child: new Container(
                      decoration: const BoxDecoration(
                        color: CupertinoColors.white,
                        border: const Border(
                          top: const BorderSide(color: const Color(0xFFBCBBC1), width: 0.0),
                          bottom: const BorderSide(color: const Color(0xFFBCBBC1), width: 0.0),
                        ),
                      ),
                      height: 44.0,
                      child: new Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: new SafeArea(
                          top: false,
                          bottom: false,
                          child: new Row(
                            children: const <Widget>[
                              const Text(
                                'Sign in',
                                style: const TextStyle(color: CupertinoColors.activeBlue),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}

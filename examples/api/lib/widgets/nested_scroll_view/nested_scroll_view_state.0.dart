// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for NestedScrollViewState

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: MyStatelessWidget(),
    );
  }
}

final GlobalKey<NestedScrollViewState> globalKey = GlobalKey();

class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      key: globalKey,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return const <Widget>[
          SliverAppBar(
            title: Text('NestedScrollViewState Demo!'),
          ),
        ];
      },
      body: const CustomScrollView(
          // Body slivers go here!
          ),
    );
  }

  ScrollController get innerController {
    return globalKey.currentState!.innerController;
  }
}

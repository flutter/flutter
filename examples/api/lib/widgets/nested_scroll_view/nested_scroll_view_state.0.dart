// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [NestedScrollViewState].

void main() => runApp(const NestedScrollViewStateExampleApp());

class NestedScrollViewStateExampleApp extends StatelessWidget {
  const NestedScrollViewStateExampleApp({super.key});

  @override
  Widget build(final BuildContext context) {
    return const MaterialApp(
      home: NestedScrollViewStateExample(),
    );
  }
}

final GlobalKey<NestedScrollViewState> globalKey = GlobalKey();

class NestedScrollViewStateExample extends StatelessWidget {
  const NestedScrollViewStateExample({super.key});

  @override
  @override
  Widget build(final BuildContext context) {
    return NestedScrollView(
      key: globalKey,
      headerSliverBuilder: (final BuildContext context, final bool innerBoxIsScrolled) {
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

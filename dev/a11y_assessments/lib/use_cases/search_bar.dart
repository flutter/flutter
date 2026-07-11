// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class SearchBarUseCase extends UseCase {
  SearchBarUseCase();

  @override
  String get name => 'SearchBar';

  @override
  String get route => '/search-bar';

  @override
  List<Tag> get tags => <Tag>[Tag.batch3, Tag.core];

  @override
  Widget build(BuildContext context) => _MainWidget();
}

class _MainWidget extends StatelessWidget {
  _MainWidget();

  final String pageTitle = getUseCaseName(SearchBarUseCase());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo'))),
      body: ListView(
        children: <Widget>[
          Semantics(
            label: 'Enabled search bar',
            child: SearchBar(
              key: const Key('enabled search bar'),
              hintText: 'Search...',
              leading: const Icon(Icons.search),
              trailing: <Widget>[
                IconButton(tooltip: 'Clear', icon: const Icon(Icons.clear), onPressed: () {}),
              ],
            ),
          ),
          Semantics(
            label: 'Disabled search bar',
            child: const SearchBar(
              key: Key('disabled search bar'),
              hintText: 'Search...',
              enabled: false,
            ),
          ),
        ],
      ),
    );
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class SearchAnchorUseCase extends UseCase {
  SearchAnchorUseCase();

  @override
  String get name => 'SearchAnchor';

  @override
  String get route => '/search-anchor';

  @override
  List<Tag> get tags => <Tag>[Tag.batch3, Tag.core];

  @override
  Widget build(BuildContext context) => _MainWidget();
}

class _MainWidget extends StatelessWidget {
  _MainWidget();

  final String pageTitle = getUseCaseName(SearchAnchorUseCase());

  static const List<String> _kOptions = <String>['apple', 'banana', 'lemon'];

  static Iterable<Widget> _getSuggestions(SearchController controller) {
    final String input = controller.value.text;
    return _kOptions
        .where((String option) => option.contains(input.toLowerCase()))
        .map(
          (String filteredOption) => ListTile(
            title: Text(filteredOption),
            onTap: () {
              controller.closeView(filteredOption);
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo'))),
      body: ListView(
        children: <Widget>[
          Semantics(
            key: const Key('enabled search anchor'),
            label: 'Enabled search anchor',
            child: SearchAnchor.bar(
              barHintText: 'Search...',
              suggestionsBuilder: (BuildContext context, SearchController controller) {
                return _getSuggestions(controller);
              },
            ),
          ),
          Semantics(
            key: const Key('disabled search anchor'),
            label: 'Disabled search anchor',
            child: SearchAnchor.bar(
              barHintText: 'Search...',
              enabled: false,
              suggestionsBuilder: (BuildContext context, SearchController controller) {
                return const Iterable<Widget>.empty();
              },
            ),
          ),
        ],
      ),
    );
  }
}

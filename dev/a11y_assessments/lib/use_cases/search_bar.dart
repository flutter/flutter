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

class _MainWidget extends StatefulWidget {
  @override
  State<_MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<_MainWidget> {
  final String pageTitle = getUseCaseName(SearchBarUseCase());
  String _statusMessage = '';

  static const List<String> _kOptions = <String>[
    'apple',
    'banana',
    'cherry',
    'date',
    'elderberry',
    'fig',
    'grape',
    'honeydew',
    'icicle',
    'jackfruit',
    'kiwi',
    'lemon',
    'mango',
    'nectarine',
    'orange',
    'papaya',
    'quince',
    'raspberry',
    'strawberry',
    'tangerine',
    'umbrella',
    'vanilla',
    'watermelon',
    'xylophone',
    'yuzu',
    'zucchini',
  ];

  void _handleSearch(String value) {
    setState(() {
      _statusMessage = 'Searched for "$value"';
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Searched for "$value"')));
  }

  Iterable<Widget> _getSuggestions(SearchController controller) {
    final String input = controller.value.text;
    return _kOptions
        .where((String option) => option.contains(input.toLowerCase()))
        .map(
          (String filteredOption) => ListTile(
            title: Text(filteredOption),
            onTap: () {
              controller.closeView(filteredOption);
              _handleSearch(filteredOption);
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
            label: 'Enabled search bar',
            child: SearchAnchor(
              builder: (BuildContext context, SearchController controller) {
                return SearchBar(
                  key: const Key('enabled search bar'),
                  controller: controller,
                  hintText: 'Search...',
                  onTap: () {
                    controller.openView();
                  },
                  onChanged: (_) {
                    controller.openView();
                  },
                  onSubmitted: (String value) {
                    _handleSearch(value);
                  },
                  leading: const Icon(Icons.search),
                  trailing: <Widget>[
                    IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        setState(() {
                          _statusMessage = 'Search cleared';
                        });
                      },
                    ),
                  ],
                );
              },
              suggestionsBuilder: (BuildContext context, SearchController controller) {
                return _getSuggestions(controller);
              },
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
          if (_statusMessage.isNotEmpty)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_statusMessage, key: const Key('status message')),
              ),
            ),
        ],
      ),
    );
  }
}

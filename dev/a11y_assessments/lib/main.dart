// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'use_cases/use_cases.dart';

void main() {
  runApp(const App());
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
}

class App extends StatelessWidget {
  const App({super.key, this.initialTags = const <Tag>{Tag.batch2}});

  final Set<Tag> initialTags;

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff6750a4),
        contrastLevel: MediaQuery.highContrastOf(context) ? 1.0 : 0.0,
      ),
    );
    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: const Color(0xff6750a4),
        contrastLevel: MediaQuery.highContrastOf(context) ? 1.0 : 0.0,
      ),
    );

    final routes = Map<String, WidgetBuilder>.fromEntries(
      useCases.map(
        (UseCase useCase) => MapEntry<String, WidgetBuilder>(
          useCase.route,
          (BuildContext context) => useCase.buildWithTitle(context),
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Accessibility Assessments Home Page',
      theme: lightTheme,
      darkTheme: darkTheme,
      routes: <String, WidgetBuilder>{
        '/': (_) => HomePage(initialTags: initialTags),
        ...routes,
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.initialTags});

  final Set<Tag> initialTags;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ScrollController scrollController = ScrollController();

  late Set<Tag> _selectedTags;

  @override
  void initState() {
    super.initState();
    _selectedTags = Set<Tag>.from(widget.initialTags);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Widget _buildUseCaseItem(int index, UseCase useCase) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Builder(
        builder: (BuildContext context) {
          return TextButton(
            key: Key(useCase.name),
            onPressed: () =>
                Navigator.of(context).pushNamed(useCase.route, arguments: useCase.name),
            child: Text(useCase.name),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<UseCase> effectiveUseCases = useCases.where((UseCase useCase) {
      return _selectedTags.isEmpty || _selectedTags.every((Tag tag) => useCase.tags.contains(tag));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Semantics(headingLevel: 1, child: const Text('Accessibility Assessments')),
        actions: <Widget>[
          MenuAnchor(
            builder: (BuildContext context, MenuController controller, Widget? child) {
              return Tooltip(
                message: 'Filter by tags',
                child: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                ),
              );
            },
            menuChildren: Tag.values.map((Tag tag) {
              return CheckboxMenuButton(
                closeOnActivate: false,
                value: _selectedTags.contains(tag),
                onChanged: (bool? value) {
                  setState(() {
                    if (value ?? false) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
                child: Tooltip(message: tag.description, child: Text(tag.name)),
              );
            }).toList(),
          ),
        ],
      ),
      body: Center(
        child: ListView(
          controller: scrollController,
          children: List<Widget>.generate(
            effectiveUseCases.length,
            (int index) => _buildUseCaseItem(index, effectiveUseCases[index]),
          ),
        ),
      ),
    );
  }
}

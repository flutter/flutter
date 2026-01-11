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
  const App({super.key});

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
      title: 'Accessibility Assessments Home Page',
      theme: lightTheme,
      darkTheme: darkTheme,
      routes: <String, WidgetBuilder>{'/': (_) => const HomePage(), ...routes},
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ScrollController scrollController = ScrollController();

  bool _showAdditionalUseCases = false;

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
      return _showAdditionalUseCases || useCase.useCaseCategory == UseCaseCategory.core;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Semantics(headingLevel: 1, child: const Text('Accessibility Assessments')),
        actions: <Widget>[
          Tooltip(
            message: 'Show additional use cases',
            waitDuration: const Duration(milliseconds: 500),
            child: Switch(
              value: _showAdditionalUseCases,
              onChanged: (bool newValue) {
                setState(() {
                  _showAdditionalUseCases = newValue;
                });
              },
            ),
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

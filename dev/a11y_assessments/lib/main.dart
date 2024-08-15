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
    final ThemeData lightTheme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xff6750a4),
      contrastLevel: MediaQuery.highContrastOf(context) ? 1.0 : 0.0,
    ));
    final ThemeData darkTheme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: const Color(0xff6750a4),
      contrastLevel: MediaQuery.highContrastOf(context) ? 1.0 : 0.0,
    ));

    final Map<String, WidgetBuilder> routes =
        Map<String, WidgetBuilder>.fromEntries(
      useCases.map((UseCase useCase) =>
          MapEntry<String, WidgetBuilder>(useCase.route, useCase.build)),
    );

    return MaterialApp(
      title: 'Accessibility Assessments Home Page',
      theme: lightTheme,
      darkTheme: darkTheme,
      routes: <String, WidgetBuilder>{
        '/': (_) => const AppWrapper(child: HomePage()),
        ...routes
      },
    );
  }
}

class AppWrapper extends StatelessWidget {

  const AppWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DynamicTitle(
      title: 'Accessibility Assessments Home Page',
      child: child,
    );
  }
}

class DynamicTitle extends StatelessWidget {
  const DynamicTitle({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Title(
      title: title,
      color: Theme.of(context).colorScheme.primary,
      child: child,
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

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Widget _buildUseCaseItem(int index, UseCase useCase) {
    return Padding(
        padding: const EdgeInsets.all(10),
        child: Builder(builder: (BuildContext context) {
          return TextButton(
            key: Key(useCase.name),
            onPressed: () => Navigator.of(context).pushNamed(useCase.route, arguments: useCase.name),
            child: Text(useCase.name),
          );
        }));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
      title: Semantics(headingLevel: 1, child: const Text('Accessibility Assessments')),
      ),
      body: Center(
        child: ListView(
          controller: scrollController,
          children: List<Widget>.generate(
            useCases.length,
            (int index) => _buildUseCaseItem(index, useCases[index]),
          ),
        ),
      ),
    );
  }
}

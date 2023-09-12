// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'use_cases/use_cases.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {

    final Map<String, WidgetBuilder> routes = Map<String, WidgetBuilder>.fromEntries(
      useCases.map((UseCase useCase) => MapEntry<String, WidgetBuilder>(useCase.route, useCase.build)),
    );
    return MaterialApp(
      title: 'Accessibility Assessments',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: <String, WidgetBuilder>{
        '/': (_) => const HomePage(),
        ...routes
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildUseCaseItem(UseCase useCase) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Builder(
          builder: (BuildContext context) {
            return TextButton(
              key: Key(useCase.name),
              onPressed: () => Navigator.of(context).pushNamed(useCase.route),
              child: Text(useCase.name),
            );
          }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility Assessments')),
      body: Center(
        child: ListView(
          children: useCases.map<Widget>(_buildUseCaseItem).toList(),
        ),
      ),
    );
  }
}

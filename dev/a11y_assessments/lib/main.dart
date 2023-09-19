// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'use_cases/use_cases.dart';

// TODO(yjbanov): https://github.com/flutter/flutter/issues/83809
//                Currently this app (as most Flutter Web apps) relies on the
//                `autofocus` property to guide the a11y focus when navigating
//                across routes (screen transitions, dialogs, etc). We may want
//                to revisit this after we figure out a long-term story for a11y
//                focus. See also https://github.com/flutter/flutter/issues/97747
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

  Widget _buildUseCaseItem(int index, UseCase useCase) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Builder(
          builder: (BuildContext context) {
            return TextButton(
              autofocus: index == 0,
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
          children: List<Widget>.generate(
            useCases.length,
            (int index) => _buildUseCaseItem(index, useCases[index]),
          ),
        ),
      ),
    );
  }
}

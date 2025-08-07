// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../utils.dart';
import 'use_cases.dart';

class SnackBarUseCase extends UseCase {
  SnackBarUseCase() : super(useCaseCategory: UseCaseCategory.core);

  @override
  String get name => 'SnackBar';

  @override
  String get route => '/snack-bar';

  @override
  Widget build(BuildContext context) => const MainWidget();
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => MainWidgetState();
}

class MainWidgetState extends State<MainWidget> {
  String pageTitle = getUseCaseName(SnackBarUseCase());

  void showAccessibleSnackBar(String message, {VoidCallback? onAction}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: onAction != null ? SnackBarAction(label: 'Action', onPressed: onAction) : null,
      ),
    );

    // Slight delay ensures announcement happens AFTER snackbar shows
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      debugPrint('Announcing: $message');
      SemanticsService.announce(message, TextDirection.ltr);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo')),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            ElevatedButton(
              child: const Text('Show Snackbar'),
              onPressed: () {
                showAccessibleSnackBar('Awesome Snackbar!');
              },
            ),
            ElevatedButton(
              child: const Text('Show Snackbar with action '),
              onPressed: () {
                showAccessibleSnackBar(
                  'Awesome Snackbar!',
                  onAction: () {
                    SnackBarAction(label: 'Action', onPressed: () {});
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

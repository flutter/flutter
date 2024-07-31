// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'use_cases.dart';

class MaterialBannerUseCase extends UseCase {

  @override
  String get name => 'MaterialBanner';

  @override
  String get route => '/material_banner';

  @override
  Widget build(BuildContext context) => MainWidget();
}

class MainWidget extends StatelessWidget {
  MainWidget({super.key});

  final FocusNode dismissButtonFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('MaterialBanner'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Show a MaterialBanner'),
          onPressed: () {
            ScaffoldMessenger.of(context).showMaterialBanner(
            MaterialBanner(
              padding: const EdgeInsets.all(20),
              content: const Text('Hello, I am a Material Banner'),
              leading: const Icon(Icons.agriculture_outlined),
              backgroundColor: Colors.green,
              actions: <Widget>[
                TextButton(
                  focusNode: dismissButtonFocusNode,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  },
                  child: const Text('DISMISS'),
                ),
              ],
            ),
          );
          dismissButtonFocusNode.requestFocus();
          },
        ),
      ),
    );
  }
}

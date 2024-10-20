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
  Widget build(BuildContext context) => const MainWidget();
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => MainWidgetState();
}

class MainWidgetState extends State<MainWidget> {
  double currentSliderValue = 20;
  ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>? controller;

  @override
  Widget build(BuildContext context) {
    VoidCallback? onPress;
    if (controller == null) {
      onPress = () {
        setState(() {
          controller = ScaffoldMessenger.of(context).showMaterialBanner(
            MaterialBanner(
              padding: const EdgeInsets.all(20),
              content: const Text('Hello, I am a Material Banner'),
              leading: const Icon(Icons.agriculture_outlined),
              backgroundColor: Colors.green,
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    controller!.close();
                    setState(() {
                      controller = null;
                    });
                  },
                  child: const Text('DISMISS'),
                ),
              ],
            ),
          );
        });
      };
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('MaterialBanner'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: onPress,
          child: const Text('Show a MaterialBanner'),
        ),
      ),
    );
  }
}

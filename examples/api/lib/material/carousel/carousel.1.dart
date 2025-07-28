// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [CarouselView.builder].

void main() => runApp(const CarouselBuilderExampleApp());

class CarouselBuilderExampleApp extends StatelessWidget {
  const CarouselBuilderExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('CarouselView.builder Sample')),
        body: const CarouselBuilderExample(),
      ),
    );
  }
}

class CarouselBuilderExample extends StatelessWidget {
  const CarouselBuilderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: CarouselView.builder(
          itemExtent: 350,
          itemCount: 1000,
          itemBuilder: (BuildContext context, int index) {
            return ColoredBox(
              color: Colors.primaries[index % Colors.primaries.length],
              child: Center(
                child: Text(
                  'Item $index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

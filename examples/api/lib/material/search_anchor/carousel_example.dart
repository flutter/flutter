// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() => runApp(const CarouselExample());

class CarouselExample extends StatefulWidget {
  const CarouselExample({super.key});

  @override
  State<CarouselExample> createState() => _CarouselExampleState();
}

class _CarouselExampleState extends State<CarouselExample> {
  final List<int> data = List<int>.generate(20, (int index) => index);

  final List<ImageProvider> images = <NetworkImage>[
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_1.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_2.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_3.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_4.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_5.png'),
    const NetworkImage(
        'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_6.png'),
  ];

  @override
  Widget build(BuildContext context) {
    print('SCREEN WIDTH: ${MediaQuery.of(context).size.width}');
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints.tightFor(height: 200),
            // constraints: BoxConstraints.tight(Size(200, 200)),
            child: Carousel(
              // clipExtent: 20,
              itemSnap: true,
              // layout: CarouselLayout.multiBrowse,
              // childWeights: const <int>[1,5,1], // [3,3,3,2,1], [1,5,1], [1,1,1], [5,1]
              children: List<Widget>.generate(data.length, (int index) {
                return Card.outlined(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0)
                  ),
                  color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.5),
                  child: Center(
                        child: Text(
                          'Item ${data[index]}',
                          style: const TextStyle(color: Colors.white, fontSize: 20),
                          overflow: TextOverflow.clip,
                          softWrap: false,
                        ),
                      ),
                );
              }).toList()),
          ),
        ),
      ),
    );
  }
}
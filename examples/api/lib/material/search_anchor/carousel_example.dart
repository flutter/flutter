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
          child: Carousel(
            itemSnap: true,
            childWeights: const <int>[3,3,3,2,1],
            // backgroundChildren: List<Widget>.generate(data.length, (int index) {
            //   return Image(
            //     fit: BoxFit.cover,
            //     image: images[index % images.length],
            //   );
            // }),
            children: List<Card>.generate(data.length, (int index) {
              return Card.outlined(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  // side: BorderSide(
                  //   width: 5,
                  //   color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.5),
                  // ),
                  borderRadius: BorderRadius.circular(20.0)
                ),
                color: Colors.transparent,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image(
                        fit: BoxFit.cover,
                        image: images[index % images.length],
                      ),
                    ),
                    Center(
                      child: Text(
                        'Item ${data[index]}',
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                        overflow: TextOverflow.clip,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
        ),
      ),
    );
  }
}
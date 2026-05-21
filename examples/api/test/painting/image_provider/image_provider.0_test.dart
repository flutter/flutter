// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_api_samples/painting/image_provider/image_provider.0.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('$CustomNetworkImage', () async {
    const String expectedUrl =
        'https://flutter.github.io/assets-for-api-docs/assets/widgets/flamingos.jpg?dpr=3.0&locale=en-US&platform=android&width=800.0&height=600.0&bidi=ltr';
    final Uri key =
        await const CustomNetworkImage(
          'https://flutter.github.io/assets-for-api-docs/assets/widgets/flamingos.jpg',
        ).obtainKey(
          const ImageConfiguration(
            devicePixelRatio: 3.0,
            locale: Locale('en', 'US'),
            platform: TargetPlatform.android,
            size: Size(800.0, 600.0),
            textDirection: TextDirection.ltr,
          ),
        );

    expect(key.toString(), expectedUrl);
  });
}

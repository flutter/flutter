// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:test/test.dart';
import 'package:flutter_test/flutter_test.dart' as flutter;

import 'dart:async';
import 'dart:ui' as ui show Image;
import 'package:flutter/http.dart' as http;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const List<int> transparentImage = const <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
];

void main() {


  test('Image decoder control test', () async {
    ui.Image image = await decodeImageFromList(new Uint8List.fromList(transparentImage));
    expect(image, isNotNull);
    expect(image.width, 1);
    expect(image.height, 1);
  });

  /// This test load an image from a byteArray returned by a mocked
  /// http Response.
  /// It use the [ImageListener] callback to wait for the loading.
  test('ImageNetwork call', () async {

    Completer<ImageInfo> networkImageCompleter = new Completer<ImageInfo>();
    void handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
      networkImageCompleter.complete(imageInfo);
    }
    Future<ImageInfo> isloaded() => networkImageCompleter.future;

    http.Client.clientOverride = () {
      return new http.MockClient((http.BaseRequest request) {
        return new Future<http.Response>.value(
          new http.Response.bytes(transparentImage, 200)
        );
      });
    };

    NetworkImage networkImage = new NetworkImage('fakeurl');
    ImageStreamCompleter completer = networkImage.load(networkImage);
    completer.addListener(handleImageChanged);
    ImageInfo imageinfo = await isloaded();
    expect(imageinfo.image, isNotNull);
    expect(imageinfo.image.width, 1);
    expect(imageinfo.image.height, 1);
  });

  /// This test load an image from a byteArray returned by a mocked
  /// http Response.
  /// It use a callback triggered by a [Timer] to wait for the loading.
  /// We use this timer to be in the same conditions than the next test
  /// that fail.
  test('ImageNetwork call with a timer completer to respect the same process than the next test', () async {

    ImageInfo toTest;
    void handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
      toTest = imageInfo;
    }

    Completer<bool> waitcompleter = new Completer<bool>();
    Future<bool> isloaded() {
      new Timer(new Duration(seconds: 4), () { waitcompleter.complete(true);});
      return waitcompleter.future;
    }

    http.Client.clientOverride = () {
      return new http.MockClient((http.BaseRequest request) {
        return new Future<http.Response>.value(
          new http.Response.bytes(transparentImage, 200)
        );
      });
    };

    NetworkImage networkImage = new NetworkImage('fakeurl2');
    ImageStreamCompleter completer = networkImage.load(networkImage);
    completer.addListener(handleImageChanged);
    await isloaded();
    expect(toTest.image, isNotNull);
    expect(toTest.image.width, 1);
    expect(toTest.image.height, 1);
  });


  /// This test is in the same conditions than the previous one but use the
  /// flutter_test class to test the load of an image from a byteArray returned
  /// by a mocked http Response.
  /// Using the flutter_test class make the test ends with a timeout.
  /// Debug shows that the process does not go further than the line 348
  /// of the image_provider.dart file (_loadAsync method [NetworkImage] class)
  /// I can't figure out what is happening and have enougth skills on flutter
  /// and the flutter_test class to solve this problem.
  /// If someone want to have look.
  flutter.testWidgets('Same test but with flutter_test framework', (flutter.WidgetTester tester) async {

    Completer<bool> waitcompleter = new Completer<bool>();
    Future<bool> isloaded() {
      new Timer(new Duration(seconds: 4), () { waitcompleter.complete(true);});
      return waitcompleter.future;
    }

    Key childKey = new UniqueKey();
    await tester.pumpWidget(
      new Image.network("fakeurl3")
    );
    await isloaded();
    RenderImage rimage = tester.renderObject(flutter.find.byKey(childKey));
    expect(rimage.image, isNotNull);
  });

}

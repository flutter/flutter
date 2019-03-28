// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_driver/driver_extension.dart';

bool caughtInZone = false;

void main() {
  enableFlutterDriverExtension();
  final ThrowingHttpClient httpClient = ThrowingHttpClient();
  final ZoneSpecification specification = ZoneSpecification(handleUncaughtError:
      (Zone zone, ZoneDelegate delegate, Zone parent, Object error,
          StackTrace stackTrace) {
    caughtInZone = true;
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      context: 'In the Zone handleUncaughtError handler',
      silent: false,
    ));
  });
  when(httpClient.getUrl(any)).thenAnswer((Invocation invocation) {
    final Completer<HttpClientRequest> completer = Completer<HttpClientRequest>.sync();
    completer.completeError(Error());
    return completer.future;
  });
  HttpOverrides.runZoned(() {
    runApp(MaterialApp(home: Scaffold(body: ListView(
      children: <Widget>[
        ImageLoader(),
      ],
    ))));
  }, createHttpClient: (SecurityContext context) {
    return httpClient;
  }, zoneSpecification: specification);
}


class ImageLoader extends StatefulWidget {
  @override
  _ImageLoaderState createState() => _ImageLoaderState();
}

class _ImageLoaderState extends State<ImageLoader> {
  bool caughtError = false;

  void _loadImage() {
    // This is not an image, but we don't care since we're using a faked
    // http client
    final NetworkImage image = NetworkImage('https://github.com/flutter/flutter');
    final ImageStream stream = image.resolve(ImageConfiguration.empty);
    stream.addListener((ImageInfo info, bool syncCall) {}, onError: (dynamic error, StackTrace stackTrace) {
      setState(() {
        caughtError = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Text message;
    if (caughtInZone) {
      message = const Text('UNCAUGHT');
    } else if (caughtError) {
      message = const Text('CAUGHT');
    } else {
      message = const Text('PENDING');
    }
    return Column(
      children: <Widget>[
        MaterialButton(
          onPressed: _loadImage,
          child: const Text('LOAD'),
        ),
        message,
      ],
    );
  }
}

class ThrowingHttpClient extends Mock implements HttpClient {}
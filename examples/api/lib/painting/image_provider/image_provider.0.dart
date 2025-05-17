// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

@immutable
class CustomNetworkImage extends ImageProvider<Uri> {
  const CustomNetworkImage(this.url);

  final String url;

  @override
  Future<Uri> obtainKey(ImageConfiguration configuration) {
    final Uri result = Uri.parse(url).replace(
      queryParameters: <String, String>{
        'dpr': '${configuration.devicePixelRatio}',
        'locale': '${configuration.locale?.toLanguageTag()}',
        'platform': '${configuration.platform?.name}',
        'width': '${configuration.size?.width}',
        'height': '${configuration.size?.height}',
        'bidi': '${configuration.textDirection?.name}',
      },
    );
    return SynchronousFuture<Uri>(result);
  }

  static http.Client get _httpClient =>
      // FIXME is an equivalent to this assert needed for http.Client?
      // assert(() {
      //   if (debugNetworkImageHttpClientProvider != null) {
      //     client = debugNetworkImageHttpClientProvider!();
      //   }
      //   return true;
      // }());
      http.Client();
  // FIXME confirm whether http.Client has an equivalent to this that needs to be called
  // ..autoUncompress = false;

  @override
  ImageStreamCompleter loadImage(Uri key, ImageDecoderCallback decode) {
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();
    debugPrint('Fetching "$key"...');
    return MultiFrameImageStreamCompleter(
      codec: _httpClient
          .get(key)
          .then<Uint8List>((http.Response response) => response.bodyBytes)
          .catchError((Object e, StackTrace stack) {
            scheduleMicrotask(() {
              PaintingBinding.instance.imageCache.evict(key);
            });
            return Future<Uint8List>.error(e, stack);
          })
          .whenComplete(chunkEvents.close)
          .then<ui.ImmutableBuffer>(ui.ImmutableBuffer.fromUint8List)
          .then<ui.Codec>(decode),
      chunkEvents: chunkEvents.stream,
      scale: 1.0,
      debugLabel: '"key"',
      informationCollector:
          () => <DiagnosticsNode>[
            DiagnosticsProperty<ImageProvider>('Image provider', this),
            DiagnosticsProperty<Uri>('URL', key),
          ],
    );
  }

  @override
  String toString() => '${objectRuntimeType(this, 'CustomNetworkImage')}("$url")';
}

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Image(
            image: const CustomNetworkImage(
              'https://flutter.github.io/assets-for-api-docs/assets/widgets/flamingos.jpg',
            ),
            width: constraints.hasBoundedWidth ? constraints.maxWidth : null,
            height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
          );
        },
      ),
    );
  }
}

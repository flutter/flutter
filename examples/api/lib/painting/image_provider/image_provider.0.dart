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

  @override
  ImageStreamCompleter loadImage(Uri key, ImageDecoderCallback decode) {
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();
    debugPrint('Fetching "$key"...');
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode: decode)
          .catchError((Object e, StackTrace stack) {
            scheduleMicrotask(() {
              PaintingBinding.instance.imageCache.evict(key);
            });
            return Future<ui.Codec>.error(e, stack);
          })
          .whenComplete(chunkEvents.close),
      chunkEvents: chunkEvents.stream,
      scale: 1.0,
      debugLabel: '"key"',
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<Uri>('URL', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    Uri key,
    StreamController<ImageChunkEvent> chunkEvents, {
    required ImageDecoderCallback decode,
  }) async {
    final http.Client client = http.Client();
    try {
      final http.StreamedResponse response = await client.send(
        http.Request('GET', key),
      );
      if (response.statusCode != 200) {
        await response.stream.drain<List<int>>(<int>[]);
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: key,
        );
      }

      final List<List<int>> chunks = <List<int>>[];
      int cumulativeBytesLoaded = 0;
      await for (final List<int> chunk in response.stream) {
        chunks.add(chunk);
        cumulativeBytesLoaded += chunk.length;
        chunkEvents.add(
          ImageChunkEvent(
            cumulativeBytesLoaded: cumulativeBytesLoaded,
            expectedTotalBytes: response.contentLength,
          ),
        );
      }

      if (cumulativeBytesLoaded == 0) {
        throw Exception('NetworkImage is an empty file: $key');
      }
      final Uint8List imageBytes = Uint8List(cumulativeBytesLoaded);
      int offset = 0;
      for (final List<int> chunk in chunks) {
        imageBytes.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      return await decode(await ui.ImmutableBuffer.fromUint8List(imageBytes));
    } finally {
      client.close();
    }
  }

  @override
  String toString() =>
      '${objectRuntimeType(this, 'CustomNetworkImage')}("$url")';
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

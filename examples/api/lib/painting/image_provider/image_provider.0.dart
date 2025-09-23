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
      codec: _loadAsync(key, decode, chunkEvents),
      chunkEvents: chunkEvents.stream,
      scale: 1.0,
      debugLabel: '"$key"',
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<Uri>('URL', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    Uri key,
    ImageDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    try {
      final http.Request request = http.Request('GET', key);
      final http.StreamedResponse response = await request.send();

      final int? contentLength = response.contentLength;
      int received = 0;
      final List<int> bytes = [];

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        chunkEvents.add(
          ImageChunkEvent(
            cumulativeBytesLoaded: received,
            expectedTotalBytes: contentLength,
          ),
        );
      }

      final Uint8List data = Uint8List.fromList(bytes);
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
        data,
      );
      return decode(buffer);
    } catch (e, _) {
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    } finally {
      await chunkEvents.close();
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

import 'dart:async' show Future, StreamController;
import 'dart:typed_data';
import 'dart:ui' as ui show Codec;
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum TestUseCase {
  loadAndFail,
  loadAndSuccess,
  success,
}

@immutable
class MockImageProvider extends ImageProvider<MockImageProvider> {
  final _timeStamp = DateTime.now().millisecondsSinceEpoch;
  MockImageProvider({
    required this.useCase,
  });

  final TestUseCase useCase;

  bool get showLoading =>
      useCase == TestUseCase.loadAndFail ||
      useCase == TestUseCase.loadAndSuccess;

  bool get fail => useCase == TestUseCase.loadAndFail;

  @override
  Future<MockImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<MockImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(MockImageProvider key, DecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode).first,
      chunkEvents: chunkEvents.stream,
      scale: 1.0,
    );
  }

  Stream<ui.Codec> _loadAsync(
    MockImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderCallback decode,
  ) async* {
    try {
      if (showLoading) {
        var totalSize = 100;
        for (var i = 0; i < totalSize; i++) {
          await Future.delayed(const Duration(milliseconds: 10));
          chunkEvents.add(ImageChunkEvent(
              cumulativeBytesLoaded: i + 1, expectedTotalBytes: totalSize));
        }
      }
      if (fail) {
        throw Exception("Image loading failed");
      }
      var url = 'https://blurha.sh/assets/images/img1.jpg';
      Uint8List imageBytes;
      imageBytes = (await http.get(Uri.parse(url))).bodyBytes;
      var decodedImage = await decode(imageBytes);
      yield decodedImage;
    } finally {
      await chunkEvents.close();
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (other is MockImageProvider) {
      return useCase == other.useCase && _timeStamp == other._timeStamp;
    }
    return false;
  }

  @override
  int get hashCode => useCase.hashCode;

  @override
  String toString() => '$runtimeType("$useCase")';
}

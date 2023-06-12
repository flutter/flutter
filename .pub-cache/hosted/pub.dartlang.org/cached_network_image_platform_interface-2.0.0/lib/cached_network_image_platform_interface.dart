library cached_network_image_platform_interface;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Render options for images on the web platform.
enum ImageRenderMethodForWeb {
  /// HtmlImage uses a default web image including default browser caching.
  /// This is the recommended and default choice.
  HtmlImage, // ignore: constant_identifier_names

  /// HttpGet uses an http client to fetch an image. It enables the use of
  /// headers, but loses some default web functionality.
  HttpGet, // ignore: constant_identifier_names
}

/// ImageLoader class to load images differently on various platforms.
class ImageLoader {
  /// loads the images async and gives the resulted codecs on a Stream. The
  /// Stream gives the option to show multiple images after each other.
  @Deprecated('use loadBufferAsync instead')
  Stream<ui.Codec> loadAsync(
    String url,
    String? cacheKey,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderCallback decode,
    BaseCacheManager cacheManager,
    int? maxHeight,
    int? maxWidth,
    Map<String, String>? headers,
    Function()? errorListener,
    ImageRenderMethodForWeb imageRenderMethodForWeb,
    Function() evictImage,
  ) {
    throw UnimplementedError();
  }

  /// loads the images async and gives the resulted codecs on a Stream. The
  /// Stream gives the option to show multiple images after each other.
  Stream<ui.Codec> loadBufferAsync(
    String url,
    String? cacheKey,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderBufferCallback decode,
    BaseCacheManager cacheManager,
    int? maxHeight,
    int? maxWidth,
    Map<String, String>? headers,
    Function()? errorListener,
    ImageRenderMethodForWeb imageRenderMethodForWeb,
    Function() evictImage,
  ) {
    throw UnimplementedError();
  }
}

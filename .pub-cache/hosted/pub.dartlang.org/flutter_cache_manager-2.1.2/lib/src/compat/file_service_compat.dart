import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_cache_manager/src/compat/file_fetcher.dart';

import '../../flutter_cache_manager.dart';
import '../web/mime_converter.dart';

class FileServiceCompat extends FileService {
  final FileFetcher fileFetcher;
  FileServiceCompat(this.fileFetcher);

  @override
  Future<FileServiceResponse> get(String url,
      {Map<String, String> headers}) async {
    var legacyResponse = await fileFetcher(url, headers: headers);
    return CompatFileServiceGetResponse(legacyResponse);
  }
}

class CompatFileServiceGetResponse implements FileServiceResponse {
  final FileFetcherResponse legacyResponse;
  final DateTime _receivedTime = clock.now();

  CompatFileServiceGetResponse(this.legacyResponse);

  bool _hasHeader(String name) {
    return legacyResponse.hasHeader(name);
  }

  String _header(String name) {
    return legacyResponse.header(name);
  }

  @override
  Stream<List<int>> get content => Stream.value(legacyResponse.bodyBytes);

  @override
  int get contentLength => legacyResponse.bodyBytes.length;

  @override
  DateTime get validTill {
    // Without a cache-control header we keep the file for a week
    var ageDuration = const Duration(days: 7);
    if (_hasHeader(HttpHeaders.cacheControlHeader)) {
      final controlSettings =
          _header(HttpHeaders.cacheControlHeader).split(',');
      for (final setting in controlSettings) {
        final sanitizedSetting = setting.trim().toLowerCase();
        if (sanitizedSetting == 'no-cache') {
          ageDuration = const Duration();
        }
        if (sanitizedSetting.startsWith('max-age=')) {
          var validSeconds = int.tryParse(sanitizedSetting.split('=')[1]) ?? 0;
          if (validSeconds > 0) {
            ageDuration = Duration(seconds: validSeconds);
          }
        }
      }
    }

    return _receivedTime.add(ageDuration);
  }

  @override
  String get eTag => _hasHeader(HttpHeaders.etagHeader)
      ? _header(HttpHeaders.etagHeader)
      : null;

  @override
  String get fileExtension {
    var fileExtension = '';
    if (_hasHeader(HttpHeaders.contentTypeHeader)) {
      var contentType =
          ContentType.parse(_header(HttpHeaders.contentTypeHeader));
      fileExtension = contentType.fileExtension ?? '';
    }
    return fileExtension;
  }

  @override
  int get statusCode => legacyResponse.statusCode as int;
}

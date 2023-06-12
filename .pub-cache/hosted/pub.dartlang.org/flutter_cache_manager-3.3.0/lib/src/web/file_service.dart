import 'dart:async';
import 'dart:io';
import 'package:clock/clock.dart';
import 'package:http/http.dart' as http;
import 'mime_converter.dart';

///Flutter Cache Manager
///Copyright (c) 2019 Rene Floor
///Released under MIT License.

/// Defines the interface for a file service.
/// Most common file service will be an [HttpFileService], however one can
/// also make something more specialized. For example you could fetch files
/// from other apps or from local storage.
abstract class FileService {
  int concurrentFetches = 10;
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers});
}

/// [HttpFileService] is the most common file service and the default for
/// [WebHelper]. One can easily adapt it to use dio or any other http client.
class HttpFileService extends FileService {
  final http.Client _httpClient;

  HttpFileService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  @override
  Future<FileServiceResponse> get(String url,
      {Map<String, String>? headers}) async {
    final req = http.Request('GET', Uri.parse(url));
    if (headers != null) {
      req.headers.addAll(headers);
    }
    final httpResponse = await _httpClient.send(req);

    return HttpGetResponse(httpResponse);
  }
}

/// Defines the interface for a get result of a [FileService].
abstract class FileServiceResponse {
  /// [content] is a stream of bytes
  Stream<List<int>> get content;

  /// [contentLength] is the total size of the content.
  /// If the size is not known beforehand contentLength is null.
  int? get contentLength;

  /// [statusCode] is expected to conform to an http status code.
  int get statusCode;

  /// Defines till when the cache should be assumed to be valid.
  DateTime get validTill;

  /// [eTag] is used when asking to update the cache
  String? get eTag;

  /// Used to save the file on the storage, includes a dot. For example '.jpeg'
  String get fileExtension;
}

/// Basic implementation of a [FileServiceResponse] for http requests.
class HttpGetResponse implements FileServiceResponse {
  HttpGetResponse(this._response);

  final DateTime _receivedTime = clock.now();

  final http.StreamedResponse _response;

  @override
  int get statusCode => _response.statusCode;

  String? _header(String name) {
    return _response.headers[name];
  }

  @override
  Stream<List<int>> get content => _response.stream;

  @override
  int? get contentLength => _response.contentLength;

  @override
  DateTime get validTill {
    // Without a cache-control header we keep the file for a week
    var ageDuration = const Duration(days: 7);
    final controlHeader = _header(HttpHeaders.cacheControlHeader);
    if (controlHeader != null) {
      final controlSettings = controlHeader.split(',');
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
  String? get eTag => _header(HttpHeaders.etagHeader);

  @override
  String get fileExtension {
    var fileExtension = '';
    final contentTypeHeader = _header(HttpHeaders.contentTypeHeader);
    if (contentTypeHeader != null) {
      final contentType = ContentType.parse(contentTypeHeader);
      fileExtension = contentType.fileExtension;
    }
    return fileExtension;
  }
}

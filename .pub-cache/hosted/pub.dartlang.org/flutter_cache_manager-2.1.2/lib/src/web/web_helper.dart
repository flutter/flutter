import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/result/file_response.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_cache_manager/src/web/file_service.dart';
import 'package:flutter_cache_manager/src/result/file_info.dart';
import 'package:flutter_cache_manager/src/web/queue_item.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

///Flutter Cache Manager
///Copyright (c) 2019 Rene Floor
///Released under MIT License.

const statusCodesNewFile = [HttpStatus.ok, HttpStatus.accepted];
const statusCodesFileNotChanged = [HttpStatus.notModified];

class WebHelper {
  WebHelper(this._store, FileService fileFetcher)
      : _memCache = {},
        fileFetcher = fileFetcher ?? HttpFileService();

  final CacheStore _store;
  @visibleForTesting
  final FileService fileFetcher;
  final Map<String, BehaviorSubject<FileResponse>> _memCache;
  final Queue<QueueItem> _queue = Queue();

  ///Download the file from the url
  Stream<FileResponse> downloadFile(String url,
      {String key,
      Map<String, String> authHeaders,
      bool ignoreMemCache = false}) {
    key ??= url;
    if (!_memCache.containsKey(key) || ignoreMemCache) {
      var subject = BehaviorSubject<FileResponse>();
      _memCache[key] = subject;
      unawaited(_downloadOrAddToQueue(url, key, authHeaders));
    }
    return _memCache[key].stream;
  }

  var concurrentCalls = 0;
  Future<void> _downloadOrAddToQueue(
    String url,
    String key,
    Map<String, String> authHeaders,
  ) async {
    //Add to queue if there are too many calls.
    if (concurrentCalls >= fileFetcher.concurrentFetches) {
      _queue.add(QueueItem(url, key, authHeaders));
      return;
    }

    concurrentCalls++;
    var subject = _memCache[key];
    try {
      await for (var result
          in _updateFile(url, key, authHeaders: authHeaders)) {
        subject.add(result);
      }
    } catch (e, stackTrace) {
      subject.addError(e, stackTrace);
    } finally {
      concurrentCalls--;
      await subject.close();
      _memCache.remove(key);
      _checkQueue();
    }
  }

  void _checkQueue() {
    if (_queue.isEmpty) return;
    var next = _queue.removeFirst();
    _downloadOrAddToQueue(next.url, next.key, next.headers);
  }

  ///Download the file from the url
  Stream<FileResponse> _updateFile(String url, String key,
      {Map<String, String> authHeaders}) async* {
    var cacheObject = await _store.retrieveCacheData(key);
    cacheObject = cacheObject == null
        ? CacheObject(url, key: key)
        : cacheObject.copyWith(url: url);
    final response = await _download(cacheObject, authHeaders);
    yield* _manageResponse(cacheObject, response);
  }

  Future<FileServiceResponse> _download(
      CacheObject cacheObject, Map<String, String> authHeaders) {
    final headers = <String, String>{};
    if (authHeaders != null) {
      headers.addAll(authHeaders);
    }

    if (cacheObject.eTag != null) {
      headers[HttpHeaders.ifNoneMatchHeader] = cacheObject.eTag;
    }

    return fileFetcher.get(cacheObject.url, headers: headers);
  }

  Stream<FileResponse> _manageResponse(
      CacheObject cacheObject, FileServiceResponse response) async* {
    final hasNewFile = statusCodesNewFile.contains(response.statusCode);
    final keepOldFile = statusCodesFileNotChanged.contains(response.statusCode);
    if (!hasNewFile && !keepOldFile) {
      throw HttpExceptionWithStatus(
        response.statusCode,
        'Invalid statusCode: ${response?.statusCode}',
        uri: Uri.parse(cacheObject.url),
      );
    }

    final oldCacheObject = cacheObject;
    var newCacheObject = _setDataFromHeaders(cacheObject, response);
    if (statusCodesNewFile.contains(response.statusCode)) {
      int savedBytes;
      await for (var progress in _saveFile(newCacheObject, response)) {
        savedBytes = progress;
        yield DownloadProgress(
            cacheObject.url, response.contentLength, progress);
      }
      newCacheObject = newCacheObject.copyWith(length: savedBytes);
    }

    unawaited(_store.putFile(newCacheObject).then((_) {
      if (newCacheObject.relativePath != oldCacheObject.relativePath) {
        _removeOldFile(oldCacheObject.relativePath);
      }
    }));

    final file = await _store.fileSystem.createFile(
      newCacheObject.relativePath,
    );
    yield FileInfo(
      file,
      FileSource.Online,
      newCacheObject.validTill,
      newCacheObject.url,
    );
  }

  CacheObject _setDataFromHeaders(
      CacheObject cacheObject, FileServiceResponse response) {
    final fileExtension = response.fileExtension;
    var filePath = cacheObject.relativePath;

    if (filePath != null &&
        !statusCodesFileNotChanged.contains(response.statusCode)) {
      if (!filePath.endsWith(fileExtension)) {
        //Delete old file directly when file extension changed
        unawaited(_removeOldFile(filePath));
      }
      // Store new file on different path
      filePath = null;
    }
    return cacheObject.copyWith(
      relativePath: filePath ?? '${Uuid().v1()}$fileExtension',
      validTill: response.validTill,
      eTag: response.eTag,
    );
  }

  Stream<int> _saveFile(CacheObject cacheObject, FileServiceResponse response) {
    var receivedBytesResultController = StreamController<int>();
    unawaited(_saveFileAndPostUpdates(
      receivedBytesResultController,
      cacheObject,
      response,
    ));
    return receivedBytesResultController.stream;
  }

  Future _saveFileAndPostUpdates(
      StreamController<int> receivedBytesResultController,
      CacheObject cacheObject,
      FileServiceResponse response) async {
    final file = await _store.fileSystem.createFile(cacheObject.relativePath);

    try {
      var receivedBytes = 0;
      final sink = file.openWrite();
      await response.content.map((s) {
        receivedBytes += s.length;
        receivedBytesResultController.add(receivedBytes);
        return s;
      }).pipe(sink);
    } catch (e, stacktrace) {
      receivedBytesResultController.addError(e, stacktrace);
    }
    await receivedBytesResultController.close();
  }

  Future<void> _removeOldFile(String relativePath) async {
    if (relativePath == null) return;
    final file = await _store.fileSystem.createFile(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class HttpExceptionWithStatus extends HttpException {
  const HttpExceptionWithStatus(this.statusCode, String message, {Uri uri})
      : super(message, uri: uri);
  final int statusCode;
}

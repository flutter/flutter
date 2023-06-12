// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'api_requester.dart';
import 'multipart_media_uploader.dart';
import 'request_impl.dart';
import 'requests.dart' as client_requests;

// TODO: Buffer less if we know the content length in advance.
/// Does media uploads using the resumable upload protocol.
class ResumableMediaUploader {
  final http.Client _httpClient;
  final client_requests.Media _uploadMedia;
  final Uri _uri;
  final String? _body;
  final String _method;
  final client_requests.ResumableUploadOptions _options;
  final Map<String, String> _requestHeaders;

  ResumableMediaUploader(
    this._httpClient,
    this._uploadMedia,
    this._body,
    this._uri,
    this._method,
    this._options,
    this._requestHeaders,
  );

  /// Returns the final [http.StreamedResponse] if the upload succeed and
  /// completes with an error otherwise.
  ///
  /// The returned response stream has not been listened to.
  Future<http.StreamedResponse> upload() async {
    final uploadUri = await _startSession();

    late StreamSubscription subscription;

    final completer = Completer<http.StreamedResponse>();
    var completed = false;

    final chunkStack = ChunkStack(_options.chunkSize);
    subscription = _uploadMedia.stream.listen((List<int> bytes) {
      chunkStack.addBytes(bytes);

      // Upload all but the last chunk.
      // The final send will be done in the [onDone] handler.
      final hasPartialChunk = chunkStack.hasPartialChunk;
      if (chunkStack.length > 1 ||
          (chunkStack.length == 1 && hasPartialChunk)) {
        // Pause the input stream.
        subscription.pause();

        // Upload all chunks except the last one.
        Iterable<_ResumableChunk> fullChunks;
        if (hasPartialChunk) {
          fullChunks = chunkStack.removeSublist(0, chunkStack.length);
        } else {
          fullChunks = chunkStack.removeSublist(0, chunkStack.length - 1);
        }

        Future.forEach(
          fullChunks,
          (_ResumableChunk c) => _uploadChunkDrained(uploadUri, c),
        ).then((_) {
          // All chunks uploaded, we can continue consuming data.
          subscription.resume();
        }).catchError((Object? error, StackTrace stack) {
          subscription.cancel();
          completed = true;
          completer.completeError(error ?? NullThrownError(), stack);
        });
      }
    }, onError: (Object? error, StackTrace stack) {
      subscription.cancel();
      if (!completed) {
        completed = true;
        completer.completeError(error ?? NullThrownError(), stack);
      }
    }, onDone: () {
      if (!completed) {
        chunkStack.finalize();

        _ResumableChunk lastChunk;
        if (chunkStack.length == 1) {
          lastChunk = chunkStack.removeSublist(0, chunkStack.length).first;
        } else {
          completer.completeError(StateError(
              'Resumable uploads need to result in at least one non-empty '
              'chunk at the end.'));
          return;
        }
        final end = lastChunk.endOfChunk;

        // Validate that we have the correct number of bytes if length was
        // specified.
        if (_uploadMedia.length != null) {
          if (end < _uploadMedia.length!) {
            completer.completeError(client_requests.ApiRequestError(
                'Received less bytes than indicated by [Media.length].'));
            return;
          } else if (end > _uploadMedia.length!) {
            completer.completeError(client_requests.ApiRequestError(
                'Received more bytes than indicated by [Media.length].'));
            return;
          }
        }

        // Upload last chunk and *do not drain the response* but complete
        // with it.
        _uploadChunkResumable(uploadUri, lastChunk, lastChunk: true)
            .then(completer.complete)
            .catchError((Object? error, StackTrace stack) {
          completer.completeError(error ?? NullThrownError(), stack);
        });
      }
    });

    return completer.future;
  }

  /// Starts a resumable upload.
  ///
  /// Returns the [Uri] which should be used for uploading all content.
  Future<Uri> _startSession() async {
    var length = 0;
    List<int>? bytes;
    if (_body != null) {
      bytes = utf8.encode(_body!);
      length = bytes.length;
    }
    final bodyStream =
        bytes == null ? const Stream<List<int>>.empty() : Stream.value(bytes);

    final request = RequestImpl(_method, _uri, bodyStream);
    request.headers.addAll({
      ..._requestHeaders,
      'content-type': contentTypeJsonUtf8,
      'content-length': '$length',
      'x-upload-content-type': _uploadMedia.contentType,
      'x-upload-content-length': '${_uploadMedia.length}',
    });

    final response = await _httpClient.send(request);

    await validateResponse(response);

    await response.stream.drain();

    final uploadUri = response.headers['location'];
    if (response.statusCode != 200 || uploadUri == null) {
      throw client_requests.ApiRequestError(
        'Invalid response for resumable upload attempt '
        '(status was: ${response.statusCode})',
      );
    }
    return Uri.parse(uploadUri);
  }

  /// Uploads [chunk], retries upon server errors. The response stream will be
  /// drained.
  Future _uploadChunkDrained(Uri uri, _ResumableChunk chunk) async {
    final response = await _uploadChunkResumable(uri, chunk);
    await response.stream.drain();
  }

  /// Does repeated attempts to upload [chunk].
  Future<http.StreamedResponse> _uploadChunkResumable(
    Uri uri,
    _ResumableChunk chunk, {
    bool lastChunk = false,
  }) {
    Future<http.StreamedResponse> tryUpload(int attemptsLeft) async {
      final response = await _uploadChunk(uri, chunk, lastChunk: lastChunk);

      final status = response.statusCode;
      if (attemptsLeft > 0 &&
          (status == 500 || (502 <= status && status < 504))) {
        await response.stream.drain();
        // Delay the next attempt. Default backoff function is exponential
        final failedAttempts = _options.numberOfAttempts - attemptsLeft;
        final duration = _options.backoffFunction(failedAttempts);
        if (duration == null) {
          throw client_requests.DetailedApiRequestError(
              status,
              'Resumable upload: Uploading a chunk resulted in status '
              '$status. Maximum number of retries reached.');
        }

        await Future.delayed(duration);
        return tryUpload(attemptsLeft - 1);
      } else if (!lastChunk && status != 308) {
        await response.stream.drain();
        throw client_requests.DetailedApiRequestError(
          status,
          'Resumable upload: Uploading a chunk resulted in status '
          '$status instead of 308.',
        );
      } else if (lastChunk && status != 201 && status != 200) {
        await response.stream.drain();
        throw client_requests.DetailedApiRequestError(
          status,
          'Resumable upload: Uploading a chunk resulted in status '
          '$status instead of 200 or 201.',
        );
      } else {
        return response;
      }
    }

    return tryUpload(_options.numberOfAttempts - 1);
  }

  /// Uploads [chunk] to [uri] and ensures the upload was successful.
  ///
  /// Returns [http.StreamedResponse] or completes with an error if
  /// the upload did not succeed.
  ///
  /// The response stream will not be listened to.
  Future<http.StreamedResponse> _uploadChunk(
    Uri uri,
    _ResumableChunk chunk, {
    bool lastChunk = false,
  }) {
    // If [uploadMedia.length] is null, we do not know the length.
    var mediaTotalLength = _uploadMedia.length?.toString();
    if (mediaTotalLength == null || lastChunk) {
      if (lastChunk) {
        mediaTotalLength = '${chunk.endOfChunk}';
      } else {
        mediaTotalLength = '*';
      }
    }

    final headers = {
      ..._requestHeaders,
      'content-type': _uploadMedia.contentType,
      'content-length': '${chunk.length}',
      'content-range':
          'bytes ${chunk.offset}-${chunk.endOfChunk - 1}/$mediaTotalLength',
    };

    final stream = Stream.fromIterable(chunk.byteArrays);
    final request = RequestImpl('PUT', uri, stream);
    request.headers.addAll(headers);
    return _httpClient.send(request);
  }
}

/// Represents a stack of [_ResumableChunk]s.
@visibleForTesting
class ChunkStack {
  final int _chunkSize;
  final List<_ResumableChunk> _chunkStack = [];

  // Currently accumulated data.
  List<List<int>> _byteArrays = [];
  int _length = 0;
  int _offset = 0;

  bool _finalized = false;

  ChunkStack(this._chunkSize);

  /// Whether data for a not-yet-finished [_ResumableChunk] is present.
  ///
  /// A call to `finalize` will create a [_ResumableChunk] of this data.
  bool get hasPartialChunk => _length > 0;

  /// The number of chunks in this [ChunkStack].
  int get length => _chunkStack.length;

  /// The total number of bytes which have been converted to [_ResumableChunk]s.
  /// Can only be called once this [ChunkStack] has been finalized.
  int get totalByteLength {
    if (!_finalized) {
      throw StateError('ChunkStack has not been finalized yet.');
    }

    return _offset;
  }

  /// Returns the chunks [from] ... [to] and deletes it from the stack.
  List<_ResumableChunk> removeSublist(int from, int to) {
    final sublist = _chunkStack.sublist(from, to);
    _chunkStack.removeRange(from, to);
    return sublist;
  }

  /// Adds [bytes] to the buffer. If the buffer is larger than the given chunk
  /// size a new [_ResumableChunk] will be created.
  void addBytes(List<int> bytes) {
    if (_finalized) {
      throw StateError('ChunkStack has already been finalized.');
    }

    final remaining = _chunkSize - _length;

    if (bytes.length >= remaining) {
      final left = bytes.sublist(0, remaining);
      final right = bytes.sublist(remaining);

      _byteArrays.add(left);
      _length += left.length;

      _chunkStack.add(_ResumableChunk(_byteArrays, _offset, _length));

      _byteArrays = [];
      _offset += _length;
      _length = 0;

      addBytes(right);
    } else if (bytes.isNotEmpty) {
      _byteArrays.add(bytes);
      _length += bytes.length;
    }
  }

  /// Finalizes this [ChunkStack] and creates the last chunk (may have less
  /// bytes than the chunk size, but not zero).
  void finalize() {
    if (_finalized) {
      throw StateError('ChunkStack has already been finalized.');
    }
    _finalized = true;

    if (_length > 0) {
      _chunkStack.add(_ResumableChunk(_byteArrays, _offset, _length));
      _offset += _length;
    }
  }
}

/// Represents a chunk of data that will be transferred in one http request.
class _ResumableChunk {
  final List<List<int>> byteArrays;
  final int offset;
  final int length;

  /// Index of the next byte after this chunk.
  int get endOfChunk => offset + length;

  _ResumableChunk(this.byteArrays, this.offset, this.length);
}

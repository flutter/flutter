// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'char_code.dart' as char_code;
import 'mime_shared.dart';

/// Bytes for '()<>@,;:\\"/[]?={} \t'.
const _separators = {
  40, 41, 60, 62, 64, 44, 59, 58, 92, 34, 47, 91, 93, 63, 61, 123, 125, 32, 9 //
};

bool _isTokenChar(int byte) =>
    byte > 31 && byte < 128 && !_separators.contains(byte);

int _toLowerCase(int byte) {
  const delta = char_code.lowerA - char_code.upperA;
  return (char_code.upperA <= byte && byte <= char_code.upperZ)
      ? byte + delta
      : byte;
}

void _expectByteValue(int val1, int val2) {
  if (val1 != val2) {
    throw MimeMultipartException('Failed to parse multipart mime 1');
  }
}

void _expectWhitespace(int byte) {
  if (byte != char_code.sp && byte != char_code.ht) {
    throw MimeMultipartException('Failed to parse multipart mime 2');
  }
}

class _MimeMultipart extends MimeMultipart {
  @override
  final Map<String, String> headers;
  final Stream<List<int>> _stream;

  _MimeMultipart(this.headers, this._stream);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> data)? onData, {
    void Function()? onDone,
    Function? onError,
    bool? cancelOnError,
  }) =>
      _stream.listen(
        onData,
        onDone: onDone,
        onError: onError,
        cancelOnError: cancelOnError,
      );
}

class BoundMultipartStream {
  static const int _startCode = 0;
  static const int _boundaryEndingCode = 1;
  static const int _boundaryEndCode = 2;
  static const int _headerStartCode = 3;
  static const int _headerFieldCode = 4;
  static const int _headerValueStartCode = 5;
  static const int _headerValueCode = 6;
  static const int _headerValueFoldingOrEndingCode = 7;
  static const int _headerValueFoldOrEndCode = 8;
  static const int _headerEndingCode = 9;
  static const int _contentCode = 10;
  static const int _lastBoundaryDash2Code = 11;
  static const int _lastBoundaryEndingCode = 12;
  static const int _lastBoundaryEndCode = 13;
  static const int _doneCode = 14;
  static const int _failCode = 15;

  final List<int> _boundary;
  final List<int> _headerField = [];
  final List<int> _headerValue = [];

  // The following states belong to `_controller`, state changes will not be
  // immediately acted upon but rather only after the current
  // `_multipartController` is done.
  static const int _controllerStateIdle = 0;
  static const int _controllerStateActive = 1;
  static const int _controllerStatePaused = 2;
  static const int _controllerStateCanceled = 3;

  int _controllerState = _controllerStateIdle;

  final _controller = StreamController<MimeMultipart>(sync: true);

  Stream<MimeMultipart> get stream => _controller.stream;

  late StreamSubscription _subscription;

  StreamController<List<int>>? _multipartController;
  Map<String, String>? _headers;

  int _state = _startCode;
  int _boundaryIndex = 2;

  /// Current index into [_buffer].
  ///
  /// If index is negative then it is the index into the artificial prefix of
  /// the boundary string.
  int _index = 0;
  List<int> _buffer = _placeholderBuffer;

  BoundMultipartStream(this._boundary, Stream<List<int>> stream) {
    _controller
      ..onPause = _pauseStream
      ..onResume = _resumeStream
      ..onCancel = () {
        _controllerState = _controllerStateCanceled;
        _tryPropagateControllerState();
      }
      ..onListen = () {
        _controllerState = _controllerStateActive;
        _subscription = stream.listen((data) {
          assert(_buffer == _placeholderBuffer);
          _subscription.pause();
          _buffer = data;
          _index = 0;
          _parse();
        }, onDone: () {
          if (_state != _doneCode) {
            _controller
                .addError(MimeMultipartException('Bad multipart ending'));
          }
          _controller.close();
        }, onError: _controller.addError);
      };
  }

  void _resumeStream() {
    assert(_controllerState == _controllerStatePaused);
    _controllerState = _controllerStateActive;
    _tryPropagateControllerState();
  }

  void _pauseStream() {
    _controllerState = _controllerStatePaused;
    _tryPropagateControllerState();
  }

  void _tryPropagateControllerState() {
    if (_multipartController == null) {
      switch (_controllerState) {
        case _controllerStateActive:
          if (_subscription.isPaused) _subscription.resume();
          break;
        case _controllerStatePaused:
          if (!_subscription.isPaused) _subscription.pause();
          break;
        case _controllerStateCanceled:
          _subscription.cancel();
          break;
        default:
          throw StateError('This code should never be reached.');
      }
    }
  }

  void _parse() {
    // Number of boundary bytes to artificially place before the supplied data.
    // The data to parse might be 'artificially' prefixed with a
    // partial match of the boundary.
    var boundaryPrefix = _boundaryIndex;
    // Position where content starts. Will be null if no known content
    // start exists. Will be negative of the content starts in the
    // boundary prefix. Will be zero or position if the content starts
    // in the current buffer.
    var contentStartIndex =
        _state == _contentCode && _boundaryIndex == 0 ? 0 : null;

    // Function to report content data for the current part. The data
    // reported is from the current content start index up til the
    // current index. As the data can be artificially prefixed with a
    // prefix of the boundary both the content start index and index
    // can be negative.
    void reportData() {
      if (contentStartIndex! < 0) {
        var contentLength = boundaryPrefix + _index - _boundaryIndex;
        if (contentLength <= boundaryPrefix) {
          _multipartController!.add(_boundary.sublist(0, contentLength));
        } else {
          _multipartController!.add(_boundary.sublist(0, boundaryPrefix));
          _multipartController!
              .add(_buffer.sublist(0, contentLength - boundaryPrefix));
        }
      } else {
        var contentEndIndex = _index - _boundaryIndex;
        _multipartController!
            .add(_buffer.sublist(contentStartIndex, contentEndIndex));
      }
    }

    while (
        _index < _buffer.length && _state != _failCode && _state != _doneCode) {
      var byte =
          _index < 0 ? _boundary[boundaryPrefix + _index] : _buffer[_index];
      switch (_state) {
        case _startCode:
          if (byte == _boundary[_boundaryIndex]) {
            _boundaryIndex++;
            if (_boundaryIndex == _boundary.length) {
              _state = _boundaryEndingCode;
              _boundaryIndex = 0;
            }
          } else {
            // Restart matching of the boundary.
            _index = _index - _boundaryIndex;
            _boundaryIndex = 0;
          }
          break;

        case _boundaryEndingCode:
          if (byte == char_code.cr) {
            _state = _boundaryEndCode;
          } else if (byte == char_code.dash) {
            _state = _lastBoundaryDash2Code;
          } else {
            _expectWhitespace(byte);
          }
          break;

        case _boundaryEndCode:
          _expectByteValue(byte, char_code.lf);
          _multipartController?.close();
          if (_multipartController != null) {
            _multipartController = null;
            _tryPropagateControllerState();
          }
          _state = _headerStartCode;
          break;

        case _headerStartCode:
          _headers = <String, String>{};
          if (byte == char_code.cr) {
            _state = _headerEndingCode;
          } else {
            // Start of new header field.
            _headerField.add(_toLowerCase(byte));
            _state = _headerFieldCode;
          }
          break;

        case _headerFieldCode:
          if (byte == char_code.colon) {
            _state = _headerValueStartCode;
          } else {
            if (!_isTokenChar(byte)) {
              throw MimeMultipartException('Invalid header field name');
            }
            _headerField.add(_toLowerCase(byte));
          }
          break;

        case _headerValueStartCode:
          if (byte == char_code.cr) {
            _state = _headerValueFoldingOrEndingCode;
          } else if (byte != char_code.sp && byte != char_code.ht) {
            // Start of new header value.
            _headerValue.add(byte);
            _state = _headerValueCode;
          }
          break;

        case _headerValueCode:
          if (byte == char_code.cr) {
            _state = _headerValueFoldingOrEndingCode;
          } else {
            _headerValue.add(byte);
          }
          break;

        case _headerValueFoldingOrEndingCode:
          _expectByteValue(byte, char_code.lf);
          _state = _headerValueFoldOrEndCode;
          break;

        case _headerValueFoldOrEndCode:
          if (byte == char_code.sp || byte == char_code.ht) {
            _state = _headerValueStartCode;
          } else {
            var headerField = utf8.decode(_headerField);
            var headerValue = utf8.decode(_headerValue);
            _headers![headerField.toLowerCase()] = headerValue;
            _headerField.clear();
            _headerValue.clear();
            if (byte == char_code.cr) {
              _state = _headerEndingCode;
            } else {
              // Start of new header field.
              _headerField.add(_toLowerCase(byte));
              _state = _headerFieldCode;
            }
          }
          break;

        case _headerEndingCode:
          _expectByteValue(byte, char_code.lf);
          _multipartController = StreamController(
              sync: true,
              onListen: () {
                if (_subscription.isPaused) _subscription.resume();
              },
              onPause: _subscription.pause,
              onResume: _subscription.resume);
          _controller
              .add(_MimeMultipart(_headers!, _multipartController!.stream));
          _headers = null;
          _state = _contentCode;
          contentStartIndex = _index + 1;
          break;

        case _contentCode:
          if (byte == _boundary[_boundaryIndex]) {
            _boundaryIndex++;
            if (_boundaryIndex == _boundary.length) {
              if (contentStartIndex != null) {
                _index++;
                reportData();
                _index--;
              }
              _multipartController!.close();
              _multipartController = null;
              _tryPropagateControllerState();
              _boundaryIndex = 0;
              _state = _boundaryEndingCode;
            }
          } else {
            // Restart matching of the boundary.
            _index = _index - _boundaryIndex;
            contentStartIndex ??= _index;
            _boundaryIndex = 0;
          }
          break;

        case _lastBoundaryDash2Code:
          _expectByteValue(byte, char_code.dash);
          _state = _lastBoundaryEndingCode;
          break;

        case _lastBoundaryEndingCode:
          if (byte == char_code.cr) {
            _state = _lastBoundaryEndCode;
          } else {
            _expectWhitespace(byte);
          }
          break;

        case _lastBoundaryEndCode:
          _expectByteValue(byte, char_code.lf);
          _multipartController?.close();
          if (_multipartController != null) {
            _multipartController = null;
            _tryPropagateControllerState();
          }
          _state = _doneCode;
          break;

        default:
          // Should be unreachable.
          assert(false);
          break;
      }

      // Move to the next byte.
      _index++;
    }

    // Report any known content.
    if (_state == _contentCode && contentStartIndex != null) {
      reportData();
    }

    // Resume if at end.
    if (_index == _buffer.length) {
      _buffer = _placeholderBuffer;
      _index = 0;
      _subscription.resume();
    }
  }
}

// Used as a placeholder instead of having a nullable buffer.
const _placeholderBuffer = <int>[];

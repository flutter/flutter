import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';


/// Efficiently converts the response body of an [HttpClientResponse] into a [Uint8List].
/// 
/// The future returned by [convert] will forward all errors emitted by [response].
Future<Uint8List> convertResponse(HttpClientResponse response) {
  // dart:io guarantees that [contentLength] is -1 if the the header is missing or
  // invalid.  This could still happen if a mocked response object does not fully
  // implement the interface.
  assert(response.contentLength != null);
  final Completer<Uint8List> completer = new Completer<Uint8List>.sync();
  if (response.contentLength == -1) {
    final ByteConversionSink sink = new ByteConversionSink.withCallback((List<int> chunk) {
      final Uint8List bytes = new Uint8List.fromList(chunk);
      completer.complete(bytes);
    });
    response.listen(sink.add, onDone: sink.close, onError: completer.completeError, cancelOnError: true);
  } else {
    // If the response has a content length, then allocate a buffer of the correct size.
    final Uint8List bytes = new Uint8List(response.contentLength);
    int offset = 0;
    response.listen((List<int> chunk) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    },
    onError: completer.completeError,
    onDone: () {
      completer.complete(bytes);
    },
    cancelOnError: true);
  }
  return completer.future;
}

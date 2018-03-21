import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';


/// [ResponseConverter] efficiently converts the response body of an [HttpClientResponse]
/// into a [Uint8List].
/// 
/// The future returned by [convert] will forward all errors emitted by [response].
class ResponseConverter extends Converter<HttpClientResponse, Future<Uint8List>> {
  const ResponseConverter();
  
  @override
  Future<Uint8List> convert(HttpClientResponse response) {
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
      response.listen((List<int> chunk) {
        bytes.addAll(chunk);
      },
      onError: completer.completeError,
      onDone: () {
        completer.complete(bytes);
      },
      cancelOnError: true);
    }
    return completer.future;
  }
}

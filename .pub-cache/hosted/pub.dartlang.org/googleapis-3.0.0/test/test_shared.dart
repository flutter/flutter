import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:http/http.dart' as http;

class HttpServerMock extends http.BaseClient {
  late core.Future<http.StreamedResponse> Function(
      http.BaseRequest, core.Object?) _callback;
  late core.bool _expectJson;

  void register(
    core.Future<http.StreamedResponse> Function(
      http.BaseRequest,
      core.Object?,
    )
        callback,
    core.bool expectJson,
  ) {
    _callback = callback;
    _expectJson = expectJson;
  }

  @core.override
  async.Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_expectJson) {
      final jsonString =
          await request.finalize().transform(convert.utf8.decoder).join();
      if (jsonString.isEmpty) {
        return _callback(request, null);
      } else {
        return _callback(request, convert.json.decode(jsonString));
      }
    } else {
      final stream = request.finalize();
      final data = await stream.toBytes();
      return _callback(request, data);
    }
  }
}

http.StreamedResponse stringResponse(
  core.int status,
  core.Map<core.String, core.String> headers,
  core.String body,
) {
  final stream = async.Stream.fromIterable([convert.utf8.encode(body)]);
  return http.StreamedResponse(stream, status, headers: headers);
}

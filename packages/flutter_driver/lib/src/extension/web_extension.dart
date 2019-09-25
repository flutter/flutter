import 'dart:convert';
import 'dart:html';    // ignore: uri_does_not_exist
import 'dart:js';      // ignore: uri_does_not_exist
import 'dart:js_util'; // ignore: uri_does_not_exist

void registerWebServiceExtension(Future<Map<String, dynamic>> Function(Map<String, String>) call) {
  setProperty(window, '\$flutterDriver', allowInterop((dynamic message) async { // ignore: undefined_function, undefined_identifier
    final Map<Object, Object> params = json.decode(message);
    final Map<Object, Object> result = await call(params);
    return json.encode(result);
  }));
}

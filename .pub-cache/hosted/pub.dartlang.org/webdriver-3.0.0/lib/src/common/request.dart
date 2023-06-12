import 'dart:convert';

class HttpMethod {
  final String name;

  const HttpMethod._(this.name);

  @override
  String toString() => 'HttpMethod.$name';

  static const httpGet = HttpMethod._('GET');
  static const httpPost = HttpMethod._('POST');
  static const httpDelete = HttpMethod._('DELETE');
}

/// Request data to send to WebDriver.
///
/// It should be converted to corresponding object in different implementations
/// of [RequestClient].
/// This is useful to remove dependency on implementation specific request
/// class.
class WebDriverRequest {
  final HttpMethod? method;

  final String? uri;

  final String? body;

  WebDriverRequest(this.method, this.uri, this.body);

  WebDriverRequest.postRequest(this.uri, [params])
      : method = HttpMethod.httpPost,
        body = params == null ? '{}' : json.encode(params);

  WebDriverRequest.getRequest(this.uri)
      : method = HttpMethod.httpGet,
        body = null;

  WebDriverRequest.deleteRequest(this.uri)
      : method = HttpMethod.httpDelete,
        body = null;

  /// Represents request that has no http request to make.
  ///
  /// Useful when the endpoint is not supported but can be inferred in some
  /// degree locally.
  WebDriverRequest.nullRequest(this.body)
      : method = null,
        uri = null;

  @override
  String toString() => '${method!.name} $uri: $body';
}

/// Request data got from WebDriver.
///
/// It should be converted from corresponding object in different
/// implementations of [RequestClient].
/// This is useful to remove dependency on implementation specific response
/// class.
class WebDriverResponse {
  final int? statusCode;

  final String? reasonPhrase;
  final String? body;

  WebDriverResponse(this.statusCode, this.reasonPhrase, this.body);

  @override
  String toString() => '$reasonPhrase ($statusCode): $body';
}

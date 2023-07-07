[![pub package](https://img.shields.io/pub/v/http.svg)](https://pub.dev/packages/http)
[![package publisher](https://img.shields.io/pub/publisher/http.svg)](https://pub.dev/packages/http/publisher)

A composable, Future-based library for making HTTP requests.

This package contains a set of high-level functions and classes that make it
easy to consume HTTP resources. It's multi-platform, and supports mobile, desktop,
and the browser.

## Using

The easiest way to use this library is via the top-level functions. They allow
you to make individual HTTP requests with minimal hassle:

```dart
import 'package:http/http.dart' as http;

var url = Uri.https('example.com', 'whatsit/create');
var response = await http.post(url, body: {'name': 'doodle', 'color': 'blue'});
print('Response status: ${response.statusCode}');
print('Response body: ${response.body}');

print(await http.read(Uri.https('example.com', 'foobar.txt')));
```

If you're making multiple requests to the same server, you can keep open a
persistent connection by using a [Client][] rather than making one-off requests.
If you do this, make sure to close the client when you're done:

```dart
var client = http.Client();
try {
  var response = await client.post(
      Uri.https('example.com', 'whatsit/create'),
      body: {'name': 'doodle', 'color': 'blue'});
  var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
  var uri = Uri.parse(decodedResponse['uri'] as String);
  print(await client.get(uri));
} finally {
  client.close();
}
```

You can also exert more fine-grained control over your requests and responses by
creating [Request][] or [StreamedRequest][] objects yourself and passing them to
[Client.send][].

[Request]: https://pub.dev/documentation/http/latest/http/Request-class.html
[StreamedRequest]: https://pub.dev/documentation/http/latest/http/StreamedRequest-class.html
[Client.send]: https://pub.dev/documentation/http/latest/http/Client/send.html

This package is designed to be composable. This makes it easy for external
libraries to work with one another to add behavior to it. Libraries wishing to
add behavior should create a subclass of [BaseClient][] that wraps another
[Client][] and adds the desired behavior:

[BaseClient]: https://pub.dev/documentation/http/latest/http/BaseClient-class.html
[Client]: https://pub.dev/documentation/http/latest/http/Client-class.html

```dart
class UserAgentClient extends http.BaseClient {
  final String userAgent;
  final http.Client _inner;

  UserAgentClient(this.userAgent, this._inner);

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['user-agent'] = userAgent;
    return _inner.send(request);
  }
}
```

## Retrying requests

`package:http/retry.dart` provides a class [`RetryClient`][RetryClient] to wrap
an underlying [`http.Client`][Client] which transparently retries failing
requests.

[RetryClient]: https://pub.dev/documentation/http/latest/retry/RetryClient-class.html
[Client]: https://pub.dev/documentation/http/latest/http/Client-class.html

```dart
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

Future<void> main() async {
  final client = RetryClient(http.Client());
  try {
    print(await client.read(Uri.http('example.org', '')));
  } finally {
    client.close();
  }
}
```

By default, this retries any request whose response has status code 503
Temporary Failure up to three retries. It waits 500ms before the first retry,
and increases the delay by 1.5x each time. All of this can be customized using
the [`RetryClient()`][new RetryClient] constructor.

[new RetryClient]: https://pub.dev/documentation/http/latest/retry/RetryClient/RetryClient.html

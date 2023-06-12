[![Dart CI](https://github.com/dart-lang/json_rpc_2/actions/workflows/test-package.yml/badge.svg)](https://github.com/dart-lang/json_rpc_2/actions/workflows/test-package.yml)
[![pub package](https://img.shields.io/pub/v/json_rpc_2.svg)](https://pub.dev/packages/json_rpc_2)
[![package publisher](https://img.shields.io/pub/publisher/json_rpc_2.svg)](https://pub.dev/packages/json_rpc_2/publisher)

A library that implements the [JSON-RPC 2.0 spec][spec].

[spec]: https://www.jsonrpc.org/specification

## Server

A JSON-RPC 2.0 server exposes a set of methods that can be called by clients.
These methods can be registered using `Server.registerMethod`:

```dart
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  var socket = WebSocketChannel.connect(Uri.parse('ws://localhost:4321'));

  // The socket is a `StreamChannel<dynamic>` because it might emit binary
  // `List<int>`, but JSON RPC 2 only works with Strings so we assert it only
  // emits those by casting it.
  var server = Server(socket.cast<String>());

  // Any string may be used as a method name. JSON-RPC 2.0 methods are
  // case-sensitive.
  var i = 0;
  server.registerMethod('count', () {
    // Just return the value to be sent as a response to the client. This can
    // be anything JSON-serializable, or a Future that completes to something
    // JSON-serializable.
    return i++;
  });

  // Methods can take parameters. They're presented as a `Parameters` object
  // which makes it easy to validate that the expected parameters exist.
  server.registerMethod('echo', (Parameters params) {
    // If the request doesn't have a "message" parameter this will
    // automatically send a response notifying the client that the request
    // was invalid.
    return params['message'].value;
  });

  // `Parameters` has methods for verifying argument types.
  server.registerMethod('subtract', (Parameters params) {
    // If "minuend" or "subtrahend" aren't numbers, this will reject the
    // request.
    return params['minuend'].asNum - params['subtrahend'].asNum;
  });

  // [Parameters] also supports optional arguments.
  server.registerMethod('sort', (Parameters params) {
    var list = params['list'].asList;
    list.sort();
    if (params['descendint'].asBoolOr(false)) {
      return list.reversed;
    } else {
      return list;
    }
  });

  // A method can send an error response by throwing a `RpcException`.
  // Any positive number may be used as an application- defined error code.
  const dividByZero = 1;
  server.registerMethod('divide', (Parameters params) {
    var divisor = params['divisor'].asNum;
    if (divisor == 0) {
      throw RpcException(dividByZero, 'Cannot divide by zero.');
    }

    return params['dividend'].asNum / divisor;
  });

  // To give you time to register all your methods, the server won't start
  // listening for requests until you call `listen`. Messages are buffered until
  // listen is called. The returned Future won't complete until the connection
  // is closed.
  server.listen();
}
```

## Client

A JSON-RPC 2.0 client calls methods on a server and handles the server's
responses to those method calls. These methods can be called using
`Client.sendRequest`:

```dart
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:pedantic/pedantic.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  var socket = WebSocketChannel.connect(Uri.parse('ws://localhost:4321'));
  var client = Client(socket.cast<String>());

  // The client won't subscribe to the input stream until you call `listen`.
  // The returned Future won't complete until the connection is closed.
  unawaited(client.listen());

  // This calls the "count" method on the server. A Future is returned that
  // will complete to the value contained in the server's response.
  var count = await client.sendRequest('count');
  print('Count is $count');

  // Parameters are passed as a simple Map or, for positional parameters, an
  // Iterable. Make sure they're JSON-serializable!
  var echo = await client.sendRequest('echo', {'message': 'hello'});
  print('Echo says "$echo"!');

  // A notification is a way to call a method that tells the server that no
  // result is expected. Its return type is `void`; even if it causes an
  // error, you won't hear back.
  client.sendNotification('count');

  // If the server sends an error response, the returned Future will complete
  // with an RpcException. You can catch this error and inspect its error
  // code, message, and any data that the server sent along with it.
  try {
    await client.sendRequest('divide', {'dividend': 2, 'divisor': 0});
  } on RpcException catch (error) {
    print('RPC error ${error.code}: ${error.message}');
  }
}
```

## Peer

Although JSON-RPC 2.0 only explicitly describes clients and servers, it also
mentions that two-way communication can be supported by making each endpoint
both a client and a server. This package supports this directly using the `Peer`
class, which implements both `Client` and `Server`. It supports the same methods
as those classes, and automatically makes sure that every message from the other
endpoint is routed and handled correctly.

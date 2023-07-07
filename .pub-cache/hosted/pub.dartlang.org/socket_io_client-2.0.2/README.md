# socket.io-client-dart

Port of awesome JavaScript Node.js library - [Socket.io-client v2.0.1~v3.0.3](https://github.com/socketio/socket.io-client) - in Dart

### Version info:

| socket.io-client-dart | Socket.io Server
-------------------|----------------
`v0.9.*` ~ `v1.* ` | `v2.*`
`v2.*`             | `v3.*` & `v4.*`

## Usage

**Dart Server**
```dart
import 'package:socket_io/socket_io.dart';

main() {
  // Dart server
  var io = Server();
  var nsp = io.of('/some');
  nsp.on('connection', (client) {
    print('connection /some');
    client.on('msg', (data) {
      print('data from /some => $data');
      client.emit('fromServer', "ok 2");
    });
  });
  io.on('connection', (client) {
    print('connection default namespace');
    client.on('msg', (data) {
      print('data from default => $data');
      client.emit('fromServer', "ok");
    });
  });
  io.listen(3000);
}
```
**Dart Client**
```dart

import 'package:socket_io_client/socket_io_client.dart' as IO;

main() {
  // Dart client
  IO.Socket socket = IO.io('http://localhost:3000');
  socket.onConnect((_) {
    print('connect');
    socket.emit('msg', 'test');
  });
  socket.on('event', (data) => print(data));
  socket.onDisconnect((_) => print('disconnect'));
  socket.on('fromServer', (_) => print(_));
}
```

### Connect manually

To connect the socket manually, set the option `autoConnect: false` and call `.connect()`.

For example,

<pre>
Socket socket = io('http://localhost:3000', 
    OptionBuilder()
      .setTransports(['websocket']) // for Flutter or Dart VM
      .<b>disableAutoConnect()</b>  // disable auto-connection
      .setExtraHeaders({'foo': 'bar'}) // optional
      .build()
  );
<b>socket.connect();</b>
</pre>

Note that `.connect()` should not be called if `autoConnect: true` 
(by default, it's enabled to true), as this will cause all event handlers to get registered/fired twice. See [Issue #33](https://github.com/rikulo/socket.io-client-dart/issues/33).

### Update the extra headers

```dart
Socket socket = ... // Create socket.
socket.io.options['extraHeaders'] = {'foo': 'bar'}; // Update the extra headers.
socket.io..disconnect()..connect(); // Reconnect the socket manually.
```

### Emit with acknowledgement

```dart
Socket socket = ... // Create socket.
socket.onConnect((_) {
    print('connect');
    socket.emitWithAck('msg', 'init', ack: (data) {
        print('ack $data') ;
        if (data != null) {
          print('from server $data');
        } else {
          print("Null") ;
        }
    });
});
```

### Socket connection events

These events can be listened on.

```dart
const List EVENTS = [
  'connect',
  'connect_error',
  'connect_timeout',
  'connecting',
  'disconnect',
  'error',
  'reconnect',
  'reconnect_attempt',
  'reconnect_failed',
  'reconnect_error',
  'reconnecting',
  'ping',
  'pong'
];

// Replace 'onConnect' with any of the above events.
socket.onConnect((_) {
    print('connect');
});
```

### Acknowledge with the socket server that an event has been received.

```dart
socket.on('eventName', (data) {
    final dataList = data as List;
    final ack = dataList.last as Function;
    ack(null);
});
```

## Usage (Flutter)

In Flutter env. not (Flutter Web env.) it only works with `dart:io` websocket,
 not with `dart:html` websocket or Ajax (XHR), so in this case
you have to add `setTransports(['websocket'])` when creates the socket instance.

For example,

```dart
IO.Socket socket = IO.io('http://localhost:3000',
  OptionBuilder()
      .setTransports(['websocket']) // for Flutter or Dart VM
      .setExtraHeaders({'foo': 'bar'}) // optional
      .build());
```

## Usage with stream and streambuilder in Flutter

```dart
import 'dart:async';


// STEP1:  Stream setup
class StreamSocket{
  final _socketResponse= StreamController<String>();

  void Function(String) get addResponse => _socketResponse.sink.add;

  Stream<String> get getResponse => _socketResponse.stream;

  void dispose(){
    _socketResponse.close();
  }
}

StreamSocket streamSocket =StreamSocket();

//STEP2: Add this function in main function in main.dart file and add incoming data to the stream
void connectAndListen(){
  IO.Socket socket = IO.io('http://localhost:3000',
      OptionBuilder()
       .setTransports(['websocket']).build());

    socket.onConnect((_) {
     print('connect');
     socket.emit('msg', 'test');
    });

    //When an event recieved from server, data is added to the stream
    socket.on('event', (data) => streamSocket.addResponse);
    socket.onDisconnect((_) => print('disconnect'));

}

//Step3: Build widgets with streambuilder

class BuildWithSocketStream extends StatelessWidget {
  const BuildWithSocketStream({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder(
        stream: streamSocket.getResponse ,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot){
          return Container(
            child: snapshot.data,
          );
        },
      ),
    );
  }
}

```

## Troubleshooting

### Cannot connect "https" server or self-signed certificate server

- Refer to https://github.com/dart-lang/sdk/issues/34284 issue.
  The workround is to use the following code provided by [@lehno](https://github.com/lehno) on [#84](https://github.com/rikulo/socket.io-client-dart/issues/84)

```dart
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}
```

### Memory leak issues in iOS when closing socket.

- Refer to https://github.com/rikulo/socket.io-client-dart/issues/108 issue.
  Please use `socket.dispose()` instead of `socket.close()` or `socket.disconnect()` to solve the memory leak issue on iOS.

### Connect_error on MacOS with SocketException: Connection failed
* Refer to https://github.com/flutter/flutter/issues/47606#issuecomment-568522318 issue.
           
By adding the following key into the to file `*.entitlements` under directory `macos/Runner/`
```
<key>com.apple.security.network.client</key>
<true/>
```

For more details, please take a look at https://flutter.dev/desktop#setting-up-entitlements

### Can't connect socket server on Flutter with Insecure HTTP connection
* Refer to https://flutter.dev/docs/release/breaking-changes/network-policy-ios-android

The HTTP connections are disabled by default on iOS and Android, so here is a workaround to this issue,
which mentioned on [stack overflow](https://stackoverflow.com/a/65730723)


## Notes to Contributors

### Fork socket.io-client-dart

If you'd like to contribute back to the core, you can [fork this repository](https://help.github.com/articles/fork-a-repo) and send us a pull request, when it is ready.

If you are new to Git or GitHub, please read [this guide](https://help.github.com/) first.

## Who Uses

- [Quire](https://quire.io) - a simple, collaborative, multi-level task management tool.
- [KEIKAI](https://keikai.io/) - a web spreadsheet for Big Data.

## Socket.io Dart Server

- [socket.io-dart](https://github.com/rikulo/socket.io-dart)

## Contributors

- Thanks [@felangel](https://github.com/felangel) for https://github.com/rikulo/socket.io-client-dart/issues/7
- Thanks [@Oskang09](https://github.com/Oskang09) for https://github.com/rikulo/socket.io-client-dart/issues/21
- Thanks [@bruce3x](https://github.com/bruce3x) for https://github.com/rikulo/socket.io-client-dart/issues/25
- Thanks [@Kavantix](https://github.com/Kavantix) for https://github.com/rikulo/socket.io-client-dart/issues/26
- Thanks [@luandnguyen](https://github.com/luandnguyen) for https://github.com/rikulo/socket.io-client-dart/issues/59
- Thanks [@jorgefspereira](https://github.com/jorgefspereira) for https://github.com/rikulo/socket.io-client-dart/pull/177
- Thanks [@fzyzcjy](https://github.com/fzyzcjy) for https://github.com/rikulo/socket.io-client-dart/pull/188
- Thanks [@darwin-morocho](https://github.com/darwin-morocho) for https://github.com/rikulo/socket.io-client-dart/pull/189
- Thanks [@chatziko](https://github.com/chatziko) for https://github.com/rikulo/socket.io-client-dart/pull/237
- Thanks [@Astray-git](https://github.com/Astray-git) for https://github.com/rikulo/socket.io-client-dart/pull/313
- Thanks [@Astray-git](https://github.com/Astray-git) for https://github.com/rikulo/socket.io-client-dart/pull/310

[![pub package](https://img.shields.io/pub/v/dds.svg)](https://pub.dev/packages/dds)
[![package publisher](https://img.shields.io/pub/publisher/dds.svg)](https://pub.dev/packages/dds/publisher)

A package used to spawn the Dart Developer Service (DDS), which is used to communicate with a Dart VM Service instance and provide extended functionality to the core VM Service Protocol.

# Functionality

Existing VM Service clients can issue both HTTP, websocket, and SSE requests to a running DDS instance as if it were an instance of the VM Service itself. If a request corresponds to an RPC defined in the [VM Service Protocol][service-protocol], DDS will forward the request and return the response from the VM Service. Requests corresponding to an RPC defined in the [DDS Protocol][dds-protocol] will be handled directly by the DDS instance.

# SSE Support

For certain web clients it may be preferrable or required to communicate with DDS using server-sent events (SSE). DDS has a SSE handler listening for requests on `/$debugHandler`.

## SSE and package:vm_service example

```dart
import 'package:sse/sse.dart';
import 'package:vm_service/vm_service.dart';

void main() {
  // Establish connection with DDS using SSE.
  final ddsChannel = SseClient('${ddsUri}\$debugHandler');

  // Wait for ddsChannel to be established
  await ddsChannel.onOpen.first;

  // Initialize VmService using the sink and stream from ddsChannel.
  final vmService = VmService(
    ddsChannel.stream,
    (e) => ddsChannel.sink.add(e),
  );

  // You're ready to query DDS and the VM service!
  print(await vmService.getVersion());
}
```

[dds-protocol]: dds_protocol.md
[service-protocol]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md

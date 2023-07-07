This package exposes the `StreamChannel` interface, which represents a two-way
communication channel. Each `StreamChannel` exposes a `Stream` for receiving
data and a `StreamSink` for sending it. 

`StreamChannel` helps abstract communication logic away from the underlying
protocol. For example, the [`test`][test] package re-uses its test suite
communication protocol for both WebSocket connections to browser suites and
Isolate connections to VM tests.

[test]: https://pub.dev/packages/test

This package also contains utilities for dealing with `StreamChannel`s and with
two-way communications in general. For documentation of these utilities, see
[the API docs][api].

[api]: https://pub.dev/documentation/stream_channel/latest/

## 4.1.0

- Limit the number of concurrent requests to prevent Chrome from automatically
  dropping them on the floor.

## 4.0.0

- Support null safety.

## 3.8.3

- Require the latest shelf and remove dead code.

## 3.8.2

- Complete `onConnected` with an error if the `SseClient` receives an error
  before the connection is successfully opened.

## 3.8.1

- Fix an issue where closing the `SseConnection` stream would result in
  an error.

## 3.8.0

- Add `onConnected` to replace `onOpen`.
- Fix an issue where failed requests would not add a `done` event to the
  connection `sink`.

## 3.7.0

- Deprecate the client's `onOpen` getter. Messages will now be buffered until
  a connection is established.

## 3.6.1

- Drop dependency on `package:uuid`.

## 3.6.0

- Improve performance by buffering out of order messages in the server instead
  of the client.

** Note ** This is not modelled as a breaking change as the server can handle
messages from older clients. However, clients should be using the latest server
if they require order guarantees.


## 3.5.0

- Add new `shutdown` methods on `SseHandler` and `SseConnection` to allow closing
  connections immediately, ignoring any keep-alive periods.

## 3.4.0

- Remove `onClose` from `SseConnection` and ensure the corresponding
  `sink.close` correctly fires.

## 3.3.0

- Add an `onClose` event to the `SseConnection`. This allows consumers to
  listen to this event in lue of `sseConnection.sink.done` as that is not
  guaranteed to fire.

## 3.2.2

- Fix an issue where `keepAlive` may cause state errors when attempting to
  send messages on a closed stream.

## 3.2.1

- Fix an issue where `keepAlive` would only allow a single reconnection.

## 3.2.0

- Re-expose `isInKeepAlivePeriod` flag on `SseConnection`. This flag will be
  `true` when a connection has been dropped and is in the keep-alive period
  waiting for a client to reconnect.

## 3.1.2

- Fix an issue where the `SseClient` would not send a `done` event when there
  was an error with the SSE connection.

## 3.1.1

- Make `isInKeepAlive` on `SseConnection` private.

**Note that this is a breaking change but in actuality no one should be
  depending on this API.**

## 3.1.0

- Add optional `keepAlive` parameter to the `SseHandler`. If `keepAlive` is
  supplied, the connection will remain active for this period after a
  disconnect and can be reconnected transparently. If there is no reconnect
  within that period, the connection will be closed normally.

## 3.0.0

- Add retry logic.

**Possible Breaking Change Error messages may now be delayed up to 5 seconds
  in the client.**

## 2.1.2

- Remove `package:http` dependency.

## 2.1.1

- Use proper headers delimiter.

## 2.1.0

- Support Firefox.

## 2.0.3

- Fix an issue where messages could come out of order.

## 2.0.2

- Support the latest `package:stream_channel`.
- Require Dart SDK `>=2.1.0 <3.0.0`.

## 2.0.1

- Update to `package:uuid` version 2.0.

## 2.0.0

- No longer expose `close` and `onClose` on an `SseConnection`. This is simply
  handled by the underlying `stream` / `sink`.
- Fix a bug where resources of the `SseConnection` were not properly closed.

## 1.0.0

- Internal cleanup.


## 0.0.1

- Initial commit.

## 2.0.2

**Bug fix:**

* [#330](https://github.com/rikulo/socket.io-client-dart/issues/330) Client throws error when buffer is received

## 2.0.1

**New Feature:**

* [#310](https://github.com/rikulo/socket.io-client-dart/pull/310) Add setAuthFn for OptionBuilder

**Bug fix:**

* [#287](https://github.com/rikulo/socket.io-client-dart/issues/287) reconnecting event is not triggered

## 2.0.0

**New Feature:**

* [#237](https://github.com/rikulo/socket.io-client-dart/pull/237) Allow sending an ack with multiple data items (making it consistent with emit)

## 1.0.2

**New Feature:**

* [#237](https://github.com/rikulo/socket.io-client-dart/pull/237) Allow sending an ack with multiple data items (making it consistent with emit)

## 1.0.1

**Bug fix:**

* [#188](https://github.com/rikulo/socket.io-client-dart/pull/188) Fixbug for Backoff when many attempts: "UnsupportedError: Unsupported operation: Infinity or NaN toInt"

## 2.0.0-beta.4-nullsafety.0

**New Feature:**

* [#177](https://github.com/rikulo/socket.io-client-dart/pull/177) Send credentials with the auth option

**Bug fix:**

* [#172](https://github.com/rikulo/socket.io-client-dart/issues/172) socket id's not synced

## 2.0.0-beta.3-nullsafety.0

**New Feature:**

* [#163](https://github.com/rikulo/socket.io-client-dart/issues/163) Null safety support for 2.0.0-beta

## 2.0.0-beta.3

**Bug fix:**

* [#150](https://github.com/rikulo/socket.io-client-dart/issues/150) Problem with setQuery in socket io version 3.0

## 2.0.0-beta.2

**Bug fix:**

* [#140](https://github.com/rikulo/socket.io-client-dart/issues/140) getting Error on emitWithAck() in v2 beta

## 2.0.0-beta.1

**New Feature:**

* [#130](https://github.com/rikulo/socket.io-client-dart/issues/130) Cannot connect to socket.io V3
* [#106](https://github.com/rikulo/socket.io-client-dart/issues/106) Can we combine emitWithBinary to emit?

## 1.0.0

* [#172](https://github.com/rikulo/socket.io-client-dart/issues/172) socket id's not synced

## 2.0.0-beta.3-nullsafety.0

**New Feature:**

* [#163](https://github.com/rikulo/socket.io-client-dart/issues/163) Null safety support for 2.0.0-beta

## 2.0.0-beta.3

**Bug fix:**

* [#150](https://github.com/rikulo/socket.io-client-dart/issues/150) Problem with setQuery in socket io version 3.0

## 2.0.0-beta.2

**Bug fix:**

* [#140](https://github.com/rikulo/socket.io-client-dart/issues/140) getting Error on emitWithAck() in v2 beta

## 2.0.0-beta.1

**New Feature:**

* [#130](https://github.com/rikulo/socket.io-client-dart/issues/130) Cannot connect to socket.io V3
* [#106](https://github.com/rikulo/socket.io-client-dart/issues/106) Can we combine emitWithBinary to emit?


**New Feature:**

* [#132](https://github.com/rikulo/socket.io-client-dart/issues/132) Migrating to null safety for Dart

## 0.9.12

**New Feature:**

* [#46](https://github.com/rikulo/socket.io-client-dart/issues/46) Make this library more "Darty"

## 0.9.11

**New Feature:**

* [#108](https://github.com/rikulo/socket.io-client-dart/issues/108) Need dispose method for clearing resources

## 0.9.10+2

* Fix dart analyzer warning for formatting issues.

## 0.9.10+1

* Fix dart analyzer warning.

## 0.9.10

**Bug fix:**

* [#72](https://github.com/rikulo/socket.io-client-dart/issues/72) Can't send Iterable as one packet

## 0.9.9

**Bug fix:**

* [#67](https://github.com/rikulo/socket.io-client-dart/issues/67) Retry connection backoff after 54 tries reconnections every 0 second

## 0.9.8

**Bug fix:**

* [#33](https://github.com/rikulo/socket.io-client-dart/issues/33) socket.on('receiveMessage',(data)=>print("data")) called twice


## 0.9.7+2

**New Feature:**

* [#48](https://github.com/rikulo/socket.io-client-dart/issues/48) add links to github repo in pubspec.yaml


## 0.9.7+1

**New Feature:**

* [#38](https://github.com/rikulo/socket.io-client-dart/issues/38) Improve pub.dev score


## 0.9.6+3

**Bug fix:**

* [#42](https://github.com/rikulo/socket.io-client-dart/issues/42) Error when using emitWithAck

## 0.9.5

**New Feature:**

* [#34](https://github.com/rikulo/socket.io-client-dart/issues/34) Add support for extraHeaders

**Bug fix:**

* [#39](https://github.com/rikulo/socket.io-client-dart/issues/39) The factor of Backoff with 54 retries causes an overflow

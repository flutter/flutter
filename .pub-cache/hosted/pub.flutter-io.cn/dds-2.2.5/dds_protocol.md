# Dart Development Service Protocol 1.3

This document describes _version 1.3_ of the Dart Development Service Protocol.
This protocol is an extension of the Dart VM Service Protocol and implements it
in it's entirety. For details on the VM Service Protocol, see the [Dart VM Service Protocol Specification][service-protocol].

The Service Protocol uses [JSON-RPC 2.0][].

[JSON-RPC 2.0]: http://www.jsonrpc.org/specification

## Table of Contents

- [RPCs, Requests, and Responses](#rpcs-requests-and-responses)
- [Events](#events)
- [Types](#types)
- [IDs and Names](#ids-and-names)
- [Revision History](#revision-history)
- [Public RPCs](#public-rpcs)
  - [getAvailableCachedCpuSamples](#getavailablecachedcpusamples)
  - [getCachedCpuSamples](#getcachedcpusamples)[
  - [getClientName](#getclientname)
  - [getDartDevelopmentServiceVersion](#getdartdevelopmentserviceversion)
  - [getLogHistorySize](#getloghistorysize)
  - [getStreamHistory](#getstreamhistory)[
  - [requirePermissionToResume](#requirepermissiontoresume)
  - [setClientName](#setclientname)
  - [setLogHistorySize](#setloghistorysize)
- [Public Types](#public-types)
  - [AvailableCachedCpuSamples](#availablecachedcpusamples)[
  - [CachedCpuSamples](#cachedcpusamples)
  - [ClientName](#clientname)
  - [DartDevelopmentServiceVersion](#dartdevelopmentserviceversion)
  - [Size](#size)
  - [StreamHistory](#streamhistory)[

## RPCs, Requests, and Responses

See the corresponding section in the VM Service protocol [here][service-protocol-rpcs-requests-and-responses].

## Events

See the corresponding section in the VM Service protocol [here][service-protocol-events].

## Binary Events

See the corresponding section in the VM Service protocol [here][service-protocol-binary-events].

## Types

See the corresponding section in the VM Service protocol [here][service-protocol-types].

## IDs and Names

See the corresponding section in the VM Service protocol [here][service-protocol-ids-and-names].

## Streams

For a list of core VM service streams, see [streamListen][service-protocol-streams].

DDS will keep a history of events on certain streams and send historical events
when a client first subscribes to a stream with history. These streams currently
consist of the following:

- `Logging`
- `Stdout`
- `Stderr`
- `Extension`

In addition, subscribing to the `Service` stream will result in a `ServiceRegistered`
event being sent to the subscribing client for each existing service extension.

## Public RPCs

The DDS Protocol supports all [public RPCs defined in the VM Service protocol][service-protocol-public-rpcs].

### getAvailableCachedCpuSamples

```
AvailableCachedCpuSamples getAvailableCachedCpuSamples();
```

The _getAvailableCachedCpuSamples_ RPC is used to determine which caches of CPU samples
are available. Caches are associated with individual _UserTag_ names and are specified
when DDS is started via the _cachedUserTags_ parameter.

See [AvailableCachedCpuSamples](#availablecachedcpusamples).

### getCachedCpuSamples

```
CachedCpuSamples getCachedCpuSamples(string isolateId, string userTag);
```

The _getCachedCpuSamples_ RPC is used to retrieve a cache of CPU samples collected
under a _UserTag_ with name _userTag_.

See [CachedCpuSamples](#cachedcpusamples).

### getClientName

```
ClientName getClientName()
```

The _getClientName_ RPC is used to retrieve the name associated with the currently
connected VM service client. If no name was previously set through the
[setClientName](#setclientname) RPC, a default name will be returned.

See [ClientName](#clientname)

### getDartDevelopmentServiceVersion

```
Version getDartDevelopmentServiceVersion()
```

The _getDartDevelopmentServiceVersion_ RPC is used to determine what version of
the Dart Development Service Protocol is served by a DDS instance.

See [Version](#version).


### getLogHistorySize

```
Size getLogHistorySize()
```

The _getLogHistorySize_ RPC is used to retrieve the current size of the log
history buffer. If the returned [Size](#size) is zero, then log history is
disabled.

See [Size](#size).


### getStreamHistory

```
StreamHistory getStreamHistory(string streamId)
```

The _getStreamHistory_ RPC is used to retrieve historical events for streams
which support event history (see [Streams](#streams) for a list of supported
streams).

See [StreamHistory](#streamhistory).

### requirePermissionToResume

```
Success requirePermissionToResume(bool onPauseStart [optional],
                                  bool onPauseReload[optional],
                                  bool onPauseExit [optional])
```

The _requirePermissionToResume_ RPC is used to change the pause/resume behavior
of isolates by providing a way for the VM service to wait for approval to resume
from some set of clients. This is useful for clients which want to perform some
operation on an isolate after a pause without it being resumed by another client.

If the _onPauseStart_ parameter is `true`, isolates will not resume after pausing
on start until the client sends a `resume` request and all other clients which
need to provide resume approval for this pause type have done so.

If the _onPauseReload_ parameter is `true`, isolates will not resume after pausing
after a reload until the client sends a `resume` request and all other clients
which need to provide resume approval for this pause type have done so.

If the _onPauseExit_ parameter is `true`, isolates will not resume after pausing
on exit until the client sends a `resume` request and all other clients which
need to provide resume approval for this pause type have done so.

**Important Notes:**

- All clients with the same client name share resume permissions. Only a
  single client of a given name is required to provide resume approval.
- When a client requiring approval disconnects from the service, a paused
  isolate may resume if all other clients requiring resume approval have
  already given approval. In the case that no other client requires resume
  approval for the current pause event, the isolate will be resumed if at
  least one other client has attempted to [resume](resume) the isolate.

### setClientName

```
Success setClientName(string name)
```

The _setClientName_ RPC is used to set a name to be associated with the currently
connected VM service client. If the _name_ parameter is a non-empty string, _name_
will become the new name associated with the client. If _name_ is an empty string,
the client's name will be reset to its default name.

See [Success](#success).

### setLogHistorySize

```
Success setLogHistorySize(int size)
```

The _setLogHistorySize_ RPC is used to set the size of the ring buffer used for
caching a limited set of historical log messages. If _size_ is 0, logging history
will be disabled. The maximum history size is 100,000 messages, with the default
set to 10,000 messages.

See [Success](#success).

## Public Types

The DDS Protocol supports all [public types defined in the VM Service protocol][service-protocol-public-types].

### AvailableCachedCpuSamples

```
class AvailableCachedCpuSamples extends Response {
  // A list of UserTag names associated with CPU sample caches.
  string[] cacheNames;
}
```

A collection of [UserTag] names associated with caches of CPU samples.

See [getAvailableCachedCpuSamples](#getavailablecachedcpusamples).

### CachedCpuSamples

```
class CachedCpuSamples extends CpuSamples {
  // The name of the UserTag associated with this cache of samples.
  string userTag;

  // Provided if the CPU sample cache has filled and older samples have been
  // dropped.
  bool truncated [optional];
}
```

An extension of [CpuSamples](#cpu-samples) which represents a set of cached
samples, associated with a particular [UserTag] name.

See [getCachedCpuSamples](#getcachedcpusamples).

### ClientName

```
class ClientName extends Response {
  // The name of the currently connected VM service client.
  string name;
}
```

See [getClientName](#getclientname) and [setClientName](#setclientname).

### Size

```
class Size extends Response {
  int size;
}
```

A simple object representing a size response.

### StreamHistory

```
class StreamHistory extends Response {
  // A list of historical Events for a stream.
  List<Event> history;
}
```

See [getStreamHistory](#getStreamHistory).

## Revision History

version | comments
------- | --------
1.0 | Initial revision
1.1 | Added `getDartDevelopmentServiceVersion` RPC.
1.2 | Added `getStreamHistory` RPC.
1.3 | Added `getAvailableCachedCpuSamples` and `getCachedCpuSamples` RPCs.

[resume]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#resume
[success]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#success
[version]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#version
[cpu-samples]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#cpusamples

[service-protocol]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md
[service-protocol-rpcs-requests-and-responses]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#rpcs-requests-and-responses
[service-protocol-events]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#events
[service-protocol-streams]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#streamlisten
[service-protocol-binary-events]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#binary-events
[service-protocol-types]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#types
[service-protocol-ids-and-names]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#ids-and-names
[service-protocol-public-rpcs]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#public-rpcs
[service-protocol-public-types]: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md#public-types

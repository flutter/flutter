# Flutter Daemon

## Overview

The `flutter` command-line tool supports a daemon server mode for use by IDEs and other tools.

```
flutter daemon
```

It runs a persistent, JSON-RPC based server to communicate with devices. IDEs and other tools can start the flutter tool in this mode and get device addition and removal notifications, as well as being able to programmatically start and stop apps on those devices.

A set of `flutter daemon` commands/events are also exposed via `flutter run --machine` and `flutter attach --machine` which allow IDEs and tools to launch and attach to flutter applications and interact to send commands like Hot Reload. The command and events that are available in these modes are documented at the bottom of this document.

## Protocol

The daemon speaks [JSON-RPC](http://json-rpc.org/) to clients. It uses stdin and stdout as the protocol transport. To send a command to the server, create your command as a JSON-RPC message, encode it to json, surround the encoded text with square brackets, and write it as one line of text to the stdin of the process:

```
[{"method":"daemon.version","id":0}]
```

The response will come back as a single line from stdout:

```
[{"id":0,"result":"0.1.0"}]
```

All requests and responses should be wrapped in square brackets. This ensures that the communications are resilient to stray output in the stdout/stdin stream.

`id` is an opaque type to the server, but ids should be unique for the life of the server. A response to a particular command will contain the id that was passed in for that command.

Each command should have a `method` field. This is in the form '`domain.command`'.

Any params for that command should be passed in through a `params` field. Here's a example request/response for the `device.getDevices` method:

```
[{"method":"device.getDevices","id":2}]
```

```
[{"id":2,"result":[{"id":"702ABC1F-5EA5-4F83-84AB-6380CA91D39A","name":"iPhone 6","platform":"ios_x64","available":true}]}]
```

## Domains and Commands

### daemon domain

#### daemon.version

The `version()` command responds with a String with the protocol version.

#### daemon.shutdown

The `shutdown()` command will terminate the flutter daemon. It is not necessary to call this before shutting down the daemon; it is perfectly acceptable to just kill the daemon process.

#### Events

#### daemon.connected

The `daemon.connected` event is sent when the daemon starts. The `params` field will be a map with the following fields:

- `version`: The protocol version. This is the same version returned by the `version()` command.
- `pid`: The `pid` of the daemon process.

#### daemon.logMessage

The `daemon.logMessage` event is sent whenever a log message is created - either a status level message or an error. The JSON message will contain an `event` field with the value `daemon.logMessage`, and an `params` field containing a map with `level`, `message`, and (optionally) `stackTrace` fields.


#### daemon.showMessage

The `daemon.showMessage` event is sent by the daemon when some if would be useful to show a message to the user. This could be an error notification or a notification that some development tools are not configured or not installed. The JSON message will contain an `event` field with the value `daemon.showMessage`, and an `params` field containing a map with `level`, `title`, and `message` fields. The valid options for `level` are `info`, `warning`, and `error`.

It is up to the client to decide how best to display the message; for some clients, it may map well to a toast style notification. There is an implicit contract that the daemon will not send too many messages over some reasonable period of time.

### app domain

#### app.restart

The `restart()` restarts the given application. It returns a Map of `{ int code, String message, String hintMessage, String hintId }` to indicate success or failure in restarting the app. A `code` of `0` indicates success, and non-zero indicates a failure. If `hintId` is non-null and equal to `restartRecommended`, that indicates that the reload was successful, but not all reloaded elements were executed during view reassembly (i.e., the user might not see all the changes in the current UI, and a restart could be necessary).

- `appId`: the id of a previously started app; this is required.
- `fullRestart`: optional; whether to do a full (rather than an incremental) restart of the application
- `reason`: optional; the reason for the full restart (eg. `save`, `manual`) for reporting purposes
- `pause`: optional; when doing a hot restart the isolate should enter a paused mode

#### app.callServiceExtension

The `callServiceExtension()` allows clients to make arbitrary calls to service protocol extensions. It returns a `Map` - the result returned by the service protocol method.

- `appId`: the id of a previously started app; this is required.
- `methodName`: the name of the service protocol extension to invoke; this is required.
- `params`: an optional Map of parameters to pass to the service protocol extension.

#### app.detach

The `detach()` command takes one parameter, `appId`. It returns a `bool` to indicate success or failure in detaching from an app without stopping it.

- `appId`: the id of a previously started app; this is required.

#### app.stop

The `stop()` command takes one parameter, `appId`. It returns a `bool` to indicate success or failure in stopping an app.

- `appId`: the id of a previously started app; this is required.

#### Events

#### app.start

This is sent when an app is starting. The `params` field will be a map with the fields `appId`, `directory`, and `deviceId`.

#### app.debugPort

This is sent when an observatory port is available for a started app. The `params` field will be a map with the fields `appId`, `port`, and `wsUri`. Clients should prefer using the `wsUri` field in preference to synthesizing a uri using the `port` field. An optional field, `baseUri`, is populated if a path prefix is required for setting breakpoints on the target device.

#### app.started

This is sent once the application launch process is complete and the app is either paused before main() (if `startPaused` is true) or main() has begun running. When attaching, this even will be fired once attached. The `params` field will be a map containing the field `appId`.

#### app.log

This is sent when output is logged for a running application. The `params` field will be a map with the fields `appId` and `log`. The `log` field is a string with the output text. If the output indicates an error, an `error` boolean field will be present, and set to `true`.

#### app.progress

This is sent when an operation starts and again when it stops. When an operation starts, the event contains the fields `id`, an opaque identifier, and `message` containing text describing the operation. When that same operation ends, the event contains the same `id` field value as when the operation started, along with a `finished` bool field with the value true, but no `message` field.

#### app.stop

This is sent when an app is stopped or detached from. The `params` field will be a map with the field `appId`.

### device domain

#### device.getDevices

Return a list of all connected devices. The `params` field will be a List; each item is a map with the fields `id`, `name`, `platform`, and `emulator` (a boolean).

#### device.enable

Turn on device polling. This will poll for newly connected devices, and fire `device.added` and `device.removed` events.

#### device.disable

Turn off device polling.

#### device.forward

Forward a host port to a device port. This call takes two required arguments, `deviceId` and `devicePort`, and one optional argument, `hostPort`. If `hostPort` is not specified, the host port will be any available port.

This method returns a map with a `hostPort` field set.

#### device.unforward

Removed a forwarded port. It takes `deviceId`, `devicePort`, and `hostPort` as required arguments.

#### Events

#### device.added

This is sent when a device is connected (and polling has been enabled via `enable()`). The `params` field will be a map with the fields `id`, `name`, `platform`, and `emulator`.

#### device.removed

This is sent when a device is disconnected (and polling has been enabled via `enable()`). The `params` field will be a map with the fields `id`, `name`, `platform`, and `emulator`.

### emulator domain

#### emulator.getEmulators

Return a list of all available emulators. The `params` field will be a List; each item is a map with the fields `id` and `name`.

#### emulator.launch

The `launch()` command allows launching an emulator/simulator by its `id`.

- `emulatorId`: the id of an emulator as returned by `getEmulators`.

#### emulator.create

The `create()` command creates a new Android emulator with an optional `name`.

- `name`: an optional name for this emulator

The returned `params` will contain:

- `success` - whether the emulator was successfully created
- `emulatorName` - the name of the emulator created; this will have been auto-generated if you did not supply one
- `error` - when `success`=`false`, a message explaining why the creation of the emulator failed

## 'flutter run --machine' and 'flutter attach --machine'

When running `flutter run --machine` or `flutter attach --machine` the following subset of the daemon is available:

### daemon domain

The following subset of the daemon domain is available in `flutter run --machine`. Refer to the documentation above for details.

- Commands
  - [`version`](#daemonversion)
  - [`shutdown`](#daemonshutdown)
- Events
  - [`connected`](#daemonconnected)
  - [`logMessage`](#daemonlogmessage)

### app domain

The following subset of the app domain is available in `flutter run --machine`. Refer to the documentation above for details.

- Commands
  - [`restart`](#apprestart)
  - [`callServiceExtension`](#appcallserviceextension)
  - [`detach`](#appdetach)
  - [`stop`](#appstop)
- Events
  - [`start`](#appstart)
  - [`debugPort`](#appdebugport)
  - [`started`](#appstarted)
  - [`log`](#applog)
  - [`progress`](#appprogress)
  - [`stop`](#appstop)

## Source

See the [source](https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/commands/daemon.dart) for the daemon protocol and implementation.

## Changelog

- 0.4.2: Added `app.detach` command
- 0.4.1: Added `flutter attach --machine`
- 0.4.0: Added `emulator.create` command
- 0.3.0: Added `daemon.connected` event at startup

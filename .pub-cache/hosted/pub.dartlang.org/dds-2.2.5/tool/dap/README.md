# Debug Adapter Protocol

Dart includes support for debugging using [the Debug Adapter Protocol](https://microsoft.github.io/debug-adapter-protocol/) as an alternative to using the [VM Service](https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md) directly, simplying the integration for new editors.

The debug adapters are started with the `dart debug_adapter` command and are intended to be consumed by DAP-compliant tools such as Dart-specific extensions for editors, or configured by users whose editors include generic configurable DAP clients.

Two adapters are available:

- `dart debug_adapter`
- `dart debug_adapter --test`

The standard adapter will run scripts using `dart` while the `--test` adapter will cause scripts to be run using `dart test` and will emit custom `dart.testNotification` events (described below).

Because in the DAP protocol the client speaks first, running this command from the terminal will result in no output (nor will the process terminate). This is expected behaviour.

For details on the standard DAP functionality, see [the Debug Adapter Protocol Overview](https://microsoft.github.io/debug-adapter-protocol/) and [the Debug Adapter Protocol Specification](https://microsoft.github.io/debug-adapter-protocol/specification). Custom extensions are detailed below.

**Flutter**: Flutter apps should be run using the debug adapter in the `flutter` tool - [see this document](https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/debug_adapters/README.md).

## Launch/Attach Arguments

Arguments common to both `launchRequest` and `attachRequest` are:

- `bool? debugExternalPackageLibraries` - whether to enable debugging for packages that are not inside the current workspace
- `bool? debugSdkLibraries` - whether to enable debugging for SDK libraries
- `bool? evaluateGettersInDebugViews` - whether to evaluate getters in expression evaluation requests (inc. hovers/watch windows)
- `bool? evaluateToStringInDebugViews` - whether to invoke `toString()` in expression evaluation requests (inc. hovers/watch windows)
- `bool? sendLogsToClient` - used to proxy all VM Service traffic back to the client in custom `dart.log` events (has performance implications, intended for troubleshooting)
- `int? vmServicePort` - the port to bind the VM Service too
- `List<String>? additionalProjectPaths` - paths of any projects (outside of `cwd`) that are open in the users workspace
- `String? cwd` - the working directory for the Dart process to be spawned in
- `Map<String, String>? env` - environment variables to be passed to any spawned process

Arguments specific to `launchRequest` are:

- `bool? noDebug` - whether to run in debug or noDebug mode (if not supplied, defaults to debug)
- `String program` - the path of the Dart program to run
- `List<String>? args` - arguments to be passed to the Dart program (after the `program` on the command line)
- `List<String>? toolArgs` - arguments passed after the tool that will run `program` (after `dart` for CLI scripts and after `dart run test:test` for test scripts)
- `List<String>? vmAdditionalArgs` - arguments passed directly to the Dart VM (after `dart` for both CLI scripts and test scripts)
- `String? console` - if set to `"terminal"` or `"externalTerminal"` will be run using the `runInTerminal` reverse-request; otherwise the debug adapter spawns the Dart process
- `String? customTool` - an optional tool to run instead of `dart` - the custom tool must be completely compatible with the tool/command it is replacing
- `int? customToolReplacesArgs` - the number of arguments to delete from the beginning of the argument list when invoking `customTool` - e.g. setting `customTool` to `dart_test` and
  `customToolReplacesArgs` to `2` for a test run would invoke `dart_test foo_test.dart` instead of `dart run test:test foo_test.dart` (if larger than the number of computed arguments all arguments will be removed, if not supplied will default to `0`)

Arguments specific to `attachRequest` are:

- `String vmServiceInfoFile` - the file to read the VM Service info from \*
- `String vmServiceInfoFile` - the VM Service URI to attach to \*

\* Exactly one of `vmServiceInfoFile` or `vmServiceInfoFile` should be supplied.

## Custom Requests

Some custom requests are available for clients to call.

### `updateDebugOptions`

`updateDebugOptions` allows updating some debug options usually provided at launch/attach while the session is running. Any keys included in the request will overwrite the previously set values. To update only some values, include only those in the parameters.

```
{
	"debugSdkLibraries": true
	"debugExternalPackageLibraries": false
}
```

### `callService`

`callService` allows calling arbitrary services (for example service extensions that have been registered). The service RPC/method should be sent in the `method` field and `params` will depend on the service being called.

```
{
	"method": "myFooService",
	"params": {
		// ...
	}
}
```

### `hotReload`

`hotReload` calls the VM's `reloadSources` service for each active isolate, reloading all modified source files.

```
{
	"method": "hotReload",
	"params": null
}
```

## Custom Events

The debug adapter may emit several custom events that are useful to clients.

### `dart.debuggerUris`

When running in debug mode, a `dart.debuggerUris` event will be emitted containing the URI of the VM Service.

```
{
	"type": "event",
	"event": "dart.debuggerUris",
	"body": {
		"vmServiceUri": "ws://127.0.0.1:123/abdef123="
	}
}
```

### `dart.log`

When `sendLogsToClient` in the launch/attach arguments is `true`, debug logging and all traffic to the VM Service will be proxied back to the client in `dart.log` events to aid troubleshooting.

```
{
	"type": "event",
	"event": "dart.log",
	"body": {
		"message": "<log message or json string>"
	}
}
```

### `dart.serviceRegistered`

Emitted when a VM Service is registered.

```
{
	"type": "event",
	"event": "dart.serviceRegistered",
	"body": {
		"service": "ServiceName",
		"method": "methodName"
	}
}
```

### `dart.serviceUnregistered`

Emitted when a VM Service is unregistered.

```
{
	"type": "event",
	"event": "dart.serviceUnregistered",
	"body": {
		"service": "ServiceName",
		"method": "methodName"
	}
}
```

### `dart.serviceExtensionAdded`

Emitted when a VM Service Extension is added.

```
{
	"type": "event",
	"event": "dart.serviceExtensionAdded",
	"body": {
		"extensionRPC": "<extensionRPC to call>",
		"isolateId": "<isolateId>"
	}
}
```

### `dart.testNotification`

When running the `--test` debug adapter, `package:test` JSON messages will be passed back to the client in a `dart.testNotification` event. For details on this protocol, see the [package:test documentation](https://github.com/dart-lang/test/blob/master/pkgs/test/doc/json_reporter.md).

```
{
	"type": "event",
	"event": "dart.testNotification",
	"body": {
		"type": "testStart",
		"test": {
			"id": 1,
			"name": "my test name",
			// ...
		}
	}
}
```


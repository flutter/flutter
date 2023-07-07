## 1.1.0

- Have `ChromeConnection.getTabs` return better exceptions where there's a
  failure setting up the Chrome connection (#85).
- Introduce a new, optional `retryFor` parameter to `ChromeConnection.getTabs`.
  This will re-try failed connections for a period of time; it can be useful to
  mitigate some intermittent connection issues very early in Chrome's startup.

## 1.0.1
- Use `package:lints` for analysis.
- Populate the pubspec `repository` field.
- Enable the `avoid_dynamic_calls` lint.

## 1.0.0
- Migrate to null safety.

## 0.7.5
- Allow the latest `logging` package.

## 0.7.4
- Support `params` to `stepInto` and `stepOver`. 

## 0.7.3
- Fix a type issue with `GlobalObjectClearedEvent`s 

## 0.7.2
- Fix a bug in `StackTrace.parent`

## 0.7.1
- Exposed `Debugger.setAsyncCallStackDepth`
- Exposed `StackTrace.parent`

## 0.7.0
- Normalized all objects to expose a `json` field for raw access to the protocol information
- Exposed `Runtime.getProperties`, `Runtime.getHeapUsage`, and `Runtime.getIsolateId`
- Exposed `DebuggerPausedEvent.hitBreakpoints` and `DebuggerPausedEvent.asyncStackTrace`
- Exposed `WipCallFrame.returnValue`
- Removed `WrappedWipEvent` (in favor of just using `WipEvent`)
- Removed `WipRemoteObject` (in favor of just using `RemoteObject`)

## 0.6.0
- Add `onSend` and `onReceive` in `WipConnection` 
- Expose `onExecutionContextCreated`, `onExecutionContextDestroyed`,
  and `onExecutionContextsCleared` on WipRuntime

## 0.5.3
- expose `name` in `WipScope`

## 0.5.2
- have `ExceptionDetails` and `WipError` implement `Exception`
- add `code` and `message` getters to `WipError`

## 0.5.1
- add `Runtime.evaluate`
- add `Debugger.setBreakpoint`
- add `Debugger.removeBreakpoint`
- add `Debugger.evaluateOnCallFrame`
- add `Debugger.getPossibleBreakpoints`

## 0.5.0+1
- fixed a bug in reading type of `WipScope`

## 0.5.0
- removed the bin/multiplex.dart binary to the example/ directory
- remove dependencies on `package:args`, package:shelf`, and `package:shelf_web_socket`

## 0.4.2
- Cast `HttpClientResponse` to `Stream<List<int>>` in response to
  SDK breaking change.

## 0.4.1
- Fix `page.reload` method.
- Disable implicit casts when developing this package.

## 0.4.0
- Change the `RemoteObject.value` return type to `Object`.

## 0.3.6
- Expose the `target` domain and additional `runtime` domain calls

## 0.3.5
- Widen the Dart SDK constraint

## 0.3.4
- Several fixes for strong mode at runtime issues
- Rename uses of deprecated dart:io constants

## 0.3.3
- Upgrade the Dart SDK minimum to 2.0.0-dev
- Rename uses of deprecated dart:convert constants

## 0.3.2
- Analysis fixes for strong mode
- Upgrade to the latest package dependencies

## 0.3.1
- Expose `ConsoleAPIEvent.timestamp`
- Expose `LogEntry.timestamp`

## 0.3.0
- Expose the `runtime` domain.
- Expose the `log` domain.
- Deprecated the `console` domain.
- Fix a bug in `Page.reload()`.
- Remove the use of parts.

## 0.2.2
- Make the package strong mode clean.

## 0.2.1+1

## 0.0.1

- Initial version (library moved out of the `grinder` package).

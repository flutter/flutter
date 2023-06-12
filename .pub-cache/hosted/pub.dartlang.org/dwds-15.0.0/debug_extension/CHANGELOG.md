
## 1.30
- Batch extension `Debugger.scriptParsed` events and send batches every 1000ms
  to the server.
- Enable null-safety.
  
## 1.29

- Notify the debugger and inspector panels when the debug session is disconnected.
- Provide a detailed error message when the debugger fails to connect.
- Send an event to the server when the debugger is detached.
- Fix compilation errors when the extension is built with DDC.

## 1.28

- Support Chrome 100 updates to the remote debugging protocol.

## 1.27

- Support embedded debugger and inspector in Chrome DevTools for Flutter Web apps. 

## 1.26

- Support embedded debugging experience in environments with no Dart app ID. 

## 1.25

- Embed Dart DevTools in Chrome DevTools.

## 1.24

- Detect Dart applications in multi-app environments and show an alert.

## 1.23

- Depend on the latest `package:sse` to improve stability of the connection with many
  concurrent requests. 

## 1.22

- Detect Dart applications and update the icon accordingly.

## 1.21

- Detect authentication issues and prompt accordingly.

## 1.20

- Return response when `dwds.startDebugging` is called.


## 1.19

- Support cross-extension communication for use with Google specific extensions.

## 1.18

- Depend on the latest `package:sse`.

## 1.17

- Depend on the latest `package:sse`.

## 1.16

- Depend on the latest `package:sse`.


## 1.15

- No longer send script parsed events when skipLists are supported,
  improving the IPL of Dart DevTools.

## 1.14

- Depend on the latest `package:sse`.


## 1.13

- Add support for using WebSockets for connection debug backend.

## 1.12

- Update error message to potentially direct users to enable debugging.

## 1.11

- Fix issue where the extension would provide an invalid alert when attempting
  to launch for a non Dart application.

## 1.10

- Properly handle `sendCommand` errors.

## 1.9

- Look for Dart applications nested in iframes.

## 1.8

- Add support for batching scriptParsed events.

## 1.7

- Depend on latest `package:sse` to get retry logic.

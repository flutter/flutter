## 0.6.0
- Fixed bug.

## 0.5.1
- Fixed bug: "@UiThread must be executed on the main thread. Current thread: EventThread" on Flutter version > 1.6.x

## 0.5.0
- Fixed bug: "@UiThread must be executed on the main thread. Current thread: EventThread" on Flutter version > 1.6.x
- Upgraded build gradle to 3.4.2.
- Changed compileSdkVersion to 28

## 0.4.7
- Upgraded android build configs.

## 0.4.6
- Fixed bugs: get hashCode function is always equal 1.

## 0.4.3
* Changed: - init with query option
* Fixed bug: - added forceNew to create socket instance

## 0.4.2
* Fixed bug: checked NULL data received before calling back when using sendMessage function* Fixed bug: checked NULL data received from server before calling back when using sendMessage function

## 0.4.1
* Changed: changed android dependency from "com.github.nkzawa:socket.io-client:0.3.0" to official socket.io "io.socket:socket.io-client:1.0.0"

## 0.4.0
* Added: The guide for installing this plugin on iOS 
* Added: MIT LICENSE

## 0.3.8
* Fixed bugs.

## 0.3.7
* Updated documentation

## 0.3.3
* Fixed bugs: iOS don't create new SocketManger (with the same domain) if it already existed.

## 0.3.2
* Fixed bugs.

## 0.3.0
* Supported iOS (Testing).

## 0.2.0
* Added function: init() socket (please call this function before doing anything with socket)

## 0.1.1
* Refactor code.

## 0.1.0
* Fixed bugs.

## 0.0.21
* Fixed bugs.

## 0.0.20
* Fixed bugs.

## 0.0.19
* Fixed bugs.

## 0.0.18
* Fixed bugs.

## 0.0.17
* Set transports = new String[]{WebSocket.NAME};

## 0.0.16
* Fixed bugs.

## 0.0.15
* Fixed bugs.
* Added 'String query' param [optional] when calling connect function

## 0.0.14
* Fixed bugs.

## 0.0.12
* Fixed bugs.

## 0.0.11
* Fixed bugs.
* Added features: supported calling connect/subscribes/unSubscribes/sendMessage with Flutter's callback Function.
* Supported OS:
    + Android
    + iOS: COMING SOON

## 0.0.8
* Initial release.
* Supported:
    + Android
    + iOS: coming soon

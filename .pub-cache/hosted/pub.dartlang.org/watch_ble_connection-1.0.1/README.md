# Watch BLE (Bluetooth Low Energy) Connection

Communication between Wear OS or watchOS SmartWatch and Android/iOS Device with Bluetooth Low Energy (BLE).

This will send and recieve messages and/or data to the platform specific wearable communication method. It uses the wearable data layer and messaging API's on android devices and WCSession on iPhones.

## Install

### Android

* add ```implementation 'com.google.android.gms:play-services-wearable:17.0.0'``` to the app level build.gradle

* make sure that the  ```applicationId``` of your WearOS app is the same as the one on your phone app

### iOS

* iOS deployment target must be at least 9.3
* enable bitcode in you app to support. [just follow these instructions to enable apple watch for your app](https://flutter.dev/docs/development/platform-integration/apple-watch)

## How to use

* For information on how to access the sent data on wearable devices please see the example project
* It is recommended to not rely on instantaneous transfer of data on IOS as applicationContext waits for a "low intensity situation" to set this value between app and watch

### Sending messages

Use the static method `WatchConnection.sendMessage(Map<String, dynamic> message);` to send a single shot message.

* on android the path `"/MessageChannel"` will be used for all messages

#### Example send message

```dart
WatchConnection.sendMessage({
  "text": "Some text",
  "integerValue": 1
});
```

### Recieve message

Use the static method `WatchConnection.listenForMessage;` to register a message listener function.

* (android specific) if the message data is a string then the library will assume it is JSON and try to convert it. if that operation fails the message data will be sent to the listener unchanged.

#### Recieve message example

```dart
// msg is either a Map<String, dynamic> or a string (make sure to check for that when using the library)
WatchListener.listenForMessage((msg) {
  print(msg);
});
```

### Set data item (datalayer/userConfig)

Use the static method `WatchConnection.setData(String path, Map<String, dynamic> message);` to set a data item with specified path (use wearOS compatible data layer paths)

* (iOS specific) the path variable is used as a key within the application context dictionary
* (iOS specific) data transfer is not instant and will wait for a "low intensity" moment. use this function only to set permanent low priority information

#### Example set data

```dart
WatchConnection.setData("/actor/cage",{
    "name": "Nicolas Saputra",
    "awesomeRating": 100
});
```

### Listen to data events

Use the static method `WatchConnection.listenForDataLayer;` to register a data listener function.

* (android specific) if the data is a string then the library will assume it is JSON and try to convert it. if that operation fails the data will be sent to the listener unchanged.
  
#### Example listen for data

```dart
// data should be a Map<String, dynamic> but can also be a string under exceptional circumstances
WatchListener.listenForDataLayer((data) {
  print(data);
});
```

### Notes

* Currently does not support nested data structures on android. Therefore it is recommended to send complex items as json strings to be parsed on the recieving end
* Supported types in communications are
  * Strings
  * Integers
  * Floats
  * Double
  * Long
  * Boolean
  * Single type lists of strings, floats, ints or longs

## Author

* [Afriwan Ahda](https://github.com/AfriwanAhda)
* [Email](mailto:afriwan.phys@gmail.com?subject=[GitHub]%20Flutter%Watch%20BLE%20Connection)

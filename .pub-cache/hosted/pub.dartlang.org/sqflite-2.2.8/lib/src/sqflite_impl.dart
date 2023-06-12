import 'dart:core';

import 'services_impl.dart';

/// Sqflite channel name
const String channelName = 'com.tekartik.sqflite';

/// Sqflite channel
const MethodChannel channel = MethodChannel(channelName);

/// Temp flag to test concurrent reads
const supportsConcurrency = false;

/// Invoke a native method
Future<T> invokeMethod<T>(String method, [Object? arguments]) async =>
    await channel.invokeMethod<T>(method, arguments) as T;

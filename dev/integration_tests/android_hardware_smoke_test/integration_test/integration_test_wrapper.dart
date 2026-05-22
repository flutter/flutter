// ignore_for_file: avoid_print, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:android_hardware_smoke_test/main.dart' as app;

void main() {
  const String channelName =
      'com.example.android_hardware_smoke_test/test_channel';

  enableFlutterDriverExtension(
    handler: (String? request) async {
      print("integration_test_wrapper: received request: $request");
      if (request == null) {
        return json.encode(<String, dynamic>{
          'message': "Error: request was null",
        });
      }

      // Decode JSON payload containing testName & performAppSideGoldenCompare
      final dynamic decoded = json.decode(request);
      final ByteData message = const JSONMessageCodec().encodeMessage(decoded)!;
      final Completer<String> completer = Completer<String>();

      // Simulates MainActivity platform message internally targeting the app's test_channel
      ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        channelName,
        message,
        (ByteData? replyData) {
          final reply =
              const JSONMessageCodec().decodeMessage(replyData)
                  as Map<dynamic, dynamic>?;
          completer.complete(json.encode(reply));
        },
      );

      return completer.future;
    },
  );

  app.main();
}

import 'dart:async';
import 'dart:convert';

import 'package:android_hardware_smoke_test/main.dart' as app;
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  const String channelName =
      "com.example.android_hardware_smoke_test/test_channel";

  enableFlutterDriverExtension(
    // Thin handler to bridge driver's requestData and MainApp's test_channel.
    handler: (String? request) async {
      if (request == null) {
        return json.encode(<String, Object?>{
          "message": "Error: request was null",
        });
      }

      // The request is encoded JSON, but there is no need to decode it here.
      final ByteData message = const StringCodec().encodeMessage(request)!;
      final Completer<String> completer = Completer<String>();

      // ignore: deprecated_member_use
      ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        channelName,
        message,
        (ByteData? replyData) {
          final reply =
              const JSONMessageCodec().decodeMessage(replyData)
                  as Map<Object?, Object?>?;
          completer.complete(json.encode(reply));
        },
      );

      return completer.future;
    },
  );

  app.main();
}

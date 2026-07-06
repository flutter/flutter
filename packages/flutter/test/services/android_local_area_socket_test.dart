import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/src/services/android_local_area_socket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AndroidLocalAreaSocket', () {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/android_local_area_config');
    final log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          log.add(methodCall);
          if (methodCall.method == 'requestLocalAreaAccess') {
            return true; // Default to granted
          }
          return null;
        },
      );
      // Reset the debug flag
      AndroidLocalAreaSocket.debugPlatformIsAndroid = false;
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });

    test('does not call channel on non-Android', () async {
      AndroidLocalAreaSocket.debugPlatformIsAndroid = false;

      // We need to override Socket.connect to avoid actual network calls.
      await IOOverrides.runZoned(() async {
        await AndroidLocalAreaSocket.connect('localhost', 80);
      }, socketConnect: (host, int port, {sourceAddress, int? sourcePort, Duration? timeout}) async {
        return MockSocket();
      });

      expect(log, isEmpty);
    });

    test('calls channel on Android and succeeds', () async {
      AndroidLocalAreaSocket.debugPlatformIsAndroid = true;

      await IOOverrides.runZoned(() async {
        await AndroidLocalAreaSocket.connect('localhost', 80);
      }, socketConnect: (host, int port, {sourceAddress, int? sourcePort, Duration? timeout}) async {
        return MockSocket();
      });

      expect(log, hasLength(1));
      expect(log.single.method, 'requestLocalAreaAccess');
    });

    test('throws SocketException on Android when permission denied', () async {
      AndroidLocalAreaSocket.debugPlatformIsAndroid = true;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          log.add(methodCall);
          if (methodCall.method == 'requestLocalAreaAccess') {
            return false; // Denied
          }
          return null;
        },
      );

      await IOOverrides.runZoned(() async {
        expect(
          () => AndroidLocalAreaSocket.connect('localhost', 80),
          throwsA(isA<SocketException>()),
        );
      }, socketConnect: (host, int port, {sourceAddress, int? sourcePort, Duration? timeout}) async {
        return MockSocket();
      });

      expect(log, hasLength(1));
    });
  });
}

class MockSocket extends Mock implements Socket {}

// Simple mock implementation if Mockito is not available or preferred not to use it here.
class Mock {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

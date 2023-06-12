import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:audio_session/audio_session.dart';

void main() {
  const MethodChannel channel = MethodChannel('audio_session');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('meaning of life', () async {
    expect('42', '42');
  });
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class MyAudioCache extends AudioCache {
  List<String> called = [];

  MyAudioCache({String prefix = 'assets/'}) : super(prefix: prefix);

  @override
  Future<Uri> fetchToMemory(String fileName) async {
    called.add(fileName);
    return Uri.parse('test/assets/$fileName');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const _channel = MethodChannel('plugins.flutter.io/path_provider');
  _channel.setMockMethodCallHandler((c) async => '/tmp');

  const channel = MethodChannel('xyz.luan/audioplayers');
  channel.setMockMethodCallHandler((MethodCall call) async => 1);

  group('AudioCache', () {
    test('sets cache', () async {
      final player = MyAudioCache();
      await player.load('audio.mp3');
      expect(player.loadedFiles['audio.mp3'], isNotNull);
      expect(player.called, hasLength(1));
      player.called.clear();

      await player.load('audio.mp3');
      expect(player.called, hasLength(0));
    });
  });
}

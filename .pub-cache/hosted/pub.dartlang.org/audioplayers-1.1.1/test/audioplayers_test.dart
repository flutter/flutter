import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/method_channel_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  const channel = MethodChannel('xyz.luan/audioplayers');
  channel.setMockMethodCallHandler((MethodCall call) async {
    calls.add(call);
    return 0;
  });

  void clear() {
    calls.clear();
  }

  MethodCall popCall() {
    return calls.removeAt(0);
  }

  MethodCall popLastCall() {
    expect(calls, hasLength(1));
    return popCall();
  }

  group('AudioPlayers', () {
    test('#play', () async {
      calls.clear();
      final player = AudioPlayer();
      await player.play(UrlSource('internet.com/file.mp3'));
      final call1 = popCall();
      expect(call1.method, 'setSourceUrl');
      expect(call1.getString('url'), 'internet.com/file.mp3');
      final call2 = popLastCall();
      expect(call2.method, 'resume');
    });

    test('multiple players', () async {
      calls.clear();
      final player1 = AudioPlayer();
      final player2 = AudioPlayer();

      await player1.play(UrlSource('internet.com/file.mp3'));
      final call1 = popCall();
      final player1Id = call1.getString('playerId');
      expect(call1.method, 'setSourceUrl');
      expect(call1.getString('url'), 'internet.com/file.mp3');
      final call2 = popLastCall();
      expect(call2.method, 'resume');

      clear();
      await player1.play(UrlSource('internet.com/file.mp3'));
      expect(popCall().getString('playerId'), player1Id);

      clear();
      await player2.play(UrlSource('internet.com/file.mp3'));
      expect(popCall().getString('playerId'), isNot(player1Id));

      clear();
      await player1.play(UrlSource('internet.com/file.mp3'));
      expect(popCall().getString('playerId'), player1Id);
    });

    test('#resume, #pause and #duration', () async {
      calls.clear();
      final player = AudioPlayer();
      await player.setSourceUrl('assets/audio.mp3');
      expect(popLastCall().method, 'setSourceUrl');

      await player.resume();
      expect(popLastCall().method, 'resume');

      await player.getDuration();
      expect(popLastCall().method, 'getDuration');

      await player.pause();
      expect(popLastCall().method, 'pause');
    });
  });
}

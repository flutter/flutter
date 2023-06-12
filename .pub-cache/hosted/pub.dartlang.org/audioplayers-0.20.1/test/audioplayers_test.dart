import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

extension _Args on MethodCall {
  Map<dynamic, dynamic> get args => arguments as Map<dynamic, dynamic>;

  String getString(String key) {
    return args[key] as String;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  const channel = MethodChannel('xyz.luan/audioplayers');
  channel.setMockMethodCallHandler((MethodCall call) async {
    calls.add(call);
    return 0;
  });

  MethodCall popCall() {
    expect(calls, hasLength(1));
    return calls.removeAt(0);
  }

  group('AudioPlayers', () {
    test('#play', () async {
      calls.clear();
      final player = AudioPlayer();
      await player.play('internet.com/file.mp3');
      final call = popCall();
      expect(call.method, 'play');
      expect(call.getString('url'), 'internet.com/file.mp3');
    });

    test('multiple players', () async {
      calls.clear();
      final player1 = AudioPlayer();
      final player2 = AudioPlayer();

      await player1.play('internet.com/file.mp3');
      final call = popCall();
      final player1Id = call.getString('playerId');
      expect(call.method, 'play');
      expect(call.getString('url'), 'internet.com/file.mp3');

      await player1.play('internet.com/file.mp3');
      expect(popCall().getString('playerId'), player1Id);

      await player2.play('internet.com/file.mp3');
      expect(popCall().getString('playerId'), isNot(player1Id));

      await player1.play('internet.com/file.mp3');
      expect(popCall().getString('playerId'), player1Id);
    });

    test('#resume, #pause and #duration', () async {
      calls.clear();
      final player = AudioPlayer();
      await player.setUrl('assets/audio.mp3');
      expect(popCall().method, 'setUrl');

      await player.resume();
      expect(popCall().method, 'resume');

      await player.getDuration();
      expect(popCall().method, 'getDuration');

      await player.pause();
      expect(popCall().method, 'pause');
    });
  });
}

//import 'package:flutter_test/flutter_test.dart';
//import 'package:integration_test/integration_test.dart';
//import 'package:just_audio/just_audio.dart';
////import 'package:just_audio_example/main.dart' as app;
//
//void main() {
//  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
//
//  void expectDuration(Duration a, Duration b, {int epsilon = 200}) {
//    expect((a - b).inMilliseconds.abs(), lessThanOrEqualTo(epsilon));
//  }
//
//  void expectState({
//    AudioPlayer player,
//    Duration position,
//    ProcessingState processingState,
//    bool playing,
//  }) {
//    if (position != null) {
//      expectDuration(player.position, position);
//    }
//    if (processingState != null) {
//      expect(player.processingState, equals(processingState));
//    }
//    if (playing != null) {
//      expect(player.playing, equals(playing));
//    }
//  }
//
//  group('just_audio example', () {
//    // TODO: Add more integration tests.
//    testWidgets('init', (WidgetTester tester) async {
//      final player = AudioPlayer();
//      expect(player.processingState, equals(ProcessingState.idle));
//      expect(player.position, equals(Duration.zero));
//      //expect(player.bufferedPosition, equals(Duration.zero));
//      expect(player.duration, equals(null));
//      expect(player.icyMetadata, equals(null));
//      expect(player.currentIndex, equals(null));
//      expect(player.androidAudioSessionId, equals(null));
//      expect(player.playing, equals(false));
//      expect(player.volume, equals(1.0));
//      expect(player.speed, equals(1.0));
//      expect(player.sequence, equals(null));
//      expect(player.hasNext, equals(false));
//      expect(player.hasPrevious, equals(false));
//      //expect(player.loopMode, equals(LoopMode.off));
//      //expect(player.shuffleModeEnabled, equals(false));
//      expect(player.automaticallyWaitsToMinimizeStalling, equals(true));
//      await player.dispose();
//    });
//    testWidgets('control', (WidgetTester tester) async {
//      final player = AudioPlayer();
//      final duration = await player.setUrl(
//          'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3');
//      final point1 = Duration(seconds: 60);
//      final stopwatch = Stopwatch();
//      expectState(
//        player: player,
//        position: Duration.zero,
//        processingState: ProcessingState.ready,
//        playing: false,
//      );
//      await player.seek(point1);
//      expectState(
//        player: player,
//        position: point1,
//        processingState: ProcessingState.ready,
//        playing: false,
//      );
//      player.play();
//      expectState(
//        player: player,
//        position: point1,
//        processingState: ProcessingState.ready,
//      );
//      await Future.delayed(Duration(milliseconds: 100));
//      expectState(player: player, playing: true);
//      await Future.delayed(Duration(seconds: 5));
//      expectState(
//        player: player,
//        position: point1 + Duration(seconds: 5),
//        processingState: ProcessingState.ready,
//        playing: true,
//      );
//      await player.seek(duration - Duration(seconds: 3));
//      expectState(
//        player: player,
//        position: duration - Duration(seconds: 3),
//        processingState: ProcessingState.ready,
//        playing: true,
//      );
//      await player.pause();
//      expectState(
//        player: player,
//        position: duration - Duration(seconds: 3),
//        processingState: ProcessingState.ready,
//        playing: false,
//      );
//      stopwatch.reset();
//      stopwatch.start();
//      final playFuture = player.play();
//      expectState(
//        player: player,
//        position: duration - Duration(seconds: 3),
//        processingState: ProcessingState.ready,
//      );
//      expectState(player: player, playing: true);
//      await playFuture;
//      expectDuration(stopwatch.elapsed, Duration(seconds: 3));
//      expectState(
//        player: player,
//        position: duration,
//        processingState: ProcessingState.completed,
//        playing: true,
//      );
//      await player.dispose();
//    });
//  });
//}

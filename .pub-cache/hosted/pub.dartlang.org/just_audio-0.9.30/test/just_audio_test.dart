import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // We need an actual HttpClient to test the proxy server.
  final overrides = MyHttpOverrides();
  HttpOverrides.global = overrides;
  HttpOverrides.runWithHttpOverrides(runTests, overrides);
}

void runTests() {
  final mock = MockJustAudio();
  JustAudioPlatform.instance = mock;
  const audioSessionChannel = MethodChannel('com.ryanheise.audio_session');

  void expectDuration(Duration a, Duration b, {int epsilon = 200}) {
    expect((a - b).inMilliseconds.abs(), lessThanOrEqualTo(epsilon));
  }

  void expectState({
    required AudioPlayer player,
    Duration? position,
    ProcessingState? processingState,
    bool? playing,
  }) {
    if (position != null) {
      expectDuration(player.position, position);
    }
    if (processingState != null) {
      expect(player.processingState, equals(processingState));
    }
    if (playing != null) {
      expect(player.playing, equals(playing));
    }
  }

  void checkIndices(List<int> indices, int length) {
    expect(indices.length, length);
    final sorted = List.of(indices)..sort();
    expect(sorted, equals(List.generate(indices.length, (i) => i)));
  }

  setUp(() {
    audioSessionChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });
  });

  tearDown(() {
    audioSessionChannel.setMockMethodCallHandler(null);
  });

  test('init', () async {
    final player = AudioPlayer();
    expect(player.processingState, equals(ProcessingState.idle));
    expect(player.position, equals(Duration.zero));
    //expect(player.bufferedPosition, equals(Duration.zero));
    expect(player.duration, equals(null));
    expect(player.icyMetadata, equals(null));
    expect(player.currentIndex, equals(null));
    expect(player.androidAudioSessionId, equals(null));
    expect(player.playing, equals(false));
    expect(player.volume, equals(1.0));
    expect(player.speed, equals(1.0));
    expect(player.sequence, equals(null));
    expect(player.hasNext, equals(false));
    expect(player.hasPrevious, equals(false));
    //expect(player.loopMode, equals(LoopMode.off));
    //expect(player.shuffleModeEnabled, equals(false));
    expect(player.automaticallyWaitsToMinimizeStalling, equals(true));
    await player.dispose();
  });

  test('idle-state', () async {
    final player = AudioPlayer();
    player.play();
    expectState(player: player, playing: true);
    await player.pause();
    expectState(player: player, playing: false);
    await player.setVolume(0.5);
    expect(player.volume, equals(0.5));
    await player.setSpeed(0.7);
    expect(player.speed, equals(0.7));
    await player.setLoopMode(LoopMode.one);
    expect(player.loopMode, equals(LoopMode.one));
    await player.setShuffleModeEnabled(true);
    expect(player.shuffleModeEnabled, equals(true));
    await player.seek(const Duration(seconds: 1));
    expectState(
        player: player, playing: false, position: const Duration(seconds: 1));
    final playlist = ConcatenatingAudioSource(children: []);
    await player.setAudioSource(playlist, preload: false);
    await playlist.addAll([
      AudioSource.uri(
        Uri.parse("https://foo.foo/foo.mp3"),
        tag: 'a',
      ),
      AudioSource.uri(
        Uri.parse("https://bar.bar/bar.mp3"),
        tag: 'b',
      ),
      AudioSource.uri(
        Uri.parse("https://baz.baz/baz.mp3"),
        tag: 'c',
      ),
    ]);
    await playlist.move(2, 1);
    await playlist.removeAt(2);
    await player.load();
    expect(playlist.sequence.map((s) => s.tag as String?).toList(),
        equals(['a', 'c']));
    await player.dispose();
  });

  test('load', () async {
    final player = AudioPlayer();
    final duration = await player.setUrl('https://foo.foo/foo.mp3');
    expect(duration, equals(audioSourceDuration));
    expect(player.duration, equals(duration));
    expect(player.processingState, equals(ProcessingState.ready));
    expect(player.position, equals(Duration.zero));
    expect(player.currentIndex, equals(0));
    expect(player.hasNext, equals(false));
    expect(player.hasPrevious, equals(false));
    expect(player.sequence!.length, equals(1));
    expect(player.playing, equals(false));
    await player.dispose();
  });

  test('load error', () async {
    final player = AudioPlayer();
    Object? exception;
    try {
      await player.setUrl('https://foo.foo/404.mp3');
      exception = null;
    } catch (e) {
      exception = e;
    }
    expect(exception != null, equals(true));
    try {
      await player.setUrl('https://foo.foo/abort.mp3');
      exception = null;
    } catch (e) {
      exception = e;
    }
    expect(exception != null, equals(true));
    try {
      await player.setUrl('https://foo.foo/error.mp3');
      exception = null;
    } catch (e) {
      exception = e;
    }
    expect(exception != null, equals(true));
    await player.dispose();
  });

  test('control', () async {
    final player = AudioPlayer();
    final duration = (await (player.setUrl('https://foo.foo/foo.mp3')))!;
    final point1 = duration * 0.3;
    final stopwatch = Stopwatch();
    expectState(
      player: player,
      position: Duration.zero,
      processingState: ProcessingState.ready,
      playing: false,
    );
    await player.seek(point1);
    expectState(
      player: player,
      position: point1,
      processingState: ProcessingState.ready,
      playing: false,
    );
    player.play();
    expectState(
      player: player,
      position: point1,
      processingState: ProcessingState.ready,
    );
    await Future<dynamic>.delayed(const Duration(milliseconds: 100));
    expectState(player: player, playing: true);
    await Future<dynamic>.delayed(const Duration(seconds: 1));
    expectState(
      player: player,
      position: point1 + const Duration(seconds: 1),
      processingState: ProcessingState.ready,
      playing: true,
    );
    await player.seek(duration - const Duration(seconds: 3));
    expectState(
      player: player,
      position: duration - const Duration(seconds: 3),
      processingState: ProcessingState.ready,
      playing: true,
    );
    await player.pause();
    expectState(
      player: player,
      position: duration - const Duration(seconds: 3),
      processingState: ProcessingState.ready,
      playing: false,
    );
    stopwatch.reset();
    stopwatch.start();
    final playFuture = player.play();
    expectState(
      player: player,
      position: duration - const Duration(seconds: 3),
      processingState: ProcessingState.ready,
    );
    expectState(player: player, playing: true);
    await playFuture;
    expectDuration(stopwatch.elapsed, const Duration(seconds: 3));
    expectState(
      player: player,
      position: duration,
      processingState: ProcessingState.completed,
      playing: true,
    );
    await player.dispose();
  });

  test('speed', () async {
    final player = AudioPlayer();
    /*final duration =*/ await player.setUrl('https://foo.foo/foo.mp3');
    const period1 = Duration(seconds: 2);
    const period2 = Duration(seconds: 2);
    const speed1 = 0.75;
    const speed2 = 1.5;
    final position1 = period1 * speed1;
    final position2 = position1 + period2 * speed2;
    expectState(player: player, position: Duration.zero);
    await player.setSpeed(speed1);
    player.play();
    await Future<dynamic>.delayed(period1);
    expectState(player: player, position: position1);
    await player.setSpeed(speed2);
    await Future<dynamic>.delayed(period2);
    expectState(player: player, position: position2);
    await player.dispose();
  });

  test('skipSilence', () async {
    final player = AudioPlayer();
    expect(player.skipSilenceEnabled, equals(false));
    await player.setSkipSilenceEnabled(true);
    expect(player.skipSilenceEnabled, equals(true));
    await player.setSkipSilenceEnabled(false);
    expect(player.skipSilenceEnabled, equals(false));
    await player.dispose();
  });

  test('pitch', () async {
    final player = AudioPlayer();
    expect(player.pitch, equals(1.0));
    await player.setPitch(1.5);
    expect(player.pitch, equals(1.5));
    await player.dispose();
  });

  test('setAutomaticallyWaitsToMinimizeStalling', () async {
    final player = AudioPlayer();
    expect(player.automaticallyWaitsToMinimizeStalling, equals(true));
    await player.setAutomaticallyWaitsToMinimizeStalling(false);
    expect(player.automaticallyWaitsToMinimizeStalling, equals(false));
    await player.setAutomaticallyWaitsToMinimizeStalling(true);
    expect(player.automaticallyWaitsToMinimizeStalling, equals(true));
    await player.dispose();
  });

  test('setCanUseNetworkResourcesForLiveStreamingWhilePaused', () async {
    final player = AudioPlayer();
    expect(player.canUseNetworkResourcesForLiveStreamingWhilePaused,
        equals(false));
    await player.setCanUseNetworkResourcesForLiveStreamingWhilePaused(true);
    expect(
        player.canUseNetworkResourcesForLiveStreamingWhilePaused, equals(true));
    await player.setCanUseNetworkResourcesForLiveStreamingWhilePaused(false);
    expect(player.canUseNetworkResourcesForLiveStreamingWhilePaused,
        equals(false));
    await player.dispose();
  });

  test('setPreferredPeakBitRate', () async {
    final player = AudioPlayer();
    expect(player.preferredPeakBitRate, equals(0.0));
    await player.setPreferredPeakBitRate(1000.0);
    expect(player.preferredPeakBitRate, equals(1000.0));
    await player.dispose();
  });

  test('setAndroidAudioAttributes', () async {
    final player = AudioPlayer();
    await player.setAndroidAudioAttributes(const AndroidAudioAttributes());
    await player.dispose();
  });

  test('positionStream', () async {
    final player = AudioPlayer();
    /*final duration =*/ await player.setUrl('https://foo.foo/foo.mp3');
    const period = Duration(seconds: 3);
    const position1 = period;
    final position2 = position1 + period;
    const speed1 = 0.75;
    const speed2 = 1.5;
    final stepDuration = period ~/ 5;
    var target = stepDuration;
    player.setSpeed(speed1);
    player.play();
    final stopwatch = Stopwatch();
    stopwatch.start();

    var completer = Completer<dynamic>();
    late StreamSubscription subscription;
    subscription = player.positionStream.listen((position) {
      if (position >= position1) {
        subscription.cancel();
        completer.complete();
      } else if (position >= target) {
        expectDuration(position, stopwatch.elapsed * speed1);
        target += stepDuration;
      }
    });
    await completer.future;
    player.setSpeed(speed2);
    stopwatch.reset();

    target = position1 + target;
    completer = Completer<dynamic>();
    subscription = player.positionStream.listen((position) {
      if (position >= position2) {
        subscription.cancel();
        completer.complete();
      } else if (position >= target) {
        expectDuration(position, position1 + stopwatch.elapsed * speed2);
        target += stepDuration;
      }
    });
    await completer.future;
    await player.dispose();
  });

  test('icyMetadata', () async {
    final player = AudioPlayer();
    expect(player.icyMetadata, equals(null));
    /*final duration =*/ await player.setUrl('https://foo.foo/foo.mp3');
    player.play();
    expect(
        player.icyMetadata!.headers!.genre, equals(icyMetadata.headers!.genre));
    expect((await player.icyMetadataStream.first)!.headers!.genre,
        equals(icyMetadata.headers!.genre));
    await player.dispose();
  });

  test('proxy', () async {
    final server = MockWebServer();
    await server.start();
    final player = AudioPlayer();
    // This simulates an actual URL
    final uri = Uri.parse(
        'http://${InternetAddress.loopbackIPv4.address}:${server.port}/proxy/foo.mp3');
    await player.setUrl('$uri', headers: {'custom-header': 'Hello'});
    // Obtain the proxy URL that the platform side should use to load the data.
    final proxyUri = Uri.parse(player.icyMetadata!.info!.url!);
    // Simulate the platform side requesting the data.
    final request = await HttpClient().getUrl(proxyUri);
    final response = await request.close();
    final responseText = await response.transform(utf8.decoder).join();
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(responseText, equals('Hello'));
    expect(response.headers.value(HttpHeaders.contentTypeHeader),
        equals('audio/mock'));
    await server.stop();
    await player.dispose();
  });

  test('proxy0.9', () async {
    final server = MockWebServer();
    await server.start();
    final player = AudioPlayer();
    // This simulates an actual URL
    final uri = Uri.parse(
        'http://${InternetAddress.loopbackIPv4.address}:${server.port}/proxy0.9/foo.mp3');
    await player.setUrl('$uri');
    // Obtain the proxy URL that the platform side should use to load the data.
    final proxyUri = Uri.parse(player.icyMetadata!.info!.url!);
    // Simulate the platform side requesting the data.
    final socket = await Socket.connect(proxyUri.host, proxyUri.port);
    //final socket = await Socket.connect(uri.host, uri.port);
    socket.write('GET ${uri.path} HTTP/1.0\n\n');
    await socket.flush();
    final responseText = await socket
        .transform(Converter.castFrom<List<int>, String, Uint8List, String>(
            utf8.decoder))
        .join();
    await socket.close();
    expect(responseText, equals('Hello'));
    await server.stop();
    await player.dispose();
  });

  test('stream-source', () async {
    final server = MockWebServer();
    await server.start();
    final player = AudioPlayer();
    // This simulates an actual URL
    await player.setAudioSource(TestStreamAudioSource(tag: 'stream-test'));
    // Obtain the proxy URL that the platform side should use to load the data.
    final proxyUri = Uri.parse(player.icyMetadata!.info!.url!);
    // Simulate the platform side requesting the data.
    Future<void> testRequest(int? start, int? end) async {
      final request = await HttpClient().getUrl(proxyUri);
      if (start != null && end != null) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-${end - 1}');
      } else if (start != null) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-');
      }
      final response = await request.close();
      //final responseData = await response.expand((chunk) => chunk).toList();
      final responseData = <int>[];
      await for (var chunk in response) {
        responseData.addAll(chunk);
      }
      expect(
          responseData,
          equals(
              byteRangeData.sublist(start ?? 0, end ?? byteRangeData.length)));
      expect(
          response.contentLength, (end ?? byteRangeData.length) - (start ?? 0));
      if (start != null && end != null) {
        expect(response.headers.value(HttpHeaders.contentRangeHeader),
            'bytes $start-${end - 1}/${byteRangeData.length}');
        expect(response.statusCode, equals(HttpStatus.partialContent));
      } else if (start != null) {
        expect(response.headers.value(HttpHeaders.contentRangeHeader),
            'bytes $start-${byteRangeData.length - 1}/${byteRangeData.length}');
        expect(response.statusCode, equals(HttpStatus.partialContent));
      } else {
        expect(response.headers.value(HttpHeaders.contentRangeHeader), null);
        expect(response.statusCode, equals(HttpStatus.ok));
      }
      expect(response.headers.value(HttpHeaders.contentTypeHeader),
          equals('audio/mock'));
    }

    await testRequest(null, null);
    await testRequest(20, null);
    await testRequest(20, 60);

    await server.stop();
    await player.dispose();
  });

  test('sequence', () async {
    final source1 = ConcatenatingAudioSource(children: [
      LoopingAudioSource(
        count: 2,
        child: ClippingAudioSource(
          start: const Duration(seconds: 60),
          end: const Duration(seconds: 65),
          child: AudioSource.uri(Uri.parse("https://foo.foo/foo.mp3")),
          tag: 'a',
        ),
      ),
      AudioSource.uri(
        Uri.parse("https://bar.bar/bar.mp3"),
        tag: 'b',
      ),
      AudioSource.uri(
        Uri.parse("https://baz.baz/baz.mp3"),
        tag: 'c',
      ),
    ]);
    expect(source1.sequence.map((s) => s.tag as String?).toList(),
        equals(['a', 'a', 'b', 'c']));
    final source2 = ConcatenatingAudioSource(children: []);
    final player = AudioPlayer();
    await player.setAudioSource(source2);
    expect(source2.sequence.length, equals(0));
    await source2
        .add(AudioSource.uri(Uri.parse('https://b.b/b.mp3'), tag: 'b'));
    await source2.insert(
        0, AudioSource.uri(Uri.parse('https://a.a/a.mp3'), tag: 'a'));
    await source2.insert(
        2, AudioSource.uri(Uri.parse('https://c.c/c.mp3'), tag: 'c'));
    await source2.addAll([
      AudioSource.uri(Uri.parse('https://d.d/d.mp3'), tag: 'd'),
      AudioSource.uri(Uri.parse('https://e.e/e.mp3'), tag: 'e'),
    ]);
    await source2.insertAll(3, [
      AudioSource.uri(Uri.parse('https://e.e/e.mp3'), tag: 'e'),
      AudioSource.uri(Uri.parse('https://f.f/f.mp3'), tag: 'f'),
    ]);
    expect(source2.sequence.map((s) => s.tag as String?),
        equals(['a', 'b', 'c', 'e', 'f', 'd', 'e']));
    await source2.removeAt(0);
    expect(source2.sequence.map((s) => s.tag as String?),
        equals(['b', 'c', 'e', 'f', 'd', 'e']));
    await source2.move(3, 2);
    expect(source2.sequence.map((s) => s.tag as String?),
        equals(['b', 'c', 'f', 'e', 'd', 'e']));
    await source2.move(2, 3);
    expect(source2.sequence.map((s) => s.tag as String?),
        equals(['b', 'c', 'e', 'f', 'd', 'e']));
    await source2.removeRange(0, 2);
    expect(source2.sequence.map((s) => s.tag as String?),
        equals(['e', 'f', 'd', 'e']));
    await source2.removeAt(3);
    expect(
        source2.sequence.map((s) => s.tag as String?), equals(['e', 'f', 'd']));
    await source2.removeRange(1, 3);
    expect(source2.sequence.map((s) => s.tag as String?), equals(['e']));
    await source2.clear();
    expect(source2.sequence.map((s) => s.tag as String?), equals(<String>[]));
    await player.dispose();
  });

  test('idle-sequence', () async {
    final source = ConcatenatingAudioSource(children: []);
    final player = AudioPlayer();
    await player.setAudioSource(source);
    await player.stop();
    expect(source.sequence.length, equals(0));
    await source.add(AudioSource.uri(Uri.parse('https://b.b/b.mp3'), tag: 'b'));
    await source.insert(
        0, AudioSource.uri(Uri.parse('https://a.a/a.mp3'), tag: 'a'));
    await source.insert(
        2, AudioSource.uri(Uri.parse('https://c.c/c.mp3'), tag: 'c'));
    await source.addAll([
      AudioSource.uri(Uri.parse('https://d.d/d.mp3'), tag: 'd'),
      AudioSource.uri(Uri.parse('https://e.e/e.mp3'), tag: 'e'),
    ]);
    await source.insertAll(3, [
      AudioSource.uri(Uri.parse('https://e.e/e.mp3'), tag: 'e'),
      AudioSource.uri(Uri.parse('https://f.f/f.mp3'), tag: 'f'),
    ]);
    expect(source.sequence.map((s) => s.tag as String?),
        equals(['a', 'b', 'c', 'e', 'f', 'd', 'e']));
    await source.removeAt(0);
    expect(source.sequence.map((s) => s.tag as String?),
        equals(['b', 'c', 'e', 'f', 'd', 'e']));
    await source.move(3, 2);
    expect(source.sequence.map((s) => s.tag as String?),
        equals(['b', 'c', 'f', 'e', 'd', 'e']));
    await source.move(2, 3);
    expect(source.sequence.map((s) => s.tag as String?),
        equals(['b', 'c', 'e', 'f', 'd', 'e']));
    await source.removeRange(0, 2);
    expect(source.sequence.map((s) => s.tag as String?),
        equals(['e', 'f', 'd', 'e']));
    await source.removeAt(3);
    expect(
        source.sequence.map((s) => s.tag as String?), equals(['e', 'f', 'd']));
    await source.removeRange(1, 3);
    expect(source.sequence.map((s) => s.tag as String?), equals(['e']));
    await source.clear();
    expect(source.sequence.map((s) => s.tag as String?), equals(<String>[]));
  });

  test('sequence-state', () async {
    final player = AudioPlayer();
    expect(player.sequenceState, equals(null));
    for (var shuffle in [false, true]) {
      if (shuffle) {
        await player.setShuffleModeEnabled(shuffle);
      }
      final playlist = ConcatenatingAudioSource(
        children: [
          AudioSource.uri(
            Uri.parse("https://bar.bar/a.mp3"),
            tag: 'a',
          ),
          AudioSource.uri(
            Uri.parse("https://baz.baz/b.mp3"),
            tag: 'b',
          ),
          AudioSource.uri(
            Uri.parse("https://baz.baz/c.mp3"),
            tag: 'c',
          ),
          AudioSource.uri(
            Uri.parse("https://baz.baz/d.mp3"),
            tag: 'd',
          ),
          AudioSource.uri(
            Uri.parse("https://baz.baz/e.mp3"),
            tag: 'e',
          ),
        ],
      );
      void expectEffectiveSequence() {
        expect(
            player.sequenceState?.effectiveSequence,
            shuffle
                ? player.effectiveIndices!
                    .map((i) => player.sequence![i])
                    .toList()
                : player.sequence);
      }

      //List<int> effectiveSequenceToIndices() {
      //  return player.effectiveSequence.map((IndexedAudioSource item) => player1.sequence.indexOf(item)).toList();
      //}
      await player.setAudioSource(playlist);
      expect(player.sequenceState?.sequence, equals(playlist.children));
      expect(player.sequenceState?.currentIndex, equals(0));
      expect(player.sequenceState?.currentSource, equals(playlist.children[0]));
      expectEffectiveSequence();
      await player.seek(Duration.zero, index: 4);
      expect(player.sequenceState?.sequence, equals(playlist.children));
      expect(player.sequenceState?.currentIndex, equals(4));
      expect(player.sequenceState?.currentSource, equals(playlist.children[4]));
      await playlist.removeAt(4);
      expectEffectiveSequence();
      expect(player.sequenceState?.sequence, equals(playlist.children));
      expect(player.sequenceState?.currentIndex, equals(3));
      expect(player.sequenceState?.currentSource, equals(playlist.children[3]));
      await playlist.removeAt(1);
      expect(player.sequenceState?.sequence, equals(playlist.children));
      expect(player.sequenceState?.currentIndex, equals(2));
      expect(player.sequenceState?.currentSource, equals(playlist.children[2]));
      await playlist.clear();
      expect(player.sequenceState?.sequence, equals(playlist.children));
      // expecting 0 here may change in a future version.
      expect(player.sequenceState?.currentIndex, equals(0));
      expect(player.sequenceState?.currentSource, equals(null));
      expectEffectiveSequence();
    }
    await player.dispose();
  });

  test('setClip', () async {
    final player = AudioPlayer();
    final duration1 = await player.setUrl('https://bar.bar/foo.mp3');
    expectDuration(duration1!, audioSourceDuration);
    final duration2 = await player.setClip(start: const Duration(seconds: 10));
    expectDuration(
        duration2!, audioSourceDuration - const Duration(seconds: 10));
    final duration3 = await player.setClip(end: const Duration(seconds: 15));
    expectDuration(duration3!, const Duration(seconds: 15));
    final duration4 = await player.setClip(
        start: const Duration(seconds: 10), end: const Duration(seconds: 21));
    expectDuration(duration4!, const Duration(seconds: 11));
    final duration5 = await player.setClip();
    expectDuration(duration5!, audioSourceDuration);
    await player.dispose();
  });

  test('detect', () async {
    expect(AudioSource.uri(Uri.parse('https://a.a/a.mpd')) is DashAudioSource,
        equals(true));
    expect(AudioSource.uri(Uri.parse('https://a.a/a.m3u8')) is HlsAudioSource,
        equals(true));
    expect(
        AudioSource.uri(Uri.parse('https://a.a/a.mp3'))
            is ProgressiveAudioSource,
        equals(true));
    expect(AudioSource.uri(Uri.parse('https://a.a/a#.mpd')) is DashAudioSource,
        equals(true));
  });

  test('shuffle order', () async {
    final shuffleOrder1 = DefaultShuffleOrder(random: Random(1001));
    checkIndices(shuffleOrder1.indices, 0);
    //expect(shuffleOrder1.indices, equals([]));
    shuffleOrder1.insert(0, 5);
    //expect(shuffleOrder1.indices, equals([3, 0, 2, 4, 1]));
    checkIndices(shuffleOrder1.indices, 5);
    shuffleOrder1.insert(3, 2);
    checkIndices(shuffleOrder1.indices, 7);
    shuffleOrder1.insert(0, 2);
    checkIndices(shuffleOrder1.indices, 9);
    shuffleOrder1.insert(9, 2);
    checkIndices(shuffleOrder1.indices, 11);

    final indices1 = List.of(shuffleOrder1.indices);
    shuffleOrder1.shuffle();
    expect(shuffleOrder1.indices, isNot(indices1));
    checkIndices(shuffleOrder1.indices, 11);
    final indices2 = List.of(shuffleOrder1.indices);
    shuffleOrder1.shuffle(initialIndex: 5);
    expect(shuffleOrder1.indices[0], equals(5));
    expect(shuffleOrder1.indices, isNot(indices2));
    checkIndices(shuffleOrder1.indices, 11);

    shuffleOrder1.removeRange(4, 6);
    checkIndices(shuffleOrder1.indices, 9);
    shuffleOrder1.removeRange(0, 2);
    checkIndices(shuffleOrder1.indices, 7);
    shuffleOrder1.removeRange(5, 7);
    checkIndices(shuffleOrder1.indices, 5);
    shuffleOrder1.removeRange(0, 5);
    checkIndices(shuffleOrder1.indices, 0);

    shuffleOrder1.insert(0, 5);
    checkIndices(shuffleOrder1.indices, 5);
    shuffleOrder1.clear();
    checkIndices(shuffleOrder1.indices, 0);
  });

  test('shuffle', () async {
    AudioSource createSource() => ConcatenatingAudioSource(
          shuffleOrder: DefaultShuffleOrder(random: Random(1001)),
          children: [
            LoopingAudioSource(
              count: 2,
              child: ClippingAudioSource(
                start: const Duration(seconds: 60),
                end: const Duration(seconds: 65),
                child: AudioSource.uri(Uri.parse("https://foo.foo/foo.mp3")),
                tag: 'a',
              ),
            ),
            AudioSource.uri(
              Uri.parse("https://bar.bar/bar.mp3"),
              tag: 'b',
            ),
            AudioSource.uri(
              Uri.parse("https://baz.baz/baz.mp3"),
              tag: 'c',
            ),
            ClippingAudioSource(
              child: AudioSource.uri(
                Uri.parse("https://baz.baz/baz.mp3"),
                tag: 'd',
              ),
            ),
          ],
        );
    final source1 = createSource();
    //expect(source1.shuffleIndices, [4, 0, 1, 3, 2]);
    checkIndices(source1.shuffleIndices, 5);
    expect(source1.shuffleIndices.skipWhile((i) => i != 0).skip(1).first,
        equals(1));
    final player1 = AudioPlayer();
    await player1.setAudioSource(source1);
    checkIndices(player1.shuffleIndices!, 5);
    expect(player1.shuffleIndices!.first, equals(0));
    expect(player1.effectiveIndices!,
        List.generate(player1.sequence!.length, (i) => i));
    await player1.seek(Duration.zero, index: 3);
    await player1.shuffle();
    checkIndices(player1.shuffleIndices!, 5);
    expect(player1.shuffleIndices!.first, equals(3));
    expect(player1.effectiveIndices!,
        List.generate(player1.sequence!.length, (i) => i));
    await player1.setShuffleModeEnabled(true);
    expect(player1.effectiveIndices!, player1.shuffleIndices!);
    await player1.dispose();

    final source2 = createSource();
    final player2 = AudioPlayer();
    await player2.setAudioSource(source2, initialIndex: 3);
    checkIndices(player2.shuffleIndices!, 5);
    expect(player2.shuffleIndices!.first, equals(3));
    await player2.dispose();
  });

  test('seekToIndex', () async {
    final source = ConcatenatingAudioSource(
      shuffleOrder: DefaultShuffleOrder(random: Random(1001)),
      children: [
        AudioSource.uri(
          Uri.parse("https://bar.bar/foo.mp3"),
          tag: 'foo',
        ),
        AudioSource.uri(
          Uri.parse("https://baz.baz/bar.mp3"),
          tag: 'bar',
        ),
      ],
    );
    final player = AudioPlayer();
    await player.setAudioSource(source);
    expect(player.currentIndex, 0);
    expect(player.hasPrevious, false);
    expect(player.hasNext, true);
    await player.seekToPrevious();
    expect(player.currentIndex, 0);
    await player.seekToNext();
    expect(player.currentIndex, 1);
    expect(player.hasPrevious, true);
    expect(player.hasNext, false);
    await player.seekToNext();
    expect(player.currentIndex, 1);
    await player.seekToPrevious();
    expect(player.currentIndex, 0);
    await player.dispose();
  });

  test('stop', () async {
    final source = ConcatenatingAudioSource(
      shuffleOrder: DefaultShuffleOrder(random: Random(1001)),
      children: [
        AudioSource.uri(
          Uri.parse("https://bar.bar/foo.mp3"),
          tag: 'foo',
        ),
        AudioSource.uri(
          Uri.parse("https://baz.baz/bar.mp3"),
          tag: 'bar',
        ),
      ],
    );
    final player = AudioPlayer();
    expect(player.processingState, ProcessingState.idle);
    await player.setAudioSource(source, preload: false);
    expect(player.processingState, ProcessingState.idle);
    await player.load();
    expect(player.processingState, ProcessingState.ready);
    await player.seek(const Duration(seconds: 5), index: 1);
    await player.setVolume(0.5);
    await player.setSpeed(0.7);
    await player.setShuffleModeEnabled(true);
    await player.setLoopMode(LoopMode.one);
    await player.stop();
    expect(player.processingState, ProcessingState.idle);
    expect(player.position, const Duration(seconds: 5));
    expect(player.volume, 0.5);
    expect(player.speed, 0.7);
    expect(player.shuffleModeEnabled, true);
    expect(player.loopMode, LoopMode.one);
    await player.load();
    expect(player.processingState, ProcessingState.ready);
    expect(player.position, const Duration(seconds: 5));
    expect(player.volume, 0.5);
    expect(player.speed, 0.7);
    expect(player.shuffleModeEnabled, true);
    expect(player.loopMode, LoopMode.one);
    await player.dispose();
  });

  test('play-load', () async {
    for (var delayMs in [0, 100]) {
      final player = AudioPlayer();
      player.play();
      if (delayMs != 0) {
        await Future<dynamic>.delayed(Duration(milliseconds: delayMs));
      }
      expect(player.playing, equals(true));
      expect(player.processingState, equals(ProcessingState.idle));
      await player.setUrl('https://bar.bar/foo.mp3');
      expect(player.processingState, equals(ProcessingState.ready));
      expect(player.playing, equals(true));
      expectDuration(player.position, Duration.zero);
      await Future<dynamic>.delayed(const Duration(seconds: 1));
      expectDuration(player.position, const Duration(seconds: 1));
      await player.dispose();
    }
  });

  test('play-set', () async {
    for (var delayMs in [0, 100]) {
      final player = AudioPlayer();
      player.play();
      if (delayMs != 0) {
        await Future<dynamic>.delayed(Duration(milliseconds: delayMs));
      }
      expect(player.playing, equals(true));
      expect(player.processingState, equals(ProcessingState.idle));
      await player.setUrl('https://bar.bar/foo.mp3', preload: false);
      expect(player.processingState, equals(ProcessingState.ready));
      expect(player.playing, equals(true));
      expectDuration(player.position, Duration.zero);
      await Future<dynamic>.delayed(const Duration(seconds: 1));
      expectDuration(player.position, const Duration(seconds: 1));
      await player.dispose();
    }
  });

  test('set-play', () async {
    final player = AudioPlayer();
    await player.setUrl('https://bar.bar/foo.mp3', preload: false);
    expect(player.processingState, equals(ProcessingState.idle));
    expect(player.playing, equals(false));
    player.play();
    expect(player.playing, equals(true));
    await player.processingStateStream
        .firstWhere((state) => state == ProcessingState.ready);
    expect(player.processingState, equals(ProcessingState.ready));
    expect(player.playing, equals(true));
    expectDuration(player.position, Duration.zero);
    await Future<dynamic>.delayed(const Duration(seconds: 1));
    expectDuration(player.position, const Duration(seconds: 1));
    await player.dispose();
  });

  test('set-set', () async {
    final player = AudioPlayer();
    await player.setAudioSource(
      ConcatenatingAudioSource(
        children: [
          AudioSource.uri(Uri.parse('https://bar.bar/foo.mp3')),
          AudioSource.uri(Uri.parse('https://bar.bar/bar.mp3')),
        ],
      ),
      preload: false,
    );
    expect(player.processingState, equals(ProcessingState.idle));
    expect(player.sequence!.length, equals(2));
    expect(player.playing, equals(false));
    await player.setAudioSource(
      ConcatenatingAudioSource(
        children: [
          AudioSource.uri(Uri.parse('https://bar.bar/foo.mp3')),
          AudioSource.uri(Uri.parse('https://bar.bar/bar.mp3')),
          AudioSource.uri(Uri.parse('https://bar.bar/baz.mp3')),
        ],
      ),
      preload: false,
    );
    expect(player.processingState, equals(ProcessingState.idle));
    expect(player.sequence!.length, equals(3));
    expect(player.playing, equals(false));
    await player.dispose();
  });

  test('load-load', () async {
    final player = AudioPlayer();
    await player.setAudioSource(
      ConcatenatingAudioSource(
        children: [
          AudioSource.uri(Uri.parse('https://bar.bar/foo.mp3')),
          AudioSource.uri(Uri.parse('https://bar.bar/bar.mp3')),
        ],
      ),
    );
    expect(player.processingState, equals(ProcessingState.ready));
    expect(player.sequence!.length, equals(2));
    expect(player.playing, equals(false));
    await player.setAudioSource(
      ConcatenatingAudioSource(
        children: [
          AudioSource.uri(Uri.parse('https://bar.bar/foo.mp3')),
          AudioSource.uri(Uri.parse('https://bar.bar/bar.mp3')),
          AudioSource.uri(Uri.parse('https://bar.bar/baz.mp3')),
        ],
      ),
    );
    expect(player.processingState, equals(ProcessingState.ready));
    expect(player.sequence!.length, equals(3));
    expect(player.playing, equals(false));
    await player.dispose();
  });

  test('load-set-load', () async {
    final player = AudioPlayer();
    await player.setAudioSource(
      ConcatenatingAudioSource(
        children: [
          AudioSource.uri(Uri.parse('https://bar.bar/foo.mp3')),
          AudioSource.uri(Uri.parse('https://bar.bar/bar.mp3')),
        ],
      ),
    );
    expect(player.processingState, equals(ProcessingState.ready));
    expect(player.sequence!.length, equals(2));
    expect(player.playing, equals(false));
    await player.setAudioSource(
      ConcatenatingAudioSource(
        children: [
          AudioSource.uri(Uri.parse('https://bar.bar/foo.mp3')),
          AudioSource.uri(Uri.parse('https://bar.bar/bar.mp3')),
          AudioSource.uri(Uri.parse('https://bar.bar/baz.mp3')),
        ],
      ),
      preload: false,
    );
    expect(player.processingState, equals(ProcessingState.idle));
    expect(player.sequence!.length, equals(3));
    expect(player.playing, equals(false));
    await player.load();
    expect(player.processingState, equals(ProcessingState.ready));
    expect(player.sequence!.length, equals(3));
    expect(player.playing, equals(false));
    await player.dispose();
  });

  test('play-load-load', () async {
    final player = AudioPlayer();
    player.play();
    await player.setUrl('https://bar.bar/foo.mp3');
    expect(player.processingState, equals(ProcessingState.ready));
    expect(player.playing, equals(true));
    expectDuration(player.position, const Duration(seconds: 0));
    await Future<dynamic>.delayed(const Duration(seconds: 1));
    expectDuration(player.position, const Duration(seconds: 1));
    await player.setUrl('https://bar.bar/bar.mp3');
    expect(player.processingState, equals(ProcessingState.ready));
    expect(player.playing, equals(true));
    expectDuration(player.position, const Duration(seconds: 0));
    await Future<dynamic>.delayed(const Duration(seconds: 1));
    expectDuration(player.position, const Duration(seconds: 1));
    await player.dispose();
  });

  test('play-load-set-play-load', () async {
    final player = AudioPlayer();
    player.play();
    await player.setUrl('https://bar.bar/foo.mp3');
    expect(player.processingState, equals(ProcessingState.ready));
    expect(player.playing, equals(true));
    expectDuration(player.position, const Duration(seconds: 0));
    await Future<dynamic>.delayed(const Duration(seconds: 1));
    expectDuration(player.position, const Duration(seconds: 1));
    player.pause();
    expect(player.playing, equals(false));
    await player.setUrl('https://bar.bar/bar.mp3', preload: false);
    expect(player.processingState, equals(ProcessingState.idle));
    expect(player.playing, equals(false));
    expectDuration(player.position, Duration.zero);
    await player.load();
    expect(player.processingState, equals(ProcessingState.ready));
    expect(player.playing, equals(false));
    expectDuration(player.position, const Duration(seconds: 0));
    player.play();
    expect(player.playing, equals(true));
    expectDuration(player.position, const Duration(seconds: 0));
    await Future<dynamic>.delayed(const Duration(seconds: 1));
    expectDuration(player.position, const Duration(seconds: 1));
    await player.dispose();
  });

  test('quick-reactivate', () async {
    final player = AudioPlayer();
    await player.setUrl('https://bar.bar/foo.mp3');
    player.stop();
    await player.setUrl('https://bar.bar/foo.mp3');
    await player.dispose();
  });

  test('play-pause', () async {
    final player = AudioPlayer();
    await player.setUrl('https://bar.bar/foo.mp3');
    player.play();
    await player.pause();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(mock.mostRecentPlayer?._playing, false);
    await player.dispose();
  });

  test('play-stop', () async {
    final player = AudioPlayer();
    await player.setUrl('https://bar.bar/foo.mp3');
    player.play();
    await player.stop();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(mock.mostRecentPlayer?._playing, false);
    await player.dispose();
  });

  test('positionStream emissions: seek while paused', () async {
    final player = AudioPlayer();
    await player.setUrl('https://bar.bar/foo.mp3');
    expectState(
      player: player,
      position: Duration.zero,
      processingState: ProcessingState.ready,
      playing: false,
    );
    var completer = Completer<dynamic>();
    late StreamSubscription subscription;
    subscription = player.positionStream.listen((position) {
      expectDuration(position, Duration.zero);
      subscription.cancel();
      completer.complete();
    });
    await completer.future;

    const duration1 = Duration(seconds: 1);
    const duration2 = Duration(milliseconds: 600);
    const duration3 = Duration(milliseconds: 750);

    await player.seek(duration1);
    expectState(
      player: player,
      position: duration1,
      processingState: ProcessingState.ready,
      playing: false,
    );
    completer = Completer<dynamic>();
    subscription = player.positionStream.listen((position) {
      expectDuration(position, duration1);
      subscription.cancel();
      completer.complete();
    });
    await completer.future;

    player.play();
    await Future<dynamic>.delayed(duration2);
    expectState(
      player: player,
      position: duration1 + duration2,
      processingState: ProcessingState.ready,
      playing: true,
    );
    await player.pause();
    completer = Completer<dynamic>();
    subscription = player.positionStream.listen((position) {
      expectDuration(position, duration1 + duration2);
      subscription.cancel();
      completer.complete();
    });
    await completer.future;

    await player.seek(duration1 + duration2 + duration3);
    expectState(
      player: player,
      position: duration1 + duration2 + duration3,
      processingState: ProcessingState.ready,
      playing: false,
    );
    completer = Completer<dynamic>();
    subscription = player.positionStream.listen((position) {
      expectDuration(position, duration1 + duration2 + duration3);
      subscription.cancel();
      completer.complete();
    });
    await completer.future;

    await player.dispose();
  });

  test('positionStream emissions: switch audio sources', () async {
    final player = AudioPlayer();
    final playlist = ConcatenatingAudioSource(
      children: [
        AudioSource.uri(Uri.parse('https://bar.bar/foo.mp3')),
        AudioSource.uri(Uri.parse('https://bar.bar/bar.mp3')),
      ],
    );
    await player.setAudioSource(playlist);
    expectState(
      player: player,
      position: Duration.zero,
      processingState: ProcessingState.ready,
      playing: false,
    );
    expect(player.currentIndex, 0);
    var completer = Completer<dynamic>();
    late StreamSubscription subscription;
    subscription = player.positionStream.listen((position) {
      expectDuration(position, Duration.zero);
      subscription.cancel();
      completer.complete();
    });
    await completer.future;

    const duration1 = Duration(seconds: 1);
    const duration2 = Duration(seconds: 600);

    await player.seek(duration1);
    expect(player.currentIndex, 0);
    completer = Completer<dynamic>();
    subscription = player.positionStream.listen((position) {
      expectDuration(position, duration1);
      subscription.cancel();
      completer.complete();
    });
    await completer.future;

    await player.seekToNext();
    expect(player.currentIndex, 1);
    completer = Completer<dynamic>();
    subscription = player.positionStream.listen((position) {
      expectDuration(position, Duration.zero);
      subscription.cancel();
      completer.complete();
    });
    await completer.future;

    await player.seek(duration1, index: 1);
    expect(player.currentIndex, 1);
    await player.seekToNext();
    // There is no next
    expect(player.currentIndex, 1);
    completer = Completer<dynamic>();
    subscription = player.positionStream.listen((position) {
      // No position change because there is no next
      expectDuration(position, duration1);
      subscription.cancel();
      completer.complete();
    });
    await completer.future;

    // Switch to index 0 and seek position at the same time
    await player.seek(duration2, index: 0);
    expect(player.currentIndex, 0);
    completer = Completer<dynamic>();
    subscription = player.positionStream.listen((position) {
      expectDuration(position, duration2);
      subscription.cancel();
      completer.complete();
    });
    await completer.future;

    await player.dispose();
  });

  test('positionDiscontinuity', () async {
    final player = AudioPlayer();
    final discontinuityEvents = <PositionDiscontinuity>[];
    final subscription =
        player.positionDiscontinuityStream.listen(discontinuityEvents.add);
    final playlist = ConcatenatingAudioSource(children: [
      AudioSource.uri(
        Uri.parse("https://bar.bar/bar.mp3"),
        tag: 'a',
      ),
      AudioSource.uri(
        Uri.parse("https://baz.baz/baz.mp3"),
        tag: 'b',
      ),
    ]);
    await player.setAudioSource(playlist);
    expect(player.currentIndex, equals(0));
    expect(discontinuityEvents.length, equals(0));
    player.play();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(discontinuityEvents.length, equals(0));
    for (var mockPlayer in mock._players.values) {
      await mockPlayer._autoAdvance();
    }
    expect(player.currentIndex, equals(1));
    expect(
        discontinuityEvents.length == 1 &&
            discontinuityEvents.first.reason ==
                PositionDiscontinuityReason.autoAdvance,
        equals(true));
    discontinuityEvents.clear();
    await player.seek(Duration.zero, index: 0);
    expect(player.currentIndex, equals(0));
    expect(
        discontinuityEvents.length == 1 &&
            discontinuityEvents.first.reason ==
                PositionDiscontinuityReason.seek,
        equals(true));
    discontinuityEvents.clear();
    // Test loop one
    await player.setLoopMode(LoopMode.one);
    await player.seek(const Duration(seconds: 119));
    discontinuityEvents.clear();
    for (var mockPlayer in mock._players.values) {
      await mockPlayer._autoAdvance();
    }
    expect(player.currentIndex, equals(0));
    expect(
        discontinuityEvents.length == 1 &&
            discontinuityEvents.first.reason ==
                PositionDiscontinuityReason.autoAdvance,
        equals(true));
    discontinuityEvents.clear();

    await player.dispose();
    subscription.cancel();
  });

  test('loadConfiguration', () async {
    final audioLoadConfiguration = AudioLoadConfiguration(
      darwinLoadControl: DarwinLoadControl(),
      androidLoadControl: AndroidLoadControl(),
      androidLivePlaybackSpeedControl: AndroidLivePlaybackSpeedControl(),
    );
    final player = AudioPlayer(
      audioLoadConfiguration: audioLoadConfiguration,
    );
    await player.setUrl('https://foo.foo/foo.mp3');
    final platformPlayer = mock.mostRecentPlayer!;
    expect(
        platformPlayer.audioLoadConfiguration?.darwinLoadControl
            ?.automaticallyWaitsToMinimizeStalling,
        equals(audioLoadConfiguration
            .darwinLoadControl?.automaticallyWaitsToMinimizeStalling));
    // TODO: check other fields.
    await player.dispose();
  });

  test('AndroidLoudnessEnhancer', () async {
    final loudnessEnhancer = AndroidLoudnessEnhancer();
    final player = AudioPlayer(
      audioPipeline: AudioPipeline(androidAudioEffects: [loudnessEnhancer]),
    );
    expect(loudnessEnhancer.targetGain, equals(0.0));
    expect(await loudnessEnhancer.targetGainStream.first, equals(0.0));
    await player.setUrl('https://foo.foo/foo.mp3');
    expect(loudnessEnhancer.targetGain, equals(0.0));
    expect(await loudnessEnhancer.targetGainStream.first, equals(0.0));
    await loudnessEnhancer.setTargetGain(1.5);
    expect(loudnessEnhancer.targetGain, equals(1.5));
    expect(await loudnessEnhancer.targetGainStream.first, equals(1.5));
    expect(loudnessEnhancer.enabled, equals(false));
    expect(await loudnessEnhancer.enabledStream.first, equals(false));
    await loudnessEnhancer.setEnabled(true);
    expect(loudnessEnhancer.enabled, equals(true));
    expect(await loudnessEnhancer.enabledStream.first, equals(true));
  });

  test('AndroidEqualizer', () async {
    final equalizer = AndroidEqualizer();
    final player = AudioPlayer(
      audioPipeline: AudioPipeline(androidAudioEffects: [equalizer]),
    );
    expect(equalizer.enabled, equals(false));
    expect(await equalizer.enabledStream.first, equals(false));
    await player.setUrl('https://foo.foo/foo.mp3');
    expect(equalizer.enabled, equals(false));
    expect(await equalizer.enabledStream.first, equals(false));
    await equalizer.setEnabled(true);
    expect(equalizer.enabled, equals(true));
    expect(await equalizer.enabledStream.first, equals(true));
    final parameters = await equalizer.parameters;
    expect(parameters.minDecibels, equals(0.0));
    expect(parameters.maxDecibels, equals(10.0));
    final bands = parameters.bands;
    expect(bands.length, equals(5));
    for (var i = 0; i < 5; i++) {
      final band = bands[i];
      expect(band.index, equals(i));
      expect(band.lowerFrequency, equals(i * 1000));
      expect(band.upperFrequency, equals((i + 1) * 1000));
      expect(band.centerFrequency, equals((i + 0.5) * 1000));
      expect(band.gain, equals(i * 0.1));
    }
  });
}

class MockJustAudio extends Mock
    with MockPlatformInterfaceMixin
    implements JustAudioPlatform {
  MockAudioPlayer? mostRecentPlayer;
  final _players = <String, MockAudioPlayer>{};

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    if (_players.containsKey(request.id)) {
      throw PlatformException(
          code: "error",
          message: "Platform player ${request.id} already exists");
    }
    final player = MockAudioPlayer(request);
    _players[request.id] = player;
    mostRecentPlayer = player;
    return player;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
      DisposePlayerRequest request) async {
    _players[request.id]!.dispose(DisposeRequest());
    _players.remove(request.id);
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
      DisposeAllPlayersRequest request) async {
    for (var player in _players.values) {
      player.dispose(DisposeRequest());
    }
    _players.clear();
    return DisposeAllPlayersResponse();
  }
}

const audioSourceDuration = Duration(minutes: 2);

final icyMetadata = IcyMetadata(
  headers: IcyHeaders(
    url: 'url',
    genre: 'Genre',
    metadataInterval: 3,
    bitrate: 100,
    isPublic: true,
    name: 'name',
  ),
  info: IcyInfo(
    title: 'title',
    url: 'url',
  ),
);

final icyMetadataMessage = IcyMetadataMessage(
  headers: IcyHeadersMessage(
    url: 'url',
    genre: 'Genre',
    metadataInterval: 3,
    bitrate: 100,
    isPublic: true,
    name: 'name',
  ),
  info: IcyInfoMessage(
    title: 'title',
    url: 'url',
  ),
);

class MockAudioPlayer extends AudioPlayerPlatform {
  final eventController = StreamController<PlaybackEventMessage>();
  final AudioLoadConfigurationMessage? audioLoadConfiguration;
  AudioSourceMessage? _audioSource;
  ProcessingStateMessage _processingState = ProcessingStateMessage.idle;
  Duration _updatePosition = Duration.zero;
  DateTime _updateTime = DateTime.now();
  // ignore: prefer_final_fields
  Duration? _duration;
  int? _index;
  var _playing = false;
  var _speed = 1.0;
  Completer<dynamic>? _playCompleter;
  Timer? _playTimer;
  LoopModeMessage _loopMode = LoopModeMessage.off;

  MockAudioPlayer(InitRequest request)
      : audioLoadConfiguration = request.audioLoadConfiguration,
        super(request.id);

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream =>
      StreamController<PlayerDataMessage>().stream;

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      eventController.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    final audioSource = request.audioSourceMessage;
    _processingState = ProcessingStateMessage.loading;
    _broadcastPlaybackEvent();
    if (audioSource is UriAudioSourceMessage) {
      if (audioSource.uri.contains('abort')) {
        throw PlatformException(code: 'abort', message: 'Failed to load URL');
      } else if (audioSource.uri.contains('404')) {
        throw PlatformException(code: '404', message: 'Not found');
      } else if (audioSource.uri.contains('error')) {
        throw PlatformException(code: 'error', message: 'Unknown error');
      }
      _duration = audioSourceDuration;
    } else if (audioSource is ClippingAudioSourceMessage) {
      _duration = (audioSource.end ?? audioSourceDuration) -
          (audioSource.start ?? Duration.zero);
    } else {
      // TODO: pull the sequence out of the audio source and return the duration
      // of the first item in the sequence.
      _duration = audioSourceDuration;
    }
    _audioSource = audioSource;
    _index = request.initialIndex ?? 0;
    // Simulate loading time.
    await Future<dynamic>.delayed(const Duration(milliseconds: 100));
    _setPosition(request.initialPosition ?? Duration.zero);
    _processingState = ProcessingStateMessage.ready;
    _broadcastPlaybackEvent();
    if (_playing) {
      _startTimer();
    }
    return LoadResponse(duration: _duration);
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    if (_playing) return PlayResponse();
    _playing = true;
    if (_duration != null) {
      _startTimer();
    }
    _playCompleter = Completer<dynamic>();
    await _playCompleter!.future;
    return PlayResponse();
  }

  void _startTimer() {
    _playTimer = Timer(_remaining, () {
      _setPosition(_position);
      _processingState = ProcessingStateMessage.completed;
      _broadcastPlaybackEvent();
      _playCompleter?.complete();
    });
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    if (!_playing) return PauseResponse();
    _playing = false;
    _playTimer?.cancel();
    _playCompleter?.complete();
    _setPosition(_position);
    _broadcastPlaybackEvent();
    return PauseResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    _setPosition(request.position ?? Duration.zero);
    _index = request.index ?? 0;
    _broadcastPlaybackEvent();
    return SeekResponse();
  }

  Future<void> _autoAdvance() async {
    _setPosition(Duration.zero);
    if (_loopMode == LoopModeMessage.off) {
      _index = _index! + 1;
    }
    _broadcastPlaybackEvent();
  }

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
      SetAndroidAudioAttributesRequest request) async {
    return SetAndroidAudioAttributesResponse();
  }

  @override
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse>
      setAutomaticallyWaitsToMinimizeStalling(
          SetAutomaticallyWaitsToMinimizeStallingRequest request) async {
    return SetAutomaticallyWaitsToMinimizeStallingResponse();
  }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async {
    _loopMode = request.loopMode;
    return SetLoopModeResponse();
  }

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
      SetShuffleModeRequest request) async {
    return SetShuffleModeResponse();
  }

  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(
      SetShuffleOrderRequest request) async {
    return SetShuffleOrderResponse();
  }

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async {
    _speed = request.speed;
    _setPosition(_position);
    return SetSpeedResponse();
  }

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async {
    return SetPitchResponse();
  }

  @override
  Future<SetSkipSilenceResponse> setSkipSilence(
      SetSkipSilenceRequest request) async {
    return SetSkipSilenceResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async {
    return SetVolumeResponse();
  }

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    _processingState = ProcessingStateMessage.idle;
    _broadcastPlaybackEvent();
    return DisposeResponse();
  }

  @override
  Future<ConcatenatingInsertAllResponse> concatenatingInsertAll(
      ConcatenatingInsertAllRequest request) async {
    // TODO
    return ConcatenatingInsertAllResponse();
  }

  @override
  Future<ConcatenatingMoveResponse> concatenatingMove(
      ConcatenatingMoveRequest request) async {
    // TODO
    return ConcatenatingMoveResponse();
  }

  @override
  Future<ConcatenatingRemoveRangeResponse> concatenatingRemoveRange(
      ConcatenatingRemoveRangeRequest request) async {
    // TODO
    return ConcatenatingRemoveRangeResponse();
  }

  void _broadcastPlaybackEvent() {
    String? url;
    if (_audioSource is UriAudioSourceMessage) {
      // Not sure why this cast is necessary...
      url = (_audioSource as UriAudioSourceMessage).uri.toString();
    }
    eventController.add(PlaybackEventMessage(
      processingState: _processingState,
      updatePosition: _updatePosition,
      updateTime: _updateTime,
      bufferedPosition: _position,
      icyMetadata: IcyMetadataMessage(
        headers: IcyHeadersMessage(
          url: url,
          genre: 'Genre',
          metadataInterval: 3,
          bitrate: 100,
          isPublic: true,
          name: 'name',
        ),
        info: IcyInfoMessage(
          title: 'title',
          url: url,
        ),
      ),
      duration: _duration,
      currentIndex: _index,
      androidAudioSessionId: null,
    ));
  }

  Duration get _position {
    if (_playing && _processingState == ProcessingStateMessage.ready) {
      final result =
          _updatePosition + (DateTime.now().difference(_updateTime)) * _speed;
      return result <= _duration! ? result : _duration!;
    } else {
      return _updatePosition;
    }
  }

  Duration get _remaining => (_duration! - _position) * (1 / _speed);

  void _setPosition(Duration position) {
    _updatePosition = position;
    _updateTime = DateTime.now();
  }

  @override
  Future<SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse>
      setCanUseNetworkResourcesForLiveStreamingWhilePaused(
          SetCanUseNetworkResourcesForLiveStreamingWhilePausedRequest
              request) async {
    return SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse();
  }

  @override
  Future<SetPreferredPeakBitRateResponse> setPreferredPeakBitRate(
      SetPreferredPeakBitRateRequest request) async {
    return SetPreferredPeakBitRateResponse();
  }

  @override
  Future<AudioEffectSetEnabledResponse> audioEffectSetEnabled(
      AudioEffectSetEnabledRequest request) async {
    return AudioEffectSetEnabledResponse();
  }

  @override
  Future<AndroidLoudnessEnhancerSetTargetGainResponse>
      androidLoudnessEnhancerSetTargetGain(
          AndroidLoudnessEnhancerSetTargetGainRequest request) async {
    return AndroidLoudnessEnhancerSetTargetGainResponse();
  }

  @override
  Future<AndroidEqualizerGetParametersResponse> androidEqualizerGetParameters(
      AndroidEqualizerGetParametersRequest request) async {
    return AndroidEqualizerGetParametersResponse(
      parameters: AndroidEqualizerParametersMessage(
        minDecibels: 0.0,
        maxDecibels: 10.0,
        bands: [
          for (var i = 0; i < 5; i++)
            AndroidEqualizerBandMessage(
              index: i,
              lowerFrequency: i * 1000,
              upperFrequency: (i + 1) * 1000,
              centerFrequency: (i + 0.5) * 1000,
              gain: i * 0.1,
            ),
        ],
      ),
    );
  }

  @override
  Future<AndroidEqualizerBandSetGainResponse> androidEqualizerBandSetGain(
      AndroidEqualizerBandSetGainRequest request) async {
    return AndroidEqualizerBandSetGainResponse();
  }
}

final byteRangeData = List.generate(200, (i) => i);

class TestStreamAudioSource extends StreamAudioSource {
  TestStreamAudioSource({dynamic tag}) : super(tag: tag);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    return StreamAudioResponse(
      contentType: 'audio/mock',
      stream: Stream.value(byteRangeData.sublist(start ?? 0, end)),
      contentLength: (end ?? byteRangeData.length) - (start ?? 0),
      offset: start ?? 0,
      sourceLength: byteRangeData.length,
    );
  }
}

class MockWebServer {
  late HttpServer _server;
  int get port => _server.port;

  Future start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) async {
      final response = request.response;
      if (request.uri.path == '/proxy0.9/foo.mp3') {
        final body = utf8.encode('Hello');
        final clientSocket =
            await request.response.detachSocket(writeHeaders: false);
        clientSocket.add(body);
        await clientSocket.flush();
        await clientSocket.close();
      } else {
        final body = utf8.encode('Hello');
        response.contentLength = body.length;
        response.statusCode = HttpStatus.ok;
        response.headers.set(HttpHeaders.contentTypeHeader, 'audio/mock');
        response.add(body);
        await response.flush();
        await response.close();
      }
    });
  }

  Future stop() => _server.close();
}

class MyHttpOverrides extends HttpOverrides {}

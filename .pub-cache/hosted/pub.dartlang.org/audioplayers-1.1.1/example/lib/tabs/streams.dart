import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_example/components/btn.dart';
import 'package:audioplayers_example/components/pad.dart';
import 'package:audioplayers_example/components/player_widget.dart';
import 'package:audioplayers_example/components/tab_wrapper.dart';
import 'package:flutter/material.dart';

class StreamsTab extends StatefulWidget {
  final AudioPlayer player;

  const StreamsTab({Key? key, required this.player}) : super(key: key);

  @override
  State<StreamsTab> createState() => _StreamsTabState();
}

class _StreamsTabState extends State<StreamsTab>
    with AutomaticKeepAliveClientMixin<StreamsTab> {
  Duration? position, duration;
  PlayerState? state;
  late List<StreamSubscription> streams;

  Duration? streamDuration, streamPosition;
  PlayerState? streamState;

  @override
  void initState() {
    super.initState();
    streams = <StreamSubscription>[
      widget.player.onDurationChanged
          .listen((it) => setState(() => streamDuration = it)),
      widget.player.onPlayerStateChanged
          .listen((it) => setState(() => streamState = it)),
      widget.player.onPositionChanged
          .listen((it) => setState(() => streamPosition = it)),
    ];
  }

  @override
  void setState(VoidCallback fn) {
    // Subscriptions only can be closed asynchronously,
    // therefore events can occur after widget has been disposed.
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    super.dispose();
    streams.forEach((it) => it.cancel());
  }

  Future<void> getPosition() async {
    final position = await widget.player.getCurrentPosition();
    setState(() => this.position = position);
  }

  Future<void> getDuration() async {
    final duration = await widget.player.getDuration();
    setState(() => this.duration = duration);
  }

  Future<void> getPlayerState() async {
    setState(() => state = widget.player.state);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return TabWrapper(
      children: [
        Row(
          children: [
            Btn(
              key: const Key('getDuration'),
              txt: 'Get Duration',
              onPressed: getDuration,
            ),
            const Pad(width: 8.0),
            Text(
              duration?.toString() ?? '-',
              key: const Key('durationText'),
            ),
          ],
        ),
        Row(
          children: [
            Btn(
              key: const Key('getPosition'),
              txt: 'Get Position',
              onPressed: getPosition,
            ),
            const Pad(width: 8.0),
            Text(
              position?.toString() ?? '-',
              key: const Key('positionText'),
            ),
          ],
        ),
        Row(
          children: [
            Btn(
              key: const Key('getPlayerState'),
              txt: 'Get State',
              onPressed: getPlayerState,
            ),
            const Pad(width: 8.0),
            Text(
              state?.toString() ?? '-',
              key: const Key('playerStateText'),
            ),
          ],
        ),
        const Divider(color: Colors.black),
        const Text('Streams'),
        Text(
          'Stream Duration: $streamDuration',
          key: const Key('onDurationText'),
        ),
        Text(
          'Stream Position: $streamPosition',
          key: const Key('onPositionText'),
        ),
        Text(
          'Stream State: $streamState',
          key: const Key('onStateText'),
        ),
        const Divider(color: Colors.black),
        PlayerWidget(player: widget.player),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

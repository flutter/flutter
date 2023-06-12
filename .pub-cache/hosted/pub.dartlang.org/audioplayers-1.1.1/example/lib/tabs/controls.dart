import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_example/components/btn.dart';
import 'package:audioplayers_example/components/tab_wrapper.dart';
import 'package:audioplayers_example/components/tgl.dart';
import 'package:audioplayers_example/components/txt.dart';
import 'package:audioplayers_example/utils.dart';
import 'package:flutter/material.dart';

class ControlsTab extends StatefulWidget {
  final AudioPlayer player;

  const ControlsTab({Key? key, required this.player}) : super(key: key);

  @override
  State<ControlsTab> createState() => _ControlsTabState();
}

class _ControlsTabState extends State<ControlsTab>
    with AutomaticKeepAliveClientMixin<ControlsTab> {
  String modalInputSeek = '';

  Future<void> _update(Future<void> Function() fn) async {
    await fn();
    // update everyone who listens to "player"
    setState(() {});
  }

  Future<void> _seekPercent(double percent) async {
    final duration = await widget.player.getDuration();
    if (duration == null) {
      toast(
        'Failed to get duration for proportional seek.',
        textKey: const Key('toast-proportional-seek-duration-null'),
      );
      return;
    }
    final position = duration * percent;
    _seekDuration(position);
  }

  Future<void> _seekDuration(Duration duration) async {
    await _update(() => widget.player.seek(duration));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return TabWrapper(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Btn(
              key: const Key('control-pause'),
              txt: 'Pause',
              onPressed: widget.player.pause,
            ),
            Btn(
              key: const Key('control-stop'),
              txt: 'Stop',
              onPressed: widget.player.stop,
            ),
            Btn(
              key: const Key('control-resume'),
              txt: 'Resume',
              onPressed: widget.player.resume,
            ),
            Btn(
              key: const Key('control-release'),
              txt: 'Release',
              onPressed: widget.player.release,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Volume'),
            ...[0.0, 0.5, 1.0, 2.0].map((it) {
              final formattedVal = it.toStringAsFixed(1);
              return Btn(
                key: Key('control-volume-$formattedVal'),
                txt: formattedVal,
                onPressed: () => widget.player.setVolume(it),
              );
            }),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Balance'),
            ...[-1.0, -0.5, 0.0, 1.0].map((it) {
              final formattedVal = it.toStringAsFixed(1);
              return Btn(
                key: Key('control-balance-$formattedVal'),
                txt: formattedVal,
                onPressed: () => widget.player.setBalance(it),
              );
            }),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Rate'),
            ...[0.0, 0.5, 1.0, 2.0].map((it) {
              final formattedVal = it.toStringAsFixed(1);
              return Btn(
                key: Key('control-rate-$formattedVal'),
                txt: formattedVal,
                onPressed: () => widget.player.setPlaybackRate(it),
              );
            }),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Player Mode'),
            EnumTgl<PlayerMode>(
              key: const Key('control-player-mode'),
              options: {
                for (var e in PlayerMode.values)
                  'control-player-mode-${e.name}': e
              },
              selected: widget.player.mode,
              onChange: (playerMode) async {
                await _update(() => widget.player.setPlayerMode(playerMode));
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Release Mode'),
            EnumTgl<ReleaseMode>(
              key: const Key('control-release-mode'),
              options: {
                for (var e in ReleaseMode.values)
                  'control-release-mode-${e.name}': e
              },
              selected: widget.player.releaseMode,
              onChange: (releaseMode) async {
                await _update(() => widget.player.setReleaseMode(releaseMode));
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Seek'),
            ...[0.0, 0.5, 1.0].map((it) {
              final formattedVal = it.toStringAsFixed(1);
              return Btn(
                key: Key('control-seek-$formattedVal'),
                txt: formattedVal,
                onPressed: () => _seekPercent(it),
              );
            }),
            Btn(
              txt: 'Custom',
              onPressed: () async {
                dialog([
                  const Text('Pick a duration and unit to seek'),
                  TxtBox(
                    value: modalInputSeek,
                    onChange: (it) => setState(() => modalInputSeek = it),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Btn(
                        txt: 'millis',
                        onPressed: () {
                          Navigator.of(context).pop();
                          _seekDuration(
                            Duration(
                              milliseconds: int.parse(modalInputSeek),
                            ),
                          );
                        },
                      ),
                      Btn(
                        txt: 'seconds',
                        onPressed: () {
                          Navigator.of(context).pop();
                          _seekDuration(
                            Duration(
                              seconds: int.parse(modalInputSeek),
                            ),
                          );
                        },
                      ),
                      Btn(
                        txt: '%',
                        onPressed: () {
                          Navigator.of(context).pop();
                          _seekPercent(double.parse(modalInputSeek));
                        },
                      ),
                      Btn(
                        txt: 'Cancel',
                        onPressed: Navigator.of(context).pop,
                      ),
                    ],
                  ),
                ]);
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

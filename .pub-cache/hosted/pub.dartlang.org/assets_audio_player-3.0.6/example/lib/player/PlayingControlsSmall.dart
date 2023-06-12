import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

import '../asset_audio_player_icons.dart';

class PlayingControlsSmall extends StatelessWidget {
  final bool isPlaying;
  final LoopMode loopMode;
  final Function() onPlay;
  final Function()? onStop;
  final Function()? toggleLoop;

  PlayingControlsSmall({
    required this.isPlaying,
    required this.loopMode,
    this.toggleLoop,
    required this.onPlay,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        NeumorphicRadio(
          style: NeumorphicRadioStyle(
            boxShape: NeumorphicBoxShape.circle(),
          ),
          padding: EdgeInsets.all(12),
          value: LoopMode.playlist,
          groupValue: loopMode,
          onChanged: (newValue) {
            if (toggleLoop != null) toggleLoop!();
          },
          child: Icon(
            Icons.loop,
            size: 18,
          ),
        ),
        SizedBox(
          width: 12,
        ),
        NeumorphicButton(
          style: NeumorphicStyle(
            boxShape: NeumorphicBoxShape.circle(),
          ),
          padding: EdgeInsets.all(16),
          onPressed: onPlay,
          child: Icon(
            isPlaying
                ? AssetAudioPlayerIcons.pause
                : AssetAudioPlayerIcons.play,
            size: 32,
          ),
        ),
        if (onStop != null)
          NeumorphicButton(
            style: NeumorphicStyle(
              boxShape: NeumorphicBoxShape.circle(),
            ),
            padding: EdgeInsets.all(16),
            onPressed: onPlay,
            child: Icon(
              AssetAudioPlayerIcons.stop,
              size: 32,
            ),
          ),
      ],
    );
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_example/components/btn.dart';
import 'package:audioplayers_example/components/cbx.dart';
import 'package:audioplayers_example/components/tab_wrapper.dart';
import 'package:audioplayers_example/components/tabs.dart';
import 'package:flutter/material.dart';

class AudioContextTab extends StatefulWidget {
  final AudioPlayer player;

  const AudioContextTab({Key? key, required this.player}) : super(key: key);

  @override
  _AudioContextTabState createState() => _AudioContextTabState();
}

class _AudioContextTabState extends State<AudioContextTab>
    with AutomaticKeepAliveClientMixin<AudioContextTab> {
  static GlobalPlatformInterface get _global => AudioPlayer.global;

  AudioContextConfig config = AudioContextConfig();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return TabWrapper(
      children: [
        const Text('Audio Context'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Btn(
              txt: 'Reset',
              onPressed: () => updateConfig(AudioContextConfig()),
            ),
            Btn(
              txt: 'Global',
              onPressed: () => _global.setGlobalAudioContext(config.build()),
            ),
            Btn(
              txt: 'Local',
              onPressed: () => widget.player.setAudioContext(config.build()),
            )
          ],
        ),
        Container(
          height: 500,
          child: Tabs(
            tabs: [
              TabData(
                key: 'contextTab-genericFlags',
                label: 'Generic Flags',
                content: _genericTab(),
              ),
              TabData(
                key: 'contextTab-android',
                label: 'Android',
                content: _androidTab(),
              ),
              TabData(
                key: 'contextTab-ios',
                label: 'iOS',
                content: _iosTab(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void updateConfig(AudioContextConfig newConfig) {
    setState(() => config = newConfig);
  }

  Widget _genericTab() {
    return Column(
      children: [
        Cbx(
          'Force Speaker',
          config.forceSpeaker,
          (v) => updateConfig(config.copy(forceSpeaker: v)),
        ),
        Cbx(
          'Duck Audio',
          config.duckAudio,
          (v) => updateConfig(config.copy(duckAudio: v)),
        ),
        Cbx(
          'Respect Silence',
          config.respectSilence,
          (v) => updateConfig(config.copy(respectSilence: v)),
        ),
        Cbx(
          'Stay Awake',
          config.stayAwake,
          (v) => updateConfig(config.copy(stayAwake: v)),
        ),
      ],
    );
  }

  Widget _androidTab() {
    final a = config.buildAndroid();
    return Column(
      children: [
        Text('isSpeakerphoneOn: ${a.isSpeakerphoneOn}'),
        Text('stayAwake: ${a.stayAwake}'),
        Text('contentType: ${a.contentType}'),
        Text('usageType: ${a.usageType}'),
        Text('audioFocus: ${a.audioFocus}'),
      ],
    );
  }

  Widget _iosTab() {
    final i = config.buildIOS();
    return Column(
      children: [
        Text('defaultToSpeaker: ${i.defaultToSpeaker}'),
        Text('category: ${i.category}'),
        Text('options: ${i.options}'),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

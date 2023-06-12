import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_example/components/btn.dart';
import 'package:audioplayers_example/components/tab_wrapper.dart';
import 'package:audioplayers_example/components/tgl.dart';
import 'package:audioplayers_example/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

const _wavUrl1 = 'https://luan.xyz/files/audio/coins.wav';
const _wavUrl2 = 'https://luan.xyz/files/audio/laser.wav';
const _mp3Url1 = 'https://luan.xyz/files/audio/ambient_c_motion.mp3';
const _mp3Url2 = 'https://luan.xyz/files/audio/nasa_on_a_mission.mp3';
const _m3u8StreamUrl =
    'https://a.files.bbci.co.uk/media/live/manifesto/audio/simulcast/hls/nonuk/sbr_low/ak/bbc_radio_one.m3u8';
const _mpgaStreamUrl = 'https://timesradio.wireless.radio/stream';

const _asset1 = 'laser.wav';
const _asset2 = 'nasa_on_a_mission.mp3';

class SourcesTab extends StatefulWidget {
  final AudioPlayer player;

  const SourcesTab({Key? key, required this.player}) : super(key: key);

  @override
  State<SourcesTab> createState() => _SourcesTabState();
}

enum InitMode {
  setSource,
  play,
}

class _SourcesTabState extends State<SourcesTab>
    with AutomaticKeepAliveClientMixin<SourcesTab> {
  Future<void> setSource(Source source) async {
    if (initMode == InitMode.setSource) {
      await widget.player.setSource(source);
      toast(
        'Completed setting source.',
        textKey: const Key('toast-source-set'),
      );
    } else {
      await widget.player.stop();
      await widget.player.play(source);
    }
  }

  InitMode initMode = InitMode.setSource;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return TabWrapper(
      children: [
        EnumTgl(
          options: {for (var e in InitMode.values) 'initMode-${e.name}': e},
          selected: initMode,
          onChange: (InitMode m) => setState(() {
            initMode = m;
          }),
        ),
        Btn(
          key: const Key('setSource-url-remote-wav-1'),
          txt: 'Remote URL WAV 1 - coins.wav',
          onPressed: () => setSource(UrlSource(_wavUrl1)),
        ),
        Btn(
          key: const Key('setSource-url-remote-wav-2'),
          txt: 'Remote URL WAV 2 - laser.wav',
          onPressed: () => setSource(UrlSource(_wavUrl2)),
        ),
        Btn(
          key: const Key('setSource-url-remote-mp3-1'),
          txt: 'Remote URL MP3 1 - ambient_c_motion.mp3',
          onPressed: () => setSource(UrlSource(_mp3Url1)),
        ),
        Btn(
          key: const Key('setSource-url-remote-mp3-2'),
          txt: 'Remote URL MP3 2 - nasa_on_a_mission.mp3',
          onPressed: () => setSource(UrlSource(_mp3Url2)),
        ),
        Btn(
          key: const Key('setSource-url-remote-m3u8'),
          txt: 'Remote URL M3U8 3 - BBC stream',
          onPressed: () => setSource(UrlSource(_m3u8StreamUrl)),
        ),
        Btn(
          key: const Key('setSource-url-remote-mpga'),
          txt: 'Remote URL MPGA 4 - Times stream',
          onPressed: () => setSource(UrlSource(_mpgaStreamUrl)),
        ),
        Btn(
          key: const Key('setSource-asset-wav'),
          txt: 'Asset 1 - laser.wav',
          onPressed: () => setSource(AssetSource(_asset1)),
        ),
        Btn(
          key: const Key('setSource-asset-mp3'),
          txt: 'Asset 2 - nasa.mp3',
          onPressed: () => setSource(AssetSource(_asset2)),
        ),
        Btn(
          key: const Key('setSource-bytes-local'),
          txt: 'Bytes - Local - laser.wav',
          onPressed: () async {
            final bytes = await AudioCache.instance.loadAsBytes(_asset1);
            setSource(BytesSource(bytes));
          },
        ),
        Btn(
          key: const Key('setSource-bytes-remote'),
          txt: 'Bytes - Remote - ambient.mp3',
          onPressed: () async {
            final bytes = await readBytes(Uri.parse(_mp3Url1));
            setSource(BytesSource(bytes));
          },
        ),
        Btn(
          key: const Key('setSource-url-local'),
          txt: 'Pick local file',
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles();
            final path = result?.files.single.path;
            if (path != null) {
              setSource(DeviceFileSource(path));
            }
          },
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class SongsSelector extends StatelessWidget {
  final Playing? playing;
  final List<Audio> audios;
  final Function(Audio) onSelected;
  final Function(List<Audio>) onPlaylistSelected;

  SongsSelector(
      {required this.playing,
      required this.audios,
      required this.onSelected,
      required this.onPlaylistSelected});

  Widget _image(Audio item) {
    if (item.metas.image == null) {
      return SizedBox(height: 40, width: 40);
    }

    return item.metas.image?.type == ImageType.network
        ? Image.network(
            item.metas.image!.path,
            height: 40,
            width: 40,
            fit: BoxFit.cover,
          )
        : Image.asset(
            item.metas.image!.path,
            height: 40,
            width: 40,
            fit: BoxFit.cover,
          );
  }

  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: -8,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(9)),
      ),
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FractionallySizedBox(
            widthFactor: 1,
            child: NeumorphicButton(
              onPressed: () {
                onPlaylistSelected(audios);
              },
              child: Center(child: Text('All as playlist')),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, position) {
                final item = audios[position];
                final isPlaying = item.path == playing?.audio.assetAudioPath;
                return Neumorphic(
                  margin: EdgeInsets.all(4),
                  style: NeumorphicStyle(
                    depth: isPlaying ? -4 : 0,
                    boxShape:
                        NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                  ),
                  child: ListTile(
                      leading: Material(
                        shape: CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: _image(item),
                      ),
                      title: Text(item.metas.title.toString(),
                          style: TextStyle(
                            color: isPlaying ? Colors.blue : Colors.black,
                          )),
                      onTap: () {
                        onSelected(item);
                      }),
                );
              },
              itemCount: audios.length,
            ),
          ),
        ],
      ),
    );
  }
}

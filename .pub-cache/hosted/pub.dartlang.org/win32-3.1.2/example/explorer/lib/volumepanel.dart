import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'models/volumes.dart';

class VolumePanel extends StatefulWidget {
  @override
  VolumePanelState createState() => VolumePanelState();
}

class VolumePanelState extends State<VolumePanel> {
  final _volumes = <Volume>[];

  @override
  void initState() {
    super.initState();

    _volumes.addAll(Volumes().getVolumes());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Storage volumes: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _volumes.length,
              itemBuilder: (context, position) => VolumeCard(
                volume: _volumes[position],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VolumeCard extends StatefulWidget {
  const VolumeCard({required this.volume});

  final Volume volume;

  @override
  VolumeCardState createState() => VolumeCardState();
}

class VolumeCardState extends State<VolumeCard> {
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const FaIcon(FontAwesomeIcons.hardDrive,
                        size: 32, color: Colors.blueGrey),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 5, 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.volume.deviceName,
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          Text(
                            widget.volume.volumeName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyText2!
                                .copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .caption
                                        ?.color),
                          ),
                          const Divider(height: 5),
                          Column(
                            children: [
                              for (var path in widget.volume.paths)
                                Text(
                                  path,
                                  style: Theme.of(context).textTheme.bodyText2,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

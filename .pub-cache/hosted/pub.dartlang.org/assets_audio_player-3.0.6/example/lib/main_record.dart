import 'dart:async';
import 'dart:io' as io;

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual);
  return runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: RecorderExample(),
        ),
      ),
    );
  }
}

class RecorderExample extends StatefulWidget {
  final LocalFileSystem localFileSystem;

  RecorderExample({localFileSystem})
      : localFileSystem = localFileSystem ?? LocalFileSystem();

  @override
  State<StatefulWidget> createState() => RecorderExampleState();
}

class RecorderExampleState extends State<RecorderExample> {
  late FlutterAudioRecorder _recorder;
  Recording? _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <
                Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () {
                    switch (_currentStatus) {
                      case RecordingStatus.Initialized:
                        {
                          _start();
                          break;
                        }
                      case RecordingStatus.Recording:
                        {
                          _pause();
                          break;
                        }
                      case RecordingStatus.Paused:
                        {
                          _resume();
                          break;
                        }
                      case RecordingStatus.Stopped:
                        {
                          _init();
                          break;
                        }
                      default:
                        break;
                    }
                  },
                  style: TextButton.styleFrom(
                    primary: Colors.lightBlue,
                  ),
                  child: _buildText(_currentStatus),
                ),
              ),
              TextButton(
                onPressed:
                    _currentStatus != RecordingStatus.Unset ? _stop : null,
                style: TextButton.styleFrom(
                  primary: Colors.blueAccent.withOpacity(0.5),
                ),
                child: Text('Stop', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(
                width: 8,
              ),
              TextButton(
                onPressed: onPlayAudio,
                style: TextButton.styleFrom(
                  primary: Colors.blueAccent.withOpacity(0.5),
                ),
                child: Text('Play', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          Text('Status : $_currentStatus'),
          Text('Avg Power: ${_current?.metering?.averagePower}'),
          Text('Peak Power: ${_current?.metering?.peakPower}'),
          Text('File path of the record: ${_current?.path}'),
          Text('Format: ${_current?.audioFormat}'),
          Text('isMeteringEnabled: ${_current?.metering?.isMeteringEnabled}'),
          Text('Extension : ${_current?.extension}'),
          Text('Audio recording duration : ${_current?.duration.toString()}')
        ]),
      ),
    );
  }

  Future<void> _init() async {
    try {
      final hasPermissions = await FlutterAudioRecorder.hasPermissions;
      if (hasPermissions == true) {
        var customPath = '/flutter_audio_recorder_';
        io.Directory? appDocDirectory;
//        io.Directory appDocDirectory = await getApplicationDocumentsDirectory();
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }

        if (appDocDirectory != null) {
          // can add extension like '.mp4' '.wav' '.m4a' '.aac'
          customPath = appDocDirectory.path +
              customPath +
              DateTime.now().millisecondsSinceEpoch.toString();

          // .wav <---> AudioFormat.WAV
          // .mp4 .m4a .aac <---> AudioFormat.AAC
          // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.
          _recorder =
              FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);

          await _recorder.initialized;
          // after initialization
          var current = await _recorder.current(channel: 0);
          print(current);
          // should be 'Initialized', if all working fine
          setState(() {
            _current = current;
            if (current?.status != null) {
              _currentStatus = current!.status!;
            }
            print(_currentStatus);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You must accept permissions')));
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _start() async {
    try {
      await _recorder.start();
      var recording = await _recorder.current(channel: 0);
      setState(() {
        _current = recording;
      });

      const tick = Duration(milliseconds: 50);
      Timer.periodic(tick, (Timer t) async {
        if (_currentStatus == RecordingStatus.Stopped) {
          t.cancel();
        }

        var current = await _recorder.current(channel: 0);
        // print(current.status);
        setState(() {
          _current = current;
          if (current?.status != null) {
            _currentStatus = current!.status!;
          }
        });
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _resume() async {
    await _recorder.resume();
    setState(() {});
  }

  Future<void> _pause() async {
    await _recorder.pause();
    setState(() {});
  }

  Future<void> _stop() async {
    final result = await _recorder.stop();
    if (result != null) {
      if (result.path != null) {
        print('Stop recording: ${result.path}');
        if (result.duration != null) {
          print('Stop recording: ${result.duration}');
          final file = widget.localFileSystem.file(result.path);
          print('File length: ${await file.length()}');
        }
        setState(() {
          _current = result;
          if (_current!.status != null) _currentStatus = _current!.status!;
        });
      }
    }
  }

  Widget _buildText(RecordingStatus status) {
    var text = '';
    switch (_currentStatus) {
      case RecordingStatus.Initialized:
        {
          text = 'Start';
          break;
        }
      case RecordingStatus.Recording:
        {
          text = 'Pause';
          break;
        }
      case RecordingStatus.Paused:
        {
          text = 'Resume';
          break;
        }
      case RecordingStatus.Stopped:
        {
          text = 'Init';
          break;
        }
      default:
        break;
    }
    return Text(text, style: TextStyle(color: Colors.white));
  }

  void onPlayAudio() async {
    final assetsAudioPlayer = AssetsAudioPlayer();
    if (_current?.path != null) {
      await assetsAudioPlayer.open(Audio.file(_current!.path!));
    }
  }
}

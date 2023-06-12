import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// A [Widget] showing all available information about the downloaded file
class FileInfoWidget extends StatelessWidget {
  final FileInfo fileInfo;
  final VoidCallback clearCache;
  final VoidCallback removeFile;

  const FileInfoWidget({
    Key key,
    this.fileInfo,
    this.clearCache,
    this.removeFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        ListTile(
          title: const Text('Original URL'),
          subtitle: Text(fileInfo.originalUrl),
        ),
        if (fileInfo.file != null)
          ListTile(
            title: const Text('Local file path'),
            subtitle: Text(fileInfo.file.path),
          ),
        ListTile(
          title: const Text('Loaded from'),
          subtitle: Text(fileInfo.source.toString()),
        ),
        ListTile(
          title: const Text('Valid Until'),
          subtitle: Text(fileInfo.validTill.toIso8601String()),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          // ignore: deprecated_member_use
          child: RaisedButton(
            child: const Text('CLEAR CACHE'),
            onPressed: clearCache,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          // ignore: deprecated_member_use
          child: RaisedButton(
            child: const Text('REMOVE FILE'),
            onPressed: removeFile,
          ),
        ),
      ],
    );
  }
}

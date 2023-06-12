import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'file_info_widget.dart';
import 'floating_action_button.dart';
import 'progress_indicator.dart' as p_i;

/// A [Widget] showing the information about the status of the [FileResponse]
class DownloadPage extends StatelessWidget {
  final Stream<FileResponse> fileStream;
  final VoidCallback downloadFile;
  final VoidCallback clearCache;
  final VoidCallback removeFile;

  const DownloadPage({
    Key key,
    this.fileStream,
    this.downloadFile,
    this.clearCache,
    this.removeFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FileResponse>(
      stream: fileStream,
      builder: (context, snapshot) {
        Widget body;

        var loading = !snapshot.hasData || snapshot.data is DownloadProgress;

        if (snapshot.hasError) {
          body = ListTile(
            title: const Text('Error'),
            subtitle: Text(snapshot.error.toString()),
          );
        } else if (loading) {
          body = p_i.ProgressIndicator(
              progress: snapshot.data as DownloadProgress);
        } else {
          body = FileInfoWidget(
            fileInfo: snapshot.data as FileInfo,
            clearCache: clearCache,
            removeFile: removeFile,
          );
        }

        return Scaffold(
          appBar: null,
          body: body,
          floatingActionButton: !loading
              ? Fab(
                  downloadFile: downloadFile,
                )
              : null,
        );
      },
    );
  }
}
